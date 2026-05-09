# Unit: /aidlc-retrospective 独立スキル化（破壊的変更）

## 概要

`skills/aidlc-retrospective/` を新設し、`steps/operations/04-completion.md` §1 の振り返りロジック（feedback_mode 解決 / wizard / cap / 本文構築 / Issue 起票 / spool / mirror_state ラベル化 / dialog token ガード）を全量移転する。`/aidlc` parser に `retrospective`（短縮: `r`）アクションを追加し、`setup` / `migrate` / `feedback` 同様に独立スキルへ委譲する。**v2.6.0 で破壊的変更**（Operations 内振り返り起動を完全廃止）。Operations 完了メッセージで `/aidlc i` と同列に `/aidlc r` を案内する。

## 含まれるユーザーストーリー

- ストーリー 4: /aidlc-retrospective 独立スキル化（破壊的変更）

## 責務

1. **`skills/aidlc-retrospective/` 新設**: `SKILL.md` / `version.txt` / 必要に応じて `scripts/` / `templates/`
2. **`/aidlc` parser 拡張**: `retrospective` / `r` アクション追加、独立スキルへの委譲（`/aidlc-retrospective {additional_context}`）
3. **ロジック全量移転**: 以下を `aidlc-retrospective` に移転
   - feedback_mode 解決ロジック
   - 振り返り wizard（`interactive` モード）
   - cap 判定（`feedback_max_per_cycle` 上限）
   - Issue 本文構築（KPT / 主因切り分け / Try / 事実テーブル）
   - `retrospective_issue_create` / `retrospective_prefill_hook` / `retrospective_update_hook`
   - spool fallback（`gh_status != available` 時）
   - mirror_state ラベル化
   - dialog token ガード（`retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify`）
4. **Operations Phase 残存ロジック削除**: `04-completion.md` §1 から実行ロジックを削除し、案内文（「振り返りは `/aidlc r` を実行してください」）のみ残す
5. **Operations 完了メッセージ更新**: `/aidlc i` 案内と同列で `/aidlc r` を表示
6. **共有ライブラリパス整理**: `lib/retrospective-issue.sh` / `lib/feedback-mode.sh` / `lib/predecessor-issue.sh` / `templates/retrospective_template.md` を `aidlc-retrospective` から参照可能にする（パス解決方針定義）
7. **対象サイクル特定ロジック新規実装**: `/aidlc r` 起動時に直近完了サイクル自動検出 or 引数明示指定の両モード
8. **互換性ドキュメント更新**: README.md / CHANGELOG.md / `aidlc-migrate` 出力に破壊的変更明示
9. **マージ前完結契約の維持**: `write-history.sh --operations-stage post-merge` ガード経路が `aidlc-retrospective` 経由でも有効であることを確認

## 境界

- 振り返りの「内容を判断する責務」は本 Unit のスコープ外（既存の AskUserQuestion ガードロジックを移転するのみ、新規ガード追加は別 Issue）
- 既存 `[rules.retrospective].feedback_mode` スキーマの拡張は対象外（互換維持）
- 振り返り Issue の重複統合 workflow（#621）は対象外（別サイクル）
- `/aidlc-retrospective` の単独 e2e テストは Operations Phase テストの一部として担保（独立 e2e CI 追加は対象外）

## 依存関係

### 依存する Unit

- なし（Unit 005 は単独実装可能）

### 外部依存

- `gh` CLI（Issue 起票 / view / edit）
- 既存 `lib/*.sh` 群（`retrospective-issue.sh` / `feedback-mode.sh` / `predecessor-issue.sh`）
- `aidlc-feedback` / `aidlc-migrate` / `aidlc-setup`（独立スキル構造の手本）

## 非機能要件（NFR）

- **互換性**: `[rules.retrospective].feedback_mode` の 5 値が新スキル経由でも従来通り解釈される
- **観測性**: 移転前後で振り返り Issue 本文の構造（KPT セクション / 主因切り分けマトリクス / 事実テーブル）が一致
- **責務分離**: `aidlc-retrospective` から `aidlc` 本体スキルへの逆参照を作らない（単方向委譲）

## 技術的考慮事項

- 移転規模が大きいため Construction Phase での **sub-Unit 分割を検討**（Phase 1: スキル骨格 + parser 拡張 / Phase 2: ロジック移転 / Phase 3: Operations 側削除 + 完了メッセージ更新 / Phase 4: ドキュメント更新）
- 共有ライブラリの位置: `skills/aidlc/scripts/lib/` を `aidlc-retrospective` から絶対パスで参照する形（最初のオプション）。あるいは `aidlc-retrospective/scripts/lib/` にコピーして単独完結させる形（第二案）。Design Phase で確定
- `predecessor_resolve_issue` のサイクル特定: `/aidlc r` 起動時の引数 / カレントブランチ / 直近 cycle 自動検出の優先順位を Design で確定
- `aidlc-migrate` 連携: v2.5.x → v2.6.0 アップグレード時の通知メッセージ追加を含む
- マージ前完結契約のガード経路: `aidlc-retrospective` 経由の `write-history.sh` 呼び出しでも `--operations-stage post-merge` ガードが有効であることを確認
- 検証: `grep -rn "retrospective" skills/aidlc/steps/operations/` で実行ロジックが残存していないこと

## 関連Issue

- #667

## 実装優先度

High（破壊的変更 + 大規模移転）

## 見積もり

8〜12 時間（スキル骨格 + parser 拡張 + ロジック移転 + Operations 側削除 + ドキュメント + 検証）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-09
- **完了日**: 2026-05-10
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
