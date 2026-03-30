# Unit: コンテンツバリデーション

## 概要
reviewing-codeスキルのSKILL.mdにASCII図・Mermaid図のバリデーション観点を追加する。

## 含まれるユーザーストーリー
- ストーリー3: コンテンツバリデーション（#279）

## 責務
- reviewing-codeスキルのSKILL.mdにASCII図のバリデーション観点を追加する（罫線接続、ラベル対応、交差線ゼロ原則と例外時の理由記録）
- reviewing-codeスキルのSKILL.mdにMermaid図のバリデーション観点を追加する（対象6種別: flowchart, sequenceDiagram, classDiagram, stateDiagram, erDiagram, gantt）
- Mermaid図の構文準拠・ノードID/ラベル重複チェック観点を記載する
- 未対応Mermaid図種別（pie, mindmap等）の構文検証対象外である旨の記載を追加する

## 境界
- 専用のバリデーションツール作成は行わない
- 図の自動生成・自動修正は行わない
- ツール実行ロジックの変更は不要

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし（プロンプト変更のみ）
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- 変更対象: `prompts/package/skills/reviewing-code/SKILL.md`
- レビュー観点の追加のみで、ツール実行ロジックの変更は不要

## 実装優先度
Medium

## 見積もり
S（SKILL.mdの観点セクション追加のみ）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-10
- **完了日**: 2026-03-10
- **担当**: @claude
