module app;

import std.stdio;
import std.string;
import std.conv;
import std.array;
import std.algorithm;
import std.datetime;

//import dfs.dfs;
import charlotte.dfs;
import charlotte.randombeam;

void main(string[] args) {
	auto solver = new RandomBeam("./practice/quest1.txt", delegate void(ans) {
		File outputFile = File("./output.txt", "w");
		foreach (string s; ans) {
			outputFile.writeln(s);
		}
	});
	solver.start();
}
