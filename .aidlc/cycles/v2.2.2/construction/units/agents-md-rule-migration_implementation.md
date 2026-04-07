# 実装記録: AGENTS.md活用・ルール移行

## 実装日時
2026-04-07

## 作成ファイル

### ソースコード
- skills/aidlc/AGENTS.md - 3セクション追加（質問と実行の判断基準、承認プロセス、AskUserQuestion使用ルール）
- skills/aidlc/steps/common/rules-core.md - 移行済み3セクション削除（188行→106行）

### テスト
該当なし（Markdownドキュメント変更のみ）

### 設計ドキュメント
- .aidlc/cycles/v2.2.2/design-artifacts/domain-models/agents-md-rule-migration_domain_model.md
- .aidlc/cycles/v2.2.2/design-artifacts/logical-designs/agents-md-rule-migration_logical_design.md

## コードレビュー結果
- [x] コードAIレビュー（Codex）: 指摘1件（中・TECHNICAL_BLOCKER: 移行前から存在する参照表記、本Unit境界外）
- [x] 統合AIレビュー（Codex）: 指摘0件
- [x] 移行内容の完全性: Codexにより確認済み

## 状態
**完了**

## 備考
関連Issue: #533, #541
