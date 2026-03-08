# Unit: jjサポート非推奨化 - プロンプト

## 概要
プロンプトファイル・スキルファイルのjjサポートを非推奨（deprecated）としてマークし、将来バージョンでの削除を予告する。コードは残存させ機能は維持する。

## 含まれるユーザーストーリー
- ストーリー 5: jjサポート関連処理の非推奨化（プロンプト部分）

## 責務
- `prompts/package/skills/versioning-with-jj/SKILL.md` に非推奨バナーを追加
- `prompts/package/skills/versioning-with-jj/references/jj-support.md` の実験的機能注記を非推奨注記に更新
- `prompts/package/prompts/common/rules.md` のjjサポート設定セクションに非推奨警告を追加
- `prompts/package/prompts/common/commit-flow.md` のVCS判定箇所に非推奨注記を追加
- `prompts/package/prompts/common/ai-tools.md` のjjスキル行に「(非推奨)」を付加
- `prompts/package/prompts/inception.md`、`construction.md`、`operations.md` のjj参照箇所に非推奨注記を追加

## 境界
- スクリプト（bin/*.sh）への非推奨警告追加はUnit 007の責務
- `docs/aidlc/` 配下は `prompts/package/` のrsyncコピーなので直接編集しない
- jjコードの削除は行わない（機能維持）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- 非推奨メッセージは統一フォーマット: 「v1.19.0で非推奨。将来のバージョンで削除予定」
- jj関連コードは全て残存させ、既存の機能を壊さない
- 非推奨バナーはユーザーが最初に目にする位置に配置

## 実装優先度
High

## 見積もり
小規模（各ファイルに非推奨注記を追加するのみ）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-07
- **完了日**: 2026-03-07
- **担当**: AI
