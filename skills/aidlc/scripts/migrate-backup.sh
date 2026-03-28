#!/usr/bin/env bash
#
# migrate-backup.sh - manifest内全リソースのバックアップ作成
#
# 使用方法:
#   ./migrate-backup.sh --manifest <path>
#
# 出力:
#   stdout: backup result JSON（backup_dir + files一覧）
#   stderr: バックアップ処理の診断メッセージ
#
# 終了コード:
#   0: 成功
#   2: エラー
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"

# jq の存在確認
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is not installed." >&2
  exit 2
fi

# 引数パース
MANIFEST=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest)
      [[ $# -lt 2 ]] && { echo "Missing value for --manifest" >&2; exit 2; }
      MANIFEST="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$MANIFEST" ]]; then
  echo "Usage: $0 --manifest <path>" >&2
  exit 2
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "Manifest file not found: $MANIFEST" >&2
  exit 2
fi

cd "${AIDLC_PROJECT_ROOT}"

# バックアップディレクトリ作成
BACKUP_DIR=$(mktemp -d /tmp/aidlc-migrate-backup-XXXXXX) || {
  echo "Failed to create backup directory" >&2
  exit 2
}

echo "Creating backup in $BACKUP_DIR ..." >&2

FILES_JSON="[]"

# manifest から全リソースを取得してバックアップ
resource_count=$(jq '.resources | length' "$MANIFEST")
for i in $(seq 0 $((resource_count - 1))); do
  path=$(jq -r ".resources[$i].path" "$MANIFEST")
  resource_type=$(jq -r ".resources[$i].resource_type" "$MANIFEST")

  # ディレクトリの場合
  if [[ "$path" == */ ]] && [[ -d "$path" ]]; then
    backup_path="${BACKUP_DIR}/${path}"
    mkdir -p "$backup_path"
    # cp -R "$path"/. で隠しファイルも含めてコピー
    if cp -R "$path"/. "$backup_path" 2>/dev/null; then
      echo "  Backed up directory: $path" >&2
    else
      echo "  WARNING: Failed to backup directory: $path" >&2
      exit 2
    fi
    FILES_JSON=$(echo "$FILES_JSON" | jq --arg s "$path" --arg b "${backup_path}" '. + [{"source": $s, "backup": $b}]')
    continue
  fi

  # ファイルの場合
  if [[ -f "$path" ]] || [[ -L "$path" ]]; then
    backup_path="${BACKUP_DIR}/${path}"
    mkdir -p "$(dirname "$backup_path")"
    if [[ -L "$path" ]]; then
      # シンボリックリンクはリンク情報を保存
      if ! cp -P "$path" "$backup_path"; then
        echo "  WARNING: Failed to backup symlink: $path" >&2
        exit 2
      fi
    else
      if ! cp "$path" "$backup_path"; then
        echo "  WARNING: Failed to backup file: $path" >&2
        exit 2
      fi
    fi
    echo "  Backed up: $path" >&2
    FILES_JSON=$(echo "$FILES_JSON" | jq --arg s "$path" --arg b "$backup_path" '. + [{"source": $s, "backup": $b}]')
  else
    echo "  Skipping (not found): $path" >&2
  fi
done

echo "Backup complete. ${resource_count} resources processed." >&2

# backup result JSON を出力
jq -n \
  --arg backup_dir "$BACKUP_DIR" \
  --argjson files "$FILES_JSON" \
  '{backup_dir: $backup_dir, files: $files}'
