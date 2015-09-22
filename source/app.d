module app;

import std.stdio;
import std.string;
import std.conv;
import std.array;
import std.algorithm;
import std.datetime;

//import dfs.dfs;
import charlotte.dfs;

void main(string[] args) {
	DFS dfs = new DFS("./practice/quest7.txt", delegate void(ans) {
		File outputFile = File("./output.txt", "w");
		foreach (string s; ans) {
			outputFile.writeln(s);
		}
	});
	dfs.start();
}
