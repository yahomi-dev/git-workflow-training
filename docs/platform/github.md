# GitHub での操作の 1 枚

受講者向け。この研修で使う GitHub の画面と `gh` の操作を、演習に出てくる順に並べた。
用語: PR (pull request。GitLab では MR)、Actions (CI)、ruleset (main を守る規則)。

## アカウント (演習 01)

1. 2FA: 右上のアバター > Settings > Password and authentication > Two-factor authentication を Enable。認証アプリを推奨。リカバリコードは保存する
   - 確かめ方: 同じページに `Two-factor authentication is enabled` と出る
2. メールの非公開: Settings > Emails で "Keep my email addresses private" と "Block command line pushes that expose my email" の両方にチェック
   - 確かめ方: チェックの下に `<ID>+<ログイン名>@users.noreply.github.com` が表示される。これが git の `user.email` に入れる noreply アドレス ([wsl2-setup.md](../wsl2-setup.md) 5 節)
3. 招待の受諾: 進行役からの collaborator 招待を、メールまたは `https://github.com/<owner>/<repo>/invitations` から Accept
   - 確かめ方: リポジトリの Issue を開くと、右側の Assignees に自分を選べる

## PR を作る (演習 03 から)

ブランチを push すると、ターミナルに `Create a pull request for 'quest/NN-...' on GitHub by visiting:` と URL が出る。
作り方は 3 つ。この研修ではテンプレートが入る上の 2 つを使う。

| やり方 | コマンド / 操作 | 補足 |
|---|---|---|
| ブラウザ | push 後にリポジトリを開くと出る黄色い帯の `Compare & pull request` | テンプレートの 5 項目が本文に自動で入る |
| `gh` + ブラウザ | `gh pr create --web` | ブランチと base を埋めた状態でブラウザが開く。テンプレートが入る |
| `gh` だけ | `gh pr create --fill` | タイトルと本文をコミットメッセージから作る。テンプレートは入らない |

確かめ方: `gh pr status` の `Current branch` に `#<番号>` 付きで PR が出る。

テンプレート (`.github/PULL_REQUEST_TEMPLATE.md`) の 5 項目 (意図 / 変更内容 / 影響範囲 / 確認方法 / 相談したいこと) と `Closes #<Issue 番号>` を埋める。
`Closes` を書くと、マージ時に Issue が自動で閉じる。

## レビューを受ける / する (演習 04、05、08)

- Files changed タブ: 差分。行番号の左に出る `+` で行コメントを付ける。複数付けるなら `Start a review` でまとめ、最後に送る
- Review changes (右上の緑のボタン) の 3 択:
  - Comment: 意見だけ。マージを止めない
  - Approve: 承認。この研修では進行役の approve 1 つでマージできる
  - Request changes: 差し戻し。直して再依頼するまでマージできない
- 返し方: コメントの返信欄に「直した (コミットの SHA)」「直さない理由」「質問」のどれかを書く。直したら `Resolve conversation` を押す
  - 確かめ方: スレッドが折りたたまれ `Resolved` と出る。未解決が残るとマージボタンが灰色のまま (会話の解決が必須)
- 再依頼: 右側 Reviewers のレビュア名の横の回転矢印 (Re-request review)。Request changes を受けたら、修正を push した後に必ず押す
  - 確かめ方: レビュア名の横が黄色い点 (Awaiting) に変わる

## マージする (演習 04 から)

マージボタンの 3 択 (Squash and merge / Rebase and merge / Create a merge commit) の違いは [merge-methods.md](../merge-methods.md)。この研修の既定は Squash and merge。

マージすると head ブランチはリポジトリ設定で自動削除される。ローカルは自分で掃除する。

    git switch main && git pull && git branch -d quest/NN-xxx

確かめ方: `Deleted branch quest/NN-xxx` と出る。

    git fetch --prune

確かめ方: `- [deleted] (none) -> origin/quest/NN-xxx` と出る。`git branch -a` にそのブランチが無い。

## main に直接 push すると (演習 03)

main は ruleset で守られている。直接 push するとこう拒否される。

    remote: error: GH013: Repository rule violations found for refs/heads/main.
    remote: - Changes must be made through a pull request.
     ! [remote rejected] main -> main (push declined due to repository rule violations)

読み方: `GH013` が「リポジトリの規則に違反した」の印。`- ` で始まる行が破った規則 (複数出ることもある)。
直し方: ブランチを切って push し、PR を出す。

    git switch -c quest/03-xxx && git push -u origin quest/03-xxx

確かめ方: `branch 'quest/03-xxx' set up to track 'origin/quest/03-xxx'` と出る。

## CI (Actions) を見る (演習 04、05)

- PR の下部に `check` のステータスが出る。緑のチェックで通過、赤い x で失敗、黄色の点で実行中
- 赤いとき: `Details` (または PR の Checks タブ) -> 左のジョブ名 `check` -> 赤い x の付いた step を開く -> `error` を含む行を探す。その行にファイル名と行番号が出る
- 直して push すると自動で再実行される。手で再実行するなら右上 `Re-run jobs`
- ターミナルからは `gh pr checks` で同じものが見られる

## revert、タグ、Release (演習 09、10)

- Revert: マージ済み PR のページ下部の `Revert` ボタン。打ち消しの PR が自動で作られる。ローカルでやるなら `git revert <SHA>`
- タグ (annotated):

      git tag -a v1.0.0 -m "初回リリース" && git push origin v1.0.0

  確かめ方: `git tag -n` に `v1.0.0  初回リリース` が出る。リポジトリの Tags ページにも出る

- Release:

      gh release create v1.0.0 --generate-notes

  確かめ方: Release の URL が表示される。開くと、マージ済み PR の一覧がリリースノートに入っている

## よく使う gh

| コマンド | 何が分かる / できる |
|---|---|
| `gh pr status` | 自分の PR、レビュー待ちの PR、今のブランチの PR |
| `gh pr view --web` | 今のブランチの PR をブラウザで開く |
| `gh pr checkout <番号>` | 他人の PR のブランチをローカルに持ってくる (演習 08 で NPC の PR を見るとき) |
| `gh pr checks` | 今の PR の CI の結果 |
| `gh issue list` | 開いている Issue の一覧 (`--label quest` で演習だけ) |
| `gh repo view --web` | リポジトリをブラウザで開く |
