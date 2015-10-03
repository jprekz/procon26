module app;

import std.stdio;
import std.string;
import std.conv;
import std.array;
import std.algorithm;
import std.datetime;

//import dfs.dfs;
import charlotte.dfs;
import charlotte.mcts;

void main(string[] args) {
	write("input problem num: ");
	string num = readln.chomp;
	auto solver = new MC("./practice/quest"~num~".txt", delegate void(ans, score) {
		File outputFile = File("./answer/output"~num~"-"~score.to!string~".txt", "w");
		foreach (string s; ans) {
			outputFile.writeln(s);
		}
	});
	solver.start();
}
