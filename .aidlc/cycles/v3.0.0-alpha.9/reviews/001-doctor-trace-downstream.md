# Review 001: doctor `[trace]` 後段検証拡充

- trace: work item 001-doctor-trace-downstream
- matrix_review_mode: code（focus: code, security）
- tool: codex (gpt-5.5) / read-only sandbox

<!-- aidlc-review:code:start status=complete -->
## Code Review

### 対象

`skills/aidlc-v3/scripts/doctor.sh`（`diagnose_trace` 後段3検証追加）/ `skills/aidlc-v3/scripts/tests/test-doctor.sh`（フィクスチャ健全化 + 後段テスト追加）のワーキングツリー差分。

### 指摘と対応（1 回目レビュー: 中 2 件 → 修正 → 2 回目レビュー: 0 件）

- **指摘 #1（中 / code）**: journal 整合の done 照合が部分一致（`[[ "$journal_txt" == *"$name"* ]]`）で、`001-foo` が done のとき journal に `001-foobar` 等があるだけで「記録済み」と誤判定（記録漏れ見逃し）。
  - **対応**: `_trace_journal_has_record` ヘルパーを新設。`- develop completed: <name>` 記録行から値を抽出し完全一致比較に変更。回帰テスト「journal に類似名記録のみ → done 未記録 WARN」を追加。
- **指摘 #2（中 / code）**: Traceability セクション判定が prefix 一致（`"## Traceability"*`）で `## Traceability Notes` を本物として集計 + フラグが一度立つとリセットされず、後続の正規セクションの不備を false OK 化。
  - **対応**: 開始条件を完全一致 `## Traceability` に限定し、正規セクション再入時に `_intent/_accept/_verify` をリセット。回帰テスト「Traceability Notes デコイ + 正規セクション不備 → WARN」を追加。

### セキュリティ観点

- read-only 厳守（state/work item/config 非変更）を確認。gh へ渡す値は本 work item では追加なし（[phase] 既存経路のみ）。
- 本文解析は共有パーサ（`fm_extract_body` / `fm_scalar`）+ bash 組込みのみで、raw grep/sed/awk/permissive jq を使わず parse-guard clean を維持（インジェクション/構造解釈逸脱なし）。
- journal 内容・Traceability 値・cycle 識別子は文字列比較のみで shell/gh へ渡さず、注入余地なし。機密情報のログ混入なし。
- N/A: ネットワーク通信を行わないローカル CLI 診断のため、ネットワーク/HTTP 関連観点は N/A。

### 最終判定

2 回目レビューで指摘 0 件。unresolved_count=0（auto_approved 相当）。

<!-- aidlc-review:code:end -->
