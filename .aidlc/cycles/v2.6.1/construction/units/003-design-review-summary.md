# レビューサマリ: Unit 003 設計レビュー

## 基本情報

- **サイクル**: v2.6.1
- **フェーズ**: Construction
- **対象**: Unit 003 aidlc-feedback の `--web` 強制起動解消（opt-in 化）

---

## Set 1: 2026-05-10 21:22:48

- **レビュー種別**: 設計レビュー（reviewing-construction-design）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘0件（unresolved=0 / defer=0、auto_approved）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `unit_003_aidlc_feedback_web_opt_in_domain_model.md`, `unit_003_aidlc_feedback_web_opt_in_logical_design.md` - 警告ログ条件が SoT 真理値表と不整合（`setting=true ∧ is_tty=false` のみで `explicit_web=true ∧ is_tty=false` が抜けていた） | 修正済み（domain-model.md L68-83 / logical-design.md L98-101 / L376: WarningEmitter 発火条件を `is_tty=false ∧ (setting=true ∨ explicit_web=true)` に統一、真理値表の警告ログ列・メッセージ統一） | - |
| 2 | 中 | `unit_003_aidlc_feedback_web_opt_in_logical_design.md` - `--template` を `--web` 専用とする前提が誤り（gh CLI の `-T/--template` は通常フラグ） | 修正済み（logical-design.md L382-413: `feedback.yml` を単一 SoT として残す方針に修正、Phase 2 着手時に gh issue create -T feedback.yml --body-file ... の実機挙動を再検証する旨を明記） | - |
| 3 | 中 | `unit_003_aidlc_feedback_web_opt_in_logical_design.md` - direct 経路で AI 手動展開すると `.github/ISSUE_TEMPLATE/feedback.yml` と feedback.md で SoT 分裂アンチパターン | 修正済み（logical-design.md L382-413: feedback.yml を SoT、AI が `body[*].attributes.label` を Markdown 見出しに変換するメタロジック手順を明文化、SoT 構造変更時の追従性を確保） | - |
| 4 | 低 | `unit_003_aidlc_feedback_web_opt_in_logical_design.md` - `resolve-route.sh` CLI モードの subcommand 不正・引数不足時の挙動が未明文化 | 修正済み（logical-design.md L160-175: 6 ケースのエラー仕様表を追加し、bats テストで網羅する旨を明記） | - |

## Set 2: 2026-05-10 21:22:48

- **レビュー種別**: 設計レビュー（reviewing-construction-design）
- **使用ツール**: codex（Round 2）
- **反復回数**: 1（Set 1 の Round 2 として継続セッション）
- **結論**: Round 2 で 1 件追加指摘 → Round 3 で指摘 0 件

### 指摘一覧（Round 2）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `unit_003_aidlc_feedback_web_opt_in_logical_design.md` - direct 経路の type 変換ルールが `markdown / textarea / input` に固定されており、未知 `type`（`dropdown` / `checkboxes` 等）の扱いが未定義 + 「手順変更不要」断言が SoT 追従性主張として過大 | 修正済み（logical-design.md L398-407: 未知 `type` のフォールバック方針（warning + プレースホルダ化、fail-fast しない）を明文化、SoT 改訂時の追従範囲を既知 type に限定し、新規 type 追加時は別 Unit での手順書改修が必要と明示） | - |

---

## まとめ

- 計 3 round（Round 1 = 4 件 / Round 2 = 1 件 / Round 3 = 0 件）
- unresolved_count=0、deferred_count=0、resolved_count=5
- `automation_mode=semi_auto` + フォールバック非該当 → `auto_approved`（自動承認 → Phase 2 へ進行）
- codex session-id: `019e11d1-330e-7130-bc49-df5fcb965dc1`
