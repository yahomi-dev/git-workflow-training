# 研修キットの設計

2026-11-06 初版。このキットを作る人・直す人・次の受講者に回す進行役が読む。
受講者はこの文書を読まなくてよい (読んでも害はない。ただし `npc/answers/` は演習 08 を終えるまで開かない)。
到達チェックは [goals.md](goals.md) に分けてある。

## 1. 前提 (決定済み、この文書では再検討しない)

- 舞台は **GitHub**。PR、Actions、Pages、`gh` CLI を使う
- 教えるのは **Git と WSL2**。Docker は「用意された compose を動かす」サイドクエストに留める
- 受講者 1 人に対してチームがいるように見せる役は、GitHub の中の **NPC** (自動化された同僚役) が担う。自動化は 3 イベントまでで増やさない
- 進め方の UI は **Web のゲーム画面** (GitHub Pages の静的サイト、見る専用。16 節)。操作そのもの (git、PR、レビュー) はターミナルと GitHub で行う。**Issue は使わない** (2026-11-06 変更。元は「Web UI は作らない」「Issue 1 件 = 演習 1 本」だったが、Issue の運用は案件で変わる比率が大きく、Git の使い方に焦点を当てるため)
- 砂場は **小さな静的サイト 1 つ**。学ぶ対象は流れであってアプリではない
- 演習は 12 本 (砂場 11 + 実タスク 1)。受講者はゲーム画面で読む
- マージ方式は **Squash and merge を既定** にし、4 つの動詞 (squash まとめる / rebase 載せ替える / ff 印を進めるだけ / merge commit 合流点を作る) で違いを教える
- ブランチ運用は **GitHub Flow** (topic -> PR -> main)。git-flow は名前と「現場で使われていたら聞く」だけ
- レビューは組織のレビュー観点集 (ID 付き) で返す。public 側に置くのは **ID と一般的な言い換えだけ**
- PR 説明文は 5 項目 (意図 / 変更内容 / 影響範囲 / 確認方法 / 相談したいこと)
- **非同期が既定**。受講者は 1 人で進め、進行役は PR を 1 営業日以内に返す。対面は 4 回 x 1h
- 前半は砂場、後半は受講者の実プロジェクトで同じ流れを通す
- 進行役個人の流儀 (個人設定、特定の型やライブラリ) を持ち込まない。現場で通用する最小を教える
- 置き場は進行役の個人アカウント配下の **public リポジトリ** (無料プランで ruleset と Actions を使うため)
- **プラットフォームはフラグで選ぶ** (2026-11-06 追加)。`kit.conf` の `PLATFORM=github|gitlab` を `scripts/setup.sh --platform` が書き、演習の用語 (PR / MR、gh / glab) は起票時に描画する。初回の実施は GitHub。GitLab 版の自動化は未実装 (15 節)

## 2. 到達チェック

[goals.md](goals.md)。WSL2 / Git 基本 / チーム開発 / GitHub 固有の 4 群 20 行。
各行は「1 つの演習の完了条件で確かめられる粒度」で書いた。達成日の記録は進行役が手元に持つ (10 節)。

## 3. 演習一覧と順序

受講者はゲーム画面でクエストを読み、ブランチを `quest/NN-<slug>` で切り、PR タイトルを `quest-NN: <動詞で終わる要約>`、PR 本文の先頭を `クエスト: quest-NN` にする。
進捗はゲーム画面が GitHub の状態から判定する: `quest/NN-*` の PR がマージされれば NN が済、`hotfix/*` のマージとタグ v1.0.0 / v1.0.1 で 10 が済、NPC の PR に人が Request changes を出せば 08 が済。PR の無い 01 / 02 / 11 / 12 は、完了条件のチェックを全部付けると済 (ブラウザに保存)。

