package indexer;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class FileTokenizer {
	
	public enum TokenizerState {
		NOT_INITIALIZED,
		WORD,
		LONGWORD,
		SPACE
	}

	protected BufferedReader s;

	protected char c;

	protected int l;

	protected StringBuilder sb;

	public int minWordLength = 2;

	public int maxWordLength = 100;

	public TokenizerState state = TokenizerState.NOT_INITIALIZED;

	public FileTokenizer(BufferedReader stream) {
		state = TokenizerState.NOT_INITIALIZED;
		s = stream;
		minWordLength = 2;
		maxWordLength = 20;
	}

	protected boolean isWordChar() {
		return c >= 'a' && c <= 'z' ||
			c >= 'A' && c <= 'Z' ||
			c >= 'а' && c <= 'я' ||
			c >= 'А' && c <= 'Я';
	}

	public String nextToken() {
		l = 0;
		c = '\0';
		sb = new StringBuilder();
		int b = 0;
		try {
			while ((b = s.read()) != -1) {
				c = (char) b;
				if (isWordChar()) {
					if (state != TokenizerState.LONGWORD) {
						sb.append(c);
						if (sb.length() >= maxWordLength) {
							state = TokenizerState.LONGWORD;
							sb.setLength(0);
						} else
							state = TokenizerState.WORD;
					}
				} else {
					if (state == TokenizerState.WORD && sb.length() >= minWordLength)
						return sb.toString().toLowerCase();
					sb.setLength(0);
					state = TokenizerState.SPACE;
				}
			}
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
		return null;
	}
	
}
