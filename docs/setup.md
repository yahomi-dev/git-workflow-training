# 公開前の整え方 (進行役向け)

GitHub でこのキットを動かすまでの手順。設定値の根拠は [design.md](design.md) 8 節。
GitLab で使う場合は 6 節へ。

## 1. 手元の確認

```bash
scripts/playtest.sh                     # 演習 03〜10 を GitHub なしで通す (数十秒)
scripts/check-forbidden.sh --all        # 秘密らしき文字列が無いこと
npx --yes html-validate@9 "site/**/*.html"
scripts/seed-issues.sh --dry-run        # Issue 本文の描画が通ること
```

`CLAUDE.local.md` と `.claude-session-state.md` が `git status` に出ないこと (gitignore 済み) を見る。
README の冒頭 3 点 (研修用 / 受講者の名前が公開される / 組織固有の情報を入れない) を読み直す。
確認が済んだらコミットする (次の bootstrap は clean な作業ツリーを要求する)。

## 2. 一発で整える: `scripts/bootstrap.sh`

```bash
scripts/bootstrap.sh                          # 受講者が決まっていれば --trainee <ログイン名>
```

順に行うこと:

1. リポジトリを public で作って push する (remote origin が既にあればそれを使う)
2. NPC の **GitHub App を Manifest フローで作る**。ブラウザが開くので **Create GitHub App を押す** (クリック 1 回目)。App の ID と秘密鍵はスクリプトが受け取る
3. App をこのリポジトリに install する。ブラウザが開くので **Only select repositories でこのリポジトリを選び、Install を押す** (クリック 2 回目)。install されるまでスクリプトが待つ
4. secret `NPC_APP_ID` と `NPC_APP_PRIVATE_KEY` を登録する
5. `scripts/setup.sh` を呼ぶ (リポジトリ設定、ruleset `main`、`baseline` タグ、受講者の招待と `TRAINEE_LOGIN`、ラベルと Issue、進行ボード)

手作業はクリック 2 回。所要は 3 分ほど。

- App は進行役のアカウントに 1 つあればよい。`~/.config/git-workflow-training/npc-app.env` と `npc-app.pem` に保存され、次のリポジトリ (次の受講者を別リポジトリで迎えるとき) では install のクリックと secret の登録だけになる。鍵はリポジトリの外にあるのでコミットに混ざらない
- App の名前は GitHub 全体で一意。既定は `<自分のログイン名>-hidamari-colleague`。変えるなら `--app-name`
- 前提: `gh auth login` 済み (`workflow` scope が無ければ bootstrap が足す)、node 18 以上、jq
- 途中で止まったら再実行する。App を作った直後に止まって保存されなかったときだけ、GitHub の Settings > Developer settings > GitHub Apps でその App を消し、`--new-app` を付けて再実行する

## 3. 手で行う場合 (bootstrap が使えないとき)

### 3.1 リポジトリ

```bash
gh repo create <owner>/git-workflow-training --public --source . --push
```

### 3.2 GitHub App

GitHub の Settings > Developer settings > GitHub Apps > New GitHub App。

| 項目 | 値 |
|---|---|
| GitHub App name | 同僚役と分かる名前 (例: `<自分>-hidamari-colleague`)。表示は `<name>[bot]` になる |
| Homepage URL | このリポジトリの URL |
| Webhook | Active のチェックを外す |
| Repository permissions | Contents: Read and write / Pull requests: Read and write / Issues: Read and write / Metadata: Read-only (自動) |
| Where can this App be installed? | Only on this account |

作成後、**App ID** を控え、Private keys > Generate a private key で `.pem` をダウンロードし、Install App でこのリポジトリだけを選ぶ。

### 3.3 secret

```bash
gh secret set NPC_APP_ID --body <App ID>
gh secret set NPC_APP_PRIVATE_KEY < <ダウンロードした .pem>
```

### 3.4 設定と起票

```bash
scripts/setup.sh --platform github --app-id <App ID> --trainee <受講者のログイン名>
```

受講者がまだ決まっていなければ `--trainee` を省き、分かってから `gh variable set TRAINEE_LOGIN --body <ログイン名>` と Settings > Collaborators の招待を行う。

## 4. ruleset を UI で設定する値 (API が拒否したとき)

Settings > Rules > Rulesets。

| 項目 | 値 |
|---|---|
| Name / Enforcement | `main` / Active |
| Target branches | Default branch |
| Bypass list | Repository admin (For pull requests only)、NPC の App (Always) |
| Restrict deletions / Block force pushes | ON / ON |
| Require a pull request before merging | ON。Required approvals 1、Dismiss stale approvals ON、Require conversation resolution ON、Allowed merge methods: Squash / Rebase / Merge |
| Require status checks to pass | ON。`check` |

## 5. 動作確認 (煙テスト)

1. Issues の一番上に pin された **進行ボード** があり、演習の表と main の木が出ていることを見る
2. 手元から `git switch -c quest/04-smoke` -> `site/README.md` に 1 行足して push -> PR を開く
3. Actions で `check` が緑、`npc-review` が動いて NPC のコメントが 3 つ付き、`board` が動いてボードに枝と PR が出ることを見る
4. PR を close し、ブランチを消す (`quest/04-*` の push は演習 06 / 07 のパッチに触れないので、何度でもやり直せる)
5. Actions > npc-pr > Run workflow は実際の演習 08 まで動かさない (動かすと NPC のブランチが残る。消せばやり直せる)

## 6. GitLab で使う場合 (自動化は未実装)

```bash
scripts/setup.sh --platform gitlab
```

kit.conf と Issue の起票だけを行う。CI (`check`)、NPC の 3 イベント、進行ボード、protected branch の設定は未実装なので、[platform/gitlab.md](platform/gitlab.md) と [design.md](design.md) 15 節を見て手で行う。
