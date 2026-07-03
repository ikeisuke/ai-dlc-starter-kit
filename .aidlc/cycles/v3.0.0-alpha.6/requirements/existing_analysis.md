# 既存コードベース分析

> 対象サブシステム focus: `skills/aidlc-v3/`（v3 リニューアル本体）の release フロー実装に関わる範囲。Phase 5（release）実装の前提把握を目的とする。

## ディレクトリ構造・ファイル構成

```
skills/aidlc-v3/
├── SKILL.md                  v3 オーケストレーター骨組み（フェーズ・コマンド・ルーティング定義）
├── steps/
│   ├── define.md             define フロー実行手順（Intent定義・Work Item分割・state 初期化）
│   ├── develop.md            develop フロー実行手順（size×depth_level 分岐・design・review）
│   └── status.md             status コマンド出力仕様（フェーズ導出・read-only）
├── scripts/
│   ├── state-init.sh         初期 state.json 生成（define Step 4 専用 / create-only）
│   ├── state-write.sh        state.json フィールド更新（atomic replace / mv）
│   ├── state-read.sh         state.json フィールド読取（read-only）
│   ├── state-validate.sh     state.json schema 検証（define_completed / release フィールド）
│   ├── work-item-next.sh     次 work item 選定（依存解決・resume 優先）
│   ├── work-item-status.sh   work item frontmatter status 読取/遷移
│   ├── work-item-validate.sh work item frontmatter schema 検証
│   ├── lib/frontmatter.sh    frontmatter パーサライブラリ
│   └── tests/                テストスイート
└── templates/
    ├── intent.md             Intent 定義テンプレート
    ├── work-item.md          Work Item frontmatter + 本文テンプレート
    ├── journal.md            Journal 追記型記録テンプレート
    └── design.md             Design 成果物テンプレート（depth_level 条件付きセクション）
```

設計 SoT は `docs/v3/`（rfc.md / workflow.md / data-model.md / migration.md）および `docs/v3-renewal-plan.md`。`config/` は v3 スキル配下になく、設定は `.aidlc/config.toml` 側に置く。

## アーキテクチャ・パターン

| パターン | 内容 | 根拠 |
|---------|------|------|
| state.json 単一状態源 | サイクルレベル状態を `state.json` に集約、`current_phase` は保持せず導出 | `docs/v3/data-model.md §3 / §5` |
| フェーズ導出（first-match） | `state.json` + work item frontmatter から `define / develop / release / complete` を一意導出 | `data-model.md §5.1` |
| frontmatter / state 責務分離 | work item 状態は frontmatter（done/withdrawn）、cycle 状態は state.json（release.*） | `data-model.md §3.3` |
| Step 単位の手順記述 | 各 step を「Step N + ゲート(★) + 成果物」で構造化、スクリプト呼び出しは usage/exit code/stdout 契約付き | `steps/define.md` / `steps/develop.md` |
| single-actor moment 書き込み | state.json 書き込みを define 完了時・release 時に限定し競合回避 | `data-model.md §3.3` |
| review perspective カタログ | 9 reviewing perspective を段階配置（develop: code/design、release: premerge/integration/deploy） | `workflow.md §6` |

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash（POSIX 寄り / macOS・Linux 両対応）+ Markdown 手順 | `skills/aidlc-v3/scripts/*.sh` |
| 実行基盤 | Claude Code Skill（`/aidlc-v3 <action>` ルーティング） | `skills/aidlc-v3/SKILL.md` |
| 状態管理 | JSON（`state.json`）+ Markdown frontmatter（work item） | `state-*.sh` / `lib/frontmatter.sh` |
| 外部 CLI | `gh`（PR 操作）、`dasel`（config 読取）、`codex`（AI レビュー） | v2 `operations-release.sh` / `read-config.sh` |

## 依存関係

- **内部（v3 内）**: `steps/*.md`（手順）→ `scripts/*.sh`（state/work-item 操作）→ `scripts/lib/frontmatter.sh`（パーサ）。release 手順は `state-read.sh` / `state-write.sh` / `state-validate.sh` / `work-item-validate.sh` に依存（read/write）。
- **review への依存**: release Step 2 の review は既存 reviewing スキル（`reviewing-operations-premerge` / `reviewing-construction-integration` / `reviewing-operations-deploy`）へルーティング。9→1 統合（`aidlc-review`）は後続 Phase のため、Phase 5 では既存 v2 reviewing スキルを呼び出す。
- **外部 CLI 依存**: `gh pr create/edit/ready/merge`、`gh pr view`（merged 判定）。
- **v2 参考資産**（直接流用ではなくパターン参考）: `skills/aidlc/steps/operations/operations-release.md`（Step 構成・PR 本文・post-merge）、`skills/aidlc/scripts/operations-release.sh`（サブコマンド設計・exit code 規約）、`skills/aidlc/templates/pr_body_template.md`。
- 循環依存: なし（手順 → スクリプト → ライブラリの一方向）。

## 特記事項

- **release フローは v3 側未実装**: `SKILL.md` で `release` コマンドは「予約（後続 Phase で実装）」（SKILL.md Line 46）。`steps/release.md` / `templates/release.md` / release 専用スクリプトは未作成。
- **state.json の release フィールドは schema 確定済み**: `release.pr_number` / `release.ready` / `release.merge_approved` の 3 フィールドが `data-model.md §3` で定義済み。`state-validate.sh` も release フィールドを検証対象に含む。Phase 5 は schema を変更せず、これらへの書き込み手順を実装する。
- **書き込みタイミングが契約化済み**: `release.merge_approved: true` は merge 後にブランチが消えるため **merge 前の最終コミット**で記録する（`data-model.md §3.3`）。`complete` 判定は `merge_approved`（承認記録）+ PR 実態（merged）の両方を要する（`data-model.md §5.1`）。
- **express ラッパとの整合**: SKILL.md の express ラッパ（work item 1 つ・risky なし時に define→develop→release 連続実行）が release アクションを参照済み（SKILL.md Line 74-83）。release.md 実装により express 経路が初めて release まで到達可能になる。
- **本サイクル自身の release は dogfooding 対象外**: alpha.6 自身のリリースは引き続き v2（`/aidlc operations`）で行う。v3 単独フルサイクル完走は Phase 6 完了が条件（Epic #736）。Phase 5 は release.md の「実装」が責務であり、自己リリースでの検証（dogfooding）は Phase 7。
