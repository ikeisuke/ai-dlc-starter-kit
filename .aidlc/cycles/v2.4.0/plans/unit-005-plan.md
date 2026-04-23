# Unit 005 計画: Inception Phase へ Milestone 作成ステップを追加 + cycle-label deprecation

## 対象 Unit

- **Unit ファイル**: `.aidlc/cycles/v2.4.0/story-artifacts/units/005-inception-milestone-step.md`
- **担当ストーリー**: ストーリー 1（Inception での Milestone 作成・紐付け）+ ストーリー 4（cycle-label.sh / label-cycle-issues.sh の deprecated 化）
- **関連 Issue**: #597（Unit B 担当部分）
- **依存 Unit**: なし（Unit 006 と並列可、Unit 007 が本 Unit + Unit 006 完了後）
- **見積もり**: 3〜5 時間

## 課題と修正方針

### 課題

GitHub Milestone 運用本採用（#597）の中核として、`skills/aidlc/steps/inception/` の Markdown ステップにサイクルバージョン確定時の Milestone 作成・対象 Issue 紐付け手順を追加する必要がある。同時に既存の「サイクルラベル付与」記述を Milestone 紐付け手順に置換し、`cycle-label.sh` / `label-cycle-issues.sh` を deprecated 化する（物理削除は本サイクル対象外、後続サイクル Unit E）。

### 修正方針

以下 5 ファイルを更新する:

1. **`skills/aidlc/steps/inception/02-preparation.md`** ステップ16 周辺（L53-L62）: 「サイクルラベル付与」→「Milestone 紐付け（PATCH）」置換
2. **`skills/aidlc/steps/inception/05-completion.md`** ステップ1（L60-L86, 完了時の必須作業）+ エクスプレスモード ステップ2（L28-L30）: 「サイクルラベル作成・Issue 紐付け」→「Milestone 作成・Issue 紐付け」置換
3. **`skills/aidlc/steps/inception/index.md`** L33 / L113 / L208: ステップ説明・gh_status 表・契約テーブル exit_condition の「サイクルラベル」→「Milestone」更新
4. **`skills/aidlc/scripts/cycle-label.sh`** ヘッダコメントに DEPRECATED 注記追加
5. **`skills/aidlc/scripts/label-cycle-issues.sh`** ヘッダコメントに DEPRECATED 注記追加

### v2.4.0 自身の自己参照回避（Unit 定義 L20 準拠）

