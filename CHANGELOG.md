# Changelog

AI-DLC Starter Kit の変更履歴です。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/) に基づいています。
バージョニングは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

---

## [1.20.0] - 2026-03-10

### Added

- 名前付きサイクル機能: `rules.cycle.mode` 設定（default/named/ask）を追加し、機能ドメイン別の並行開発を可能に。Inception Phaseプロンプトに名前入力・バリデーション・バージョン提案フローを統合（#293）
- squash-unitスキル定義: `squash-unit.sh` をスキル呼び出しで実行可能にするSKILL.mdを作成。引数自動解決・dry-runフロー・エラーハンドリングを定義し、commit-flow.mdにスキル呼び出し推奨を追記（#291）

### Changed

- 名前付きサイクル対応スクリプト修正: `setup-branch.sh`、`aidlc-cycle-info.sh`、`post-merge-cleanup.sh`、`init-cycle-dir.sh`、`suggest-version.sh` を `[name]/vX.X.X` 形式に対応。従来形式との後方互換を維持（#293）

---

## [1.19.1] - 2026-03-09

### Added

- Error Handling基本定義: エラー重大度レベル（Critical/High/Medium/Low）の定義と、Inception・Construction・Operationsフェーズごとの代表的エラーと回復手順をガイドとして追加（#282）
- Terminology/Glossary作成: AI-DLC用語集を新規作成 - Cycle, Phase, Intent, Unit, Story, PRFAQ等の10以上の用語を定義・参照先付きで整備（#283）

### Changed

- プロンプトルール明確化: `$()` 禁止ルールにバッククォート禁止を追加、改善提案時のバックログIssue登録ルールを`rules.md`に明文化（#286, #289）
- レビュースキル外部ツール優先: `review-flow.md`を更新し、外部CLIツール（codex, claude, gemini）をセルフレビューより優先するフローに変更。セルフレビューはフォールバックとして機能（#285）
- session-title表示順変更: `aidlc-session-title.sh`の表示フォーマットを「プロジェクト / バージョン / フェーズ / Unit」に変更し、オプションのunit引数を追加（#287）
- post-merge-cleanup.sh運用組み込み: Operations PhaseのPRマージワークフローに`post-merge-cleanup.sh`の実行を統合。worktree環境検出とdry-runバリデーションを追加（#288）

---

## [1.19.0] - 2026-03-07

### Added

- Overconfidence Prevention原則: AIの過信防止ルールを共通ルール（rules.md）に明文化 - 確信度が低い場合は推測せず質問するフロー、質問すべき場面のチェックリスト、レッドフラグと成功指標を追加（#218）
- Depth Levels（成果物詳細度の3段階制御）: `docs/aidlc.toml` に `[rules.depth_level]` 設定を追加し、minimal/standard/comprehensive の3レベルで成果物の詳細度を調整可能に。全フェーズプロンプト（Inception/Construction/Operations）にDepth Level分岐ロジックを実装（#218）
- Session Continuity: セッション中断・再開の正式サポート - `session-state.md` による状態保存・復元の仕組みを構築。コンテキストリセット時・ユーザー明示的中断時に自動生成し、再開時に中断地点から作業を継続可能に（#218）

### Changed

- Reverse Engineering強化: Inception Phaseの既存コード分析（ステップ2）を体系的手順に強化 - 構造解析・パターン検出・技術スタック推定を含むリバースエンジニアリングステージとして再構成（#218）

### Deprecated

- jjサポートを非推奨化: `[rules.jj].enabled = true` 設定時に非推奨警告を表示。将来のバージョンで完全削除予定。移行先: 別リポジトリのversioning-with-jjスキル（#276）

---

## [1.18.5] - 2026-03-06

### Fixed

- upgrade-aidlc.sh: worktree環境でのrsync同期漏れを修正 - Tier 3にメタ開発環境検出ガードを追加し、worktree内の最新ファイルがdocs/aidlc/に正しく反映されるように（#274）

### Changed

- コンパクション後のautomation_mode復元手順を強化: 適用範囲をsemi_auto限定からモード非依存に変更し、不到達の終了コード1を削除（#273）
- issue-onlyモード時のバックログ操作一貫性: inception.md・construction.mdのバックログ関連ロジックに4モードチェックを追加し、排他モード時のローカルファイル操作をスキップ（#272）

### Removed

- 既存ローカルバックログファイル（backlog-completed.md + backlog-completed/ 54ファイル）を削除 - issue-onlyモードで不要（#272）

