package utils;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * 
 * @author Bogdan Trofimov
 *
 */
public class Utils {
	
	public static String pathDelimeter = "\\";
	
	public static String getSafeString(String str) {
		return str.replace("\\", "\\\\");
	}

	protected static Connection conn = null;
	
	public static Connection conn() {
		if(conn == null)
			try {
				conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/AIST",
					"postgres",
//					"1"
					"1234567890qwertyuiopasdfghjkl;"
					);
				conn.setAutoCommit(false);
			} catch (SQLException e) {
				throw new RuntimeException(e);
			}
		return conn;
	}
	
	public static long eventSpan(Runnable event) {
		long start = System.nanoTime();
		event.run();
		return System.currentTimeMillis() - start;
	}
	
}
