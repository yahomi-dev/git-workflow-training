#!/usr/bin/env bash
# baseline のコピーと編集後のコピーから、リポジトリルート相対のパッチを作る。
#
# 使い方: scripts/npc/make-patch.sh <base-root> <mod-root> <out.patch>
#   <base-root>/site/...  baseline の site/ をコピーしたもの
#   <mod-root>/site/...   編集後。新規ファイルは <mod-root>/.vscode/... のようにルート相対で置く
#   2 つは同じ親ディレクトリに置く (接頭辞を取り除くため)
#
# 出来たパッチは `git apply --check <out.patch>` で当たることを確かめる。
set -euo pipefail

base="${1:?base-root が必要}"
mod="${2:?mod-root が必要}"
out="${3:?出力先が必要}"

parent_b="$(cd "$(dirname "$base")" && pwd)"
parent_m="$(cd "$(dirname "$mod")" && pwd)"

if [ "$parent_b" != "$parent_m" ]; then
  echo "make-patch: base と mod は同じ親ディレクトリに置いてください" >&2
  exit 1
fi

nb="$(basename "$base")"
nm="$(basename "$mod")"
out_dir="$(cd "$(dirname "$out")" 2>/dev/null && pwd || true)"

if [ -z "$out_dir" ]; then
  mkdir -p "$(dirname "$out")"
  out_dir="$(cd "$(dirname "$out")" && pwd)"
fi

out_abs="${out_dir}/$(basename "$out")"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

cd "$parent_b"
# 差分があると終了コードが 1 になるので無視する
git -c core.quotepath=false diff --no-index --no-color -- "$nb" "$nm" > "$tmp" || true

sed -E \
  -e "s#^(diff --git) a/${nb}/(.*) b/${nm}/#\1 a/\2 b/#" \
  -e "s#^(diff --git) a/${nm}/(.*) b/${nm}/#\1 a/\2 b/#" \
  -e "s#^(diff --git) a/${nb}/(.*) b/${nb}/#\1 a/\2 b/#" \
  -e "s#^--- a/${nb}/#--- a/#" \
  -e "s#^--- a/${nm}/#--- a/#" \
  -e "s#^\+\+\+ b/${nm}/#+++ b/#" \
  -e "s#^\+\+\+ b/${nb}/#+++ b/#" \
  "$tmp" > "$out_abs"

if [ ! -s "$out_abs" ]; then
  echo "make-patch: 差分がありません" >&2
  exit 1
fi

echo "make-patch: ${out_abs} ($(grep -c '^diff --git' "$out_abs") files)"
