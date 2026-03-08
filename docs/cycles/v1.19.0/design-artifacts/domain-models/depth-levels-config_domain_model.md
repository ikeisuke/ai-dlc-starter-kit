# ドメインモデル: Depth Level設定・共通ルール

## 概要

成果物詳細度（Depth Level）の3段階制御（minimal/standard/comprehensive）の設定体系と共通ルールを定義するドメインモデル。設定の構造、バリデーション仕様、各レベルの成果物要件を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

**用語注記**: 本文書で「Depth Level」は概念名（単数形）。設定キー `rules.depth_level.level` は概念名をそのまま使用。`rules.history.level` とはセクション名（`depth_level` vs `history`）で区別され、参照時は常に完全修飾キーを使用する。

## 値オブジェクト（Value Object）

### DepthLevel

成果物詳細度のレベルを表す列挙型。

- **有効値**: `"minimal"` | `"standard"` | `"comprehensive"`
- **デフォルト値**: `"standard"`
- **不変性**: 設定ファイルから読み込まれた後は変更されない
- **等価性**: 文字列の完全一致で判定（大小文字を区別する）
- **正規化**: 前後の空白はトリムする。空文字は無効値として扱う。大小文字変換は行わない（小文字のみ有効）

### DepthLevelConfig

`[rules.depth_level]` セクションの設定構造。

- **属性**:
  - `level`: DepthLevel - 成果物詳細度のレベル
- **設定キー**: `rules.depth_level.level`（完全修飾キー）

## ドメインサービス

### DepthLevelResolver（インターフェース）

設定からDepth Levelを解決するサービスのインターフェース。

- **責務**: 設定値を取得し、バリデーションとフォールバックを行う
- **操作**:
  - `resolve()` → DepthLevel - 有効なDepthLevelを返す
    1. 設定取得ポート経由で `rules.depth_level.level` の値を取得（デフォルト: `"standard"`）
    2. 正規化: 前後の空白をトリム
    3. 有効値チェック: `minimal` / `standard` / `comprehensive` のいずれか
    4. 無効値の場合: 警告を出力し `"standard"` にフォールバック
- **警告文言**: `【警告】rules.depth_level.level に無効な値 "{入力値}" が設定されています。"standard" にフォールバックします。有効値: minimal / standard / comprehensive`

**注意**: 実装詳細（`read-config.sh` 等）は論理設計で定義する。ドメインモデルでは設定取得ポートとして抽象化する。

### DepthLevelMigrator（インターフェース）

設定マイグレーション時にセクション欠落を補完するサービスのインターフェース。

- **責務**: `[rules.depth_level]` セクションが存在しない場合に追加する（欠落補完のみ。バリデーションは行わない）
- **操作**:
  - `migrate()` - セクション欠落時にデフォルト値で補完
    - 不在時: デフォルト値（`level = "standard"`）でセクションを追加
    - 存在時: スキップ

**注意**: 実装詳細（`_add_section` / `grep` 等）は論理設計で定義する。

## レベル別成果物要件

### minimal（簡略モード）

シンプルなバグ修正や小規模変更に適用。

| フェーズ | 成果物 | 要件 |
|---------|--------|------|
| Inception | Intent | 1-2文の簡潔な記述 |
| Inception | ユーザーストーリー | 受け入れ基準を主要ケースのみに簡略化 |
| Inception | Unit定義 | 最小限の責務・境界記述 |
| Construction | ドメインモデル | スキップ可能（設計省略を明記） |
| Construction | 論理設計 | スキップ可能（設計省略を明記） |
| Construction | コード・テスト | 通常通り |
| Operations | リリース準備 | 通常通り |

### standard（標準モード）

通常の機能開発に適用。現行の動作と同等。

| フェーズ | 成果物 | 要件 |
|---------|--------|------|
| Inception | Intent | 標準的な記述（背景・目的・スコープ） |
| Inception | ユーザーストーリー | 完全な受け入れ基準（INVEST準拠） |
| Inception | Unit定義 | 完全な責務・境界・依存関係記述 |
| Construction | ドメインモデル | 標準的なドメインモデル設計 |
| Construction | 論理設計 | 標準的な論理設計 |
| Construction | コード・テスト | 通常通り |
| Operations | リリース準備 | 通常通り |

### comprehensive（詳細モード）

複雑な機能開発やアーキテクチャ変更に適用。

| フェーズ | 成果物 | 要件 |
|---------|--------|------|
| Inception | Intent | 詳細な記述 + リスク分析・代替案検討セクション追加 |
| Inception | ユーザーストーリー | 完全な受け入れ基準 + エッジケース網羅 |
| Inception | Unit定義 | 完全な記述 + 技術的リスク評価 |
| Construction | ドメインモデル | 詳細なドメインモデル + ドメインイベント定義 |
| Construction | 論理設計 | 詳細な論理設計 + シーケンス図・状態遷移図 |
| Construction | コード・テスト | 通常通り + 統合テスト強化 |
| Operations | リリース準備 | 通常通り + ロールバック手順の詳細化 |

## ユビキタス言語

- **Depth Level**: 成果物詳細度のレベル（単数形で概念を表す）。タスクの複雑度に応じて制御する。設定キー `rules.depth_level.level` の `depth_level` 部分がこの概念に対応する。`rules.history.level`（履歴記録レベル）とは別の概念
- **minimal**: 簡略モード。バグ修正等のシンプルなタスク向け
- **standard**: 標準モード。通常の機能開発向け。デフォルト
- **comprehensive**: 詳細モード。複雑な機能開発やアーキテクチャ変更向け
- **完全修飾キー**: 設定値を参照する際のドット区切りのフルパス（例: `rules.depth_level.level`）

## 不明点と質問（設計中に記録）

（なし - ユーザーストーリーと受け入れ基準から要件が明確）
