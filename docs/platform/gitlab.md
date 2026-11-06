# GitLab での操作の 1 枚

この研修キットの GitLab 版は自動化 (CI の `check`、NPC) が未実装。ここでは用語と操作の対応だけを示す。
受講者向け。GitHub 版の [github.md](github.md) を先に読み、違うところをこの 1 枚で差し替える。
用語: MR (merge request。GitHub の PR と同じもの)。この 1 枚では GitLab の画面に合わせて MR と書く。

## 用語の対応

| GitHub | GitLab |
|---|---|
| Pull request (PR) | Merge request (MR) |
| Actions / Checks | CI/CD / Pipelines |
| Ruleset (main を守る規則) | Protected branches (役割で決まる) |
| Collaborator (Write) | Member (Developer) |
| Tags / Releases | Tags / Releases (同じ) |
| `gh` | `glab` |

## アカウント

- 2FA: 右上のアバター > Edit profile > Account > Two-factor authentication を Enable。認証アプリ推奨。リカバリコードを保存する
- コミット用メール: Edit profile > Commit email で `Use a private email` を選ぶ。`<ID>-<ユーザ名>@users.noreply.<GitLab のホスト>` が表示される。これを `git config --global user.email` に入れる
- 招待: メールまたは通知から Accept
  - 確かめ方: プロジェクトの左メニュー Manage > Members に自分が `Developer` で載っている

## MR を作る

ブランチを push すると、ターミナルに `remote: To create a merge request for quest/NN-..., visit:` と URL が出る。

| やり方 | 操作 | 補足 |
|---|---|---|
| ブラウザ | push 後に出た URL を開く。または Code > Merge requests > New merge request | 本文の `Choose a template` でテンプレートを選ぶ |
| `glab` | `glab mr create --fill` | タイトルと本文をコミットから作る。テンプレートは入らないので本文を後で編集する |

MR テンプレートは `.gitlab/merge_request_templates/<名前>.md` に置かれる。`Default.md` があれば自動で入る。無ければ `Choose a template` で選ぶ。

確かめ方: `glab mr view` で今のブランチの MR が `!<番号>` 付きで表示される。

## レビュー

- Changes タブ: 差分。行番号にマウスを乗せると出る吹き出しで行コメント。複数付けるなら `Start a review` でまとめ、`Submit review` で送る
- スレッド: 返信欄に「直した / 直さない理由 / 質問」を書き、直したら `Resolve thread`
  - プロジェクト設定で "All threads must be resolved" が ON なら、未解決があるとマージできない
- Approve: MR 上部の `Approve` ボタン。Free では approve は任意で、必須にはできない (必須にできるのは Premium 以上)。「approve が付くまでマージしない」はチーム内の約束として守る
- Request changes: `Submit review` の選択肢にある。ただし Free では押してもマージを止めない (止めるのは Premium 以上)。差し戻しは「未解決スレッドを残す」で表し、スレッドの先頭に `差し戻し:` と書く
- 再依頼: 右側 Reviewers のレビュア名の横の矢印 (Request re-review)

## マージ方式

プロジェクト設定 Settings > Merge requests の `Merge method` で決まる。MR ごとには選べない。

| Merge method | 4 つの動詞との対応 ([merge-methods.md](../merge-methods.md)) |
|---|---|
| Merge commit | merge commit |
| Merge commit with semi-linear history | ff できる状態を要求してから merge commit。遅れていると MR に `Rebase` ボタンが出る |
| Fast-forward merge | ff。遅れていると MR に `Rebase` ボタンが出る |

squash は MR の `Squash commits` チェックボックス。既定は同じ設定ページの `Squash commits when merging` (Do not allow / Allow / Encourage / Require)。

マージ後のローカルの掃除は GitHub と同じ (`git switch main && git pull && git branch -d <branch>`、`git fetch --prune`)。
MR の `Delete source branch` にチェックが付いていればリモートのブランチは消える。

## main に直接 push すると

protected branch は役割で決まる。既定では `main` に push できるのは Maintainer だけで、Developer は MR 経由になる。

    remote: GitLab: You are not allowed to push code to protected branches on this project.
     ! [remote rejected] main -> main (pre-receive hook declined)

読み方: `pre-receive hook declined` が「サーバ側の規則で拒否された」の印。その上の `remote: GitLab:` の行が理由。
直し方は GitHub と同じ。ブランチを切って push し、MR を出す。

## CI/CD (Pipelines) を見る

- MR のページ上部に Pipeline の状態 (passed / failed / running) が出る。Pipelines タブで一覧
- 赤いとき: Pipeline の番号 -> 赤いジョブをクリック -> ログの末尾から `ERROR` を探す。右上の `Retry` で再実行
- ターミナルからは `glab ci status` で見られる
- この研修キットの GitLab 版には `.gitlab-ci.yml` が無いので、Pipeline は動かない

## revert、タグ、Release

- Revert: マージ済み MR のページの `Revert` ボタン。打ち消しの MR が自動で作られる。ローカルでやるなら `git revert <SHA>`
- タグ: GitHub と同じ

      git tag -a v1.0.0 -m "初回リリース" && git push origin v1.0.0

- Release:

      glab release create v1.0.0 --notes "初回リリース"

  確かめ方: プロジェクトの左メニュー Deploy > Releases に `v1.0.0` が出る

## よく使う glab

| コマンド | 何が分かる / できる |
|---|---|
| `glab auth login` / `glab auth status` | ログインと確認。自社ホストの GitLab は `--hostname <ホスト>` を付ける |
| `glab mr list` | 開いている MR の一覧 |
| `glab mr view --web` | 今のブランチの MR をブラウザで開く |
| `glab mr checkout <番号>` | 他人の MR のブランチをローカルに持ってくる |
| `glab issue list` | 開いている Issue の一覧 |
| `glab ci status` | 今のブランチの Pipeline の状態 |
