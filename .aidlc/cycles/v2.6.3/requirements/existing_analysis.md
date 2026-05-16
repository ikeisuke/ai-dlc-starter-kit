# 既存コードベース分析

対象: AI-DLC Starter Kit（ai-dlc-starter-kit）/ ブランチ dev / 現行バージョン v2.6.2
本分析は v2.6.3（patch サイクル / 7 件のバックログ Issue 解決）の Reverse Engineering ステップとして実施。

## ディレクトリ構造・ファイル構成

```text
ai-dlc-starter-kit/
├── .claude-plugin/         # marketplace.json（version SoT = metadata.version）
├── .claude/                # Claude Code 設定（settings.json / settings.local.json）
├── .github/
│   ├── ISSUE_TEMPLATE/     # backlog / bug / feature / feedback の Issue フォーム
│   └── workflows/          # CI: pr-check / migration-tests / cycle-phase-completion-check /
│                           #     skill-reference-check / auto-tag
├── AGENTS.md, CLAUDE.md    # AI エージェント向けリポジトリ規約（Bash ツール安全パターン等の SoT）
├── bin/                    # リポジトリ運用・CI 用の汎用スクリプト群（配布対象外の開発ツール）
│   ├── check-*.sh          # CI チェッカ（markdownlint / size / utf8 / skill-references /
│   │                       #   bash-substitution / cycle-phase-completion / test-isolation 等）
│   ├── *-github-project.sh # GitHub Projects 連携（setup / probe / audit / migrate-issue-524）
│   ├── gh-project-cli.sh   # GitHub Projects CLI 本体
│   ├── lib/                # gh-project-* 共通ライブラリ（evidence / repo / spec / state / scope-check）
│   ├── update-version.sh   # バージョン更新
│   └── tests/              # bin 配下スクリプトの bats / sh テスト（aidlc-paths / gh-project /
│                           #   check-test-isolation / operations-712-squash / squash-unit）
├── config/                 # github-project-spec.yaml
├── docs/                   # 翻訳・設定・開発ドキュメント、docs/versions/v1.0.0/（v1 期の成果物アーカイブ）
├── examples/kiro/          # Kiro CLI 用エージェント設定例
├── prompts/                # setup-prompt.md
├── skills/                 # 配布物本体（Claude Code プラグインのスキル群）
│   ├── aidlc/              # メインオーケストレーター
│   │   ├── SKILL.md        # スキル定義本文（本文 500 行制限、詳細は steps/ に分離）
│   │   ├── agents/         # サブエージェント定義（retrospective-drafter.md）
│   │   ├── config/         # defaults.toml / config.toml.example / 各種スキーマ・テンプレート
│   │   ├── guides/         # 運用ガイド（20+ ファイル: backlog / branch-protection / error-handling 等）
│   │   ├── scripts/        # bash スクリプト本体（40+ ファイル）
│   │   │   ├── lib/        # 共通ライブラリ（bootstrap / version / validate / aidlc-paths /
│   │   │   │               #   cycle-resolver / toml-reader / retrospective-* 等）
│   │   │   └── tests/      # *.sh 単体テスト（test_*.sh、source して関数を assert する形式）
│   │   ├── steps/          # フェーズ別ステップ手順（Markdown）
│   │   │   ├── common/     # 全フェーズ共通（review-flow / review-routing / commit-flow /
│   │   │   │               #   bash-tool-safety / rules-core 等）
│   │   │   ├── inception/  # 01-setup 〜 06-backtrack
│   │   │   ├── construction/ # 01-setup 〜 04-completion
│   │   │   └── operations/ # 01-setup / 02-deploy / 03-release / 04-completion /
│   │   │                   #   operations-release.md
│   │   └── templates/      # 成果物テンプレート（intent / user_stories / pr_body 等 30+）
│   ├── aidlc-setup/        # 初期セットアップスキル（config 生成 / AI ツール導入 / migrate）
│   ├── aidlc-migrate/      # v1→v2 環境移行スキル
│   │   ├── scripts/        # migrate-*.sh + lib/path-guard.sh
│   │   └── steps/          # 01-preflight / 02-execute / 03-verify
│   ├── aidlc-feedback/     # フィードバック送信スキル
│   ├── aidlc-retrospective/ # 振り返りスキル
│   ├── install-kiro-agent/ # Kiro CLI エージェント設定インストール
│   ├── reviewing-common/   # Reviewing スキル共通基盤の「正本」（reviewing-common-base.md）
│   ├── reviewing-*/        # 9 個のフェーズ別レビュースキル（references/ に正本のコピーを保持）
│   ├── squash-unit/        # SKILL.md のみ（スクリプトは aidlc/scripts/squash-unit.sh を参照）
│   └── write-history/      # SKILL.md のみ（同上 write-history.sh を参照）
└── tests/                  # リポジトリ統合 bats テスト（50+ ファイル、fixtures/ 同梱）
```

