# 既存コードベース分析

> 本サイクル（Phase 4 = develop normal/risky 分岐）のスコープに合わせ、`skills/aidlc-v3/` の develop サブシステムに焦点を当てた brownfield 解析。全リポジトリの網羅解析ではない（Intent 制約 前提C）。

## ディレクトリ構造・ファイル構成

`skills/aidlc-v3/`（v3 本体 / v3.0.0-alpha.4 時点）:

```text
skills/aidlc-v3/
  SKILL.md                       ルーティング骨組み + コマンド体系（define/develop/release/reflect/status/doctor）
  steps/
    define.md                    Inception 相当（Intent/work item 永続化・cycle/state 初期化）— 実装済
    develop.md                   Construction 相当 — tiny のみ実装、normal/risky は停止（本サイクルの主対象）
    status.md                    読み取り専用のフェーズ導出・現在地表示 — 実装済
  scripts/
    state-init.sh                state.json 初期化
    state-read.sh                state.json の指定フィールド読取（read-only）
    state-validate.sh            state.json schema 検証
    state-write.sh               state.json の atomic 更新（temp+mv）
    work-item-next.sh            依存解決 + resume 優先で次 work item 選定（read-only）
    work-item-status.sh          frontmatter status の読取（--read）/ 遷移（atomic・現在 status 確認付き）
    work-item-validate.sh        work item frontmatter/本文 schema 検証（必須キー・enum・依存実在）
    lib/frontmatter.sh           共有 frontmatter パーサライブラリ（構造解釈のみ。enum 検証は consumer 責務）
    tests/                       bash unit test 群（下記「技術スタック」参照）
  templates/
    intent.md                    Intent テンプレート
    work-item.md                 work item テンプレート（frontmatter + 本文必須セクション）
    journal.md                   追記型ジャーナル（日付見出し + 箇条書き）
```

**コマンド体系の実装状況**:

| コマンド | 状態変更 | 実装状況（alpha.4 時点） |
|---------|---------|------------------------|
| `define` | あり | 実装済（steps/define.md） |
| `develop` | あり | **tiny のみ**実装（steps/develop.md）。normal/risky は停止 |
| `status` | なし（読取専用） | 実装済（steps/status.md） |
| `release` / `reflect` / `doctor` | あり/なし | 予約（未実装 / Phase 5・6） |

## アーキテクチャ・パターン

- **ハイブリッド状態管理（RFC DG-6）**: サイクルレベル状態は `.aidlc/state.json`（JSON / schema validation 対象）、work item 個別状態は各 `work-items/<id>-<slug>.md` の frontmatter（Markdown / 並行編集コンフリクト回避）。根拠: `docs/v3/data-model.md` §3・§4・§9。
- **`current_phase` を保持しない設計**: フェーズは `state.json` + 全 work item frontmatter status から都度導出する。導出規則の正本は `docs/v3/data-model.md` §5（`workflow.md` §7.1 は「参考」と明記され data-model.md §5 がその正本）。根拠: data-model.md §5.1 導出表、develop.md「完了後のフェーズ導出」。
- **パース安全境界の集約（RFC P4 / #733 P1 再発防止）**: frontmatter / status の構造解釈は専用スクリプトに集約。`lib/frontmatter.sh`（構造抽出の共有ライブラリ）が既存。各スクリプトの責務:

  | スクリプト | 読取 | 検証 | 遷移 |
  |-----------|------|------|------|
  | `work-item-status.sh` | ✓（--read） | ✓（status enum/一意性） | ✓（atomic / 現在 status 確認） |
  | `work-item-validate.sh` | ✓ | ✓（必須キー/enum/id 整合/依存実在/セクション） | - |
  | `work-item-next.sh` | ✓ | -（validate 済み前提） | - |
  | `state-read.sh` / `state-validate.sh` / `state-write.sh` | ✓ | ✓ | ✓（atomic） |
  | `lib/frontmatter.sh` | ✓（構造解釈のみ） | -（consumer 責務） | - |

  > #733 T1（共有 parser 集約）は **alpha.4 で完了済み**（alpha.4 Unit 001 で `lib/frontmatter.sh` 新設 + consumer 3 本〔validate/next/status〕移行 + 禁止規約文書化、Unit 002 で T4 CI 機械検出を実装）。`state-*.sh` の JSON/jq は alpha.4 T1 の対象外（state-validate.sh に集約済み / #731）。本サイクルに T1 残作業はない。

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | bash（`-e -u -o pipefail`）、JSON 処理は jq、テキストは grep/awk/sed | `skills/aidlc-v3/scripts/*.sh` |
| フレームワーク | なし（プロンプト + シェルスクリプト構成のスキルプラグイン） | `skills/aidlc-v3/SKILL.md` |
| テスト | bash unit test 群（`skills/aidlc-v3/scripts/tests/`）: `test-define-flow.sh` / `test-develop-flow.sh` / `test-work-item-next.sh` / `test-state-scripts.sh` / `test-frontmatter-parser.sh` / `test-cycle-resolution.sh` / `test-activation.sh`。実行: `bash skills/aidlc-v3/scripts/tests/<file>.sh` | `skills/aidlc-v3/scripts/tests/`（実在確認済み） |

