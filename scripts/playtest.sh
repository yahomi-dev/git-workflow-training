#!/usr/bin/env bash
# GitHub なしで演習 03〜10 の手順を通す (保守用の自動テストプレイ)。
#
# 作業ディレクトリに模擬の origin (bare)、GitHub 役、NPC 役、受講者役の clone を作り、
# 各演習の Issue に書いてあるコマンドを受講者役が順に打つ。NPC は本物の scripts/npc/conflict.sh を使う。
# PR のマージは GitHub 役が Squash / Rebase and merge と同じ結果になるように行う。
# main への直接 push は pre-receive hook が拒否する (ruleset の模擬)。
#
# 使い方: scripts/playtest.sh [--keep]
#   --keep  終了後も作業ディレクトリを残す (中を見たいとき)
# 前提: git、bash。html-validate (npx) があれば最後に HTML も検証する。
# 対象は今の作業ツリー (未コミットの変更も含む。gitignore 済みは除く)。
set -euo pipefail

keep=0
[ "${1:-}" = "--keep" ] && keep=1

src="$(git rev-parse --show-toplevel)"
work="$(mktemp -d)"
step_name="(準備)"

on_exit() {
  local code=$?

  if [ "$code" -ne 0 ]; then
    echo
    echo "playtest: 失敗: ${step_name}" >&2
    echo "playtest: 作業ディレクトリ: ${work}" >&2
    exit "$code"
  fi

  if [ "$keep" -eq 1 ]; then
    echo "playtest: 作業ディレクトリを残した: ${work}"
  else
    rm -rf "$work"
  fi
}
trap on_exit EXIT

step() {
  step_name="$1"
  echo
  echo "== ${step_name}"
}

expect_grep() {
  # expect_grep <pattern> <file> [説明]
  if ! grep -q -F -- "$1" "$2"; then
    echo "期待した文字列がない: '$1' in $2 ${3:-}" >&2
    return 1
  fi
}

expect_fail() {
  # 失敗するはずのコマンド。成功したらエラー
  if "$@" > "${work}/expect_fail.log" 2>&1; then
    echo "失敗するはずのコマンドが成功した: $*" >&2
    return 1
  fi
}

origin="${work}/origin.git"
server="${work}/server"
npc="${work}/npc"
trainee="${work}/trainee"

# ---- 準備: 模擬 origin と baseline -------------------------------------------------

step "準備: 模擬 origin と baseline"
git init --quiet --bare --initial-branch=main "$origin"

cat > "${origin}/hooks/pre-receive" << 'EOF'
#!/usr/bin/env bash
# main への直接 push を拒否する (ruleset の模擬)。PLAYTEST_ALLOW_MAIN=1 のとき (GitHub 役と NPC 役) だけ通す
while read -r _old _new ref; do
  if [ "$ref" = "refs/heads/main" ] && [ -z "${PLAYTEST_ALLOW_MAIN:-}" ]; then
    echo "error: GH013: Repository rule violations found for refs/heads/main. (playtest の模擬)" >&2
    echo "- Changes must be made through a pull request." >&2
    exit 1
  fi
done
EOF
chmod +x "${origin}/hooks/pre-receive"

seed="${work}/seed"
mkdir -p "$seed"
(cd "$src" && git ls-files --cached --others --exclude-standard -z | tar --null -cf - -T -) | tar -xf - -C "$seed"
(
  cd "$seed"
  git init --quiet --initial-branch=main
  git config user.name "kit-maintainer"
  git config user.email "kit-maintainer@example.com"
  git add --all
  git commit --quiet -m "baseline"
  git tag -a baseline -m "砂場 (site/) の初期状態"
  git remote add origin "$origin"
  PLAYTEST_ALLOW_MAIN=1 git push --quiet -u origin main
  git push --quiet origin baseline
)

git clone --quiet "$origin" "$server"
git -C "$server" config user.name "github-role"
git -C "$server" config user.email "github-role@example.com"

git clone --quiet "$origin" "$npc"

git clone --quiet "$origin" "$trainee"
git -C "$trainee" config user.name "playtest-trainee"
git -C "$trainee" config user.email "0+playtest-trainee@users.noreply.github.com"

pr_counter=0

