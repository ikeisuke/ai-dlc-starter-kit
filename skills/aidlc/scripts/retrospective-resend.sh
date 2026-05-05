#!/usr/bin/env bash
# retrospective-resend.sh - Unit 002 スプール再送 CLI
#
# Usage:
#   bash retrospective-resend.sh [--cycle <CYCLE>] [--dry-run] [--strict]
#
# 終了コード:
#   0 - 全エントリが created または skipped で完結（failed が 0 件のみ）
#   1 - failed が 1 件以上含まれる / 中断 / ランタイム異常
#   2 - 引数エラー / spool 不正 / cycle 不在

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/retrospective-issue.sh
source "$SCRIPT_DIR/lib/retrospective-issue.sh"

CYCLE=""
DRY_RUN=false
STRICT=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --cycle <CYCLE>   Target cycle (default: latest cycle in .aidlc/cycles/)
  --dry-run         Show targets and predicted results without spool changes
  --strict          Stop on SHA256 mismatch (default: skip + warn)
  -h, --help        Show this help

Exit codes:
  0  All entries created or skipped (no failures)
  1  At least one entry failed / interrupted / runtime error
  2  Argument error / spool malformed / cycle not found
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --cycle)
            if [[ $# -lt 2 || -z "${2:-}" || "${2:0:2}" == "--" || "${2:0:1}" == "-" ]]; then
                echo "error	missing-value	--cycle requires a non-empty value" >&2
                usage >&2
                exit 2
            fi
            shift
            CYCLE="$1"
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --strict)
            STRICT=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "error	unknown-arg	$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift || true
done

# cycle 自動決定
if [[ -z "$CYCLE" ]]; then
    if [[ ! -d ".aidlc/cycles" ]]; then
        echo "error	no-cycles-dir" >&2
        exit 2
    fi
    CYCLE=$(ls -1 .aidlc/cycles | sort -V | tail -n 1)
    if [[ -z "$CYCLE" ]]; then
        echo "error	no-cycle-found" >&2
        exit 2
    fi
fi

# cycle バリデーション（path traversal 防御 / __retro_validate_cycle は retrospective-issue.sh で定義）
if ! __retro_validate_cycle "$CYCLE"; then
    exit 2
fi

SPOOL_PATH=".aidlc/cycles/$CYCLE/history/retrospective-spool.md"

if [[ ! -f "$SPOOL_PATH" ]]; then
    echo "error	spool-not-found	cycle=$CYCLE	path=$SPOOL_PATH" >&2
    exit 2
fi

# gh_status チェック
GH_STATUS=$(__retro_gh_status)
if [[ "$GH_STATUS" != "available" ]]; then
    echo "error	gh-not-available	status=$GH_STATUS" >&2
    exit 1
fi

echo "resend	cycle	$CYCLE"

# エントリ抽出
ENTRIES_FILE=$(mktemp -t aidlc-resend-entries.XXXXXX)
if ! _spool_extract_entries "$SPOOL_PATH" > "$ENTRIES_FILE"; then
    rm -f "$ENTRIES_FILE"
    exit 2
fi

ENTRY_COUNT=$(wc -l < "$ENTRIES_FILE" | tr -d ' ')
echo "resend	loaded	$ENTRY_COUNT"

CREATED_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0
REMAINING_COUNT=0
IDX=0

# 各エントリを処理
while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    IDX=$((IDX + 1))

    # JSON フィールド抽出
    ID=$(printf '%s' "$entry" | jq -r '.id // empty')
    ENTRY_CYCLE=$(printf '%s' "$entry" | jq -r '.cycle // empty')
    FEEDBACK_MODE=$(printf '%s' "$entry" | jq -r '.feedback_mode // empty')
    TARGET=$(printf '%s' "$entry" | jq -r '.target // empty')
    RETRY_TARGET=$(printf '%s' "$entry" | jq -r '.retry_target // empty')
    LOCAL_CREATED=$(printf '%s' "$entry" | jq -r '.partial_state.local_created // empty')
    MIRROR_CREATED=$(printf '%s' "$entry" | jq -r '.partial_state.mirror_created // empty')
    BODY_B64=$(printf '%s' "$entry" | jq -r '.body_b64 // empty')
    BODY_SHA256=$(printf '%s' "$entry" | jq -r '.body_sha256 // empty')

    if [[ -z "$ID" || -z "$RETRY_TARGET" || -z "$BODY_B64" ]]; then
        echo "resend	processed	$IDX	result=skipped	reason=invalid-entry" >&2
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        REMAINING_COUNT=$((REMAINING_COUNT + 1))
        continue
    fi

    # body デコード + integrity 検証
    BODY_FILE=$(mktemp -t aidlc-resend-body.XXXXXX)
    printf '%s' "$BODY_B64" | __retro_base64_decode > "$BODY_FILE"
    ACTUAL_SHA=$(__retro_sha256 < "$BODY_FILE")
    if [[ "$ACTUAL_SHA" != "$BODY_SHA256" ]]; then
        if [[ "$STRICT" == "true" ]]; then
            echo "error	sha256-mismatch	id=$ID	expected=$BODY_SHA256	actual=$ACTUAL_SHA" >&2
            rm -f "$BODY_FILE" "$ENTRIES_FILE"
            exit 1
        fi
        echo "warn	sha256-mismatch	id=$ID	expected=$BODY_SHA256	actual=$ACTUAL_SHA" >&2
        echo "resend	processed	$IDX	result=skipped	reason=sha256-mismatch"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        REMAINING_COUNT=$((REMAINING_COUNT + 1))
        rm -f "$BODY_FILE"
        continue
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "resend	processed	$IDX	dry-run	id=$ID	retry_target=$RETRY_TARGET	local_created=${LOCAL_CREATED:-null}"
        rm -f "$BODY_FILE"
        continue
    fi

    # retry_target に応じた起票
    # partial_state.local_created が非 null の場合、local 側は再起票せず既存 URL を採用
    RESULT_FILE=$(mktemp -t aidlc-resend-result.XXXXXX)
    SKIP_LOCAL=""
    if [[ -n "$LOCAL_CREATED" && "$LOCAL_CREATED" != "null" ]]; then
        SKIP_LOCAL="1"
    fi
    set +e
    AIDLC_RETRO_FORCE_TARGET="$RETRY_TARGET" \
    AIDLC_RETRO_SKIP_LOCAL="$SKIP_LOCAL" \
        retrospective_issue_create "$BODY_FILE" "$FEEDBACK_MODE" "$ENTRY_CYCLE" > "$RESULT_FILE"
    RC=$?
    set -e

    case $RC in
        0)
            if grep -q '^result=created' "$RESULT_FILE"; then
                URL=$(awk -F'=' '/^(local|mirror)_issue_url=|^issue_url=/{print $2; exit}' "$RESULT_FILE")
                echo "resend	processed	$IDX	result=created	id=$ID	issue_url=$URL"
                _spool_remove_by_id "$SPOOL_PATH" "$ID" || true
                CREATED_COUNT=$((CREATED_COUNT + 1))
            elif grep -q '^result=skipped' "$RESULT_FILE"; then
                REASON=$(awk -F'=' '/^reason=/{print $2; exit}' "$RESULT_FILE")
                echo "resend	processed	$IDX	result=skipped	id=$ID	reason=$REASON"
                _spool_remove_by_id "$SPOOL_PATH" "$ID" || true
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            else
                echo "resend	processed	$IDX	result=spooled	id=$ID	reason=re-spooled" >&2
                REMAINING_COUNT=$((REMAINING_COUNT + 1))
            fi
            ;;
        1)
            REASON=$(awk -F'=' '/^reason=/{print $2; exit}' "$RESULT_FILE")
            echo "resend	processed	$IDX	result=failed	id=$ID	reason=$REASON"
            FAILED_COUNT=$((FAILED_COUNT + 1))
            REMAINING_COUNT=$((REMAINING_COUNT + 1))
            ;;
        *)
            echo "error	resend-fatal	id=$ID	rc=$RC" >&2
            rm -f "$BODY_FILE" "$RESULT_FILE" "$ENTRIES_FILE"
            exit 1
            ;;
    esac
    rm -f "$BODY_FILE" "$RESULT_FILE"
    : "$MIRROR_CREATED" "$TARGET"  # 取得済（将来拡張用 / 未使用 warning 抑止）
done < "$ENTRIES_FILE"

rm -f "$ENTRIES_FILE"

printf 'resend\tsummary\tcreated=%d\tfailed=%d\tskipped=%d\tremaining=%d\n' \
    "$CREATED_COUNT" "$FAILED_COUNT" "$SKIPPED_COUNT" "$REMAINING_COUNT"

if [[ "$FAILED_COUNT" -gt 0 ]]; then
    exit 1
fi
exit 0
