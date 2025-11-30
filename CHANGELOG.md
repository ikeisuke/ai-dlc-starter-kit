# Changelog

AI-DLC Starter Kit の変更履歴です。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/) に基づいています。
バージョニングは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

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
