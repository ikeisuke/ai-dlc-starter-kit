#!/usr/bin/env bash
#
# key-aliases.sh - 設定キーエイリアスマップ定義（正本）
#
# Git関連設定キーの旧→新統合に伴うエイリアスマッピングを提供する。
# read-config.sh と detect-missing-keys.sh から共有参照される。
#
# 提供する関数:
#   aidlc_normalize_key(key)          - legacy key → canonical key に正規化（冪等）
#   aidlc_get_legacy_key(canonical)   - canonical key → legacy key を返す
#

# legacy key → canonical key に正規化
# canonical key はそのまま返す（冪等）
# 引数: $1 - 設定キー
# 出力: canonical key
aidlc_normalize_key() {
    local key="$1"
    case "$key" in
        rules.branch.mode)
            echo "rules.git.branch_mode" ;;
        rules.unit_branch.enabled)
            echo "rules.git.unit_branch_enabled" ;;
        rules.squash.enabled)
            echo "rules.git.squash_enabled" ;;
        rules.commit.ai_author)
            echo "rules.git.ai_author" ;;
        rules.commit.ai_author_auto_detect)
            echo "rules.git.ai_author_auto_detect" ;;
        *)
            echo "$key" ;;
    esac
}

# canonical key → legacy key を返す
# マップにない場合は空文字
# 引数: $1 - canonical key
# 出力: legacy key（または空文字）
aidlc_get_legacy_key() {
    local canonical="$1"
    case "$canonical" in
        rules.git.branch_mode)
            echo "rules.branch.mode" ;;
        rules.git.unit_branch_enabled)
            echo "rules.unit_branch.enabled" ;;
        rules.git.squash_enabled)
            echo "rules.squash.enabled" ;;
        rules.git.ai_author)
            echo "rules.commit.ai_author" ;;
        rules.git.ai_author_auto_detect)
            echo "rules.commit.ai_author_auto_detect" ;;
        *)
            echo "" ;;
    esac
}
