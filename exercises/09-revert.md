<!-- kit
title: quest-09: マージ済みの変更を revert で取り消す
week: 3
-->
# quest-09: マージ済みの変更を revert で取り消す

<!-- issue:start -->
## 状況

図書室の担当者から: 「すみません、『図書室のまどから』はまだ入荷していませんでした。演習 07 で入れた差し替えを取り消して、元に戻してください。」

マージ済みの変更を、履歴を消さずに **打ち消すコミット** で戻します。

## やること

1. 取り消す対象のコミットを見つける

   ```bash
   git switch main
   git pull
   git log --oneline -6
   ```

   演習 07 で取り込んだ「おすすめ本の 1 冊目を『図書室のまどから』に差し替える」の SHA (先頭 7 文字) を控える

2. ブランチを切って revert する

   ```bash
   git switch -c quest/09-revert-pick
   git revert <控えた SHA>
   ```

   エディタが開く。メッセージはそのまま (`Revert "..."`) で保存して閉じる。

3. 結果を確かめる

   ```bash
   git log --oneline -3
   git diff main
   ```

   `site/index.html` の 1 冊目が『春のおべんとう図鑑』(同僚が入れていたもの) に戻っていれば OK。ブラウザでも見る

4. push して {{pr_long}} を作る

   ```bash
   git push -u origin quest/09-revert-pick
   ```

   タイトル `quest-09: おすすめ本の差し替えを取り消す`。本文の「意図」に **元の {{pr}} の番号と SHA** を書く。`Closes #`

5. {{ci}} が緑になったらレビューを依頼し、{{approve}} の後に {{squash_merge}} でマージ。ローカルを掃除する
6. (見るだけ) 演習 07 の {{pr}} のページを開き、{{revert_button}} がどこにあるか確かめる。押すと同じことを {{platform}} が代わりにやってくれる (ブランチと {{pr}} が自動で作られる)。押した場合は、作られた {{pr}} を close してブランチを消す

## 完了条件

- [ ] `git revert` で作ったコミットを含む {{pr}} をマージした
- [ ] main の `site/index.html` の 1 冊目が『春のおべんとう図鑑』に戻っている
- [ ] {{pr}} 本文に、元の {{pr}} の番号と SHA が書いてある
- [ ] `git log --oneline -3` の出力を Issue にコメントした

## 参考

- revert は「過去を消す」のではなく「打ち消す変更を新しく積む」。履歴は残る。これが `reset --hard` や force push と違うところ

## 詰まったら

`git revert` の途中で衝突したら、演習 06 と同じように解消して `git revert --continue`。やめるなら `git revert --abort`。
<!-- issue:end -->

<!-- notes:start -->
## 進行役メモ

- この Issue は演習 07 の {{pr}} がマージされてから案内する (対象が無いと始められない)
- 手順 2 でエディタが開いて抜けられない受講者が多い。`core.editor` が未設定なら nano か vim が開く。`git config --global core.editor "code --wait"` を演習 02 で入れてあれば VS Code が開く
- レビューで見るもの: revert コミットが 1 つで、他の変更が混ざっていないか。本文に元の {{pr}} 番号と SHA があるか (「何を打ち消したか」が履歴から辿れる)
- 到達チェック **G-5**
<!-- notes:end -->
