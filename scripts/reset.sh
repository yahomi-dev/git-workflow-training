#!/usr/bin/env bash
# 砂場を次の受講者向けに初期状態へ戻す (GitHub)。手順書は docs/reset.md。
#
# 使い方: scripts/reset.sh --yes [--trainee <次の受講者のログイン名>]
#   1. 開いている PR を close し、quest/* と npc/* のリモートブランチを削除
#   2. v* のタグと Release を削除 (baseline は残す)
#   3. site/ を baseline の状態に戻すコミットを PR 経由で main に入れる (履歴は書き換えない)
#   4. quest ラベルの Issue を close し、起票し直す
#   5. --trainee があれば TRAINEE_LOGIN を更新し、collaborator に招待する (前の受講者を外すのは手で)
#   6. NPC のパッチが baseline に当たるか確かめる
# 前提: 進行役 (リポジトリの admin) が `gh auth login` 済み。作業ツリーが clean。
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/platform.sh
source "${here}/lib/platform.sh"

yes=0
trainee=""

while [ $# -gt 0 ]; do
  case "$1" in
    --yes) yes=1; shift ;;
    --trainee) trainee="$2"; shift 2 ;;
    *) echo "reset: 不明な引数 $1" >&2; exit 1 ;;
  esac
done

if [ "$yes" -ne 1 ]; then
  echo "reset: 開いている PR を close し、ブランチとタグを消します。実行するには --yes を付けてください" >&2
  exit 1
fi

platform="$(kit_platform)"
kit_require_platform "$platform"

if [ "$platform" != "github" ]; then
  echo "reset: GitLab 版は未実装です。docs/reset.md の手順を手で行ってください" >&2
  exit 1
fi

cd "$(kit_root)"

if [ -n "$(git status --porcelain)" ]; then
  echo "reset: 作業ツリーが clean ではありません" >&2
  exit 1
fi

git switch main > /dev/null
git pull --ff-only > /dev/null
git fetch --prune --tags > /dev/null

echo "== 1. PR とブランチ"
for n in $(gh pr list --state open --json number --jq '.[].number'); do
  gh pr close "$n" --delete-branch --comment "次の受講者向けにリセットするため close します" > /dev/null
  echo "closed PR #${n}"
done

for ref in $(git ls-remote --heads origin 'quest/*' 'npc/*' | awk '{print $2}'); do
  branch="${ref#refs/heads/}"
  git push origin --delete "$branch" > /dev/null
  echo "deleted branch ${branch}"
done

echo
echo "== 2. タグと Release"
for ref in $(git ls-remote --tags origin 'v*' | awk '{print $2}' | grep -v '\^{}$'); do
  tag="${ref#refs/tags/}"

  if gh release view "$tag" > /dev/null 2>&1; then
    gh release delete "$tag" --yes --cleanup-tag > /dev/null
    echo "deleted release and tag ${tag}"
  else
    git push origin --delete "$tag" > /dev/null
    echo "deleted tag ${tag}"
  fi

  git tag -d "$tag" > /dev/null 2>&1 || true
done

echo
echo "== 3. site/ を baseline に戻す"
branch="chore/reset-$(date +%Y%m%d-%H%M%S)"
git switch --create "$branch" > /dev/null
git checkout baseline -- site/

if [ -z "$(git status --porcelain)" ]; then
  echo "site/ は既に baseline と同じ"
  git switch main > /dev/null
  git branch -D "$branch" > /dev/null
else
  git commit --quiet -m "砂場を初期状態に戻す

次の受講者向けに site/ を baseline タグの状態へ戻す。履歴は書き換えない。"
  git push --set-upstream origin "$branch" > /dev/null
  gh pr create --fill --label quest > /dev/null 2>&1 || gh pr create --fill > /dev/null
  gh pr merge "$branch" --squash --admin --delete-branch > /dev/null
  git switch main > /dev/null
  git pull --ff-only > /dev/null
  echo "main に入れた: $(git rev-parse --short HEAD)"
fi

echo
echo "== 4. Issue"
for n in $(gh issue list --label quest --state open --json number --jq '.[].number'); do
  gh issue close "$n" --comment "次の受講者向けにリセットするため close します" > /dev/null
  echo "closed issue #${n}"
done
"${here}/seed-issues.sh" --platform github
"${here}/board.sh" update

if [ -n "$trainee" ]; then
  echo
  echo "== 5. 受講者"
  nwo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
  gh api --method PUT "repos/${nwo}/collaborators/${trainee}" -f permission=push > /dev/null
  gh variable set TRAINEE_LOGIN --body "$trainee"
  echo "TRAINEE_LOGIN=${trainee}。前の受講者を Settings > Collaborators から外すのは手で"
fi

echo
echo "== 6. NPC のパッチ"
for p in npc/quests/*/conflict.patch npc/quests/*/pr.patch; do
  [ -f "$p" ] || continue
  git apply --check "$p" && echo "OK: ${p}"
done

echo
echo "reset: 完了"
