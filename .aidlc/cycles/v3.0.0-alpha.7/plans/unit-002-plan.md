# Unit 002 実装計画: reflect フロー実装

## 対象

- **Unit**: 002-reflect-flow
- **関連 Issue**: Relates to #736（v3 リニューアル Epic / Phase 6）
- **depth_level**: standard / **automation_mode**: semi_auto / **review_mode**: required

## 背景・目的

v3 に reflect（振り返り）フローを実装し、`/aidlc-v3 reflect` でサイクルの KPT 抽出 → 改善 Issue 化 → `reflect.md` 記録 → `journal.md` 追記までを v3 単独手順で行えるようにする。SoT: `docs/v3/workflow.md §3.4`（Step 1–4）/ `docs/v3/data-model.md §7・§10`。

## 実装方針

既存 v3 ステップ（`skills/aidlc-v3/steps/release.md`）の記法・構成を踏襲した手順ベース実装（重スクリプトなし）。

### 変更1: `skills/aidlc-v3/steps/reflect.md`（新規）

release.md の構成を踏襲し、以下を含む:

- **位置づけ前文**（`>` ブロック）: v3.0.0-alpha.7 / Phase 6、reflect は state を変更しない（read + 成果物生成のみ）、明示の承認ゲートなし（Step 2 人間編集 / Step 3 Issue 化確認）。
- **目的 / フロー全体（Step 一覧表）**。
- **パス解決**: `scripts/` はスキルベース相対、cycle 成果物は `.aidlc/cycles/<cycle>/`、正本は `docs/v3/...`。
- **Step 0: 前提確認**（指摘#1 反映）:
  - `scripts/state-read.sh current_cycle` で `<cycle>` 解決（exit 0/1/2 分岐）。
  - **complete 前提確認**（`data-model.md §5.1`: reflect は complete 状態でのみ実行可）: `state-read.sh` で `release.merge_approved`（true）と `release.pr_number` を確認し、`gh pr view <pr_number>` 等で **PR merged 実態**を確認する。complete でない場合は reflect を実行せず案内して終了。
  - **complete 判定の取得不能時の扱い**: PR merged 確認に必要な `gh` が不可用な場合は **skip-continue ではなく停止または明示的な手動確認分岐**とする（complete 判定は SoT 必須前提。Issue 化の gh 不可用 skip-continue とは区別する）。
- **Step 1: 材料収集**（指摘#2 反映）: `journal.md` / `release.md` / work item の `withdrawn`・`blocked` を読み込む。
  - work item の **status 判定**は `scripts/work-item-status.sh`（frontmatter `status` 専用）経由とし **frontmatter 生パース（grep/sed/awk 直書き）禁止**。
  - **理由（reason）は frontmatter に専用キーを持たない**（`data-model.md §4`）。withdrawn/blocked の理由は work item 本文（Implementation Notes 等）/ `journal.md` / `release.md` から **非構造データとして抽出**し、見つからなければ `unknown` と記録する。data-model に新キーを増やさない。
- **Step 2: KPT 抽出**: AI が Keep/Problem/Try を提案 → 人間が確認・編集（reflect.md テンプレートに記録）。
- **Step 3: 行動化**（指摘#3 反映）: Try を Issue 化するか確認。**承認しない→Issue 作らない / 一部承認→必要分のみ作成**。`gh issue create --body-file`（file-based / 機密マスク）後、stdout の URL から **Issue 番号/URL を確定し reflect.md の「Issue リンク」章に記録**する。
  - **必須ラベル検証は行わない**（reflect Issue の必須ラベルは SoT / Unit 定義に未定義のため、未定義ラベル前提の検証を導入しない）。任意でラベルを付ける場合も検証は URL/番号確定の記録に絞る（SoT にないラベル運用を増やさない）。
- **Step 4: 完了**: `journal.md` に `- reflect completed: <cycle>` 相当を追記（当日日付見出しがなければ追加 / 直接追記）。
- **完了後のフェーズ導出**: reflect は `complete` 状態を変えないため簡素に記述。
- **gh_status 分岐**: `gh` 不可用時は Issue 化を **skip（停止ではない）** し reflect.md 記録は継続。Issue 化できなかった Try は reflect.md に `PENDING_MANUAL` 相当で記録。
- **core から外す（実装しない）明示**: upstream mirror / cap 管理 / dialog token / aggregate retrospective issue / 推定値検出ガード等の重い補助ロジック を「実装しない」と前文または専用注記に明記。

### 変更2: `skills/aidlc-v3/templates/reflect.md`（新規）

