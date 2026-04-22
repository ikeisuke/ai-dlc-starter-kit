# Unit: Inception Phase へ Milestone 作成ステップを追加 + cycle-label deprecation

## 概要

GitHub Milestone 運用本採用（#597）の中核 Unit。`skills/aidlc/steps/inception/` の Markdown ステップに、サイクルバージョン確定時に Milestone を作成し対象 Issue を紐付ける手順を追加する。同時に既存の「サイクルラベル付与」記述を Milestone 紐付け手順に置換し、`cycle-label.sh` / `label-cycle-issues.sh` を deprecated 化する（物理削除は本サイクル対象外）。AI/人間が Markdown 手順に従って `gh api` を順次実行することで、対話なしで Milestone 作成と紐付けが完了する状態を作る。

## 含まれるユーザーストーリー

- ストーリー 1: Inception での Milestone 作成・紐付け（Unit B 由来）
- ストーリー 4: cycle-label.sh / label-cycle-issues.sh の deprecated 化（Unit B 由来）

## 責務

- `skills/aidlc/steps/inception/02-preparation.md` ステップ16 から「サイクルラベル付与」記述（`scripts/label-cycle-issues.sh` 呼び出し）を削除し、Milestone 紐付け手順（`gh api --method PATCH repos/OWNER/REPO/issues/NUMBER -F milestone=N`）に置換
- `skills/aidlc/steps/inception/05-completion.md` ステップ1「サイクルラベル作成・Issue紐付け」を削除し、Milestone 作成手順（`gh api repos/OWNER/REPO/milestones --method POST -f title=vX.Y.Z`）+ Issue 紐付け手順に置換
- `gh issue edit --milestone` がトークンスコープで失敗するケース向けに `gh api --method PATCH repos/OWNER/REPO/issues/NUMBER -F milestone=N` フォールバック手順を各ステップ内に明示
- `skills/aidlc/scripts/cycle-label.sh` のスクリプト先頭コメントに「DEPRECATED: v2.4.0 で非推奨化、物理削除は Unit E（後続サイクル）で実施予定」を追記
- `skills/aidlc/scripts/label-cycle-issues.sh` 同様に deprecation 記述を追加
- CHANGELOG（v2.4.0 リリースノート）への両スクリプト deprecation 記載は **Unit 007 の受け入れ基準に委譲**する（CHANGELOG の `#597` 節編集は Unit 007 が排他所有、本 Unit はスクリプト先頭コメントへの記述のみを担当）。本 Unit 完了報告で「Unit 007 で CHANGELOG への deprecation 記載が必要」を明示し、Unit 007 の受け入れ基準に項目追加を依頼する
- **v2.4.0 サイクル自身の自己参照回避は共有手順に含めない**: 共有プロダクト（`skills/aidlc/steps/inception/`）の Markdown ステップは「v2.4.0 自身に適用しない」等のサイクル固有注記を持たない。v2.5.0 以降のすべてのサイクルで等しく適用される恒久手順として記述する。サイクル固有の運用は `story-artifacts/user_stories.md` の運用タスク T1 と `inception/decisions.md`（Inception 完了処理で作成）に閉じる

## 境界

- Operations Phase 側の Milestone close + 紐付け確認は Unit 006 で扱う
- ドキュメント側（docs/configuration.md / README.md / guides / rules.md）の更新は Unit 007 で扱う
- `cycle-label.sh` / `label-cycle-issues.sh` の物理削除は本 Unit 対象外（後続サイクル Unit E）
- 過去 v2 サイクル（v2.0.0〜v2.3.5）の遡及 Milestone 化（Unit D）は本サイクル対象外

## 依存関係

### 依存する Unit

- なし（Unit 006 と並列で進められる。Unit 007 は本 Unit と Unit 006 の両方完了後に着手）

### 外部依存

- `gh` CLI（v2 系、`gh api` サブコマンド利用）
- GitHub REST API: `POST /repos/{owner}/{repo}/milestones`、`PATCH /repos/{owner}/{repo}/issues/{number}`
- `gh milestone` サブコマンド非存在前提（REST API 直叩き）

## 非機能要件（NFR）

- **パフォーマンス**: AI/人間が手順に従って `gh api` を 1 サイクルあたり 1 回（Milestone 作成）+ 対象 Issue 数（紐付け）回実行する。10〜20 Issue/サイクルで数秒〜十数秒
- **セキュリティ**: トークンスコープが不足する場合のフォールバック手順を必ず明示。`gh api` 呼び出し時に機密情報がコマンドラインに露出しないこと
- **スケーラビリティ**: 1 Issue = 1 Milestone 制約（GitHub 仕様）。持ち越し時は付け替え or Backlog 保持の 2 択を手順内で明示
- **可用性**: 手順は対話なしで完結すること（Markdown ステップを順に実行できる構造）

## 技術的考慮事項

- 既存の Inception index.md（フェーズインデックス）のチェックポイント表 / 分岐ロジックへの影響有無を Construction Phase 設計時に確認（02-preparation.md / 05-completion.md の構造変更が phase-recovery-spec.md §5.1 のチェックポイントに影響するか）
- Markdown ステップ内に gh api コマンド例を記述する際、変数プレースホルダ（`{{CYCLE}}` / `{milestone_number}` / `{NUMBER}`）の表記を既存スタイルに合わせる
- Inception index.md（02-preparation.md / 05-completion.md の参照元）の更新要否を確認
- `cycle-label.sh` / `label-cycle-issues.sh` の deprecation 注記は、スクリプトを実行した際の stderr に警告メッセージを出すかは Construction 設計時に判断（純コメント追加のみで済ませる方が破壊的変更が少ない）

## 関連Issue

- #597（部分対応：Unit B 担当部分。Unit A は Unit 006、Unit C は Unit 007、Unit D-F は本サイクル対象外）

## 実装優先度

High（#597 本採用の中核、Unit 006 / 007 のドキュメント整合の基準になる）

## 見積もり

3〜5 時間（Markdown ステップ更新 2 ファイル: `02-preparation.md` / `05-completion.md` + script 先頭コメント 2 ファイル: `cycle-label.sh` / `label-cycle-issues.sh` + 動作確認。CHANGELOG 記載は Unit 007 へ委譲済みのため本 Unit 見積もりに含まない）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
