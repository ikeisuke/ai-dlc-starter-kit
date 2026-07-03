# Unit 003 計画: aidlc-v3 skill 骨組み

- **Unit**: 003-v3-skill-skeleton（aidlc-v3 skill 骨組み）
- **サイクル**: v3.0.0-alpha.2（Phase 2: aidlc-v3 skeleton）
- **depth_level**: standard / **automation_mode**: semi_auto / **review_mode**: required
- **依存**: Unit 001（state スクリプト）/ Unit 002（テンプレート）= ともに完了
- **関連 Issue**: なし

## 1. 目的

`skills/aidlc-v3/SKILL.md`（ルーティング）と `steps/define.md` / `steps/status.md`（手順・出力仕様）を作成し、v3 の define 手順と status 出力仕様を**読める形**で固定する。フロー実行実装は含まない（Phase 3 のインプットを明確化する）。

設計正本: `docs/v3/workflow.md` §2（コマンド体系）/ §3.1（define）/ §3.5（status）/ §4（express）、`docs/v3/data-model.md` §5（フェーズ導出）、`docs/v3/rfc.md` DG-1（コマンド名 `develop`）。

## 2. スコープ

### 含むもの

- `skills/aidlc-v3/SKILL.md` — ルーティング（define / develop / release / reflect / status / doctor + 連続実行ラッパ `express` + 旧名エイリアス inception / construction / operations / retrospective + 引数なし実行のフェーズ導出ルーティング + コアルール参照）
- `skills/aidlc-v3/steps/define.md` — define フロー Step 1-4（環境チェック / Intent 定義 / Work Item 分割 / 初期化）を読める手順として記述
- `skills/aidlc-v3/steps/status.md` — status 出力仕様（フェーズ導出は `docs/v3/data-model.md` §5 への参照に留め、導出結果の表示仕様 + 出力例を記述。complete 判定は `release.merge_approved` と PR の merged 実態の両方を参照）

### 含まないもの（後続フェーズへ defer）

- define / status フローの**実行実装**（Phase 3 以降。本 Unit は手順・出力仕様の記述に留める）
- `marketplace.json` への `aidlc-v3` 登録（`/aidlc-v3` 起動有効化）。flow 未実装のため Phase 3 以降へ defer
- `steps/develop.md` / `release.md` / `recovery.md` / `rules.md`（後続 Phase）
- `aidlc-review` 統合スキル / `doctor.sh` 実装（後続 Phase）
- v2（`skills/aidlc`）への一切の変更

## 3. 設計方針（Phase 1 で詳細化）

### 3.1 SKILL.md（`workflow.md` §2 / §4 / RFC DG-1）

- **6 コマンド**: define / develop / release / reflect / status / doctor
- **express**: 単一 work item サイクル専用の連続実行ラッパ（複数 work item / risky は個別実行へ案内）
- **旧名エイリアス**: inception→define / construction→develop / operations→release / retrospective→reflect（後方互換）。**不採用動詞 build / implement はエイリアスにしない**（RFC DG-1）
- **引数なし実行**: state.json + work item frontmatter からフェーズ導出（正本は data-model §5。SKILL.md は導出結果を参照、規則を再定義しない）
- **コアルール参照**: 共通ルールへの参照（v3 の rules は後続 Phase だが参照ポイントを置く）

### 3.2 steps/define.md（`workflow.md` §3.1）

