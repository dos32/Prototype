package indexer;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;

import utils.Logger;
import utils.StopWatch;
import utils.Utils;
import static utils.Utils.conn;

public class FileIndexer {
	
	private static CallableStatement insTerm;
	
	private static void init() {
		try {
			if(insTerm == null)
				insTerm  = conn().prepareCall("{ ? = call terms_add(?, ?) }");
		} catch(SQLException e) {
			throw new RuntimeException(e);
		}
	}
	
	static class TermEntry {
		public long fileId;
		public String term;
		
		public TermEntry(long fileId, String term) {
			this.fileId = fileId;
			this.term = term;
		}
	}
	private static ArrayList<TermEntry> buffer = new ArrayList<TermEntry>();
	private static final int BUFFER_SIZE = 10000;
	private static void addTerm(long fileId, String term) throws SQLException {
		if(buffer.size() >= BUFFER_SIZE) {
			flush();
		}
		buffer.add(new TermEntry(fileId, term));
	}
	
	public static void flush() throws SQLException {
		ArrayList<String> terms = new ArrayList<String>();
		for(int i = 0; i<buffer.size(); i++) {
			if(i != 0 && (buffer.get(i-1).fileId != buffer.get(i).fileId || i == buffer.size()-1)) {
				if(i == buffer.size()-1)
					terms.add(buffer.get(i).term);
				insTerm.registerOutParameter(1, Types.ARRAY);
				insTerm.setArray(2, conn().createArrayOf("text", terms.toArray()));
				insTerm.setLong(3, buffer.get(i-1).fileId);
				StopWatch sw = new StopWatch();
				insTerm.execute();
				sw.stop();
				Logger.Logf("Flush %d terms, %f term per sec\r", terms.size(), terms.size()*1000/sw.getElapsedMs());
				terms.clear();
			}
			terms.add(buffer.get(i).term);
		}
		buffer.clear();
	}

	public static void index(long fileId, File file) throws SQLException, IOException {
		try {
			FileTokenizer tokenizer = new FileTokenizer(new BufferedReader(
					new InputStreamReader(new FileInputStream(file), Charset.forName(CharsetDetector.detect(file)))));
			init();
			for(String term = tokenizer.nextToken(); term != null; term = tokenizer.nextToken()) {
//				System.out.println(term);
				addTerm(fileId, term);
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
	}
	
}
