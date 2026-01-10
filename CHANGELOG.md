# Changelog

AI-DLC Starter Kit の変更履歴です。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/) に基づいています。
バージョニングは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

---

## [1.6.1] - 2026-01-10

### Added
- フェーズ簡略指示機能（「インセプション進めて」等のキーワードでプロンプト自動読み込み）
- AGENTS.md テンプレートに共通ルールセクション追加
- ブランチ名からのサイクル自動判定機能
- mainブランチ時のセットアップ促進メッセージ
- 各フェーズプロンプトの完了時メッセージを簡略指示形式に更新

### Changed
- rules_template.md から AI-DLC 共通ルールを分離（AGENTS.md へ移動）
- AskUserQuestion 機能の使用ルールを強化（不明点がなくなるまで繰り返し質問）

---

## [1.6.0] - 2026-01-10

### Added
- CLAUDE.md/AGENTS.md を参照形式に変更（既存プロジェクトでの上書き問題解消）
- docs/aidlc/prompts/ に CLAUDE.md, AGENTS.md を追加（rsync 同期対象）
- AskUserQuestion 機能の活用ルール（CLAUDE.md）
- TodoWrite ツールの活用ルール（CLAUDE.md）
- レビュー前後のコミットワークフロー
- CHANGELOG.md による変更履歴管理
- バージョンタグ運用手順（Operations Phase）

### Changed
- セットアップフロー改善（worktree/ブランチ操作の簡略化）
- ブランチ作成とワークツリー作成を一括実行可能に

### Fixed
- `ls -d` コマンドのスラッシュ二重表示問題

---

## [1.5.4] - 2026-01-08

### Added
- markdownlint ルールの段階的有効化
- AGENTS.md/CLAUDE.md への AI-DLC 統合
- レビュー前後のタイミングでコミット

### Changed
- 一問一答質問で AskUserQuestion 使用

### Fixed
- AI レビュー必須設定が機能しない問題
- macOS の grep -oP 互換性問題
- Unit ブランチ作成時に PR が作成されない問題

---

## [1.5.3] - 2026-01-03

### Added
- AI レビュー機能の強化
- CI/CD 基盤整備（GitHub Actions）
- 監視基盤整備

### Changed
- シェル互換性の向上（bash/zsh 両対応）

### Fixed
- セットアップ関連の複数バグ修正

---

## [1.5.2] - 2025-12-25

### Added
- ドラフト PR ベースの並行作業ワークフロー
- バックログ移行の自動化（旧形式→新形式）

### Changed
- アップグレードしない場合でもサイクル開始可能に

---

## [1.5.1] - 2025-12-22

### Added
- プロジェクトタイプの明示的設定機能

### Changed
- 履歴保存タイミングの調整
- コミットメッセージにサイクル名を含める
- セットアップエントリーポイントの変更
- セットアッププロンプトの統合・整理

---

## [1.5.0] - 2025-12-20

### Added
- 予想禁止・一問一答質問ルール
- Construction Phase 以外でのコード記述制限
- 外部入力（AI MCP・ユーザー）の検証ルール

### Changed
- サイクルセットアップ処理を専用プロンプトに分離
- グリーンフィールドセットアップ時の質問フロー改善

### Removed
- Operations Phase のセルフアップデート処理を廃止

---

## [1.4.1] - 2025-12-20

### Added
- コマンドラインツールのプロジェクトタイプ追加
- Workaround 実施時のバックログ追加ルール
- README.md 読み込み時のリンク追跡機能

### Changed
- Unit 定義ファイルに実行順序番号を付与

### Removed
- コミットハッシュのファイル記録を廃止

---

## [1.4.0] - 2025-12-16

### Added
- git worktree 活用ワークフローの提案
- Operations Phase でアプリケーションバージョン更新確認
- AI MCP レビュー活用の提案機能
- 作業中の割り込み対応ルール明確化

### Changed
- history.md の複数人開発時コンフリクト対策
- サイクルバージョン提案ロジック改善
- Operations Phase「完了時の必須作業」構造改善

