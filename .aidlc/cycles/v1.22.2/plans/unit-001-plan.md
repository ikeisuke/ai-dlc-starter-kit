# Unit 001 計画: aidlc-setupスクリプト修正

## 概要

aidlc-setup.sh のスクリプト不在エラーを修正し、lib/ディレクトリを含む全リソースがユーザープロジェクトに正しくデプロイされるようにする。

## 問題分析

### 根本原因

aidlc-setup.sh の `resolve_starter_kit_root()` が外部プロジェクト環境で正しくスターターキットのルートを解決できない場合がある:

1. **ghq未インストール**: ghqフォールバックが使えない外部プロジェクト環境
2. **AIDLC_STARTER_KIT_PATH未設定**: 環境変数が設定されていない
3. **エラーメッセージの不足**: スクリプト不在時にどのパスを探したかが不明確

### 連鎖的影響

- `resolve_starter_kit_root()` が失敗 → STARTER_KIT_ROOT が不正
- → `check-setup-type.sh` が見つからない（warn）
- → `sync-package.sh` が見つからない（error）
- → lib/ を含む全ディレクトリの同期が失敗（#339）

### 依存マップ

#### 直接依存（STARTER_KIT_ROOT相対のスクリプト）

| スクリプト | パス（STARTER_KIT_ROOT相対） | 必須/任意 | 失敗時の挙動 |
|-----------|---------------------------|----------|------------|
| check-setup-type.sh | `prompts/setup/bin/check-setup-type.sh` | 任意 | warn出力、SETUP_TYPE空で続行 |
| migrate-config.sh | `prompts/package/bin/migrate-config.sh` | 任意 | warn出力、マイグレーションスキップ |
| sync-package.sh | `prompts/package/bin/sync-package.sh` | **必須** | error出力、exit 1 |
| version.txt | `version.txt` | 任意 | KIT_VERSION="unknown"で続行 |

#### 推移依存（sync-package.shの同期対象ディレクトリ）

sync-package.sh が正常動作した場合に同期される7ディレクトリ:

| ソース（STARTER_KIT_ROOT相対） | デプロイ先 |
|-------------------------------|----------|
| `prompts/package/prompts/` | `docs/aidlc/prompts/` |
| `prompts/package/templates/` | `docs/aidlc/templates/` |
| `prompts/package/guides/` | `docs/aidlc/guides/` |
| `prompts/package/bin/` | `docs/aidlc/bin/` |
| `prompts/package/skills/` | `docs/aidlc/skills/` |
| `prompts/package/kiro/` | `docs/aidlc/kiro/` |
| `prompts/package/lib/` | `docs/aidlc/lib/` |

sync-package.sh 不在の場合、上記7ディレクトリすべてが同期されない（#339のlib/不在はこの結果）。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` | パス解決ロジック改善、エラーメッセージ強化（本スクリプトが全依存のパス解決責務を集約） |

**責務の明確化**: パス解決は `aidlc-setup.sh` 側に集約する。各子スクリプト（check-setup-type.sh, sync-package.sh等）は自身のパス解決に関与しない。

## 実装計画

### 1. パス解決ロジックの改善とエラーメッセージ強化

- `resolve_starter_kit_root()` のエラーメッセージに実際に検索したパスと推奨アクション（AIDLC_STARTER_KIT_PATH設定の案内）を追加
- ghq不在時のエラーメッセージ改善
- 各依存スクリプト不在時のエラーメッセージに実際のパスを含める

**出力契約ルール**:

| キー | 出力先 | 用途 | 繰り返し |
|-----|--------|------|---------|
| `error:*` | stderr | 致命的エラー | 不可（1エラーにつき1行） |
| `warn:*` | stdout | 警告（続行可能） | 可 |
| `detail:*` | stderr | エラーの補足情報（探索パス等） | 可 |
| その他既存キー | stdout | 状態出力（mode:, setup_type:, version_from:等） | 既存仕様に従う |

- 既存の `key:value` 出力形式は変更しない（後方互換性維持）
- `detail:` は新規追加キー。既存コンシューマ（aidlc-setupスキルのAIエージェント）は未知キーを無視する前提
- `detail:` 行は `error:` の補足としてのみ使用し、同一ストリーム（stderr）に出力（順序保証が成立）
- `warn:` の補足情報が必要な場合は `warn:` 行自体のvalue部に含める（ストリーム分離による順序不整合を回避）

### 2. 検証（テストマトリクス）

| シナリオ | 環境 | AIDLC_STARTER_KIT_PATH | ghq | 期待結果 |
|---------|------|----------------------|-----|---------|
| A | メタ開発（worktree） | 未設定 | - | 正常完了（パターン2検出） |
| B | メタ開発（本体） | 未設定 | - | 正常完了（パターン2検出） |
| C | 外部PJ | 設定済み（正しいパス） | - | 正常完了 |
| D | 外部PJ | 未設定 | あり | 正常完了（ghq解決） |
| E | 外部PJ | 未設定 | なし | エラー（パスと対処法表示） |
| F | 外部PJ | 設定済み（不正パス） | - | エラー（パスと対処法表示） |

検証時にはsync-package.shの同期対象（上記7ディレクトリ）が全てソースに存在し、同期コマンドに渡されることも確認する。

## 完了条件チェックリスト

- [x] aidlc-setup.sh から check-setup-type.sh の絶対パスを正しく解決できること
- [x] aidlc-setup.sh から sync-package.sh の絶対パスを正しく解決できること
- [x] lib/ を含む7ディレクトリの同期が実行されることの検証
- [x] エラー時の具体的なメッセージ出力（パスと対処法を含む、既存key:value形式を維持、detail:行で補足）
- [x] メタ開発環境での動作確認（テストマトリクスA, B）
- [x] 外部プロジェクト環境の検証シナリオ（テストマトリクスC〜F）を実施
