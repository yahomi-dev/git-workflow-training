# NPC (同僚役の自動化)

受講者 1 人に対してチームがいるように見せる役。GitHub App のトークンで動く 3 つの workflow が、ここに置いたデータを使う。設計は `docs/design.md` 6 節。

| イベント | workflow | 使うデータ |
|---|---|---|
| (a) 受講者が `quest/NN-*` を push したら main を進めて衝突させる | `.github/workflows/npc-conflict.yml` -> `scripts/npc/conflict.sh` | `quests/NN/conflict.patch`、`quests/NN/conflict-message.txt` |
| (b) 受講者の PR が開いたら確認依頼型のレビューコメントを付ける | `.github/workflows/npc-review.yml` -> `scripts/npc/review.sh` | `quests/NN/review/*.md` (1 ファイル 1 論点) |
| (c) 欠陥を仕込んだ PR を開いて受講者にレビューさせる | `.github/workflows/npc-pr.yml` (手で起動) -> `scripts/npc/pr.sh` | `quests/NN/pr.patch`、`pr-title.txt`、`pr-message.txt`、`pr-body.md` |

`answers/` には (c) の欠陥一覧がある。受講者は演習 08 を終えるまで開かない。

## パッチの作り方

パッチは `baseline` タグの `site/` に対する差分。`site/` を意図して変えたら作り直す。

```bash
# 1. baseline の site/ と、変更後の site/ を別ディレクトリに用意する
work=$(mktemp -d)
git archive baseline site | tar -x -C "$work"          # $work/site = baseline
cp -r "$work/site" "$work/mod"                           # $work/mod  = 編集用
#    ($work/mod を編集する。新規ファイルを足すときは $work/mod/.vscode/... のようにリポジトリルート相対で)

# 2. パッチにする (パスの接頭辞をリポジトリルート相対に直す)
scripts/npc/make-patch.sh "$work/site" "$work/mod" npc/quests/NN/conflict.patch

# 3. 当たることを確かめる
git apply --check npc/quests/NN/conflict.patch
```

`pr.patch` も同じ手順。`.github/workflows/` には触れない (workflow の変更には別の権限が要る)。

## 冪等性と手当て

- (a) は **今の main の内容** で判定する。パッチが逆向きに当たれば「積んである」として何もしない (コミットの `NPC-Quest: NN` トレーラは人が履歴を読むための印で、判定には使わない。履歴で判定すると、リセット後の次の受講者で衝突が起きなくなる)
- (a) のパッチが当たらないと workflow は赤で止まる。進行役が手元で当てて PR 経由で入れる (手順は演習 06 の進行役メモ)
- (b) は PR が開いた瞬間に 1 回だけ動く。head が `quest/` で始まらない PR (NPC 自身の PR) には反応しない
- (c) はブランチが既にあれば何もしない。やり直すときはブランチと PR を消してから起動する
