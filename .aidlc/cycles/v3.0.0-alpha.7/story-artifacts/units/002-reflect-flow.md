# Unit: reflect フロー実装

## 概要

v3 に reflect（振り返り）フローを実装し、`/aidlc-v3 reflect` でサイクルの KPT 抽出と改善 Issue 化、`reflect.md` 記録、`journal.md` 追記までを v3 単独の手順で行えるようにする。

## 含まれるユーザーストーリー
- ストーリー 1: reflect で振り返り→改善 Issue 化

## 責務
- `skills/aidlc-v3/steps/reflect.md` の新規作成（`docs/v3/workflow.md §3.4` Step 1–4: 材料収集 / KPT 抽出（人間編集）/ 行動化（Try の Issue 化 + `reflect.md` 記録）/ 完了（`journal.md` 追記））。
- `skills/aidlc-v3/templates/reflect.md` の新規作成（Keep / Problem / Try / Issue リンクの章立て）。
- `SKILL.md` の `reflect` を「予約」から実装済み（`steps/reflect.md`）に更新し、`retrospective` エイリアス・express ラッパと整合させる。
- core から外す項目（upstream mirror / cap 管理 / dialog token / aggregate retrospective issue）を「実装しない」と手順・ドキュメントに明示。
- reflect 手順のドライ検証（Step 1–4 の入出力・成果物生成パス確認）。Try の Issue 化を**承認しない場合は Issue を作らない** / **一部のみ承認時は必要分のみ作る**分岐挙動もドライ検証する。

## 境界
- doctor / status / #735 は扱わない（別 Unit）。
- 推定値検出ガード等の重い振り返り補助ロジックは core 外として実装しない。
- frontmatter の生パースは `lib/frontmatter.sh` に委譲（grep/sed/awk 直書き禁止）。

## 依存関係

### 依存する Unit
- なし

### 外部依存
- `gh issue create`（Try の Issue 化 / `gh_status=available` 時のみ）
- `docs/v3/workflow.md §3.4` / `docs/v3/data-model.md §7・§10`（SoT 参照）

## 非機能要件（NFR）
- **パフォーマンス**: 手順ベース（スクリプト重処理なし）。
- **セキュリティ**: reflect.md / Issue 本文に機密情報を含めない（review-flow のマスク方針準用）。
- **スケーラビリティ**: 該当なし。
- **可用性**: `gh` 不可用時は Issue 化を skip し reflect.md 記録は継続。

## 技術的考慮事項
- reflect は明示の承認ゲートを持たない（Step 2 人間編集 / Step 3 Issue 化を人間確認）。
- 成果物保存先契約（`data-model.md §10`）: reflect → `reflect.md` + Issue。

## 関連Issue
- Relates to #736（v3 リニューアル Epic / Phase 6）

## 実装優先度
High

## 見積もり
0.5〜1 サイクル日相当（手順 + テンプレート + ドライ検証）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-28
- **完了日**: 2026-06-29
- **担当**: Claude (Construction Phase)
- **エクスプレス適格性**: -
- **適格性理由**: -
