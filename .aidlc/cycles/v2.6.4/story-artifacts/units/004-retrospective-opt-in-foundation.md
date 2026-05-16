# Unit: 振り返りスキル `aidlc-retrospective` の opt-in 基盤導入 + 後方互換確保

## 概要

振り返りスキル `aidlc-retrospective` の Issue 起票方針を「振り返り単位の自動起票（現行）」から「Try/改善単位での個別起票（将来）」へ段階的に移行するため、patch スコープで **opt-in 基盤の導入** と **`predecessor_resolve_issue` の 5 経路解決の後方互換確保** までを実施する。デフォルト動作は不変。破壊的変更（自動起票完全廃止 / `Retrospective:` タイトル運用見直し / API 破壊的変更）は v2.7.0+ に明示除外する。

## 含まれるユーザーストーリー

- ストーリー 4: 振り返りスキル `aidlc-retrospective` の opt-in 基盤導入 + 後方互換確保（#710 / patch サブセット）

## 責務

- **opt-in 基盤の導入**:
  - 振り返り集約 Issue 起票を切り替える config フラグ追加（例: `[rules.retrospective].auto_issue_creation` または同等。具体名は Construction Phase 設計で確定）
  - **デフォルト値での挙動不変**: デフォルト値は現行動作互換（=作成する）に固定し、デフォルト設定のままでは consumer プロジェクトの挙動は一切変わらない
  - **`false` 経路の実装方針**: 「実装するが既定では未発火」とする。フラグが `false` の場合に集約 Issue 起票をスキップする経路を実装するが、デフォルト値が `true` であるため、明示的に `config.toml` で `false` を設定したユーザーだけが新経路を体験する（Try/改善単位の個別起票への移行準備）。`false` 経路の動作確認も Construction Phase の Unit 内で実施する
- **後方互換確保**:
  - `predecessor_resolve_issue`（`skills/aidlc/scripts/lib/predecessor-issue.sh`）の 5 経路解決の `resolution_path` 出力不変を確認
  - **必須チェック手順（手動再現でも同一基準で再現可能）**:
    1. **経路 1（milestone+label）**: `gh available × milestone_enabled=true × Issue ヒット` の状況を再現（テスト用 cycle で gh CLI 経由で milestone + retrospective label 付き Issue を 1 件作成）→ `predecessor_resolve_issue "{{TEST_CYCLE}}"` を実行 → `resolution_path: "milestone_and_label"` および `issue_url` が想定 Issue を指すことを確認
    2. **経路 1' (label fallback)**: 同条件で `milestone_enabled=false` に変更 → `resolution_path: "label_fallback"` を確認
    3. **経路 2（spool fallback）**: gh 不可 + spool 存在の状況を再現 → `resolution_path: "spool_fallback"` を確認
    4. **経路 3（v2.5.0 互換）**: 経路 1/1'/2 すべて 0 件 + `cycles/{{TEST_CYCLE}}/operations/retrospective.md` 存在 → `resolution_path: "v250_compat"` を確認
    5. **経路 4（warn+continue）**: すべて 0 件 → `resolution_path: "warn_continue"` を確認
  - 既存 bats テストがあれば pass、なければ上記 5 経路の手動再現結果（実行コマンド・期待出力・実出力・判定結果）を `inception/decisions.md` に DR として残す
- **既存ガードの動作維持**:
  - 対話必須トークン / cap 判定 / mirror 送信判断の挙動が破壊されていないことを以下の必須チェック手順で確認:
    1. **対話必須トークン**: 振り返りスキル実行時、対話必須箇所でユーザー応答なしに進行しないことを確認（テスト手段: `AskUserQuestion` が呼ばれる箇所を 1 つ以上手動実行し、応答前にスキップされないことを観察）
    2. **cap 判定**: 振り返り Issue 起票の cap 上限（既存仕様の値）に達した場合に追加起票が拒否されることを確認（手動で cap 直前 / 超過の 2 状況を再現）
    3. **mirror 送信判断**: mirror 送信の AskUserQuestion が「送る / 送らない」の選択を正しく要求することを確認
- **対象外項目の明示記載**:
  - 関連スキルのドキュメントに「v2.6.4 サイクル対象外項目」と「v2.7.0+ で対応予定」を defer 記録

## 境界

- **本 Unit 対象外**:
  - 振り返り Issue 自動起票の完全廃止
  - `Retrospective: {cycle}` タイトル運用の本格的見直し
  - 振り返り Issue API の破壊的変更
  - Try/改善単位での個別起票実装（基盤整備までで、実装は v2.7.0+）
- `aidlc-retrospective` 以外のスキル（`aidlc-feedback` 等）への波及改修は本 Unit 対象外

## 依存関係

### 依存する Unit

- なし（独立 Unit）

### 外部依存

- `gh` CLI（既存）
- `skills/aidlc/scripts/lib/predecessor-issue.sh`（既存）
- `skills/aidlc/scripts/lib/feedback-mode.sh`（既存）
- `skills/aidlc/scripts/lib/retrospective-api.sh` / `retrospective-issue.sh`（既存）
- 関連 bats テスト（`tests/retrospective_*.bats` 等）

## 非機能要件（NFR）

- **後方互換性**: 既存サイクル振り返り Issue 検索（`predecessor_resolve_issue` の 5 経路）が現状通り動作（=既存サイクルの振り返り探索が一切壊れない）
- **段階的改修**: 本サイクルでは挙動を変えず、フラグ追加のみで v2.7.0+ への橋頭堡を確保
- **デフォルト動作不変**: 既存 consumer プロジェクトで `config.toml` を変更しないユーザーは挙動変化を体験しない

## 技術的考慮事項

- SKILL.md 本文 500 行制限を超えないこと（`aidlc-retrospective` / `aidlc` 関連の改訂で注意）
- `predecessor_resolve_issue` の 5 経路解決は最優先で後方互換確保（既存サイクルの振り返り検索が壊れると影響大）
- AI エージェント Bash ツール経由の安全パターン遵守
- `printf -v` 系 result-out 関数を新規導入する場合は v2.6.3 で追加された namespace 規約に従う
- config フラグの命名は既存 `rules.*` 体系との整合性を保つ（Construction Phase の論理設計で確定）

## 関連Issue

- #710（部分対応 / `Relates` 扱い。完全クローズは v2.7.0+ で破壊的変更が入った時点）
- v2.6.3 サイクル振り返り議論（KPT で振り返り Issue 不要と判断した運用実例）
- 既存 Issue #586（v2.6.3 Try の実体としてバックログに存在）

## 実装優先度

Medium（refactor / 将来基盤）

## 見積もり

1 〜 1.5 日（opt-in 基盤導入 + 後方互換確認 + 対象外項目の defer 記録）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