| # | 演習 | 完了条件 (受講者が 1 人で) | 想定 | NPC | 形式 | 週 |
|---|---|---|---|---|---|---|
| 01 | GitHub アカウントと 2FA | 2FA 有効。メール非公開 (noreply) と「メールが露出する push をブロック」が ON。collaborator 招待を受諾。public で名前と commit が見えることを了承 | 1h | - | 非同期 | W1 |
| 02 | WSL2 と clone | Ubuntu 上で `git config` 3 点、`gh auth login`、VS Code の WSL 接続、`~/src/` 配下へ clone、`git log --oneline` が見える | 2h | - | 対面 1 | W1 |
| 03 | 最初の commit と push | main へ直接 push して拒否される体験 -> `quest/03-*` に載せ替えて push。拒否された理由を PR 本文に 1 行で書く。短い PR を出し、approve 後に Squash and merge で入れる | 1h | - | 非同期 | W1 |
| 04 | ブランチと PR | クエストの依頼を PR に。5 項目テンプレ。CI 緑。NPC のコメント (b) に「直した / 直さない理由 / 質問」で返して resolve。進行役の approve 後に Squash and merge | 1.5h | (b) | 非同期 | W1 |
| 05 | 差し戻しへの対応 | 進行役が Request changes (手動、進行役メモの台本)。修正を push、返答、再依頼、approve、マージ | 1h | - | 非同期 | W2 |
| 06 | 衝突解消 | push 後に NPC が main を進める (a)。`git merge origin/main` で衝突を解消、両方の意図を残す。CI 緑、マージ | 1.5h | (a) | 対面 2 | W2 |
| 07 | rebase と squash と 4 つの動詞 | 3 コミットに刻み、(a) の衝突を `git rebase origin/main` で解消 (自分の側を採る)。`reset --soft` で 1 コミットに squash、ff 可能を `merge-base --is-ancestor` で確認、`--force-with-lease`。PR 本文に 4 つの動詞。Rebase and merge で取り込み、SHA が変わるのを見る | 2h | (a) | 非同期 | W2 |
| 08 | 他人の PR をレビュー | NPC の PR (c) を観点 ID + 温度感でレビューし Request changes。見逃し表を進行役と作る | 1.5h | (c) | 対面 3 | W3 |
| 09 | revert | 演習 07 で入れた変更を `git revert` で打ち消す PR。Revert ボタンは場所を見るだけ | 1h | - | 非同期 | W3 |
| 10 | hotfix とタグ | `v1.0.0` を打つ -> 仕込まれた不具合 (切れたリンク) を hotfix ブランチから PR -> マージ -> `v1.0.1` (annotated) と Release | 1h | - | 非同期 | W3 |
| 11 | 現場の初日に聞くこと + Docker | [first-day-questions.md](first-day-questions.md) の質問を自分の言葉でゲーム画面のメモに書く。Docker サイドクエスト (`docker compose up` で砂場を表示)。到達チェックの自己評価。PR は作らない | 1h | - | 対面 4 | W4 |
| 12 | 実タスク編 | 実プロジェクトで同じ流れを 1 往復し、運用手順の初版を書く ([real-task.md](real-task.md))。内容は public に書かない | 3h | - | 非同期 | W4 |

- 想定時間の合計は砂場 11 本で約 14.5h、実タスク編を含めて約 17.5h
- 衝突とレビューは中盤、hotfix とタグは後半 (前提どおり)
- 2026-11-06: 旧 11 (squash -> rebase -> ff) を 07 に吸収した。到達チェック G-6 / T-5 は 07 で確かめる

### 実タスク編 (W4)

受講者の実プロジェクトで同じ流れを 1 往復する。砂場側にはクエストの文 (`quest-12`) だけがある。
内容は [real-task.md](real-task.md): (1) タスクを 1 つ選び完了条件を 1 行で書く、(2) 同じブランチ命名と 5 項目 PR、(3) レビューを受けて 1 往復、(4) 自分が抜けた後に別の人が同じ作業をできる「運用手順の初版」を書く。

### 演習ファイルの形

`exercises/NN-<slug>.md` 1 ファイルに 2 部を置く。

1. **クエスト本文** (受講者向け。`<!-- quest:start -->` 〜 `<!-- quest:end -->`): 状況 (架空の同僚からの依頼文)、やること、完了条件 (`- [ ]` で 1 行ずつ。ゲーム画面で押せるチェックになる)、参考 (`docs/` へのリンク)、詰まったら (何分で誰に聞くか)
2. **進行役メモ** (進行役向け。`<!-- notes:start -->` 〜 `<!-- notes:end -->`): 見るところ、差し戻しの台本 (05)、NPC が動かなかったときの手当て、よくある詰まり

本文は `{{pr}}` などの用語 placeholder (`web/terms/<platform>.json`) と `<!-- platform:github -->` ... `<!-- /platform -->` のブロックで 1 ソースにする (15 節)。
ゲーム画面 (`web/lib/quests.mjs`) が raw から取って描画する。相対リンクは blob URL に書き換える。手元で同じ描画を見るには `scripts/render.sh`。

## 4. 砂場アプリ

### 題材

架空の小さな図書室「ひだまり図書室」の案内サイト。実在の組織・人物・案件とは無関係であることを `site/README.md` に明記する。

```
site/
  index.html     開館時間の表、お知らせ (ul)、おすすめ本 3 冊 (ol)、フッタ (アクセスへのリンク)
  style.css      最小の装飾
  img/logo.svg   1 枚だけ (alt の練習用)
  README.md      題材の説明と架空である旨
```

HTML と CSS だけ。ビルド無し。ブラウザで `index.html` を開けば確認できる。

### 衝突を狙える行

クエストの本文が「どの行を何に変えるか」を指示するので、受講者がその行を変える限り衝突が起きる。

| 演習 | 受講者が変える行 (クエストの指示) | NPC が同じ行に入れる変更 (conflict.patch) |
|---|---|---|
| 06 | 開館時間の表「土曜」行: `10:00〜17:00` -> `10:00〜18:00` | `土曜 10:00〜16:00 (冬季)` |
| 07 | おすすめ本の 1 冊目: 題名 A -> B | 題名 A -> C |

衝突しなかった場合 (受講者が別の行を変えた、NPC が動かなかった) の手当ては進行役メモに書く。

