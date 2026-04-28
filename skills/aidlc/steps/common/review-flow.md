# AI レビューフロー

> ルーティング判定は `review-routing.md` 参照。本ファイルは `ReviewRoutingDecision` 受領後の実行手順のみを扱う。

ユーザー承認前に AI レビューを実行する。`review-routing.md` で `ReviewRoutingDecision` を導出後に以下を実行。`disabled` はパス 3 へ直行。

## 実行手順

**パス 1（外部 CLI）**: (1) レビュー前コミット → (2) 機密情報除外スキャン（`review-routing.md §2` の除外パターンで照合、`/`なし→ベース名、`/`あり→相対パス、ケースインセンシティブ。全除外 → パス 3、除外ファイルはパスのみ通知）→ (3) 反復レビュー（最大 3 回）: スキル呼び出し → 指摘あれば修正 → 再レビュー、指摘ゼロで完了、3 回後も残で指摘対応判断フロー。

**Codex セッション管理**: 初回後 session id を記録、2 回目以降 `codex exec resume <session-id>`。**エラー時**は `review-routing.md §6` の `fallback_policy` に従う（`cli_runtime_error` / `cli_output_parse_error` への対応ポリシー、`skip_reason_required=true` は下記バリデーション適用）。

**パス 2（セルフ）**: 呼び出し形式は `review-routing.md §7`。反復・完了はパス 1 と同一。**パス 1 → パス 2 の遷移**は `review-routing.md §4` の ToolSelection 順序（`["codex", "self"]` 相当のリスト走査）の自然な延長として読める。`tools = ["codex"]` 設定の場合、暗黙シムにより末尾 self が補完されるため、外部 CLI 失敗時のセルフ降下は `fallback_to_self` ポリシーと等価に動作する（`recommend` モード）。

**パス 3（ユーザー）**: レビュー前コミット → 成果物提示 → 承認要求。修正依頼 → 反映 → レビュー後コミット → 再提示。

**スキップ理由バリデーション**（`skip_reason_required=true` 時）: 空文字不可、禁止パターン（「パッチだから」「小さい変更だから」「時間がないから」等）のみは拒否、履歴に記録。

## 指摘対応判断フロー

反復レビュー 3 回後に残指摘がある場合に実行。

**千日手検出**: 過去 3 回で「同種の指摘」（同一種別・同一パス・同一本質）が 3 回連続出現 → ユーザー判断。

**各指摘への判断**:

| 選択肢 | 動作 |
|--------|------|
| 修正する（推奨） | 修正後、反復レビューに戻る |
| TECHNICAL_BLOCKER | 技術的理由を記録（具体的な根拠必須） |
| OUT_OF_SCOPE | 次サイクルで対応、バックログ登録 |

**理由バリデーション**: 上記「スキップ理由バリデーション」と同じ（空文字不可、禁止パターン拒否）。

**スコープ保護確認**（OUT_OF_SCOPE 時のみ）: `rules-core.md` の「スコープ保護ルール」に基づき、指摘対象が `.aidlc/cycles/{{CYCLE}}/requirements/intent.md` の「含まれるもの」に該当するかを判定。

- 該当 → `automation_mode` に関わらずユーザー確認（対象要件・指摘内容を提示して「スコープから除外してよろしいですか？」）。「はい」→ 履歴に `スコープ保護確認` 記録 → バックログ登録 / 「いいえ」→ 「修正する」に戻る
- 非該当 → バックログ登録へ
- 判定不能（「含まれるもの」不在・曖昧）→ ユーザー確認にフォールバック（安全側）

**OUT_OF_SCOPE バックログ登録**:

- `focus: security` → 公開 Issue への詳細記載禁止。`SECURITY_PRIVATE`（非公開管理）またはマスク済み Issue（本文は `## 概要`（脆弱性種類のみ、再現手順・影響範囲は禁止）+ `## 検出元`（サイクル・Unit・種別）のみ）
- その他 → `gh issue create --title "[Backlog] {要約}" --label "backlog,type:{種別},priority:medium" --body-file <パス>`。`{slug}` は `^[a-z0-9][a-z0-9-]{0,63}$` のみ許可

**判断完了後**: RESOLVE 選択あり → 反復レビューへ戻る / 全て先送り → レビュー完了処理（`review_detected=true` でセミオートゲートが `fallback(review_issues)`）。

## レビュー完了時の共通処理

パス 1/2 完了時: (1) シグナル生成（`review_detected`, `deferred_count`, `resolved_count`, `unresolved_count`、承認ポイント内有効）/ (2) レビュー後コミット / (3) **レビューサマリ更新**【必須、計画承認前除く、未作成のまま次へ進まない】/ (4) セミオートゲート判定（`unresolved_count == 0` かつフォールバック非該当 → `auto_approved`）。

## レビューサマリファイル

計画承認前以外のレビュー完了時に生成・追記。テンプレート: `templates/review_summary_template.md`、既存時は `---` 後に追記。パス: Construction → `construction/units/{NNN}-review-summary.md`、Inception → `inception/{成果物名}-review-summary.md`。

**バックログ列の有効値**: `#NNN`（Issue 作成済み）/ `PENDING_MANUAL`（gh CLI 失敗等で手動登録待ち）/ `SECURITY_PRIVATE`（security 指摘の非公開対応）/ `-`（修正済み・TECHNICAL_BLOCKER 時）。OUT_OF_SCOPE 時は `-` 以外必須。

## 履歴記録

`/write-history` で記録する主要イベント: `AIレビュー完了` / `フォールバック`（機密情報マスク済み）/ `千日手判断` / `AIレビュー指摘対応判断` / `バックログ自動登録` / `AIレビュースキップ`。

## AI レビュー指摘の却下禁止【絶対遵守】

AI レビュワーの指摘をメインエージェントが自己判断で却下してはならない。必ず (1) 修正して再レビュー、または (2) 指摘対応判断フローでユーザー判断を仰ぐ。

## 外部入力検証

**AI レビュー応答**: サブエージェント（Agent ツール）に委譲して事実関係・技術的正確性・対象コード整合性を検証（メインエージェントは結果に介入しない）。出力: 応答要約 / 検証結果 / 相違点 / 結論。サブエージェント起動失敗時はメインエージェントが同フォーマットで検証（却下禁止ルール適用）。セルフレビューは同一エージェント内のため検証非適用（構造・妥当性のみ）。

**ユーザー入力**: 曖昧な入力は解釈を明示して確認。複数解釈可能な場合はすべて提示。

## 分割ファイル参照

- `review-routing.md`: ルーティング判定テーブル集（レビュー開始時の `ReviewRoutingDecision` 導出）
- `review-flow-reference.md`: 外部 CLI の既知制約と対処法（CLI 利用前・エラー発生時）
