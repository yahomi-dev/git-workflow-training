#!/usr/bin/env bash
# 進行ボード: 演習の進み具合と、ブランチの木 (Mermaid の gitGraph) を 1 枚の Markdown にする。
#
# 使い方:
#   scripts/board.sh render   描画した Markdown を標準出力に出す (手元で見る)
#   scripts/board.sh update   label `board` の Issue を作る / 更新して pin する (GitHub。gh か App トークン)
# 前提: git。GitHub の情報 (Issue、PR) は gh でリポジトリに届くときだけ載せる。
# 自動更新は .github/workflows/board.yml (push、PR、Issue の変化で動く)。
set -euo pipefail

cmd="${1:-render}"
cd "$(git rev-parse --show-toplevel)"

main_ref="main"
if git rev-parse -q --verify origin/main > /dev/null; then
  main_ref="origin/main"
fi

have_gh=0
if command -v gh > /dev/null 2>&1 && gh repo view > /dev/null 2>&1; then
  have_gh=1
fi

short_msg() {
  # コミットの 1 行目を 24 文字に切り、Mermaid で困る文字を外す
  local m
  m="$(git log -1 --format=%s "$1" | tr -d '"\\`')"

  if [ "${#m}" -gt 24 ]; then
    m="${m:0:24}..."
  fi

  echo "$m"
}

safe_name() {
  # Mermaid の branch 名に使える形にする (origin/ を外し、英数字と - _ 以外を - に)
  local n="${1#origin/}"
  echo "${n//[^A-Za-z0-9_-]/-}"
}

render_progress() {
  if [ "$have_gh" -eq 0 ]; then
    echo "(GitHub に接続していないので、演習の進み具合は出せません。手元の木だけ描きます)"
    return
  fi

  local json current
  json="$(gh issue list --label quest --state all --limit 100 --json number,title,state)"

  if [ "$(jq length <<< "$json")" -eq 0 ]; then
    echo "(演習の Issue がまだありません。scripts/seed-issues.sh で起票します)"
    return
  fi

  current="$(jq -r '[.[] | select(.state == "OPEN")] | sort_by(.title) | .[0].number // empty' <<< "$json")"
  echo "| 演習 | 状態 | Issue |"
  echo "|---|---|---|"
  jq -r --arg cur "$current" '
    sort_by(.title) | .[] |
    "| \(.title) | \(
      if .state == "CLOSED" then "済"
      elif (.number | tostring) == $cur then "**いまここ**"
      else "まだ" end
    ) | #\(.number) |"
  ' <<< "$json"
}

render_prs() {
  if [ "$have_gh" -eq 0 ]; then
    return
  fi

  echo
  echo "## 開いている PR"
  echo
  local list
  # jq の式に含むバッククォートは Markdown のためのもの (シェルで展開させない)
  # shellcheck disable=SC2016
  list="$(gh pr list --state open --limit 50 --json number,title,headRefName,reviewDecision,isDraft --jq '
    .[] | "- #\(.number) \(.title) (`\(.headRefName)`) " + (
      if .isDraft then "下書き"
      elif .reviewDecision == "APPROVED" then "承認済み。マージできる"
      elif .reviewDecision == "CHANGES_REQUESTED" then "差し戻し中。直して再依頼する"
      else "レビュー待ち" end
    )
  ')"

  if [ -z "$list" ]; then
    echo "なし"
  else
    echo "$list"
  fi
}

render_gitgraph() {
  local -a main_shas branches
  mapfile -t main_shas < <(git rev-list --reverse --max-count=12 "$main_ref")

  if [ "${#main_shas[@]}" -eq 0 ]; then
    echo "(コミットがありません)"
    return
  fi

  local first="${main_shas[0]}" last="${main_shas[${#main_shas[@]}-1]}"

  if [ "$main_ref" = "origin/main" ]; then
    mapfile -t branches < <(git for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -v -E '^origin/(main|HEAD)$' || true)
  else
    mapfile -t branches < <(git for-each-ref --format='%(refname:short)' refs/heads | grep -v -x main || true)
  fi

  # 分岐点 (merge-base) ごとに枝をまとめる。窓より古い分岐点は窓の先頭に付ける
  declare -A attach
  local b mb
  for b in "${branches[@]}"; do
    mb="$(git merge-base "$main_ref" "$b" 2> /dev/null || true)"
    [ -n "$mb" ] || continue

    if ! printf '%s\n' "${main_shas[@]}" | grep -qx "$mb"; then
      mb="$first"
    fi

    attach["$mb"]="${attach[$mb]:-} ${b}"
  done

  echo '```mermaid'
  echo 'gitGraph'
  local sha tag name c
  local -a bshas
  for sha in "${main_shas[@]}"; do
    tag="$(git tag --points-at "$sha" | head -n 1)"
    printf '    commit id: "%s %s"' "$(git rev-parse --short "$sha")" "$(short_msg "$sha")"
    [ -z "$tag" ] || printf ' tag: "%s"' "$tag"
    [ "$sha" != "$last" ] || printf ' type: HIGHLIGHT'
    echo

    for b in ${attach[$sha]:-}; do
      name="$(safe_name "$b")"
      echo "    branch ${name}"
      echo "    checkout ${name}"
      mapfile -t bshas < <(git rev-list --reverse --max-count=8 "${sha}..${b}")
      for c in "${bshas[@]}"; do
        printf '    commit id: "%s %s"\n' "$(git rev-parse --short "$c")" "$(short_msg "$c")"
      done
      echo "    checkout main"
    done
  done
  echo '```'
}

