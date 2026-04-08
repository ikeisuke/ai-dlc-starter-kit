# 実行計画: Unit 006 adminマージ禁止・auto-merge対応

## 概要

Operations PhaseのマージフローにCIチェック通過後のauto-merge対応を追加し、admin権限によるbypass mergeを前提としない設計を明文化する。

## 不変条件

1. **既存のマージ方法選択（通常/Squash/Rebase）は維持**
2. **既存のマージ条件を緩和しない**
3. **GitHub側の設定変更はガイドで案内のみ**（自動設定は行わない）
4. **adminバイパスは事前前提として禁止**（事後検知ではなくBranch protection側で制御）

## 対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `scripts/pr-ops.sh` | mergeサブコマンドにauto-merge対応を追加（CI確認・`--auto`実行・エラー種別吸収） |
| `steps/operations/operations-release.md` | 7.13を2段構成に整理（方法決定 → 実行モード決定）、adminバイパス前提の排除 |
| `guides/branch-protection.md` | 新規作成: Branch protection設定手順ガイド |

## 変更内容

### scripts/pr-ops.sh の変更

mergeサブコマンドに以下の責務を追加:

1. **CIステータス確認**: `gh pr checks {PR番号}` でチェック状態を取得
2. **全チェック通過時**: 即時マージ（現行動作）
3. **未完了/失敗時**: `gh pr merge --auto` でauto-merge設定を試行
4. **出力拡張**:

| 出力 | 意味 |
|------|------|
| `pr:{N}:merged:{method}` | 即時マージ成功（現行） |
| `pr:{N}:auto-merge-set:{method}` | auto-merge設定成功（CI完了後に自動マージ） |
| `pr:{N}:error:auto-merge-not-enabled` | リポジトリでauto-merge未有効化 |
| `pr:{N}:error:checks-failed` | CIチェック失敗（auto-merge不可） |
| `pr:{N}:error:permission-denied` | 権限不足 |
| `pr:{N}:error:{existing}` | 既存エラー（維持） |

### operations-release.md 7.13の変更

現在のマージフロー（L179-197）を2段構成に整理:

**段1: マージ方法決定**（現行ロジック維持）
- `gh_status`、`merge_method` に基づく方法選択

**段2: 実行モード決定**（新規追加）
- `pr-ops.sh merge` の結果に応じた次アクション:

| 結果 | 対応 |
|------|------|
| `merged` | 完了 |
| `auto-merge-set` | 「CI完了後に自動マージされます」と表示 |
| `auto-merge-not-enabled` | ガイド（`guides/branch-protection.md`）を案内し、CI完了待ちを提示 |
| `checks-failed` | CIエラー内容を確認し、修正を案内 |
| `permission-denied` | 権限のあるメンテナへの依頼、またはGitHub UIでの保護ルール準拠マージを案内 |
| その他error | エラー内容を表示し、再試行/中断の選択 |

**adminバイパスの前提排除**: Branch protectionでbypassを禁止する設定を前提とし、フロー上はadmin overrideを案内しない。保護設定未整備の場合はガイドを案内。

### guides/branch-protection.md

以下の設定手順を案内:
- Branch protection rulesの有効化
- "Do not allow bypassing the above settings" の有効化（adminバイパス禁止）
- Required status checks の設定
- Auto-mergeの有効化（Settings → General → Allow auto-merge）

## 完了条件チェックリスト

- [ ] pr-ops.sh mergeにCI確認・auto-merge対応が追加されている
- [ ] pr-ops.sh の出力に新規ステータスが追加されている
- [ ] 7.13が2段構成（方法決定 → 実行モード決定）に整理されている
- [ ] フォールバックが原因別に分離されている（auto-merge未有効化/権限不足/CI失敗）
- [ ] adminバイパスを前提としない設計が明文化されている
- [ ] Branch protection設定ガイドが作成されている
- [ ] 既存のマージ方法選択（merge_method設定）が維持されている
- [ ] 差分レビューで既存動作への影響がないことを確認済み
