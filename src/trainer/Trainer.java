package trainer;

import static utils.Utils.conn;

import java.awt.Component;
import java.awt.Container;
import java.awt.Insets;
import java.io.PrintStream;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import javax.swing.BoxLayout;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;

import utils.AppLock;
import utils.Logger;
import utils.StopWatch;
import utils.outputRedirect.OutputRedirect;

/**
 * 
 * @author Bogdan Trofimov
 *
 */
public class Trainer extends JFrame {
	private static final long serialVersionUID = 2177298796154436547L;

	static double getProgressPercent() throws Exception {
		CallableStatement progress = conn().prepareCall("{ call _trained_docs_percent() }");
		ResultSet res = progress.executeQuery();
		if(res.next())
			return res.getDouble(1);
		else
			throw new Exception("Can't fetch result");
	}
	
	static int getMaxNeurons(long datasetSize) {
		int res = (int) Math.round(Math.pow(
				datasetSize, Settings.maxNeuronsFactor));
		return res;
	}
	
	static void handleClusters(long docId) throws SQLException {
		PreparedStatement getNeuronsCount = conn()
				.prepareStatement("select count(1) from neurons");
		ResultSet ncr = getNeuronsCount.executeQuery();
		ncr.next();
		Logger.Logf("Count neurons = %s\n", ncr.getLong(1));
		PreparedStatement getNearestNeurons = conn()
			.prepareStatement("select id, get_distance(doc_get_vector(?), "+
				"array(select (term_id, value)::_vector "+
				"from neuron_vectors "+
				"where neuron_vectors.neuron_id = id)::_vector[]) as dist "+
				"from neurons order by dist asc limit 2;");
		getNearestNeurons.setLong(1, docId);
		StopWatch sw = new StopWatch();
		ResultSet nearestNeuronsRes = getNearestNeurons.executeQuery();
		sw.PrintTime("get nearest neurons %s ms\n");
		Logger.Logf("next1 %s\n", nearestNeuronsRes.next());
		long n1 = nearestNeuronsRes.getLong(1);
		Logger.Logf("next2 %s\n", nearestNeuronsRes.next());
		long n2 = nearestNeuronsRes.getLong(1);
		nearestNeuronsRes.close();
		CallableStatement neuronBindDoc = conn()
			.prepareCall("{ call neuron_bind_doc(?, ?) }");
		neuronBindDoc.setLong(1, n1);
		neuronBindDoc.setLong(2, docId);
		sw = new StopWatch();
		neuronBindDoc.execute();
		sw.PrintTime("neuron_bind_doc %s ms\n");
		CallableStatement neuronBindNeuron = conn()
			.prepareCall("{ call neuron_bind_neuron(?, ?) }");
		neuronBindNeuron.setLong(1, n1);
		neuronBindNeuron.setLong(2, n2);
		sw = new StopWatch();
		Logger.Logf("n1 = %s, n2 = %s\n", n1, n2);
		neuronBindNeuron.execute();
		sw.PrintTime("neuron_bind_neuron %s ms\n");
		CallableStatement neuronIncBondAge = conn()
			.prepareCall("{ call neuron_inc_bond_age(?) }");
		neuronIncBondAge.setLong(1, n1);
		sw = new StopWatch();
		neuronIncBondAge.execute();
		sw.PrintTime("neuron_inc_bond_age %s ms\n");
	}
	
