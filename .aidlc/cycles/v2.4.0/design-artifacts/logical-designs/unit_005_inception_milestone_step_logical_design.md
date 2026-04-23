# 論理設計: Unit 005 Inception Phase へ Milestone 作成ステップを追加 + cycle-label deprecation

## 概要

修正対象 5 ファイル（`02-preparation.md` / `05-completion.md` / `index.md` / `cycle-label.sh` / `label-cycle-issues.sh`）の修正前後のテキスト差分と動作確認手順を定義する。本 Unit は Markdown 編集 + シェルスクリプト先頭コメント追記のみのため、コンポーネント構成・処理フロー等は採用せず、**修正前後テキスト差分の正確性 + 5 ケース判定ロジックの正しさ + 責任分離（02-preparation vs 05-completion）の整合性** を中心に定義する。

**重要**: この論理設計では**コードは書かず**、テキスト差分とその位置のみを定義する。具体的なファイル編集は Phase 2 で行う。

## アーキテクチャパターン

ドキュメント置換 + シェルスクリプトヘッダコメント追記。GitHub Milestone REST API の冪等性（同名 Milestone への再紐付けは冪等）を活用した恒久手順記述。

## 修正対象ファイル一覧

### 1. `skills/aidlc/steps/inception/02-preparation.md`（L53-L62 周辺）

#### 修正前

```markdown
**サイクルラベル付与**（`gh_status` が `available` の場合、Issueを選択した後）:

選択したIssueにサイクルラベルを付与します。

\`\`\`bash
# 一括付与（Unit定義作成後に実行）
scripts/label-cycle-issues.sh {{CYCLE}}
\`\`\`

詳細は `guides/issue-management.md` を参照。
```

#### 修正後

```markdown
**Milestone 紐付け**（`gh_status` が `available` の場合、Issueを選択した後）:

選択したIssueを今回サイクルの Milestone に紐付けます。Milestone は `inception.05-completion` ステップ1で正式に作成・紐付けされます。本ステップでは **既存 Milestone がある場合のみ先行紐付け** を行うオプショナル動作とし、Milestone 作成・OWNER/REPO 解決・フォールバック PATCH の正式な手順は 05-completion ステップ1 に集約します。

\`\`\`bash
# 1. Milestone 一覧（state=all）から {{CYCLE}} を検索（同名 closed 検出のため state=all）
MILESTONE_LOOKUP=$(gh api "repos/{owner}/{repo}/milestones?state=all" \\
  --jq "[.[] | select(.title == \"{{CYCLE}}\") | {number, state}]")

OPEN_COUNT=$(echo "$MILESTONE_LOOKUP" | jq '[.[] | select(.state == "open")] | length')
CLOSED_COUNT=$(echo "$MILESTONE_LOOKUP" | jq '[.[] | select(.state == "closed")] | length')

# 2. 「open=1 && closed=0」のときだけ先行紐付け実行、それ以外は必ずスキップ
if [ "$OPEN_COUNT" -eq 1 ] && [ "$CLOSED_COUNT" -eq 0 ]; then
  # 各 Issue を gh issue edit で先行紐付け
  gh issue edit ISSUE_NUMBER --milestone "{{CYCLE}}"
else
  echo "Milestone {{CYCLE}} は open=$OPEN_COUNT closed=$CLOSED_COUNT のため、本ステップでの先行紐付けはスキップします（05-completion ステップ1 で判定・作成・紐付けされます）"
fi
\`\`\`

**注**: 本ステップでの先行紐付けは `gh issue edit --milestone` のみを使用し、PATCH フォールバックは 05-completion ステップ1 に集約します（PATCH は OWNER/REPO 動的解決を必要とするため、責任分離のため）。`gh issue edit --milestone` が権限または環境差分で失敗する場合は本ステップではエラーログのみ残し、05-completion ステップ1 のフォールバック手順で再試行されます。`OPEN_COUNT == 1 && CLOSED_COUNT == 0` 以外のケース（open≥2 / closed≥1 / 混在 / 不在）は **必ず先行紐付けをスキップ** し、05-completion ステップ1 の 5 ケース判定に委譲します。

詳細は `guides/issue-management.md` を参照。
```

