# Changelog

AI-DLC Starter Kit の変更履歴です。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/) に基づいています。
バージョニングは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

---

## [1.11.1] - 2026-01-29

### Added

- Construction → Operations引き継ぎファイル形式とテンプレート（#140）
  - operations_task_template.mdで手動タスクを明確に引き継ぎ
- ユーティリティスクリプト（#142）
  - aidlc-env-check.sh: 環境確認
  - aidlc-cycle-info.sh: サイクル情報取得
  - aidlc-git-info.sh: Git情報取得
- docs/shared/ ディレクトリ構成ガイドライン（#104）
  - サイクル横断で引き継ぐ共通資料の配置場所を明確化

### Changed

- construction.mdの各ステップにAIレビュー実施指示を明示化（#144）
  - Phase 1（設計）、Phase 2（実装）の承認前にレビューを必須化
- sandbox-environment.mdを大幅拡充（#141）
  - 認証方式比較（Keychain vs 手動、API Key vs OAuth）
  - サンドボックス種類の説明（ファイルシステム、ネットワーク、プロセス）
  - Cursor Read-Only Mode、Cline Auto-Approveの詳細説明
- ai-agent-allowlist.mdにユーティリティスクリプト活用を追記（#142）
  - 複合コマンドをスクリプト呼び出しに置き換え

---

## [1.11.0] - 2026-01-29

### Added

- サンドボックス環境ガイド追加（#26）
  - sandbox-environment.mdで各ツールのサンドボックス設定を解説
- AIエージェント許可リストガイド追加（#29）
  - ai-agent-allowlist.mdで各ツールの許可設定を解説
- aidlc.tomlテンプレート化（#138）
  - セットアップ時にテンプレートファイルから生成

### Changed

- Operations Phaseスキップ確認改善（#98）
  - 既存設定がある場合は確認なしで進行可能に
- タスク管理説明文追加（#129）
  - Construction PhaseでToDo機能の活用を推奨
- AIレビュー完了判定修正（#138）
  - 指摘ゼロで完了と判定するロジックを明確化
- README.mdバージョンセクション追加（#138）
  - 最新バージョンとバージョン履歴セクションの構成を標準化

---

## [1.10.1] - 2026-01-28

### Added

- gh (GitHub CLI) Skill（#123）
  - Git操作、Issue/PR管理、リポジトリ管理をAIエージェントから実行
- jj (Jujutsu) Skill（#124）
  - モダンなバージョン管理ツールjjの操作をAIエージェントから実行
- PRマージ後の確認手順（#134）
  - Operations Phaseでsquash使用を明示的に確認するフロー追加

### Changed

- README.mdのバージョン履歴を降順（新しい順）に変更（#130）
  - 最新バージョンを先頭に表示

### Fixed

- Codex Skillのresume機能の説明を明確化（#132）
  - threadId/agentIdの使い分けを明記

---

## [1.10.0] - 2026-01-28

### Added

- バックログ登録時の不明点確認フロー（#101）
  - 登録前に質問を促すガイダンス追加
- Unit完了時の設計・実装整合性チェック機能（#106）
  - Construction Phase Phase 2終了時に設計との整合性を確認
- AIレビュー指摘の先送り抑制ルール（#112）
  - 「あとでやる」判断時はユーザー承認必須に
- Issueテンプレートの差分確認機能（#113）
  - セットアップ時に既存テンプレートとの差分を表示
- PRによるIssue自動Close機能（#114）
  - Operations PhaseのPR作成時に `Closes #xx` を自動記載
- Issue用基本ラベルのセットアッププロンプト統合（#127）
  - init-labels.shによるラベル自動作成

### Changed

- inception.mdサイズ最適化（#115）
  - 812行から約10%削減
- バージョンチェックを環境一覧スクリプトに統合（#128）
  - env-info.shでバージョン情報を一括出力

### Fixed

- prompts/version.txt参照問題（#126）
  - 参照箇所をversion.txtに修正

---

## [1.9.3] - 2026-01-26

### Added

- env-info.shに--setupオプション追加
  - セットアップ時に必要な情報を一括出力（project.name, backlog.mode, current_branch, latest_cycle）
- codex skillにresume機能の説明追加

### Changed

- skills構成をシンボリックリンクからrsyncコピー方式に変更
  - プロジェクト独自スキルの追加が可能に
- KiroCLIエージェント設定を正確な内容に修正
  - .kiro/agents/aidlc.jsonのresources参照を修正
- init-cycle-dir.shのバージョン形式チェックを緩和
  - 任意の文字列を受け入れ可能に（空文字・スラッシュのみ拒否）
- アップグレード指示にメタ開発用パス参照を追記

### Fixed

