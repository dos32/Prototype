package search;

import static utils.Utils.conn;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;

import utils.Logger;

/**
 * 
 * @author Bogdan Trofimov
 *
 */
public class Search /*extends JFrame*/ {
	
	public static ArrayList<String> search(String... query) throws SQLException {
		PreparedStatement searchSt = conn()
			.prepareStatement("select net_search(?)");
		searchSt.setArray(1, conn().createArrayOf("text", query));
		ResultSet searchRes = searchSt.executeQuery();
		ArrayList<String> res = new ArrayList<String>();
		while (searchRes.next())
			res.add(searchRes.getString(1));
		return res;
	}
	
//	JTextField requestArea;
	
	public Search() {
	/*	setTitle("Trainer");
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		Container pane = getContentPane();
		setLayout(new BoxLayout(pane, BoxLayout.Y_AXIS));
		
		JLabel label1 = new JLabel("request:");
		pane.add(label1);
        label1.setAlignmentX(Component.LEFT_ALIGNMENT);
        
        JPanel jp = new JPanel();
		pane.add(jp);
		jp.setLayout(new BoxLayout(jp, BoxLayout.LINE_AXIS));
		
		requestArea = new JTextField();
		JScrollPane jsp1 = new JScrollPane(requestArea);
		jp.add(jsp1);
		requestArea.setMargin(new Insets(2, 2, 2, 2));
		requestArea.setEditable(true);
		
		JButton searchButton = new JButton("search");
		jsp1.add(searchButton);
		searchButton.addActionListener((evt) -> {
			
		});
		
		*/
	}
	
	private static String readLine(String format, Object... args) throws IOException {
	    if (System.console() != null) {
	        return System.console().readLine(format, args);
	    }
	    System.out.print(String.format(format, args));
	    BufferedReader reader = new BufferedReader(new InputStreamReader(
	            System.in));
	    return reader.readLine();
	}
	
	private static void write(String format, Object... args) {
	    if (System.console() != null)
	        System.console().format(format, args);
	    else
	    	System.out.format(format, args);
	}
	
	public static void main(String[] args) throws SQLException, IOException {
		boolean flag = true;
		while(flag) {
			String[] query = readLine("Enter search query:").split(" ");
			Logger.LogEvent("searching..", () -> {
				try {
					ArrayList<String> res = new ArrayList<>();
					PreparedStatement searchSt = conn()
							.prepareStatement("select net_search(?)");
					searchSt.setArray(1, conn().createArrayOf("text", query));
					ResultSet searchRes = searchSt.executeQuery();
					while (searchRes.next())
						res.add(searchRes.getString(1));
					if(res.size() > 0) {
						System.out.printf("founded %s occurences\r", res.size());
						res.forEach(System.out::println);
					} else
						System.out.println("<search have no results>");
				} catch (Exception e) {
					throw new RuntimeException(e);
				}
			});
			String f = readLine("Continue? y/n");
			flag = f.equalsIgnoreCase("y");
		}
	}
	
}
