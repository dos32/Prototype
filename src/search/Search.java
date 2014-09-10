package search;

import static utils.Utils.conn;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;

import utils.Logger;

public class Search {
	
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
	
	public static void main(String[] args) throws SQLException {
		Logger.LogEvent("searching %s", () -> {
			try {
				ArrayList<String> res = search("indica");
				if(res.size() > 0)
					res.forEach(System.out::println);
				else
					System.out.println("<search have no results>");
			} catch (Exception e) {
				throw new RuntimeException(e);
			}
		});
	}
	
}