- jj-support.mdの未追跡ファイル記述を修正
- jj-support.mdのリモートブックマーク表記を修正

---

## [1.9.2] - 2026-01-26

### Added

- プレリリースバージョンサポート（-alpha, -beta, -rc形式）
  - サイクル名・ブランチ名に-alpha, -beta, -rc接尾辞を許可
  - write-history.shでプレリリース形式のバリデーション対応
- KiroCLI Skills対応
  - resourcesフィールドによるファイル指定ガイド
  - .kiro/agents/aidlc.json自動生成

### Changed

- operations.mdサイズ最適化（付録を外部ファイルに分離）
  - 依存コマンド追加手順を`docs/development/dependency-commands.md`に移動
- ai_tools設定による複数AIサービス対応
  - 優先順位付きのサービスリスト指定
  - codex, claude, geminiの切り替え対応強化
- AI著者情報の自動検出機能
  - AI著者情報をツールから自動判定
  - ai_author設定のデフォルト値最適化

---

## [1.9.1] - 2026-01-25

### Added

- init-cycle-dir.shに共通バックログディレクトリ作成機能を追加
- コンテキストコンパクション時のAIDLC情報保持指示（AGENTS.md）

### Changed

- サイクル一覧取得時の不要項目（backlog, backlog-completed等）を除外
- 環境確認（gh/dasel状態）をセットアップ時1回に統合し重複解消
- 確認系処理をスクリプト化（check-gh-status.sh, check-backlog-mode.sh活用強化）
- Co-Authored-By設定をaidlc.toml経由で柔軟に設定可能に
- setup.mdの手動mkdirコマンドをinit-cycle-dir.shに統合
- rsync処理で`.github`ディレクトリを除外対象に追加
- セットアップ専用スクリプト（check-setup-type.sh）を`prompts/setup/bin/`に配置変更

---

## [1.9.0] - 2026-01-23

### Added

- プロンプトモジュール化基盤
  - common/intro.md - AI-DLC概要・役割定義の共通化
  - common/rules.md - 開発ルールの共通化
  - common/review-flow.md - AIレビューフローの外部化
- 参照方式の標準化（「ファイルを読み込んでください」指示形式）
- 参照漏れチェックスクリプト（check-references.sh）
- 設定確認スクリプト
  - check-backlog-mode.sh - バックログモード確認
  - check-gh-status.sh - GitHub CLI状態確認
- Operations Phaseサイズチェック機能（[rules.size_check]設定）
- 参照ガイド（reference-guide.md）
- deprecation対象コード一覧と警告メッセージ

### Changed

- 複合コマンドを単純コマンド + スクリプト呼び出しに置換
- プロンプト重複セクション削減（約300行削減）
- AIレビューフローを外部ファイル参照に変更
- アップグレード指示にメタ開発用パス参照を追加

### Removed

- 各プロンプト内の重複共通セクション（外部ファイル化）
- インラインの複合コマンド（スクリプト化）

---

## [1.8.2] - 2026-01-21

### Added

- スキルファイル対応（setup.skill.md, upgrade.skill.md）- AIエージェントのスキル拡張機能
- セットアップスクリプト（setup-aidlc.sh）- 対話型セットアップの自動化
- KiroCLI対応セクション（AGENTS.md）- resourcesフィールド設定ガイド
- AIレビューツール設定（ai_tools）- 複数AIサービスの優先順位設定対応
- jjサポート強化 - よくあるミスと対処法セクション追加

### Changed

- AIレビュー設定をai_toolsリストで指定可能に（Skills優先、MCPフォールバック方式統合）
- 全フェーズで反復レビュー処理を統一化
- スキルファイル同期をrsync対象に追加（prompts/package/skills/ → docs/aidlc/skills/）

---

## [1.8.1] - 2026-01-20

### Added

- env-info.shをsetup.mdの依存ツール確認セクションで活用
- write-history.shを各フェーズプロンプト（inception/construction/operations）に統合
- label-cycle-issues.sh - Unit定義ファイルからIssue番号を抽出しサイクルラベルを一括付与
- AIレビュー設定をSkills優先（MCPフォールバック）方式に改善（#70, #73）
- 依存コマンド追加手順をoperations.mdにドキュメント化（#72）

### Changed

- 履歴記録をheredocからwrite-history.sh呼び出しに統一
- AIレビュー判定フロー：Skills利用可能時はSkill使用、不可時はMCPフォールバック

---

## [1.8.0] - 2026-01-18

### Added

