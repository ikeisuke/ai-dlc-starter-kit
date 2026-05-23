# レビューサマリ: Unit 001 — T 中心アウトプット仕様 + `aggregate_issue_enabled` フラグ + cap 仕様 SoT 定義

## 基本情報

- **サイクル**: v2.6.6
- **フェーズ**: Construction
- **対象**: Unit 001（T 中心アウトプット仕様 + `aggregate_issue_enabled` フラグ + cap 仕様 SoT 定義）

---

## Set 1: 2026-05-18 設計レビュー（Phase 1 完了時）

- **レビュー種別**: 設計レビュー（reviewing-construction-design / focus=architecture）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘0件（last_round_clean=true → completed）
- **codex session id**: 019e3910-7e65-7a73-8636-d06790742a0d

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_001_aggregate_flag_and_spec_sot_logical_design.md` - 「事前コード読込み」が (a)(b)(c) 明示構造になっておらず、設計単体での監査性が低い | 修正済み（論理設計に (a) Read 対象 + 目的 / (b) 設計時に意識すべき挙動 / (c) 既存実装に基づく代替案検討 の 3 観点を独立再掲） | - |
| 2 | 中 | `.aidlc/cycles/v2.6.6/design-artifacts/domain-models/unit_001_aggregate_flag_and_spec_sot_domain_model.md`, `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_001_aggregate_flag_and_spec_sot_logical_design.md` - fail-safe 契約 `read-config.sh` exit 1 時の warn 出力有無がドメインモデルと論理設計内部フローで不一致 | 修正済み（ドメインモデル §概念 3 と論理設計のスクリプトインターフェース節 / 内部処理を計画書 §必須対応 4 と完全一致化。exit 1 = warn なし / exit 0 不正値・exit 2+ = warn あり） | - |
| 3 | 低 | `.aidlc/cycles/v2.6.6/design-artifacts/domain-models/unit_001_aggregate_flag_and_spec_sot_domain_model.md`, `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_001_aggregate_flag_and_spec_sot_logical_design.md` - result-out 関数 local 命名規約への具体的な言及が設計成果物内で抜け | 修正済み（両ファイルに「実装制約」節を追加。Bash ツール経由コマンド置換禁止 + result-out 関数 local 命名規約 + codex stdin 待ちガードを SoT 参照付きで明記） | - |
| 4 | 中 | `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_001_aggregate_flag_and_spec_sot_logical_design.md` - Round 2: 「テスト責務」記述で fail-safe 3 ケースすべてに stderr warn と記載され、契約表（exit 1 は warn なし）と矛盾 | 修正済み（コンポーネント詳細 7 のテスト責務記述を契約表に統一。exit 1 = warn なし / exit 0 不正値 + exit 2+ = warn あり に区別） | - |

### 反復経過

| Round | 指摘件数（高/中/低） | 状態 |
|-------|---------------------|------|
| 1 | 3件（0/2/1） | 反復継続（中 2 件 / 低 1 件 → 全件修正） |
| 2 | 1件（0/1/0） | 反復継続（中 1 件 → 修正） |
| 3 | 0件 | clean → completed |

---

## Set 2: 2026-05-18 統合レビュー（Phase 2 完了時 / コードレビュー + 統合レビュー兼用）

- **レビュー種別**: 統合レビュー（reviewing-construction-integration / focus=code+architecture）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘0件（last_round_clean=true → completed）
- **codex session id**: 019e3919-526f-7eb2-a37f-2a5ba06ff7c1

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `skills/aidlc/scripts/lib/retrospective-api.sh` - helper 内 `set +e/-e` が caller の errexit 状態を上書きする副作用リスク | 修正済み（helper を `if value=$(...); then rc=0; else rc=$?; fi` 形式に変更。bats 22 件継続 pass） | - |
| 2 | 中 | `.aidlc/cycles/v2.6.6/plans/unit-001-plan.md`, `.aidlc/cycles/v2.6.6/story-artifacts/units/001-aggregate-flag-and-spec-sot.md`, `.aidlc/cycles/v2.6.6/design-artifacts/domain-models/unit_001_aggregate_flag_and_spec_sot_domain_model.md`, `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_001_aggregate_flag_and_spec_sot_logical_design.md`, `tests/fixtures/retrospective_v265_aggregate.json`, `tests/retrospective-aggregate-enabled.bats` - SC-04 の SoT が設計文書群（v2.6.5 実データ必須 / 取得不可なら blocked）と実装（schema-only / HLP4 skip）で不整合 | 修正済み（SC-04 を「Unit 001 段階基準 = schema-only / Unit 004 finalize 基準 = 差分 0 同等性 bats」の二段階基準として 4 ドキュメント（plan / unit 定義 / domain / logical）で統一。v2.6.5 集約 Issue 実起票不在の事実を根拠に「v2.6.5 リリース時点コード生成 output と等価」へ Intent SC-04 を解釈置換） | - |
| 3 | 低 | `.aidlc/cycles/v2.6.6/story-artifacts/units/001-aggregate-flag-and-spec-sot.md` - Unit 定義「責務」と「境界」で SC-04 責務記述が混在 | 修正済み（責務側を二段階基準に合わせて Unit 001 段階責務 = fixture スキーマ + 正規化 SoT + helper + 構造検証 bats と明示し、差分 0 同等性 bats は Unit 004 finalize 責務と分離） | - |
| 4 | 低 | `.aidlc/cycles/v2.6.6/design-artifacts/domain-models/unit_001_aggregate_flag_and_spec_sot_domain_model.md` - 「不明点と質問」末尾に旧方針（取得不可なら blocked）が残存 | 修正済み（Q&A を二段階基準で更新。v2.6.5 集約 Issue 起票実績不在の事実 + schema-only / finalize 二段階運用へ統一） | - |

### 反復経過

| Round | 指摘件数（高/中/低） | 状態 |
|-------|---------------------|------|
| 1 | 2件（0/2/0） | 反復継続（中 2 件 → 修正） |
| 2 | 2件（0/0/2） | 反復継続（低 2 件 → 修正） |
| 3 | 0件 | clean → completed |