---

## [1.18.4] - 2026-03-05

### Added

- セミオートモードPhase遷移改善: Construction→Operations遷移時の不要な停止を解消し、全Unit完了時に自動遷移（#267）
- エラー時バックログ記録支援: Construction Phaseでエラー発生時にバックログ登録を提案するフローを追加（#266）
- session-titleスキル: macOS専用のターミナルタブタイトル＋iTerm2バッジ設定スキルを新規作成。osascript（on run argv）でインジェクション防止（#269）
- PRマージ前レビューコメント確認: Operations Phase 6.7実行前にGitHub REST APIでCHANGES_REQUESTED状態と未返信コメントを検出する必須ゲートを追加（#268）

---

## [1.18.3] - 2026-03-04

### Added

- CI Bashコードブロック置換チェック: `prompts/package/prompts/` 配下のMarkdownファイル内のBashコードブロックで `$()` やバッククォートによるコマンド置換を自動検出するCIジョブを追加（#261）
- バージョン決定コンテキスト表示: Inception Phaseのバージョン提案前にバックログ一覧と直近サイクルの概要を表示（#217）
- 非SemVerサイクル命名対応: suggest-version.shで全サイクル一覧を出力し、カスタム名の重複チェックをサポート（#217）
- マージ後worktree同期自動化: `bin/post-merge-sync.sh` で親リポジトリのmain pull、worktreeのdetached HEAD化、マージ済みサイクルブランチ削除を自動化（#211）

### Changed

- upgrade-aidlc.sh: daselを必須依存に変更し、未インストール時にエラー終了とインストール手順を表示（#263）
- upgrade-aidlc.sh: `--config` オプションを廃止（全ユーザーがデフォルトパスを使用しており実需なし）（#264）

### Fixed

- セミオートモードでConstruction Phaseのレビューサマリが生成されないバグを修正（#262）

---

## [1.18.2] - 2026-03-02

### Added

- セッションタイトル設定ステップ: 各フェーズ初期化時にターミナルタイトルを自動設定し複数セッションの判別を容易に（#215）
- AIレビューフロー機密情報除外スキャン: レビュー前に機密ファイル（.env, .key等）を自動除外するステップを追加（#255）

### Changed

- upgrading-aidlcスキルのスクリプト化・PR自動分離: アップグレード処理をbin/upgrade-aidlc.shに外出しし、PR作成を自動化（#256, #213, #212）
- update-version.shをbin/に移動: rsync対象外にし利用先プロジェクトへの誤配布を防止（#210）

### Fixed

- プロンプト内Bashコードブロックから`$()`パターンを排除: AIエージェントによる意図しないコマンド展開を防止（#258）

---

## [1.18.1] - 2026-03-02

### Added

- worktreeクリーンアップスクリプト: PRマージ後の手動クリーンアップ作業（5ステップ）を自動化する`post-merge-cleanup.sh`を新規作成（#227）

### Changed

- operations.md分割リファクタリング: 1000行超のoperations.mdからステップ6をoperations-release.mdに分離し保守性向上（#257）
- バリデーションスクリプト統合: validate-uncommitted.shとvalidate-remote-sync.shをvalidate-git.shに統合、後方互換ラッパー提供（#248）

### Security

- write-history.shの--contentパラメータの安全性に関するドキュメント改善: ヒアドキュメント方式の安全性根拠を技術的に明記（#254）

---

## [1.18.0] - 2026-03-01

### Added

- セミオートモード実装: `[rules.automation].mode = "semi_auto"` 設定でAIレビュー合格時のユーザー承認を省略し自動遷移（#164）
- Amazon AI-DLCリポジトリ調査レポート: awslabs/aidlc-workflows との4軸比較分析と取り込み候補11件のリストアップ（#218）

### Changed

- レビューサマリ指摘一覧の詳細化: 問題点と対応内容を明確に記載するようテンプレートを改善（#247）
- Issueクローズタイミング変更: Unit完了時からPRマージ時（Operations Phase）に変更（#249）

### Fixed

- issue-ops.sh: ラベル未作成時のエラーハンドリング改善（label-not-found分類追加）（#250）
- squash-unit.sh: ルートコミットでのretroactive squash対応（#251）
- resolve-starter-kit-path.sh: スクリプト実行位置ベースのパス解決に書き直し（#252）

---

## [1.17.1] - 2026-02-28

### Added

