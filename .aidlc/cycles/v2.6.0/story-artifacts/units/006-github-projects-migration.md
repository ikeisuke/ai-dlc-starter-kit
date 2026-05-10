# Unit: GitHub Projects (ProjectsV2) フル移行

## 概要

Issue #524 の手動チェックリスト運用を GitHub Projects (ProjectsV2) に移行する。Project の作成・フィールド定義・ビュー定義・自動化ワークフロー（`Item closed` → `Status=Done`）・Item 一括投入・Issue #524 のリダイレクト化・AI-DLC 運用ガイダンス更新までを一括で実施する。Milestone（サイクルスコープ）と並行運用し、`priority:*` ラベルとの SoT 方針を運用ルールに明記する。

## 含まれるユーザーストーリー

- ストーリー 3: GitHub Projects (ProjectsV2) フル移行

## 責務

1. **gh CLI トークンスコープ拡張ガイドの整備**: `gh auth refresh -s project,read:project` 手順を `docs/` または `README.md` に記載（**実行はユーザー手動作業**）
2. **Project 作成**: `gh project create` で ProjectsV2 を作成。命名・Visibility（public/private）を確定
3. **フィールド定義**:
   - `Status`（single select）: `Backlog` / `Next` / `In Progress` / `Review` / `Done`
   - `Priority`（single select）: `high` / `medium` / `low`
   - `Cycle`（single select）: 既存 milestone 連動 + `Later`
   - `Type`（label 流用フィルタ）
4. **ビュー定義**:
   - Roadmap（Cycle × Status の時系列）
   - Backlog Board（Status カンバン）
   - Priority Table（Priority + Type フィルタ）
   - Feedback View（feedback ラベル絞り込み）
5. **自動化ワークフロー設定**: `Item closed` トリガで `Status=Done` 遷移を有効化。テスト用 Issue で実証
6. **Item 一括投入**: 現状 Open Issue（Issue #524 リスト記載分）を Project に追加。Priority / Cycle / Status の初期値セット
7. **Issue #524 リダイレクト化**: 本文を Project URL + 運用ルールのみに置換、完了済みセクション削除運用を廃止
8. **AI-DLC 運用ガイダンス更新**:
   - `skills/aidlc/steps/inception/02-preparation.md` の「ステップ17 バックログ確認」に Project 参照ステップを組み込み
   - `gh project item-list` または Project URL 案内を追加
9. **CHANGELOG / README 更新**: v2.6.0 で GitHub Projects 移行を明示
10. **異常系ハンドリング**: gh CLI トークンスコープ不足時、AI-DLC スクリプトは Project 操作をスキップして警告のみで続行

## 境界

- `priority:*` ラベルと Project `Priority` フィールドの **双方向同期 workflow** は対象外（別サイクル）
- 振り返り Issue / backlog Issue の分離（#664）は対象外
- Project の workflow 拡張（自動 `Status=Next` 遷移等、`Item closed` 以外の自動化）は対象外
- 既存 milestone 機能との重複削除は対象外（並行運用方針）

## 依存関係

### 依存する Unit

- なし（独立して実装可能）

### 外部依存

- `gh` CLI v2.x（`project` サブコマンド対応）
- `gh` トークンスコープ `project` / `read:project`（ユーザー手動作業）
- GitHub Projects (ProjectsV2) 機能（GitHub.com 上）

## 非機能要件（NFR）

- **冪等性**: `gh project create` / `field-create` / `view-create` / `item-add` の二重実行を防ぐ事前確認ロジック
- **可観測性**: スクリプト実行ログで作成された Project URL / 各フィールド ID を出力
- **柔軟性**: gh CLI スコープ不足時に AI-DLC 主機能（バックログ確認等）を阻害しない

## 技術的考慮事項

- `gh project` コマンドの利用が中心。一部は GraphQL `addProjectV2ItemById` / `updateProjectV2ItemFieldValue` 経由
- 冪等性: `gh project list --owner <owner>` で既存 Project を確認、未作成時のみ create
- Item 一括投入は `gh project item-add --owner <owner> --number <project-number> --url <issue-url>` を Issue ごとにループ
- `Cycle` フィールド値は既存 milestone（`v2.6.0` 等）を初期値として投入
- Priority フィールド値は既存 `priority:*` ラベルから派生
- Status フィールド初期値: 既存 Issue は `Backlog`、closed は `Done`
- `Item closed` workflow は GitHub UI または GraphQL `enableProjectV2Workflow` で有効化（Construction Design で確定）

## 関連Issue

- #673
- 関連: #31（過去検討）/ #524（移行対象）

## 実装優先度

Medium

## 見積もり

5〜8 時間（Project 作成 + フィールド/ビュー定義 + Item 一括投入 + Issue #524 リダイレクト + ドキュメント更新 + AI-DLC 連携）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-10
- **完了日**: 2026-05-10
- **担当**: AI-DLC (Claude Code)
- **エクスプレス適格性**: -
- **適格性理由**: -