## 依存関係

- **develop.md の参照先**:
  - scripts: `work-item-next.sh` / `work-item-status.sh` / `state-read.sh`（スキルベース相対）
  - docs（SoT）: `docs/v3/data-model.md`（§4 frontmatter schema / §5 フェーズ導出 / §8 size×depth_level）、`docs/v3/workflow.md`（§3.2 develop / §6.1 review 統合 / §6.2 size×review / §6.3 size×depth_level）
- **work item frontmatter スキーマ（正本: data-model.md §4.1）**: `id`（string）/ `status`（enum: pending・in_progress・blocked・done・withdrawn）/ `size`（enum: tiny・normal・risky）/ `risk`（enum: low・medium・high）/ `assigned`（string or null）/ `dependencies`（array of 実在 id）。本文必須セクション: Goal / Scope / Acceptance Criteria / Traceability / Size / Risk / Dependencies / Implementation Notes（§4.2）。
- **size×depth_level マトリクスの SoT**: `docs/v3/data-model.md` §8 が**唯一の正本**（「本表が成果物要否の唯一の正本」と明記）。`workflow.md` §6.3 は内容完全一致のミラー。`depth_level` は `.aidlc/config.toml` 側に保存（enum: minimal/standard/comprehensive、既定 standard）、`size` は work item frontmatter 側。両者の組で参照する。
- **既存 reviewing-construction-* スキル**: 呼び出しは `skill="reviewing-construction-[plan|design|code]", args="[対象] 優先ツール: [tool]"`（review-routing.md §7）。develop 内で plan（開始時）/ design（design 完了時）/ code（実装完了時、risky は security focus）を使用。

## 特記事項

- **Phase 4 の現状の穴（develop.md）**:
  - Step 1（develop.md L73-79 付近）: `size != tiny` の場合「normal / risky フローは未サポートです（Phase 4 で対応予定）」と案内して mutation なしで終了。pending / in_progress いずれの選定経路でも停止。
  - Step 2（L101-103）: 「計画 + 設計（tiny はスキップ）」で本実装が空。
  - Step 5（develop.md にレビュー本実装なし / tiny はスキップ）。
  - `designs/*.md` / `reviews/*.md` の生成ロジックは未実装（cycle dir には `design-artifacts/` 等の v2 系ディレクトリが init-cycle-dir で作られるが、v3 develop からの生成は未配線）。
  - **design テンプレートが存在しない**（`skills/aidlc-v3/templates/design.md` なし）→ 新規作成が必要。
- **SoT 内の文言不整合（Construction で解消対象）**: `workflow.md` §3.2 は「risky: design + risk analysis + test plan」と depth_level 非依存のサマリ表現だが、唯一の正本である `data-model.md` §8（= workflow.md §6.3 ミラー）では `risky+standard` は risk analysis / test plan を含まず `risky+comprehensive` のみ含む。本サイクルは §8 を正本として実装し、§3.2 の文言補正は該当 Unit で行う（Intent [Answer] に記録済み）。
- **exit code 21**: 解析過程で「normal/risky 停止時 exit 21」との情報があったが develop.md 本文には明記がなく未確認（test-develop-flow.sh 側の規約の可能性）。Construction の実装/テスト時に確認する。
- **depth_level 読取の未配線（推定）**: size×depth_level 判定には `.aidlc/config.toml` の `depth_level` 読取が必要だが、v3 scripts に専用読取が現状あるかは未確認。Construction で確認・必要なら追加。