- セルフレビューのスキル統合: reviewing-code/architecture/security/inceptionのSKILL.mdにself-reviewモードを追加し、review-flow.mdのステップ5.5からスキル経由でセルフレビューを実行可能に（#241）
- スコープ外指摘のバックログ自動登録: 指摘対応判断フローで「スコープ外」選択時にバックログ登録を必須化（#240）
- アップグレード処理スクリプト化: migrate-config.sh（設定マイグレーション）とresolve-starter-kit-path.sh（パス解決）をdocs/aidlc/bin/に追加（#233）
- $()コマンドのスクリプトファイル化: pr-ops.sh（PR操作）、issue-ops.sh拡張等でClaude Codeの許可プロンプトを削減（#243）

### Changed

- 千日手検出の同種指摘判定基準を明確化: review-flow.mdに判定条件を明文化（#239）
- mode=required時のステップ6フォールバック承認強化: ユーザー承認へ進む選択時に理由・対象成果物のwrite-history.sh記録を必須化（#238）
- ステップ6スキップ記録をwrite-history.sh形式に統一（#237）
- squash-unit.sh retroactiveモード改善: コミットフォーマット依存リスクを軽減（#244）
- Operations PhaseのIssueクローズ確認改善: PRのClosesセクションに含まれるIssueの手動確認を簡素化（#242）

### Security

- write-history.shの--contentパラメータでヒアドキュメント方式によるエスケープ処理を実装し、コマンドインジェクションリスクを排除（#236）

---

## [1.17.0] - 2026-02-28

### Added

- レビューサマリファイル生成: AIレビュー実施時に `{NNN}-review-summary.md` を自動生成し、レビュー結果を蓄積（#226）
- PR本文へのレビュー情報記載: Unit PRにレビューサマリ内容、サイクルPRにサマリファイルリンクを自動記載（#226）
- Inception Phase完了時のsquashルール: commit-flow.mdにInception完了コミットのsquash手順を追加（#234）
- squash-unit.sh 事後squash対応: `--retroactive`オプションで過去Unitの事後squashが可能に（#228）

### Changed

- 「人間レビュー」→「ユーザーレビュー」に用語統一: prompts/package/配下の全プロンプトで「人間レビュー」「人間に承認」「人間に提示」を置換（#230）
- AIレビュー未完了時のユーザーレビュー移行を制限: 指摘0件または指摘対応判断フロー完了まで続行を強制（#231）
- セルフレビューでサブエージェント活用: TaskツールやCodex等でメインコンテキストと分離したレビューを実施（#226）
- aidlc.tomlに`project.type`フィールドを追加

---

## [1.16.4] - 2026-02-26

### Fixed

- read-config.sh: dasel v3予約語（`type`, `name`等）を含むTOMLキーのクオート処理を追加（#223）
- issue-ops.sh: 認証済みgh環境でも `gh-not-authenticated` エラーを返すバグを修正（#225）
- Operations Phase完了メッセージの「start setup」を「start inception」に修正（#229）

### Changed

- read-config.shドキュメント: 古い呼び出しパターンを現行インターフェースに更新（#224）
- ai-agent-allowlist.md: Claude Code許可設定の推奨パターンを策定・追記（#219）

---

## [1.16.3] - 2026-02-23

### Changed

- read-config.sh: defaults.tomlからのフォールバック値取得を改善し、`--default`オプション不要で正常値を返すように修正（#221）
- ブランチ作成方式: `[rules.branch].mode`設定の追加により、サイクル開始時のブランチ方式選択を固定化可能に（#220）
- コンテキストリセット: Unit完了時・Phase完了時のリセットメッセージに完了作業の要約・リポジトリ状態・次アクションのサマリを追加（#209, #214）
- セルフレビューフォールバック: 外部レビューツール（Skills）利用不可時に実行中エージェント自身がセルフレビューを実施する機能を追加（#216）

---

## [1.16.2] - 2026-02-22

### Added

- `check-issue-templates.sh`: GitHub Issueテンプレートのローカル/リモート差分検出スクリプト（#205）
- `update-version.sh`: version.txtとaidlc.tomlのバージョン一括更新スクリプト（#204）
- `sync-package.sh`: prompts/package/からdocs/aidlc/へのrsync同期一括スクリプト（#203）
- `defaults.toml`: read-config.shのデフォルト値集中管理ファイル（#206）
- フェーズ実行方式（スキル化 vs サブエージェント化）の設計検討ドキュメント（#200）

### Changed

