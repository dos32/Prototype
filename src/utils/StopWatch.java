package utils;

public class StopWatch {
	
	private long startTime;
	private long endTime;
	private boolean stopped = false;
	
	public StopWatch() {
		startTime = System.nanoTime();
	}
	
	public void stop() {
		stopped = true;
		endTime = System.nanoTime();
	}
	
	public double getElapsedMs() {
		return ((stopped?endTime:System.nanoTime()) - startTime) / 1e6d;
	}
	
	public long getElapsedNano() {
		return (stopped?endTime:System.nanoTime()) - startTime;
	}
	
	public void PrintTime(String fmt) {
		Logger.Logf(fmt, getElapsedMs());
	}
	
}