render() {
  echo "# 進行ボード"
  echo
  echo "最後の更新: $(date -u '+%Y-%m-%d %H:%M UTC')。push、PR、Issue の変化で自動更新される。手元で見るときは \`scripts/board.sh render\`。"
  echo
  echo "## いまどこ"
  echo
  render_progress
  render_prs
  echo
  echo "## ブランチの木 (main と、まだマージされていない枝)"
  echo
  echo "右端の強調された丸が今の main。横に出ている線が作業中の枝。タグ (v1.0.0 など) はその時点の main に付けた名前。"
  echo
  render_gitgraph
  echo
  echo "<details><summary>ターミナルで見た形 (git log --graph)</summary>"
  echo
  echo '```text'
  git log --graph --oneline --decorate --all -20
  echo '```'
  echo
  echo "</details>"
  echo
  echo "## 読み方"
  echo
  echo "- 1 つの丸が 1 コミット。main の列が本線で、Squash and merge で入れた PR は本線の 1 コミットになる"
  echo "- 枝が本線から横に出ている間は、まだマージされていない。マージして枝を消すと木から消える"
  echo "- 自分のブランチが main より後ろにいるとき (本線が進んでいる) は、取り込む前に rebase か merge が要る (演習 06、07)"
}

update() {
  [ "$have_gh" -eq 1 ] || { echo "board: gh でリポジトリに届きません" >&2; exit 1; }
  local body num url
  body="$(mktemp)"
  trap 'rm -f "$body"' EXIT
  render > "$body"
  num="$(gh issue list --label board --state open --limit 1 --json number --jq '.[0].number // empty')"

  if [ -z "$num" ]; then
    gh label create board --color 1d76db --description "進行ボード (自動更新)" --force > /dev/null 2>&1 || true
    url="$(gh issue create --title "進行ボード (自動更新)" --label board --body-file "$body")"
    num="${url##*/}"
    gh issue pin "$num" > /dev/null 2>&1 || true
    echo "board: 作った #${num}"
  else
    gh issue edit "$num" --body-file "$body" > /dev/null
    echo "board: 更新した #${num}"
  fi
}

case "$cmd" in
  render) render ;;
  update) update ;;
  *) echo "board: render か update を指定してください" >&2; exit 1 ;;
esac