- aidlc.toml設定キー構造を統一: `[backlog]`セクションを`[rules.backlog]`に移動（#207）
- read-config.shデフォルト値を集中管理に移行: 呼び出し側での`--default`指定が不要に（#206）
- check-backlog-mode.sh, env-info.sh: 旧キー`[backlog].mode`のフォールバック読み取りを追加（#207）

---

## [1.16.1] - 2026-02-21

### Added

- `validate-remote-sync.sh`: リモート同期確認ロジックをスクリプト化（#201）
- `validate-uncommitted.sh`: コミット漏れ確認ロジックをスクリプト化（#201）
- 共通処理スキル化の全体設計ドキュメント: 各フェーズプロンプトの共通処理をスキルとして切り出す設計を策定（#200）

### Changed

- Operations Phase: 定型処理（リモート同期確認・コミット漏れ確認）をスクリプト呼び出しに置き換え、1033行→996行に削減（#201）

---

## [1.16.0] - 2026-02-20

### Fixed

- aidlc-git-info.sh: git worktree環境でVCSを正しく検出できない問題を修正（#198）
- suggest-version.sh: `get_latest_cycle()`にSemVerバリデーションを追加し不正なバージョン文字列を除外（#197）

### Changed

- Operations Phase: PRマージ前にリモートpush確認ステップ（6.6.6）を追加（#196）

---

## [1.15.2] - 2026-02-19

### Fixed

- check-open-issues.sh: `--limit` 引数の数値バリデーション追加（#194）
- suggest-version.sh: case文にデフォルトケース追加（#194）
- ios-version-update.md: パラメータ展開構文エラー修正（`${{CYCLE}#v}` → `${CYCLE#v}`）（#194）
- config-merge.md: TOML同一テーブル重複定義修正（#194）
- check-open-issues.sh: エラー処理フォールバック改善（#194）
- issue-ops.sh: `parse_gh_error` に認証エラー対応を追加（#194）
- cycle-label.sh: リダイレクト設定の補足コメント追加（#194）
- setup-branch.sh: `realpath` 利用への変更（#194）
- aidlc-git-info.sh: IFS初期化追加（#194）
- env-info.sh: dasel `-f` オプション利用に変更（3箇所）（#194）

---

## [1.15.1] - 2026-02-18

### Added

- AIDLC専用レビュースキル: Inception Phase成果物（ユーザーストーリー・インテント）のレビュー機能（#191）
  - `reviewing-inception/SKILL.md`: ユーザーストーリー品質・Unit分解の妥当性を検証

### Changed

- upgrading-aidlcスキル簡略化（#189）
  - setup-prompt.mdのローカル探索ステップを省略し、2ステップ（ローカル確認→toml経由解決）で特定
- Kiro標準スキル呼び出し対応（#192）
  - `setup-ai-tools.sh`で`.kiro/skills/`にシンボリックリンクを配置
  - Kiroネイティブのスキル発見機能に対応

### Fixed

- migrate-backlog.sh: macOS sed互換性エラー修正（#190）
  - 日本語文字範囲を含むsedパターンをPerl互換の正規表現に置換

---

## [1.15.0] - 2026-02-15

### Added

- Unit完了時のコミットsquashスクリプト（#187）
  - `bin/squash-unit.sh`: git環境でのsquash実行スクリプト
  - jj環境対応（`jj squash`コマンドによる統合）
  - インタラクティブ操作不使用（CI/自動化対応）
  - construction.mdにsquash呼び出しフローを統合

### Changed

- プロンプト構造の大規模リファクタリング（#116）
  - 巨大な単一ファイル（inception.md, construction.md, operations.md）を共通モジュールに分割
  - `prompts/package/prompts/common/` に共通コンポーネントを外部化
    - agents-rules.md, ai-tools.md, commit-flow.md, compaction.md, context-reset.md
    - feedback.md, phase-responsibilities.md, progress-management.md, project-info.md
    - review-flow.md, rules.md
  - 各フェーズプロンプトはフェーズ固有の内容のみに簡素化
  - Skills化に向けた構造的基盤の整備
- コミット処理をconstruction.mdに統合リファクタリング（#187）
  - Unit完了コミットとsquash処理の一貫したフロー定義
  - Co-Authored-By自動検出の共通化

---

## [1.14.1] - 2026-02-14

### Changed

- Operations Phaseステップ6.0（バージョンファイル更新）をプロジェクト固有処理に移動（#185）
  - operations.md（パッケージ側）からステップ6.0を削除
  - rules.mdのカスタムワークフローとして再配置
  - 既存の「カスタムワークフローはスキップ対象外」の仕組みを活用
