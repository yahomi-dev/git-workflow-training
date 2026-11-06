#!/usr/bin/env bash
# NPC イベント (a): 受講者が quest/NN-* を push したら、用意したパッチを main に積んで衝突させる。
#
# 前提: main を checkout 済みで、push できるトークンで認証されている (npc-conflict.yml が用意する)。
# 引数: <演習番号 2 桁>。環境変数: NPC_SLUG、GH_TOKEN、GH_REPO
# 冪等: 今の main の内容で判定する (履歴は見ない。リセットで site/ を baseline に戻した後も正しく動く)。
#   パッチが逆向きに当たる = 既に積んである -> 何もしない
#   パッチが当たる        = まだ            -> 積む
#   どちらも当たらない     = main が想定と違う -> 赤で止めて進行役が見る
set -euo pipefail

nn="${1:?演習番号 (2 桁) が必要}"
patch="npc/quests/${nn}/conflict.patch"
message="npc/quests/${nn}/conflict-message.txt"

if [ ! -f "$patch" ]; then
  echo "quest ${nn}: 衝突パッチなし。何もしない"
  exit 0
fi

if [ ! -f "$message" ]; then
  echo "quest ${nn}: ${message} がありません" >&2
  exit 1
fi

if git apply --check --reverse "$patch" 2> /dev/null; then
  echo "quest ${nn}: 既に main に積んである。何もしない"
  exit 0
fi

if ! git apply --check "$patch" 2> /dev/null; then
  echo "quest ${nn}: パッチが main に当たらない。受講者の解消済みの変更が入っているか、site/ が想定と違う。進行役が確認する" >&2
  exit 1
fi

# shellcheck source=scripts/npc/identity.sh
source "$(dirname "$0")/identity.sh"

git apply --3way "$patch"
git commit --quiet -F "$message"
git push origin HEAD:main
echo "quest ${nn}: main に積んだ ($(git rev-parse --short HEAD))"