共有プロダクト（`skills/aidlc/steps/inception/`）の Markdown ステップは「v2.4.0 自身に適用しない」等のサイクル固有注記を持たない。v2.5.0 以降のすべてのサイクルで等しく適用される恒久手順として記述する。v2.4.0 自身の Milestone (#2) 作成と関連 Issue 紐付けは Inception Phase 運用タスク T1 で既に手動実施済み（実際の運用タスクは `.aidlc/cycles/v2.4.0/inception/decisions.md` および `story-artifacts/user_stories.md` 末尾「運用タスク T1」に閉じる）。

### Unit 007 への CHANGELOG 委譲（Unit 定義 L19 準拠）

CHANGELOG（v2.4.0 リリースノート）への両スクリプト deprecation 記載は **Unit 007 の受け入れ基準に委譲** する。本 Unit はスクリプトのヘッダコメントへの記述のみを担当し、Unit 007 の実装計画作成時に「本 Unit 005 で発生した CHANGELOG `#597` 節への deprecation 記載追加」を明示的に伝える。本 Unit の完了報告で:

> Unit 007 の責務追加: CHANGELOG `#597` 節に `cycle-label.sh` / `label-cycle-issues.sh` の deprecation 記載を追加する。

を明記する。

### 修正詳細

#### 02-preparation.md L53-L62 修正案

##### 修正前

```markdown
**サイクルラベル付与**（`gh_status` が `available` の場合、Issueを選択した後）:

選択したIssueにサイクルラベルを付与します。

\`\`\`bash
# 一括付与（Unit定義作成後に実行）
scripts/label-cycle-issues.sh {{CYCLE}}
\`\`\`

詳細は `guides/issue-management.md` を参照。
```

##### 修正後

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

注: 02-preparation.md ステップ16 の段階では Milestone が未作成の場合があるため、05-completion.md ステップ1 で確実に作成・紐付けする責任設計とする。02-preparation.md は「先行紐付け（既存 open Milestone がある場合のみ、`gh issue edit` のみ）」のオプショナル動作。

#### 05-completion.md L60-L86 修正案（完了時の必須作業 ステップ1）

##### 修正前

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

##### 修正後

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

#### 05-completion.md L28-L30 修正案（エクスプレスモード ステップ2）

##### 修正前

```markdown
### 2. サイクルラベル作成・Issue紐付け

「完了時の必須作業」のステップ1と同じ手順を実行する。
```

##### 修正後

```markdown
### 2. Milestone 作成・Issue 紐付け

「完了時の必須作業」のステップ1と同じ手順を実行する（1-1: Milestone 確認・作成 / 1-2: 関連 Issue への Milestone 一括紐付け）。
```

#### index.md L33 / L113 / L208 修正案

##### L33 修正前

```text
| `inception.05-completion` | 完了処理 | サイクルラベル、履歴記録、意思決定記録、ドラフト PR、squash、コミット、コンテキストリセット |
```

##### L33 修正後

```text
| `inception.05-completion` | 完了処理 | Milestone（v2.4.0以降）、履歴記録、意思決定記録、ドラフト PR、squash、コミット、コンテキストリセット |
```

##### L113 修正前

```text
| `available` | Issue 確認・バックログ確認・サイクルラベル付与・ドラフト PR 作成をすべて実行 |
```

##### L113 修正後

```text
| `available` | Issue 確認・バックログ確認・Milestone（v2.4.0以降）紐付け・ドラフト PR 作成をすべて実行 |
```

##### L208 修正前

```text
| `inception.05-completion` | `steps/inception/05-completion.md` | `inception.04-stories-units` 承認後 | サイクルラベル／履歴／意思決定記録／PR／squash／コミット／コンテキストリセット完了 | `on_demand` |
```

##### L208 修正後

```text
| `inception.05-completion` | `steps/inception/05-completion.md` | `inception.04-stories-units` 承認後 | Milestone（v2.4.0以降）／履歴／意思決定記録／PR／squash／コミット／コンテキストリセット完了 | `on_demand` |
```

#### cycle-label.sh ヘッダコメント追記案

L1 の `#!/usr/bin/env bash` の後、L19 の `set -euo pipefail` の前に以下を挿入:

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

#### label-cycle-issues.sh ヘッダコメント追記案

同様に、L1 の `#!/usr/bin/env bash` の後、`set -euo pipefail` の前に上記と同様の DEPRECATED 注記を挿入（スクリプト名のみ差し替え）。

## ファイル変更一覧

| ファイル | 変更内容 | 行数規模 |
|---------|---------|----------|
| `skills/aidlc/steps/inception/02-preparation.md` | L53-L62 のサイクルラベル付与記述を Milestone 紐付け（先行紐付け、既存時のみ）に置換 | -10 + 25 行 |
| `skills/aidlc/steps/inception/05-completion.md` | L60-L86 完了時必須ステップ1 を Milestone 作成・紐付け（1-1/1-2 構造）に置換、L28-L30 エクスプレス ステップ2 を整合更新 | -27 + 70 行 |
| `skills/aidlc/steps/inception/index.md` | L33 / L113 / L208 のサイクルラベル言及を Milestone（v2.4.0以降）に更新 | -3 + 3 行 |
| `skills/aidlc/scripts/cycle-label.sh` | ヘッダ DEPRECATED 注記追加（純コメント、機能変更なし） | +9 行 |
| `skills/aidlc/scripts/label-cycle-issues.sh` | ヘッダ DEPRECATED 注記追加（純コメント、機能変更なし） | +9 行 |

## 動作確認手順

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

## 境界遵守

- **CHANGELOG `#597` 節記載**: 本 Unit 対象外（Unit 007 の責務）。本 Unit 完了報告で「Unit 007 の受け入れ基準に CHANGELOG への deprecation 記載追加を依頼」を明記
- **Operations Phase 側 Milestone close**: Unit 006 の責務（並列）
- **ドキュメント側（docs/configuration.md / README.md / guides / rules.md）の更新**: Unit 007 の責務
- **`cycle-label.sh` / `label-cycle-issues.sh` の物理削除**: 本 Unit 対象外（後続サイクル Unit E）
- **過去 v2 サイクル（v2.0.0〜v2.3.5）の遡及 Milestone 化**: 本サイクル対象外（Unit D）
- **v2.4.0 自身の Milestone 作成・Issue 紐付け**: 運用タスク T1 で実施済み（本 Unit の自動化対象外）

## リスク評価

### 技術的リスク

- **Low-Medium**: `gh issue edit --milestone` が権限または環境差分で失敗するケース（ホスト/トークン構成・gh バージョン差・GitHub Enterprise 差等）が想定される → フォールバック `gh api --method PATCH` を Markdown 内に明示し、自動切り替えするよう設計
- **Low**: `gh api` の OWNER/REPO 解決を `gh repo view` から動的取得する手順は、リポジトリ移管時にも追従する設計
- **Low**: 02-preparation.md ステップ16 の「先行紐付け（既存時のみ）」は 05-completion ステップ1 で必ず再実行されるため、二重紐付けにはならない（GitHub 仕様で同じ Milestone への再紐付けは冪等）
- **Low**: Milestone 作成前に state=all で同名検索する 4 ケース判定（open≥2 / open=1 / closed≥1 / open=0 closed=0）により、重複作成や命名衝突を防止

### 運用リスク

- **Medium**: v2.5.0 以降の最初のサイクルで Markdown ステップ通りに Milestone 作成・紐付けが動くかは実運用で確認される（本 Unit の動作確認スコープ外）
- **Low**: `cycle-label.sh` / `label-cycle-issues.sh` の参照箇所を `grep -rn "cycle-label.sh\|label-cycle-issues.sh"` で確認:
  - **本 Unit が更新する**: Inception ステップ（`02-preparation.md` / `05-completion.md` / `index.md`）+ スクリプト本体ヘッダ
  - **Unit 007 が更新する**: ガイド（`guides/issue-management.md` / `guides/backlog-management.md`）
  - **既存 CHANGELOG（過去サイクル）**: `CHANGELOG.md` 内に複数の過去言及あり（v1.x〜v2.x の各サイクルでの新規追加・拡張記録）。これらは履歴であり修正対象外
  - **CI / GitHub Actions / 自動化スクリプト**: 呼び出しなし（`grep -rn` で確認、`.github/workflows/` 配下にも記述なし）

### 将来的な技術的負債

- **Note**: deprecated スクリプトの物理削除（Unit E）は v2.5.0 以降のバックログ Issue で別扱い。それまでは併存（呼び出し元削除済みのため副作用なし）

## 関連 Issue

- #597（部分対応：Unit B 担当部分。Unit A は Unit 006、Unit C は Unit 007）