- Operations Phaseステップ0のスキップ判定改善（#184）
  - バージョン確認をステップ1（デプロイ準備）からステップ6（リリース準備）に移動
  - ステップ0「変更なし」選択時のスキップ対象をステップ1-4に限定
  - ステップ5（バックログ整理）を常に実行（ステップ1-4の成果物に依存しないため）
- `rules.unit_branch.enabled` の未設定時デフォルト値を `true` から `false` に変更（#182）
  - 明示的に `enabled = true` を設定済みのユーザーには影響なし

---

## [1.14.0] - 2026-02-14

### Added

- レビュー種別スキル新設（#181）
  - reviewing-code: コード品質レビュー（可読性、保守性、パフォーマンス、テスト品質）
  - reviewing-architecture: アーキテクチャレビュー（構造、パターン、API設計、依存関係）
  - reviewing-security: セキュリティレビュー（OWASP Top 10、認証認可、依存脆弱性）

### Changed

- AIレビューフローをスキルベースに刷新（#181）
  - review-flow.mdをレビュー種別スキル呼び出しに変更
  - 設定セクション名を `[rules.mcp_review]` → `[rules.reviewing]` に変更
  - MCP関連参照を全て削除
- jjスキル改善
  - agentskills.ioベストプラクティスに準拠したフロントマター
  - Git比較表をreferences/に分離（Progressive Disclosure）
- aidlc-upgradeスキル改善
  - agentskills.ioベストプラクティスに準拠したフロントマター
  - setup-prompt.md検索フローを最適化（2ステップ検索、再帰Glob禁止）
- ドキュメント・リンク整合（#181）
  - AGENTS.md、skill-usage-guide.md、setup-prompt.md、rules.mdを新スキル構成に更新

### Removed

- 旧レビュースキル削除（#181）
  - codex-review、claude-review、gemini-review の各スキルを削除
- ghスキル削除
  - gh操作はスキル経由不要のため削除
- guides/jj-support.md
  - jjスキルのreferences/に統合済み

---

## [1.13.4] - 2026-02-12

### Added

- Codex CLIスキル設定ドキュメント（#177）
  - `skill-usage-guide.md` にCodex CLI / Gemini CLIセクションを分離・拡充
  - `~/.codex/skills/` へのシンボリックリンク設定手順と確認方法を追加
- Codex skills compatibilityフィールド（#178）
  - `codex-review/SKILL.md` にAgent Skills Specification v1.0準拠のcompatibilityフィールドを追加
  - サンドボックス要件（ネットワークアクセス等）を明記

### Fixed

- claude-reviewスキルの不安定動作対策（#179）
  - `--output-format stream-json` オプションをデフォルトに追加し、レスポンス未返却を改善
  - 既知の制限事項セクションを新設（レスポンス未返却、指摘の非決定性、stream-json出力形式）
  - 全コマンド例にstream-jsonオプションを追加

---

## [1.13.3] - 2026-02-10

### Added

- フィードバック送信機能のオン/オフ設定（#174）
  - `docs/aidlc.toml` に `[rules.feedback].enabled` を追加
  - `enabled = false` で機能を無効化可能（企業利用時の情報漏洩リスク軽減）
  - `read-config.sh` による設定読み込みに対応

### Changed

- Construction Phase progress.md更新タイミング修正（#175）
  - Unitブランチ使用時、progress.md更新をPR作成前に移動
  - Operations Phaseの「PR準備完了」パターンをConstruction Phaseにも適用

---

## [1.13.2] - 2026-02-07

### Added

- コンパクション時のフェーズプロンプト再読み込み指示（#170）
  - 自動要約後もフェーズのルールと手順が維持されるよう対応
  - inception.md, construction.md, operations.mdに再読み込み指示を追加
- Issueラベル初期化処理のセットアップ/アップグレード対応（#169）
  - init-labels.shをアップグレード時にも実行するよう修正

### Changed

- setup-branch.shがプレリリースバージョン（-alpha.N, -beta.N, -rc.N）に対応
- operations.md行数削減（#172）
  - AIレビューフローをreview-flow.mdへの外部参照に変更
- セルフアップデート処理を `/aidlc-upgrade` スキル呼び出しに簡略化
- progress.md更新タイミングをPRマージ前（Gitコミット前）に移動

### Removed