### 仕込んである不具合 (演習 10 の hotfix 用)

フッタの「アクセス」リンクが存在しないページ `access.html` を指している。初日から main にあるが、クリックしない限り気づかない。演習 10 のクエストで初めて報告する。リセットで `site/` を baseline に戻すと不具合も戻る。

### CI (`check`)

`.github/workflows/check.yml`。`pull_request` と `main` への push で動く。ジョブ名 `check` を ruleset の必須ステータスチェックにする。

1. `npx --yes html-validate "site/**/*.html"` (HTML の構文)
2. `scripts/check-forbidden.sh` (トークンらしき文字列 `ghp_` / `github_pat_`、`.env`、`/mnt/c/` の混入を grep)

演習 08 の NPC の PR は **CI を通る** ように欠陥を選ぶ (6.5 節)。「CI が緑でも人が見るものがある」を体験させるため。

### Docker サイドクエスト

`compose.yaml` (nginx:alpine、`./site` を読み取り専用でマウント、8080) と最小の `Dockerfile`。演習 12 で `docker compose up` して `http://localhost:8080` を見るだけ。Dockerfile の書き方は教えない (現場で学ぶ。初日に聞くことに含める)。

## 5. WSL2 の 1 枚 ([wsl2-setup.md](wsl2-setup.md))

1 枚に収める。順序は作業順。

1. `wsl --install -d Ubuntu` (PowerShell 管理者) -> 再起動 -> Ubuntu のユーザ作成
2. `sudo apt update && sudo apt upgrade`
3. リポジトリは Linux 側 `~/src/` に置く。`/mnt/c` は遅く、改行とパーミッションで事故る
4. git は Ubuntu 側の `git` を使う (Windows 側の Git と混ぜない)
5. `git config --global` で `user.name` / `user.email` (noreply) / `core.autocrlf input` / `init.defaultBranch main`
6. `gh` CLI (公式 apt リポジトリから) と `gh auth login` (HTTPS、ブラウザ)。SSH 鍵は囲みで任意
7. VS Code (Windows 側) + WSL 拡張。WSL のシェルから `code .`
8. clone と動作確認 (`git log --oneline | head`)
9. つまずき: CRLF と `\r` のエラー、`/mnt/c` 上のパーミッション、`explorer.exe .` でフォルダを開く、Windows 側の資格情報との混線

## 6. NPC の設計

### 6.1 身元: 検証した事実と推奨

**検証 1 (2026-11-06、GitHub Docs "Managing your personal access tokens")**: fine-grained PAT は「1 人のユーザまたは 1 つの組織が所有するリソース」にしか届かない。collaborator として他者所有のリポジトリへ書く用途は、ドキュメントが既知の制限として挙げている。つまり **専用アカウント + fine-grained PAT の案は成立しない**。

**検証 2 (同日、REST API "Create a repository ruleset")**: ruleset の bypass 主体 `actor_type` は `Integration` (GitHub App) / `OrganizationAdmin` / `RepositoryRole` / `Team` / `DeployKey` / `User`。`bypass_mode` は `always` / `pull_request` / `exempt`。

| 案 | 仕組み | 利点 | 欠点 |
|---|---|---|---|
| **A (推奨): GitHub App** | 進行役の個人アカウントが所有する App を作り、このリポジトリだけに install。権限は Contents RW / Pull requests RW / Issues RW。ruleset の bypass に Integration として登録 (`always`)。workflow では `actions/create-github-app-token` でトークンを得る。表示名は `<app-slug>[bot]` | アカウントを増やさない。権限がリポジトリ 1 つに閉じる。bypass を主体単位で付けられる。App のトークンで起こしたイベントは次の workflow を起動する | 名前に `[bot]` が付き、人らしさは下がる |
| B: machine account | 利用規約で 1 人 1 つ持てる自動処理専用アカウント + classic PAT (`public_repo` scope) を `NPC_TOKEN` に。main への直接 push (イベント a) には bypass が要る: `User` 型を UI で指定できるか公開時に確認、できなければ write 権限の `DeployKey` を bypass にして (a) だけ deploy key で push | 人の名前で振る舞える | アカウントと 2FA を 1 つ余計に維持。classic PAT は粒度が粗い。secret が 2 つ |

どちらでも workflow 本体は同じで、「トークンを得る step」だけが差し替わる。この設計は A を既定として書く。

### 6.2 3 つのイベント

**(a) 衝突パッチ `npc-conflict.yml`**

- `on: push` / `branches: ['quest/**']`
- ブランチ名から `NN` を取り、`npc/quests/NN/conflict.patch` が無ければ何もせず終了
- main を checkout。冪等性は **今の main の内容** で判定する: パッチが逆向きに当たれば既に積んであるので終了、当たれば積む、どちらでもなければ赤で止める (履歴のトレーラで判定すると、リセット後の次の受講者で衝突が起きなくなるため、履歴は見ない)
- `git apply --3way conflict.patch`、NPC の名前でコミット (本文に `NPC-Quest: NN` のトレーラ。人が履歴を読むための印)、NPC トークンで main へ push
- `concurrency: npc-conflict` で同時実行を 1 本に
- パッチが当たらなければ赤で止める。進行役が手で当てる手順を進行役メモに書く

