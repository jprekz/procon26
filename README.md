# procon26

第26回高専プロコンの競技部門で用いたプログラム。だいぶアレなコードだけどせっかくなので公開。

このチームではソルバー2台・サーバー1台の構成で出場，そのソルバーのうち片方がこのプログラム。以下が出場した時のマシンスペック等

* PC: Lenovo ThinkPad E440
* OS: Windows 10 Pro 64bit
* CPU: Core i5-4200M
* RAM: 4GB
* Compiler: ldc2-0.16.0-alpha4-win64-msvc (LLVM 3.7.0)

念のため少し内容を解説しておくと，source/dfsが初期に書いたコードでsource/charlotteが本番で用いたコード。source/dfsのほうは色々ときたないので見ると頭がめうになりそう

charlotteの中身は，charlotte.dfsとcharlotte.mctsとcharlotte.guaranaがそれぞれ探索アルゴリズムで，その他は共通の型定義やアルゴリズム。

charlotte.dfsは単純な深さ優先探索で，本番では使わなかった。

charlotte.mctsは，中を見るとMCTSとMCとMCTSP(int N)の3つのクラスがある。MCは単純なモンテカルロ法(ランダム)，MCTSはモンテカルロ木探索。MCTSPはMCTSのプレイアウトを改良したもので，MCTSのプレイアウトは一つ次のノードを見つけるとすぐに遷移するが，MCTSPでは次のノードを一定数見つけたあと，その中から最良のノードへ遷移する。この次ノードを見つける数がテンプレート引数の Nである。Nが大きいほど良いプレイアウト結果が得られるが，その分重くなる。

charlotte.guaranaは本番一日目が終わった後(一回戦落ちして敗者復活戦行きが決まった)，一晩で書き上げたアルゴリズム。書いているときは何がなんだかよく分からなくなっていたが，改めて見ると多少ゴチャゴチャしているだけの貪欲法っぽい。ループするたびに次ノードを探す際の探索範囲が広くなっていく。
評価関数が2つほどあるが，特徴的なのはpossibilityZero関数の方。possibilityMapという(眠い頭で考えた)概念を使う。敷地内の全ての空き地について，今置こうとしている石からN個次の石の中で置ける可能性のある石の数を数える。このとき，置ける可能性が0の空き地は，少なくともN手以内には埋めることができないことがわかる。特にN手先が最後の石の場合は，絶対に埋めることのできない空き地となる。このような，"N手以内に置ける可能性が0の空き地"がより少ないノードを優先するという評価方法である。
この評価関数は，N手先までの全ての石について全ての置き方を試すので，だいぶ重い処理となる。このNという値は一回探索が終わってループするたびに大きくなっていく。コード中では，Nを"先読みする深さ"として"height"，次ノードを探す際の探索範囲の方を"width"と書いている。どうでもいいか。

本番では，始めにguaranaアルゴリズムを回し，良い解が出なくなってきたらMCTSP!(64)アルゴリズムに切り替える(source/app.d内に記述)ようにして臨んだ。どちらのアルゴリズムにも得手不得手があり，本番でも問題によっていい感じに切り替わってくれた(手動で切り替えたりもしたが…)。

なんでビームサーチにしなかったんだろうなぁ… (゜-゜)

## To build:

必要なもの:

  * dmd 2.067.0 or later (or other D compiler)
  * dub 0.9.22 or later
  * curl (windowsならchocolatey使えば cinst curl でおk)

以下を実行するとコンパイルされ自動で実行される:

```sh
dub
```

以下のコマンドだとコンパイル時最適化が行われる:

```sh
dub --build=release
```

LDC2を導入している環境だと以下が最速:

```sh
dub --build=release --compiler=ldc2
```

"dub"の代わりに"dub build"とするとコンパイルのみを行う。詳しくはdubのリファレンス等を参照。

## Usage

問題・回答の送受信方法について4つのモードを用意した。コマンドライン引数に --mode=local のように書いて指定できる。(dub使ってると指定できないっぽいので，dub build してから ./procon26 --mode=local のようにしてくだせえ)

- practice (デフォルト)
  - プロコン練習場の問題を解く。画面の指示に従い非公式・公式のどちらか選び，問題番号を入力すると，勝手に問題をダウンロードして解き始める。問題ファイルは./practice，解答ファイルは./answerに保存される。非公式はファイル名の頭に"u"，公式はファイル名の頭に"o"がつく。
- local
  - 問題ファイルのパスを直接指定する。回答ファイルは./answerに保存される。
- direct
  - 競技サーバーに直接接続することを想定した動作モード。競技サーバーから問題をGETして解答をPOSTする。問題ファイルは./problem，解答ファイルは./answerに保存される。
