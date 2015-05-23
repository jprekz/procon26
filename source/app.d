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
	writeln(s.transform(true, 0));
	writeln(s.transform(true, 1));
	writeln(s.transform(true, 2));
	writeln(s.transform(true, 3));
	
	benchMark(10000000, {
		assert(!s.getbit(0, 7));
		assert(!s.transform(true,1).getbit(0, 3));
	});
}

void benchMark(int repeat, void delegate() f) {
	StopWatch sw;
	sw.start();
	for (int i; i < repeat; i++) f();
	sw.stop();
	writeln(sw.peek().msecs, "msec");
}
