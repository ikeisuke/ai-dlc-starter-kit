# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v2.0.3

## 開発の目的
v2.0.0〜v2.0.2で構築したv2基盤のクリーンアップと品質改善を行う。具体的には、廃止予定機能の削除（Lite版ルーティング、ローカルバックログ）、ドキュメントの矛盾解消、テスト追加、ワークフロー改善を通じて、コードベースの保守性と信頼性を向上させる。

## ターゲットユーザー
AI-DLCスターターキットの利用者および開発者（自分自身を含む）

## ビジネス価値
- 廃止機能の削除によるコードベースの簡素化とメンテナンスコスト削減
- E2Eテスト追加による移行スクリプトの信頼性向上
- ドキュメント矛盾の解消によるユーザー混乱の防止
- ワークフロー改善による開発体験の向上

## 成功基準
- SKILL.md、CLAUDE.md、AGENTS.mdからLite版ルーティングテーブル（`lite inception`/`lite construction`/`lite operations`）が削除されていること
- Liteプロンプトファイル（`steps/*/lite-*.md` 等）が存在しないこと
- `backlog_mode`設定から`git`/`git-only`オプションが削除され、`issue`/`issue-only`のみサポートされていること
- `backlog_mode`に旧値（`git`/`git-only`）が設定されている場合、警告メッセージを表示し`issue`にフォールバックすること（エラーにはしない）
- v1→v2移行スクリプト（migrate-detect.sh, migrate-apply-config.sh, migrate-apply-data.sh, migrate-cleanup.sh, migrate-verify.sh）のE2Eテストが追加され、全テストがパスすること
- examples/kiro/README.mdの記述がsetup-ai-tools.shの実際の動作（シンボリックリンク自動管理）と一致していること
- Construction Phaseのステップ8（バックログ確認）が、全バックログ一覧表示ではなく、対象UnitのUnit定義ファイル「関連Issue」セクションから特定したIssueの詳細のみ確認する方式に変更されていること

## 期限とマイルストーン
1サイクルで完了（パッチリリース）

## 制約事項
- 既存のv2ユーザーへの影響を最小限にする
- ローカルバックログ廃止時、旧設定（`git`/`git-only`）はフォールバック＋警告で対応する（breaking changeにしない）
- ローカルバックログ関連ディレクトリ（`.aidlc/cycles/backlog/`等）の自動削除は行わない（既存データの安全性を優先）

## 含まれるもの
- #427: v1→v2移行スクリプトのE2Eテスト追加（テストコード追加のみ。移行スクリプト本体の変更は含まない）
- #426: Kiro設定のドキュメント矛盾を解消（examples/kiro/README.mdのドキュメント更新のみ）
- #425: Lite版ルーティングエントリの廃止・削除（SKILL.md/CLAUDE.md/AGENTS.mdのテーブル削除、Liteプロンプトファイル削除、旧Lite指示への廃止メッセージ実装）
- #424: Construction Phaseのバックログチェック改善（steps/construction/01-setup.mdのステップ8プロンプト変更のみ）
- #423: ローカルバックログの仕組みを廃止（プロンプト・スクリプト・設定のコード変更、defaults.tomlの有効値変更、バリデーション追加）

## 含まれないもの
- 新機能の追加（full_autoモード、並列Unit等）
- v1系のメンテナンス
- アーキテクチャの大規模変更
- 既存ローカルバックログデータの移行ツール
