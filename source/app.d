module app;

import std.stdio;
import std.string;
import std.conv;
import std.array;
import std.algorithm;
import std.datetime;

import meu;

void main(string[] args) {
	MeuAI meu = new MeuAI("./practice/quest1.txt", delegate void(ans) {
		File outputFile = File("./output.txt", "w");
		ans.each!(str => outputFile.writeln(str));
	});
	meu.start();
}

void benchMark(int repeat, void delegate() f) {
	StopWatch sw;
	sw.start();
	for (int i; i < repeat; i++) f();
	sw.stop();
	writeln(sw.peek().msecs, "msec");
}
