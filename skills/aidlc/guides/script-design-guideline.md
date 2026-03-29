# スキルスクリプト設計ガイドライン

スキル配下のシェルスクリプト（`scripts/*.sh`）の設計方針を定義する。

## 基本原則

### 1. 自己完結性

各スクリプトは、他スキルの内部実装に依存しない自己完結した実行単位とする。

**推奨パターン**:
```bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# プロジェクトルートの解決（自己完結）
AIDLC_PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error:project-root-not-found" >&2; exit 2
}

# 必要なパスのみ定義（使用するものだけ）
AIDLC_CONFIG="${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
```

**禁止パターン**:
```bash
# 他スキルの内部ライブラリに依存
source "${SCRIPT_DIR}/lib/bootstrap.sh"  # lib/ が存在しない場合に壊れる
```

### 2. 最小依存

スクリプトが使用する変数・関数は、実際に使うものだけを定義する。共通ライブラリからの全量インポートは避ける。

| 使用変数 | 定義方法 |
|---------|---------|
| `AIDLC_PROJECT_ROOT` | `git rev-parse --show-toplevel` |
| `AIDLC_CONFIG` | `${AIDLC_PROJECT_ROOT}/.aidlc/config.toml` |
| `AIDLC_CYCLES` | `${AIDLC_PROJECT_ROOT}/.aidlc/cycles` |
| `AIDLC_PLUGIN_ROOT` | `${AIDLC_PROJECT_ROOT}/skills/aidlc` |

### 3. 同一スキル内のlib/は許可

同じスキル内の `scripts/lib/` からのインポートは許可する。ただし、他スキルの `scripts/lib/` からのインポートは禁止。

```bash
# OK: 同一スキル内
source "${SCRIPT_DIR}/lib/toml-reader.sh"

# NG: 他スキルの内部実装
source "${AIDLC_PROJECT_ROOT}/skills/aidlc/scripts/lib/bootstrap.sh"
```

## bootstrap.sh依存の問題点

v2.0.0-v2.0.7のスキル分離時に発生した問題:

1. **lib/不在**: スキル分離後、`aidlc-setup/scripts/lib/bootstrap.sh` が存在しないにもかかわらず、各スクリプトが `source "${SCRIPT_DIR}/lib/bootstrap.sh"` を実行
2. **過剰な依存**: bootstrap.sh は6つの環境変数 + toml-reader.sh + ユーティリティ関数を一括提供するが、多くのスクリプトは1-2変数しか使用していなかった
3. **暗黙のパス解決**: `AIDLC_PLUGIN_ROOT` が `BASH_SOURCE[0]` から算出されるため、スクリプトの配置場所に依存

### 脱却パターン

| 修正前 | 修正後 |
|--------|--------|
| `source "${SCRIPT_DIR}/lib/bootstrap.sh"` | 使用変数のインライン定義 |
| `AIDLC_PROJECT_ROOT` (bootstrap経由) | `git rev-parse --show-toplevel` |
| `AIDLC_PLUGIN_ROOT` (bootstrap経由) | `${AIDLC_PROJECT_ROOT}/skills/aidlc` |
| `AIDLC_CONFIG` (bootstrap経由) | `${AIDLC_PROJECT_ROOT}/.aidlc/config.toml` |

## 新規スクリプト作成チェックリスト

新しいスクリプトを作成する際に確認する項目:

- [ ] `set -euo pipefail` が先頭にあるか
- [ ] `SCRIPT_DIR` が定義されているか
- [ ] 他スキルの `scripts/lib/` に依存していないか
- [ ] 使用する環境変数が全てスクリプト内で定義されているか（または同一スキルのlib/からインポート）
- [ ] 終了コードが `exit-code-convention.md` に準拠しているか
- [ ] 出力形式が `key:value` の構造化形式か
- [ ] `--help` オプションが実装されているか
- [ ] エラーメッセージが標準エラー出力に出力されているか

## 参考

- `guides/exit-code-convention.md` — 終了コード規約
- `guides/error-handling.md` — エラーハンドリング
