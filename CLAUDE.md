# git-workflow-training の作り方

このリポジトリは public の研修キット。設計の正は `docs/design.md`。構成や方針を変えるときは design.md を先に直し、教材を追従させる。

## 入れないもの

`docs/design.md` 12 節に従う。受講者の個人情報・特性・評価・日程、進行役の所属組織に関する情報、組織内文書のパスや本文、トークンや鍵は入れない。進行役の文脈は gitignore 済みの `CLAUDE.local.md` に書く。

## 書き方

- 日本語。括弧は半角 `()`。矢印は `->` `<-` (Unicode の矢印は使わない)
- 受講者向けの文書 (`exercises/`、`docs/wsl2-setup.md` など) は初心者が 1 人で読む前提。1 つの手順に 1 コマンド、直後に結果の確かめ方を書く
- 演習は「完了条件」を 1 行ずつ、受講者が自分で判定できる形で書く
- 演習ファイルは「クエスト本文」(`<!-- quest:start -->`〜`<!-- quest:end -->`) と「進行役メモ」(`<!-- notes:start -->`〜`<!-- notes:end -->`) の 2 部構成。ゲーム画面 (`web/`) が raw から読んで描画する。Issue は使わない
- 進行役個人の流儀 (個人設定、特定の型やライブラリ) を持ち込まない。現場で通用する最小を書く
- レビュー観点は ID と `docs/review-ids.md` の一般的な言い換えだけを使う。組織内の観点集の本文を転記しない
- 受講者の名前や日付は演習本体に書かない。必要なら `<受講者>` のような placeholder にする

## NPC と砂場

- NPC のパッチは `baseline` タグから `git diff` で生成し、`.github/workflows/` に触れない
- 衝突パッチはクエスト本文が指示する行と同じ行を狙う (`docs/design.md` 4 節の表)
- 演習 08 の欠陥入り PR は CI (`check`) を通る欠陥だけで構成する

## 検証

- 通しテスト: `scripts/playtest.sh` (GitHub なしで演習 03〜10 を模擬環境で通す。演習の手順、砂場、NPC パッチを変えたら必ず回す)
- HTML: `npx --yes html-validate "site/**/*.html"`
- 禁止文字列: `scripts/check-forbidden.sh --all`
- パッチ: `git apply --check npc/quests/*/*.patch` を baseline の `site/` に対して
- ゲーム画面のロジック: `node scripts/web-check.mjs` (本物のリポジトリに対して判定と gitGraph を出す。未置換の `{{...}}` も報告する)。手元の描画確認は `scripts/render.sh --section quest exercises/NN-*.md`
- シェルと JS: `shellcheck -s bash -x scripts/*.sh scripts/npc/*.sh scripts/lib/*.sh`、`node --check web/app.mjs web/lib/*.mjs`

## GitHub への操作

リポジトリ作成、push、ruleset、secret の登録は進行役が `docs/setup.md` に沿って行う。Claude は手順とスクリプトを用意し、明示の指示がない限り GitHub へは操作しない。
