#!/usr/bin/env bash
# 進行役が最初に 1 回叩く。リポジトリの作成と push -> NPC の GitHub App (Manifest フロー) -> secret -> 設定 (ruleset、baseline、Pages)。
# 残る手作業はブラウザで 2 クリック (App の作成確認と、このリポジトリへの install)。
#
# 使い方: scripts/bootstrap.sh [--repo <owner/name>] [--app-name <App 名>] [--trainee <受講者>] [--new-app] [--port <番号>]
#   --repo      作るリポジトリ (既定: <自分>/<ディレクトリ名>)。remote origin が既にあればそれを使い、作らない
#   --app-name  App の名前。GitHub 全体で一意 (既定: <自分>-hidamari-colleague)
#   --trainee   受講者のログイン名 (後からでもよい。setup.sh か gh variable set で)
#   --new-app   保存済みの App があっても作り直す
#   --port      受け口のポート (既定: 空いているポートを自動で選ぶ)
#
# App は進行役のアカウントに 1 つあればよく、~/.config/git-workflow-training/ に保存して次のリポジトリでも再利用する。
# 前提: gh auth login 済み (scope に workflow)、node 18 以上、jq、作業ツリーが clean で 1 つ以上コミットがある。
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/platform.sh
source "${here}/lib/platform.sh"

repo=""
app_name=""
trainee=""
new_app=0
port=""

while [ $# -gt 0 ]; do
  case "$1" in
    --repo) repo="$2"; shift 2 ;;
    --app-name) app_name="$2"; shift 2 ;;
    --trainee) trainee="$2"; shift 2 ;;
    --new-app) new_app=1; shift ;;
    --port) port="$2"; shift 2 ;;
    *) echo "bootstrap: 不明な引数 $1" >&2; exit 1 ;;
  esac
done

die() {
  echo "bootstrap: $*" >&2
  exit 1
}

open_url() {
  local url="$1"

  if grep -qi microsoft /proc/version 2> /dev/null && command -v explorer.exe > /dev/null 2>&1; then
    explorer.exe "$url" > /dev/null 2>&1 || true
  elif command -v xdg-open > /dev/null 2>&1; then
    xdg-open "$url" > /dev/null 2>&1 || true
  elif command -v open > /dev/null 2>&1; then
    open "$url" > /dev/null 2>&1 || true
  fi

  echo "ブラウザで開く: ${url}"
}

pick_free_port() {
  node -e 'const s = require("node:net").createServer(); s.listen(0, "127.0.0.1", () => { process.stdout.write(String(s.address().port)); s.close(); });'
}

cd "$(kit_root)"

echo "== 0. 前提"
for c in gh node jq curl; do
  command -v "$c" > /dev/null 2>&1 || die "${c} が見つかりません"
done
gh auth status > /dev/null 2>&1 || die "gh auth login を先に行ってください"

scopes="$(gh api -i user 2> /dev/null | grep -i '^x-oauth-scopes:' || true)"

if ! grep -q 'workflow' <<< "$scopes"; then
  echo "gh のトークンに workflow scope が無いので追加します (workflow ファイルを push するため)"
  gh auth refresh -s workflow
fi

login="$(gh api user --jq .login)"
[ -z "$(git status --porcelain)" ] || die "作業ツリーが clean ではありません。先にコミットしてください (例: git add -A && git commit -m '研修キット初版')"
git rev-parse -q --verify HEAD > /dev/null || die "コミットがありません"
echo "アカウント: ${login}"

echo
echo "== 1. リポジトリ"
if git remote get-url origin > /dev/null 2>&1; then
  nwo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
  echo "既存のリポジトリを使う: ${nwo}"
  git push -u origin main > /dev/null 2>&1 || true
else
  [ -n "$repo" ] || repo="${login}/$(basename "$PWD")"
  gh repo create "$repo" --public --source . --remote origin --push \
    --description "チーム開発の流れを GitHub 上で手を動かして学ぶ研修キット (砂場 + NPC)"
  nwo="$repo"
  echo "作った: https://github.com/${nwo}"
fi

echo
echo "== 2. NPC の GitHub App"
conf_dir="${HOME}/.config/git-workflow-training"
app_env="${conf_dir}/npc-app.env"
app_pem="${conf_dir}/npc-app.pem"
mkdir -p "$conf_dir"

if [ -f "$app_env" ] && [ -f "$app_pem" ] && [ "$new_app" -eq 0 ]; then
  # shellcheck source=/dev/null
  source "$app_env"
  echo "保存済みの App を使う: ${NPC_APP_SLUG} (id ${NPC_APP_ID})。作り直すなら --new-app"
