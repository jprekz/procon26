module charlotte.problemreader;

import std.conv;
import std.stdio;
import std.string;

import charlotte.answertypes;
import charlotte.problemtypes;

class Reader {
	immutable Stone[] stone;
	immutable Field field;

	this(string fileName) {
		auto file = File(fileName);

		// load field
		bool[32][32] f;
		for (int i; i < 32; i++) {
			string s = file.readln.chomp;
			for (int j; j < 32; j++) {
                f[i][j] = (s[j] == '0') ? 0 : 1;
			}
		}
		field = f;

		file.readln;

		// load stones
		int N = file.readln.chomp.to!int;
		Stone[] st;
		for (int i; i < N; i++) {	//i個目
			bool[8][8] b;
			for (int j; j < 8; j++) {	//j行目
				string s = file.readln.chomp;
				for (int k; k < 8; k++) {	//k列目
                    b[j][k] = (s[k] == '0') ? 0 : 1;
				}
			}
			st ~= b;
			file.readln;
		}
		stone = st.idup;
	}
}
