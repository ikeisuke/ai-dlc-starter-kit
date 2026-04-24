# Unit 006 計画: Operations Phase へ Milestone close + 紐付け確認 + fallback 作成を組込み

## 対象 Unit

- **Unit ファイル**: `.aidlc/cycles/v2.4.0/story-artifacts/units/006-operations-milestone-close.md`
- **担当ストーリー**: ストーリー 2（Operations での Milestone close + 紐付け確認、Unit A 由来）
- **関連 Issue**: #597（Unit A 担当部分）
- **依存 Unit**: なし（Unit 005 と並列、Unit 005 は完了済み）
- **見積もり**: 3〜4 時間

## 課題と修正方針

### 課題

GitHub Milestone 運用本採用（#597）の Operations Phase 側として、サイクル完了時の Milestone close + 関連 PR/Issue の Milestone 紐付け確認 + Inception スキップ漏れ等で Milestone 不在時の fallback 作成手順を Markdown ステップに追加する。マージ前完結ルール（v2.3.5 / Unit 002）と整合させる必要がある。

### 修正方針

以下 3 ファイルを更新する:

1. **`skills/aidlc/steps/operations/01-setup.md`** ステップ10 (Construction 引き継ぎタスク確認) の後に、新規ステップ11「Milestone 紐付け確認・fallback 判定」を追加
2. **`skills/aidlc/steps/operations/04-completion.md`** ステップ5 (PRマージ後の手順) の通常環境フロー / worktreeフローの後（バージョンタグ付け / ブランチ削除完了後）に、Milestone close 手順を追加
3. **`skills/aidlc/steps/operations/index.md`** §2.8 「gh_status 分岐」表を 2 行 → 3 行に拡張し、補助契約として「`gh_status = available` 時の Milestone 紐付け補完失敗」を追記。Milestone close 例外契約（`gh_status != available` で exit 1）と紐付け補完失敗契約（`LINK_FAILED >= 1` で exit 1）を中央契約として明記する（実装ステップ・index・plan のトレーサビリティ確保）

### 配置検討

| 候補 | 配置先 | 理由 | 採否 |
|------|-------|------|------|
| (A) 01-setup.md 新規ステップ11 | Milestone 紐付け確認 + fallback 判定 | Operations 開始時にサイクル状態の整合性を確認 | **採用** |
| (B) 04-completion.md ステップ5 末尾 | Milestone close（マージ後） | マージ前完結ルール準拠（cycle ブランチ配下ファイル更新せず GitHub 側操作のみ） | **採用** |
| (C) operations-release.md §7.6 | progress.md 固定スロット反映と一緒に Milestone close | マージ前完結ルールに反する（マージ前に Milestone close するとリリース未完了状態と乖離） | 不採用 |
| (D) 02-deploy.md / 03-release.md | 02-deploy はデプロイ実作業、03-release は短い | 実装上の論理的接合点なし | 不採用 |

### マージ前完結ルールとの整合確認

`04-completion.md` L40-L55 「マージ前完結ルール」では、PR マージ後の `.aidlc/cycles/{{CYCLE}}/**` 配下ファイル改変は禁止される。本 Unit の Milestone close は GitHub 側操作（`gh api PATCH milestones`）のため、cycle ブランチ配下のファイルには影響しない。`write-history.sh` ガード（exit 3）にも影響しない。よって、ステップ5 (PRマージ後の手順) の通常環境フロー / worktreeフロー完了後の追加ステップとして配置可能。

### 修正詳細

#### 01-setup.md ステップ10 の後に新規ステップ11 を追加

##### 挿入位置

L121-L127（ステップ10「Construction 引き継ぎタスク確認」）の直後、L128 の `---` 区切りの直前。

##### 挿入内容

```markdown
### 11. Milestone 紐付け確認・fallback 判定【重要】

**`gh_status` を参照する。**

`gh_status` が `available` 以外の場合: 「警告: GitHub CLIが利用できないため、Milestone 紐付け確認をスキップします」と表示してスキップ。

`gh_status` が `available` の場合、以下の手順を実行:

#### 11-1. Milestone 状態確認（5 ケース判定 + fallback 作成）

```bash
# 1. OWNER/REPO 動的解決
OWNER=$(gh repo view --json owner --jq .owner.login)
REPO=$(gh repo view --json name --jq .name)