- canon
  - かのんサーバーを経由して接続することを想定した動作モード。かのんサーバーのAPIに合わせている以外はdirectと同じ。

## Memo (以下，開発中の独り言)

2015-05-24 15:25 現状，stone構造体とfield構造体を定義しただけ。実行してもテストコードが走るのみ。たんさくがんばる

2015-05-25 00:38 immutable構造体はオワコンらしいので構造体やめて素の配列にした。とりあえずMeuAI(愚直深さ優先探索)がひと通りできたっぽい。でもなんかコンパイル時最適化有効にすると結果変わるんだけど……不穏だめう

2015-07-26 20:31 どうしたらいいんだろうか(((((
初めに入力の盤面と石の大きさ・形などを解析して，この問題がどれくらいの規模か・極端に大きい石や複雑な石はないか・置ける場所が限られる石はないか，などを見極める。その情報を元に最適な探索アルゴリズムを回す。みたいな感じかなー

2015-08-25 20:49 とりあえず適当に書いた深さ優先探索のコードは隔離して，新しくちゃんと設計しつつ書き直す。いいモジュール名思いつかなかったからcharlotteにした

2015/09/23 17:01 charlotte.DFSを一通り実装した。対称な形の石では反転・回転動作を枝刈りするし，ノードを開く処理は並列化した。また，64bitでもコンパイルできるようにもした。ldc2-0.16.0-alpha4-win64-msvcでの動作を確認。dmdで32bitコンパイルするより3倍くらいはやい。これは強そうだ。

2015/09/23 22:36 ふと思いついてcharlotte.RandomBeamを実装した。非常に単純な乱択アルゴリズムだが，場合によっては割と使える事が判明。途中で探索を打ち切れば，解の方向性をざっと決めるのにも使えそう。(追記: (原始)モンテカルロ法，MCというアルゴリズムらしい。リネームした)

2015/10/04 17:50 モンテカルロ木探索を実装したり，コピペっぽいところを一つにまとめたりと色々もそもそした。ひとつ目の石から順に探索するだけでは限界が見えてきた。問題に含まれる石の中で特に配置が重要なものを検出して，そこから順に探索を進める感じのアプローチを考え中。

#### charlotteの設計メモ (最終更新: 2015/09/23)
- 型定義
  - charlotte.problemtypes
    - Stone型，Field型
      - 単純なbool型の配列で持つのが無難か?
      - int型等の配列にして探索中に色々なデータを持たせるのもアリか
  - charlotte.answertypes
    - Operation型
      - 回答データの一行分のデータと，ひとつ前のOperationへの参照を持つ。クラス。
    - Place型
      - 一つの石を置く場所を表す。flip[表，裏]，rotate[0，90，180，270]，x[-7~38]，y[-7~38] の構造体。
    - Rotation型
      - 回転角。deg0，deg90，deg180，deg270 の列挙型。
- Analyze
  - 対称な形の石は，異なる操作をしても同じ配置になることがある
    - よって，探索ノード数を削減できる
  - それぞれの石・敷地について，ずく数，近傍マス数，幅，...などの探索のヒントになりそうな値を求める
  - 求めた値はStoneAnalyzed構造体にまとめて保持する
  - 敷地を部分ごとに分解するとかも
- Search
  - DFS(深さ優先探索)
    - 再帰による実装だとスタックオーバーフローっぽいエラーが出て死んだので，スタックを用いた実装にした。以前と挙動が違うため，最初の回答が出てくるまでが遅い。
    - 一つのNodeから次のNodeを生成する処理が結構重いため，並列化が有効?
      - やってみたけどそんなに速くならないっぽい 目視1.5倍くらい
  - MC(原始モンテカルロ法)
    - 石を置けるところにランダムに置いていき，最後の石まで終わったらそれを回答とする。これを繰り返すのみ。バックトラック等の処理は行わない。
    - CPUのそれぞれのスレッドで独立に探索する。ハイスコアを更新する回答を見つけたらそれを出力する。
    - 細長い敷地の問題で割りと有効。
  - MCTS(モンテカルロ木探索)
    - 原始モンテカルロ法に木探索を組み合わせたアルゴリズム。詳しくはググるかSlackを参照。
    - 問題によっては非常に効果があるが，今回のプロコン問題とはあまり相性が良くないっぽい? プレイアウトに時間が掛かり過ぎて十分な試行回数が得られない
- Idea
  - 石を置く場所を決めるのに評価関数を導入する
  - 後ろから探索するとどうなる?
    - 条件が複雑になって死ぬ
  - 探索中，特にずく数が小さい石については配置を確定せず保留し，あとで隙間を埋めるのに使う
