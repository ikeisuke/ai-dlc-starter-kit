# Unit 002 計画: Depth Levels設定・共通ルール

## 概要

成果物詳細度の3段階制御（minimal/standard/comprehensive）の設定体系と共通ルールを定義する。各フェーズプロンプトへの判定ロジック組み込みはUnit 003の責務であり、本Unitでは設定インフラと仕様定義（Unit 003が実装する契約仕様を含む）に集中する。

## Unit 002/003 契約仕様

Unit 002が定義し、Unit 003が実装する契約:

- **設定キー**: `rules.depth_level.level`（完全修飾キーで参照）
- **有効値**: `"minimal"` | `"standard"` | `"comprehensive"`
- **デフォルト値**: `"standard"`
- **無効値時の動作**: 警告メッセージを出力し `"standard"` にフォールバック
- **警告文言**: `【警告】rules.depth_level.level に無効な値 "{入力値}" が設定されています。"standard" にフォールバックします。有効値: minimal / standard / comprehensive`
- **読み込みコマンド**: `docs/aidlc/bin/read-config.sh rules.depth_level.level --default "standard"`

Unit 003は上記契約に基づき、各フェーズプロンプト内で判定ロジックを実装する。

## 変更対象ファイル

1. **`docs/aidlc.toml`** - `[rules.depth_level]` セクション追加
2. **`prompts/package/prompts/common/rules.md`** - Depth Level共通仕様セクション追加
3. **`prompts/package/bin/migrate-config.sh`** - `[rules.depth_level]` セクションの自動追加処理

## 責務分離

- **`rules.md`**: Depth Levelの仕様定義（各レベルの定義、成果物要件一覧、バリデーション仕様、警告文言）。AIエージェントが参照する規約文書
- **`migrate-config.sh`**: `[rules.depth_level]` セクションの欠落補完のみ。バリデーションは行わない
- **`read-config.sh`**: 設定値の読み込みAPI。各フェーズプロンプトは必ずこのAPIを経由して設定を取得する（`aidlc.toml` の直接解析は禁止）
- **各フェーズプロンプト（Unit 003）**: `read-config.sh` で取得した値に対する実行時バリデーションと分岐

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計

- Depth Levelの3段階（minimal/standard/comprehensive）の定義
- 各レベルで制御される成果物要件の構造化
- バリデーション仕様と警告文言の定義

#### ステップ2: 論理設計

- `aidlc.toml` のセクション構造設計
- `rules.md` に追加する仕様セクションの構成設計（契約仕様を含む）
- `migrate-config.sh` の `_add_section` パターンに基づく追加処理設計

### Phase 2: 実装

#### ステップ4: コード生成

1. `docs/aidlc.toml` に `[rules.depth_level]` セクション追加
   - `level = "standard"` をデフォルト値として設定
   - 設定コメントで有効値と説明を記載

2. `prompts/package/prompts/common/rules.md` にDepth Level仕様追加
   - 設定読み込み方法（`read-config.sh rules.depth_level.level --default "standard"`、完全修飾キーを使用）
   - 各レベルの定義（minimal/standard/comprehensive）
   - レベル別成果物要件一覧（フェーズ×成果物のマトリクス）
   - 無効値の警告文言・フォールバック動作（契約仕様セクションの警告文言を使用）

3. `prompts/package/bin/migrate-config.sh` に `_add_section` 追加
   - 既存パターン（`_add_section "rules\\.history"` 等）に準じた実装
   - デフォルト値: `standard`
   - 責務: セクション欠落時の補完のみ

#### ステップ5: テスト生成

- `migrate-config.sh --dry-run` での動作確認
- 既存設定ファイルに `[rules.depth_level]` が存在しない場合のマイグレーション確認
- 既存設定ファイルに `[rules.depth_level]` が存在する場合のスキップ確認
- `read-config.sh rules.depth_level.level --default "standard"` での完全修飾キー読み込み確認

#### ステップ6: 統合とレビュー

- `read-config.sh` での読み込み確認（完全修飾キー）
- markdownlint実行

## 完了条件チェックリスト

- [x] `docs/aidlc.toml` に `[rules.depth_level]` セクションを追加（デフォルト: standard）
- [x] `prompts/package/prompts/common/rules.md` にDepth Levelの共通仕様を記載（各レベルの定義、レベル別成果物要件一覧）
- [x] 無効な `level` 値設定時の警告・フォールバック動作をルールに明記
- [x] `prompts/package/bin/migrate-config.sh` に `[rules.depth_level]` セクションの自動追加処理を追加（既存ユーザーのマイグレーション対応）
