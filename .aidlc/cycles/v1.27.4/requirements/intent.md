# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.27.4

## 開発の目的
AI-DLCワークフローの信頼性・安全性を向上させる。具体的には、v1.27.3で発見された3つの問題（aidlc-setup.shの警告検出ロジック不整合、バックログ登録時のスコープ判定不足、semi_autoゲートのレビュー未実施チェック欠如）を修正し、ワークフロー全体の品質ガードを強化する。

## ターゲットユーザー
AI-DLCスターターキットを使用する開発者（AI-DLC利用者全般）

## ビジネス価値
- aidlc-setupの警告検出が終了コード規約変更後も正しく動作するようになる
- スコープ内の作業がバックログに誤登録されることを防止し、サイクル内での対応漏れを防ぐ
- semi_autoモードでAIレビュー未実施のまま自動承認されるリスクを排除する

## 成功基準
- aidlc-setup.shがmigrate-config.shのstdout出力に警告メッセージが含まれる場合に警告扱いとし、終了コードに依存しない判定が動作する
- rules.mdのバックログ登録ルールを修正し、登録前にintent.mdのスコープと照合してスコープ内項目の登録を拒否する動作が実現される
- semi_autoゲートのフォールバック条件テーブルにreview_not_executedが追加され、AIレビュー未実施時は自動承認せず確認プロンプトへ遷移する

## 期限とマイルストーン
パッチリリース（v1.27.4）

## 制約事項
- メタ開発構造: プロンプト修正は `prompts/package/` を編集し、`docs/aidlc/` には直接編集しない
- 終了コード規約（`guides/exit-code-convention.md`）に準拠する

## 影響分析

| 機能 | 変更有無 | 詳細 |
|------|---------|------|
| `aidlc-setup.sh` | 変更あり | migrate-config.shの警告検出をexit code判定からstdout解析に変更 |
| `automation_mode=manual` | 変更なし | manualフローには影響しない（フォールバック条件追加はsemi_auto専用） |
| `automation_mode=semi_auto` | 変更あり | フォールバック条件テーブルにreview_not_executedを追加。AIレビュー未実施時は自動承認をブロック |
| バックログ登録フロー | 変更あり | 登録前にintent.mdのスコープと照合するチェックを追加。スコープ外項目の登録動作は変更なし |
| migrate-config.sh | 変更なし | v1.27.3で既に終了コード規約準拠済み。本サイクルでは修正しない |

## スコープ

### 含まれるもの
- #402: aidlc-setup.shのmigrate-config警告検出をstdout解析に移行
- #401: バックログ登録時のスコープガード追加（rules.mdの改善提案ルール・気づき記録フロー修正）
- #400: semi_autoゲートのフォールバック条件テーブルにreview_not_executed追加

### 除外するもの
- 上記以外のバックログIssue
- 新機能の追加（full_autoモード、並列Unit実装等）

## 不明点と質問（Inception Phase中に記録）

[Question] サイクルの主目的のテーマ表現は？
[Answer] AI-DLCワークフローの信頼性・安全性向上

[Question] 各Issueの対応範囲の確認
[Answer] #402はaidlc-setup.shのstdout解析移行、#401はrules.mdのスコープチェック追加、#400はrules.mdのフォールバック条件追加。追加・除外なし

[Question] 既存機能への影響（#402の他スクリプトへの影響、#400の動作変更の意図）
[Answer] OK（影響は確認済み、動作変更は意図通り）
