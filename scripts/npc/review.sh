#!/usr/bin/env bash
# NPC イベント (b): 受講者の PR が開いたら、確認依頼型のコメントを 1 ファイル 1 論点で付ける。
#
# できるだけ site/index.html へのファイル単位のレビューコメントにする (スレッドになり、Resolve の操作を練習できる)。
# 対象ファイルが差分に無いなどで失敗したら、PR 全体へのコメントにフォールバックする。
# 引数: <演習番号 2 桁> <PR 番号> <head の SHA>。環境変数: GH_TOKEN、GH_REPO
set -euo pipefail

nn="${1:?演習番号 (2 桁) が必要}"
pr="${2:?PR 番号が必要}"
sha="${3:?head の SHA が必要}"
dir="npc/quests/${nn}/review"
target="site/index.html"

if [ ! -d "$dir" ]; then
  echo "quest ${nn}: レビューコメントなし。何もしない"
  exit 0
fi

post_file_comment() {
  local file="$1"
  jq -n --rawfile body "$file" --arg sha "$sha" --arg path "$target" \
    '{body: $body, commit_id: $sha, path: $path, subject_type: "file"}' \
    | gh api --method POST "repos/${GH_REPO}/pulls/${pr}/comments" --input - > /dev/null
}

posted=0
for file in "$dir"/*.md; do
  [ -f "$file" ] || continue

  if post_file_comment "$file" 2> /dev/null; then
    echo "file comment: ${file}"
  else
    gh pr comment "$pr" --body-file "$file" > /dev/null
    echo "pr comment (fallback): ${file}"
  fi

  posted=$((posted + 1))
done

if [ "$posted" -gt 0 ]; then
  gh pr review "$pr" --comment \
    --body "レビューしました。${posted} 点、確認をお願いします。1 コメント 1 論点なので、1 つずつ返信してから Resolve してください。"
fi

echo "quest ${nn}: ${posted} 件コメントした"
