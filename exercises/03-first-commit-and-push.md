<!-- kit
title: quest-03: 最初の commit と push をする
week: 1
-->
# quest-03: 最初の commit と push をする

<!-- issue:start -->
## 状況

図書室の担当者から: 「サイトの README の『編集メンバー』に、あなたのログイン名を足しておいてください。」

小さな変更を 1 つ、commit して push し、{{pr}} で main に入れるまでを通します。
途中で **わざと main に直接 push して、拒否される** ところを見ます。

## やること

1. 最新の main にいることを確かめる

   ```bash
   git switch main
   git pull
   git status
   ```

   `nothing to commit, working tree clean` と出れば OK。

2. `site/README.md` の「編集メンバー」の下に、自分のログイン名を 1 行足す (`- <ログイン名>`)
3. 変更を確認して commit する

   ```bash
   git status
   git diff
   git add site/README.md
   git commit -m "編集メンバーに自分を追加する"
   git log --oneline -3
   ```

4. **main に直接 push してみる**

   ```bash
   git push origin main
   ```

   拒否される。エラーに `{{push_rejected}}` の文言が出る。**エラーの最初の数行をこの Issue にコメント**し、なぜ拒否されたと思うかを 1 行で書く

5. 今の commit をブランチに載せ替える。commit はそのままブランチに付いてくる

   ```bash
   git switch -c quest/03-add-member
   git log --oneline -3
   ```

6. ローカルの main を origin と同じ状態に戻す (main は自分で進めない)

   ```bash
   git switch main
   git reset --hard origin/main
   git switch quest/03-add-member
   ```

7. ブランチを push する

   ```bash
   git push -u origin quest/03-add-member
   ```

   ブラウザでリポジトリを開き、Branches に `quest/03-add-member` が出ていれば OK。Issues の一番上の **進行ボード** にも、main から横に出た自分の枝が描かれる (1〜2 分で更新される)。

8. {{pr_long}} を作る。{{pr_create}}。タイトルは `quest-03: 編集メンバーに自分を追加する`。本文はテンプレートの 5 項目を短く埋め、`Closes #<この Issue の番号>` を書く
9. {{ci}} の `check` が緑になるのを待つ ({{ci_tab}})。進行役にレビューを依頼する (Reviewers に進行役を指定)
10. 進行役の {{approve}} が付いたら、**{{squash_merge}}** でマージする
11. ローカルを掃除する

    ```bash
    git switch main
    git pull
    git branch -d quest/03-add-member
    git log --oneline -3
    ```

## 完了条件

- [ ] main への直接 push が拒否されたエラーを Issue にコメントし、理由を 1 行で書いた
- [ ] `quest/03-add-member` ブランチが {{platform}} に見える
- [ ] {{pr}} のタイトルが `quest-03:` で始まり、本文に `Closes #` がある
- [ ] 進行役の {{approve}} の後に {{squash_merge}} でマージし、main の `site/README.md` に自分のログイン名がある
- [ ] ローカルの main を pull し、作業ブランチを消した

## 参考

- [{{platform}} での操作の 1 枚](../{{platform_doc}})
- [4 つの動詞](../docs/merge-methods.md) (今は「squash まとめる」だけ読めばよい)

## 詰まったら

- `git status` の出力を添えて進行役に聞く。30 分で聞く
- 手順 11 の `git branch -d` で `warning: deleting branch ... not yet merged to HEAD` と出ても、ブランチが消えていれば OK ({{squash_merge}} で入れたので、ローカルの commit と main の commit は別物になっている)。`error: The branch ... is not fully merged` で止まったら `git branch -D <ブランチ名>` で消す
<!-- issue:end -->

<!-- notes:start -->
## 進行役メモ

- main の保護 ({{protected}}) が効いていれば手順 4 で拒否される。拒否されなかったら設定を確認する (`docs/setup.md` 5 節の表)
- 手順 6 の `git reset --hard origin/main` は「ローカルの main を origin と同じにする」操作。commit は quest ブランチに残っていることを `git log` で一緒に見る。受講者が怖がるので、何が消えて何が残るかを言葉にしてもらう
- レビューは軽くてよい。見るのは、タイトルの形、`Closes #`、diff が 1 行であること。コメントは `[NITS]` 1 つまで。{{approve}} してマージは受講者にさせる
- このブランチは `quest/03-*` なので NPC は動かない (パッチもレビューコメントも 03 には無い)
- 到達チェック **G-1 / G-2 / H-2**
<!-- notes:end -->
