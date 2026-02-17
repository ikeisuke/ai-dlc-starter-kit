# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.15.1 - スキル管理の標準化とツール互換性改善

## 開発の目的
AI-DLCスターターキットのスキル管理をKiroの標準形式に対応させ、AIDLC固有のレビュースキルを追加し、既存ツールの互換性問題を修正する。これにより、複数のAIツール間での一貫したスキル呼び出しと、Inception Phase成果物の品質向上を実現する。

## ターゲットユーザー
AI-DLCスターターキットを使用する開発者（Claude Code、Kiro等の複数AIツール利用者）

## ビジネス価値
- Kiroの標準スキル呼び出し方式に対応することで、Kiroユーザーの利便性が向上する
- AIDLC専用レビュースキルにより、インテントやユーザーストーリーの品質チェックが自動化される
- upgrading-aidlcスキルの簡略化で、アップグレード体験が改善される
- macOS sed互換性修正で、gitモード利用時のバックログ移行が正常に動作する

## 成功基準
- Kiroの `.kiro/skills/` 標準呼び出し方式で既存スキルが動作すること
- AIDLC専用レビュースキル（インテント・ユーザーストーリー用）が作成され、レビューフローに統合されていること
- upgrading-aidlcスキルでsetup-prompt.mdのローカル探索ステップが省略されていること
- migrate-backlog.shがmacOSのBSD sedでエラーなく動作すること

## 期限とマイルストーン
パッチリリース（v1.15.1）として、単一サイクルで完了

## 制約事項
- `docs/aidlc/` は直接編集禁止（`prompts/package/` を編集し、Operations Phaseでrsync反映）
- Claude CodeとKiroの両方で動作するスキル形式を維持すること
- 既存スキルの後方互換性を保つこと

## 不明点と質問（Inception Phase中に記録）

[Question] サイクルのテーマ・方向性
[Answer] 「スキル管理の標準化とツール互換性改善」で合意

[Question] #192と#191の依存関係
[Answer] 依存関係なし。それぞれ独立して対応可能

[Question] スコープの除外事項
[Answer] #164（セミオートモード）、#31（GitHub Projects連携）は対象外。その他の除外事項なし
