# Unit 001: エクスプレスモード再設計 - 計画

## 概要
エクスプレスモードを「フェーズ連続実行（フロー制御）」に純化し、depth_level との結合を解除する。

## 変更対象ファイル

### 主要変更（prompts/package/ 配下）
1. `prompts/package/prompts/common/rules.md` — エクスプレスモード仕様セクションの再定義
2. `prompts/package/prompts/inception.md` — ステップ4b・ステップ14b・エクスプレスモード完了処理の改修
3. `prompts/package/prompts/construction.md` — エクスプレスモード検出セクションの改修
4. `prompts/package/prompts/CLAUDE.md` — フェーズ簡略指示の `start express` 説明更新
5. `prompts/package/prompts/AGENTS.md` — フェーズ簡略指示の `start express` 説明更新

### 必要に応じて変更
6. `prompts/package/templates/unit_definition_template.md` — 適格性判定結果フィールドの追加（検討）

## 実装計画

### Phase 1: 設計
1. **ドメインモデル設計**: エクスプレスモードの概念モデル再定義（3軸の独立性: エクスプレスモード=フロー制御、depth_level=成果物詳細度、automation_mode=承認制御）
2. **論理設計**: 各プロンプトファイルの変更箇所の詳細設計

### Phase 2: 実装
1. `rules.md` エクスプレスモード仕様セクションの改修
   - 適用条件から `depth_level=minimal` 要件を削除
   - 複雑度判定ロジック（4項目判定ルール表）を追加
   - Unit数のハードコーディング制限を削除
   - `start express` コマンドの意味変更
2. `inception.md` の改修
   - ステップ14b: `start express` が depth_level をオーバーライドしない
   - ステップ4b: depth_level 条件を削除し、エクスプレスモード有効化フラグで判定
   - エクスプレスモード完了処理: depth_level に応じた成果物要件の分岐を維持
3. `construction.md` の改修
   - エクスプレスモード検出セクション: depth_level=minimal 条件を削除
4. `CLAUDE.md` / `AGENTS.md` の `start express` 説明更新
5. 後方互換性テスト（プロンプトレベルの検証シナリオ）

## 完了条件チェックリスト
- [x] `rules.md` エクスプレスモード仕様の再定義（depth_level=minimal 前提の削除）
- [x] 複雑度判定ロジック（4項目判定ルール表）の定義
- [x] Unit定義ファイルの実装状態セクションへ適格性判定結果・理由を記録するルール定義
- [x] `inception.md` ステップ4b の判定条件変更
- [x] `start express` コマンドの意味変更（minimal オーバーライド → フェーズ連続実行有効化）
- [x] `construction.md` のエクスプレスモード遷移先の整合性確認
- [x] 後方互換性: 既存の minimal + Unit数1 フローが従来通り動作する設計であること