**(b) レビューコメント `npc-review.yml`**

- `on: pull_request` / `types: [opened]`、head が `quest/**` のときだけ (NPC 自身の PR には反応しない)
- `npc/quests/NN/review/*.md` を 1 ファイル 1 論点として投稿する
- 差分の行を知らなくても付けられるように、**file-level のレビューコメント** (`subject_type: file`、対象 `site/index.html`) として出す。これでスレッドになり、受講者が resolve の操作を練習できる。対象ファイルが差分に無ければ review の本文へフォールバック
- 文面は「温度感タグ + ID + 確認依頼」の形。差分を見ずに書けるので、確認して合っていれば resolve、違えば直す、という往復になる (6.4 節)

**(c) 欠陥入り PR `npc-pr.yml`**

- `on: workflow_dispatch` / 入力 `quest` (既定 `08`)。進行役が対面 3 の前に手で起動する (タイミングを進行役が握る)
- main から `npc/NN-<slug>` を切り、`npc/quests/NN/pr.patch` を当てて push、`gh pr create --body-file pr-body.md --reviewer <受講者>`。受講者のログインは repository variable `TRAINEE_LOGIN`
- label `npc`。ブランチが既にあれば何もしない

共通: パッチは `.github/workflows/` に触れない (workflow の変更には別権限が要る)。

### 6.3 データ配置

```
npc/
  README.md                 NPC の説明。パッチの再生成手順 (baseline タグから git diff)
  quests/
    04/review/01-desc.md    1 ファイル 1 論点
    04/review/02-scope.md
    04/review/03-check.md
    06/conflict.patch
    07/conflict.patch
    08/pr.patch
    08/pr-body.md           5 項目テンプレに沿っているが中身が差分と食い違う (欠陥の 1 つ)
  answers/
    README.md               「受講者は演習 08 の前に開かない」
    08.md                   欠陥一覧 (6.5 節) と見逃し表の雛形 (6.6 節)
```

### 6.4 (b) の文面 (演習 04)

| ファイル | 文面の骨子 |
|---|---|
| 01-desc.md | `[Q] DESC-01` PR 本文の「変更内容」に書いたファイルと Files changed の一覧が一致しているか確認してください。一致していれば resolve、違えば本文を直して返信を |
| 02-scope.md | `[SHOULD] SCOPE-01` タイトルは `quest-04:` で始め、1 つのクエストの変更だけが入っているか確認してください |
| 03-check.md | `[NITS] DESC-05` 「確認方法」に、何を開いて何を見てどうだったかを 1 行添えると再現しやすくなります |

受講者が既に正しくできていても成立する文面にしてある (確認依頼型)。NPC はこの後の返信には反応しない。進行役が approve する前に、受講者の返し方 (直した / 直さない理由 / 質問) と resolve を見る。

### 6.5 (c) の欠陥一覧 (演習 08)

NPC の PR の筋書き: 「お知らせを 1 件追加しました」と言いつつ、CSS と画像とサンプル設定ファイルも触っている。10 個の欠陥。すべて CI (`check`) を通る。

| No. | 場所 | 欠陥 | ID | 温度感 |
|---|---|---|---|---|
| 1 | `site/config.sample.js` (新規) | 実物らしい見た目のダミー API キーが書かれている | SEC-02 | MUST (秘密がリポジトリに入るため) |
| 2 | `index.html` お知らせ | 追加した `<img>` に alt が無い | STATIC-10 | SHOULD |
| 3 | `index.html` お知らせ | 太字にしたいだけの箇所に `<h3>` を使い、見出し階層が飛ぶ | STATIC-06 | SHOULD |
| 4 | `style.css` | お知らせ欄に `height: 120px` の固定高。文言が長いと切れる | STATIC-09 | SHOULD |
| 5 | `style.css` / `index.html` | class 名の綴りが CSS と HTML で食い違い (`evnet-list` / `event-list`)、スタイルが当たらない | STATIC-04 | SHOULD |
| 6 | `.vscode/settings.json` (新規) | ローカル専用のエディタ設定がコミットに混入 | SCOPE-02 | SHOULD |
| 7 | `style.css` コメント | `/home/<誰か>/...` のローカルパスがコメントに残っている | ENV-04 | SHOULD |
| 8 | `index.html` コメント | 「平日のみ表示」とコメントがあるが、実装は土日も表示する | DOC-01 | SHOULD |
| 9 | PR 本文 | 「お知らせを 1 件追加」としか書いていないが、CSS と設定ファイルも変えている | DESC-01 (REQ-05 も可) | SHOULD |
| 10 | `index.html` 文言 | 画面に出る文言の誤字 (「開舘時間」) | STYLE-01 | NITS |