役割の要点:
- `skills/` が配布物本体。`bin/` はリポジトリ自身の CI / 運用ツールで配布対象外。
- `skills/aidlc/scripts/` に実行ロジック、`skills/aidlc/steps/` に手順記述（SoT）、`skills/aidlc/guides/` に補足ガイドという三層構成。
- テストは 2 系統: `tests/` と `bin/tests/`（bats）、`skills/*/scripts/tests/`（純 sh、関数単体）。

## アーキテクチャ・パターン

- **Claude Code プラグイン構成**: `.claude-plugin/marketplace.json` でプラグイン `aidlc` を定義し、複数スキルをまとめて配布。各スキルは `SKILL.md` + 補助ファイル。
  - 根拠: `.claude-plugin/marketplace.json`、`README.md` のインストール手順、`skills/*/SKILL.md`。
- **SoT 一元化方針**: 規約・仕様の単一情報源（Single Source of Truth）を 1 ファイルに集約し、他ドキュメントは参照のみ。
  - 根拠: `CLAUDE.md`「§AI エージェント Bash ツール経由の安全パターン」が SoT、`SKILL.md` / `steps/common/bash-tool-safety.md` は参照。version の SoT は `.claude-plugin/marketplace.json` の `metadata.version`（`skills/aidlc/scripts/lib/version.sh` / `bootstrap.sh` のコメント）。
- **正本＋同期コピー（reviewing-common）**: `skills/reviewing-common/reviewing-common-base.md` を正本とし、`bin/sync-reviewing-common.sh` が 9 個の Reviewing スキルの `references/` へコピー。`--verify` で CI 検証。
  - 根拠: `bin/sync-reviewing-common.sh`、`.github/workflows/skill-reference-check.yml`。
- **bash ライブラリ層 + bootstrap パターン**: 各スクリプトは冒頭で `lib/bootstrap.sh` を source し、`AIDLC_PROJECT_ROOT` / `AIDLC_PLUGIN_ROOT` / `AIDLC_CYCLES` 等の環境変数と共通関数を取得。`set -euo pipefail` は呼び出し側責務。多重 source ガード（`_..._SOURCED` フラグ）が各 lib に存在。
  - 根拠: `skills/aidlc/scripts/lib/bootstrap.sh`、`write-history.sh:55-57`、`path-guard.sh:26-29`、`version.sh:29`。
- **CLI モード / source 互換の二重インターフェース**: ライブラリは `source` でも `bash <path>` 直接実行でも動作。末尾の `[[ "${BASH_SOURCE[0]}" == "$0" ]]` ガードで CLI モード判定。AI エージェント Bash ツール経由は CLI モード推奨。
  - 根拠: `version.sh:200-202`、同ファイル冒頭コメント、`SKILL.md`「バージョン表示」節。
- **機械可読な stdout/stderr 契約**: スクリプトは `history:<path>:<状態>` / `error:<code>:<message>` / tab 区切り 4 フィールド（`error\t<id>\t<path>\treason=<code>`）等、固定フォーマットで結果を返す。終了コードも規約化（0 成功 / 1 引数・コンテンツエラー / 2 I/O・環境エラー / 3 ガード拒否 等）。
  - 根拠: `write-history.sh:24-51`、`path-guard.sh:10-23`、`operations-release.sh` の `printf 'error\t...'` 群、`skills/aidlc/guides/exit-code-convention.md`。
