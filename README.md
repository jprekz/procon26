# procon26

かいはつちう

## To build:

必要なもの:

  * dmd 2.067.0 or later
  * dub 0.9.22 or later

以下を実行するとコンパイルされ自動で実行される:

```sh
dub
```

以下のコマンドだとコンパイル時最適化が行われる:

```sh
dub --build=release
```

詳しくはdubのリファレンス等を参照。

## Memo

2015-05-24 15:25 現状, stone構造体とfield構造体を定義しただけ。実行してもテストコードが走るのみ。たんさくがんばる

2015-05-25 00:38 immutable構造体はオワコンらしいので構造体やめて素の配列にした。とりあえずMeuAI(愚直深さ優先探索)がひと通りできたっぽい。でもなんかコンパイル時最適化有効にすると結果変わるんだけど……不穏だめう

2015-07-26 20:31 どうしたらいいんだろうか(((((
初めに入力の盤面と石の大きさ・形などを解析して, この問題がどれくらいの規模か・極端に大きい石や複雑な石はないか・置ける場所が限られる石はないか, などを見極める。その情報を元に最適な探索アルゴリズムを回す。みたいな感じかなー

2015-08-25 20:49 とりあえず適当に書いた深さ優先探索のコードは隔離して, 新しくちゃんと設計しつつ書き直す。いいモジュール名思いつかなかったからcharlotteにした

#### charlotteの設計メモ (最終更新: 2015/09/18)
- 型定義
  - charlotte.problemtypes
    - Stone型, Field型
      - 単純なbool型の配列で持つのが無難か?
      - int型等の配列にして探索中に色々なデータを持たせるのもアリか
  - charlotte.answertypes
    - Operation型
      - 回答データの一行分のデータと, ひとつ前のOperationへの参照を持つ。クラス。
    - Place型
      - 一つの石を置く場所を表す。flip[表, 裏], rotate[0, 90, 180, 270], x[-7~38], y[-7~38] の構造体。
    - Rotation型
      - 回転角。deg0, deg90, deg180, deg270 の列挙型。
- Analyze
  - すべての石をnormalizeする
    - 石を左上に揃え, 石の幅と高さを求め, 横長になるよう回転する
    - normalizeしたあとのStoneとその配置となるPlaceを返す
  - 対称な形の石は, 異なる操作をしても同じ配置になることがある
    - よって, 探索範囲を縮小できる
      - normalizeと一緒に処理?
  - それぞれの石・敷地について, ずく数, 近傍マス数, 幅, ...などの探索のヒントになりそうな値を求める。
  - 求めた値はどう保持する?
  - 敷地を部分ごとに分解するとかも
- Search
  - DFS(再実装することになるが一応。以前のコードは妙なバグが有る)
    - 再帰による実装だとスタックオーバーフローっぽいエラーが出て死んだので, スタックを用いた実装にした。以前と挙動が違うため, 最初の回答が出てくるまでが遅い。