- 1 行目 `# Reflect: {{cycle}}`、直後に HTML コメントで生成タイミング・章立ての意味を解説（journal.md/release.md テンプレ記法準拠）。
- 章立て: **Keep / Problem / Try / Issue リンク**（`002-reflect-flow.md:12`）。
- markdownlint 整合（見出し前後空行 / `{{cycle}}` プレースホルダ）。

### 変更3: `skills/aidlc-v3/SKILL.md`（更新）

- description（:9 付近）・位置づけ注記（:20-21 付近）: reflect を「予約」→ 実装済み（`steps/reflect.md` 実在）に。doctor のみ予約のまま。
- コマンド表（:45 付近）: reflect 行を `steps/reflect.md`（実在 / Unit 002 実装）に更新。
- パス解決の `steps/` 列挙（:117 付近）に `reflect.md` 追加。
- retrospective エイリアス（:68 付近）: reflect 実装に伴いルーティング先有効化を整合確認（注記更新）。
- express ラッパ（:72-81 付近）: express は define→develop→release で **reflect を含まない**点を維持（reflect を express チェーンに加えない）。

### 変更4: ドライ検証 `skills/aidlc-v3/scripts/tests/test-reflect-flow.sh`（新規）

`test-release-flow.sh` と同方式（自己完結 / jq 前提 / ネットワーク非依存 / pass-fail カウンタ / 静的構造検証）。検証項目:

1. `bash -n` + shellcheck（テスト自身）
2. 成果物存在（`steps/reflect.md` / `templates/reflect.md` / SKILL.md）
3. reflect.md に Step 0–4 見出しが存在
4. 各 Step の入出力・成果物生成パス（`.aidlc/cycles/<cycle>/reflect.md` + journal 追記）が記述されている
5. **Step 0 complete 前提確認**（`release.merge_approved` / `release.pr_number` / PR merged 実態）が手順に明記
6. **Step 1 材料収集対象**（`journal.md` / `release.md` / work item の withdrawn・blocked）が明記、理由は非構造抽出（unknown フォールバック）
7. **Try Issue 化の 3 分岐**（承認しない→作らない / 一部承認→必要分 / gh 不可→Issue化 skip + reflect.md 継続）が手順に明記（grep ベース契約検証）
8. テンプレート章立て（Keep / Problem / Try / Issue リンク）の構造
9. **reflect が state を変更しない**こと（`state-write.sh` を呼ばない / 手順内に state 変更がない）を契約検証
10. SKILL.md の reflect が `steps/reflect.md` を指し、reflect の「予約」stale 注記が残らないこと
11. SKILL.md の **`retrospective` エイリアス整合**と **express に reflect を含めない**ことを契約検証
12. **journal 追記形式**（当日日付見出し配下に箇条書き追記）が手順に明記
13. core から外す 5 項目が「実装しない」と明記されていること

## 完了条件チェックリスト

Unit 定義「責務」由来:

- [ ] `skills/aidlc-v3/steps/reflect.md` 新規作成（Step 1–4: 材料収集 / KPT 抽出 / 行動化 / 完了）
- [ ] `skills/aidlc-v3/templates/reflect.md` 新規作成（Keep / Problem / Try / Issue リンク章立て）
- [ ] `SKILL.md` の reflect を「予約」→実装済み（`steps/reflect.md`）に更新、retrospective エイリアス・express 整合
- [ ] core から外す項目（upstream mirror / cap 管理 / dialog token / aggregate retrospective issue / 重い補助ロジック）を「実装しない」と明示
- [ ] reflect 手順のドライ検証（Step 1–4 入出力・成果物生成パス確認）。Try Issue 化の承認分岐（承認しない / 一部承認 / gh 不可 skip）もドライ検証
- [ ] frontmatter 生パースは `lib/frontmatter.sh`（または既存読取スクリプト）に委譲（grep/sed/awk 直書き禁止）
- [ ] reflect.md / Issue 本文に機密情報を含めない（マスク方針準用）

## スコープ外（Unit 境界）

- doctor / status / #735（別 Unit）
- core から外す 5 項目の実装（明示的に「実装しない」と記載するのみ）
- express チェーンへの reflect 追加（reflect は任意・post-complete）

## リスク・考慮事項

- SoT（workflow.md §3.4 / data-model.md §10）との文言整合を厳守。
- gh 不可用時は **停止ではなく skip-continue**（reflect の Issue 化は任意成果物。release の gh 停止とは異なる）。
- 既存 v3 ステップ記法（release.md）への準拠でレビュー反復を削減。
- Bash ツール経由のコマンド置換禁止規約（#697）はスクリプト/手順記述で遵守。
