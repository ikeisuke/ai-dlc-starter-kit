# Issue管理ガイド

## 概要

AI-DLCにおけるIssueライフサイクル管理のガイドです。ステータスラベルによる進捗可視化とPRマージ時の自動クローズを活用して、Issue管理の追跡性を向上させます。

**関連ガイド**: バックログ管理については [backlog-management.md](backlog-management.md) を参照

---

## ステータスラベル定義

### ラベル一覧

| ラベル名 | 説明 | 色コード |
|---------|------|---------|
| `status:backlog` | バックログにある未着手の状態 | `#FBCA04` |
| `status:in-progress` | 作業中 | `#0E8A16` |
| `status:blocked` | 他の作業やIssueにブロックされている | `#D93F0B` |

**注意**: ステータスラベルは排他的です。1つのIssueには同時に1つのステータスラベルのみ付与できます。

### ラベル作成コマンド

```bash
# ステータスラベルの一括作成
gh label create "status:backlog" --color "FBCA04" --description "バックログにある未着手の状態"
gh label create "status:in-progress" --color "0E8A16" --description "作業中"
gh label create "status:blocked" --color "D93F0B" --description "他の作業にブロックされている"
```

### 状態遷移図

```text
[Issue作成] → status:backlog
     ↓
[Unit開始] → status:in-progress ←→ [ブロック] → status:blocked
     ↓                                   ↓
[PRマージ] → (自動クローズ、ラベルなし)  [解除] → status:in-progress
```

---

## フェーズ別操作フロー

### Inception Phase

1. **対応Issue選択**
   - バックログからサイクルで対応するIssueを選択
   - Unit定義ファイルに関連Issueとして記載

2. **Milestone 紐付け**
   - Milestone の正式作成と関連 Issue 紐付けは Inception Phase の `05-completion.md` ステップ 1 で実施（主経路: `gh issue edit --milestone`、権限/環境差分による失敗時フォールバック: `gh api --method PATCH`）
   - `02-preparation.md` ステップ 16 は既存 Milestone がある場合のみ先行紐付けする補助動作（v2.4.0 / #597）
   - 補足: 旧サイクル（v2.3.6 以前）で使用していた `cycle:v*` ラベル付与スクリプト（`label-cycle-issues.sh`）は v2.4.0 で deprecated（物理残置）
   - **手動復旧手順**: gh 利用可能時の duplicate/closed 混在復旧（パターン A-1）、gh 利用可能時の LINK_FAILED 復旧（パターン A-2、Issue / PR 双方対応）、gh 利用不可時（パターン B、curl + PAT または GitHub UI）の 3 パターンは [`backlog-management.md` の Inception Phase 節](backlog-management.md#inception-phase) を参照

3. **サイクルPR作成**
   - ドラフトPRに全関連Issueを `Closes #XX` 形式で記載
   - PRテンプレートの「Closes」セクションに記載

### Construction Phase

1. **Unit開始時**
   ```bash
   # ステータスを in-progress に更新
   skills/aidlc/scripts/issue-ops.sh set-status <issue_number> in-progress
   ```

2. **ブロック発生時**
   ```bash
   # ステータスを blocked に更新
   skills/aidlc/scripts/issue-ops.sh set-status <issue_number> blocked

   # 解除時は in-progress に戻す
   skills/aidlc/scripts/issue-ops.sh set-status <issue_number> in-progress
   ```

3. **Unit PR作成**
   - 関連Issueを参照として記載（`関連Issue: #XX`）
   - `Closes #XX` は含めない（サイクルPRで自動クローズ）

### Operations Phase

1. **サイクルPR Ready化時**
   - 「Closes」セクションに全対応Issueが記載されているか確認
   - 記載漏れがある場合は追加

2. **PRマージ時**
   - `Closes #XX` 記載のIssueは自動的にクローズされる
   - ステータスラベルは手動削除不要（クローズで無効化）

3. **残存Issue確認**
   - 未クローズのIssueを次サイクルに引き継ぐか確認

---

## PRとIssueの紐付け

### 自動クローズの仕組み

GitHubでは、PRをマージする際にPR本文に以下のキーワード + Issue番号が含まれていると、関連Issueが自動的にクローズされます：

- `Closes #XX`
- `Fixes #XX`
- `Resolves #XX`

### AI-DLCでの使い分け

| PR種別 | 記載方法 | 理由 |
|--------|---------|------|
| サイクルPR（cycle/vX.X.X → main） | `Closes #XX` | mainマージ時に自動クローズ |
| Unit PR（cycle/vX.X.X/unit-NNN → cycle/vX.X.X） | `関連Issue: #XX`（参照のみ） | 中間PRでのクローズを防止 |

### サイクルPRテンプレート例

```markdown
## サイクル概要
[Intentから抽出した1-2文の概要]

## 含まれるUnit
- Unit 001: [Unit名]
- Unit 002: [Unit名]

## Closes
- Closes #28
- Closes #31
```

### Unit PRテンプレート例

```markdown
## Unit概要
[Unit定義から抽出した概要]

## 関連Issue
- #28（参照のみ、サイクルPRでCloses）

---
:construction: このPRは作業中です。Unit完了時にレビュー依頼を行います。
```

---

## トラブルシューティング

### ステータスラベルが重複している場合

複数のステータスラベルが付いている場合は、`set-status` コマンドで正しいステータスに更新してください。古いラベルは自動的に削除されます。

```bash
# 正しいステータスに更新（古いラベルは自動削除）
skills/aidlc/scripts/issue-ops.sh set-status <issue_number> in-progress
```

### Issueが自動クローズされなかった場合

1. サイクルPRの「Closes」セクションを確認
2. 記載漏れがあれば追加
3. 手動でクローズする場合：
   ```bash
   skills/aidlc/scripts/issue-ops.sh close <issue_number>
   ```

### ステータスラベルが存在しない場合

リポジトリにステータスラベルがない場合は、上記の「ラベル作成コマンド」を実行してください。

---

## 関連ファイル

- `skills/aidlc/scripts/issue-ops.sh` - Issue操作スクリプト
- `skills/aidlc/scripts/label-cycle-issues.sh` - サイクルラベル一括付与スクリプト（**v2.4.0 で deprecated**、Milestone 運用本採用により Inception ステップへ移行）
- `skills/aidlc/guides/backlog-management.md` - バックログ管理ガイド
