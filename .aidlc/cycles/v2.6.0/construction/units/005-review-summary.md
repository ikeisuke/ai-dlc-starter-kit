# レビューサマリ: Unit 005 - /aidlc-retrospective 独立スキル化

## 基本情報

- **サイクル**: v2.6.0
- **フェーズ**: Construction
- **対象**: Unit 005 (aidlc-retrospective-skill-extraction)

---

## Set 1: 2026-05-10 設計レビュー

- **レビュー種別**: 設計レビュー（Phase 1 / focus=architecture）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘0件（Round 2 で last_round_clean）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_005_aidlc_retrospective_skill_extraction_logical_design.md`（write-history.sh 評価ロジック疑似コード） - `--operations-stage` / `AIDLC_OPERATIONS_STAGE` を許可値ならそのまま採用しており、設計目的（呼出元入力値→実行コンテキスト導出）と矛盾。Guard 迂回可能 | 修正済み（unit_005_..._logical_design.md L「評価ロジック」: ヒント値はステップ 2 で導出値と cross-check し、不一致時 exit 3 を契約に固定。ステップ 1（実行コンテキスト導出）→ ステップ 2（ヒント値検証）の順序に書き直し、契約サマリを追記） | - |
| 2 | 中 | `.aidlc/cycles/v2.6.0/design-artifacts/domain-models/unit_005_aidlc_retrospective_skill_extraction_domain_model.md`（依存方向定義）, `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_005_aidlc_retrospective_skill_extraction_logical_design.md`（SKILL.md 依存記述） - Facade 単方向に対し RetrospectiveSkill が cycle-resolver.sh を直接依存しており境界が曖昧 | 修正済み（unit_005_..._domain_model.md L「ドメインモデル図」末尾: 層定義表 L1〜L4 + 依存規則 + Facade 境界補足を追加。L3 公開コンポーネント層に RetrospectiveAPI / CycleResolver / WriteHistoryGuard を並列配置。unit_005_..._logical_design.md SKILL.md 依存記述に層定義参照を追記） | - |
| 3 | 中 | `.aidlc/cycles/v2.6.0/design-artifacts/domain-models/unit_005_aidlc_retrospective_skill_extraction_domain_model.md`（RetrospectiveAPI 不変条件）, `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_005_aidlc_retrospective_skill_extraction_logical_design.md`（公開関数戻り値仕様） - 「stdout は key=value 形式に統一」と複数関数の生文字列返却が不一致 | 修正済み（unit_005_..._domain_model.md L「RetrospectiveAPI 不変条件」: 出力タイプ A（key=value 複数行）/ B（raw text 1 行）に分類。unit_005_..._logical_design.md L「retrospective-api.sh 出力形式の規約」: タイプ別表 + 各関数仕様に「出力タイプ」項目を明示） | - |
| 4 | 低 | `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_005_aidlc_retrospective_skill_extraction_logical_design.md`（cycle-resolver.sh S3a 記述） - S3a が `gh pr list` と `git log` で揺れて Strategy 責務境界が一貫していない | 修正済み（unit_005_..._logical_design.md L「Strategy 一覧 / S3a 正規仕様」: 第一データソース `git log`（オフライン可）→ 第二データソース `gh pr list`（fallback）の正規仕様に固定。NFR 対応関係表を追加） | - |

合計: 4 件（高: 1 / 中: 2 / 低: 1）→ 全件修正、Round 2 で指摘 0 件で完了

---

## Set 2: 2026-05-10 コードレビュー

- **レビュー種別**: コード生成後（Phase 2 / focus=code,security）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘 0 件（Round 3 で last_round_clean）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `skills/aidlc-retrospective/steps/retrospective.md`, `CHANGELOG.md` - feedback_mode 仕様の齟齬（手順/CHANGELOG が旧 3 値前提、実装は 5 値正規系） | 修正済み（retrospective.md L44-49: 表を 5 値正規系（`interactive` / `local-issue-only` / `mirror-only` / `local-and-mirror` / `disabled`）に更新 + 旧値互換テーブル併記。完了サマリ L281: 5 値表記に修正。CHANGELOG.md L16: 互換維持の記述を 5 値正規系 + 旧値互換入力に書き直し） | - |
| 2 | 中 | `skills/aidlc-retrospective/steps/retrospective.md`, `skills/aidlc/scripts/lib/retrospective-api.sh` - Facade 境界違反（`feedback_mode_requires_wizard` 内部関数を直接呼出） | 修正済み（retrospective-api.sh: `retrospective_api_requires_wizard` を Facade 公開関数として追加 + ヘッダ規約コメント更新。retrospective.md L52 周辺: 直接呼出を `retrospective_api_requires_wizard` 経由のコード例に置換） | - |
| 3 | 中 | `skills/aidlc-retrospective/steps/retrospective.md` - sed `s/{{CYCLE}}/{{CYCLE}}/g` が実質 no-op（AI 実行時 `{{CYCLE}}` 置換モデルとの衝突） | 修正済み（retrospective.md: bash コード内の全 `"{{CYCLE}}"` を `"$cycle"` 変数参照に統一（L175 / L190 / L199 / L201 / L210 / L219 / L257 相当）。L29 の説明文を `$cycle` 変数参照前提に明示。sed は `"s\|{{CYCLE}}\|${cycle//\|/\\\|}\|g"` で値展開 + delimiter 衝突回避） | - |
| 4 | 中 | `skills/aidlc/scripts/lib/cycle-resolver.sh` - rc=2 fatal 契約が `\|\| true` 吸収で実質到達不能 | 修正済み（cycle-resolver.sh: 各 Strategy で `command -v` ガード + 終了コード捕捉 + `\|\| true` 除去。S3b の `\|\| pwd` silent fallback 削除（git toplevel 解決失敗時は候補なし扱い）。`cycle_resolver_resolve` 本体で各 Strategy の rc=2 を即時伝播する分岐追加。Round 3 でヘッダコメントを「Strategy は 0/1 のみ、rc=2 は将来拡張用予約 path」と実装整合化） | - |
| 5 | 低 | `skills/aidlc/scripts/write-history.sh` - `--unit-slug` の `^[a-z0-9][a-z0-9-]{0,63}$` パターン検証が欠落 | 修正済み（`skills/aidlc/scripts/lib/validate.sh`: `validate_unit_slug` 関数を新設。`skills/aidlc/scripts/write-history.sh` L630-: `--unit-slug` 受け取り時に `validate_unit_slug` を呼び、不一致なら `invalid-unit-slug` で exit 1） | - |
| 6 | 中 | `skills/aidlc-retrospective/steps/retrospective.md` - Step 2 prefill で `kpt_md_path` 未定義参照（定義は Step 3） | 修正済み（retrospective.md L168-204: Step 2 冒頭に「KPT テンプレ展開」を追加し、`kpt_md_path` 初期化 + sed テンプレ展開を prefill 呼出より前に移動。Step 3 は `kpt_md_path` 再利用のコメント化。セクションタイトルも「KPT テンプレ展開 + cap 判定 + prefill フック」に更新） | - |
| 7 | 中 | `skills/aidlc/scripts/lib/cycle-resolver.sh` - Strategy 契約コメント「0/1/2」と実装の乖離（実装は 0/1 のみ） | 修正済み（cycle-resolver.sh L17-28, L176-178: Strategy return code 規約を「0=候補確定 / 1=候補なし（想定内エラーを集約）」の 2 値に修正。rc=2 は「将来の内部 cross-check 不整合用に予約。現行実装では未到達」と明示。`resolve()` 側の rc=2 propagation 分岐は将来拡張ポイントとして残置を明文化） | - |

合計: 7 件（高: 1 / 中: 5 / 低: 1）→ 全件修正、Round 3 で指摘 0 件で完了

- **codex セッション ID**: 019e0e6f-9369-75e0-a1ee-05cf2e8bd18b

---

## Set 3: 2026-05-10 統合とレビュー

- **レビュー種別**: 統合とレビュー（Phase 2 最終 / focus=integration）
- **使用ツール**: codex（同一セッション継続）
- **反復回数**: 1
- **結論**: 指摘 0 件（1R clean 特例）
- **検証範囲**:
  - `bats tests/`: 全 303 件 pass（回帰なし）
  - `bin/tests/operations-712-squash` / `bin/tests/aidlc-paths`: 全 pass
  - `bin/tests/test_check_marketplace_version.sh`: 26 件 pass
  - `bin/tests/test_update_version_no_toml_write.sh`: 14 件 pass
  - `bin/check-bash-substitution.sh`: no violations, 34 files checked
  - 工程 D 検証コマンド全 4 件 pass（Operations 残存ロジックなし / parser 拡張 / 新スキル存在 / Inception 不変）
- **追加テスト** (Unit 005 で新規 / 書き換え):
  - `tests/cycle-resolver.bats` (10 件): S1〜S3b Strategy / 優先順位 / fail-safe / S3b pwd fallback 削除確認
  - `tests/retrospective-api-facade.bats` (10 件): 公開関数の存在 / 5 値正規系 / 旧値互換 / requires_wizard Facade 経由 / 多重 source ガード
  - `tests/validate-unit-slug.bats` (9 件): kebab-case 許可 / 拒否ケース / write-history.sh 統合
  - `tests/operations-04-completion-section1-5.bats` (9 件、書き換え): Unit 005 移転後の構造 verify
- **codex セッション ID**: 019e0e6f-9369-75e0-a1ee-05cf2e8bd18b（Set 2 と同一セッション）

### 指摘一覧

指摘 0 件
