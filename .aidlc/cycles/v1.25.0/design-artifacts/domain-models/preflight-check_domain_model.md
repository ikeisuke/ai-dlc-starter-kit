# ドメインモデル: プリフライトチェック・設定値一括提示

## 概要

各フェーズ開始時に環境・ツール・設定の整合性を一括チェックし、結果をコンテキスト変数として提供するプリフライトチェック機構のドメインモデル。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## エンティティ（Entity）

### PreflightCheck（プリフライトチェック実行）

- **ID**: フェーズ名（inception / construction / operations）
- **属性**:
  - phase: string - 実行対象フェーズ
  - check_items: CheckItem[] - チェック項目のリスト
  - config_values: ConfigValue[] - 取得した設定値のリスト
  - overall_result: PreflightResult - 全体の判定結果
- **振る舞い**:
  - execute(): 全チェック項目を実行し、結果を集約する
  - retry(item): 特定のチェック項目を再チェックする（最大3回）
  - present_results(): チェック結果と設定値を統一フォーマットで提示する

## 値オブジェクト（Value Object）

### CheckItem（チェック項目）

- **属性**:
  - name: string - チェック項目名（例: "git存在確認"）
  - severity: Severity - 重大度（blocker / warn / info）
  - retryable: boolean - 再チェック可能か
  - check_command: string - 実行するコマンド/スクリプト
  - result: CheckResult - チェック結果
  - condition: string | null - 実行条件（null = 常時実行）
- **不変性**: チェック項目定義は実行時に変更されない
- **等価性**: name で判定

### CheckResult（チェック結果）

- **属性**:
  - status: "pass" | "fail" - 合否
  - value: string - 取得した値（例: "available", "not-installed"）
  - message: string - ユーザー向けメッセージ
- **不変性**: 一度決定した結果は変更されない（再チェック時は新インスタンス生成）
- **等価性**: status + value で判定

### Severity（重大度）

- **属性**: level: "blocker" | "warn" | "info"
- **不変性**: 定義時に固定
- **等価性**: level で判定

### PreflightResult（全体判定結果）

- **属性**:
  - can_proceed: boolean - フェーズ続行可能か
  - blocker_failures: CheckItem[] - blockerレベルの失敗項目
  - warnings: CheckItem[] - warnレベルの失敗項目
  - info_messages: CheckItem[] - infoレベルの情報項目
- **不変性**: チェック完了後に確定
- **等価性**: can_proceed + failures で判定

### ConfigValue（設定値）

- **属性**:
  - key: string - 設定キー名（例: "rules.depth_level.level"）
  - context_var: string - 正規化されたコンテキスト変数名（例: "depth_level"）
  - value: string - 取得した値
  - is_default: boolean - デフォルト値が使用されたか
- **不変性**: 取得後に変更されない
- **等価性**: key で判定

## 集約（Aggregate）

### PreflightCheckAggregate

- **集約ルート**: PreflightCheck
- **含まれる要素**: CheckItem[], CheckResult[], ConfigValue[], PreflightResult
- **境界**: 1回のプリフライト実行に関する全情報
- **不変条件**:
  - blocker項目が1つでもfailならcan_proceed=false
  - warn項目のfailはcan_proceed=trueだが警告を必ず提示
  - info項目のfailはcan_proceed=trueで情報表示のみ

## ドメインサービス

### PreflightExecutionService

- **責務**: チェック項目の実行順序制御と結果集約
- **操作**:
  - run_all_checks(): 全チェック項目を定義順に実行
  - run_config_batch(): `read-config.sh --keys` で設定値を一括取得
  - evaluate_result(): CheckResult[]からPreflightResultを生成
  - retry_check(item, attempt): 失敗項目の再チェック（最大3回）

### ConfigNormalizationService

- **責務**: 既存スクリプトの出力キー名をコンテキスト変数名に正規化
- **操作**:
  - normalize(raw_output): スクリプト出力をConfigValue[]に変換

## チェック項目定義テーブル

| # | name | severity | retryable | check_command | condition | context_var |
|---|------|----------|-----------|---------------|-----------|-------------|
| 1 | git存在確認 | blocker | Yes | `which git` | 常時 | - |
| 2 | aidlc.toml存在確認 | blocker | Yes | `ls docs/aidlc.toml` | 常時 | - |
| 3 | gh状態確認 | warn | Yes | `env-info.sh` 出力の `gh:` 行を解析（唯一の情報源） | 常時 | `gh_status` |
| 5 | [project].name存在確認 | warn | Yes | `read-config.sh project.name` | aidlc.toml存在時 | - |
| 5 | レビューツール存在確認 | info | No | `which <tool>` (tools配列の先頭) | `review_mode != disabled` かつ `tools` 非空 | - |
| 6 | 設定値個別取得 | info | No | `read-config.sh <key> --default <value>` を各キーに実行 | aidlc.toml存在時 | 各設定値（下記キー対応表参照） |

## 設定値一括取得キーリスト

```text
rules.depth_level.level
rules.automation.mode
rules.reviewing.mode
rules.reviewing.tools
rules.squash.enabled
rules.linting.markdown_lint
rules.unit_branch.enabled
rules.history.level
rules.backlog.mode
```

## ユビキタス言語

- **プリフライトチェック**: フェーズ開始前の環境・設定一括検証
- **blocker**: フェーズ続行を不可能にする致命的な問題
- **warn**: フェーズは続行可能だが、一部機能が制限される問題
- **info**: 情報提供のみ。フェーズ続行に影響しない
- **コンテキスト変数**: プリフライト結果を保持し、以降のステップで参照される変数
- **正規化**: 既存スクリプトの異なる出力キー名を統一されたコンテキスト変数名に変換すること

## 不明点と質問（設計中に記録）

（なし）