- define フロー Step 1-4 を読める手順として記述:
  1. 環境チェック（config.toml 存在 / git clean / 前 cycle journal・reflect 読込）
  2. Intent 定義（目的 1 文 → 承認 / scope in・out / acceptance criteria → intent.md）★ Intent 承認
  3. Work Item 分割（intent を work item に分割 → 承認 / size・risk 付与 / 依存整理 → work-items/*.md）★ Work Item 承認
  4. 初期化（state.json 初期化 / cycle ディレクトリ / journal.md 追記 / branch + commit）
- テンプレート参照: `templates/intent.md` / `templates/work-item.md` / `templates/journal.md`（Unit 002 実体）
- スクリプト参照: `scripts/state-write.sh`（state.json 初期化は Phase 3 実装、本 Unit は手順で参照）

### 3.3 steps/status.md（`workflow.md` §3.5 / `data-model.md` §5）

- **フェーズ導出ロジックは `docs/v3/data-model.md` §5 への参照 + 導出結果の表示仕様**として記述する（導出規則そのものを再定義しない）。first-match / complete 最優先を記す場合は「非規範サマリ（正本は data-model §5）」と明記する
- 出力例（現在地・次アクション）
- complete 判定は `release.merge_approved`（state.json）と PR の merged 実態の**両方**を参照する旨を含める
- スクリプト参照: `scripts/state-read.sh`（state.json 読取は Phase 3 実装、本 Unit は手順で参照）

### 3.4 共通方針

- 参照パス（`templates/` / `scripts/`）は Unit 001/002 の実体（`state-read.sh` / `state-write.sh` / `state-validate.sh` / `intent.md` / `work-item.md` / `journal.md`）と一致させる。**`scripts/` / `templates/` は `skills/aidlc-v3/SKILL.md` と同じスキルベースディレクトリからの相対パス**として記述する（step ファイル相対で `steps/templates/...` のように解釈されないよう明示）
- コマンド名は `develop`（RFC DG-1。`build` / `implement` は不採用・エイリアスにもしない）
- フェーズ導出の正本は data-model §5。SKILL.md / status.md は導出結果を参照（再定義しない）
- `skills/**` で `skills/aidlc/` プロジェクトルート相対参照を含めない（CI 構造チェック）
- markdownlint 通過

## 4. 完了条件チェックリスト

- [ ] `skills/aidlc-v3/SKILL.md` に define/develop/release/reflect/status/doctor + express + 旧名エイリアス（inception/construction/operations/retrospective）+ 引数なし実行のフェーズ導出ルーティングが記述されている
- [ ] SKILL.md のコマンド名が `develop`（`build`/`implement` をエイリアスに含めない / RFC DG-1）
- [ ] SKILL.md に `express` の適格条件が記述されている（**単一 work item の tiny/normal のみ連続実行し、複数 work item または risky を含む場合は個別実行へ案内する** / workflow.md §4）
- [ ] `steps/define.md` に define フロー Step 1-4 が**読める形**で記述され、★承認ゲート（Intent 承認 / Work Item 承認）が明示されている
- [ ] `steps/define.md` Step 4（初期化）に state.json 初期化時の**必須フィールド**（schema_version / current_cycle / define_completed / release{pr_number/ready/merge_approved} / updated_at）、`define_completed` の書き込みタイミング、`scripts/state-write.sh` / `scripts/state-validate.sh` への参照が明示されている
- [ ] `steps/status.md` に status 出力仕様（出力例）が記述され、フェーズ導出は **data-model §5 への参照 + 導出結果の表示仕様**として記述（規則を再定義せず、first-match 等を書く場合は非規範サマリと明記）、complete 判定が `release.merge_approved` と PR の merged 実態の**両方**を参照する旨を含む
- [ ] define.md / status.md の参照パス（`templates/` / `scripts/`）が Unit 001/002 の実体ファイル名と一致し、スキルベースディレクトリ相対として記述されている
- [ ] フェーズ導出の正本が data-model §5 である旨を参照し、SKILL.md/status.md で規則を再定義していない
- [ ] フロー実行実装・marketplace.json 登録を含まない（スコープ境界）
- [ ] **v2 非影響**: `skills/aidlc/` 配下に変更がない（`git diff` で確認）
- [ ] `skills/**` 配下で `skills/aidlc/` プロジェクトルート相対参照を含まない（CI 構造チェック準拠）
- [ ] markdownlint を通過する

## 5. 想定リスク

- **コマンド名の誤り**（build/implement 混入）→ 設計レビューで RFC DG-1 照合
- **フェーズ導出の二重定義**（SKILL.md/status.md で規則を再定義）→ data-model §5 を正本参照に留める
- **参照パスの不一致**（Unit 001/002 実体とずれ）→ 構造検証で実ファイル名を照合
- **スコープ逸脱**（flow 実行実装の混入）→ 「読める手順・出力仕様」に留める方針を設計で明示

## 6. 進め方

1. Phase 1（設計）: ドメインモデル + 論理設計（SKILL.md ルーティング表 / define Step 構造 / status 出力仕様）→ 設計 AI レビュー → 承認
2. Phase 2（実装）: SKILL.md / define.md / status.md 生成 → コード AI レビュー → 構造検証（参照パス・コマンド名・導出整合）→ 統合 AI レビュー → 承認
3. 完了処理: 完了条件チェック → Unit 状態更新 → 履歴記録 → markdownlint → squash → コミット → Construction Phase 完了（全 Unit 完了）
