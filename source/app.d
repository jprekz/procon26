module app;

import std.stdio;
import std.string;
import std.conv;
import std.array;
import std.algorithm;
import std.datetime;

import field;
import reader;
import stone;

void main(string[] args) {
	auto rd = Reader("./practice/quest1.txt");
	auto s = rd.stone[1];
	writeln(rd.field);
	writeln(s);
	StopWatch sw;
	sw.start();
	for (int i; i < 100000000; i++) {
		assert(!s.getbit(i%8, 7));
		assert(!s.transform(true,1).getbit(0, 3));
	}
	sw.stop();
	writeln(sw.peek().msecs);
}