# GitHub 役: Squash and merge
merge_squash() {
  local branch="$1" title="$2"
  pr_counter=$((pr_counter + 1))
  (
    cd "$server"
    git fetch --quiet origin
    git switch --quiet main
    git pull --quiet --ff-only
    git merge --quiet --squash "origin/${branch}"
    git commit --quiet -m "${title} (#${pr_counter})"
    PLAYTEST_ALLOW_MAIN=1 git push --quiet
    git push --quiet origin --delete "$branch"
  )
  echo "GitHub 役: Squash and merge #${pr_counter} ${branch}"
}

# GitHub 役: Rebase and merge (ff できる状態でも SHA を書き換える)
merge_rebase() {
  local branch="$1"
  pr_counter=$((pr_counter + 1))
  (
    cd "$server"
    git fetch --quiet origin
    git switch --quiet main
    git pull --quiet --ff-only
    git switch --quiet -c tmp-rebase "origin/${branch}"
    GIT_EDITOR=true git rebase --quiet --force-rebase main
    git switch --quiet main
    git merge --quiet --ff-only tmp-rebase
    git branch --quiet -D tmp-rebase
    PLAYTEST_ALLOW_MAIN=1 git push --quiet
    git push --quiet origin --delete "$branch"
  )
  echo "GitHub 役: Rebase and merge #${pr_counter} ${branch}"
}

# NPC 役: 本物の conflict.sh
npc_conflict() {
  local nn="$1"
  (
    cd "$npc"
    git fetch --quiet origin
    git switch --quiet main
    git pull --quiet --ff-only
    PLAYTEST_ALLOW_MAIN=1 NPC_NAME="hidamari-colleague[bot]" \
      NPC_EMAIL="0+hidamari-colleague[bot]@users.noreply.github.com" \
      GH_TOKEN=playtest GH_REPO=playtest/playtest \
      scripts/npc/conflict.sh "$nn"
  )
}

# 受講者役: 演習の後片付け
trainee_cleanup() {
  local branch="$1"
  git switch --quiet main
  git pull --quiet
  git branch --quiet -d "$branch"
}

index="site/index.html"
cd "$trainee"

# ---- quest-03 -------------------------------------------------------------------------

step "quest-03: 最初の commit と push (main への push は拒否される)"
git switch --quiet main
git pull --quiet
printf -- '- playtest-trainee\n' >> site/README.md
git add site/README.md
git commit --quiet -m "編集メンバーに自分を追加する"
expect_fail git push origin main
expect_grep "GH013" "${work}/expect_fail.log" "(main への push が拒否される)"
git switch --quiet -c quest/03-add-member
git switch --quiet main
git reset --quiet --hard origin/main
git switch --quiet quest/03-add-member
git push --quiet -u origin quest/03-add-member
merge_squash quest/03-add-member "quest-03: 編集メンバーに自分を追加する"
trainee_cleanup quest/03-add-member
expect_grep "- playtest-trainee" site/README.md

# ---- quest-04 -------------------------------------------------------------------------

step "quest-04: お知らせを先頭に 1 件追加"
git switch --quiet -c quest/04-add-notice
expect_grep '<ul class="news-list">' "$index"
sed -i 's|^\( *\)<ul class="news-list">|&\n\1  <li>読み聞かせ会を毎月第 3 日曜 14:00 に開きます。</li>|' "$index"
git add "$index"
git commit --quiet -m "お知らせに読み聞かせ会の案内を追加する"
git push --quiet -u origin quest/04-add-notice
merge_squash quest/04-add-notice "quest-04: お知らせに読み聞かせ会の案内を追加する"
trainee_cleanup quest/04-add-notice
expect_grep "読み聞かせ会を毎月第 3 日曜" "$index"
[ "$(grep -c '<li>' "$index")" -ge 6 ] || { echo "お知らせとおすすめ本の li の数が想定外" >&2; exit 1; }

# ---- quest-05 -------------------------------------------------------------------------

