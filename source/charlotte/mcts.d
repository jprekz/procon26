module charlotte.mcts;

import std.stdio;
import std.string;
import std.range;
import std.algorithm;
import std.typecons;
import std.parallelism;
import std.datetime;
import std.conv;
import std.math;
import std.random;
import core.cpuid;

import charlotte.answertypes;
import charlotte.problemreader;
import charlotte.problemtypes;
import charlotte.stoneanalyzer;

class MCTS {
	const Reader problem;
	const void delegate(string[], int) findAnswerDelegate;
    const Place[] allPlaceList = calcAllPlaceList;
	const StoneAnalyzed[] stoneInfo;
	const int fieldCells;
	const int stonesTotal;
	StopWatch sw;

	this(string problemName, void delegate(string[], int) findAnswer) {
		problem = new Reader(problemName);
		findAnswerDelegate = findAnswer;
		sw.start();
		stoneInfo = problem.stone.analyzeAll;
		writeln(sw.peek().msecs,"msec");
		fieldCells = problem.field.countEmptyCells;
		stonesTotal = problem.stone.length.to!int;
	}

	class Node {
	    int depth;
	    Field nowField;
	    Field placeableMap;
	    bool first;
	    Operation searchingAnswer;
		this(int d, Field n, Field p, bool f, Operation s) {
			depth = d; nowField = n; placeableMap = p;
			first = f; searchingAnswer = s;
		}
		Node[] calcChildNodes() {
			Node[] ls;
			foreach (p; allPlaceList) {
				if ((stoneInfo[depth].skipFlip && p.flip) ||
					(stoneInfo[depth].skipR90 && (p.rotate == 1 || p.rotate == 3)) ||
					(stoneInfo[depth].skipR180 && p.rotate == 2)) {
					continue;
				}
				Stone stoneRotated = problem.stone[depth].transform(p.flip, p.rotate);
				if (stoneRotated.isProtrude(p.x, p.y)) continue;
				Field placedStone = stoneRotated.putStoneOnField(p.x, p.y);
				if ((placedStone & nowField) != Field.init ||
					(placedStone & placeableMap) == Field.init) {
					continue;
				}
				ls ~= new Node(
					depth + 1,
					nowField | placedStone,
					(first) ? placedStone.bordering
						: (placeableMap | placedStone.bordering),
					false,
					new Operation(p, searchingAnswer)
				);
			}
			ls ~= new Node(
				depth + 1,
				nowField,
				placeableMap,
				first,
				new Operation(searchingAnswer)
			);
			return ls;
		}
	}

	class MCTNode {
		Node node;
		MCTNode parentNode;
		double score = 0.8;
		int visits = 0;
		bool expanded = false;
		MCTNode[] childNodes = MCTNode[].init;
		this(Node n, MCTNode p) {
			node = n;
			parentNode = p;
		}
		void expand() {
			if (expanded) return;
			Node[] cNode = node.calcChildNodes;
			foreach (i, n; cNode) {
				if (cNode.length > 100 && i % (cNode.length/100+1) != 0) continue;
				childNodes ~= new MCTNode(n, this);
			}
			expanded = true;
		}
		MCTNode selectNext() {
			assert (expanded);
			auto totalVisits = visits;
			auto values = childNodes.map!((n) {
				const c = 0.1;
				return n.score + c * sqrt(log(totalVisits) / n.visits).to!double;
			}).array;
			int index = 0; double max = 0.0;
			foreach (i, v; values) {
				if (max < v) {
					max = v;
					index = i.to!int;
				}
			}
			return childNodes[index];
		}
		bool isExpandedCond() {
			if (node.depth >= stonesTotal - 1) return false;
			return visits >= 4;
		}
		void updateUpwards(int scoreUpdate) {
			double normalizedScore = 1.0 - scoreUpdate.to!double / fieldCells;
			visits++;
			score = (score * visits + normalizedScore) / (visits + 1);
			if (parentNode !is null) parentNode.updateUpwards(scoreUpdate);
		}
	}

	void start() {
		MCTNode root = new MCTNode(new Node( 0,
			problem.field,
			problem.field.inv,
			true,
			null
		), null);
		root.expand;
		foreach (i; parallel(iota(threadsPerCPU), 1)) {
			int[] rndOrder = iota(allPlaceList.length).map!("a.to!int").array;
			while (true) {
				MCTNode now = root;
				while (now.expanded) now = now.selectNext;
				if (now.isExpandedCond) {
					synchronized { now.expand; }
					now = now.childNodes[0];
				}
				now.visits++;
				int score = playout(now.node, rndOrder);
				now.visits--;
				writeln(now.node.depth,",\t",score,",\t",sw.peek().msecs,"msec");
				now.updateUpwards(score);
				rndOrder.randomShuffle;
			}
		}
	}

	int playout(Node firstNode, ref const int[] rndOrder) {
		Node now = new Node(
			firstNode.depth,
			firstNode.nowField,
			firstNode.placeableMap,
			firstNode.first,
			firstNode.searchingAnswer
		);
		while (true) {
			if (now.depth >= stonesTotal) {
				end(now.nowField, now.searchingAnswer);
				return now.nowField.countEmptyCells;
			}

			bool flag = true;
			foreach (i; rndOrder) {
				Place p = allPlaceList[i];
				if ((stoneInfo[now.depth].skipFlip && p.flip) ||
					(stoneInfo[now.depth].skipR90 && (p.rotate == 1 || p.rotate == 3)) ||
					(stoneInfo[now.depth].skipR180 && p.rotate == 2)) {
					continue;
				}
				// 石を回転
				Stone stoneRotated = problem.stone[now.depth].transform(p.flip, p.rotate);

				// 石がフィールド外にはみ出さないか
				if (stoneRotated.isProtrude(p.x, p.y)) continue;

				// 石をField座標に配置
				Field placedStone = stoneRotated.putStoneOnField(p.x, p.y);

				// 石が置ける位置にあるか
				if ((placedStone.isWrap(now.nowField)) ||
					!(placedStone.isWrap(now.placeableMap))) {
					continue;
				}

				now.depth ++;
				now.nowField = now.nowField | placedStone;
				now.placeableMap = (now.first) ? placedStone.bordering
					: (now.placeableMap | placedStone.bordering);
				now.first = false;
				now.searchingAnswer = new Operation(p, now.searchingAnswer);
				flag = false;
				break;
			}

			if (flag) {
				now.depth ++;
				now.searchingAnswer = new Operation(now.searchingAnswer);
			}
		}
	}

	int bestScore = 1024;
	void end(Field f, Operation ans) {
		int score = f.countEmptyCells;
		if (bestScore <= score) return;
		bestScore = score;
		writeln(f.toString, score);
		findAnswerDelegate(ans.getAnswer(), score);
	}
}



class MC : MCTS {
	this(string problemName, void delegate(string[], int) findAnswer) {
		super(problemName, findAnswer);
	}

	override void start() {
		foreach (i; parallel(iota(threadsPerCPU), 1)) {
			int[] rndOrder = iota(allPlaceList.length).map!("a.to!int").array;
			while (true) {
				int score = playout( new Node( 0,
					problem.field,
					problem.field.inv,
					true,
					null
				), rndOrder);
				writeln(score,",\t",sw.peek().msecs,"msec");
				rndOrder.randomShuffle;
			}
		}
	}
}
