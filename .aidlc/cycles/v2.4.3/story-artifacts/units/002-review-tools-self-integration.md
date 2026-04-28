# Unit: レビューツール設定への self 正式統合と後方互換シム（#611）

## 概要

`[rules.reviewing].tools` に `"self"`（および alias `"claude"`）を正式に許容し、外部 CLI の usage limit / 不在 / parse 失敗を「ツール解決順序の自然な延長」として self に降ろせるようにする。既存設定（`tools = ["codex"]` / `tools = []` / 未設定）を破壊しないため `ToolSelection` ロジック内に暗黙シム（末尾 self 補完 / `claude → self` alias 正規化）を実装し、`review-routing.md` / `review-flow.md` の文書を新仕様に整合させる。

## 含まれるユーザーストーリー

- ストーリー 2: レビューツール設定への self 正式統合（#611）

## 責務

- `skills/aidlc/steps/common/review-routing.md` の §3 設定 / §4 ToolSelection / §5 PathSelection / §6 FallbackPolicyResolution の更新（§6 は「ツール解決順序の延長として self に降りる」表現への整理を含み、Construction Phase 設計で章を縮約 or 注記化のいずれを採るか判断・実施する）
- `skills/aidlc/steps/common/review-flow.md` のパス1/パス2 / Codex セッション管理 / フォールバック関連記述の整合更新
- `skills/aidlc/config/defaults.toml` の現状維持確認 + 方針記録
- 後方互換シム（暗黙末尾 self 補完）の論理実装と動作確認テーブル
- alias 正規化（`"claude" → "self"`）の実装と動作確認
- 6 パターンの後方互換 / 新規明示パターン動作確認の記録

## 境界

- `"self"` / `"claude"` 以外の汎用ツール名正規化拡張は対象外（複数 LLM 並列実行も同様）
- セルフレビュー実行ロジックの再設計は対象外（既存パス2フローを流用）
- レビュー対象スキル群（`reviewing-construction-*` / `reviewing-inception-*` / `reviewing-operations-*`）の本体修正は不要（ToolResolution の入口で吸収）

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `dasel`（`.aidlc/config.toml` 読み出し、変更影響なし）
- `codex` CLI（外部レビューツールとして従来通り使用）

## 非機能要件（NFR）

- **パフォーマンス**: ツール解決ロジックは O(N) リスト走査で N≦数件のため影響なし
- **セキュリティ**: 影響なし
- **スケーラビリティ**: alias 機構は最小実装で将来の汎用化を妨げない
- **可用性**: 既存設定の後方互換性を維持

## 技術的考慮事項

- 暗黙シムは `review-routing.md` の `ToolSelection` 内に集約（`read-config.sh` 利用側ではなく）
- 動作確認は 6 パターン: A=`["codex"]` / B=`[]`（従来「セルフ直行シグナル」と意味付け、シム適用結果 `["self"]` 相当と等価で動作することを明文化）/ C=`["codex","self"]` / D=`["self"]` / E=`["claude"]` / F=未設定
- 確認方法: `scripts/read-config.sh` 経由 + 擬似 ToolSelection 実行表 / または bats テスト（Construction Phase 設計時に確定）
- `review-routing.md` は純粋参照ファイルのため、文書整合性レビュー（grep / 相互参照確認）が必要
- `defaults.toml` の `tools = ["codex"]` は維持（暗黙シムで実質 `["codex", "self"]` 相当）

## 関連Issue

- #611

## 実装優先度

High

## 見積もり

M（Medium）: 文書改訂 + 後方互換テスト 6 パターン。Construction Phase で 1-2 セッション

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-28
- **完了日**: 2026-04-28
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