ID の意味は [review-ids.md](review-ids.md) (一般的な言い換えのみ)。組織の観点集があれば、そちらの同じ ID の本文を正とする。

### 6.6 見逃し表

`npc/answers/08.md` に雛形を置き、記入したものは進行役が手元に持つ (public には書かない)。

| 欠陥 No. | 正しい ID / 温度感 | 受講者の ID / 温度感 | 判定 (指摘 / 見逃し / ID 違い / 温度感違い) |
|---|---|---|---|

判定の集計 (10 個のうち指摘できた数、MUST を拾えたか) が到達チェック T-4 の根拠になる。

## 7. リポジトリ構成

```
README.md                       研修用である旨、受講者の名前が公開される旨、組織固有の情報を入れない旨、進め方
LICENSE                         MIT
CLAUDE.md                       教材の作り方 (public に置ける範囲)
CLAUDE.local.md                 (gitignore 済み) 進行役の文脈
kit.conf                        PLATFORM=github|gitlab (scripts/setup.sh が書く)
.htmlvalidate.json              CI の HTML 検証の設定
docs/
  design.md                     この文書
  goals.md                      到達チェック
  wsl2-setup.md                 WSL2 の 1 枚
  merge-methods.md              4 つの動詞
  review-ids.md                 使う観点 ID と一般的な言い換え、温度感タグ
  first-day-questions.md        現場の初日に聞くこと (空欄付き)
  real-task.md                  実タスク編
  platform/github.md            GitHub での操作の 1 枚
  platform/gitlab.md            GitLab での操作の 1 枚 (自動化は未実装の旨)
  setup.md                      公開前の整え方 (進行役向け手順)
  reset.md                      リセット手順 (進行役向け)
  progress-template.md          記録の書式 (個人情報なし)
exercises/
  01-github-account.md          クエスト本文 + 進行役メモ。placeholder とプラットフォーム別ブロックを含む
  02-wsl2-and-clone.md
  03-first-commit-and-push.md
  04-branch-and-pr.md
  05-respond-to-review.md
  06-resolve-conflict.md
  07-rebase-squash-and-verbs.md
  08-review-npc-pr.md
  09-revert.md
  10-hotfix-and-tag.md
  11-first-day-and-docker.md
  12-real-task.md
site/                           砂場 (4 節)
compose.yaml, Dockerfile        サイドクエスト
npc/                            6.3 節
web/                            ゲーム画面 (GitHub Pages。16 節)
  index.html, style.css, app.mjs
  lib/github.mjs                GitHub API (認証なし、ETag) と raw の取得
  lib/progress.mjs              進捗の判定 (純粋関数)
  lib/gitgraph.mjs              Mermaid gitGraph のテキスト生成 (純粋関数)
  lib/quests.mjs                演習 markdown の描画規則 (メタ、セクション、platform、用語、リンク)
  lib/save.mjs                  セーブデータ (localStorage)
  terms/github.json, gitlab.json   用語 placeholder の値 (render.sh も読む)
scripts/
  bootstrap.sh                  最初に 1 回: リポジトリ作成 -> App (Manifest フロー) -> install 待ち -> secret -> setup.sh
  lib/app-manifest.mjs          Manifest フローの受け口 (node。ブラウザからの戻りを受けて App の id / pem を得る)
  lib/app-jwt.mjs               App として API を呼ぶ JWT (install の検知)
  lib/platform.sh               kit.conf の読み書き
  render.sh                     演習の描画を手元で確認 (ゲーム画面と同じ規則)
  setup.sh                      公開前の設定 (リポジトリ設定、ruleset、baseline タグ、招待、Pages)
  reset.sh                      砂場を初期状態へ (11 節)
  playtest.sh                   GitHub なしの自動テストプレイ (演習 03〜10)
  web-check.mjs                 ゲーム画面のロジックを本物のリポジトリに対して確かめる (node)
  check-forbidden.sh            CI と手元で使う禁止文字列の検査
  npc/make-patch.sh             パッチの生成
  npc/identity.sh               NPC の git 識別情報
  npc/conflict.sh, review.sh, pr.sh   3 イベントの本体 (workflow から呼ぶ)
.github/
  workflows/check.yml           CI
  workflows/npc-conflict.yml, npc-review.yml, npc-pr.yml
  workflows/pages.yml           ゲーム画面のデプロイ (web/ が変わったとき)
  PULL_REQUEST_TEMPLATE.md      `クエスト: quest-NN` + 5 項目
  ruleset-main.json             ruleset の定義 (scripts/setup.sh が API で適用)
```

## 8. 公開前の整え方 (設定値)

手順は [setup.md](setup.md) に書く。ここでは値だけ決める。
最初の公開は `scripts/bootstrap.sh` が一括で行う: リポジトリ作成と push -> GitHub App の作成 (**Manifest フロー**。設定済みの manifest をブラウザに送り、人は Create GitHub App を 1 回押す。戻ってきた code を `POST /app-manifests/{code}/conversions` で交換して id と秘密鍵を得る) -> install (人がリポジトリを選ぶ 1 回) を待つ -> secret 登録 -> `scripts/setup.sh`。
App は進行役のアカウントに 1 つで、`~/.config/git-workflow-training/` に保存して次のリポジトリでも使う。手作業はクリック 2 回。
`scripts/setup.sh --platform github --app-id <App ID> --trainee <login>` 単体では、リポジトリ設定、ruleset、baseline タグ、招待と variable、GitHub Pages の有効化を行う。

