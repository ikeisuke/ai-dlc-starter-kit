# Unit 3: Dependabot PR確認 - 実装計画

## 概要

Inception Phase開始時にDependabot PRの有無を確認し、セキュリティ更新の見落としを防止する機能を実装する。

## 目的

- GitHub CLIでDependabot PRの一覧を取得
- PRがある場合、一覧を表示
- 今回のサイクルで対応するかどうかをユーザーに確認

## 実装範囲

### 変更対象ファイル

1. `prompts/package/prompts/inception.md`
   - ステップ3（バックログ確認）の前後にDependabot PR確認手順を追加

### 変更内容

1. **新規ステップの追加**: 「ステップ2.5: Dependabot PR確認」として以下を追加
   - GitHub CLIでDependabot PRの一覧取得
   - PRがある場合は表示して対応確認
   - GitHub CLIが未設定の場合はスキップ

### 境界（スコープ外）

- PRのマージやクローズは行わない（確認のみ）
- Dependabot以外のPRは対象外
- GitHub CLIが利用できない環境ではスキップ

## 技術的考慮事項

- コマンド: `gh pr list --label "dependencies" --state open`
- GitHub CLIが未設定の場合のエラーハンドリング
- PRがない場合のメッセージ表示

## 設計フェーズ（Phase 1）

### ステップ1: ドメインモデル設計

このUnitはプロンプト修正のみでコード実装がないため、ドメインモデル設計は「軽量版」として実施：
- プロンプトの構造と責務を定義
- 追加する手順のフローを明確化

### ステップ2: 論理設計

- inception.mdへの変更箇所の特定
- 追加するMarkdown構造の設計
- エラーハンドリングのフロー設計

### ステップ3: 設計レビュー

- 設計内容をユーザーに提示し承認を得る

## 実装フェーズ（Phase 2）

### ステップ4: コード生成

- `prompts/package/prompts/inception.md`に手順を追加

### ステップ5: テスト生成

- 手動テスト手順の作成
  - Dependabot PRがある場合の動作確認
  - PRがない場合の動作確認
  - GitHub CLI未設定の場合の動作確認

### ステップ6: 統合とレビュー

- 変更内容の確認
- 実装記録の作成
- コミット

## 完了基準

- [ ] inception.mdにDependabot PR確認手順が追加されている
- [ ] GitHub CLI未設定時のエラーハンドリングが実装されている
- [ ] 実装記録が作成されている
- [ ] Unit定義ファイルの実装状態が「完了」に更新されている

---

作成日: 2025-12-12
