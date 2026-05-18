# レビューサマリ: Unit 002 — §1.2.5 セルフレビュー観点新ステップ + 3 問固定判別ガイド

## 基本情報

- **サイクル**: v2.6.6
- **フェーズ**: Construction
- **対象**: Unit 002（§1.2.5 セルフレビュー観点新ステップ + 3 問固定判別ガイド / aidlc-retrospective skill）

---

## Set 1: 2026-05-18 設計レビュー（Phase 1 完了時）

- **レビュー種別**: 設計レビュー（reviewing-construction-design / focus=architecture）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘0件（last_round_clean=true → completed）
- **codex session id**: 019e3b7e-99db-70e0-b5e3-1b10a1b2c5e6

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_002_selfreview_and_classification_guide_logical_design.md` - §1.2.5 セルフレビュー実行フローのステップ 7 で `retrospective_api_ensure_label` を呼び出す設計が計画書「責務分割」表（§1.5 起票直前での helper 呼び出しは Unit 004 責務）と不整合 | 修正済み（論理設計のステップ 7 から `ensure_label` 呼び出しを削除し、capped 時は `selfreview_capped=true` 記録のみとした。事前コード読込み (b)(c) にも責務境界違反として却下する「案 F」を追加し計画書との整合を明文化） | - |
| 2 | 中 | `.aidlc/cycles/v2.6.6/design-artifacts/domain-models/unit_002_selfreview_and_classification_guide_domain_model.md` - `SelfReviewSessionAggregate` 不変条件で `capped ⟺ responses.size==4` と `undecidable ⟺ いずれか is_undecidable=true` が 4 回目で undecidable 発生時に同時成立不能 | 修正済み（ドメインモデルの不変条件を優先順位付きに改訂: undecidable 最優先 → pass → capped → rebuttal。論理設計の判定論理疑似コードの順序と完全一致） | - |
| 3 | 中 | `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_002_selfreview_and_classification_guide_logical_design.md` - 「事前コード読込み」セクションの見出しが簡略化され (a)(b)(c) も「要点のみ再掲」で記述粒度が depth_level=standard 要件を満たさない | 修正済み（論理設計 §「事前コード読込み（ステップ 0 / v2.6.5 / #679 / Unit 002）」を完全な h2 見出しと (a) Read 対象 + 目的 / (b) 設計時に意識すべき挙動 / (c) 既存実装に基づく代替案検討 の具体記述に書き直した。ドメインモデル参照だけにせず重複ありで完全展開） | - |

### 反復経過

| Round | 指摘件数（高/中/低） | 状態 |
|-------|---------------------|------|
| 1 | 3件（1/2/0） | 反復継続（高 1 件 / 中 2 件 → 全件修正） |
| 2 | 0件 | clean → completed |

---

## Set 2: 2026-05-18 コードレビュー（Phase 2 / コード生成完了時）

- **レビュー種別**: コードレビュー（reviewing-construction-code / focus=code+security）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘0件（last_round_clean=true → completed）
- **codex session id**: 019e3b83-ab86-7083-9ab8-595cdf375de8

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `skills/aidlc/scripts/lib/retrospective-api.sh` - `retrospective_api_record_selfreview` の一時ファイルが `${TMPDIR}/aidlc-retro-selfreview-record.$$` で予測可能、`>` リダイレクトでシンボリックリンク悪用 (TOCTOU) リスク | 修正済み（`mktemp ...XXXXXX` + `umask 077` で予測不能化、mktemp 失敗時 return 2） | - |
| 2 | 中 | `skills/aidlc/scripts/lib/retrospective-api.sh` - `retrospective_api_record_selfreview` 引数 `verdict` / `selfreview_capped` のホワイトリスト検証不在で契約外値が `history/operations.md` に到達可能 | 修正済み（`case` でホワイトリスト検証追加、不正値は warn + return 1） | - |
| 3 | 低 | `skills/aidlc-retrospective/templates/try_classification_guide.md` - 質問 3 「再入余地なし」合格条件が「チェック追加逃げを避ける」主旨と緊張関係 | 修正済み（合格条件を「構造的根拠を Try 内で明示」に限定、根拠不明示時は観点 A 該当として差し戻し対象とする旨を補強） | - |
| 4 | 中 | `skills/aidlc/scripts/lib/retrospective-api.sh:401-416` - Round 2 指摘: `verdict` と `selfreview_capped` の組み合わせ検証が未実装（`verdict=pass` + `selfreview_capped=true` 等の不整合通過） | 修正済み（公開契約 §3 の相関検証を追加、`verdict=capped ⟺ selfreview_capped=true` 不変条件を強制） | - |

### 反復経過

| Round | 指摘件数（高/中/低） | 状態 |
|-------|---------------------|------|
| 1 | 3件（1/1/1） | 反復継続（高 1 件 / 中 1 件 / 低 1 件 → 全件修正） |
| 2 | 1件（0/1/0） | 反復継続（中 1 件 → 修正） |
| 3 | 0件 | clean → completed |

---

## Set 3: 2026-05-18 統合レビュー（Phase 2 / 統合とレビュー完了時）

- **レビュー種別**: 統合レビュー（reviewing-construction-integration / focus=code+architecture）
- **使用ツール**: codex
- **反復回数**: 1
- **結論**: 指摘0件（1R clean 特例 → completed）
- **codex session id**: 019e3b8d-e483-7380-aa5c-91b6111883ad

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| - | - | - | 指摘なし（1R clean） | - |

### 反復経過

| Round | 指摘件数（高/中/低） | 状態 |
|-------|---------------------|------|
| 1 | 0件 | 1R clean 特例 → completed |

### 補足

- 設計 (Set 1) / コード (Set 2) / 統合 (Set 3) いずれも codex で 2R/3R/1R clean
- bats 全 452 件 pass / Unit 002 新規 29 件 pass
- markdownlint Unit 002 関連 6 ファイル 0 error
- 計画書「公開契約」§1〜§3 / 「責務分割」表との整合性確認済（Unit 002 内で `ensure_label` を呼ばず / `verdict=capped ⟺ selfreview_capped=true` 強制 / 既存 `retrospective_api_*` シグネチャ不変）
