# 既存コードベース分析

本サイクル v2.5.3 の対象は「振り返り機能の信頼性向上」であり、改修対象ファイルが事前に絞り込まれているため、本ファイルは対象範囲のスコープ調査のみに限定する（プロジェクト全体の解析は省略）。

## ディレクトリ構造・ファイル構成

本サイクルで触れる主要ディレクトリ:

```text
skills/aidlc/
├── SKILL.md                                  # メインスキル本体（500行制限）
├── steps/
│   ├── operations/
│   │   └── 04-completion.md                  # Operations Phase 完了処理（651 行）
│   └── common/
│       └── review-flow.md                    # AI レビューフロー（247 行）
└── scripts/
    ├── write-history.sh                      # 履歴記録スクリプト（787 行）
    └── lib/
        ├── predecessor-issue.sh              # 前サイクル振り返り Issue 解決（338 行）
        ├── retrospective-issue.sh            # 振り返り Issue 起票・候補集約（1051 行）
        ├── retrospective-llm-draft.sh        # LLM ドラフト生成
        ├── retrospective-human-review.sh     # 人間レビュー
        ├── feedback-mode.sh                  # feedback_mode 設定読み出し
        ├── feedback-mode-wizard.sh           # interactive モード wizard
        ├── aidlc-paths.sh                    # AIDLC_PROJECT_ROOT 対応 path 解決（v2.5.2 Unit 003 で新設）
        └── ...

skills/write-history/
└── SKILL.md                                  # write-history 委譲スキル

templates/
├── retrospective_template.md                 # 振り返り KPT テンプレ
├── inception_progress_template.md
└── operations_progress_template.md
```

## アーキテクチャ・パターン

| 項目 | 検出結果 | 根拠 |
|------|---------|------|
| ドキュメント / プロセス記述 | Markdown ベースの宣言型ステップ仕様 | `steps/**/*.md` がプロセス定義の本体。コードはそれを支援する shell ライブラリ |
| Skill 委譲パターン | `skills/<name>/SKILL.md` に簡易インターフェースを定義し、実体スクリプトは `skills/aidlc/scripts/` に配置 | `skills/write-history/SKILL.md` が `skills/aidlc/scripts/write-history.sh` を呼び出す構造 |
| Bash ライブラリ多重 source ガード | 各 `.sh` ファイルの先頭で `__AIDLC_<NAME>_LOADED=1` を立てて多重 source を防止 | `predecessor-issue.sh:21-24` / `retrospective-issue.sh` 等 |
| 関数借用（horizontal dependency） | `predecessor-issue.sh` が `retrospective-issue.sh` から関数を借用（**本サイクルで解消対象**） | `predecessor-issue.sh:32-36` で `source "${__PRED_SCRIPT_DIR}/retrospective-issue.sh"` |
| Stdin/Stdout 契約 | NDJSON 1 行 + stderr 構造化（`<level>\t<code>\t<detail>`） | `predecessor-issue.sh` の出力フォーマットコメント |
| 5R 化レビューフロー | `review-flow.md` で「最後 2R 連続 clean or defer」を完了条件とする 5 round 上限の反復レビュー | `steps/common/review-flow.md` |
| 退避関数（`__retro_*` プレフィックス） | retrospective 系の内部 helper 関数は `__retro_` または `_spool_` プレフィックスで命名 | `retrospective-issue.sh` |

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 主要言語 | Markdown / Bash | `.aidlc/config.toml` の `[project.tech_stack].languages = ["Markdown"]`（実際は bash 実装多数） |
| Shell バージョン要件 | bash 4+（連想配列・`mapfile` 利用箇所あり） | `predecessor-issue.sh:1` shebang `#!/usr/bin/env bash` |
| 設定ファイル形式 | TOML（`config.toml` / `defaults.toml`） + dasel/yq | `aidlc-config-tools` で dasel 利用 |
| 外部 CLI 依存 | `gh`（GitHub CLI）/ `codex`（Codex CLI / レビュー）/ `dasel`（TOML 操作） | プリフライトの env-info.sh |
| テストフレームワーク | bats / shellcheck（基本）+ skill 単体は inline | `bin/tests/**` |

## 依存関係

### 内部モジュール間（本サイクル対象）

```text
[predecessor-issue.sh]
        |
        | source（直接 source / 本サイクルで解消対象）
        v
[retrospective-issue.sh]
        |
        +-- __retro_validate_cycle      （cycle 検証）
        +-- __retro_gh_status            （gh CLI 可用性）
        +-- _spool_extract_entries       （NDJSON spool パース）
        +-- _spool_append / _spool_remove_by_id（本サイクルでは触れない）
        +-- retrospective_collect_candidates（候補集約 / 触れない）
        +-- retrospective_issue_create   （起票 / 触れない）
        +-- retrospective_body_compose   （本文構築 / 触れない）
        +-- retrospective_prefill_hook   （Unit 003 prefill / 触れない）
        +-- retrospective_update_hook    （Unit 003 update / 触れない）

[aidlc-paths.sh]                    （v2.5.2 Unit 003 / 既存独立 helper として分離済 / 参考）
```

### Unit 004 で実施する分離後の構造（目標）

```text
[predecessor-issue.sh]
[retrospective-issue.sh]
        |
        | source（独立して呼び出し / 横依存なし）
        v
[aidlc-validate.sh]   # __retro_validate_cycle 等
[aidlc-gh.sh]         # __retro_gh_status 等
[aidlc-spool.sh]      # _spool_extract_entries 等
```

### 外部依存（変更なし）

- `gh` CLI: Issue 起票・Milestone 操作
- `codex` CLI: AI レビュー
- `dasel` / `yq`: TOML / YAML 操作

### エントリポイント（本サイクルで触る部分のみ）

- `04-completion.md` §1.0〜§1.5: Operations Phase 振り返りステップ → Unit 001 / Unit 003 で改訂
- `SKILL.md` AskUserQuestion 使用ルール表 → Unit 001 で「振り返り内容の決定」種別追加
- `review-flow.md` の指摘判定箇所 → Unit 003 で推定値検出ガード追加
- `write-history.sh` / `skills/write-history/SKILL.md` → Unit 002 で `--mode unit-complete-short-note` / `--mode operations-round` 追加
- `predecessor-issue.sh` / `retrospective-issue.sh` → Unit 004 で関数移管

### 循環依存の有無

現状: `predecessor-issue.sh` → `retrospective-issue.sh` の片方向（一方向 source）。逆依存はない。Unit 004 の helper 分離後は両者ともそれぞれ独立 helper（`aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`）を直接 source する形となり、依然として循環は発生しない。

## 特記事項

- **改修対象は既存仕様の追加・拡張のみ**: 既存の関数シグネチャ・出力フォーマット（NDJSON 1 行 + stderr 構造化）は破壊変更しない。Unit 004 では関数の物理配置のみが変わり、関数名・引数・戻り値・stderr メッセージは同一を維持する。
- **後方互換性の保証**: 既存呼び出し元（`01-setup.md` §4a など）は `predecessor_resolve_issue` を引き続き呼ぶ。実装内部の source 構造のみが変わるため、API 非破壊。
- **多重 source ガード**: 既存の `__AIDLC_<NAME>_SH_LOADED=1` パターンを新 helper 群でも踏襲する。
- **マージ前完結契約 (DR-001 / Unit 002 / v2.3.5)**: マージ後は `.aidlc/cycles/{{CYCLE}}/**` を改変できない。本サイクルでも全ての記録物（review-summary / progress.md / history / decisions.md）をマージ前に確定させる。
- **未完了箇所**: なし（解析範囲内で全項目記載完了）。