# 2. Milestone 一覧（state=all）から {{CYCLE}} を検索
MILESTONE_LOOKUP=$(gh api "repos/$OWNER/$REPO/milestones?state=all" \
  --jq "[.[] | select(.title == \"{{CYCLE}}\") | {number, state}]")

OPEN_COUNT=$(echo "$MILESTONE_LOOKUP" | jq '[.[] | select(.state == "open")] | length')
CLOSED_COUNT=$(echo "$MILESTONE_LOOKUP" | jq '[.[] | select(.state == "closed")] | length')

# 3. 5 ケース判定（ストーリー 2 受け入れ基準の優先順位通り、最初に該当した規則のみを適用）
if [ "$CLOSED_COUNT" -ge 1 ]; then
  # closed 1 件以上 → エラー停止（誤再オープンを避けるため、手動判断を要求）
  echo "ERROR: Milestone {{CYCLE}} の closed が ${CLOSED_COUNT} 件あります。同名 closed Milestone がある場合の意図確認を必須化（誤再オープン防止）。手動確認: gh api repos/$OWNER/$REPO/milestones?state=all" >&2
  exit 1
elif [ "$OPEN_COUNT" -ge 2 ]; then
  # open 2 件以上 → エラー停止（手動修正が必要）
  echo "ERROR: Milestone {{CYCLE}} の open が ${OPEN_COUNT} 件あります。重複候補を確認: gh api repos/$OWNER/$REPO/milestones?state=all" >&2
  exit 1
elif [ "$OPEN_COUNT" -eq 1 ]; then
  # open 1 件 → 再利用
  MILESTONE_NUMBER=$(echo "$MILESTONE_LOOKUP" | jq '.[] | select(.state == "open") | .number')
  echo "milestone:{{CYCLE}}:exists:number=$MILESTONE_NUMBER"
else
  # open 0 / closed 0 → fallback 作成（Inception スキップ漏れを救済）
  echo "WARNING: Milestone {{CYCLE}} が不在です。Inception スキップ漏れの可能性があります。fallback で作成します。"
  MILESTONE_NUMBER=$(gh api --method POST "repos/$OWNER/$REPO/milestones" \
    -f title="{{CYCLE}}" \
    --jq .number)
  echo "milestone:{{CYCLE}}:fallback-created:number=$MILESTONE_NUMBER"
fi
```

#### 11-2. 関連 Issue/PR の Milestone 紐付け確認・補完

Operations 開始時点で、関連 Issue/PR がすべて Milestone に紐付いているかを確認し、不足分を補完する:

```bash
# Unit 定義から関連 Issue 番号を抽出（Inception で同一 awk ロジックを使用）
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

# 各 Issue の現在の Milestone 紐付け状態を確認し、3 分岐で処理（不足時のみ PATCH、付け替えは行わない）
# 失敗 ID は LINK_FAILED に蓄積し、ステップ11 末尾で集約判定する
LINK_FAILED=""
if [ -n "$ISSUE_NUMBERS" ]; then
  while read -r ISSUE; do
    if [ -z "$ISSUE" ]; then continue; fi
    CURRENT_MILESTONE=$(gh issue view "$ISSUE" --json milestone --jq '.milestone.title // empty')
    if [ -z "$CURRENT_MILESTONE" ]; then
      # 1. empty → 不足のため追加紐付け（gh api PATCH で確実に Milestone 番号を指定）
      if gh api --method PATCH "repos/$OWNER/$REPO/issues/$ISSUE" -F milestone=$MILESTONE_NUMBER 2>/dev/null; then
        echo "issue:$ISSUE:linked:milestone={{CYCLE}}:via-api"
      else
        echo "issue:$ISSUE:link-failed" >&2
        LINK_FAILED="${LINK_FAILED}issue:$ISSUE "
      fi
    elif [ "$CURRENT_MILESTONE" = "{{CYCLE}}" ]; then
      # 2. {{CYCLE}} → 既に紐付け済み（冪等、何もしない）
      echo "issue:$ISSUE:already-linked:milestone={{CYCLE}}"
    else
      # 3. 他 Milestone → 警告のみ（付け替えは Inception 持ち越し時の判断、Unit 005 の手順または運用タスクに委譲）
      echo "WARNING: issue:$ISSUE は他の Milestone （$CURRENT_MILESTONE）に紐付け済みです。1 Issue = 1 Milestone 制約のため、付け替えが必要な場合は Inception の手順 (a) 新サイクルへ付け替え / (b) Backlog に戻して保持 の判断を Operations 担当者に委ねます" >&2
      echo "issue:$ISSUE:other-milestone:current=$CURRENT_MILESTONE:skip-overwrite"
    fi
  done <<< "$ISSUE_NUMBERS"
