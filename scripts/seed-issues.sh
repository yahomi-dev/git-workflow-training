#!/usr/bin/env bash
# exercises/*.md の Issue 本文を、プラットフォーム向けに描画して起票する。
#
# 使い方: scripts/seed-issues.sh [--platform github|gitlab] [--only NN] [--dry-run]
#   --only NN   その演習だけ起票する
#   --dry-run   起票せず、タイトルと本文を標準出力に出す
# 前提: GitHub は `gh auth login` 済み、GitLab は `glab auth login` 済み。リポジトリの中で実行する。
#
# 演習ファイルの先頭にあるメタ情報を読む:
#   <!-- kit
#   title: quest-04: お知らせを 1 件追加する
#   week: 1
#   -->
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/platform.sh
source "${here}/lib/platform.sh"

platform=""
only=""
dry_run=0

while [ $# -gt 0 ]; do
  case "$1" in
    --platform) platform="$2"; shift 2 ;;
    --only) only="$2"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    *) echo "seed-issues: 不明な引数 $1" >&2; exit 1 ;;
  esac
done

[ -n "$platform" ] || platform="$(kit_platform)"
kit_require_platform "$platform"
cd "$(kit_root)"

remote_web_url() {
  # remote が無ければ空を返す (dry-run を手元で試せるように)
  local url
  url="$(git remote get-url origin 2> /dev/null || true)"
  [ -n "$url" ] || return 0
  url="${url%.git}"
  case "$url" in
    git@*) url="https://${url#git@}"; url="${url/://}" ;;
    ssh://git@*) url="https://${url#ssh://git@}" ;;
  esac
  echo "$url"
}

base_url="$(remote_web_url)"

case "$platform" in
  github)
    [ -z "$base_url" ] || base_url="${base_url}/blob/main"
    ensure_labels() {
      gh label create quest --color 0e8a16 --description "研修の演習" --force > /dev/null
      gh label create npc --color 8250df --description "NPC (同僚役) の PR" --force > /dev/null
      gh label create board --color 1d76db --description "進行ボード (自動更新)" --force > /dev/null
      local w
      for w in 1 2 3 4; do
        gh label create "week-${w}" --color c5def5 --description "第 ${w} 週" --force > /dev/null
      done
    }
    create_issue() {
      gh issue create --title "$1" --body-file "$2" --label "$3"
    }
    ;;
  gitlab)
    [ -z "$base_url" ] || base_url="${base_url}/-/blob/main"
    ensure_labels() {
      glab label create --name quest --color '#0e8a16' --description "研修の演習" > /dev/null 2>&1 || true
      glab label create --name npc --color '#8250df' --description "NPC (同僚役) の MR" > /dev/null 2>&1 || true
      local w
      for w in 1 2 3 4; do
        glab label create --name "week-${w}" --color '#c5def5' --description "第 ${w} 週" > /dev/null 2>&1 || true
      done
    }
    create_issue() {
      glab issue create --title "$1" --description "$(cat "$2")" --label "$3" --yes
    }
    ;;
esac

meta_value() {
  # 描画済みファイルの先頭の <!-- kit ... --> から key の値を取る
  sed -n '/^<!-- kit$/,/^-->$/p' "$1" | sed -n "s/^$2: //p" | head -n 1
}

if [ "$dry_run" -eq 0 ]; then
  ensure_labels
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

count=0
for file in exercises/[0-9][0-9]-*.md; do
  [ -f "$file" ] || continue
  nn="$(basename "$file" | cut -c1-2)"

  if [ -n "$only" ] && [ "$nn" != "$only" ]; then
    continue
  fi

  if ! grep -q '^<!-- kit$' "$file"; then
    echo "skip (メタ情報なし): ${file}" >&2
    continue
  fi

  rendered="${tmp_dir}/${nn}.md"
  body="${tmp_dir}/${nn}-issue.md"
  "${here}/render.sh" --platform "$platform" "$file" > "$rendered"
  "${here}/render.sh" --platform "$platform" --section issue --base-url "$base_url" "$file" > "$body"

  title="$(meta_value "$rendered" title)"
  week="$(meta_value "$rendered" week)"
  labels="quest"
  [ -z "$week" ] || labels="${labels},week-${week}"

  if [ "$dry_run" -eq 1 ]; then
    echo "===== ${title} [${labels}] ====="
    cat "$body"
    echo
  else
    create_issue "$title" "$body" "$labels"
  fi

  count=$((count + 1))
done

echo "seed-issues: ${count} 件 (${platform}, dry-run=${dry_run})"
