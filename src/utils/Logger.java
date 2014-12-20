package utils;

/**
 * 
 * @author Bogdan Trofimov
 *
 */
public class Logger {
	
	public static void Log(String... s) {
		System.out.println(s);
	}
	
	public static void Logf(String fmt, Object... args) {
		System.out.printf(fmt, args);
	}
	
	public static void LogEvent(String eventName, Runnable event) {
		StopWatch sw = new StopWatch();
		Logf("Event \"%s\" started\n", eventName);
		event.run();
		sw.stop();
		Logf("Event \"%s\" ended in %s ms\n", eventName, sw.getElapsedMs());
	}
	
}
