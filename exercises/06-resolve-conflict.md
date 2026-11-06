<!-- kit
title: quest-06: 衝突を解消する
week: 2
-->
# quest-06: 衝突を解消する

<!-- issue:start -->
## 状況

図書室の担当者から: 「土曜の閉館を 18:00 まで延ばすことになりました。開館時間の表の土曜行を `10:00〜18:00` にしてください。」

同じころ、別の同僚 (NPC) も土曜行を触っています。あなたが push すると、同僚の変更が main に入り、**衝突** します。
この演習は **対面 2** で、衝突の解消を進行役と一緒に行います。push までは 1 人で進めておいてください。

## やること

### 対面の前に (1 人で)

1. ブランチを切る

   ```bash
   git switch main
   git pull
   git switch -c quest/06-saturday-hours
   ```

2. `site/index.html` の開館時間の表、土曜行の `<td>10:00〜17:00</td>` を `<td>10:00〜18:00</td>` にする。**この行だけ** を変える
3. commit して push する

   ```bash
   git add site/index.html
   git commit -m "土曜の閉館時間を 18:00 に延ばす"
   git push -u origin quest/06-saturday-hours
   ```

4. 2〜3 分待ってから、main が進んだことを見る

   ```bash
   git fetch origin
   git log --oneline origin/main -3
   ```

   同僚 (NPC) の「開館時間の土曜行を冬季ダイヤに変更する」というコミットが見えれば OK。見えなければ進行役に連絡する。進行ボードの木でも、自分の枝が出た後に main が 1 つ進んだ形になっている (これが衝突の原因)

### 対面で (進行役と)

5. main の変更を自分のブランチに取り込む

   ```bash
   git merge origin/main
   ```

   `CONFLICT (content): Merge conflict in site/index.html` と出る。**この出力をこの Issue にコメント**する

6. `git status` を読む。`both modified: site/index.html` が衝突しているファイル
7. `site/index.html` を開き、衝突マーカーを探す

   ```text
   <<<<<<< HEAD
   (自分の変更)
   =======
   (同僚の変更)
   >>>>>>> origin/main
   ```

8. **両方の意図を残す** 形に書き直す。マーカーの 3 行 (`<<<<<<<`、`=======`、`>>>>>>>`) は消す

   ```html
   <td>10:00〜18:00 (12 月〜2 月は 16:00 まで)</td>
   ```

9. 解消を記録して push する

   ```bash
   git add site/index.html
   git commit
   git log --oneline --graph -5
   git push
   ```

   `git commit` でエディタが開く。メッセージはそのままで保存して閉じる

10. {{pr_long}} を作る (タイトル `quest-06: 土曜の閉館時間を 18:00 に延ばす`、5 項目、`Closes #`)。「相談したいこと」に、解消で迷った点を書く
11. {{ci}} が緑になったらレビューを依頼し、{{approve}} の後に {{squash_merge}} でマージ。ローカルを掃除する

## 完了条件

- [ ] 衝突が起きたときの出力を Issue にコメントした
- [ ] 解消後の土曜行が、自分の変更 (18:00) と同僚の変更 (冬季 16:00) の両方を含む
- [ ] `git log --oneline --graph -5` の出力を Issue にコメントした
- [ ] {{pr}} をマージし、ローカルの main を pull して作業ブランチを消した

## 参考

- [4 つの動詞](../docs/merge-methods.md) の「merge commit 合流点を作る」
- 途中でやめたいとき: `git merge --abort` で merge 前に戻る

## 詰まったら

対面中なので進行役に聞く。マーカーが残ったまま commit してしまったら、直してもう 1 回 commit すればよい。
<!-- issue:end -->

<!-- notes:start -->
## 進行役メモ

- **対面 2 (1 時間)**: 手順 1〜4 は事前に 1 人で。対面では 5〜9 を一緒に (30 分)、残りで「なぜ衝突するのか」をコミットグラフで説明し、`git merge --abort` も一度試す
- NPC (a) は `quest/06-*` の push で動き、`npc/quests/06/conflict.patch` を main に積む。確認は Actions の `npc-conflict`
- NPC が動かなかったとき: 進行役が手で積む。`git switch -c npc-manual/06 origin/main && git apply npc/quests/06/conflict.patch && git commit -a -F npc/quests/06/conflict-message.txt && git push -u origin npc-manual/06` の後、{{pr}} を作って `gh pr merge --squash --admin` (進行役は {{pr}} 経由の bypass を持つ)
- 衝突しなかったとき: 受講者が別の行を変えている。Issue のとおりの行に直してもらい (commit を追加)、もう一度 `git merge origin/main`。NPC のコミットは既に main にあるので、同じ行なら衝突する
- 解消の方針は「両方の意図を残す」。片方を消して終わらせないこと。ここが演習 07 (自分の側を採る) との対比になる
- 到達チェック **G-3**
<!-- notes:end -->