---

## [1.3.2] - 2025-12-13

### Added
- コミットハッシュ記録の注意事項
- PR マージ後のブランチ削除をオペレーションルールに追加
- アップグレード時の変更内容要約表示

### Removed
- 全ファイルから「最終更新」セクションを廃止

### Fixed
- Operations Phase アップグレード処理でのバージョン番号更新問題

---

## [1.3.1] - 2025-12-12

### Added
- バックログ項目の対応済みチェック
- Inception Phase 開始時の Dependabot PR 確認

### Changed
- アップグレード不要時のセットアップスキップ対応

---

## [1.3.0] - 2025-12-10

### Added
- Construction Phase 用 progress テンプレート
- Unit 開始前のバックログ確認ステップ
- PR マージ後の main 移動・pull 手順明確化

### Changed
- progress.md を Unit 定義ファイル内「実装状態」セクションに統合（複数人開発時のコンフリクト対策）
- コンテキストリセットのタイミング見直し
- Unit 定義ファイルのパス予測を効率化
- backlog.md/backlog-completed.md の構造改善
- 初回セットアップ時のサイクルバージョン提案改善

### Fixed
- Operations Phase のバージョン更新処理

---

## [1.2.3] - 2025-12-09

### Added
- フェーズ遷移のガードレール強化
- aidlc.toml に starter_kit_version フィールド追加

### Fixed
- Lite版プロンプトのパス解決問題
- 履歴の日時記録の正確性向上
- バージョン移行時の安全性向上

---

## [1.2.2] - 2025-12-06

### Added
- Unit 作業中の気づき記録フロー
- ホームディレクトリへのユーザー共通設定機能
- Lite版サイクルの案内を追加

### Changed
- ファイルコピー判定にハッシュ値を使用
- Inception Phase でサイクル固有バックログを確認

---

## [1.2.1] - 2025-12-06

### Added
- Operations Phase 完了時のバックログ自動移動

### Changed
- セットアップ時の確認方式改善（一問一答→まとめて確認）

### Fixed
- Construction Phase が progress.md を作成するよう修正
- prompt-reference-guide.md と operations 関連ファイルの配置修正

---

## [1.2.0] - 2025-12-05

### Added
- GitHub Actions による自動タグ付け
- プロンプトへのバージョン情報埋め込み

### Changed
- プロンプトの分割・短縮化（AI応答品質向上）
- セットアップ処理を「初回」と「サイクル」に分離

---

## [1.1.0] - 2025-12-02

### Added
- Operations Phase 再利用性（サイクル横断での CI/CD 維持）
- 軽量サイクル（Lite版）のサポート
- ブランチ確認機能（誤ブランチでの作業防止）
- コンテキストリセット提案機能（フェーズ移行時・Unit完了時）

---

## [1.0.1] - 2025-11-28

### Added
- バージョンアップ基盤の構築（CHANGELOG.md, version.txt）
- テスト記録テンプレート（`docs/aidlc/templates/test_record_template.md`）
- バグ対応フロー文書（`docs/aidlc/bug-response-flow.md`）
- バックログ管理テンプレート（`docs/aidlc/templates/backlog_template.md`）
- セットアップファイルのフェーズ別分割（`prompts/setup/`）

### Changed
- セットアッププロンプトの最適化（1746行 → 5ファイル分割）
- サイクル指定方法の改善（各フェーズプロンプトでサイクル確認）
- Operations Phase プロンプト更新（テスト記録・バグ対応セクション追加）
- Construction Phase プロンプト更新（バックトラックセクション強化）

### Fixed
- セットアップ時の `inception/` ディレクトリ作成バグを修正
- 日付取得方法の明確化（タイムゾーン付き）

---

## [1.0.0] - 2025-11-27

### Added
- AI-DLC Starter Kit 初回リリース
- 3フェーズ構成（Inception / Construction / Operations）
- プロンプトテンプレート一式
- ドキュメントテンプレート一式
