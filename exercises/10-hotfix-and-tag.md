<!-- kit
title: quest-10: hotfix を入れてタグを打つ
week: 3
-->
# quest-10: hotfix を入れてタグを打つ

<!-- quest:start -->
## 状況

図書室の担当者から: 「今日の状態を `v1.0.0` として記録しておいてください。」
その直後、利用者から連絡: 「フッタの『アクセス』を押しても何も開きません。」

今日の状態にタグを打ち、急ぎの修正 (hotfix) を **main から切ったブランチ** で最短で入れ、`v1.0.1` のタグと Release を作ります。
急いでいても {{pr}} 経由で入れるのは変わりません。

## やること

1. 今の main に `v1.0.0` を打つ

   ```bash
   git switch main
   git pull
   git tag -a v1.0.0 -m "初回リリース"
   git push origin v1.0.0
   ```

   {{platform}} の Tags に `v1.0.0` が出れば OK。

2. 原因を見る。`site/index.html` のフッタに `<a href="access.html">アクセス</a>` があるが、`access.html` は存在しない
3. hotfix ブランチを **main から** 切る

   ```bash
   git switch -c hotfix/access-link
   ```

4. 直す。リンク先を同じページ内の説明に向け、説明を足す
   - `<a href="access.html">アクセス</a>` を `<a href="#access">アクセス</a>` にする
   - `<p class="site-note">` の **直前** に 1 行足す

     ```html
     <p id="access" class="access">アクセス: ひだまり通り 1-2-3 (架空の住所)。バス停「ひだまり通り」からすぐ。</p>
     ```

   ブラウザで開き、「アクセス」を押すと説明の場所に移動することを確かめる

5. commit して push し、{{pr_long}} を作る

   ```bash
   git add site/index.html
   git commit -m "hotfix: フッタのアクセスのリンク切れを直す"
   git push -u origin hotfix/access-link
   ```

   タイトル `hotfix: フッタのアクセスのリンク切れを直す`。先頭行は `クエスト: quest-10`。本文の「影響範囲」はフッタのみ

6. {{ci}} が緑になったらレビューを依頼し、{{approve}} の後に {{squash_merge}} でマージ
7. `v1.0.1` を打ち、Release を作る

   ```bash
   git switch main
   git pull
   git tag -a v1.0.1 -m "hotfix: アクセスのリンク切れを直した"
   git push origin v1.0.1
   git log --oneline --decorate -3
   ```

<!-- platform:github -->
   ```bash
   gh release create v1.0.1 --title "v1.0.1" --notes "フッタのアクセスのリンク切れを直した"
   ```
<!-- /platform -->
<!-- platform:gitlab -->
   ```bash
   glab release create v1.0.1 --name "v1.0.1" --notes "フッタのアクセスのリンク切れを直した"
   ```
<!-- /platform -->

   {{release}} に `v1.0.1` が出れば OK。`git log --oneline --decorate -3` の出力をゲーム画面の 10 のメモに貼る。ローカルの作業ブランチを消す

## 完了条件

hotfix の {{pr}} がマージされ、タグ `v1.0.0` と `v1.0.1` が push されると、ゲーム画面がこの演習を自動で済にする。

- [ ] `git ls-remote --tags origin` に `v1.0.0` と `v1.0.1` がある
- [ ] hotfix の {{pr}} が main から切ったブランチで、{{pr}} 経由でマージされた
- [ ] ブラウザで「アクセス」のリンクが動く
- [ ] Release `v1.0.1` がある
- [ ] `git log --oneline --decorate -3` の出力をゲーム画面の 10 のメモに貼った

## 参考

- [4 つの動詞](../docs/merge-methods.md)
- タグは「このコミットに名前を付ける」。`-a` (annotated) を付けると誰がいつ打ったかが残る

## 詰まったら

タグを間違えて打ったら `git tag -d v1.0.1` (ローカル) と `git push origin --delete v1.0.1` (リモート) で消してやり直せる。Release を作った後なら Release も消す。
<!-- quest:end -->

<!-- notes:start -->
## 進行役メモ

- 不具合 (`access.html` へのリンク切れ) は baseline から仕込んである。この演習の依頼文で初めて報告する (それまでの演習では触れない)
- hotfix でもルールを変えない (保護された main、{{pr}}、レビュー)。現場では hotfix 用の別ルール (レビュー省略、専用ブランチ) があることも多い。「初日に聞くこと」につなげる
- `hotfix/` ブランチでは NPC は動かない (NPC は `quest/` だけを見る)
- レビューで見るもの: 変更がフッタに閉じているか、ついでの修正が混ざっていないか、「影響範囲」が実態と合っているか
- 到達チェック **T-6**。ゲーム画面で済になったら進行役は手元の記録に達成日を書く
<!-- notes:end -->
