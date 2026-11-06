<!-- kit
title: quest-07: rebase で載せ替え、squash で 1 コミットにする
week: 2
-->
# quest-07: rebase で載せ替え、squash で 1 コミットにする

<!-- issue:start -->
## 状況

図書室の担当者から: 「今月のおすすめ本の 1 冊目を『図書室のまどから』に差し替えてください。作業は小さく刻んで commit してかまいません。ただし、{{pr}} はこのチームの約束で **1 コミットにまとめて** 出してください。」

同僚 (NPC) も 1 冊目を触っていて、また衝突します。今回は `git merge` ではなく **`git rebase`** で解消し、複数のコミットを **squash** で 1 つにして、ff できる状態で {{pr}} を出します。
最後に [4 つの動詞](../docs/merge-methods.md) を読んで、自分の言葉で説明を書きます。

## やること

1. ブランチを切る

   ```bash
   git switch main
   git pull
   git switch -c quest/07-replace-pick
   ```

2. **3 回に分けて commit** する (小さく刻む練習。中身より回数)
   - 1 回目: `site/index.html` のおすすめ本の 1 冊目 `『ひだまり通りの猫たち』` を `『図書室のまどかか』` にする (わざと誤字)。`git commit -m "おすすめ本の 1 冊目を差し替える"`
   - 2 回目: 誤字を直して `『図書室のまどから』` にする。`git commit -m "題名の誤字を直す"`
   - 3 回目: 同じ行の題名の後ろに ` (ひだまり文庫)` を足す。`git commit -m "出版社を添える"`

   `git log --oneline -4` で 3 つの commit が見えれば OK。

3. push して、同僚の変更が main に入るのを待つ (2〜3 分)

   ```bash
   git push -u origin quest/07-replace-pick
   git fetch origin
   git log --oneline origin/main -3
   ```

   「今月のおすすめ本の 1 冊目を差し替える」という同僚のコミットが見えれば OK。

4. **rebase** で自分の 3 コミットを main の先端に載せ替える

   ```bash
   git rebase origin/main
   ```

   1 回目の commit で `CONFLICT` が出る。`git status` を読む。

5. 衝突を解消する。この演習では **自分の側を採る** (担当者から依頼を受けているのは自分なので)。1 冊目の行を、自分の 1 回目の commit の内容 `<li>『図書室のまどかか』</li>` にし、マーカー 3 行を消す

   ```bash
   git add site/index.html
   git rebase --continue
   ```

   エディタが開いたら、そのまま保存して閉じる。2 回目と 3 回目の commit は自動で載る。`git log --oneline -5` で、自分の 3 コミットが同僚のコミットの上に並んでいれば OK。

6. ff できる状態かを確かめる

   ```bash
   git merge-base --is-ancestor origin/main HEAD && echo "ff できる"
   ```

7. **squash** で 3 コミットを 1 つにする

   ```bash
   git reset --soft origin/main
   git status
   git commit -m "おすすめ本の 1 冊目を『図書室のまどから』に差し替える"
   git log --oneline -3
   ```

   自分のコミットが 1 つだけになっていれば OK。

8. push する。履歴を書き換えたので、普通の push は拒否される。**`--force-with-lease`** を使う

   ```bash
   git push --force-with-lease
   ```

9. {{pr_long}} を作る (タイトル `quest-07: おすすめ本の 1 冊目を差し替える`、5 項目、`Closes #`)
   - 「相談したいこと」に、[4 つの動詞](../docs/merge-methods.md) を読んで **squash / rebase / ff / merge commit の違いを自分の言葉で** 4 行書く
   - Commits タブで commit が 1 つであることを確かめる
10. {{ci}} が緑になったらレビューを依頼し、{{approve}} の後に **{{rebase_merge}}** で取り込む (今回は squash ではなく、こちらを使う)
11. 取り込まれた後、main のコミットの SHA を見る

    ```bash
    git switch main
    git pull
    git log --oneline -3
    ```

    自分のコミットの SHA が、push したときと **変わっている** ことを確かめる (理由は 4 つの動詞に書いてある)。この出力を Issue にコメントする。ローカルの作業ブランチを消す

## 完了条件

- [ ] 衝突を `git rebase` で解消した (merge ではなく)
- [ ] {{pr}} の commit が 1 つだけになっている
- [ ] `git push --force-with-lease` を使い、`--force` との違いを Issue に 1 行で書いた
- [ ] {{pr}} 本文に 4 つの動詞の説明を自分の言葉で書いた
- [ ] {{rebase_merge}} で取り込み、SHA が変わったことを Issue にコメントした

## 参考

- [4 つの動詞](../docs/merge-methods.md)
- 途中でやめたいとき: `git rebase --abort` で rebase 前に戻る

## 詰まったら

rebase の途中で迷ったら `git status` を読む。「どのコミットを当てている途中か」が書いてある。それでも分からなければ `git rebase --abort` して進行役に聞く。
<!-- issue:end -->

<!-- notes:start -->
## 進行役メモ

- NPC (a) は `quest/07-*` の push で動き、`npc/quests/07/conflict.patch` (1 冊目を『春のおべんとう図鑑』に) を main に積む。動かなかったときの手当ては演習 06 の進行役メモと同じ (番号を 07 に)
- 手順 5 で「自分の側を採る」のは、演習 06 の「両方残す」との対比。どちらが正しいかは状況で決まる、と言葉にしてもらう
- 手順 7 の `git reset --soft origin/main` は「コミットをほどいて変更だけ残す」。`git status` で 3 コミット分の変更がステージに乗っていることを一緒に見る。`git rebase -i` で fixup する方法もあるが、ここでは教えない
- `--force-with-lease` は「自分が知らない間に誰かが push していたら止まる」。`--force` との違いを Issue に書いてもらう
- {{rebase_merge}} で取り込むと、ff できる状態でも SHA が書き換わる。手順 11 で実際に見せる。ここで「GitHub には純粋な ff のボタンが無い」ことに触れる
- レビューで見るもの: commit が 1 つか、4 つの動詞の説明が自分の言葉か (`docs/merge-methods.md` の丸写しなら `[Q]` で聞き直す)
- 到達チェック **G-4 / G-6 / T-5**
<!-- notes:end -->
