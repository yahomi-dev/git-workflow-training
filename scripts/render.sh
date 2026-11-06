#!/usr/bin/env bash
# 演習ファイル (exercises/*.md) をプラットフォーム向けに描画して標準出力に出す (手元での確認用。
# ゲーム画面 web/lib/quests.mjs も同じ規則で描画する)。
#
#   - {{name}} を web/terms/<platform>.json の値で置き換える
#   - <!-- platform:github --> ... <!-- /platform --> のブロックは、指定プラットフォームのものだけ残す
#   - --section quest|notes で、<!-- quest:start --> .. <!-- quest:end --> (または notes) の中だけを出す (旧名 issue も可)
#   - --base-url <URL> で、docs/ などへの相対リンクを絶対 URL にする
#
# 使い方: scripts/render.sh [--platform github|gitlab] [--section quest|notes] [--base-url URL] <file>
# 置換されずに残った {{...}} があれば、警告を出して終了コード 1 にする。
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/platform.sh
source "${here}/lib/platform.sh"

platform=""
section=""
base_url=""

while [ $# -gt 0 ]; do
  case "$1" in
    --platform) platform="$2"; shift 2 ;;
    --section) section="$2"; shift 2 ;;
    --base-url) base_url="$2"; shift 2 ;;
    --) shift; break ;;
    -*) echo "render: 不明なオプション $1" >&2; exit 1 ;;
    *) break ;;
  esac
done

file="${1:?描画するファイルが必要}"
[ -n "$platform" ] || platform="$(kit_platform)"
kit_require_platform "$platform"
terms_file="$(kit_root)/web/terms/${platform}.json"
[ -f "$terms_file" ] || { echo "render: ${terms_file} がありません" >&2; exit 1; }

# 旧名 issue は quest として扱う
[ "$section" != "issue" ] || section="quest"
alias_section=""
[ "$section" != "quest" ] || alias_section="issue"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# 1. セクションの切り出しとプラットフォーム別ブロックの選別
awk -v platform="$platform" -v section="$section" -v alias_section="$alias_section" '
  BEGIN { keep = 1; inside = (section == "") }
  function is_marker(line, name, kind) {
    return name != "" && index(line, "<!-- " name ":" kind " -->") > 0
  }
  {
    if (is_marker($0, section, "start") || is_marker($0, alias_section, "start")) { inside = 1; next }
    if (is_marker($0, section, "end") || is_marker($0, alias_section, "end")) { inside = 0; next }
    if (!inside) next
    if ($0 ~ /^<!-- platform:[a-z]+ -->[ \t]*$/) {
      p = $0
      sub(/^<!-- platform:/, "", p)
      sub(/ -->[ \t]*$/, "", p)
      keep = (p == platform)
      next
    }
    if ($0 ~ /^<!-- \/platform -->[ \t]*$/) { keep = 1; next }
    if (keep) print
  }
' "$file" > "$tmp"

# 2. 用語の置換 (値の区切り文字と特殊文字をエスケープする)
while IFS=$'\t' read -r name value; do
  escaped="$(printf '%s' "$value" | sed -e 's/[\\|&]/\\&/g')"
  sed -i "s|{{${name}}}|${escaped}|g" "$tmp"
done < <(jq -r 'to_entries[] | "\(.key)\t\(.value)"' "$terms_file")

# 3. 相対リンクを絶対 URL にする (exercises/ からの ../docs/... と、ルートからの docs/... の両方)
if [ -n "$base_url" ]; then
  sed -i -E "s#\]\((\.\./)?((docs|site|npc|scripts|exercises|\.github)/)#](${base_url}/\2#g" "$tmp"
fi

cat "$tmp"

if grep -n '{{[a-z_]*}}' "$tmp" >&2; then
  echo "render: 置換されていない {{...}} があります (${file})" >&2
  exit 1
fi
