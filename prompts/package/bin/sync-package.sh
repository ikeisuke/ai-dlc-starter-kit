#!/usr/bin/env bash
# 後方互換ラッパー - 次サイクルで削除予定
# sync-package.sh は prompts/bin/ に移動しました
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# prompts/package/bin/ からの場合: ../../bin/sync-package.sh
# docs/aidlc/bin/ からの場合（sync経由）: ../../../prompts/bin/sync-package.sh
if [[ -x "${SCRIPT_DIR}/../../bin/sync-package.sh" ]]; then
    exec "${SCRIPT_DIR}/../../bin/sync-package.sh" "$@"
elif [[ -x "${SCRIPT_DIR}/../../../prompts/bin/sync-package.sh" ]]; then
    exec "${SCRIPT_DIR}/../../../prompts/bin/sync-package.sh" "$@"
else
    echo "error:sync-package-not-found" >&2
    exit 1
fi