step "quest-05: 注記を追加し、差し戻しで文言を直す"
git switch --quiet -c quest/05-entry-note
expect_grep '</table>' "$index"
sed -i 's|^\( *\)</table>|&\n\1<p class="hours-note">入館は閉館の少し前までにお願いします。</p>|' "$index"
git add "$index"
git commit --quiet -m "開館時間の表に入館の注記を追加する"
git push --quiet -u origin quest/05-entry-note
# 差し戻し (REQ-01): 文言を Issue の追記に合わせる
sed -i 's|閉館の少し前まで|閉館の 15 分前まで|' "$index"
git add "$index"
git commit --quiet -m "注記の文言を Issue の追記に合わせる"
git push --quiet
merge_squash quest/05-entry-note "quest-05: 開館時間の表に入館の注記を追加する"
trainee_cleanup quest/05-entry-note
expect_grep "入館は閉館の 15 分前までにお願いします。" "$index"

# ---- quest-06 -------------------------------------------------------------------------

step "quest-06: 衝突を merge で解消 (両方の意図を残す)"
git switch --quiet -c quest/06-saturday-hours
expect_grep '<td>10:00〜17:00</td>' "$index"
sed -i 's|<td>10:00〜17:00</td>|<td>10:00〜18:00</td>|' "$index"
git add "$index"
git commit --quiet -m "土曜の閉館時間を 18:00 に延ばす"
git push --quiet -u origin quest/06-saturday-hours
npc_conflict 06
npc_conflict 06   # 2 回目は何もしないこと (冪等)
git fetch --quiet origin
expect_fail git merge origin/main
expect_grep "CONFLICT" "${work}/expect_fail.log" "(merge で衝突する)"
expect_grep "<<<<<<< HEAD" "$index"
awk '
  /^<<<<<<< / { skipping = 1; print "              <td>10:00〜18:00 (12 月〜2 月は 16:00 まで)</td>"; next }
  /^>>>>>>> / { skipping = 0; next }
  skipping != 1 { print }
' "$index" > "${index}.resolved"
mv "${index}.resolved" "$index"
git add "$index"
GIT_EDITOR=true git commit --quiet --no-edit
git push --quiet
merge_squash quest/06-saturday-hours "quest-06: 土曜の閉館時間を 18:00 に延ばす"
trainee_cleanup quest/06-saturday-hours
expect_grep "<td>10:00〜18:00 (12 月〜2 月は 16:00 まで)</td>" "$index"
expect_grep "NPC-Quest: 06" <(git log --format=%B -5) "(NPC のコミットが main にある)"

# ---- quest-07 -------------------------------------------------------------------------

step "quest-07: 3 コミット -> rebase で衝突解消 (自分の側) -> squash -> force-with-lease -> Rebase and merge"
git switch --quiet -c quest/07-replace-pick
expect_grep '<li>『ひだまり通りの猫たち』</li>' "$index"
sed -i 's|『ひだまり通りの猫たち』|『図書室のまどかか』|' "$index"
git commit --quiet -am "おすすめ本の 1 冊目を差し替える"
sed -i 's|『図書室のまどかか』|『図書室のまどから』|' "$index"
git commit --quiet -am "題名の誤字を直す"
sed -i 's|『図書室のまどから』</li>|『図書室のまどから』 (ひだまり文庫)</li>|' "$index"
git commit --quiet -am "出版社を添える"
[ "$(git rev-list --count origin/main..HEAD)" -eq 3 ] || { echo "3 コミットになっていない" >&2; exit 1; }
git push --quiet -u origin quest/07-replace-pick
npc_conflict 07
git fetch --quiet origin
expect_fail env GIT_EDITOR=true git rebase origin/main
expect_grep "CONFLICT" "${work}/expect_fail.log" "(rebase で衝突する)"
git checkout --quiet --theirs "$index"   # rebase 中の theirs = 自分のコミット
expect_grep '『図書室のまどかか』' "$index"
git add "$index"
GIT_EDITOR=true git rebase --continue > /dev/null
git merge-base --is-ancestor origin/main HEAD || { echo "ff できる状態になっていない" >&2; exit 1; }
[ "$(git rev-list --count origin/main..HEAD)" -eq 3 ] || { echo "rebase 後に 3 コミットではない" >&2; exit 1; }
git reset --quiet --soft origin/main
git commit --quiet -m "おすすめ本の 1 冊目を『図書室のまどから』に差し替える"
[ "$(git rev-list --count origin/main..HEAD)" -eq 1 ] || { echo "squash 後に 1 コミットではない" >&2; exit 1; }
expect_fail git push                      # 履歴を書き換えたので普通の push は拒否される
git push --quiet --force-with-lease
branch_sha="$(git rev-parse HEAD)"
merge_rebase quest/07-replace-pick
trainee_cleanup quest/07-replace-pick
expect_grep '『図書室のまどから』 (ひだまり文庫)' "$index"
[ "$(git rev-parse HEAD)" != "$branch_sha" ] || { echo "Rebase and merge で SHA が変わっていない" >&2; exit 1; }

