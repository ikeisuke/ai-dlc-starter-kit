# Inception Phase - 完了処理

## 実行ルール

1. **計画作成**: 各ステップ開始前に計画ファイルを `.aidlc/cycles/{{CYCLE}}/plans/` に作成
2. **ユーザーの承認【重要】**: 計画ファイルのパスを提示し「この計画で進めてよろしいですか？」と明示的に質問、承認を待つ
3. **実行**: 承認後に実行

---

## 完了基準

- すべての成果物作成（Intent、ユーザーストーリー、Unit定義）
- 技術スタック決定（greenfieldの場合）
- **コンテキストリセットの提示完了**（ユーザーが連続実行を明示指示した場合はスキップ可）

---

## エクスプレスモード完了処理【ステップ4bでエクスプレスモード有効時のみ】

ステップ4b でエクスプレスモードが有効と判定された場合、以下の簡略完了処理を実行してから Construction Phase に自動遷移する。エクスプレスモードが無効の場合はこのセクションをスキップし、「完了時の必須作業」セクションへ進む。

### 1. progress.md 更新

- `depth_level=minimal` の場合: ステップ5（PRFAQ）を「スキップ」に更新する（Depth Level仕様でスキップ可能のため）
- `depth_level=standard/comprehensive` の場合: ステップ5（PRFAQ）はステップ4bの後に実行され、完了後にこのセクションに到達するため、progress.md で「完了」を確認するのみ

### 2. Milestone 作成・Issue 紐付け

「完了時の必須作業」のステップ1と同じ手順を実行する（1-1: Milestone 確認・作成 / 1-2: 関連 Issue への Milestone 一括紐付け）。

### 3. 履歴記録

`/write-history` スキルで記録（`--step "Inception Phase完了（エクスプレスモード）"`）。

### 4-5. Squash・Gitコミット

「完了時の必須作業」のステップ6（Squash）・ステップ7（Gitコミット）と同じ手順を実行する。squash結果に応じてコミットをスキップまたは実行。

**コミット失敗時**: `commit-flow.md` の手順に沿った手動コミットを案内する。

### 6. Construction Phase への自動遷移

コンテキストリセット提示を**スキップ**し、Construction Phase に自動遷移する。

```text
【エクスプレスモード】Inception Phase 完了。Construction Phase に自動遷移します。
```

SKILL.md の引数ルーティングに従い、Construction Phase を開始する（`/aidlc construction` を実行）。`automation_mode` の設定はそのまま引き継がれる。

**注意**: エクスプレスモードでの Construction Phase 遷移時、construction.md の「最初に必ず実行すること」は通常通り実行する（サイクル存在確認、進捗状況確認等）。Phase 1（設計）の扱いは depth_level に従う:
- `depth_level=minimal`: Phase 1 スキップ可能（construction.md の既存仕様に従う）
- `depth_level=standard/comprehensive`: Phase 1 は通常実行（設計省略しない）

---

## 完了時の必須作業【重要】

### 1. Milestone 作成・Issue 紐付け

**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

```bash
MILESTONE_ENABLED=$(scripts/read-config.sh rules.github.milestone_enabled 2>/dev/null || echo "false")
```

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合: メッセージ `milestone:disabled:skip:step=05-completion-step1:reason=opt-out` を出力し、**本ステップ（1-1 Milestone 確認・作成 + 1-2 関連 Issue 一括紐付け）をすべてスキップ**して次のステップ（履歴記録等）へ進む。後続の `gh_status` 判定および Milestone 作成・紐付け bash 群は **一切実行しない**
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定 + 1-1 Milestone 確認・作成 + 1-2 関連 Issue 一括紐付けを実行する

`gh_status` を参照する。

**判定と処理**:

`gh_status` が `available` 以外の場合: 「警告: GitHub CLIが利用できないため、スキップします」と表示してスキップ。

`gh_status` が `available` の場合、以下の手順を実行:

#### 1-1. Milestone 確認・作成

```bash
# 1. OWNER/REPO 動的解決
OWNER=$(gh repo view --json owner --jq .owner.login)
REPO=$(gh repo view --json name --jq .name)

# 2. Milestone 一覧（state=all）から {{CYCLE}} を検索（同名 closed 検出のため state=all）
MILESTONE_LOOKUP=$(gh api "repos/$OWNER/$REPO/milestones?state=all" \
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
  MILESTONE_NUMBER=$(gh api --method POST "repos/$OWNER/$REPO/milestones" \
    -f title="{{CYCLE}}" \
    --jq .number)
  echo "milestone:{{CYCLE}}:created:number=$MILESTONE_NUMBER"
fi
```

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

