package indexer;

import java.io.File;
import java.io.IOException;

import org.mozilla.universalchardet.UniversalDetector;

/**
 * 
 * @author Bogdan Trofimov
 *
 */
public class CharsetDetector {

	public static String detect(File file) throws IOException {
	    try(java.io.FileInputStream fis = new java.io.FileInputStream(file)) {
		    byte[] buf = new byte[4096];
		    UniversalDetector detector = new UniversalDetector(null);
		    int nread;
		    while ((nread = fis.read(buf)) > 0 && !detector.isDone()) {
		      detector.handleData(buf, 0, nread);
		    }
		    detector.dataEnd();
		    String encoding = detector.getDetectedCharset();
		    if (encoding != null)
		    	return encoding;
		    else {
		    	System.err.printf("No encoding detected on file \"%s\"\n", file.getAbsolutePath());
		    	return "UTF8";
		    }
//		    detector.reset();
	    }
	}
	
}
