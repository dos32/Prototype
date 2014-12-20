package indexer;

import java.io.File;
import java.io.IOException;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.stream.Stream;

import utils.Logger;
import utils.Utils;
import static utils.Utils.conn;

/**
 * 
 * @author Bogdan Trofimov
 *
 */
public class Indexer {
	
	private static CallableStatement qPush;
	
	protected static void queuePush(File... args) throws SQLException, IOException {
		for(File folder : args) {
			if(folder.exists())
				if(folder.isDirectory()) {
					qPush.registerOutParameter(1, Types.BIGINT);
					qPush.setString(2, folder.getAbsolutePath());
					qPush.execute();
				} else
					addToIndex(folder);
			else
				throw new RuntimeException("file \"%s\" is not exists\r\r" + folder.getAbsolutePath());
		}
	}
	
	protected static String queuePeek() throws SQLException {
		String res = null;
		Statement st = conn().createStatement();
		ResultSet r = st.executeQuery(
			"SELECT id, path FROM index_queue ORDER BY id LIMIT 1;"
		);
		if(r.next()) {
			res = r.getString(2);
		}
		r.close();
		return res;
	}
	
	public static void queueRemove() throws SQLException {
		Statement st = conn().createStatement();
		st.execute(
			"DELETE FROM index_queue WHERE id = (select min(id) from index_queue);"
		);
	}
	
	private static PreparedStatement idxSelectRoots;
	private static PreparedStatement idxSelect;
	private static PreparedStatement idxInsert;
	protected static void addToIndex(File file) throws SQLException, IOException {
		System.out.println("adding " + file.getAbsolutePath());
		String[] pathParts = file.getAbsolutePath().split(String.format("%s+", Utils.getSafeString(Utils.pathDelimeter)));
		Object parentId = null;
		for(int i=0; i<pathParts.length; i++) {
			String part = pathParts[i];
			ResultSet r1;
			if(parentId == null) {
				idxSelectRoots.setString(1, part);
				r1 = idxSelectRoots.executeQuery();
			} else {
				idxSelect.setString(1, part);
				idxSelect.setLong(2, (long)parentId);
				r1 = idxSelect.executeQuery();
			}
			if(r1.next())
				parentId = r1.getObject(1);
			else {
				idxInsert.setObject(1, parentId);
				idxInsert.setString(2, part);
				idxInsert.setBoolean(3, i != pathParts.length - 1 || file.isDirectory());
				ResultSet r2 = idxInsert.executeQuery();
				if(r2.next())
					parentId = r2.getObject(1);
				else
					System.err.println("addToIndex: RETURNING id is not fetched");
				r2.close();
			}
			r1.close();
		}
//		if(!file.isDirectory()) {
//			FileIndexer.index((long) parentId, file);
//			FileIndexer.flush();
//		}
		conn().commit();
	}

	public static void index(File... dirs) throws SQLException, IOException {
		// indexing headers:
		idxSelect = conn().prepareStatement("SELECT id "+
				"FROM docs WHERE node = ? AND parent_id = ?;");
		idxSelectRoots = conn().prepareStatement("SELECT id "+
				"FROM docs WHERE node = ? AND parent_id is null;");
		idxInsert = conn().prepareStatement("INSERT INTO docs (parent_id, node, weight, indexed) "+
				"VALUES (?, ?, 0, ?) RETURNING id;");
		qPush = conn().prepareCall("{ ? = call queue_push(?) }");
		queuePush(dirs);
		conn().commit();
		String path = null;
		while((path = queuePeek()) != null) {
			File dir = new File(path);
			if(dir.exists()) {
			    File list[] = dir.listFiles();
			    for(int i = 0; i < list.length; i++) {
			        File subFile = list[i];
			        if(subFile.isFile()) {
			        	addToIndex(subFile);
			        } else if(subFile.isDirectory())
			        	queuePush(subFile);
			    }
				addToIndex(dir);
			} else
				System.err.printf("directory %s is not exists, remove it from queue\r", path);
		    queueRemove();
			conn().commit();
		}
		idxSelect.close();
		idxSelectRoots.close();
		idxInsert.close();
		// indexing content of files:
		PreparedStatement getNextNotIndexed = conn().prepareStatement("select id, doc_get_path(id) from docs "+
				"where indexed = false limit 1");
		PreparedStatement setIndexed = conn().prepareStatement("update docs set indexed = true where id = ?");
		ResultSet notIndexed = getNextNotIndexed.executeQuery();
		while(notIndexed.next()) {
			Logger.Logf("indexing %s\r", notIndexed.getString(2));
			File file = new File(notIndexed.getString(2));
			if(!file.isDirectory()) {
				FileIndexer.index(notIndexed.getLong(1), file);
				FileIndexer.flush();
			}
			setIndexed.setLong(1, notIndexed.getLong(1));
			setIndexed.execute();
			conn().commit();
			notIndexed.close();
			notIndexed = getNextNotIndexed.executeQuery();
		}
		conn().close();
	}
	
	public static void main(String[] args) throws IOException, SQLException {
		File[] files = (File[]) Stream.of(args).map(e -> new File(e)).toArray();
		index(files);
//		index(new File[] {new File("G:\\docs\\")});
//		index();
	}

}
