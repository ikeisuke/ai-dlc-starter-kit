# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.13.0

## 開発の目的
AI-DLCのプロセス品質とIssue管理を改善し、上流工程での品質担保と開発サイクル全体の可視化・追跡性を向上させる。

## ターゲットユーザー
AI-DLCを使用して開発を行うチーム・個人開発者

## ビジネス価値
- **上流品質向上**: Inception PhaseでのAIレビュー導入により、下流での手戻りを削減
- **プロセス改善**: Issue管理の明文化により、何をいつやるかが明確になり、閉じ忘れを防止
- **メンテコスト削減**: 不要な機能（Dependabot確認）を削除し、コードベースをシンプルに保つ
- **リリース品質向上**: バージョン更新漏れを防止するプロセス改善

## 成功基準
- Inception PhaseでAIレビューが実行可能になっている
- Intent明確化での質問がより詳細になっている
- PRマージ時に関連Issueが自動クローズされる運用フローが確立している
- label-cycle-issues.shのラベル付け漏れが解消している
- version.txt更新ステップがOperations Phaseに明記されている
- Dependabot PR確認機能が削除されている

## 期限とマイルストーン
特になし（通常のサイクル進行）

## 制約事項
- メタ開発のため、`prompts/package/`を編集し、rsyncで`docs/aidlc/`に反映
- 後方互換性を維持（既存プロジェクトへの影響を最小限に）

## 対応Issue

| # | タイトル | 方向性 |
|---|----------|--------|
| 158 | Operations Phaseにversion.txt更新ステップを明示化 | プロセス改善 |
| 154 | Inception PhaseにAIレビュー導入 | 品質向上 |
| 148 | label-cycle-issues.shのバグ修正 | バグ修正 |
| 96 | Dependabot PR確認機能の削除 | 機能削除 |
| 28 | Issue駆動統合設計 | プロセス改善 |

## 不明点と質問（Inception Phase中に記録）

[Question] #28 Issue駆動統合設計の具体的なスコープは？
[Answer] テンプレートは既存、Issue管理には移行済み。問題は「何をいつやるか不明瞭」「閉じ忘れ」。方向性:
1. Issueライフサイクル管理の明文化
2. PRマージ時の自動クローズ（Closes #XXを含めるプロセス）
3. ラベル・マイルストーン活用

[Question] #96 Dependabot PR確認機能はどうするか？
[Answer] 機能を削除してメンテコスト削減

[Question] #154 Inception PhaseへのAIレビューはどの箇所に？
[Answer] Intent、ユーザーストーリー、Unit定義の3箇所すべて。加えて:
- Intent明確化での質問を深掘り
- 受け入れ条件の厳格化（曖昧な条件を許容しない）

[Question] #148 label-cycle-issues.shの問題は？
[Answer] ラベル付け漏れ（対象Issueが漏れる）があった。バグ調査・修正で対応。
