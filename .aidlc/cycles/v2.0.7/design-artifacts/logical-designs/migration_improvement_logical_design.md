# 論理設計: マイグレーション改善

## 概要

migrate-config.sh を bootstrap.sh 非依存の自己完結スクリプトに書き換え、不足セクション追加・エラー表示改善を実装する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャ方針

### スキル自己完結の原則

Anthropic公式スキルのパターンに準拠し、各スキルは自己完結する:

- スクリプトは **他スキルの内部実装に依存しない**
- スクリプトは **自スキル内に配置されているリソースのみ使用**
- プロジェクトルートは **優先順位解決**（引数推定 → pwd → git rev-parse → エラー）
- スキル内リソースは **SCRIPT_DIR からの相対パス** で解決

### bootstrap.sh 依存の脱却

`migrate-config.sh` が bootstrap.sh から使っている機能:

| bootstrap.sh の提供物 | 実際の使用箇所 | 代替手段 |
|---------------------|-------------|---------|
| `AIDLC_CONFIG` | デフォルトの config パス | `pwd/.aidlc/config.toml` |
| `AIDLC_PROJECT_ROOT` | rules.md のパス算出 | `pwd` |
| `AIDLC_PLUGIN_ROOT` | guides/ パス（jj移行案内） | `SCRIPT_DIR/../..`（自スキルルート） |
| `AIDLC_LOCAL_CONFIG` | オーバーライドファイル警告 | `pwd/.aidlc/config.local.toml` |
| `AIDLC_LOCAL_CONFIG_LEGACY` | レガシーオーバーライド警告 | `pwd/.aidlc/config.toml.local` |
| toml-reader.sh の関数 | 未使用（grep/sed/awk で直接操作） | 不要 |

→ **bootstrap.sh の source を削除し、上記の代替で自己解決可能**

## コンポーネント構成

```text
skills/aidlc-setup/scripts/
└── migrate-config.sh    (自己完結・bootstrap.sh非依存に改修)
```

migrate-config.sh は **aidlc-setup に留める**（移動しない）。

## スクリプトインターフェース設計

### migrate-config.sh（改善後）

#### 概要
config.tomlのセクション/キーを新スキーマにマイグレーションする自己完結スクリプト。

#### パス解決（bootstrap.sh に代わる自己解決）

**プロジェクトルート解決の優先順位**:
1. `--config` 引数が指定されている場合、そのディレクトリの親から推定
2. `pwd` に `.aidlc/` ディレクトリが存在する場合、`pwd` を採用
3. `git rev-parse --show-toplevel` でgitルートを取得
4. いずれも該当しない場合、`error:project-root-not-found` で exit 1

```text
SCRIPT_DIR = cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
SKILL_ROOT = cd "${SCRIPT_DIR}/.." && pwd        # skills/aidlc-setup/
PROJECT_ROOT = 上記優先順位で解決
CONFIG = --config引数 or ${PROJECT_ROOT}/.aidlc/config.toml
RULES = --rules引数 or ${PROJECT_ROOT}/.aidlc/rules.md
LOCAL_CONFIG = ${PROJECT_ROOT}/.aidlc/config.local.toml
LOCAL_CONFIG_LEGACY = ${PROJECT_ROOT}/.aidlc/config.toml.local
```

#### 引数
| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--config <path>` | 任意 | config.tomlパス（デフォルト: `.aidlc/config.toml`） |
| `--rules <path>` | 任意 | rules.mdパス（廃止設定の移行先参照用。config.toml の変更のみ行い、rules.md 自体は更新しない） |
| `--dry-run` | 任意 | 変更なしでシミュレーション |

#### 出力（stdout）: 構造化メッセージ
```text
mode:{execute|dry-run}
config:{path}
migrate:rename:rules.mcp_review->rules.reviewing
migrate:add-section:rules.automation
skip:already-exists:rules.reviewing
warn:deprecated-config:rules.jj
...
result:completed:migrated=3,skipped=5,warnings=1
```

#### 終了コード
- `0`: 正常終了（警告含む）
- `1`: エラー（ファイル不在等）

#### 追加マイグレーションルール（新規）

既存ルールに加え、v2で追加された以下のセクションを不足時に補完:

| セクション | デフォルト内容 | 追加バージョン |
|-----------|-------------|-------------|
| `[rules.automation]` | `mode = "manual"` | v2.0.0 |
| `[rules.construction]` | `max_retry = 3` | v2.0.0 |
| `[rules.preflight]` | `enabled = true`, `checks = [...]` | v2.0.0 |
| `[rules.squash]` | `enabled = false` | v2.0.0 |
| `[rules.unit_branch]` | `enabled = false` | v2.0.0 |
| `[rules.upgrade_check]` | `enabled = false` | v2.0.0 |

#### エラー表示改善（#453対応）

1. **awk処理の成功/失敗判定**: `rules.reviewing.tools` 追加時、awk の結果を検証し失敗時は `warn:` を出力（成功メッセージ抑制）
2. **`_has_warnings` 変数**: `result:completed-with-warnings` の制御に使用。終了コードは変更しない
3. **コメント修正**: 終了コード仕様を実装と一致させる

#### サマリ表示改善

`result:` 行に全カウントを含める（ドメインモデルのデータ契約に準拠）:
- `result:completed:migrated={N},skipped={N},warnings={N}`
- `result:completed-with-warnings:migrated={N},skipped={N},warnings={N}`

`status` は `warnings > 0` で `completed-with-warnings`、それ以外は `completed`。
カウントは各 `migrate:` / `skip:` / `warn:` メッセージ出力時にインクリメント。

### migrate-apply-config.sh への影響と依存契約

`migrate-config.sh` は **aidlc-setup の内部実装**（非公開）として位置づける。他スキルからの直接呼び出しは禁止。

migrate-apply-config.sh が `${SCRIPT_DIR}/migrate-config.sh` で参照している問題:
- 現状: aidlc-migrate/scripts/ に実体がなく silently skip
- 方針: silent skip は設計上禁止。バックログで以下のいずれかに対応:
  - aidlc-migrate に migrate-config.sh のコピーを配置
  - または migrate-apply-config.sh 内にマイグレーションロジックを統合
- Unit 006 ではこの依存契約の明文化とバックログ登録まで行う

## 非機能要件（NFR）への対応

### セキュリティ
- **要件**: 設定ファイルのデータロス防止
- **対応策**: dry-runモード、一時ファイル+mv の安全パターン（既存実装を維持）、未知キーの保持

## 技術選定
- **言語**: Bash
- **依存コマンド**: grep, sed, awk, mktemp（既存依存を維持）

## 実装上の注意事項
- bootstrap.sh の source を削除し、パス解決を自己完結に置き換える
- toml-reader.sh の関数は migrate-config.sh 内で未使用のため、source 削除のみで対応
- `AIDLC_PLUGIN_ROOT` を参照している箇所（guides/jj-migration.md のパス表示）は `SKILL_ROOT` に置き換え
- 既存の dry-run テストが書き換え後も動作することを確認
