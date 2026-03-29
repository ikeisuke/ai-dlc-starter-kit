# ドメインモデル: マイグレーション改善

## 概要

config.tomlの設定マイグレーション処理における責務単位とデータ契約を定義する。

## 責務単位

### ルール集合（MigrationRules）
- マイグレーションルールの定義と適用判定
- ルール種別: セクション追加、セクションリネーム、キーリネーム、廃止検出
- 各ルールは「対象パターン」「変換内容」「デフォルト値」を持つ

### ターゲットファイル（config.toml のみ）
- マイグレーション対象は config.toml に限定
- rules.md への更新は行わない（必要時は `warn:` で手動対応を促す）

### 結果ログ（MigrationResults）
- 各ルール適用の結果を構造化メッセージで出力
- プレフィックス: `migrate:` / `skip:` / `warn:` / `error:`

### サマリ（MigrationSummary）
- 結果の集約: migrated数、skipped数、warnings数
- `result:{status}:migrated={N},skipped={N},warnings={N}` 形式で出力

## データ契約

### 構造化メッセージ（stdout）

| プレフィックス | 意味 | 例 |
|-------------|------|-----|
| `mode:` | 実行モード | `mode:execute`, `mode:dry-run` |
| `config:` | 対象ファイルパス | `config:.aidlc/config.toml` |
| `migrate:` | 成功した変換 | `migrate:add-section:rules.automation` |
| `skip:` | スキップした変換 | `skip:already-exists:rules.reviewing` |
| `warn:` | 警告 | `warn:deprecated-config:rules.jj` |
| `error:` | エラー（stderr） | `error:config-not-found` |
| `result:` | 最終サマリ | `result:completed:migrated=3,skipped=5,warnings=1` |

### result行のstatusフィールド

| status | 条件 |
|--------|------|
| `completed` | warnings = 0 |
| `completed-with-warnings` | warnings > 0 |

### 終了コード

| コード | 意味 |
|-------|------|
| `0` | 正常終了（warnings含む） |
| `1` | エラー（ファイル不在等） |

### stdout / stderr の使い分け

- **stdout**: 構造化メッセージ（機械可読）
- **stderr**: 人間向け診断メッセージ（jj廃止案内等）

## スクリプト配置と公開性

| スクリプト | 配置先 | 公開性 |
|-----------|--------|--------|
| migrate-config.sh | skills/aidlc-setup/scripts/ | 内部実装（aidlc-setup スキル内でのみ使用） |

他スキルからの直接呼び出しは禁止。aidlc-migrate が同等機能を必要とする場合は自前のコピーを持つ（バックログ対応）。