- **result-out（出力変数注入）パターン**: 一部関数は第 1 引数に結果格納変数名を受け取り `printf -v "$var"` で書き戻す。コマンド置換 `$(...)` を避けるため（zsh OOM クラスバグ対策 / Intent 制約）に採用。
  - 根拠: `path-guard.sh` の `_aidlc_migrate_realpath` / `_..._realpath_m_into` / `_..._realpath_fallback_into` / `_..._normalize_logical_only`。
- **fail-closed セキュリティガード**: パストラバーサル検証、Operations post-merge 履歴書き込みガード等、判定不能時は安全側（拒否 / skip）に倒す。
  - 根拠: `path-guard.sh:_aidlc_migrate_validate_path`、`write-history.sh:evaluate_post_merge_guard`。
- **ドッグフーディング特殊処理の本体非埋め込み**: starter kit 自身か consumer かを本体スクリプトで判定しない。opt-in シグナル（ファイル存在）/ 明示フラグ / wrapper 分離で表現。
  - 根拠: `CLAUDE.md`「§ドッグフーディング特殊処理を本体に埋めない」。
- **AI-DLC サイクルワークフロー**: `.aidlc/cycles/<version>/` 配下に requirements / design-artifacts / plans / story-artifacts / construction / operations / history を持つフェーズ駆動。`init-cycle-dir.sh` がディレクトリ生成。

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash（`#!/usr/bin/env bash`、`set -euo pipefail`）。テスト補助に純 POSIX sh / bats | `skills/aidlc/scripts/*.sh`、`skills/aidlc/scripts/tests/test_*.sh` |
| フレームワーク | Claude Code プラグイン / スキル（SKILL.md ベース）。テストは bats-core | `.claude-plugin/marketplace.json`、`tests/*.bats`、`bin/tests/**/*.bats` |
| 主要ライブラリ | dasel（TOML/JSON 操作、優先）/ jq（フォールバック）/ git / gh CLI / markdownlint-cli2 | `version.sh:100-111`、`run-markdownlint.sh`、`.markdownlint-cli2.jsonc`、`write-history.sh:283`（gh）、`README.md` 前提条件 |
| 設定形式 | TOML（`config.toml` / `defaults.toml`）、JSON（`marketplace.json` / Kiro `aidlc.json`）、YAML（`github-project-spec.yaml` / Issue フォーム） | `skills/aidlc/config/`、`.claude-plugin/`、`config/` |
| CI | GitHub Actions（pr-check / migration-tests / cycle-phase-completion-check / skill-reference-check / auto-tag） | `.github/workflows/*.yml` |

## 依存関係

- **エントリポイント**:
  - スキル: 各 `skills/*/SKILL.md`（Claude Code が読み込む）。メインは `skills/aidlc/SKILL.md`。
  - スクリプト: `skills/aidlc/scripts/*.sh`（CLI 直接実行 or steps から呼び出し）、`bin/*.sh`（CI / 運用）。
- **内部モジュール境界（bash lib 層）**:
  - `skills/aidlc/scripts/lib/bootstrap.sh` … 全 `skills/aidlc/scripts/*.sh` の共通土台。`toml-reader.sh` と `version.sh` を内部で source。
  - `skills/aidlc/scripts/lib/version.sh` … `read_marketplace_version` / `read_starter_kit_version` / `validate_semver` を提供。`bootstrap.sh` から source される（境界: version 検証）。
  - `skills/aidlc/scripts/lib/validate.sh` … `validate_cycle` / `validate_unit_slug` / `validate_round_number` / `validate_non_negative_int` / `validate_write_history_mode` 等。`write-history.sh` 等が利用。
  - `skills/aidlc/scripts/lib/aidlc-paths.sh` … `aidlc_cycle_path` による cycle パス解決（境界: パス連結のみ、正規化は呼び出し側責務）。
  - `skills/aidlc/scripts/lib/cycle-resolver.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` / `retrospective-*.sh` … 各機能別境界。
  - `skills/aidlc-migrate/scripts/lib/path-guard.sh` … aidlc-migrate 専用のパストラバーサル検証境界。`migrate-apply-config.sh` から利用。aidlc 側 lib とは独立（別スキルの独自ライブラリ）。
  - `bin/lib/gh-project-*.sh` … `gh-project-cli.sh` / `*-github-project.sh` 群の共通境界。
