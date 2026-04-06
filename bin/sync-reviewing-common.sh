#!/usr/bin/env bash
set -euo pipefail

# sync-reviewing-common.sh
# 正本（skills/reviewing-common/reviewing-common-base.md）を
# 9つのReviewingスキルの references/ にコピーする。

SOURCE="skills/reviewing-common/reviewing-common-base.md"

TARGETS=(
  "skills/reviewing-construction-code/references/reviewing-common-base.md"
  "skills/reviewing-construction-design/references/reviewing-common-base.md"
  "skills/reviewing-construction-integration/references/reviewing-common-base.md"
  "skills/reviewing-construction-plan/references/reviewing-common-base.md"
  "skills/reviewing-inception-intent/references/reviewing-common-base.md"
  "skills/reviewing-inception-stories/references/reviewing-common-base.md"
  "skills/reviewing-inception-units/references/reviewing-common-base.md"
  "skills/reviewing-operations-deploy/references/reviewing-common-base.md"
  "skills/reviewing-operations-premerge/references/reviewing-common-base.md"
)

usage() {
  echo "Usage: bin/sync-reviewing-common.sh [--dry-run | --verify]" >&2
  echo "  --dry-run  Show what would be updated without copying" >&2
  echo "  --verify   Verify all targets match the source" >&2
  exit 2
}

MODE="sync"
if [[ $# -gt 1 ]]; then
  usage
elif [[ $# -eq 1 ]]; then
  case "$1" in
    --dry-run) MODE="dry-run" ;;
    --verify)  MODE="verify" ;;
    *)         usage ;;
  esac
fi

if [[ ! -f "$SOURCE" ]]; then
  echo "error: source file not found: $SOURCE" >&2
  exit 1
fi

source_md5=$(md5 -q "$SOURCE" 2>/dev/null || md5sum "$SOURCE" | cut -d' ' -f1)
updated=0
checked=0
errors=0

for target in "${TARGETS[@]}"; do
  checked=$((checked + 1))

  if [[ ! -f "$target" ]]; then
    if [[ "$MODE" == "verify" ]]; then
      echo "verify: $target (MISSING)" >&2
      errors=$((errors + 1))
    elif [[ "$MODE" == "dry-run" ]]; then
      echo "dry-run: $target (would create)"
    else
      cp "$SOURCE" "$target"
      echo "sync: $target (created)"
      updated=$((updated + 1))
    fi
    continue
  fi

  target_md5=$(md5 -q "$target" 2>/dev/null || md5sum "$target" | cut -d' ' -f1)

  if [[ "$source_md5" != "$target_md5" ]]; then
    if [[ "$MODE" == "verify" ]]; then
      echo "verify: $target (MISMATCH)" >&2
      errors=$((errors + 1))
    elif [[ "$MODE" == "dry-run" ]]; then
      echo "dry-run: $target (would update)"
      updated=$((updated + 1))
    else
      cp "$SOURCE" "$target"
      echo "sync: $target (updated)"
      updated=$((updated + 1))
    fi
  else
    if [[ "$MODE" == "verify" ]]; then
      echo "verify: $target (OK)"
    elif [[ "$MODE" == "dry-run" ]]; then
      echo "dry-run: $target (unchanged)"
    else
      echo "sync: $target (unchanged)"
    fi
  fi
done

total=${#TARGETS[@]}
case "$MODE" in
  verify)
    if [[ $errors -gt 0 ]]; then
      echo "verify: $total files checked, $errors mismatches" >&2
      exit 1
    else
      echo "verify: $total/$total files OK"
    fi
    ;;
  dry-run)
    echo "dry-run: $total files checked, $updated would be updated"
    ;;
  sync)
    echo "sync: $total/$total files checked, $updated updated"
    ;;
esac
