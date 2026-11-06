#!/usr/bin/env bash
# NPC イベント (c): 欠陥を仕込んだ PR を開き、受講者をレビュアーに指名する。
#
# 前提: main を checkout 済みで、push できるトークンで認証されている (npc-pr.yml が用意する)。
# 引数: <演習番号 2 桁>。環境変数: NPC_SLUG、GH_TOKEN、GH_REPO、TRAINEE_LOGIN (任意)
# 冪等: ブランチが既にあれば何もしない。やり直すときはブランチと PR を消してから起動する。
set -euo pipefail

nn="${1:?演習番号 (2 桁) が必要}"
q="npc/quests/${nn}"

for f in pr.patch pr-branch.txt pr-title.txt pr-message.txt pr-body.md; do
  if [ ! -f "${q}/${f}" ]; then
    echo "quest ${nn}: ${q}/${f} がありません" >&2
    exit 1
  fi
done

branch="npc/${nn}-$(tr -d '\n' < "${q}/pr-branch.txt")"

if git ls-remote --exit-code --heads origin "$branch" > /dev/null; then
  echo "quest ${nn}: ブランチ ${branch} は既にある。何もしない"
  exit 0
fi

# shellcheck source=scripts/npc/identity.sh
source "$(dirname "$0")/identity.sh"

git switch --create "$branch"
git apply --3way "${q}/pr.patch"
git add --all
git commit --quiet -F "${q}/pr-message.txt"
git push origin "$branch"

gh label create npc --color 8250df --description "NPC (同僚役) の PR" --force > /dev/null || true

args=(
  --base main
  --head "$branch"
  --title "$(head -n 1 "${q}/pr-title.txt")"
  --body-file "${q}/pr-body.md"
  --label npc
)

if [ -n "${TRAINEE_LOGIN:-}" ]; then
  args+=(--reviewer "$TRAINEE_LOGIN")
fi

gh pr create "${args[@]}"