	public static void train() throws SQLException {
		PreparedStatement getNeuronsCount = conn()
			.prepareStatement("select count(1) from neurons");
		ResultSet neuronsCountRes = getNeuronsCount.executeQuery();
		neuronsCountRes.next();
		long neuronsCount = neuronsCountRes.getLong(1);
		if(neuronsCount < 2) {
			final CallableStatement createNeuron = conn()
				.prepareCall("{ ? = call neuron_create(doc_get_random()) }");
			createNeuron.registerOutParameter(1, Types.BIGINT);
			CallableStatement neuronBindNeuron = conn()
				.prepareCall("{ call neuron_bind_neuron(?, ?) }");
			createNeuron.execute();
			long n1 = createNeuron.getLong(1);
			createNeuron.execute();
			long n2 = createNeuron.getLong(1);
			neuronBindNeuron.setLong(1, n1);
			neuronBindNeuron.setLong(2, n2);
			neuronBindNeuron.execute();
		} else {
			PreparedStatement getEpoch = conn()
				.prepareStatement("select ivalue from variables "+
						"where name = 'epoch'");
			ResultSet epochRes = getEpoch.executeQuery();
			epochRes.next();
			long epoch = epochRes.getLong(1);
			PreparedStatement getDatasetSize = conn()
				.prepareStatement("select count(1) from docs");
			ResultSet datasetSizeRes = getDatasetSize.executeQuery();
			datasetSizeRes.next();
			long datasetSize = datasetSizeRes.getLong(1);
			if(epoch % 5 == 0 && neuronsCount < getMaxNeurons(datasetSize))
				conn().prepareCall("{ call neuron_add() }").execute();
			CallableStatement getRandomDoc = conn()
				.prepareCall("{ ? = call doc_get_random() }");
			getRandomDoc.registerOutParameter(1, Types.BIGINT);
			for(int i = 0; i < 10; i++) {
				iteration++;
				trainer.refreshInfo();
				getRandomDoc.execute();
				Logger.Logf("\ninner iteration: %s/10\n", i);
				Logger.Logf("handleClusters on %s\n",
					getRandomDoc.getLong(1));
				handleClusters(getRandomDoc.getLong(1));
			}
		}
		conn().commit();
	}
	
	static int iteration = 0;
	static Trainer trainer;
	
	JLabel label1, label2;
	JTextArea console1, console2;
	
	public Trainer() {
		setTitle("Trainer");
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		Container pane = getContentPane();
		setLayout(new BoxLayout(pane, BoxLayout.Y_AXIS));
		
		label1 = new JLabel();
		pane.add(label1);
        label1.setAlignmentX(Component.CENTER_ALIGNMENT);
		
        label2 = new JLabel();
		pane.add(label2);
		label2.setAlignmentX(Component.CENTER_ALIGNMENT);
		
		JPanel jp = new JPanel();
		pane.add(jp);
//		jp.setSize(10, 10);
		jp.setLayout(new BoxLayout(jp, BoxLayout.LINE_AXIS));
		
		console1 = new JTextArea();
		JScrollPane jsp1 = new JScrollPane(console1);
		jp.add(jsp1);
		console1.setMargin(new Insets(2, 2, 2, 2));
		console1.setEditable(false);

		console2 = new JTextArea();
		JScrollPane jsp2 = new JScrollPane(console2);
		jp.add(jsp2);
		console2.setMargin(new Insets(2, 2, 2, 2));
		console2.setEditable(false);
		
		setSize(500, 300);
		setVisible(true);
	}
	
	void refreshInfo() {
		try {
			label1.setText(String.format("progress = %.2f%%", getProgressPercent()));
			label2.setText(String.format("iteration = %d", iteration));
		} catch (Exception e) {
			label1.setText(e.getMessage());
		}
	}
	
	public static void main(String[] args) throws SQLException {
		if(!AppLock.setLock("Trainer"))
			System.err.println("Trainer already runned");
		else {
			trainer = new Trainer();
			OutputRedirect oro = new OutputRedirect(s -> trainer.console1.append(s + "\n"));
			System.setOut(new PrintStream(oro.getOutputStream()));
			oro.start();
			OutputRedirect ore = new OutputRedirect(s -> trainer.console2.append(s + "\n"));
			System.setErr(new PrintStream(ore.getOutputStream()));
			ore.start();
			while(true) {
//				iteration++;
//				trainer1.refreshInfo();
				train();
			}
		}
	}
	
}