- setup-context.md機能を廃止
  - SetupとInception統合により不要になったため
  - setup_context_template.mdを削除

### Fixed

- backlogディレクトリ作成の条件分岐（#162）
  - Issue駆動モード時に不要なディレクトリ作成を抑制

---

## [1.13.1] - 2026-02-06

### Added

- アップグレード処理のスキル化（#133部分）
  - `/upgrade` コマンドでAI-DLCアップグレードを開始可能に
  - aidlc-upgrade/SKILL.mdを追加
- AskUserQuestion機能の活用ガイド強化（#168）
  - 「必ず使用すべき場面」リストを追加
  - Unit選択、設計承認、AIレビュー継続判断等を明記

### Changed

- PRマージ手順の改善（#167）
  - progress.md更新をコミットしてからマージする手順を明記
- Unit完了時のコミット確認追加（#166）
  - Construction Phaseに `git status` 確認ステップを追加
- 論理設計テンプレート強化（#165）
  - スクリプトインターフェース設計セクションを追加
  - 成功時出力/エラー時出力/使用コマンドの記載ガイド
- 旧形式バックログ移行をsetup-prompt.mdに移動（#163）
  - inception.mdからアップグレード処理へ移動
  - v2.0.0で削除予定のDEPRECATED注記を追加
- アップグレード完了後の案内メッセージ更新（#160）
  - 「start inception」での開始を案内

### Fixed

- suggest-version.shがalpha/betaなしバージョンでエラーとなる問題（#161）
  - `v2.0.0` 等のバージョンでも正しく動作するように修正

---

## [1.13.0] - 2026-02-05

### Added

- Operations Phaseにversion.txt更新手順を明示化（#158）
  - リリース準備ステップでバージョン更新漏れを防止
- Inception PhaseにAIレビュー導入（#154）
  - Intent明確化の深掘り強化
  - 受け入れ条件の厳格化
- Issueライフサイクル管理ガイド追加（#28）
  - issue-management.mdでIssue状態遷移を明文化
  - ラベル・マイルストーン活用の推奨
- PRマージ時のIssue自動クローズ機能強化（#96）
  - Operations PhaseのPR作成時に複数Issue対応

### Fixed

- label-cycle-issues.shのラベル付け漏れバグ修正（#148）
  - 対象Issueが正しくラベル付けされるように修正

### Removed

- Dependabot PR確認機能を廃止（#96）
  - aidlc.tomlの[inception.dependabot]セクションは無視される
  - 必要な場合はrules.mdに手動確認手順を記載可能

---

## [1.12.1] - 2026-02-04

### Added

- inception.md外部化スクリプト（#151）
  - suggest-version.sh: バージョン推測
  - setup-branch.sh: ブランチ/worktree作成
  - migrate-backlog.sh: バックログ移行
  - worktree-usage.md: worktree使用ガイド

### Changed

- Construction Phase確認の自動化（#156）
  - AIレビュー実施確認を履歴ファイルから自動判断
  - 引き継ぎ確認をoperations/tasks/確認で自動化
- inception.mdサイズ最適化（#151）
  - 1215行→865行（350行削減）
  - 冗長な記述をスクリプト呼び出しに外部化
- setup-prompt.md参照先変更（#152）
  - setup.md経由を廃止し、inception.mdを直接参照

### Fixed

- env-info.shバグ修正（#153）
  - starter_kit_versionがdocs/aidlc.tomlから正しく取得されない問題
  - current_branchがjj/git環境で正しく取得されない問題
  - dasel未インストール環境でのフォールバック

---

## [1.12.0] - 2026-02-01

### Added

- プロジェクト個人設定機能（aidlc.toml.local）
  - チーム共有設定と個人の好みを分離、設定コンフリクトを防止
- ユーザー共通設定機能（~/.aidlc/config.toml）
  - 複数プロジェクトで共通の設定を一元管理
- 3階層設定マージ機能
  - ユーザー共通 → プロジェクト → プロジェクト個人の優先順位で設定をマージ
- config-merge.mdガイド追加
  - 設定マージの仕組みと使用方法を解説

### Changed

- Setup/Inception Phase統合（通常版・Lite版）
  - 1回のプロンプト読み込みでサイクル開始からUnit定義まで完了可能に
- Codex Skill resume機能活用
  - AIレビュー時に同一Unit内でコンテキストを継続可能に
- Dependabot PR確認オプション化
  - aidlc.tomlで有効/無効を設定可能に（デフォルト: 無効）

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
