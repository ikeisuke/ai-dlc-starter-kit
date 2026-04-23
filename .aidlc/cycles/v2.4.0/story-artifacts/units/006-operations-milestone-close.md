# Unit: Operations Phase へ Milestone close + 紐付け確認 + fallback 作成を組込み

## 概要

`skills/aidlc/steps/operations/` の Markdown ステップに、サイクル完了時の対象 PR/Issue の Milestone 紐付け確認と Milestone close 手順を追加する。Milestone 作成は Unit 005（Inception）責務であり、本 Unit（Operations）は通常作成しない。Operations 開始時に Milestone 不在を検出した場合のみ、4 段階優先順位の判定規則（closed 1+→停止 / open 2+→停止 / open 1→再利用 / 両方 0→fallback 作成）に従って fallback を提供する。

## 含まれるユーザーストーリー

- ストーリー 2: Operations での Milestone close + 紐付け確認（Unit A 由来）

## 責務

- `skills/aidlc/steps/operations/` の該当ステップ（`02-deploy.md` / `03-release.md` / `04-completion.md` / `operations-release.md` のいずれか適切な箇所）に、以下を追加:
  - 対象 PR/Issue の Milestone 紐付け確認手順（`gh api --method PATCH repos/OWNER/REPO/issues/NUMBER -F milestone=N` で不足分を追加紐付け可能）
  - Milestone close 手順（`gh api repos/OWNER/REPO/milestones/{number} --method PATCH -f state=closed`、対話なし実行可能）
  - Milestone 不在時の fallback 判定規則（4 段階優先順位、ストーリー 2 の受け入れ基準に明示済み）
  - fallback 発火条件と警告メッセージのテキスト（実装者が解釈で補わずに済むレベル）
  - `gh api` 失敗時の close 中断条件と警告メッセージ
- v2.3.5 由来のマージ前完結ルールとの整合確認（progress.md 固定スロット更新タイミングと矛盾しない位置に Milestone close 手順を配置）
- ステップ内のフロー（gh_status 判定、紐付け確認、fallback 判定、close 実行）の順序を明示

## 境界

- Inception Phase 側の Milestone 作成は Unit 005 で扱う
- ドキュメント側（docs/configuration.md / README.md / guides / rules.md）の更新は Unit 007 で扱う
- 過去 v2 サイクル（v2.0.0〜v2.3.5）の遡及 Milestone 化（Unit D）は本サイクル対象外

## 依存関係

### 依存する Unit

- なし（Unit 005 と並列実装可能、ただし本サイクル v2.4.0 自身の運用は Inception 完了時の運用タスク T1 で補完）

### 外部依存

- `gh` CLI（v2 系、`gh api` サブコマンド利用）
- GitHub REST API: `PATCH /repos/{owner}/{repo}/milestones/{number}`、`PATCH /repos/{owner}/{repo}/issues/{number}`、`GET /repos/{owner}/{repo}/milestones?state=open|closed|all`
- マージ前完結ルール（v2.3.5 で導入、`progress.md` 固定スロット）

## 非機能要件（NFR）

- **パフォーマンス**: 対象 PR/Issue 数（10〜20 件想定）に対して数秒〜十数秒
- **セキュリティ**: トークンスコープ不足時のフォールバック手順を明示、機密情報の露出回避
- **スケーラビリティ**: 1 Issue = 1 Milestone 制約に整合
- **可用性**: 手順は対話なしで完結。`gh api` 失敗時は誤った成功扱いを避けるため close 中断 + 警告

## 技術的考慮事項

- 既存の Operations index.md / `operations-release.md` の章構成への影響を Construction Phase 設計時に確認
- マージ前完結ルール（v2.3.5）との整合: progress.md `release_gate_ready` / `completion_gate_ready` / `pr_number` 固定スロットの更新タイミングと、Milestone close のタイミング（マージ前完結が前提）を矛盾なく配置する
- 4 段階優先順位の判定規則は、Markdown ステップ内に擬似コード or 表形式で明示する（実装者が読み違えないレベル）
- `gh pr view --json milestone` 等で現在の Milestone 紐付け状態を取得する手順も補助的に明示

## 関連Issue

- #597（部分対応：Unit A 担当部分。Unit B は Unit 005、Unit C は Unit 007、Unit D-F は本サイクル対象外）

## 実装優先度

High（#597 本採用の中核、Unit 005 と並列）

## 見積もり

3〜4 時間（Markdown ステップ更新 1-2 ファイル + 判定規則記述 + 動作確認）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-23
- **完了日**: 2026-04-23
- **担当**: AI（Claude / codex 協調）
- **エクスプレス適格性**: -
- **適格性理由**: -
