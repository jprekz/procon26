module app;

import std.stdio;
import std.string;
import std.conv;
import std.array;
import std.algorithm;
import std.datetime;

//import dfs.dfs;
import charlotte.dfs;
import charlotte.mc;
import charlotte.mcts;

void main(string[] args) {
	write("input problem num: ");
	string num = readln.chomp;
	auto solver = new MCTS("./practice/quest"~num~".txt", delegate void(ans) {
		File outputFile = File("./output.txt", "w");
		foreach (string s; ans) {
			outputFile.writeln(s);
		}
	});
	solver.start();
}