# ---- quest-08 (パッチが当たることだけ確認。PR 作成は gh が要る) -------------------------

step "quest-08: NPC の欠陥入りパッチが今の main に当たる"
(
  cd "$npc"
  git fetch --quiet origin
  git switch --quiet main
  git pull --quiet --ff-only
  git switch --quiet -c npc/08-reading-circle-notice
  git apply --3way npc/quests/08/pr.patch
  git add --all
  git commit --quiet -F npc/quests/08/pr-message.txt
  git push --quiet -u origin npc/08-reading-circle-notice
  expect_grep 'news-item-featured' site/index.html
  expect_grep 'news-item-featurd' site/style.css
  [ -f site/config.sample.js ] || { echo "config.sample.js が無い" >&2; exit 1; }
  [ -f .vscode/settings.json ] || { echo ".vscode/settings.json が無い" >&2; exit 1; }
  scripts/check-forbidden.sh site/config.sample.js site/index.html site/style.css > /dev/null
  git switch --quiet main
)

# ---- quest-09 -------------------------------------------------------------------------

step "quest-09: revert"
target_sha="$(git rev-parse HEAD)"
git switch --quiet -c quest/09-revert-pick
GIT_EDITOR=true git revert --no-edit "$target_sha" > /dev/null
expect_grep '<li>『春のおべんとう図鑑』</li>' "$index"
git push --quiet -u origin quest/09-revert-pick
merge_squash quest/09-revert-pick "quest-09: おすすめ本の差し替えを取り消す"
trainee_cleanup quest/09-revert-pick
expect_grep '<li>『春のおべんとう図鑑』</li>' "$index"

# ---- quest-10 -------------------------------------------------------------------------

step "quest-10: タグ -> hotfix -> タグ"
git tag -a v1.0.0 -m "初回リリース"
git push --quiet origin v1.0.0
git switch --quiet -c hotfix/access-link
expect_grep '<a href="access.html">アクセス</a>' "$index"
sed -i 's|<a href="access.html">アクセス</a>|<a href="#access">アクセス</a>|' "$index"
sed -i 's|^\( *\)<p class="site-note">|\1<p id="access" class="access">アクセス: ひだまり通り 1-2-3 (架空の住所)。バス停「ひだまり通り」からすぐ。</p>\n&|' "$index"
git add "$index"
git commit --quiet -m "hotfix: フッタのアクセスのリンク切れを直す"
git push --quiet -u origin hotfix/access-link
merge_squash hotfix/access-link "hotfix: フッタのアクセスのリンク切れを直す"
trainee_cleanup hotfix/access-link
git tag -a v1.0.1 -m "hotfix: アクセスのリンク切れを直した"
git push --quiet origin v1.0.1
expect_grep 'id="access"' "$index"
expect_grep 'href="#access"' "$index"
git ls-remote --tags origin | grep -q 'refs/tags/v1.0.0$' || { echo "v1.0.0 が origin に無い" >&2; exit 1; }
git ls-remote --tags origin | grep -q 'refs/tags/v1.0.1$' || { echo "v1.0.1 が origin に無い" >&2; exit 1; }

# ---- 仕上げ ---------------------------------------------------------------------------

step "仕上げ: 最終状態の検証"
scripts/check-forbidden.sh site/index.html site/style.css site/README.md > /dev/null

if command -v npx > /dev/null 2>&1; then
  npx --yes html-validate@9 "$index" > /dev/null 2>&1 && echo "html-validate: main OK"
  (cd "$npc" && git switch --quiet npc/08-reading-circle-notice && npx --yes html-validate@9 site/index.html > /dev/null 2>&1 && echo "html-validate: NPC の PR も通る (欠陥は人が見る)")
else
  echo "npx が無いので html-validate は省略"
fi

echo
echo "main の履歴:"
git log --oneline --decorate -12
echo
echo "playtest: OK (quest-03 .. quest-10)"
