# 論理設計: Depth Level設定・共通ルール

## 概要

Depth Level設定の具体的なファイル構造、追加するセクションの内容、マイグレーションスクリプトの変更点を定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存のAI-DLC設定パターン（TOMLセクション + プロンプト内仕様記述 + マイグレーションスクリプト）を踏襲。新規パターンの導入はない。

## コンポーネント構成

### 変更対象ファイル構成

```text
設定ファイル
├── docs/aidlc.toml                            # [rules.depth_level] セクション追加
└── prompts/package/
    ├── prompts/common/rules.md                # Depth Level仕様セクション追加
    └── bin/migrate-config.sh                  # _add_section 追加
```

### コンポーネント詳細

#### `docs/aidlc.toml` - 設定セクション

- **責務**: Depth Levelの設定値を保持
- **依存**: なし
- **追加内容**: `[rules.depth_level]` セクション

#### `prompts/package/prompts/common/rules.md` - 仕様定義（DepthLevelResolver仕様のSoT）

- **責務**: Depth Levelの仕様を**唯一の定義源（Single Source of Truth）**として保持する規約文書。バリデーション・フォールバック仕様を単一箇所で定義する。**仕様定義のみを担い、実装は行わない**
- **依存**: `read-config.sh`（設定読み込みAPI = ドメインモデルの「設定取得ポート」の実装）
- **追加内容**: Depth Level仕様セクション（設定読み込み方法、レベル定義、成果物要件一覧、バリデーション仕様）
- **消費者**: 各フェーズプロンプト（Unit 003）がこの仕様を参照して判定ロジックを実装する

#### `prompts/package/bin/migrate-config.sh` - マイグレーション（DepthLevelMigrator実装）

- **責務**: `[rules.depth_level]` セクション欠落時の補完（ドメインモデルの「マイグレーションポート」の実装）
- **依存**: `_add_section` ヘルパー関数（既存）
- **追加内容**: `_add_section "rules\\.depth_level"` 呼び出し

## ファイル形式

### `docs/aidlc.toml` 追加セクション

- **形式**: TOML
- **追加位置**: `[rules.linting]` セクションの後（`migrate-config.sh` の `_add_section` 順序と一致させる）
- **主要フィールド**:
  - `level`: DepthLevel列挙型 - `"minimal"` | `"standard"` | `"comprehensive"`（デフォルト: `"standard"`、小文字のみ有効、前後空白はトリム、空文字は無効値）

### `rules.md` 追加セクション構成

- **追加位置**: 「jjサポート設定」セクションの前（設定系セクション群の一部として）
- **構成**:
  1. Depth Level仕様【重要】（セクション見出し）
  2. 設定読み込み（`read-config.sh rules.depth_level.level --default "standard"`）
  3. レベル定義テーブル（minimal/standard/comprehensive の定義）
  4. レベル別成果物要件一覧（フェーズ×成果物マトリクス）
  5. バリデーション仕様（正規化ルール、有効値判定、警告文言、フォールバック動作を一括定義）
  6. Unit 003向け契約仕様（フェーズプロンプトでの判定ロジック実装規約 - rules.mdの仕様を参照する旨を明記）

## 処理フロー概要

### マイグレーションフロー

**ステップ**:

1. `migrate-config.sh` 実行時に `_add_section "rules\\.depth_level"` が呼ばれる
2. `grep -q "^\[rules\.depth_level\]"` で既存チェック（`_add_section` ヘルパー内部）
3. 不在の場合: デフォルトセクションを追記
4. 存在する場合: スキップ

**関与するコンポーネント**: `migrate-config.sh`

### 設定読み込み・バリデーションフロー（rules.mdに一元定義、Unit 003が各フェーズで実装）

**ステップ**:

1. フェーズプロンプト開始時に `read-config.sh rules.depth_level.level --default "standard"` を実行
2. 戻り値を取得
3. 正規化: 前後の空白をトリム
4. 有効値チェック: `minimal` / `standard` / `comprehensive` のいずれか（小文字完全一致）
5. 無効値の場合（空文字、大文字混在、typo等）: 警告文言を出力し `"standard"` を使用
6. 有効値に基づいて成果物要件を分岐

**責務分離**: `rules.md` は仕様のSoT（定義のみ）。各フェーズプロンプト（Unit 003）は `rules.md` の仕様を参照して判定ロジックを実装する。仕様の重複記述は禁止。

**関与するコンポーネント**: `read-config.sh`（設定取得）, `rules.md`（仕様SoT）, 各フェーズプロンプト（判定実装）

## スクリプトインターフェース設計

### migrate-config.sh（既存スクリプトへの追加）

#### 追加内容

`_add_section` 呼び出しの追加。既存の `_add_section "rules\\.linting"` の後に配置。

#### 追加するセクション内容

```text
[rules.depth_level]
# 成果物詳細度設定（v1.19.0で追加）
# level: "minimal" | "standard" | "comprehensive"
# - minimal: シンプルなタスク向け（設計省略可、受け入れ基準簡略化）
# - standard: 通常の機能開発向け（デフォルト）
# - comprehensive: 複雑な機能開発向け（リスク分析・代替案検討等を追加）
level = "standard"
```

#### 成功時出力

```text
migrate:add-section:rules.depth_level
```

または

```text
skip:already-exists:rules.depth_level
```

## 非機能要件（NFR）への対応

- **パフォーマンス**: N/A（設定・プロンプト変更のみ）
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術選定

- **言語**: Bash（migrate-config.sh）、Markdown（rules.md）
- **フレームワーク**: N/A
- **ツール**: read-config.sh（既存の設定読み込みAPI）

## 実装上の注意事項

- `docs/aidlc/` は `prompts/package/` のrsyncコピーのため、`prompts/package/` のみ編集する
- `docs/aidlc.toml` はプロジェクト設定ファイルであり直接編集対象
- `[rules.history].level` との混同を避けるため、設定キーは常に完全修飾キー（`rules.depth_level.level`）で参照する
- `_add_section` の配置順序: 既存の `_add_section "rules\\.linting"` の後に追加（`aidlc.toml` の手編集時も同じ順序）

## 不明点と質問（設計中に記録）

（なし - ドメインモデルと計画ファイルから要件が明確）
