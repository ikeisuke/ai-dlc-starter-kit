# Unit: Depth Levels設定・共通ルール

## 概要
成果物詳細度の3段階制御（minimal/standard/comprehensive）の設定体系と共通ルールを定義する。

## 含まれるユーザーストーリー
- ストーリー 2: 成果物詳細度の適応的制御（設定・共通ルール部分）

## 責務
- `docs/aidlc.toml` に `[rules.depth_level]` セクションを追加（デフォルト: standard）
- `prompts/package/prompts/common/rules.md` にDepth Levelの共通仕様を記載（各レベルの定義、レベル別成果物要件一覧）
- 無効な `level` 値設定時の警告・フォールバック動作をルールに明記
- `prompts/package/bin/migrate-config.sh` に `[rules.depth_level]` セクションの自動追加処理を追加（既存ユーザーのマイグレーション対応）

## 境界
- 各フェーズプロンプト（inception.md, construction.md, operations.md）への判定ロジック組み込みはUnit 003の責務
- テンプレートファイル自体は変更しない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- Amazon AIDLC の depth-levels.md（MIT-0ライセンス、参照元として活用）

## 非機能要件（NFR）
- **パフォーマンス**: N/A（設定・プロンプト変更のみ）
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- `[rules.history].level` との混同を避ける命名（`depth_level`）
- `docs/aidlc.toml` はプロジェクト設定ファイルであり直接編集対象
- `migrate-config.sh` に `_add_section "rules\\.depth_level"` を追加する必要がある。Unit 007でもmigrate-config.shのjjセクション処理を削除するため、推奨実装順: Unit 007（jj削除）→ Unit 002（depth_level追加）
- `common/rules.md` はUnit 001（Overconfidence Prevention）・Unit 006（jj削除）でも変更される。推奨実装順: Unit 006（削除）→ Unit 001（再構成）→ Unit 002（追加）で競合リスクを最小化

## 実装優先度
High

## 見積もり
中規模（設定ファイル追加 + rules.mdへの仕様記載）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-06
- **完了日**: 2026-03-06
- **担当**: Claude
