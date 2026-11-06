# リセット手順 (進行役向け)

次の受講者に回すとき、砂場を初期状態に戻す。main の履歴は書き換えない (force push を教えない方針と揃える。前の受講者の commit は履歴に残る)。

## 自動 (GitHub)

```bash
git switch main && git pull
scripts/reset.sh --yes --trainee <次の受講者のログイン名>
```

やること:

1. 開いている PR を close し、`quest/*` と `npc/*` のリモートブランチを削除
2. `v*` のタグと Release を削除 (`baseline` は残す)
3. `site/` を `baseline` の状態に戻すコミットを PR 経由で main に入れる (admin の bypass は PR 経由のみ)
4. `quest` ラベルの Issue を close し、起票し直す。進行ボードも更新する
5. `TRAINEE_LOGIN` を更新し、次の受講者を collaborator に招待
6. NPC のパッチが baseline に当たることを `git apply --check` で確かめる

## 手で行うこと

- 前の受講者を Settings > Collaborators から外す
- 進行記録 ([progress-template.md](progress-template.md)) を新しく作る
- 対面の日程を組む

## キットを直したとき

- `site/` を意図して変えたら `baseline` タグを動かし、NPC のパッチを作り直す ([../npc/README.md](../npc/README.md))

```bash
git tag -f -a baseline -m "砂場 (site/) の初期状態" && git push -f origin baseline
```

- `exercises/` や `docs/` だけの変更なら何もしなくてよい。次の起票から反映される

## GitLab の場合

`scripts/reset.sh` は GitLab 未対応。上の 1〜6 を `glab` と UI で行う。Issue の起票だけは `scripts/seed-issues.sh --platform gitlab` が使える。
