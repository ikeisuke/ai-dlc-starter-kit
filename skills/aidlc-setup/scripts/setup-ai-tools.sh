#!/bin/bash
# AIツール設定のセットアップ
# - Claude Code: permissions 設定

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AIDLC_TEMPLATES_DIR="${SCRIPT_DIR}/../templates"

# ============================================
# ============================================
# Claude Code 許可パターンのセットアップ
# ============================================

# JSON状態判定
# $1: ファイルパス
# stdout: absent / valid / invalid / unknown
_detect_json_state() {
  local file_path="$1"

  if [ ! -f "$file_path" ]; then
    echo "absent"
    return
  fi

  # jq で検証（優先）
  if command -v jq >/dev/null 2>&1; then
    if jq . "$file_path" >/dev/null 2>&1; then
      echo "valid"
    else
      echo "invalid"
    fi
    return
  fi

  # python3 で検証（フォールバック）
  if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$file_path" 2>/dev/null; then
      echo "valid"
    else
      echo "invalid"
    fi
    return
  fi

  # jq・python3 ともに不在
  echo "unknown"
}

# テンプレートJSON生成
# 外部ファイル（config/settings-template.json）から読み込み、不在時はインラインフォールバック
# 注: settings-template.json は現在リポジトリに含まれていないため、常にフォールバックが使用される
# 将来的にテンプレート外部化する場合は config/ ディレクトリに配置すること
# stdout: JSON文字列
_generate_template() {
  local template_file="${SCRIPT_DIR}/../config/settings-template.json"
  if [ -f "$template_file" ]; then
    local content
    content=$(cat "$template_file") || { echo "Warning: Failed to read $template_file" >&2; }
    if [ -n "$content" ]; then
      # JSON妥当性検証（jq or python3 利用可能時のみ）
      if command -v jq >/dev/null 2>&1; then
        if echo "$content" | jq empty 2>/dev/null; then
          echo "$content"
          return 0
        fi
        echo "Warning: $template_file is invalid JSON, using fallback" >&2
      elif command -v python3 >/dev/null 2>&1; then
        if echo "$content" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
          echo "$content"
          return 0
        fi
        echo "Warning: $template_file is invalid JSON, using fallback" >&2
      else
        # 検証ツールなし: そのまま使用
        echo "$content"
        return 0
      fi
    fi
  fi

  # フォールバック: 外部ファイルが不在・無効の場合のインラインテンプレート
  # NOTE: このフォールバックは settings-template.json と同期を保つ必要がある
  cat <<'TEMPLATE_EOF'
{
  "permissions": {
    "allow": [
      "Bash(cat:*)",
      "Bash(claude:*)",
      "Bash(command -v:*)",
      "Bash(date *)",
      "Bash(diff *)",
      "Bash(skills/*/scripts/*)",
      "Bash(skills/*/bin/*)",
      "Bash(echo:*)",
      "Bash(GIT_TERMINAL_PROMPT=0 git fetch:*)",
      "Bash(gh auth status)",
      "Bash(gh issue:*)",
      "Bash(gh pr:*)",
      "Bash(gh repo:*)",
      "Bash(git add:*)",
      "Bash(git branch:*)",
      "Bash(git checkout *)",
      "Bash(git commit -F:*)",
      "Bash(git commit -m:*)",
      "Bash(git commit:*)",
      "Bash(git diff *)",
      "Bash(git fetch *)",
      "Bash(git log *)",
      "Bash(git merge *)",
      "Bash(git merge-base *)",
      "Bash(git pull:*)",
      "Bash(git push *)",
      "Bash(git remote)",
      "Bash(git remote -v)",
      "Bash(git remote show:*)",
      "Bash(git rev-parse *)",
      "Bash(git revert:*)",
      "Bash(git show:*)",
      "Bash(git status *)",
      "Bash(git tag *)",
      "Bash(grep:*)",
      "Bash(head *)",
      "Bash(jq:*)",
      "Bash(ls *)",
      "Bash(markdownlint:*)",
      "Bash(mkdir *)",
      "Bash(mktemp /tmp/aidlc-:*)",
      "Bash(npx markdownlint-cli:*)",
      "Bash(tail *)",
      "Bash(tee -a .aidlc/cycles/*/history/*)",
      "Bash(touch *)",
      "Bash(wc *)",
      "Bash(which *)",
      "Skill(aidlc-feedback)",
      "Skill(aidlc-migrate)",
      "Skill(aidlc-setup)",
      "Skill(reviewing-inception-intent)",
      "Skill(reviewing-inception-stories)",
      "Skill(reviewing-inception-units)",
      "Skill(reviewing-construction-plan)",
      "Skill(reviewing-construction-design)",
      "Skill(reviewing-construction-code)",
      "Skill(reviewing-construction-integration)",
      "Skill(reviewing-operations-deploy)",
      "Skill(reviewing-operations-premerge)",
      "Skill(squash-unit)",
      "Skill(write-history)"
    ],
    "ask": [
      "Bash(git push*--force *)",
      "Bash(git push*--force-with-lease *)",
      "Bash(git branch*-D *)",
      "Bash(git branch*--force *)",
      "Bash(git tag*-d *)",
      "Bash(git checkout -- *)",
      "Bash(git checkout . *)",
      "Bash(gh pr merge *)"
    ]
  }
}
TEMPLATE_EOF
}