fi
```

**注**: `while ... <<< "$ISSUE_NUMBERS"` を使用するのは、`echo ... | while` だとサブシェルで `LINK_FAILED` 変数が親シェルに伝播しないため。bash here-string で同シェルコンテキストを維持し、ステップ11 末尾の集約判定（exit 1）を可能にする。

**注**: `gh issue edit --milestone` ではなく `gh api PATCH` を使用するのは、Operations 開始時点では Inception で既に紐付け済みケースが多く、確実に Milestone 番号を指定するため。**冪等補完原則**: 既存 Milestone がある Issue/PR は付け替えず、empty の Issue/PR のみに新規紐付けを行う（Unit 定義 NFR 「1 Issue = 1 Milestone 制約に整合」と整合）。

#### 11-3. PR の Milestone 紐付け確認

```bash
# 現在のブランチに紐づく PR を取得
PR_NUMBER=$(gh pr list --head "$(git branch --show-current)" --state open --json number --jq '.[0].number // empty')

if [ -n "$PR_NUMBER" ]; then
  PR_MILESTONE=$(gh pr view "$PR_NUMBER" --json milestone --jq '.milestone.title // empty')
  if [ -z "$PR_MILESTONE" ]; then
    # 1. empty → 不足のため追加紐付け
    if gh api --method PATCH "repos/$OWNER/$REPO/issues/$PR_NUMBER" -F milestone=$MILESTONE_NUMBER 2>/dev/null; then
      echo "pr:$PR_NUMBER:linked:milestone={{CYCLE}}:via-api"
    else
      echo "pr:$PR_NUMBER:link-failed" >&2
      LINK_FAILED="${LINK_FAILED}pr:$PR_NUMBER "
    fi
  elif [ "$PR_MILESTONE" = "{{CYCLE}}" ]; then
    # 2. {{CYCLE}} → 既に紐付け済み（冪等、何もしない）
    echo "pr:$PR_NUMBER:already-linked:milestone={{CYCLE}}"
  else
    # 3. 他 Milestone → 警告のみ（付け替えは判断ポイント、Operations 担当者に委ねる）
    echo "WARNING: pr:$PR_NUMBER は他の Milestone （$PR_MILESTONE）に紐付け済みです。1 Issue = 1 Milestone 制約のため、付け替えが必要な場合は Operations 担当者に委ねます" >&2
    echo "pr:$PR_NUMBER:other-milestone:current=$PR_MILESTONE:skip-overwrite"
  fi
else
  echo "pr:not-found-or-not-open"
fi

# ステップ11 末尾集約判定: 補完失敗があれば exit 1（後段 04-completion 5.5 を実施しない契約）
if [ -n "$LINK_FAILED" ]; then
  echo "ERROR: Milestone 紐付け補完に失敗した対象があります: $LINK_FAILED" >&2
  echo "ERROR: 失敗対象を手動で復旧してから本ステップを再実行してください（または .aidlc/cycles/{{CYCLE}}/operations/tasks/ に手動対応タスクを作成）。link-failed が解消するまで 04-completion ステップ5.5 (Milestone close) は実施しないでください。" >&2
  exit 1
