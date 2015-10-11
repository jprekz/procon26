module app;

import std.stdio;
import std.string;
import std.path;
import std.file;
import std.conv;
import std.array;
import std.algorithm;
import std.datetime;
import std.getopt;
import std.parallelism;
import std.net.curl;
import core.thread;
import std.process;

//import dfs.dfs;
import charlotte.dfs;
import charlotte.mcts;

const string unofficialPracticeHost = "procon26practice.sakura.ne.jp/problem/download";
const string officialPracticeHost = "practice26.procon-online.net/questions";

const string serverHost = "testform26.procon-online.net";
const string canonServerHost = "172.16.2.97:40000";
const string teamTestToken = "0123456789abcdef";
const string teamToken = "1f261bf2056249d7";

enum Mode { practice, local, direct, canon }

void main(string[] args) {
	int problemNumber = -1;
	Mode mode;
	getopt(
		args,
		"num", &problemNumber,
		"mode", &mode
	);

	string problemFileName = getProblem(mode, problemNumber);
	string problemBaseName = baseName(problemFileName, ".txt");

	auto solver = new MCTSP!(64)(problemFileName, delegate (ans, score, stones) {
		string answerFileName =
			"./answer/"~problemBaseName~"-"~score.to!string~"-"~stones.to!string~".txt";
		File answerFile = File(answerFileName, "w");
		foreach (string s; ans) {
			answerFile.writeln(s);
		}
		answerFile.close();
		if (mode == Mode.canon) {
			auto curl = execute(["curl", "http://"~canonServerHost~"/answer",
				"--form-string", "score="~score.to!string,
				"--form-string", "stone="~stones.to!string,
				"--form-string", "token=jprekz",
				"-F", "answer=@"~answerFileName[2 .. $]]);
			curl.output.writeln;
		} else if (mode == Mode.direct) {
			auto curl = execute(["curl", "http://"~serverHost~"/answer",
				"--form-string", "token="~teamToken,
				"-F", "answer=@"~answerFileName[2 .. $]]);
			curl.output.writeln;
			Thread.sleep(dur!("msecs")(800));	//クソ実装
		}
	});
	solver.start();
}

string getProblem(Mode mode, ref int problemNumber) {
	string problemFileName;
	if (mode == Mode.practice) {
		int host;
		while (1) {
			writeln("1) unofficial    2) official");
			writeln("select host(1/2): ");
			host = readln.chomp.to!int;
			if (host == 1 || host == 2) break;
		}
		write("input problem num: ");
		problemNumber = readln.chomp.to!int;
		if (host == 1) {
			problemFileName = "./practice/u"~"quest"~problemNumber.to!string~".txt";
			if (!exists(problemFileName)) download(unofficialPracticeHost~"/quest"~problemNumber.to!string~".txt",
				problemFileName);
		} else {
			problemFileName = "./practice/o"~"quest"~problemNumber.to!string~".txt";
			if (!exists(problemFileName)) download(officialPracticeHost~"/"~problemNumber.to!string~".txt",
				problemFileName);
		}
	} else if (mode == Mode.local) {
		write("input file path: ./");
		problemFileName = "./" ~ readln.chomp;
	} else if (mode == Mode.canon) {
		if (problemNumber == -1) {
			write("input problem num: ");
			problemNumber = readln.chomp.to!int;
		}
		problemFileName = "./problem/quest"~problemNumber.to!string~".txt";
		download(canonServerHost~"/quest?num="~problemNumber.to!string,
			problemFileName);
	} else if (mode == Mode.direct) {
		if (problemNumber == -1) {
			write("input problem num: ");
			problemNumber = readln.chomp.to!int;
		}
		problemFileName = "./problem/quest"~problemNumber.to!string~".txt";
		download(serverHost~"/quest"~problemNumber.to!string~".txt?token="~teamToken,
			problemFileName);
	}
	return problemFileName;
}
