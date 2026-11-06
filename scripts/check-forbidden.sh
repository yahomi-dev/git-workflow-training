#!/usr/bin/env bash
# 禁止文字列の検査。CI (check) と、公開前の手元確認で使う。
#
# 使い方:
#   scripts/check-forbidden.sh --all          git 管理下の全ファイルを見る
#   scripts/check-forbidden.sh <file>...      指定したファイルだけ見る
#
# 見るもの: トークンや秘密鍵らしき文字列、.env 系のファイル名。
# 見ないもの: 一般的なローカルパスや文言 (人が見る。演習 08 の欠陥はここを通る)。
# 誤検出は、その行に `forbidden-check: allow` を含めて理由を書くと除外される。
set -euo pipefail

patterns=(
  'ghp_[A-Za-z0-9]{20,}'
  'github_pat_[A-Za-z0-9_]{20,}'
  'glpat-[A-Za-z0-9_-]{20,}'
  'BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY'
  'AKIA[0-9A-Z]{16}'
)
allow_marker='forbidden-check: allow'

if [ "${1:-}" = "--all" ]; then
  # 追跡済みに加え、まだ add していないファイルも見る (gitignore 済みは除く)
  mapfile -t files < <(git ls-files --cached --others --exclude-standard)
else
  files=("$@")
fi

if [ "${#files[@]}" -eq 0 ]; then
  echo "check-forbidden: 対象ファイルがありません"
  exit 0
fi

grep_args=()
for p in "${patterns[@]}"; do
  grep_args+=(-e "$p")
done

status=0
for f in "${files[@]}"; do
  [ -f "$f" ] || continue

  case "$f" in
    scripts/check-forbidden.sh) continue ;;
  esac

  base="$(basename -- "$f")"
  case "$base" in
    .env|.env.*)
      echo "forbidden: ${f}: .env 系のファイルはコミットしない"
      status=1
      ;;
  esac

  while IFS= read -r hit; do
    case "$hit" in
      *"$allow_marker"*) continue ;;
    esac
    echo "forbidden: ${f}:${hit}"
    status=1
  done < <(grep -n -E -I "${grep_args[@]}" -- "$f" || true)
done

if [ "$status" -eq 0 ]; then
  echo "check-forbidden: OK (${#files[@]} files)"
fi
exit "$status"