- **名前**: `git-workflow-training` (確定。内容を表し、組織名を含まない)
- **README 冒頭の 3 点**: 研修用である / 受講者のアカウント名と commit が公開される (参加は本人の了承のうえで) / 組織固有の情報・秘密は入れない
- **Settings > General**: Issues / Wiki / Projects OFF (Issue は使わない)。Pull Requests: Squash (既定、メッセージは PR タイトル + 本文)、Rebase 許可、Merge commit 許可 (4 つの動詞を見せるため)。Automatically delete head branches ON
- **Pages**: Source = GitHub Actions (`pages.yml` が `web/` を配る)。URL は `https://<owner>.github.io/<repo>/`
- **Actions**: Workflow permissions は read-only (GITHUB_TOKEN は使わない)
- **Ruleset `main`** (default branch を対象):
  - Restrict deletions、Block force pushes
  - Require a pull request before merging: 必須承認 1、新しい push で古い承認を無効化 ON、会話の解決を必須 ON
  - Require status checks to pass: `check`
  - Bypass: NPC の App (`always`。イベント a のため)、Repository admin (`pull_request` のみ。進行役が自分の PR をマージするため。直接 push はしない)
- **Collaborators**: 受講者 (Write)
- **Variables**: `TRAINEE_LOGIN`。**Secrets**: `NPC_APP_ID`、`NPC_APP_PRIVATE_KEY` (案 B なら `NPC_TOKEN`)
- **Tag `baseline`**: 砂場の初期状態を指す。`site/` を意図して変えたら動かす
- **ラベル**: `npc` (NPC の PR に付く。`scripts/npc/pr.sh` が無ければ作る)
- 公開の直前に `scripts/check-forbidden.sh --all` と 12 節の線引きを目で確認する

## 9. 受講者の GitHub アカウント (演習 01 の一般形)

- 個人アカウントを使う (GitHub は 1 人 1 アカウント。所属が変わっても同じアカウントを使い続ける)。既にあればそれ
- 所属組織のメールアドレスは GitHub に登録しない (secondary にも)。commit に出る経路を断つ
- Settings > Emails で "Keep my email addresses private" と "Block command line pushes that expose my email" を ON。`git config user.email` は noreply アドレス
- 2FA は必須。認証アプリを推奨
- public リポジトリで名前・commit・失敗が見えることを、対面 1 の冒頭で説明して了承を取る。了承の記録は進行役の手元に (リポジトリには書かない)

## 10. 記録の取り方

書式は [progress-template.md](progress-template.md) に置く。記入したものは進行役の手元に持ち、リポジトリには入れない。

1. 到達チェックの達成日 (goals.md の 20 行 x 達成日 / 確かめた演習 / 備考)
2. PR ごとの指摘と見逃し (受講者が出した PR: 進行役が付けた ID と受講者の返し方 / 受講者がレビューした PR: 6.6 節の見逃し表)
3. 対面 15 分メモ (日付 / 分かったこと / つまずき / 次にやること)
4. 進行役の時間実績 (週 / 作る / 返す / 対面 / 記録)

## 11. リセット手順

次の受講者に回すとき、進行役が手元で `scripts/reset.sh` を実行する。main の履歴は書き換えない (force push を教えない方針と揃える。前の受講者の commit は履歴に残る)。

1. 前提: 進行役の `gh auth`、clean な作業ツリー、main が最新
2. 開いている PR をすべて close (`gh pr close --delete-branch`)
3. リモートの `quest/*` と `npc/*` ブランチを削除
4. タグ `v*` と Release を削除 (`baseline` は残す)
5. `git checkout baseline -- site/` して「砂場を初期状態に戻す」コミットを作り、PR 経由でマージ (`gh pr merge --squash --admin`。admin の bypass は PR のみ)
6. ゲーム画面の進捗はブラウザの保存なので、新しい受講者は「はじめから」を押す (リポジトリ側では何もしない)
7. `TRAINEE_LOGIN` を更新し、新しい受講者を collaborator に招待。前の受講者を外す
8. `npc/quests/*/conflict.patch` と `pr.patch` が baseline に当たることを `git apply --check` で確認

キットの内容 (docs、exercises、npc、scripts) を直したときは、`site/` を変えた場合だけ `baseline` タグを動かす。

## 12. 公開の線引き

このリポジトリは public なので、次を入れない。

- 受講者の名前以外の個人情報、特性、評価、達成日、日程
- 進行役の所属組織の名前、関係者、顧客・案件名、所属組織のメールアドレス
- 受講者の次の配属先に関する情報
- 組織内のレビュー観点集の本文。ID と一般的な言い換え (review-ids.md) だけ
- 組織内の文書へのパスやリンク
- トークン、鍵、`.env` (CI と `scripts/check-forbidden.sh` が機械的に見る)