else
  [ -n "$app_name" ] || app_name="${login}-hidamari-colleague"
  manifest="$(mktemp)"
  result="$(mktemp)"
  trap 'rm -f "$manifest" "$result"' EXIT

  # webhook は使わないので hook_attributes を書かない (書くと url が必須になり、manifest が拒否される)
  jq -n --arg name "$app_name" --arg url "https://github.com/${nwo}" '{
    name: $name,
    url: $url,
    description: "研修キットの同僚役 (NPC)。衝突を起こし、レビューコメントを付け、欠陥入りの PR を出す",
    public: false,
    default_events: [],
    default_permissions: { contents: "write", pull_requests: "write", issues: "write", metadata: "read" }
  }' > "$manifest"

  [ -n "$port" ] || port="$(pick_free_port)"
  node_err="$(mktemp)"
  trap 'rm -f "$manifest" "$result" "$node_err"' EXIT

  echo "App 名: ${app_name}"
  GH_TOKEN="$(gh auth token)" node "${here}/lib/app-manifest.mjs" --manifest "$manifest" --port "$port" > "$result" 2> "$node_err" &
  node_pid=$!

  # 受け口が立つまで待つ (立たなければブラウザを開かずに止める)
  ready=0
  for _ in $(seq 1 20); do
    kill -0 "$node_pid" 2> /dev/null || break

    if curl -s -o /dev/null "http://127.0.0.1:${port}/"; then
      ready=1
      break
    fi

    sleep 0.3
  done

  if [ "$ready" -ne 1 ]; then
    cat "$node_err" >&2
    die "受け口 (127.0.0.1:${port}) が起動しませんでした。--port <別の番号> で再実行してください"
  fi

  echo "ブラウザが開いたら Create GitHub App を押してください (1 クリック目)"
  open_url "http://127.0.0.1:${port}/"

  if ! wait "$node_pid"; then
    cat "$node_err" >&2
    die "App の作成が完了しませんでした。GitHub 側に App が出来てしまっていたら消してから再実行 (--new-app)"
  fi

  NPC_APP_ID="$(jq -r .id "$result")"
  NPC_APP_SLUG="$(jq -r .slug "$result")"
  (umask 077 && jq -r .pem "$result" > "$app_pem")
  (umask 077 && printf 'NPC_APP_ID=%s\nNPC_APP_SLUG=%s\n' "$NPC_APP_ID" "$NPC_APP_SLUG" > "$app_env")
  echo "作った: $(jq -r .html_url "$result") (id ${NPC_APP_ID})。鍵は ${app_pem} に保存した"
fi

echo
echo "== 3. App をこのリポジトリに install"
installation_has_repo() {
  # App 自身の JWT で「このリポジトリに install されているか」を聞く (gh のトークンでは installations を一覧できない)
  local jwt code
  jwt="$(node "${here}/lib/app-jwt.mjs" --app-id "$NPC_APP_ID" --pem "$app_pem")"
  code="$(curl -s -o /dev/null -w '%{http_code}' \
    -H "Authorization: Bearer ${jwt}" \
    -H "Accept: application/vnd.github+json" \
    -H "User-Agent: git-workflow-training-bootstrap" \
    "https://api.github.com/repos/${nwo}/installation")"
  [ "$code" = "200" ]
}

if installation_has_repo; then
  echo "install 済み"
else
  echo "ブラウザが開いたら、Only select repositories で ${nwo} を選んで Install を押してください (2 クリック目)"
  open_url "https://github.com/apps/${NPC_APP_SLUG}/installations/new"
  waited=0

  until installation_has_repo; do
    sleep 5
    waited=$((waited + 5))

    if [ "$waited" -ge 600 ]; then
      die "10 分待っても install されませんでした。install してから再実行してください (作り直しは不要)"
    fi
  done

  echo "install を確認した"
fi

echo
echo "== 4. secret"
gh secret set NPC_APP_ID --body "$NPC_APP_ID"
gh secret set NPC_APP_PRIVATE_KEY < "$app_pem"
echo "NPC_APP_ID と NPC_APP_PRIVATE_KEY を登録した"

echo
echo "== 5. 設定と起票 (scripts/setup.sh)"
if [ -n "$trainee" ]; then
  "${here}/setup.sh" --platform github --app-id "$NPC_APP_ID" --trainee "$trainee"
else
  "${here}/setup.sh" --platform github --app-id "$NPC_APP_ID"
fi

echo
echo "== 完了"
echo "リポジトリ: https://github.com/${nwo}"
echo "ゲーム画面: https://${nwo%%/*}.github.io/${nwo##*/}/ (初回は Pages のデプロイが終わるまで数分かかる)"
echo "次: docs/setup.md の煙テスト (quest/04-smoke ブランチで PR を 1 本開き、check と npc-review が動き、ゲーム画面に枝が出ることを見る)"
[ -n "$trainee" ] || echo "受講者が決まったら: gh variable set TRAINEE_LOGIN --body <ログイン名> と、Settings > Collaborators で招待 (または scripts/setup.sh --trainee)"
