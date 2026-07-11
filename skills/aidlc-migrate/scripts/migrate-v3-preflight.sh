#!/usr/bin/env bash
#
# migrate-v3-preflight.sh - v2→v3 migration の前提検証
#
# 使用方法:
#   ./migrate-v3-preflight.sh
#
# 出力:
#   stdout: status:ok（全チェック通過時）
#   stderr: warn:one-way-migration:...（常に出力 / 片方向移行警告）
#           error:<code>[:<detail>]（チェック失敗時）
#
# 終了コード:
#   0: 前提チェック通過
#   1: 前提条件エラー（config 不在 / v3 移行済み / dirty worktree / v1 マーカー残存）
#   2: システムエラー（git リポジトリ外 / jq 不在 / state-init.sh・state-validate.sh 解決不可）
#
# 環境変数:
#   AIDLC_STATE_INIT_SCRIPT: state-init.sh の解決候補を単一パスに固定する明示 override
#                            （未設定時は steps/v3-migrate.md Step 5 と同じ 2 候補を順に解決）
#
# 手順方針の正本: docs/v3/migration.md §6
#

set -euo pipefail

AIDLC_PROJECT_ROOT="${AIDLC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null)}" || {
  echo "error:project-root-not-found" >&2; exit 2
}
# 環境変数override時の安全性検証: gitリポジトリであることを確認
if ! git -C "$AIDLC_PROJECT_ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "error:invalid-project-root:$AIDLC_PROJECT_ROOT" >&2; exit 2
fi

# 片方向移行警告（migration.md §1/§5/§7）: チェック結果に関わらず常に明示する
echo "warn:one-way-migration:v2→v3 移行は片方向であり、適用後の v2 への巻き戻し（v2 runtime 互換）は保証されない" >&2

# jq の存在確認（state-init.sh が依存）
if ! command -v jq >/dev/null 2>&1; then
  echo "error:jq-not-found" >&2
  exit 2
fi

# state-init.sh の解決確認（Step 5 の state.json 初期化が依存）。
# config 置換後に state 初期化が依存不備で失敗する部分適用状態を防ぐため、適用前に検証する。
# 候補は steps/v3-migrate.md Step 5 の 2 候補解決と同一に保つ。
_preflight_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_preflight_state_init_candidates=(
  "${_preflight_script_dir}/../../aidlc-v3/scripts/state-init.sh"
  "${_preflight_script_dir}/../../aidlc/scripts/state-init.sh"
)
if [ -n "${AIDLC_STATE_INIT_SCRIPT:-}" ]; then
  _preflight_state_init_candidates=("${AIDLC_STATE_INIT_SCRIPT}")
fi
_preflight_state_init_resolved=""
for _preflight_cand in "${_preflight_state_init_candidates[@]}"; do
  if [ -f "${_preflight_cand}" ] && [ -x "${_preflight_cand}" ]; then
    _preflight_state_init_resolved="${_preflight_cand}"
    break
  fi
done
if [ -z "${_preflight_state_init_resolved}" ]; then
  echo "error:state-init-not-found:state-init.sh を解決できない（実行可能な候補なし）" >&2
  exit 2
fi
_preflight_state_validate="$(dirname "${_preflight_state_init_resolved}")/state-validate.sh"
if [ ! -f "${_preflight_state_validate}" ] || [ ! -x "${_preflight_state_validate}" ]; then
  echo "error:state-validate-not-found:state-init.sh と同ディレクトリに実行可能な state-validate.sh がない" >&2
  exit 2
fi

cd "$AIDLC_PROJECT_ROOT"

# v1 マーカー残存チェック（1 実行 1 世代: v1→v2 を先に完了させる）
if [ -f "docs/aidlc.toml" ]; then
  echo "error:v1-markers-present:docs/aidlc.toml（先に v1→v2 migration を完了させてください）" >&2
  exit 1
fi

# v2 config の存在（v2 環境シグナル）
if [ ! -f ".aidlc/config.toml" ]; then
  echo "error:config-not-found:.aidlc/config.toml（AI-DLC 未セットアップの可能性）" >&2
  exit 1
fi

# state.json 不在（存在 = 既に v3 移行済みシグナル）
if [ -e ".aidlc/state.json" ]; then
  echo "error:already-v3:.aidlc/state.json が存在する（v3 移行済み）" >&2
  exit 1
fi

# clean worktree（適用前状態を git で復元可能にするための必須条件）
if [ -n "$(git status --porcelain)" ]; then
  echo "error:dirty-worktree:未コミット変更がある（commit / stash してから再実行）" >&2
  exit 1
fi

echo "status:ok"