```bash
# Unit 定義から関連 Issue 番号を抽出
# - 抽出ロジックは旧 label-cycle-issues.sh の extract_issue_numbers() に基づく
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
  # 各 Issue を Milestone に紐付け（既存 Milestone がある場合は付け替えず警告のみ、Operations 01-setup ステップ 11 と同じ冪等補完原則）
  echo "$ISSUE_NUMBERS" | while read -r ISSUE; do
    if [ -z "$ISSUE" ]; then continue; fi
    # 既存 Milestone を確認（1 Issue = 1 Milestone 制約のため、付け替えは行わない）
    CURRENT_MILESTONE=$(gh issue view "$ISSUE" --json milestone --jq '.milestone.title // empty')
    if [ -n "$CURRENT_MILESTONE" ] && [ "$CURRENT_MILESTONE" != "{{CYCLE}}" ]; then
      echo "WARNING: issue:$ISSUE は他の Milestone （$CURRENT_MILESTONE）に紐付け済みです。1 Issue = 1 Milestone 制約のため、付け替えが必要な場合は (a) 新サイクルへ付け替え / (b) Backlog に戻して保持 の 2 択をユーザーに確認してから手動で付け替えてください" >&2
      echo "issue:$ISSUE:other-milestone:current=$CURRENT_MILESTONE:skip-overwrite"
      continue
    elif [ "$CURRENT_MILESTONE" = "{{CYCLE}}" ]; then
      echo "issue:$ISSUE:already-linked:milestone={{CYCLE}}"
      continue
    fi
    # empty Milestone の場合のみ新規紐付け
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
```

**フォールバック手順**: `gh issue edit --milestone` が **権限または環境差分で失敗する場合** は `gh api --method PATCH` を必ず使用する。具体的なエラー時のみ自動的に PATCH に切り替わる。

**1 Issue = 1 Milestone 制約**（GitHub 仕様）: Issue が既に他サイクルの Milestone に紐付いている場合、**自動では付け替えず、警告のみ出力してスキップ**する（Operations 01-setup ステップ 11 と同じ冪等補完原則）。サイクル持ち越し時は (a) 新サイクルへ付け替え / (b) Backlog に戻して保持 の 2 択をユーザーに確認してから手動で付け替えること。

**出力例**:

```text
milestone:v1.8.0:created:number=5
issue:81:linked:milestone=v1.8.0
issue:72:linked:milestone=v1.8.0
```

**注**: Issue 番号が見つからない場合は Milestone 作成のみ行い、紐付けはスキップする（出力 `milestone:created` + `milestone:no-issues-to-link`）。

### 2. iOSバージョン更新【project.type=iosの場合のみ】

`.aidlc/config.toml` の `[project].type` が `ios` の場合のみ実行。詳細手順は `guides/ios-version-update.md` を参照。

### 3. 履歴記録
`/write-history` スキルで `.aidlc/cycles/{{CYCLE}}/history/inception.md` に追記。

### 4. 意思決定記録【必須チェック】

**このステップのスキップは禁止。記録対象の有無を必ず確認すること。記録対象がなければスキップ（ファイル未作成で問題なし）だが、確認自体を省略してはいけない。**

Inception Phase 中に重要な意思決定（AIが複数の選択肢を提示し、ユーザーが選択した場面）があった場合、`.aidlc/cycles/{{CYCLE}}/inception/decisions.md` に記録する。

**記録対象**:
- 2つ以上の明確な選択肢からユーザーが選択した場面
- 技術選定、設計方針、スコープ決定などの重要な判断

**記録対象外**:
- Yes/No の単純な承認確認
- 手続き的な選択（ブランチ方式、ファイル名等）

**手順**:
1. セッション中に発生した意思決定を振り返る
2. 記録対象に該当するものがあれば、テンプレート（`templates/decision_record_template.md`）に従い `decisions.md` を作成
3. 記録IDは連番（DR-001, DR-002, ...）
4. 記録対象がなければ「意思決定記録: 対象なし」と明示的に報告してスキップ（ファイル未作成で問題なし）

### 5. ドラフトPR作成【推奨】

> 分岐判定ロジック（`resolveDraftPrAction`、正規化契約）は `steps/inception/index.md` §2.7.1 を参照。本ステップは判定結果の `action` に応じた実行手順のみを持つ。

**ステップ5a. gh_status 判定**:
- **`gh_status` が `available` 以外**: `action=skip_unavailable`
  ```text
  GitHub CLIが利用できないため、ドラフトPR作成をスキップします。
  必要に応じて、後で手動でPRを作成してください。
  ```
  → `read-config.sh` は実行せずステップ5を終了

**ステップ5b. draft_pr 取得・正規化**（`gh_status=available` の場合のみ）:

```bash
scripts/read-config.sh rules.git.draft_pr
```

`index.md` §2.7.1 の正規化契約に従い、`draft_pr_effective` と `decision_source` を決定する。`decision_source` が `explicit` 以外の場合、対応する警告メッセージを表示する。

**ステップ5c. 既存PR確認**（`draft_pr_effective` が `never` 以外の場合）:

1. 事前にBashで `git branch --show-current` を実行し、現在のブランチ名を取得
2. 取得したブランチ名を使って以下を実行:

```bash
gh pr list --head "<取得したブランチ名>" --state open
```

