# 既存コードベース分析

> 対象は本サイクル（Phase 6: reflect + doctor + status 拡充 / #735）に関連する v3 サブシステムに絞った focused 分析。全リポジトリ網羅ではない。

## ディレクトリ構造・ファイル構成

```text
skills/aidlc-v3/
├── SKILL.md                  # ルーティング骨組み（reflect/doctor は「予約」）
├── steps/
│   ├── define.md             # 実装済（Phase 3 / Unit 001）
│   ├── develop.md            # 実装済（tiny / normal / risky）
│   ├── release.md            # 実装済（Phase 5 / Step 1–4）
│   ├── status.md             # 出力仕様（71行 / 実行実装は本サイクルで拡充対象）
│   ├── reflect.md            # ★未存在（本サイクルで新規作成）
│   └── doctor.md             # ★未存在（本サイクルで新規作成）
├── scripts/
│   ├── state-init.sh / state-read.sh / state-write.sh / state-validate.sh
│   ├── work-item-next.sh / work-item-status.sh / work-item-validate.sh
│   ├── doctor.sh             # ★未存在（本サイクルで新規作成）
│   ├── lib/
│   │   └── frontmatter.sh    # 共有 parser 安全境界（149行 / #733 T1 / alpha.4）
│   └── tests/                # test-*.sh（8ファイル / 契約・回帰テスト）
└── templates/
    ├── release.md / work-item.md ...
    └── reflect.md            # ★未存在（本サイクルで新規作成）

skills/aidlc/scripts/
├── squash-unit.sh            # #735 修正対象（複数 --message footgun）
└── tests/                    # 回帰テスト追加先（#735）

bin/
└── check-frontmatter-parse-guard.sh  # 禁止パースパターン機械検出（#733 T4 / CI 連携）

docs/v3/
├── workflow.md (326行)       # §3.4 reflect / §3.5 status / §3.6 doctor の SoT
└── data-model.md             # §5 フェーズ導出（SoT）/ §7 journal / §10 成果物
docs/v3-renewal-plan.md       # Phase 6 実装計画の SoT
```

## アーキテクチャ・パターン

| パターン | 内容 | 根拠 |
|---------|------|------|
| 状態の明示化（RFC DG-6） | フェーズは会話履歴推論でなく `state.json` + work item frontmatter から**導出**。`current_phase` は保持しない | `steps/status.md` L14-22 / `docs/v3/data-model.md §5` |
| 安全境界の集約（fail-closed） | frontmatter 構造解釈を `lib/frontmatter.sh` に一元化。個別 consumer での grep/sed/awk/permissive jq を**禁止規約**として明文化 | `lib/frontmatter.sh` L24-31 |
| JSON は jq を SoT | state.json の schema 検証は `state-validate.sh` に集約（#731）。スクリプト間の重複パースなし | `lib/frontmatter.sh` ヘッダ注記 / `state-validate.sh` |
| 読み取り専用補助コマンド | `status`（読み取り専用）/ `doctor`（診断のみ・自動修正なし）はフェーズ進行ゲートを持たない | `docs/v3/workflow.md` L33 |
| 既存スクリプト再利用前提の doctor | doctor は新規ロジックを最小化し `state-validate.sh` / `work-item-validate.sh` / native git・gh を wrap する設計 | `docs/v3/workflow.md §3.6` チェック項目表 |
| result-out 不使用（dynamic scope 回避） | `lib/frontmatter.sh` 全関数は stdout 返却 + return code（printf -v 不使用） | `lib/frontmatter.sh` 設計・契約注記 |

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash（POSIX 寄り shell script）+ Markdown（手順・仕様） | `skills/aidlc-v3/scripts/*.sh` / `steps/*.md` |
| 主要ツール | `jq`（JSON）/ `dasel`（TOML config）/ `gh`（GitHub）/ `git` | `state-*.sh` / `scripts/read-config.sh` / CI workflows |
| テスト | 自作 bash テストハーネス（assertion ベース） | `skills/aidlc-v3/scripts/tests/test-*.sh` |
| CI | GitHub Actions（`pr-check.yml` / `skill-reference-check.yml` 等） | `.github/workflows/` |
| 配布 | Claude Code プラグイン（marketplace.json 登録） | `.claude-plugin/marketplace.json` |

## 依存関係

- **reflect（新規）→ 依存**: `journal.md`（追記 / data-model §7）/ `release.md`（前段成果物）/ work item frontmatter（withdrawn・blocked 理由）/ `gh issue create`（Try の Issue 化）/ `templates/reflect.md`（新規）。retrospective エイリアス整合（SKILL.md）。
- **doctor（新規）→ 依存**: `read-config.sh`（config）/ `state-validate.sh`（state schema）/ `work-item-validate.sh`（work-items）/ native `git`・`gh`（git/gh/pr）/ `bin/check-frontmatter-parse-guard.sh` 相当（parse-guard）/ 必須スクリプト存在確認。**`[phase]` 導出・`[trace]` は本サイクル非依存（defer）**。
- **status 拡充 → 依存**: `state-read.sh` / work item frontmatter / フェーズ導出（data-model §5）。出力フォーマットは workflow.md §3.5。
- **#735（squash-unit.sh）→ 依存**: 独立（v2 ツール / `skills/aidlc/scripts/`）。v3 サブシステムへの依存なし。`parse_args` の `--message` ハンドラ（後勝ち上書き）と Co-Authored-By トレーラ付与経路が修正対象。
- **循環依存**: なし。補助コマンド（status/doctor）はフェーズコマンドに依存せず、state/frontmatter の読み取りのみ。

## 特記事項

- **#733 は実装不要**: Try T1/T2'/T4/T6 はすべて alpha.4 で実装・CI ガード済み（`lib/frontmatter.sh` / conformance test 28 assertion / `bin/check-frontmatter-parse-guard.sh` + CI / `state-read.sh` の CycleResolver 明示優先 + 回帰テスト）。本サイクルではクローズのみ。
- **doctor の「やり過ぎ」回避**: workflow.md §3.6 は 10 チェック項目を列挙するが、実装負荷の大半は `[phase]`（導出 code 化 ~100行）と `[trace]`（intent_refs 整合 ~200行）に集中。両者は機能確定待ちのため alpha.8 へ defer し、残り 8 項目（config/state/cycle/work-items/git/gh/pr/scripts）+ parse-guard を既存再利用で shallow 実装する（~200-300行）。
- **status の現状**: `steps/status.md` は出力**仕様**であり「出力生成の実行実装は Phase 3 以降 / 本 skeleton は参照に留める」と注記。本サイクルの「status 拡充」は出力例（Remaining / Suggested command / 導出根拠）への整合を主眼とする。
- **メタ開発の二重参照**: 編集対象はプロジェクトルート相対 `skills/aidlc-v3/**`（META-001）。スキル実行時はスキルベース相対参照。#735 の `squash-unit.sh` は v2（`skills/aidlc/`）側の変更で、v3 リニューアル本流とは独立。