- スクリプト化基盤（`docs/aidlc/bin/`）
  - env-info.sh - 環境情報取得
  - init-labels.sh - GitHubラベル初期化
  - init-cycle-dir.sh - サイクルディレクトリ初期化
  - cycle-label.sh - サイクルラベル管理
  - issue-ops.sh - Issue操作
  - write-history.sh - 履歴書き込み
  - sync-prompts.sh - プロンプト同期
  - run-markdownlint.sh - Markdownlint実行
- プランモード活用ガイド（`docs/aidlc/guides/plan-mode.md`）
- フェーズ間連携（セットアップ→インセプション引き継ぎ）
- Unit完了チェック機能（Construction Phase Phase2終了時）
- markdownlint設定対応（[rules.linting].markdown_lint）
- 簡略指示「AIDLCアップデート」追加
- フィードバック手段追加（GitHub Issues/Discussionsへの誘導）
- worktreeサブディレクトリ化対応
- プロンプト最適化分析レポート（次サイクル向け準備）

### Changed

- 複合コマンドをスクリプト化（許可リスト運用改善）
- 各フェーズプロンプトでスクリプト呼び出しに統合
- セットアップコンテキストテンプレート追加

### Fixed

- 後方互換性：スクリプト未同期環境でのフォールバック動作

---

## [1.7.4] - 2026-01-14

### Added

- ツールインストール案内セクション（setup-prompt.md）- gh必須、dasel/jq/curlオプション
- サブエージェント活用ガイド（construction.md, guides/subagent-usage.md）
- KiroCLI対応セクション（AGENTS.md）- resources設定案内
- 質問深掘りルール（AGENTS.md）- 追加質問の深掘り方法を明確化
- 受け入れ基準の書き方ガイダンス（inception.md）- 良い例・悪い例を含む

### Fixed

- issue-onlyモードでのGitHub CLI検証・サイクルラベル作成が正常動作するよう修正
- 未追跡ファイルのみ存在する場合のコミット処理を修正（git status --porcelain使用）

---

## [1.7.3] - 2026-01-14

### Added

- daselによるTOML読み込み対応（setup-prompt.md）
- jj作業開始・終了時のガイド（jj-support.md）
- jj推奨設定（auto-local-bookmark）の記載
- Unit境界でのbookmark操作ガイド

### Changed

- プロンプト全体をdasel v3系に統一
- Markdownlint対象範囲を最適化（現在サイクルまたは変更ファイルのみ）
- setup.mdのステップ番号を連番に整理
- ドラフトPRのタイトル・説明文からドラフト表記を削除

### Fixed

- aidlc.tomlのコメント内バージョン番号が古い問題
- cicd_setup.mdのYAML抜粋が実ファイルと不一致の問題
- deployment_checklist.mdのlint対象がCIと不整合の問題
- post_release_operations.mdのGitHub Issueテンプレート記載漏れ

---

## [1.7.2] - 2026-01-13

### Added

- Claude Codeプランモード活用調査文書（Unit 006成果物として追加）
- iOSビルド番号確認機能（Inception Phaseでxcrun読み取り対応）
- GitHub Issueテンプレート（backlog.yml, bug.yml, feature.yml）
- jj許可リストガイドへのjjコマンド追加

### Changed

- セットアップフロー最適化（不要な確認ステップの省略）
- jjサポートドキュメント強化（gitとjjの考え方の違いセクション追加）
- バックログ管理ガイド改善（issue-driven-backlog.md → backlog-management.mdに統合）
- AGENTS.mdにバックログ管理方針を追加

### Fixed

- setup-prompt.mdテンプレートに[rules.jj]セクション追加

---

## [1.7.1] - 2026-01-11

### Added

- jjサポート有効化フラグ（[rules.jj].enabled）
- iOSアプリ向けInception Phaseでのバージョン更新対応
- AskUserQuestion推奨オプション順序ルール（推奨を一番上に配置）
- バックログラベル作成手順（setup.md）

### Changed

- Unitブランチ設定をconstruction.mdに統合（[rules.unit_branch].enabled参照）
- 許可リスト運用改善のための複合コマンド削減
- AIレビューイテレーション処理の改善
- バックログ管理モード（issue）の読み込み処理を修正

---

## [1.7.0] - 2026-01-11

### Added
- AIエージェント許可リストガイド（Claude Code, Cursor, Cline, Windsurf対応）
- GitHub Issueテンプレート（backlog.yml, bug.yml, feature.yml）
- setup-promptパス記録機能（aidlc.tomlの[paths].setup_prompt）
- Issue駆動バックログ管理ガイド（git/issueモード切替対応）
- jj（Jujutsu）基本ワークフローガイド（実験的サポート）
- Unitブランチ無効化設定（[rules.unit_branch].enabled）
- バックログ管理モード設定（[backlog].mode: git/issue）

### Removed
- Construction Phaseのバックアップステップを廃止（冗長なため）

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