- **既存PRあり**: `action=skip_existing_pr` → 既存PRのURLを表示し、新規作成をスキップ

**ステップ5d. action に応じた実行**（`index.md` §2.7.1 `resolveDraftPrAction` の結果に従う）。**出力**: `action`（DraftPrAction）+ `user_confirmation`（`ask_user` 時のみ: `true`=はい / `false`=いいえ）:

- **`skip_never`**: 以下を表示してスキップ
  ```text
  draft_pr=never のため、ドラフトPR作成をスキップします。
  ```

- **`ask_user`**: ユーザーに確認（`AskUserQuestion`）
  ```text
  ドラフトPRを作成しますか？

  ドラフトPRを作成すると：
  - 進捗がGitHub上で可視化されます
  - 複数人での並行作業が容易になります
  - Unit単位でのレビューが可能になります

  1. はい - ドラフトPRを作成する
  2. いいえ - スキップする（後で手動で作成可能）
  ```

- **`create_draft_pr`**: ユーザー確認なしでPR作成に進む

**ステップ5d-1. 設定保存フロー【ユーザー選択】**（**入力**: `action` + `user_confirmation`。`action` が `ask_user` の場合のみ実行。`skip_never` / `create_draft_pr` ではスキップ）:

本確認は SKILL.md「AskUserQuestion 使用ルール」の「ユーザー選択」種別のため、`automation_mode` に関わらず `AskUserQuestion` 必須（詳細は SKILL.md 参照）。

ステップ5dでユーザーが選択した後、`AskUserQuestion` で「この選択を設定に保存しますか？」と確認:

- **いいえ（今回のみ使用） (Recommended)**: 保存せず、今回の選択のみ使用して続行
- **はい（保存する）**: 保存先を選択（デフォルト: `config.local.toml`（個人設定）、代替: `config.toml`（プロジェクト共有））
  ```bash
  scripts/write-config.sh rules.git.draft_pr "<always|never>" --scope <local|project>
  ```
  成功時: 「設定を保存しました」と表示。失敗時: 警告表示して続行

保存値マッピング: ステップ5dのユーザー選択（PR 作成の可否）「はい（作成）」→ `always` / 「いいえ（作成しない）」→ `never` に変換した値を保存する。

**ステップ5e. PR作成実行**（**入力**: `action` + `user_confirmation`。`action` が `ask_user` の場合はステップ5d-1完了後、`action` が `create_draft_pr` の場合はステップ5d完了後に実行。`action` が `create_draft_pr`、または `action` が `ask_user` かつ `user_confirmation=true` の場合のみ実行）:

**関連Issue番号の抽出**:
Unit定義ファイルの「関連Issue」セクションから、全Issue番号を抽出し、`Closes #XX` 形式でリスト化します。

1. Writeツールで一時ファイルを作成（テンプレート: `templates/inception_pr_body_template.md` を参照）

2. 以下を実行:

```bash
gh pr create --draft \
  --title "サイクル {{CYCLE}}" \
  --body-file <一時ファイルパス>
```

3. 一時ファイルを削除

**注意**: PRがmainにマージされると、`Closes #XX` に記載されたIssueは自動的にクローズされます。

**成功時**:
```text
ドラフトPRを作成しました：
[PR URL]

このPRはOperations Phase完了時にReady for Reviewに変更されます。
```

### 6. Squash（コミット統合）【オプション】

**【次のアクション】** `steps/common/commit-flow.md` の「Squash統合フロー」を読み込んで、Inception Phase完了squashの手順に従ってください。

- `squash:success` の場合: ステップ7をスキップ
- `squash:skipped:no-commits` の場合: ステップ7に進む
- `squash:error` の場合: commit-flow.mdのエラーリカバリ手順に従う。リカバリ後、ステップ7（通常コミット）に進む

### 7. Gitコミット

`squash:success` なら `git status` 確認のみ。それ以外は `commit-flow.md` の「Inception Phase完了コミット」に従う。

### 8. 完了サマリ出力【必須】

以下の完了サマリを出力する。※ 情報源にない内容は出力しない。

```text
【Inception Phase 完了サマリ】
- サイクル: {{CYCLE}}
- 作成した成果物:
  - Intent: [intent.mdの概要（1行）]
  - ユーザーストーリー: [ストーリー数]件
  - Unit定義: [Unit数]件（[Unit名の一覧]）
- 技術スタック: [決定内容。該当しなければ「該当なし」]
- 関連Issue: [Issue番号の一覧。なければ「なし」]
- 残課題・バックログ: [登録したバックログIssue番号。なければ「なし」]
```

### 9. コンテキストリセット提示【必須】

`semi_auto`: スキップしConstruction Phaseを自動開始。`manual`: ユーザーの明示的な連続実行指示（「続けて」等）がない限り、以下を実行（デフォルトはリセット）。

セッションサマリ（サイクル番号、ブランチ/PR状態、次のアクション）を収集し、テンプレート（`templates/context_reset_template.md`）に従い出力する。
