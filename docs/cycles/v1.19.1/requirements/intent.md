# Intent（開発意図）

## プロジェクト名

AI-DLC v1.19.1 - フロー品質改善とプロンプト明確化

## 開発の目的

AI-DLCのレビュースキル動作修正、プロンプトルールの明文化、運用フローの改善、およびドキュメント整備（エラーハンドリング基本定義・用語集）を通じて、AI-DLCの使い勝手と信頼性を向上させる。

## ターゲットユーザー

AI-DLCスターターキットを利用する開発者およびAIエージェント

## ビジネス価値

- **レビュー品質の向上**: 外部ツール（codex等）が利用可能な場合に適切に優先され、セルフレビューへの不要なフォールバックが解消される（#285）
- **プロンプトの安全性強化**: `$()`・バッククォート禁止ルールの明文化により、AIエージェントの意図しないコマンド展開を防止（#286）
- **セッション判別の改善**: session-titleの表示順改善により、複数セッション間の識別性が向上（#287）
- **運用フローの自動化**: post-merge-cleanup.shの組み込みにより、PRマージ後の手動作業忘れを防止（#288）
- **改善提案の追跡可能性**: バックログissue作成ルールにより、口頭提案の消失を防止（#289）
- **エラー対応の体系化**: エラーの重大度分類と基本復旧手順の定義により、トラブル時の対応を標準化（#282）
- **用語の統一**: AI-DLC固有用語の用語集作成により、理解の齟齬を防止（#283）

## 成功基準

- **#285**: レビュースキルが外部ツール（CLIコマンドとして実行可能な状態）利用可能時に外部ツールを優先し、self-reviewモードは外部ツール実行失敗時のフォールバックとしてのみ使用される
- **#286**: `prompts/package/prompts/common/rules.md` にBashコードブロック内の`$()`・バッククォート禁止ルールが明文化されている
- **#287**: session-titleの表示順が「プロジェクト / バージョン / フェーズ / ユニット」に変更されている
- **#288**: `prompts/package/prompts/operations.md` のPRマージ後の手順に `post-merge-cleanup.sh` の実行ステップが追加されている
- **#289**: 改善提案時にバックログissueを必ず作成するルールが `prompts/package/prompts/common/rules.md` に追加されている
- **#282**: エラーの重大度レベル定義と主要フェーズの基本復旧手順が文書化されている
- **#283**: AI-DLC固有用語の用語集が `prompts/package/guides/glossary.md` に作成されている（`docs/aidlc/guides/glossary.md` はOperations Phaseのrsyncで生成）

## 期限とマイルストーン

パッチリリースのため、1サイクル（1-2セッション）での完了を想定。中間マイルストーンはUnit単位の完了で管理

## 制約事項

- メタ開発: `docs/aidlc/` は直接編集禁止。変更は `prompts/package/` に対して行う
- #282のError Handling体系化は基本レベル（エラー分類と代表的な復旧手順）にとどめ、包括的なフレームワークは別サイクルで対応
- 既存の動作互換性を維持する
  - 影響対象: レビュー実行フロー（review-flow.md）、Operations Phase手順（operations.md）、共通ルール（rules.md）、session-titleスキル
  - 互換性確認: 既存のセミオート・手動の両モードで動作確認

## 不明点と質問（Inception Phase中に記録）

[Question] #282 Error Handling体系化のスコープ
[Answer] 基本的なエラー分類と代表的な復旧手順のみ。包括的なフレームワークは別サイクルで対応

[Question] #283 Terminology/Glossaryの作成形式
[Answer] 新規ファイルとして `prompts/package/guides/glossary.md` に作成（`docs/aidlc/guides/glossary.md` はOperations Phaseのrsyncで生成）

[Question] 全体的な目的の解釈確認
[Answer] 「フロー品質改善とプロンプト明確化」のパッチリリースで正しい
