# プラットフォーム (github | gitlab) の決め方。scripts/*.sh が source する。
# 優先順: 環境変数 KIT_PLATFORM -> kit.conf の PLATFORM -> github

kit_root() {
  git rev-parse --show-toplevel
}

kit_platform() {
  if [ -n "${KIT_PLATFORM:-}" ]; then
    echo "$KIT_PLATFORM"
    return
  fi

  local conf value
  conf="$(kit_root)/kit.conf"

  if [ -f "$conf" ]; then
    value="$(sed -n 's/^PLATFORM=//p' "$conf" | tail -n 1)"

    if [ -n "$value" ]; then
      echo "$value"
      return
    fi
  fi

  echo github
}

kit_require_platform() {
  case "$1" in
    github|gitlab) ;;
    *)
      echo "PLATFORM は github か gitlab です: $1" >&2
      exit 1
      ;;
  esac
}

kit_write_platform() {
  local platform="$1" conf
  kit_require_platform "$platform"
  conf="$(kit_root)/kit.conf"
  {
    echo "# 研修キットの設定。scripts/setup.sh --platform <github|gitlab> が書き換える。"
    echo "# scripts/ はこの値で用語の描画 (PR / MR など) と使う CLI (gh / glab) を切り替える。"
    echo "PLATFORM=${platform}"
  } > "$conf"
}
