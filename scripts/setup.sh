#!/usr/bin/env bash
# 公開前の整え方のうち、自動化できる部分を行う。手順書は docs/setup.md。
#
# 使い方:
#   scripts/setup.sh --platform github [--app-id <NPC の GitHub App ID>] [--trainee <受講者のログイン名>] [--skip-issues]
#   scripts/setup.sh --platform gitlab [--skip-issues]
#
# GitHub で行うこと:
#   1. kit.conf に PLATFORM を書く
#   2. リポジトリ設定 (Squash 既定、Rebase と Merge commit も許可、head ブランチ自動削除、Wiki / Projects オフ)
#   3. ruleset `main` (.github/ruleset-main.json。--app-id があれば NPC の App を bypass に入れる)
#   4. baseline タグ (無ければ今の HEAD に打って push)
#   5. 受講者を collaborator (Write) に招待し、variable TRAINEE_LOGIN を設定 (--trainee があれば)
#   6. ラベルと Issue の起票 (scripts/seed-issues.sh)
#   secret (NPC_APP_ID、NPC_APP_PRIVATE_KEY) は秘密なので登録せず、コマンドを表示するだけ
#
# GitLab では kit.conf と Issue の起票だけを行い、残りは手順を表示する (自動化は未実装)。
# 前提: `gh auth login` 済み、remote origin がリポジトリを指し、main を push 済み。
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/platform.sh
source "${here}/lib/platform.sh"

platform=""
app_id=""
trainee=""
skip_issues=0

while [ $# -gt 0 ]; do
  case "$1" in
    --platform) platform="$2"; shift 2 ;;
    --app-id) app_id="$2"; shift 2 ;;
    --trainee) trainee="$2"; shift 2 ;;
    --skip-issues) skip_issues=1; shift ;;
    *) echo "setup: 不明な引数 $1" >&2; exit 1 ;;
  esac
done

if [ -z "$platform" ]; then
  echo "setup: --platform github|gitlab を指定してください" >&2
  exit 1
fi

kit_require_platform "$platform"
cd "$(kit_root)"

echo "== 1. kit.conf"
kit_write_platform "$platform"
echo "PLATFORM=${platform}"

if [ "$platform" = "gitlab" ]; then
  echo
  echo "GitLab 版の自動化 (CI の check、NPC、protected branch の設定) は未実装です。"
  echo "docs/platform/gitlab.md と docs/design.md 15 節を見て、protected branch と merge method を手で設定してください。"

  if [ "$skip_issues" -eq 0 ]; then
    echo
    echo "== Issue の起票 (glab)"
    "${here}/seed-issues.sh" --platform gitlab
  fi

  exit 0
fi

nwo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
echo "対象: ${nwo}"

echo
echo "== 2. リポジトリ設定"
gh api --method PATCH "repos/${nwo}" \
  -F allow_squash_merge=true \
  -F allow_rebase_merge=true \
  -F allow_merge_commit=true \
  -F delete_branch_on_merge=true \
  -f squash_merge_commit_title=PR_TITLE \
  -f squash_merge_commit_message=PR_BODY \
  -F has_wiki=false \
  -F has_projects=false \
  -F has_issues=true > /dev/null
echo "Squash 既定 / Rebase・Merge commit 許可 / head ブランチ自動削除 / Wiki・Projects オフ"

echo
echo "== 3. ruleset main"
ruleset_json="$(mktemp)"
trap 'rm -f "$ruleset_json"' EXIT

if [ -n "$app_id" ]; then
  jq --argjson id "$app_id" \
    '(.bypass_actors[] | select(.actor_type == "Integration") | .actor_id) = $id' \
    .github/ruleset-main.json > "$ruleset_json"
else
  jq 'del(.bypass_actors[] | select(.actor_type == "Integration"))' \
    .github/ruleset-main.json > "$ruleset_json"
  echo "注意: --app-id が無いので NPC の App を bypass に入れていない。後で --app-id 付きで再実行する"
fi

existing="$(gh api "repos/${nwo}/rulesets" --jq '.[] | select(.name == "main") | .id' | head -n 1)"

if [ -n "$existing" ]; then
  gh api --method PUT "repos/${nwo}/rulesets/${existing}" --input "$ruleset_json" > /dev/null
  echo "更新した (id ${existing})"
else
  gh api --method POST "repos/${nwo}/rulesets" --input "$ruleset_json" > /dev/null
  echo "作成した"
fi

echo
echo "== 4. baseline タグ"
if git rev-parse -q --verify refs/tags/baseline > /dev/null; then
  echo "既にある: $(git rev-parse --short baseline)"
else
  git tag -a baseline -m "砂場 (site/) の初期状態"
  echo "打った: $(git rev-parse --short baseline)"
fi
git push origin baseline

if [ -n "$trainee" ]; then
  echo
  echo "== 5. 受講者"
  gh api --method PUT "repos/${nwo}/collaborators/${trainee}" -f permission=push > /dev/null
  gh variable set TRAINEE_LOGIN --body "$trainee"
  echo "collaborator (Write) に招待し、TRAINEE_LOGIN=${trainee} を設定した"
fi

if [ "$skip_issues" -eq 0 ]; then
  echo
  echo "== 6. ラベルと Issue"
  "${here}/seed-issues.sh" --platform github
fi

echo
echo "== 7. 進行ボード"
"${here}/board.sh" update

echo
echo "== 残り (手で行う。scripts/bootstrap.sh を使った場合は済んでいる)"
echo "secret の登録 (値は人が持つ):"
echo "  gh secret set NPC_APP_ID --body <App ID>"
echo "  gh secret set NPC_APP_PRIVATE_KEY < <ダウンロードした .pem>"
echo "App の install: GitHub の Settings > Developer settings > GitHub Apps > <App> > Install App でこのリポジトリだけを選ぶ"
echo "確認: docs/setup.md の表と Settings > Rules > Rulesets を見比べる"
