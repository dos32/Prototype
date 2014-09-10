package trainer;

import static utils.Utils.conn;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import utils.Logger;
import utils.StopWatch;

public class Trainer {
	
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
				getRandomDoc.execute();
				Logger.Logf("\ninner iteration: %s/10\n", i);
				Logger.Logf("handleClusters on %s\n",
					getRandomDoc.getLong(1));
				handleClusters(getRandomDoc.getLong(1));
			}
		}
		conn().commit();
	}
	
	public static void main(String[] args) throws SQLException {
		for(int i = 0; i < 500; i++) {
			Logger.Logf("*** iteration: %s ***\n", i);
			train();
		}
		System.out.println("training done");
	}
	
}
