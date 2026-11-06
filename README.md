# git-workflow-training

チーム開発の流れ (ブランチ、PR、レビュー、衝突解消、hotfix) を、GitHub 上で手を動かして学ぶ研修キット。
WSL2 の環境構築から始め、12 本のクエストをゲーム画面 (GitHub Pages) で読みながら進める。同僚役 (NPC) が自動で衝突を起こし、レビューコメントを付け、欠陥入りの PR を出す。

## はじめに読むこと

- **研修用のリポジトリです。** 砂場のサイト (ひだまり図書室) は架空で、実在の組織・人物・作品とは関係ありません
- **受講者のアカウント名と commit、失敗はこの public リポジトリで公開されます。** 参加は本人の了承のうえで行います (演習 01)
- **所属組織の情報、顧客や案件の名前、秘密 (鍵、トークン) は入れません。** 研修の記録 (達成日、指摘の表) もリポジトリの外に置きます
- 用語は GitHub を既定にしています。GitLab でも用語を置き換えて使えますが、自動化 (CI、NPC) は GitHub 版のみです

## 受講者の進め方

1. **ゲーム画面** (`https://<owner>.github.io/<repo>/`。進行役から URL をもらう) を開き、「はじめから」を押す。クエスト 01 から順に、画面の本文どおりに進める
2. 操作はターミナルと GitHub で行う。ゲーム画面は、今どのクエストか、完了条件、NPC の動き、開いている PR、main と枝の形を見る場所。PR がマージされると自動で「済」になる (PR の無いクエストは完了条件のチェックで)
3. 分からないことは [docs/](docs/) を見る。まず [docs/wsl2-setup.md](docs/wsl2-setup.md)、PR を出す前に [docs/platform/github.md](docs/platform/github.md)
4. 詰まったら 30 分で進行役に聞く。1 人で抱えない
5. 終わったら [docs/goals.md](docs/goals.md) (到達チェック) を自分で読み、1 人でできる行に印を付ける

## 進行役の進め方

1. [docs/design.md](docs/design.md) を読む (設計の正)
2. `scripts/bootstrap.sh` で公開と設定を一括で行う (ブラウザで 2 クリック。手順と手で行う場合は [docs/setup.md](docs/setup.md))。終わるとゲーム画面の URL が出る
3. 受講者の PR を 1 営業日以内に返す。レビューは [docs/review-ids.md](docs/review-ids.md) の ID と温度感で
4. 対面 4 回 (WSL2、衝突、レビューの読み合わせ、振り返り) を各 1 時間
5. 記録は [docs/progress-template.md](docs/progress-template.md) の書式で手元に
6. 次の受講者に回すときは [docs/reset.md](docs/reset.md)

## 構成

| 場所 | 中身 |
|---|---|
| `web/` | ゲーム画面 (GitHub Pages の静的サイト。進捗、クエスト本文、NPC の動き、ブランチの木) |
| `exercises/` | 演習 12 本 (クエスト本文 + 進行役メモ)。ゲーム画面がここから読む |
| `docs/` | 到達チェック、WSL2 の 1 枚、4 つの動詞、観点 ID、初日に聞くこと、設計、設定とリセットの手順 |
| `site/` | 砂場のサイト (HTML / CSS) |
| `npc/` | 同僚役のデータ (衝突パッチ、レビューコメント、欠陥入り PR、答え) |
| `scripts/` | 公開の一括化 (bootstrap)、設定、リセット、自動テストプレイ、ゲーム画面の確認、禁止文字列の検査、描画 |
| `.github/` | CI (`check`)、NPC の workflow 3 本、Pages のデプロイ、PR テンプレート、ruleset の定義 |
| `compose.yaml` | サイドクエスト (演習 11) で砂場を Docker で表示する |

## ライセンス

[MIT](LICENSE)。自分の研修にそのまま使ってよい。使うときは `docs/setup.md` から。
