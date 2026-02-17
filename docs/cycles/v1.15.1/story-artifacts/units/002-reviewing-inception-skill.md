# Unit: AIDLC専用レビュースキル作成

## 概要
Inception Phase成果物（Intent、ユーザーストーリー、Unit定義）を専用の観点でレビューする `reviewing-inception` スキルを作成し、レビューフローに統合する。

## 含まれるユーザーストーリー
- ストーリー 2: AIDLC専用レビュースキル作成 (#191)

## 関連Issue
- #191

## 責務
- `reviewing-inception` スキル定義ファイルの作成（SKILL.md）
- Intent、ユーザーストーリー、Unit定義のレビュー観点定義
- `review-flow.md` のCallerContextマッピングテーブル更新
- 有効なレビュー種別テーブルへの追加

## 境界
- 既存レビュースキル（code, architecture, security）は変更しない
- Construction Phase / Operations Phase のレビューフローは変更しない
- スキルの実行ツール（codex, claude, gemini）自体の変更は含まない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- 既存レビュースキルの形式（YAML frontmatter + Markdown）

## 非機能要件（NFR）
- **パフォーマンス**: AIレビュー実行時間は既存スキルと同等
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 新たなレビュー観点の追加が容易な構造
- **可用性**: codex, claude, geminiの3ツールで動作

## 技術的考慮事項
- 既存スキル形式に厳密に準拠（YAML frontmatter: name, description, argument-hint, compatibility, allowed-tools）
- `session-management.md` は既存スキルのものを参照で共有
- `prompts/package/skills/` に作成（メタ開発ルール）
- `prompts/package/prompts/common/review-flow.md` のCallerContextマッピングを更新

## 実装優先度
Medium

## 見積もり
中規模（スキル定義作成、レビュー観点の設計、review-flow統合）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