fi
```

**注**: PR も Issue API で Milestone 操作可能（GitHub 仕様、PR は Issue の特殊形）。**冪等補完原則**: Issue 同様、empty の場合のみ新規紐付け、他 Milestone がある場合は付け替えず警告のみ。**集約判定契約**: link-failed が 1 件以上ある場合は exit 1 で中断し、04-completion 5.5 (Milestone close) は実施しない契約とする（紐付け未達のまま close するとサイクル可視化が不完全になるため）。

**判定マトリクス**（5 ケース、ストーリー 2 受け入れ基準準拠、Unit 005 と同じ 5 行表記で揃える）:

| open 件数 | closed 件数 | 動作 |
|----------|-----------|------|
| ≥ 2 | 0 | エラー停止（重複作成、手動整理を要求） |
| 1 | 0 | 再利用（既存 open を使用） |
| 0 | 0 | **fallback 作成**（Inception スキップ漏れ救済、警告メッセージ表示） |
| 0 | ≥ 1 | エラー停止（誤再オープン防止、手動判断要求） |
| ≥ 1 | ≥ 1 | エラー停止（混在、誤再オープン防止 / 優先順位 1 と整合） |

実装側では `CLOSED_COUNT >= 1` を最優先停止条件としており、この優先順位はストーリー 2 受け入れ基準 L40-L44 と完全一致（4 段階優先順位で 5 ケースを畳み込んで表現）。
```

##### Unit 005 と Unit 006（setup 11-1 / completion 5.5）の 5 ケース判定差分

**一文要約**: 3 配置とも 5 ケース判定基盤は同一だが、配置ごとに 2 ケースの動作が異なる: `open=0,closed=0` は Unit 005 = 通常作成 / Unit 006 setup 11-1 = fallback 作成 / Unit 006 completion 5.5 = エラー停止、`open=0,closed=1` は Unit 005 / Unit 006 setup 11-1 = エラー停止 / Unit 006 completion 5.5 = already-closed 成功扱い。

| ケース | Unit 005（Inception 完了時, 1-1） | Unit 006 setup 11-1（Operations 開始時） | Unit 006 completion 5.5（Operations 完了時） |
|--------|----------------------------------|---------------------------------------|------------------------------------------|
| open=0 closed=0 | 通常作成 (`:created`) | **fallback 作成** (`:fallback-created` + 警告) | **エラー停止** (`ERROR + exit 1`) |
| open=0 closed=1 | エラー停止（誤再オープン防止） | エラー停止（誤再オープン防止） | **already-closed 成功扱い** (`:already-closed:number=N`、二重 close 回避) |
| open=1 closed=0 | 既存再利用 | 既存再利用 | close 実行 (`:closed:number=N`) |
| open≥2 / 混在 / closed≥2 | エラー停止 | エラー停止 | エラー停止 |

#### 04-completion.md ステップ5 末尾に Milestone close 手順を追加

##### 挿入位置

L173-L181（ステップ5 「マージ済みブランチの削除」と「注意: この手順を実行してから次サイクルのセットアップを開始してください」）の後、L183 「### 6. 完了サマリ出力」の直前。新規ステップとして「### 5.5 Milestone close」相当（または通常環境フロー内 ステップ5 として）を追加。

選択: `### 5.5 Milestone close【マージ前完結契約準拠】` として独立節を新設（既存ステップ番号構造を維持）。

##### 挿入内容