入れてよいもの: 架空の題材、演習の本文、進行役メモ (一般形)、NPC のパッチと答え、設定値、リセット手順。
進行役の文脈は `CLAUDE.local.md` (gitignore 済み) と進行役の手元のメモに置く。

## 13. 決定の記録

2026-11-06 に進行役が決めた。

1. NPC の身元は GitHub App (6.1 節の案 A)。machine account は作らない
2. 旧演習 11 (squash -> rebase -> ff) を 07 に吸収し、砂場は 11 本 + 実タスク編 (12)
3. リポジトリ名は `git-workflow-training`、ライセンスは MIT
4. プラットフォームはフラグで選べる構造にする (15 節)。初回の実施は GitHub
5. 進め方の UI は Web のゲーム画面 (見る専用、GitHub Pages)。Issue は使わない (同日、テストプレイに入る直前に認識の食い違いが分かって変更。16 節)

## 14. 実装の状態

2026-11-06 時点。GitHub への公開は進行役が [setup.md](setup.md) に沿って行う。

| 部品 | 状態 |
|---|---|
| 砂場 `site/`、CI (`check.yml`、`.htmlvalidate.json`、`check-forbidden.sh`)、compose / Dockerfile | 作成済み。html-validate と check-forbidden を手元で通した |
| `docs/` 一式 | 作成済み |
| `exercises/` 12 本 | 作成済み。Issue 依存を外してゲーム画面向けに書き換え済み。描画は `scripts/web-check.mjs` と `scripts/render.sh` で確認 |
| NPC: パッチ 3 本、レビューコメント 3 本、答え、workflow 3 本、scripts/npc | 作成済み。パッチは `git apply --check` を通した。workflow は公開後の煙テスト (setup.md 6 節) で動作を見る |
| `scripts/` (render、setup、reset) | 作成済み。shellcheck を通した。setup / reset は公開で実際に使った (Issue 関連は撤去済み) |
| `scripts/playtest.sh` (GitHub なしの自動テストプレイ) | 作成済み。模擬 origin に pre-receive hook で main を保護し、受講者役が演習 03〜10 のクエスト本文のコマンドを順に打つ。NPC は本物の conflict.sh。通し結果: 衝突 2 回、rebase 解消、squash、force-with-lease、Rebase and merge の SHA 変化、revert、hotfix とタグ、NPC パッチの最終状態での適用、すべて OK (2026-11-06) |
| `scripts/bootstrap.sh` + `scripts/lib/app-manifest.mjs` + `app-jwt.mjs` (公開の一括化) | 公開で実際に使った。固定ポート、manifest の hook_attributes、install 検知の API を直して通った |
| ゲーム画面 (`web/`、`pages.yml`。16 節) | 作成済み。ロジックは `scripts/web-check.mjs` で本物のリポジトリに対して確認。Pages の配信はマージ後に初めて動く |
| 公開 | 2026-11-06 に public で公開済み。App install、secret、ruleset、baseline タグ、煙テスト (check / npc-review / npc-conflict) まで確認 |
| GitLab 版の自動化 | 未実装 (15 節) |

## 15. プラットフォーム切替と GitLab 版

### 切り替えの仕組み (実装済み)

- `kit.conf` の `PLATFORM=github|gitlab`。`scripts/setup.sh --platform` が書き、`scripts/lib/platform.sh` が読む (環境変数 `KIT_PLATFORM` が優先)
- 演習 (`exercises/*.md`) は 1 ソース。用語は `{{pr}}` などの placeholder (`web/terms/<platform>.json`)、プラットフォーム固有の手順は `<!-- platform:github -->` ... `<!-- /platform -->` のブロック。ゲーム画面 (`web/lib/quests.mjs`) が描画し、`scripts/render.sh` が手元で同じ描画を出す。プラットフォームは `kit.conf` から読む
- `docs/` は描画しない。両プラットフォームを併記し、操作の 1 枚だけ `docs/platform/github.md` と `docs/platform/gitlab.md` に分ける
- 自動化 (CI、NPC) はプラットフォーム固有。GitHub 版は `.github/`、GitLab 版は `.gitlab-ci.yml` に置く想定で、同じリポジトリに共存できる (push 先が GitHub なら Actions だけが動く)

### GitLab 版の実装メモ (未実装。次の受講者が GitLab のときに作る)

Free の self-managed を想定した対応表。