- **外部ライブラリ依存**: git / gh CLI（GitHub 操作、PR 状態取得）、dasel または jq（設定読み取り）、markdownlint-cli2（lint）、bats-core（テスト）。dasel/jq は双方不在時 exit 2。
- **循環依存**: bash lib 層に明示的な循環は検出されず。`bootstrap.sh` → `toml-reader.sh` / `version.sh` の単方向。多重 source は各 lib のガードフラグで吸収。
- **同期依存（ビルド時整合）**: `reviewing-common-base.md`（正本）→ 9 スキルの `references/` コピー。`config/defaults.toml` ↔ テンプレートのキー同期（`bin/check-defaults-sync.sh`）。これらは CI で verify される。

## 特記事項

v2.6.3 の 7 Issue が触れる領域の現状:

### #706 — path-guard.sh の result-out 関数 namespace 統一
`skills/aidlc-migrate/scripts/lib/path-guard.sh` は result-out（出力変数注入）パターンを多用する。`_aidlc_migrate_path_guard_realpath_m_into` の冒頭コメント（68-72 行）に、呼出側が `_resolved` というローカル名で結果を受けるため本関数内で同名ローカルを宣言すると bash dynamic scope で `printf -v` が呼出側ではなく本関数のローカルを書き換える shadowing バグ（v2.6.2 CI で表面化、#680 残課題）の経緯が記録されている。回避策として本関数のみ `_local_m_resolved` という別名を使用。一方で `_aidlc_migrate_realpath` / `_aidlc_migrate_path_guard_init` / `_aidlc_migrate_validate_path` / `_..._realpath_fallback_into` / `_..._normalize_logical_only` はいずれも `_resolved` / `_result_var` / `_input` 等の汎用ローカル名のままで、命名規約が統一されていない。直近コミット `da212aea` も同種の `_resolved` shadowing 修正であり、リファクタの動機が明確。

### #703 — codex exec の `</dev/null` 必須運用の明文化
`skills/reviewing-common/reviewing-common-base.md` は「実行コマンド」節で `codex exec -s read-only -C . "<レビュー指示>"`（10 行）、「セッション継続」節で `codex exec resume <session-id> "<指示>"`（29 行）を記載しているが、いずれも `</dev/null`（stdin リダイレクト）の指定がない。`skills/aidlc/steps/common/review-flow.md` 11 行の Codex セッション管理記述、`review-routing.md` にも `</dev/null` 必須運用の明記はなし。本ファイルは `bin/sync-reviewing-common.sh` で 9 スキルの `references/` に同期される正本のため、修正は正本 1 箇所 → CI verify で伝播する構造。

### #701 — operations-release.sh cmd_squash_712 への validate_cycle 導入
`skills/aidlc/scripts/operations-release.sh` の `cmd_squash_712`（1012 行〜）は `--cycle` を受け取るが `validate_cycle` を呼んでいない。現状は補助関数 `__squash_712_check_history_clean`（847 行〜）内で「最小限のパストラバーサル拒否」（`*..* / /* / 改行` のみチェック、852-855 行）を行っているのみで、コメント（851 行）に「包括的な cmd_squash_712 全体への validate_cycle 導入は本 Unit のスコープ外（別 Issue 起票）」と明記されている。`validate_cycle` は `skills/aidlc/scripts/lib/validate.sh:39` に既存（空文字 / `..` / 空白 / 制御文字 / 先頭スラッシュ等を拒否）。他コマンド（`cmd_record_release_prep_commit` 等）も同様に未適用。`write-history.sh:944` は既に `validate_cycle` を使用しており、これが踏襲すべき先行パターン。

### #694 — operations ステップのマージ前 CI 通過確認フローの SoT 化
`skills/aidlc/steps/operations/` 配下にはマージ前の CI 通過確認に関する記述が複数ファイルに分散。`operations-release.md` には `## 7.9〜7.11 事前チェック`（109 行〜）、`reason:no-checks-configured` / `reason:checks-query-failed` の `--skip-checks` 分岐（347-361 行）、CI 状態と `--skip-checks` の効果表（361 行〜）がある。`03-release.md` は「CI/CD動作」（17 行）に簡潔に触れるのみ。`merge_pr` コマンド（`operations-release.sh:647`）が CI チェックを実行する実装側。CI 通過確認の手順が単一の SoT に集約されておらず、ステップファイル間で粒度が不揃い。