```markdown
### 5.5 Milestone close【マージ前完結契約準拠】

**マージ完了後、サイクル完了の可視化として GitHub Milestone を close する**。マージ前完結契約（v2.3.5 / Unit 002）に従い、本ステップは GitHub 側操作のみで `.aidlc/cycles/{{CYCLE}}/**` 配下のファイルは更新しない。

`gh_status` を参照する。

`gh_status` が `available` 以外の場合: 以下のメッセージを表示し **exit 1 で中断する**（Milestone close 未実施のままサイクル完了させない）:

```text
ERROR: GitHub CLI が利用できないため Milestone close を実行できません。
gh CLI / 認証を復旧してから 5.5 を再実行してください。

gh 非依存の手動代替手順（CLI 復旧が困難な場合のみ）:
1. https://github.com/OWNER/REPO/milestones を開き、{{CYCLE}} の number を確認
2. REST API 直叩き（`curl -X PATCH -H "Authorization: token <PAT>" \
   -H "Accept: application/vnd.github+json" \
   https://api.github.com/repos/OWNER/REPO/milestones/<number> \
   -d '{"state":"closed"}'）または GitHub UI 上で Milestone を Close
3. 再実行不要（手動完了後、本ステップをスキップ可）
```

`gh_status` が `available` の場合、以下を実行:

```bash
# 1. OWNER/REPO 動的解決
OWNER=$(gh repo view --json owner --jq .owner.login)
REPO=$(gh repo view --json name --jq .name)

# 2. Milestone 一覧（state=all）を取得（01-setup ステップ11-1 と同じ判定基盤）
MILESTONE_LOOKUP=$(gh api "repos/$OWNER/$REPO/milestones?state=all" \
  --jq "[.[] | select(.title == \"{{CYCLE}}\") | {number, state}]")

OPEN_COUNT=$(echo "$MILESTONE_LOOKUP" | jq '[.[] | select(.state == "open")] | length')
CLOSED_COUNT=$(echo "$MILESTONE_LOOKUP" | jq '[.[] | select(.state == "closed")] | length')

# 3. 5 ケース判定（ストーリー 2 受け入れ基準の優先順位通り、setup 側 11-1 と同じ判定基盤）
if [ "$CLOSED_COUNT" -eq 1 ] && [ "$OPEN_COUNT" -eq 0 ]; then
  # closed=1 && open=0 → 既に close 済み（成功扱い、二重 close を回避）
  CLOSED_NUMBER=$(echo "$MILESTONE_LOOKUP" | jq '.[] | select(.state == "closed") | .number')
  echo "milestone:{{CYCLE}}:already-closed:number=$CLOSED_NUMBER"
elif [ "$CLOSED_COUNT" -ge 1 ]; then
  # closed≥1 残ケース（closed≥2 || closed≥1 && open≥1 混在）→ エラー停止（誤再オープン防止 + 多重 closed 検出）
  echo "ERROR: Milestone {{CYCLE}} の closed が ${CLOSED_COUNT} 件 + open が ${OPEN_COUNT} 件あります（多重 closed または混在状態）。同名 closed Milestone がある場合の意図確認を必須化（誤再オープン防止）。手動確認: gh api repos/$OWNER/$REPO/milestones?state=all" >&2
  exit 1
elif [ "$OPEN_COUNT" -ge 2 ]; then
  # open≥2 → エラー停止（重複、複数 number が返る異常系を握りつぶさない）
  echo "ERROR: Milestone {{CYCLE}} の open が ${OPEN_COUNT} 件あります（重複作成の可能性）。重複候補を確認: gh api repos/$OWNER/$REPO/milestones?state=all" >&2
  exit 1
elif [ "$OPEN_COUNT" -eq 1 ]; then
  # open=1 && closed=0 → close 実行
  MILESTONE_NUMBER=$(echo "$MILESTONE_LOOKUP" | jq '.[] | select(.state == "open") | .number')
  if gh api "repos/$OWNER/$REPO/milestones/$MILESTONE_NUMBER" --method PATCH -f state=closed --jq '.state' 2>/tmp/milestone-close-error.log; then
    echo "milestone:{{CYCLE}}:closed:number=$MILESTONE_NUMBER"
  else
    ERROR_DETAIL=$(cat /tmp/milestone-close-error.log)
    echo "ERROR: Milestone close 失敗: $ERROR_DETAIL。手動で次のコマンドを実行してください: gh api repos/$OWNER/$REPO/milestones/$MILESTONE_NUMBER --method PATCH -f state=closed" >&2
    rm -f /tmp/milestone-close-error.log
    exit 1
  fi
  rm -f /tmp/milestone-close-error.log
else
  # open=0 && closed=0 → エラー停止（運用異常、誤った成功扱いを避ける）
  echo "ERROR: Milestone {{CYCLE}} が見つかりません（open / closed のいずれにも存在しない）。01-setup.md ステップ11 の fallback 作成が未実行 or 手動作業漏れの可能性。手動確認: gh api repos/$OWNER/$REPO/milestones?state=all" >&2
  exit 1
fi
```

**5 ケース判定マトリクス（5.5 完了処理、相互排他の 5 行）**:

| open 件数 | closed 件数 | 動作 |
|----------|-----------|------|
| ≥ 1 | ≥ 1 | エラー停止（混在、誤再オープン防止 / 優先順位 1 と整合） |
| ≥ 2 | 0 | エラー停止（重複作成、手動修正要求） |
| 1 | 0 | close 実行 |
| 0 | 0 | エラー停止（運用異常、setup 側 fallback 未実行 or 手動漏れ） |
| 0 | 1（厳密に 1） | already-closed（二重 close 回避、成功扱い） |

`closed≥2 && open=0` は実装側 `elif [ "$CLOSED_COUNT" -ge 1 ]` 分岐でエラー停止（多重 closed 検出）。

判定ロジックは setup 側 11-1 と同じ判定基盤を使うが、completion では `open=0,closed=1` を成功扱い、`open=0,closed=0` をエラー扱いに変える点だけが setup と異なる。

**フォールバック手順**: `gh api` 失敗時（HTTP 4xx/5xx）は close 操作を中断し、警告メッセージで手動コマンドを案内する（誤った成功扱いを避ける）。

**マージ前完結契約との整合**: 本ステップは GitHub 側操作のみ。`.aidlc/cycles/{{CYCLE}}/**` 配下のファイル（progress.md / history / 成果物）は更新しない。`write-history.sh` ガード（exit 3）にも影響しない。

**期待出力例**:

```text
milestone:v2.4.0:closed:number=2
```
```

## ファイル変更一覧

| ファイル | 変更内容 | 行数規模 |
|---------|---------|----------|
| `skills/aidlc/steps/operations/01-setup.md` | ステップ10 の後（L127）にステップ11「Milestone 紐付け確認・fallback 判定」を新規追加（11-1: 5 ケース判定 + fallback 作成 / 11-2: Issue 紐付け補完 + LINK_FAILED 蓄積 / 11-3: PR 紐付け補完 + ステップ11 末尾集約判定 exit 1） | +130 行 |
| `skills/aidlc/steps/operations/04-completion.md` | ステップ5 末尾（L181）にステップ5.5「Milestone close」を新規追加（5 ケース判定的に open=1 のみ close 実行 / closed 既存は already-closed 扱い / 失敗時は手動コマンド案内 + exit 1 / `gh_status != available` 時 exit 1 + REST API 直叩き手動代替手順） | +70 行 |
| `skills/aidlc/steps/operations/index.md` | §2.8 「gh_status 分岐」表を 2 行 → 3 行に拡張し、補助契約として「`gh_status = available` 時の Milestone 紐付け補完失敗 → exit 1」を追記。Milestone close の `gh_status != available` 例外契約も明記（中央契約として実装ステップとの整合確保） | +6 行 |

## 動作確認手順

### 検証スコープ限定

本 Unit のスコープは **Markdown ステップの追加** のみであり、実際の `gh api` コマンド実行による Milestone close / 紐付け確認 / fallback 作成の動作確認は本 Unit の完了基準には含めない（v2.5.0 以降のサイクルで自然に検証される。v2.4.0 自身の Milestone (#2) は運用タスク T1 で作成済みで、Operations Phase での close は次回 Operations 実行時に実施される）。

### Markdown 整合性検証

```bash
# 新ステップが追加されているか
grep -c "### 11. Milestone 紐付け確認・fallback 判定" skills/aidlc/steps/operations/01-setup.md  # 期待値: 1
grep -c "### 5.5 Milestone close" skills/aidlc/steps/operations/04-completion.md  # 期待値: 1

# 5 ケース判定が含まれているか
grep -c "milestone:{{CYCLE}}:fallback-created" skills/aidlc/steps/operations/01-setup.md  # 期待値: 1
grep -c "milestone:{{CYCLE}}:exists:number" skills/aidlc/steps/operations/01-setup.md  # 期待値: 1
grep -cE 'CLOSED_COUNT.*-ge 1' skills/aidlc/steps/operations/01-setup.md  # 期待値: ≥1

# Milestone close が含まれているか
grep -c "milestone:{{CYCLE}}:closed:number" skills/aidlc/steps/operations/04-completion.md  # 期待値: 1
grep -c "milestone:{{CYCLE}}:already-closed:number" skills/aidlc/steps/operations/04-completion.md  # 期待値: 1
grep -c "ERROR: Milestone close 失敗" skills/aidlc/steps/operations/04-completion.md  # 期待値: 1
grep -cE 'CLOSED_COUNT.*-ge 1' skills/aidlc/steps/operations/04-completion.md  # 期待値: ≥1（5 ケース判定 setup と同じ判定基盤）
grep -c "ERROR: Milestone .* が見つかりません" skills/aidlc/steps/operations/04-completion.md  # 期待値: 1（open=0 closed=0 の停止）

# マージ前完結契約準拠
grep -c "マージ前完結契約準拠" skills/aidlc/steps/operations/04-completion.md  # 期待値: 1
grep -c "GitHub 側操作のみ" skills/aidlc/steps/operations/04-completion.md  # 期待値: ≥1
```

### v2.4.0 自身の Milestone 状態確認（参考、本 Unit の完了基準には含めない）

```bash
gh api repos/ikeisuke/ai-dlc-starter-kit/milestones --jq '.[] | select(.title == "v2.4.0") | {number, state}'
# 期待: {number: 2, state: "open"}（Operations Phase での close は次回実行時）
```

## 境界遵守

- **Inception Phase 側 Milestone 作成**: Unit 005（完了済み）の責務
- **ドキュメント側（docs/configuration.md / README.md / guides / rules.md）の更新**: Unit 007 の責務
- **過去 v2 サイクル（v2.0.0〜v2.3.5）の遡及 Milestone 化**: 本サイクル対象外（Unit D）
- **CHANGELOG `#597` 節の本 Unit 関連記載**: Unit 007 の責務（CHANGELOG `#597` 節は Unit 007 が排他所有）
- **v2.4.0 自身の Milestone close**: 本サイクルの Operations Phase 実施時（自然検証、本 Unit の完了基準には含めない）

## リスク評価

### 技術的リスク

- **Low-Medium**: `gh api PATCH milestones` の権限要件は通常の `repo` スコープで充足。トークンスコープ不足時はエラーメッセージで手動コマンドを案内
- **Low**: `gh api` の OWNER/REPO 動的解決はリポジトリ移管時にも追従
- **Low**: `gh issue view --json milestone` で既存紐付けを確認してから補完するため、二重紐付けにはならない（GitHub 仕様で同じ Milestone への再紐付けは冪等）
- **Low**: 5 ケース判定で `CLOSED_COUNT >= 1` を最優先停止条件としているため、誤再オープンを防止

### 運用リスク

- **Medium**: v2.5.0 以降の最初のサイクル Operations Phase で Markdown ステップ通りに動くかは実運用で確認される（本 Unit の動作確認スコープ外）
- **Low**: マージ前完結契約との整合 → GitHub 側操作のみで cycle ブランチ配下を更新しないため、`write-history.sh` ガード（exit 3）にも影響なし
- **Low-Medium**: `01-setup.md` ステップ11 の fallback 作成が誤発火するリスク（Inception で正常に Milestone が作成されたのに、何らかの理由で見つからないケース） → 警告メッセージ「Inception スキップ漏れの可能性があります」で利用者の判断を促す

### 将来的な技術的負債

- **Note**: 5 ケース判定は Unit 005 と Unit 006 で論理的に同一だが、Markdown ステップ内に重複記述される。共通化（スクリプト化）は本 Unit 対象外（v2.5.0 以降のリファクタリング Issue 候補）
- **Note**: PR の Milestone 紐付け（11-3）は Issue API 経由（GitHub 仕様）。専用 PR API への移行は v2.5.0 以降のバックログ候補

## 関連 Issue

- #597（部分対応：Unit A 担当部分。Unit B は Unit 005（完了済み）、Unit C は Unit 007）
