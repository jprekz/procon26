module dfs.reader;

import std.conv;
import std.stdio;
import std.string;

import dfs.stone;
import dfs.field;

class Reader {
	immutable Stone[] stone;
	immutable Field field;

	this(string fileName) {
		auto file = File(fileName);

		// load field
		int[32] f;
		for (int i; i < 32; i++) {
			string s = file.readln.chomp;
			for (int j; j < 32; j++) {
				f[i] <<= 1;
				if (s[j] == '0') continue;
				f[i] ++;
			}
		}
		field = f;

		file.readln;

		// load stones
		int N = file.readln.chomp.to!int;
		Stone[] st;
		for (int i; i < N; i++) {	//i個目
			byte[8] b = 0;
			for (int j; j < 8; j++) {	//j行目
				string s = file.readln.chomp;
				for (int k; k < 8; k++) {	//k列目
					b[j] <<= 1;
					if (s[k] == '0') continue;
					b[j] ++;
				}
			}
			st ~= b;
			file.readln;
		}
		stone = st;
	}
}