# 原子的書き込み
# $1: ターゲットパス
# stdin: 書き込み内容
# 戻り値: 0=成功, 1=失敗
_write_atomic() {
  local target_path="$1"
  local tmp_file

  mkdir -p "$(dirname "$target_path")"
  tmp_file=$(mktemp "$(dirname "$target_path")/.settings.json.tmp.XXXXXX") || return 1

  if cat > "$tmp_file" 2>/dev/null; then
    if \mv "$tmp_file" "$target_path" 2>/dev/null; then
      return 0
    fi
  fi

  # 失敗時: テンポラリファイルを削除
  \rm -f "$tmp_file" 2>/dev/null
  return 1
}

# パターンマージ（jq版）
# $1: 既存JSONファイルパス
# stdout: マージ済みJSON文字列
# 戻り値: 0=新規パターンあり, 1=全て既存, 2=エラー
_merge_permissions_jq() {
  local existing_file="$1"
  local template_defaults
  local template_obj
  template_obj=$(_generate_template) || return 2
  template_defaults=$(echo "$template_obj" | jq '.permissions.allow') || return 2
  local template_ask
  template_ask=$(echo "$template_obj" | jq '.permissions.ask // []') || return 2

  local merged
  merged=$(jq --argjson defaults "$template_defaults" --argjson ask_defaults "$template_ask" '
    .permissions //= {} |
    .permissions.allow //= [] |
    .permissions.ask //= [] |

    # --- allow マージ ---
    .permissions.allow as $existing |
    ($defaults - $existing) as $new_candidates |

    # ワイルドカード包含判定: 既存ルールから :*) で終わるものを抽出
    ($existing | map(select(type == "string" and endswith(":*)")))) as $wildcards |

    # 各候補について、既存ワイルドカードに包含されるかチェック
    [
      $new_candidates[] |
      . as $candidate |
      if ($candidate | type) != "string" then $candidate
      elif ($candidate | test("^[^(]+\\(")) then
        # Type部分とパス部分を抽出
        ($candidate | split("(") | .[0]) as $cand_type |
        ($candidate | split("(") | .[1:] | join("(") | rtrimstr(")")) as $cand_path |
        if [
          $wildcards[] |
          select(type == "string" and test("^[^(]+\\(")) |
          (split("(") | .[0]) as $wc_type |
          (split("(") | .[1:] | join("(") | rtrimstr(":*)")) as $wc_prefix |
          select($wc_type == $cand_type and ($cand_path | startswith($wc_prefix)))
        ] | length > 0 then empty
        else $candidate
        end
      else $candidate
      end
    ] as $new |

    (($new_candidates | length) - ($new | length)) as $skipped |

    # --- ask マージ（単純 set-difference、ワイルドカード判定不要）---
    .permissions.ask as $existing_ask |
    ($ask_defaults - $existing_ask) as $new_ask |

    # --- 結果を適用 ---
    (if ($new | length) > 0 then .permissions.allow += $new else . end) |
    (if ($new_ask | length) > 0 then .permissions.ask += $new_ask else . end) |
    . + {"_new_count": (($new | length) + ($new_ask | length)), "_skipped_count": $skipped}
  ' "$existing_file") || return 2

  local new_count
  new_count=$(echo "$merged" | jq -r '._new_count') || return 2
  # _skipped_count は caller が抽出するため、_new_count のみ削除
  merged=$(echo "$merged" | jq 'del(._new_count)') || return 2

  echo "$merged"
  if [ "$new_count" -gt 0 ]; then
    echo "$new_count" >&2
    return 0
  else
    return 1
  fi
}

# パターンマージ（python3版）
# $1: 既存JSONファイルパス
# stdout: マージ済みJSON文字列
# 戻り値: 0=新規パターンあり, 1=全て既存, 2=エラー
_merge_permissions_python() {
  local existing_file="$1"
  local template_json
  template_json=$(_generate_template) || return 2

  python3 -c "
import json, sys, re

def is_covered_by_wildcard(rule, wildcards):
    if not isinstance(rule, str):
        return False
    m = re.match(r'^([^(]+)\((.+)\)$', rule)
    if not m:
        return False
    cand_type, cand_path = m.group(1), m.group(2)
    for wc in wildcards:
        wm = re.match(r'^([^(]+)\((.*):\*\)$', wc)
        if not wm:
            continue
        wc_type, wc_prefix = wm.group(1), wm.group(2)
        if wc_type == cand_type and cand_path.startswith(wc_prefix):
            return True
    return False

try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    tpl = json.loads(sys.argv[2])
    defaults = tpl['permissions']['allow']
    ask_defaults = tpl.get('permissions', {}).get('ask', [])
    if not isinstance(defaults, list):
        sys.exit(2)

    if 'permissions' not in data:
        data['permissions'] = {}
    if 'allow' not in data['permissions']:
        data['permissions']['allow'] = []
    if 'ask' not in data['permissions']:
        data['permissions']['ask'] = []
    if not isinstance(data['permissions']['allow'], list):
        sys.exit(2)

    # --- allow merge ---
    existing = data['permissions']['allow']
    existing_set = {x for x in existing if isinstance(x, str)}
    new_candidates = [p for p in defaults if p not in existing_set]

    # Wildcard containment check
    wildcards = [r for r in existing if isinstance(r, str) and r.endswith(':*)')]
    new_patterns = [p for p in new_candidates if not is_covered_by_wildcard(p, wildcards)]
    skipped_count = len(new_candidates) - len(new_patterns)

    # --- ask merge (simple set-difference) ---
    existing_ask = data['permissions'].get('ask', [])
    existing_ask_set = {x for x in existing_ask if isinstance(x, str)}
    new_ask = [p for p in ask_defaults if p not in existing_ask_set]

    total_new = len(new_patterns) + len(new_ask)

    if new_patterns:
        data['permissions']['allow'].extend(new_patterns)
    if new_ask:
        data['permissions']['ask'].extend(new_ask)
    data['_skipped_count'] = skipped_count
    print(json.dumps(data, indent=2, ensure_ascii=False))
    if total_new > 0:
        print(total_new, file=sys.stderr)
        sys.exit(0)
    else:
        sys.exit(1)
except SystemExit:
    raise
except Exception:
    sys.exit(2)
" "$existing_file" "$template_json"
}

setup_claude_permissions() {
  local SETTINGS_FILE=".claude/settings.json"
  local result=""
  local new_count=""

  # JSON状態判定
  local state
  state=$(_detect_json_state "$SETTINGS_FILE")

  case "$state" in
    absent)
      # テンプレートJSON新規作成
      if _generate_template | _write_atomic "$SETTINGS_FILE"; then
        echo "Created: $SETTINGS_FILE (default permissions)"
        result="created"
      else
        echo "Warning: Failed to write $SETTINGS_FILE, skipping"
        result="failed"
      fi
      ;;

    invalid)
      # バックアップ＋テンプレートJSON新規作成
      if ! \cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak" 2>/dev/null; then
        echo "Warning: Failed to backup $SETTINGS_FILE, skipping"
        result="failed"
      else
        echo "Backup: $SETTINGS_FILE → ${SETTINGS_FILE}.bak (invalid JSON)"
        if _generate_template | _write_atomic "$SETTINGS_FILE"; then
          echo "Created: $SETTINGS_FILE (default permissions)"
          result="created"
        else
          echo "Warning: Failed to write $SETTINGS_FILE, skipping"
          result="failed"
        fi
      fi
      ;;

    unknown)
      echo "Warning: jq/python3 not found, cannot validate/update existing $SETTINGS_FILE"
      result="degraded"
      ;;

    valid)
      # マージツール利用可否チェック
      local merge_count_file
      if command -v jq >/dev/null 2>&1; then
        merge_count_file=$(mktemp /tmp/aidlc-merge-count.XXXXXX)
        local merged_json merge_rc
        merged_json=$(_merge_permissions_jq "$SETTINGS_FILE" 2>"$merge_count_file") && merge_rc=0 || merge_rc=$?

        case $merge_rc in
          0)
            new_count=$(cat "$merge_count_file" 2>/dev/null)
            \rm -f "$merge_count_file" 2>/dev/null
            # _skipped_count メタデータを抽出・削除
            local skipped_count
            skipped_count=$(echo "$merged_json" | jq -r '._skipped_count // 0') 2>/dev/null || skipped_count=0
            merged_json=$(echo "$merged_json" | jq 'del(._skipped_count)') 2>/dev/null || true
            if echo "$merged_json" | _write_atomic "$SETTINGS_FILE"; then
              if [ "$skipped_count" -gt 0 ] 2>/dev/null; then
                echo "Updated: $SETTINGS_FILE ($new_count new permissions added, $skipped_count skipped by wildcard)"
              else
                echo "Updated: $SETTINGS_FILE ($new_count new permissions added)"
              fi
              result="updated"
            else
              echo "Warning: Failed to write $SETTINGS_FILE, skipping"
              result="failed"
            fi
            ;;
          1)
            \rm -f "$merge_count_file" 2>/dev/null
            # スキップ情報の表示（全パターン既存の場合でもワイルドカード包含があり得る）
            local skipped_count
            skipped_count=$(echo "$merged_json" | jq -r '._skipped_count // 0') 2>/dev/null || skipped_count=0
            if [ "$skipped_count" -gt 0 ] 2>/dev/null; then
              echo "Skipped: $SETTINGS_FILE (all permissions already present, $skipped_count skipped by wildcard)"
            else
              echo "Skipped: $SETTINGS_FILE (all permissions already present)"
            fi
            result="skipped"
            ;;
          *)
            \rm -f "$merge_count_file" 2>/dev/null
            echo "Warning: Failed to merge permissions for $SETTINGS_FILE, skipping"
            result="failed"
            ;;
        esac

      elif command -v python3 >/dev/null 2>&1; then
        merge_count_file=$(mktemp /tmp/aidlc-merge-count.XXXXXX)
        local merged_json merge_rc
        merged_json=$(_merge_permissions_python "$SETTINGS_FILE" 2>"$merge_count_file") && merge_rc=0 || merge_rc=$?

        case $merge_rc in
          0)
            new_count=$(cat "$merge_count_file" 2>/dev/null)
            \rm -f "$merge_count_file" 2>/dev/null
            # _skipped_count メタデータを抽出・削除（python3で処理）
            local skipped_count
            skipped_count=$(echo "$merged_json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('_skipped_count',0))") 2>/dev/null || skipped_count=0
            merged_json=$(echo "$merged_json" | python3 -c "import json,sys; d=json.load(sys.stdin); d.pop('_skipped_count',None); print(json.dumps(d,indent=2,ensure_ascii=False))") 2>/dev/null || true
            if echo "$merged_json" | _write_atomic "$SETTINGS_FILE"; then
              if [ "$skipped_count" -gt 0 ] 2>/dev/null; then
                echo "Updated: $SETTINGS_FILE ($new_count new permissions added, $skipped_count skipped by wildcard)"
              else
                echo "Updated: $SETTINGS_FILE ($new_count new permissions added)"
              fi
              result="updated"
            else
              echo "Warning: Failed to write $SETTINGS_FILE, skipping"
              result="failed"
            fi
            ;;
          1)
            \rm -f "$merge_count_file" 2>/dev/null
            # スキップ情報の表示
            local skipped_count
            skipped_count=$(echo "$merged_json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('_skipped_count',0))") 2>/dev/null || skipped_count=0
            if [ "$skipped_count" -gt 0 ] 2>/dev/null; then
              echo "Skipped: $SETTINGS_FILE (all permissions already present, $skipped_count skipped by wildcard)"
            else
              echo "Skipped: $SETTINGS_FILE (all permissions already present)"
            fi
            result="skipped"
            ;;
          *)
            \rm -f "$merge_count_file" 2>/dev/null
            echo "Warning: Failed to merge permissions for $SETTINGS_FILE, skipping"
            result="failed"
            ;;
        esac

      else
        echo "Warning: jq/python3 not found, cannot update existing $SETTINGS_FILE"
        result="degraded"
      fi
      ;;
  esac

  echo "Done: Claude permissions setup complete"
  echo "result:${result}"

  # 失敗時は非ゼロを返し、set -e によりスクリプト全体を終了させる。
  # 呼び出し元 (_run_setup_ai_tools) が set +e で exit code を検出する。
  case "$result" in
    created|updated|skipped|degraded) return 0 ;;
    *) return 1 ;;  # failed および未知値
  esac
}

# ============================================
# メイン処理
# ============================================
echo "=== AI Tools Setup ==="
echo ""

echo "[1/1] Setting up Claude Code permissions..."
setup_claude_permissions
echo ""

echo "=== Setup Complete ==="
