# Unit: review-flow 5R 化と defer 自動化

## 概要

`skills/aidlc/steps/common/review-flow.md` および各 reviewing スキル（construction / operations / inception）の review round 上限を 3R から 5R に拡張し、完了条件を「最後 2 round 連続で指摘ゼロまたは defer 化」に改定する。さらに defer 判定時の AI agent による即時 Issue 起票フローと、Round 4 以降の新領域指摘の自動 backlog 化フローを追加する。本 Unit は本サイクルの後続 Unit（B/C/D）の review に対しても効力を持つ（自己適用の閉ループ）。

**「自動」の射程（明示）**: 本 Unit における「自動 Issue 起票」「自動 backlog 化」は **AI agent が機械的手順を実施する運用フローの自動化（人手＋AI 手順の自動化）** を指す。Bash スクリプトでの判定自動化やワークフロー自動化は本サイクルではスコープ外（次サイクル候補）。

## 含まれるユーザーストーリー

- ストーリー 1A: review-flow round 上限 5R 化と完了条件改定
- ストーリー 1B: review-flow defer 判定時の自動 Issue 起票フロー
- ストーリー 1C: Round 4 以降の新領域指摘の自動 backlog 化

## 責務

### 正本ファイル（実装の主たる更新先）

- `skills/aidlc/steps/common/review-flow.md`（**正本**）: round 上限・完了条件を 3R→5R / 「最後 2 round 連続ゼロ or defer 化」に改定。defer 判定時の自動 Issue 起票フロー（必須ラベル: `backlog`, `type:defer-from-review` / 起票後ラベル検証 / 失敗時 `PENDING_MANUAL`）と Round 4 以降の新領域指摘の自動 backlog 化フロー（必須ラベル: `backlog`, `type:new-area-from-round4plus` / 領域キー差分による準機械判定 / `内容` 列のパス記法規約）を追加

### 同期先ファイル（正本を参照、または記述同期）

- `skills/aidlc/steps/common/review-flow-reference.md`: 正本に合わせて round 上限・完了条件・新フロー記述を同期
- 各 reviewing スキル: `reviewing-construction-{plan,design,code,integration}`, `reviewing-operations-{deploy,premerge}`, `reviewing-inception-{intent,stories,units}` の各 SKILL.md / 配下ドキュメントが review-flow.md を参照する記述になっていれば追加更新不要。直接 round 上限値や完了条件を記述している場合は正本に合わせて同期

### テンプレート更新（条件付き）

- `templates/review_summary_template.md`: 以下の条件で更新必須:
  - **必須更新条件**: テンプレートに `## Round 4 新領域判定` セクション（`K_old` / `K_new` / `K_new - K_old` を JSON 配列で記録するセクション）が存在しない場合 → 本 Unit で追加必須
  - その他の更新（5R 化に関する記述）はテンプレート内に該当記述がある場合のみ同期

## 境界

- review-flow.md の改修以外（例: AI レビュースキルの根本的な実装変更）は本 Unit の対象外
- 既存 review-summary の retro-active な書き換えは行わない（v2.5.1 以前の review-summary は新フォーマットへ強制移行しない）
- **テスト追従の責務（明示）**: review-flow 記述に依存する既存 BATS テスト（例: round 上限 / 完了条件 / defer 扱いを参照するテスト）の更新は **本 Unit の責務**。一方、新規 BATS 基盤の拡張（テストランナー差し替え、CI 連携の根本改修等）は本 Unit のスコープ外
- Bash スクリプトでの新領域判定の自動化は本サイクルではスコープ外（次サイクル候補）

## 依存関係

### 依存する Unit

- なし（本 Unit が本サイクル最初の Unit）

### 外部依存

- `gh` CLI（`gh issue create`、`gh issue view --json labels`）

## 非機能要件（NFR）

- **パフォーマンス**: review-flow 1 round あたりの実行時間に影響しない（ドキュメント改修中心）
- **セキュリティ**: 起票時に機密情報（秘密鍵、トークン、内部パス以外の機密 PATH）を Issue 本文に含めない注意書きを review-flow.md に追記
- **スケーラビリティ**: 本 Unit は単一ファイル群の改修のため考慮不要
- **可用性**: `gh` 不可時は warn 継続（review 自体は中断しない）

## 技術的考慮事項

- 5R 化は本 Unit 完了直後から本サイクル後続 Unit の review に対して有効化（自己適用）
- `reviewing-common`（`skills/reviewing-common/`）に共通記述があれば 5R 化を反映する。`bin/sync-reviewing-common.sh` で各 reviewing スキルへ同期する運用を考慮
- 起票後ラベル検証（`gh issue view --json labels`）の `[.labels[].name]` jq クエリは `gh` v2 系で動作することを前提
- 新領域判定の判定手順（手順 0〜7）は review-flow.md に手順詳細として記載し、各 reviewing スキルからは review-flow.md を参照する形に統一

## 関連Issue

- #635（review-flow 5R 化 + defer 即時 Issue 化 + Round 4 新領域指摘の自動 backlog 化）

## 実装優先度

High（本 Unit 完了は後続 Unit の review に対する効力発動のトリガー）

## 見積もり

中（複数ファイル改修 + 自己適用の検証 + Skill Reference Check 通過確認）。0.5 〜 1 日。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