### 2. `skills/aidlc/steps/inception/05-completion.md`（L60-L86 完了時必須ステップ1）

#### 修正前

```markdown
### 1. サイクルラベル作成・Issue紐付け

`gh_status` を参照する。

**判定と処理**:

`gh_status` が `available` 以外の場合: 「警告: GitHub CLIが利用できないため、スキップします」と表示してスキップ。

`gh_status` が `available` の場合:

\`\`\`bash
# サイクルラベル確認・作成（cycle-label.shスクリプトを使用）
scripts/cycle-label.sh "{{CYCLE}}"

# 関連Issueへのサイクルラベル一括付与
scripts/label-cycle-issues.sh "{{CYCLE}}"
\`\`\`

**出力例**:

\`\`\`text
label:cycle:v1.8.0:created
issue:81:labeled:cycle:v1.8.0
issue:72:labeled:cycle:v1.8.0
\`\`\`

**注**: Issue番号が見つからない場合は出力なしで正常終了する。
```

#### 修正後

```markdown
### 1. Milestone 作成・Issue 紐付け

`gh_status` を参照する。

**判定と処理**:

`gh_status` が `available` 以外の場合: 「警告: GitHub CLIが利用できないため、スキップします」と表示してスキップ。

`gh_status` が `available` の場合、以下の手順を実行:

#### 1-1. Milestone 確認・作成

\`\`\`bash
# 1. OWNER/REPO 動的解決
OWNER=$(gh repo view --json owner --jq .owner.login)
REPO=$(gh repo view --json name --jq .name)

# 2. Milestone 一覧（state=all）から {{CYCLE}} を検索（同名 closed 検出のため state=all）
MILESTONE_LOOKUP=$(gh api "repos/$OWNER/$REPO/milestones?state=all" \\
  --jq "[.[] | select(.title == \"{{CYCLE}}\") | {number, state}]")

OPEN_COUNT=$(echo "$MILESTONE_LOOKUP" | jq '[.[] | select(.state == "open")] | length')
CLOSED_COUNT=$(echo "$MILESTONE_LOOKUP" | jq '[.[] | select(.state == "closed")] | length')

# 3. 5 ケース判定（closed 混在を含む重複作成防止）
if [ "$CLOSED_COUNT" -ge 1 ]; then
  # closed 同名がある → 停止（過去サイクルの Milestone close 状態と衝突）
  echo "ERROR: Milestone {{CYCLE}} の closed が ${CLOSED_COUNT} 件あります。過去サイクルとの命名衝突の可能性。手動確認してください: gh api repos/$OWNER/$REPO/milestones?state=all" >&2
  exit 1
elif [ "$OPEN_COUNT" -ge 2 ]; then
  # open が 2 件以上 → 停止（運用タスクで重複作成された可能性）
  echo "ERROR: Milestone {{CYCLE}} の open が ${OPEN_COUNT} 件あります。重複作成の可能性。手動で 1 件に整理してください。" >&2
  exit 1
elif [ "$OPEN_COUNT" -eq 1 ]; then
  # open=1 → 既存を再利用
  MILESTONE_NUMBER=$(echo "$MILESTONE_LOOKUP" | jq '.[] | select(.state == "open") | .number')
  echo "milestone:{{CYCLE}}:exists:number=$MILESTONE_NUMBER"
else
  # open=0 closed=0 → 新規作成
  MILESTONE_NUMBER=$(gh api --method POST "repos/$OWNER/$REPO/milestones" \\
    -f title="{{CYCLE}}" \\
    --jq .number)
  echo "milestone:{{CYCLE}}:created:number=$MILESTONE_NUMBER"
fi
\`\`\`

**判定マトリクス**（5 ケース、closed 混在含む）:

| open 件数 | closed 件数 | 動作 |
|----------|-----------|------|
| ≥ 2 | 0 | 停止（重複作成、手動整理を要求） |
| 1 | 0 | 再利用（既存 open を使用） |
| 0 | 0 | 新規作成 |
| 0 | ≥ 1 | 停止（命名衝突、過去サイクルとの再使用判定を要求） |
| ≥ 1 | ≥ 1 | 停止（混在、運用ミスの可能性として手動確認を要求） |

実装側でも `closed >= 1` の判定を最優先で停止条件としているため、混在ケース（`open>=1 && closed>=1`）も停止される。

#### 1-2. 関連 Issue への Milestone 一括紐付け

Unit 定義ファイル（`.aidlc/cycles/{{CYCLE}}/story-artifacts/units/*.md`）の「関連 Issue」セクションから Issue 番号を抽出し、各 Issue を Milestone に紐付ける。

\`\`\`bash
# Unit 定義から関連 Issue 番号を抽出
# - 抽出ロジックは label-cycle-issues.sh の extract_issue_numbers() に基づく
# - スコープ: 各 Unit ファイルの "## 関連Issue" セクションから次の "## " まで
# - 対応形式: "Closes #数字" / "Fixes #数字" / "- Closes #数字" / "- Fixes #数字" / "- #数字"
ISSUE_NUMBERS=$(awk '
  /^## 関連Issue/ { in_section = 1; next }
  /^## / { in_section = 0 }
  in_section {
    lower_line = tolower($0)
    if (match(lower_line, /^[[:space:]]*(- )?(closes|fixes) #[0-9]+/)) {
      line = $0
      if (match(line, /#[0-9]+/)) {
        num = substr(line, RSTART + 1, RLENGTH - 1)
        if (num != "") print num
      }
    } else if (match(lower_line, /^[[:space:]]*- #[0-9]+/)) {
      line = $0
      if (match(line, /#[0-9]+/)) {
        num = substr(line, RSTART + 1, RLENGTH - 1)
        if (num != "") print num
      }
    }
  }
' .aidlc/cycles/{{CYCLE}}/story-artifacts/units/*.md 2>/dev/null | sort -n | uniq)

# Issue 番号がなければスキップ
if [ -z "$ISSUE_NUMBERS" ]; then
  echo "milestone:{{CYCLE}}:no-issues-to-link"
else
  # 各 Issue を Milestone に紐付け
  echo "$ISSUE_NUMBERS" | while read -r ISSUE; do
    if [ -z "$ISSUE" ]; then continue; fi
    # 優先: gh issue edit --milestone（簡潔）
    if gh issue edit "$ISSUE" --milestone "{{CYCLE}}" 2>/dev/null; then
      echo "issue:$ISSUE:linked:milestone={{CYCLE}}"
    else
      # フォールバック: gh api --method PATCH（gh issue edit が権限/環境差分で失敗する場合）
      if gh api --method PATCH "repos/$OWNER/$REPO/issues/$ISSUE" -F milestone=$MILESTONE_NUMBER 2>/dev/null; then
        echo "issue:$ISSUE:linked:milestone={{CYCLE}}:via-api"
      else
        echo "issue:$ISSUE:link-failed" >&2
      fi
    fi
  done
fi
\`\`\`

**フォールバック手順**: `gh issue edit --milestone` が **権限または環境差分で失敗する場合** は `gh api --method PATCH` を必ず使用する。具体的なエラー時のみ自動的に PATCH に切り替わる。

**1 Issue = 1 Milestone 制約**（GitHub 仕様）: Issue が既に他サイクルの Milestone に紐付いている場合、Milestone 付け替えとなる。サイクル持ち越し時は (a) 新サイクルへ付け替え / (b) Backlog に戻して保持 の 2 択をユーザーに確認する。

**出力例**:

\`\`\`text
milestone:v1.8.0:created:number=5
issue:81:linked:milestone=v1.8.0
issue:72:linked:milestone=v1.8.0
\`\`\`

**注**: Issue 番号が見つからない場合は Milestone 作成のみ行い、紐付けはスキップする（出力 `milestone:created` + `milestone:no-issues-to-link`）。
```

### 3. `skills/aidlc/steps/inception/05-completion.md`（L28-L30 エクスプレスモード ステップ2）

#### 修正前

```markdown
### 2. サイクルラベル作成・Issue紐付け

「完了時の必須作業」のステップ1と同じ手順を実行する。
```

#### 修正後

```markdown
### 2. Milestone 作成・Issue 紐付け

「完了時の必須作業」のステップ1と同じ手順を実行する（1-1: Milestone 確認・作成 / 1-2: 関連 Issue への Milestone 一括紐付け）。
```

### 4. `skills/aidlc/steps/inception/index.md`（L33 / L113 / L208）

#### L33 修正前

```text
| `inception.05-completion` | 完了処理 | サイクルラベル、履歴記録、意思決定記録、ドラフト PR、squash、コミット、コンテキストリセット |
```

#### L33 修正後

```text
| `inception.05-completion` | 完了処理 | Milestone（v2.4.0以降）、履歴記録、意思決定記録、ドラフト PR、squash、コミット、コンテキストリセット |
```

#### L113 修正前

```text
| `available` | Issue 確認・バックログ確認・サイクルラベル付与・ドラフト PR 作成をすべて実行 |
```

#### L113 修正後

```text
| `available` | Issue 確認・バックログ確認・Milestone（v2.4.0以降）紐付け・ドラフト PR 作成をすべて実行 |
```

#### L208 修正前

```text
| `inception.05-completion` | `steps/inception/05-completion.md` | `inception.04-stories-units` 承認後 | サイクルラベル／履歴／意思決定記録／PR／squash／コミット／コンテキストリセット完了 | `on_demand` |
```

#### L208 修正後

```text
| `inception.05-completion` | `steps/inception/05-completion.md` | `inception.04-stories-units` 承認後 | Milestone（v2.4.0以降）／履歴／意思決定記録／PR／squash／コミット／コンテキストリセット完了 | `on_demand` |
```

### 5. `skills/aidlc/scripts/cycle-label.sh` ヘッダ DEPRECATED 注記追加

挿入位置: `#!/usr/bin/env bash`（L1）の直後、`set -euo pipefail`（現行実ファイルでは L21）の直前に以下を挿入。

```text
#
# DEPRECATED: v2.4.0 で非推奨化（#597 / Unit 005）。
#   サイクル運用が GitHub サイクルラベルから GitHub Milestone へ移行したため、
#   本スクリプトは新規 Inception Phase からは呼び出されません。
#   v2.5.0 以降のサイクルでは `inception.05-completion` ステップ1 の
#   Milestone 作成・紐付け手順を使用してください。
#   本スクリプトの物理削除は後続サイクル Unit E（v2.5.0 以降）で実施予定です。
#
```

### 6. `skills/aidlc/scripts/label-cycle-issues.sh` ヘッダ DEPRECATED 注記追加

挿入位置: `#!/usr/bin/env bash`（L1）の直後、`set -euo pipefail`（現行実ファイルでは L29）の直前に上記と同様の DEPRECATED 注記を挿入（スクリプト名のみ「`label-cycle-issues.sh`」に差し替え不要、注記本文はスクリプト名に依存しないため再利用）。

## 動作確認手順

plan「動作確認手順」セクション L336-L381 を参照し、検証観点・コードブロック・期待値注記を維持したうえで本論理設計に記載する（論理設計の節編成上必要な見出しレベル調整や記述の整形は許容する）。

### 検証スコープ限定

本 Unit のスコープは **Markdown ステップ更新 + script コメント追記** のみであり、実際の `gh api` コマンド実行による Milestone 作成・Issue 紐付けの動作確認は本 Unit の完了基準には含めない（v2.5.0 以降のサイクルで自然に検証される。v2.4.0 自身は運用タスク T1 で既に手動実施済み）。

### Markdown 整合性検証

```bash
# 旧記述が完全削除されているか
grep -c "サイクルラベル" skills/aidlc/steps/inception/02-preparation.md  # 期待値: 0
grep -c "サイクルラベル" skills/aidlc/steps/inception/05-completion.md   # 期待値: 0
grep -c "サイクルラベル" skills/aidlc/steps/inception/index.md           # 期待値: 0
grep -c "label-cycle-issues.sh" skills/aidlc/steps/inception/02-preparation.md  # 期待値: 0
grep -c "scripts/cycle-label.sh\|scripts/label-cycle-issues.sh" skills/aidlc/steps/inception/05-completion.md  # 期待値: 0（呼び出しの有無を確認、出典説明コメントとしての参照は許容）

# 新記述が追加されているか
grep -c "Milestone" skills/aidlc/steps/inception/02-preparation.md  # 期待値: ≥1
grep -c "Milestone 作成・Issue 紐付け" skills/aidlc/steps/inception/05-completion.md  # 期待値: ≥1（L60 + L28 のエクスプレス）
grep -c "gh api.*milestones.*--method POST" skills/aidlc/steps/inception/05-completion.md  # 期待値: ≥1
grep -c "gh api --method PATCH.*issues.*milestone" skills/aidlc/steps/inception/05-completion.md  # 期待値: ≥1（フォールバック手順）

# index.md 整合
grep -c "Milestone（v2.4.0以降）" skills/aidlc/steps/inception/index.md  # 期待値: 3（L33/L113/L208）
```

### Script DEPRECATED 注記検証

```bash
# DEPRECATED 注記
grep -c "DEPRECATED: v2.4.0 で非推奨化" skills/aidlc/scripts/cycle-label.sh         # 期待値: 1
grep -c "DEPRECATED: v2.4.0 で非推奨化" skills/aidlc/scripts/label-cycle-issues.sh  # 期待値: 1

# 機能変更なしの確認（既存ロジック保持）
grep -c "set -euo pipefail" skills/aidlc/scripts/cycle-label.sh         # 期待値: 1
grep -c "set -euo pipefail" skills/aidlc/scripts/label-cycle-issues.sh  # 期待値: 1
bash -n skills/aidlc/scripts/cycle-label.sh         && echo "syntax ok"
bash -n skills/aidlc/scripts/label-cycle-issues.sh  && echo "syntax ok"
```

### v2.4.0 自身の Milestone 状態確認（参考、本 Unit の完了基準には含めない）

```bash
gh api repos/ikeisuke/ai-dlc-starter-kit/milestones --jq '.[] | select(.title == "v2.4.0") | {number, state}'
# 期待: {number: 2, state: "open"}
```

## 整合性

### 5 ケース判定ロジックとの整合

- 02-preparation 側は `OPEN_COUNT == 1 && CLOSED_COUNT == 0` のときだけ先行紐付け実行、それ以外は必ずスキップ（plan の責任分離設計に準拠）
- 05-completion 側は `CLOSED_COUNT >= 1` を最優先停止条件とし、5 ケース判定マトリクス全てを網羅（混在ケース `open>=1 && closed>=1` も自動停止）

### Unit 007 への CHANGELOG 委譲との整合

- 本 Unit はスクリプトヘッダ DEPRECATED 注記のみ。CHANGELOG `#597` 節への deprecation 記載は Unit 007 の責務
- Unit 005 完了報告で「Unit 007 の受け入れ基準に CHANGELOG `#597` 節 deprecation 記載追加を依頼」を明記

### v2.4.0 自身の自己参照回避との整合

- 共有プロダクト（`skills/aidlc/steps/inception/`）の Markdown ステップは「v2.4.0 自身に適用しない」等のサイクル固有注記を持たない
- v2.4.0 自身の Milestone (#2) 作成・関連 Issue 紐付けは運用タスク T1 で実施済み（`.aidlc/cycles/v2.4.0/inception/decisions.md` および `story-artifacts/user_stories.md` 末尾「運用タスク T1」に閉じる）

## 不明点と質問

なし（plan 段階で codex AI レビュー 4 反復を経て確定済み）。
