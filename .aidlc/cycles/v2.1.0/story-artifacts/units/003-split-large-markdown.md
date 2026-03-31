# Unit: 400行超えMarkdownファイルの分割

## 概要
`skills/aidlc/` 配下の400行超えMarkdownファイル9つを分割し、各ファイルを400行以内に収める。

## 含まれるユーザーストーリー
- ストーリー 4: 400行超えMarkdownファイルの分割

## 責務
- 対象9ファイルの分割
  - steps/inception/01-setup.md (692行)
  - steps/operations/operations-release.md (628行)
  - guides/sandbox-environment.md (583行)
  - guides/ai-agent-allowlist.md (573行)
  - steps/common/rules.md (546行)
  - steps/construction/01-setup.md (478行)
  - steps/common/review-flow.md (439行)
  - steps/common/commit-flow.md (438行)
  - steps/construction/04-completion.md (416行)
- 分割後のファイル間参照の整合性維持
- SKILL.md の読み込み順序指示の更新

## 境界
- 過去cycleのアーカイブ、生成物、履歴ファイルは対象外
- ファイル内容の論理的変更は行わない（構造的分割のみ）

## 依存関係

### 依存する Unit
- Unit 002: レビュースキルリファクタリング（review-flow.md が Unit 002 で変更されるため、分割は変更後に実施）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- セクション単位で自然な分割点を選定
- 分割後のファイル名は親ファイルからの連番または機能名を付与
- 既存の「【次のアクション】今すぐ読み込んで」パターンで分割ファイルを参照

## 関連Issue
- なし

## 実装優先度
Medium

## 見積もり
中規模（9ファイルの分割、参照更新）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-31
- **完了日**: 2026-04-01
- **担当**: @claude
- **エクスプレス適格性**: -
- **適格性理由**: -