### #698 — /aidlc v 経路の SKILL.md バージョン表示節改訂 + version.sh 自己解決化
`skills/aidlc/SKILL.md` の「### バージョン表示」節（259 行〜）は CLI モード呼び出し `bash {SKILLベースディレクトリ}/scripts/lib/version.sh {marketplace.json のパス}` を必須とし、`marketplace.json` のパスを呼び出し側（AI エージェント）が `{SKILLベースディレクトリ}/../../.claude-plugin/marketplace.json` として組み立てる契約になっている（268 行付近、制約事項の `..` 例外 311 行）。`skills/aidlc/scripts/lib/version.sh` 側は引数 `$1` で JSON パスを受け取るのみで、パスを自己解決しない（`read_marketplace_version` は `$1` 必須、200-202 行の CLI ガード）。一方 `bootstrap.sh` は `AIDLC_PLUGIN_ROOT` から `marketplace.json` パスを既に算出している（38-46 行コメント）。「自己解決化」とは version.sh が `BASH_SOURCE` 等から marketplace.json を自力で導出し、呼び出し側のパス組み立て責務を不要にする方向の改修と読める。

### #705 — review-flow.md の MD038 違反 3 件
`skills/aidlc/steps/common/review-flow.md` 内に MD038（code span 内の前後空白）違反が 3 件存在するとされる。grep による機械抽出では `` ` ``（バッククォート）と空白の隣接が多数ヒットするが、その大半は正常な「コードスパン + 通常テキスト」の境界。実際の MD038 違反箇所は markdownlint-cli2 実行で特定する必要がある（`bin/check-markdownlint.sh` / `.markdownlint-cli2.jsonc` 設定下）。修正は当該 3 箇所のコードスパン内側の空白除去のみで、本文の意味変更を伴わない軽微な lint 修正。

### #702 — write-history.sh の symlink 解決＋repo-root 取得ロジックの共通ヘルパ化
`skills/aidlc/scripts/write-history.sh` には「filepath の symlink 解決（`cd ... && pwd -P`）→ `git rev-parse --show-toplevel` で repo-root 取得 → repo-root 相対パス正規化」という同一手順が 2 関数に重複している: `check_history_staged_status`（545 行〜、ステップ 0〜2）と `_commit_operations_round_history`（622 行〜、同パターン）。コメントにも「check_history_staged_status と同じパターン」と明記（628 行）。同種ロジックは `post-merge-cleanup.sh` / `main-repo-health-check.sh` / `squash-unit.sh` / `lib/cycle-resolver.sh` / `lib/retrospective-api.sh` / `lib/bootstrap.sh` でも `rev-parse --show-toplevel` / `pwd -P` を使用しており、共通ヘルパ（`lib/` 配下の新規関数）への切り出し余地がある。`bootstrap.sh` が共通ヘルパの配置先候補。

### 全般的な注意点・制約
- 配布物本体（`skills/`）はコマンド置換 `$(...)` / backtick を Bash ツール引数で使わない規約下にある（`CLAUDE.md` §AI エージェント Bash ツール経由の安全パターン / Issue #697）。`path-guard.sh` は新規ファイル内でコマンド置換を一切使わない設計（process substitution + `read` で代替）。新規・改修コードもこの制約に従う必要がある。
- result-out パターンと bash dynamic scope の相互作用（#706 の shadowing）は v2.6.2 で繰り返し CI を壊した実績があり、namespace 規約の明文化が再発防止策として要請されている。
- `reviewing-common-base.md`（#703 が触れる）は正本＋同期コピー構造のため、修正は正本のみ・CI（skill-reference-check）が同期を担保。
- v2.6.3 は patch サイクルであり、7 Issue はいずれも既存挙動の互換を保つ範囲のリファクタ・ドキュメント整備・lint 修正・バリデーション追加で、新規機能追加や破壊的変更は含まない。
