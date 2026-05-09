# 既存コードベース分析

本サイクル v2.6.0 のスコープに直接関係するコンポーネントに絞って既存コードを調査した結果。

## ディレクトリ構造・ファイル構成

```text
ai-dlc-starter-kit/
├── .claude-plugin/
│   └── marketplace.json        # ★ #617 SoT 移行先（現在 metadata.version = "2.0.4" で乖離中）
├── .aidlc/
│   ├── config.toml             # starter_kit_version = "2.5.5"（書き換え対象 / aidlc-setup 経由）
│   ├── rules.md                # ★ #614 L107/L122 MD040 違反箇所
│   └── cycles/                 # サイクル成果物
├── bin/
│   └── update-version.sh       # ★ #617 拡張対象。現在 version.txt 系 3 ファイルのみ更新
├── version.txt                 # ★ #617 廃止候補（現在: 2.5.6）
├── skills/
│   ├── aidlc/                  # 主スキル
│   │   ├── SKILL.md            # ★ /aidlc parser に retrospective 追加（#667）
│   │   ├── version.txt         # ★ #617 廃止候補
│   │   ├── scripts/
│   │   │   ├── env-info.sh     # starter_kit_version 取得経路（移行影響）
│   │   │   ├── lib/version.sh  # read_starter_kit_version（移行影響）
│   │   │   └── ...
│   │   └── steps/
│   │       ├── inception/01-setup.md  # ★ #617 ステップ5a の参照経路
│   │       └── operations/04-completion.md  # ★ #667 §1 振り返りロジック移転元
│   ├── aidlc-setup/
│   │   ├── version.txt         # ★ #617 廃止候補
│   │   └── scripts/
│   │       └── migrate-backlog.sh  # ★ #615 cut -c1-50 バグ箇所（line 79）
│   ├── aidlc-feedback/         # 既存独立スキル（参考: /aidlc-retrospective 構造の手本）
│   ├── aidlc-migrate/          # 既存独立スキル
│   └── reviewing-*/            # レビュー系スキル
└── tests/                      # ルートレベル test
```

## アーキテクチャ・パターン

| 項目 | 値 | 根拠 |
|------|-----|------|
| プラグイン構造 | Claude Code Plugin (Anthropic Marketplace) | `.claude-plugin/marketplace.json`、`skills/*/SKILL.md` |
| スキル方式 | 階層化スキル + シェルスクリプト補助 | `skills/<name>/SKILL.md` + `skills/<name>/scripts/*.sh` |
| 設定読み込み | TOML ベース 4 層マージ | `.aidlc/config.toml` / `config.local.toml` / `defaults.toml` / user-global |
| バージョン管理（現状） | `version.txt` × 3 + `config.toml.starter_kit_version` の **多重 SoT** | `bin/update-version.sh` ヘッダコメント / `marketplace.json.metadata.version` |
| オーケストレーション | `/aidlc {action}` 単一エントリ + 独立スキルへの委譲 | `skills/aidlc/SKILL.md`「引数ルーティング」 |
| Phase 駆動 | Inception → Construction → Operations の 3 Phase + 共通 step | `steps/{phase}/index.md` / `phase-recovery-spec.md` |
| 委譲パターン | `setup` / `migrate` / `feedback` は独立スキルへ委譲（透過引数） | SKILL.md「独立フロー委譲」セクション |
| 振り返り（現状） | Operations Phase §1 内に統合 | `steps/operations/04-completion.md` §1 |
| ガード方式 | dialog token + 文書ガード + 実行時ガードの三段防御 | `04-completion.md` 抜粋（`retrospective_dialog_token_verify`） |

### #617 の現状アーキテクチャ抜粋

`bin/update-version.sh` ヘッダコメントに明記:

> 注: .aidlc/config.toml.starter_kit_version は v2.4.0 以降は更新対象外。
> 存在チェックと妥当性検証（read_starter_kit_version）のみ実施。

`marketplace.json` は更新対象に含まれていない。よって以下が SoT 候補となる:

- ルート `version.txt`（現値: `2.5.6`）
- `skills/aidlc/version.txt`（現値: `2.5.6`）
- `skills/aidlc-setup/version.txt`（不在 / または現値）
- `.aidlc/config.toml.starter_kit_version`（現値: `2.5.5` → 古い値で残置）
- `.claude-plugin/marketplace.json.metadata.version`（現値: `2.0.4` → 古い値で残置）

→ **5 経路のうち 2 経路が更新対象から漏れている**ことが Issue #617 の本質。SoT 一本化により全経路を `marketplace.json` に集約する。

### #667 の現状アーキテクチャ抜粋

`steps/operations/04-completion.md` §1 に振り返りロジックが集約済み:

- `retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify`（実行時ガード）
- `retrospective_issue_create` / `retrospective_prefill_hook` / `retrospective_update_hook`
- `lib/retrospective-issue.sh` / `lib/feedback-mode.sh` / `lib/predecessor-issue.sh`
- `templates/retrospective_template.md`
- 振り返り Issue 起票 + spool fallback + mirror 送信 + 重複統合

これらを `skills/aidlc-retrospective/` に移転する。`aidlc-feedback` 構造（独立スキル + scripts + SKILL.md + version.txt）が手本となる。

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 主言語 | Markdown（プロンプト/手順）+ Bash | `.aidlc/config.toml` の `[project.tech_stack]`、各 SKILL.md・scripts/*.sh |
| 設定パーサ | `dasel`（v3.x 推奨）+ `sed/grep` フォールバック | `scripts/env-info.sh`、`scripts/lib/version.sh` |
| Lint | `markdownlint-cli2` | `.aidlc/config.toml [rules.linting]`、`skills/aidlc-setup/scripts/check-markdownlint.sh` |
| AI レビュー | `codex` CLI（preferred） | `[rules.reviewing] tools = ["codex"]` |
| GitHub 連携 | `gh` CLI（issues / pr / api / project） | `scripts/check-open-issues.sh`、`milestone-ops.sh`、各 issue / pr 操作 |
| バージョン同期 | `bin/update-version.sh`（自前） | 同ファイル |
| Plugin Marketplace | `.claude-plugin/marketplace.json`（Claude Code plugin spec） | 同ファイル |

## 依存関係

- **`bin/update-version.sh`** → `skills/aidlc/scripts/lib/version.sh` の `read_starter_kit_version()` を `source` 経由で呼び出し（パス: `_LIB_DIR="${_SCRIPT_DIR}/../skills/aidlc/scripts/lib"`）
- **`scripts/env-info.sh`** → `lib/version.sh` の `read_starter_kit_version()` を呼び出してプリフライト出力に組み込み
- **`SKILL.md` (`/aidlc version`)** → `skills/aidlc/version.txt`（**SoT 移行で参照先変更必要**）
- **`steps/inception/01-setup.md` ステップ5a** → リモート `version.txt` (curl) + `skills/aidlc/version.txt` + `read-config.sh starter_kit_version` の 3 点取得（**SoT 移行で参照先変更必要**）
- **`migrate-backlog.sh` line 79** → `cut -c1-50` で title → slug 変換（**#615 修正対象**）
- **`steps/operations/04-completion.md` §1** → `lib/retrospective-issue.sh` / `lib/feedback-mode.sh` / `lib/predecessor-issue.sh` / `templates/retrospective_template.md`（**#667 移転対象一式**）
- **エントリポイント**: `/aidlc {action}` → `skills/aidlc/SKILL.md` parser → 独立スキル委譲（`/aidlc-setup` / `/aidlc-migrate` / `/aidlc-feedback`）。**#667 で `/aidlc-retrospective` 委譲を追加**
- **循環依存**: 検出なし（独立スキルへの委譲は単方向）

## 特記事項

- **`marketplace.json` の現バージョンが 2.0.4 で大幅に乖離**: バックフィルとして本サイクル冒頭で 2.6.0 へ更新する必要がある（#617 期待結果 4）
- **`config.toml` の `starter_kit_version` が 2.5.5 で 1 段階遅れている**: `aidlc-setup/aidlc-migrate` 経由でのみ更新される設計のため、Operations 完了時の更新フローに依存する
- **マージ前完結契約（DR-001）**: `cycles/{{CYCLE}}/**` への変更は PR マージ前に完結させる必要がある。`/aidlc-retrospective` の独立化に際しても本契約を維持すること（独立スキル化後も `cycles/.../**` への副作用が発生する場合は同等のガードが必要）
- **`steps/operations/04-completion.md` §1 は規模が大きい**（dialog token / wizard / cap / spool / mirror_state）。移転時は責務単位で Unit 分割を検討する
- **Plugin Marketplace 仕様の再確認**: SoT を `marketplace.json` に移す際、Plugin Marketplace の規約上「どのフィールドが正式バージョン参照か」を v2.6.0 Construction Phase で再確認すること
- **`predecessor_resolve_issue` のサイクル特定**: `/aidlc-retrospective` 独立後は「対象サイクル」の自動検出ロジックが新規必要（現状は Operations Phase 内なので暗黙的に当該サイクル）
- **観測誤り検証**: 本分析では実装ファイル本体を全行読まず、`grep` / `head` ベースで検出した。Construction Phase の各 Unit 設計時に、対象ファイルの全文を読んで再確認すること（特に #617 の `update-version.sh` 全行と `marketplace.json` フィールド定義、#667 の `04-completion.md` §1 全行）
