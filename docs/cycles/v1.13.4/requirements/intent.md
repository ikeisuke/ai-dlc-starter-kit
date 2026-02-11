# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.13.4 - AIレビュースキルの改善・安定化

## 開発の目的
AIレビュースキル（特にCodex関連）の利便性と安定性を向上させる。Codex skillsのセットアップ改善（シンボリックリンク配置先の調整、compatibilityフィールドの追加）と、claude-reviewスキルの不安定動作の調査・修正を行う。

## ターゲットユーザー
AI-DLCスターターキットを使用してAIレビュー（Codex/Claude）を活用している開発者

## ビジネス価値
- Codex skillsのセットアップが正しく動作し、ユーザーがスムーズにAIレビューを開始できる
- claude-reviewスキルの安定動作により、AIレビューの信頼性が向上する
- compatibilityフィールドの記載により、サンドボックス要件が明確化される

## 成功基準
- Codex skillsのシンボリックリンクが `~/.codex/skills` に正しく配置される
- Codex skillsのSKILL.mdにcompatibilityフィールドが追加され、サンドボックス要件が明記される
- claude-reviewスキルの不安定動作（レスポンス未返却、指摘の二転三転）の原因が特定され、修正される

## 期限とマイルストーン
パッチリリース（短期）

## 制約事項
- メタ開発: `prompts/package/` を編集し、`docs/aidlc/` は直接編集しない
- Codex CLIのスキル単位でのサンドボックス解除は未対応のため、compatibilityフィールドはドキュメント用途のみ
- claude-reviewの不安定動作は調査結果次第で対応範囲が変わる可能性がある

## 不明点と質問（Inception Phase中に記録）

[Question] 今回のIntentの全体テーマ・狙いは？
[Answer] AIレビュースキルの改善・安定化。特にCodex対応が中心。

[Question] #179 claude-reviewの不安定動作の具体的な症状は？
[Answer] レスポンスが返ってこない（タイムアウト的な問題）と、細かい指摘が反復レビューで二転三転する（一貫性の問題）の2つ。

[Question] 3つのIssueすべてをこのサイクルで完了させる想定か？
[Answer] はい、すべて完了させる。
