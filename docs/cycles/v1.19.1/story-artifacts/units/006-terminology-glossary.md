# Unit: Terminology/Glossary作成

## 概要

AI-DLC固有用語の用語集を作成し、ドキュメントやプロンプトで使われる用語の統一的な定義を提供する。

## 含まれるユーザーストーリー

- ストーリー 7: Terminology/Glossary作成（#283）

## 責務

- AI-DLC固有用語の定義一覧作成（最低10用語）
- 必須用語セット（最低限含む）: Cycle, Phase, Intent, Unit, Story, PRFAQ, Construction, Operations, Inception, Backlog
- 各用語に簡潔な説明と関連フェーズ/成果物への参照

## 境界

- 既存ドキュメントの用語置換は含まない
- 多言語対応は含まない

## 依存関係

### 依存する Unit

- なし

### 外部依存

- なし

## 非機能要件（NFR）

- **パフォーマンス**: N/A（ドキュメント作成のみ）
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項

- 新規ファイル作成: `prompts/package/guides/glossary.md`
- 既存の `intro.md` の内容と重複しないよう注意
- Amazon AIDLCの terminology.md を参考

## 実装優先度

Low

## 見積もり

小（新規ドキュメント作成のみ）

## 関連Issue

- #283

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-08
- **完了日**: 2026-03-09
- **担当**: @ai
