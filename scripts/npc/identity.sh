# NPC (GitHub App) の名前で commit するための git 設定。conflict.sh / pr.sh が source する。
# 環境変数: NPC_SLUG (App の slug。create-github-app-token の app-slug 出力)、GH_TOKEN
# NPC_NAME と NPC_EMAIL が両方あればそれを使い、API を呼ばない (scripts/playtest.sh が GitHub なしで動かすため)。
set -euo pipefail

if [ -n "${NPC_NAME:-}" ] && [ -n "${NPC_EMAIL:-}" ]; then
  git config user.name "$NPC_NAME"
  git config user.email "$NPC_EMAIL"
else
  npc_slug="${NPC_SLUG:?NPC_SLUG (GitHub App の slug) が必要}"
  npc_bot="${npc_slug}[bot]"
  npc_uid="$(gh api "users/${npc_slug}%5Bbot%5D" --jq .id)"

  git config user.name "$npc_bot"
  git config user.email "${npc_uid}+${npc_bot}@users.noreply.github.com"
fi
