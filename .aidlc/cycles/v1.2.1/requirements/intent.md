# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.2.1 - 技術的負債解消

## 開発の目的
v1.2.0で導入した新アーキテクチャ（設定ファイル参照方式、プロンプト外部ファイル化）に伴う技術的負債を解消し、AI-DLCの運用品質を向上させる。

## ターゲットユーザー
AI-DLC Starter Kitを利用してAI駆動開発を行う開発者

## ビジネス価値
- セットアップ時のユーザー体験向上（一問一答→まとめて確認形式）
- バックログ管理の自動化による運用負荷軽減
- フェーズ間の責務明確化による保守性向上
- デグレ修正による機能の完全性確保

## 成功基準
- setup-init.md でプロジェクト情報をまとめて確認できる
- Operations Phase完了時にバックログ完了項目が自動的に移動される
- Construction Phaseが自身のprogress.mdを作成する
- prompt-reference-guide.md と operations関連ファイルが正しく配置される

## 期限とマイルストーン
- Inception Phase: Intent、ユーザーストーリー、Unit定義
- Construction Phase: 各Unitの実装
- Operations Phase: テスト、リリース

## 制約事項
- メタ開発: AI-DLC Starter Kit自体の改善であることを意識
- 既存のproject.toml設定方式との整合性を維持
- 後方互換性: 既存サイクルへの影響を最小化

## 不明点と質問（Inception Phase中に記録）

（すべての項目はバックログから明確に定義されているため、追加の質問なし）