| GitHub 版 | GitLab 版の対応 |
|---|---|
| ruleset で main を保護、承認 1 必須、会話の解決必須 | protected branch (Allowed to merge: Developers + Maintainers / Allowed to push and merge: No one)。承認の必須化は Premium なので約束で守る。"All threads must be resolved" は Free で設定可 |
| Squash and merge 既定、Rebase and merge も許可 | Merge method = Merge commit、Squash commits = Encourage。演習 07 の取り込みは Fast-forward merge に一時的に切り替えるか、semi-linear history で代替 |
| GitHub App (NPC) | Project access token (bot ユーザ `project_<id>_bot`、role Maintainer、scope `api` + `write_repository`)。CI/CD 変数 `NPC_TOKEN` (masked、protected) |
| Actions `check` | `.gitlab-ci.yml` の `check` ジョブ (node イメージで html-validate + check-forbidden.sh)。必須化は "Pipelines must succeed" |
| (a) push `quest/**` -> conflict | `rules: - if: $CI_COMMIT_BRANCH =~ /^quest\//` のジョブ。`scripts/npc/conflict.sh` の `gh api` を `glab api` に、push 先 URL に token を埋める |
| (b) PR opened -> review | `rules: - if: $CI_PIPELINE_SOURCE == "merge_request_event"` のジョブで discussions API (`POST /projects/:id/merge_requests/:iid/discussions`)。ファイル単位のスレッドには position が要るので、まず MR 全体の discussion で代替 |
| (c) workflow_dispatch -> NPC PR | 手動パイプライン (Run pipeline、変数 `NPC_QUEST=08`) と `rules: - if: $NPC_QUEST`。`glab mr create --reviewer` |
| `gh` CLI | `glab` CLI |
| ゲーム画面の GitHub API 呼び出し | GitLab REST API に差し替え (`web/lib/github.mjs` を `gitlab.mjs` に。branches / tags / merge_requests / compare / approvals) |
| Revert ボタン、Tag、Release | 同等の機能あり ([platform/gitlab.md](platform/gitlab.md)) |

`scripts/setup.sh --platform gitlab` は kit.conf を書き、残りは手順を表示する。`scripts/reset.sh` は GitLab では止まる。

## 16. ゲーム画面 (web/) (2026-11-06 追加)

受講者が「今どこにいるか」「次に何をするか」「main と枝がどういう形か」を 1 つの画面で見られるようにする。**見る専用**で、操作そのもの (git、PR、レビュー) はターミナルと GitHub で行う。これは「現場で使う本物の道具」から離れないための線引き。

- **置き場**: `web/` の静的サイト。GitHub Pages (`pages.yml`、`web/` が変わったときにデプロイ)。バックエンド無し。URL は `https://<owner>.github.io/<repo>/`
- **データ**: GitHub REST API を認証なしで読む (public リポジトリ。60 回/時)。ETag で条件付き取得にし、304 は回数を消費しない。1 回の更新で branches / tags / pulls / commits / compare (枝ごと) / reviews (NPC の PR ごと) / contents を呼ぶ (8〜12 回)。2 分ごとに自動更新、手動更新ボタンあり。演習の本文と `kit.conf` は raw.githubusercontent.com から取る
- **進捗の判定** (`web/lib/progress.mjs`、純粋関数): `quest/NN-*` の PR がマージ -> NN 済 / `hotfix/*` のマージ + タグ v1.0.0 と v1.0.1 -> 10 済 / NPC の PR に人が Request changes -> 08 済 / 01, 02, 11, 12 は完了条件のチェック (`- [ ]`) を全部付けると済。未完了で `quest/NN-*` の枝か PR があれば「作業中」。最初の未完了が「いまここ」
- **セーブデータ** (`web/lib/save.mjs`): localStorage に、開始日時、完了条件のチェック、クエストごとのメモ。「はじめから」で消して作り直し、「続きから」で読む。GitHub 側の状態は保存しない (毎回取り直す)。砂場を戻すのは進行役の `scripts/reset.sh`
- **画面**: 左にクエスト一覧 (済 / 作業中 / いまここ)、NPC の動き (main への commit、PR、レビュー)、開いている PR。右に選んだクエストの本文 (markdown。完了条件は押せるチェック)、進行役メモ (折りたたみ)、メモ欄、前後のクエストへ。下にブランチの木 (Mermaid の `gitGraph` をブラウザで描く。規則: main の直近 12 コミット、枝は merge-base から、タグ、先端を強調)
- **描画の規則** (`web/lib/quests.mjs`): メタ (`<!-- kit -->`)、セクション (`quest` / `notes`)、platform ブロック、`{{用語}}` (`web/terms/<platform>.json`)、相対リンクを blob URL に。`scripts/render.sh` も同じ規則で、手元での確認用
- **依存**: marked と mermaid を CDN (jsdelivr) の ES module で読む。ビルド無し。markdown は自分のリポジトリの内容なので sanitize しない (進行役がマージしたものだけが main に入る)
- **検証**: `scripts/web-check.mjs` が同じ lib を node で動かし、本物のリポジトリに対して判定と gitGraph のテキストを出す
- **NPC の 3 イベントとは別** の仕組み。前提「NPC の自動化は 3 イベントまで」には数えない
- **補助**: VS Code の Git Graph 拡張と `git tree` エイリアスを [wsl2-setup.md](wsl2-setup.md) で任意として案内する。ゲーム画面は「GitHub 上の全体」、Git Graph は「手元の今」
