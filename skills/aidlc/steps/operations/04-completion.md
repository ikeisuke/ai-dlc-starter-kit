# Operations Phase 完了処理（`operations.04-completion`）

> バックトラック判定・worktree フロー判定・`gh_status` 分岐は `steps/operations/index.md`（フェーズインデックス）§2 に集約されている。本ファイルはバックトラック手順・PR マージ後手順・次サイクル準備の詳細手順本体のみを含む。

## このフェーズに戻る場合【バックトラック】

Constructionに戻る必要がある場合（バグ修正・機能修正）:

1. **バグを記録**: テスト記録ファイルにバグ詳細を記載
2. **バグ種類を判定**: バグ対応フローの分類ガイドに従って判定
   - 設計バグ → Construction Phase（設計）に戻る
   - 実装バグ → Construction Phase（実装）に戻る
   - 環境バグ → Operations Phaseで修正
3. **Construction Phaseに戻る場合**:
   - SKILL.md の引数ルーティングに従い遷移（`/aidlc construction` を実行）
   - Construction Phaseの「このフェーズに戻る場合 - Operations Phaseからバグ修正で戻ってきた場合」セクションの手順に従う
4. **修正完了後**: SKILL.md の引数ルーティングに従い遷移（`/aidlc operations` を実行）して再開
5. **再テスト実施**: テスト記録テンプレートを使用して再テストを記録

---

## AI-DLCサイクル完了【重要・コンテキストリセット必須】

### 1. フィードバック収集
ユーザーからのフィードバック、メトリクス、課題を収集

### 2. 分析と改善点洗い出し
次期バージョンで対応すべき改善点をリストアップ

### 3. バックログ記録
次サイクルに引き継ぐタスクがある場合、GitHub Issueを作成してバックログに記録する（ガイド: `guides/backlog-management.md`）。

### 4. 次期サイクルの計画
新しいサイクル識別子を決定（例: v1.0.1 → v1.1.0, 2024-12 → 2025-01）

### 5. PRマージ後の手順【重要】

PRがマージされたら、次サイクル開始前に以下を実行：

#### 【重要】マージ前完結ルール（Unit 002 / #583）

PR マージ（7.13）完了後は `.aidlc/cycles/{{CYCLE}}/**` 配下のいかなるファイルも改変してはならない。特に以下を禁止する:

- `history/operations.md` への追記（**`/write-history` スキル（`scripts/write-history.sh`）呼び出し禁止**）
- `operations/progress.md` のステータス・固定スロット更新
- `operations/post_release_operations.md` や他の成果物の追記

**理由**: cycle ブランチは post-merge-sync.sh で削除されるため、マージ後の改変は記録として残らず、未コミット差分として手動破棄が必要になる。マージ完了の事実は GitHub 上の PR・merge commit・自動タグが記録源となる。

**ガード動作**（Unit 002 / DR-001）: マージ後に `write-history.sh --phase operations` を呼び出した場合、以下のいずれかに該当すれば exit code `3` で拒否され、`error:post-merge-history-write-forbidden:<reason_code>:<diagnostics>` 形式の機械可読メッセージが stdout と stderr の両方に出力される:

1. **第一条件**: `--operations-stage post-merge` を明示指定した場合（即拒否）
2. **第二条件（AND フォールバック）**: `operations/progress.md` の `completion_gate_ready=true` かつ `gh pr view` で該当 PR が `state=MERGED ∧ mergedAt!=null ∧ number 一致` と確認できた場合

7.8 以降の正常な呼び出し（Draft PR Ready 化のログ等）が必要な場合は `--operations-stage pre-merge` を明示すること。exit 3 は誤呼び出し検出用であり、正常な Operations 呼び出しには影響しない（後方互換）。

---

1. **未コミット変更の確認**:

   ```bash
   git status --porcelain
   ```

   **空でない場合**:

   ```text
   【注意】未コミットの変更があります。
   通常、この時点で未コミット変更は存在しないはずです（7.9で確認済み）。

   変更されているファイル:
   {git status --porcelain の実行結果をここに貼り付け}

   対応方法を選択してください：
   1. コミットする（推奨）- 変更を履歴として残す
   2. stashする - 一時的に退避してcheckout後に復元
   3. 破棄する - 誤生成/一時ファイルのみ（progress.md, history, Unit定義は破棄NG）
   ```

2. **worktree環境判定**:

   事前にBashで `git rev-parse --git-dir` を実行し、結果を確認する。

   - 結果が `.git` で終わる（通常リポジトリ）: **通常環境フロー**（ステップ1-4）へ
   - 結果が `.git/worktrees/` を含む（worktree環境）: **worktreeフロー**（ステップW）へ

#### worktreeフロー（ステップW）

worktree環境では `post-merge-cleanup.sh` がmain pull（親リポジトリ側）、fetch、detached HEAD切り替え、ブランチ削除をすべて実行する。そのため通常環境フローのステップ1（mainへcheckout）・ステップ2（git pull）・ステップ4（ブランチ削除）はスクリプトが代行するためスキップし、ステップ3（タグ付け）のみ手動で実行する。

**スクリプトパス探索と実行**:

事前にBashで以下の順にスクリプトの存在を確認する:

```bash
if [ -x "scripts/post-merge-cleanup.sh" ]; then
    echo "found:scripts/post-merge-cleanup.sh"
else
    echo "not_found"
fi
```

- **スクリプトが見つからない場合**（`not_found`）: 以下を表示し、手動対応を案内する（worktree環境では `git checkout main` が利用できないため、メインリポジトリ側で手動操作が必要）

  ```text
  【警告】post-merge-cleanup.sh が見つかりません。
  worktree環境ではスクリプトによるクリーンアップが必要です。
  メインリポジトリ側で手動操作を行ってください。
  ```

**W-1. dry-run実行**:

AIが探索結果のパスを使用して以下を実行する:

```bash
<探索結果のパス> --cycle {{CYCLE}} --dry-run
```

**注意**: 探索結果が `scripts/` の場合はそのパスを使用する。スクリプトに実行権限がない場合は `bash <探索結果のパス>` で実行する。

実行予定を確認し、問題がないことを確認する。

**失敗判定基準**: 終了コード `!= 0` で失敗と判定。実行フェーズの致命的エラーでは通常 `status:error` 出力を伴う。終了コード `0` かつ `status:warning` は成功扱い（警告内容は確認するが処理は続行可）。

- **dry-run成功時**: ステップW-2へ
- **dry-run失敗時**: エラー内容を表示し、手動対応を案内する。**注意**: worktree環境では `main` ブランチが他のworktreeでcheckout済みのため、通常環境のステップ1（`git checkout main`）は実行できない。スクリプトのエラー出力にある `main_repo_path` を参照し、メインリポジトリ側で手動操作を行うこと

**W-2. 本実行**:

```bash
<探索結果のパス> --cycle {{CYCLE}}
```

**注意**: スクリプトに実行権限がない場合は `bash <探索結果のパス>` で実行する。

- **成功時**: ステップ3（バージョンタグ付け）へ合流（ステップ4はスクリプトが実行済みのためスキップ）
- **失敗時**: エラー内容を表示し、メインリポジトリ側での手動復旧を案内

#### 通常環境フロー（ステップ1-4）

1. **mainブランチに移動**:

   ```bash
   git checkout main
   ```

2. **最新の変更を取得**:
   ```bash
   git pull origin main
   ```

3. **バージョンタグ付け**:

   **設定確認**: `.aidlc/config.toml` の `[rules.release]` セクションを読み、`version_tag` の値を確認

   - `version_tag = false`（デフォルト）: このステップをスキップ
   - `version_tag = true`: 以下を実行

   ```bash
   # アノテーション付きタグを作成（マージ後の最新コミットに付与）
   git tag -a vX.X.X -m "Release vX.X.X"

   # タグをリモートにプッシュ（個別タグ指定で安全にプッシュ）
   git push origin vX.X.X
   ```

   **GitHub Release作成（オプション）**:
   ```bash
   # GitHub CLIが利用可能な場合
   gh release create vX.X.X --title "vX.X.X" --notes "See CHANGELOG.md for details"
   ```

4. **マージ済みブランチの削除**:
   ```bash
   # ローカルブランチの削除
   git branch -d cycle/vX.X.X
   # リモートブランチの削除（必要に応じて）
   git push origin --delete cycle/vX.X.X
   ```

**注意**: この手順を実行してから次サイクルのセットアップを開始してください。

### 5.5 Milestone close【マージ前完結契約準拠】

**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

```bash
MILESTONE_ENABLED=$(scripts/read-config.sh rules.github.milestone_enabled 2>/dev/null || echo "false")
```

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合: メッセージ `milestone:disabled:skip:step=04-completion-step5.5:reason=opt-out` を出力し、**本ステップの Milestone close をすべてスキップ**して次のステップへ進む。後続の `gh_status` 判定 / `gh_status != available` 時 exit 1 契約 / Milestone close 5 ケース判定処理は **一切実行しない**（opt-out 時はマージ前完結契約のサイクル完了可視化要件は **opt-out 利用者の責任範囲外** とし、close 自体を要求しないため、警告も表示しない）
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定（`available` 以外で exit 1）+ Milestone close 5 ケース判定処理を実行する

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
# - `--paginate` + `per_page=100` で全ページを取得（Milestone 30 件超のリポでも検索漏れ防止）
MILESTONE_LOOKUP=$(gh api --paginate "repos/$OWNER/$REPO/milestones?state=all&per_page=100" \
  --jq "[.[] | select(.title == \"{{CYCLE}}\") | {number, state}]")

OPEN_COUNT=$(echo "$MILESTONE_LOOKUP" | jq '[.[] | select(.state == "open")] | length')
CLOSED_COUNT=$(echo "$MILESTONE_LOOKUP" | jq '[.[] | select(.state == "closed")] | length')

# 3. 5 ケース判定（ストーリー 2 受け入れ基準の優先順位通り、setup 側 11-1 と同じ判定基盤）
if [ "$CLOSED_COUNT" -eq 1 ] && [ "$OPEN_COUNT" -eq 0 ]; then
  CLOSED_NUMBER=$(echo "$MILESTONE_LOOKUP" | jq '.[] | select(.state == "closed") | .number')
  echo "milestone:{{CYCLE}}:already-closed:number=$CLOSED_NUMBER"
elif [ "$CLOSED_COUNT" -ge 1 ]; then
  echo "ERROR: Milestone {{CYCLE}} の closed が ${CLOSED_COUNT} 件 + open が ${OPEN_COUNT} 件あります（多重 closed または混在状態）。同名 closed Milestone がある場合の意図確認を必須化（誤再オープン防止）。手動確認: gh api --paginate \"repos/\$OWNER/\$REPO/milestones?state=all&per_page=100\"" >&2
  exit 1
elif [ "$OPEN_COUNT" -ge 2 ]; then
  echo "ERROR: Milestone {{CYCLE}} の open が ${OPEN_COUNT} 件あります（重複作成の可能性）。重複候補を確認: gh api --paginate \"repos/\$OWNER/\$REPO/milestones?state=all&per_page=100\"" >&2
  exit 1
elif [ "$OPEN_COUNT" -eq 1 ]; then
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
  echo "ERROR: Milestone {{CYCLE}} が見つかりません（open / closed のいずれにも存在しない）。01-setup.md ステップ11 の fallback 作成が未実行 or 手動作業漏れの可能性。手動確認: gh api --paginate \"repos/\$OWNER/\$REPO/milestones?state=all&per_page=100\"" >&2
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

### 6. 完了サマリ出力【必須】

以下の完了サマリを出力する。※ 情報源にない内容は出力しない。

```text
【Operations Phase 完了サマリ】
- サイクル: {{CYCLE}}
- リリースバージョン: [リリースしたバージョン]
- マージPR: [PR番号とURL]
- クローズしたIssue: [Closes指定したIssue番号の一覧。なければ「なし」]
- 残課題・バックログ: [登録したバックログIssue番号。なければ「なし」]
```

### 7. 次のサイクル開始【必須】

ユーザーの明示的な連続実行指示（「続けて」等）がない限り、以下のメッセージを提示する（デフォルトはリセット）。セッションサマリ（サイクル番号、ブランチ/PR状態、次のアクション）を収集する。

````markdown
---
## サイクル完了

コンテキストをリセットして次のサイクルを開始してください。

**理由**: 長い会話履歴はAIの応答品質を低下させます。新しいセッションで開始することで最適なパフォーマンスを維持できます。

**セッションサマリ**:
- **完了**: サイクル {{CYCLE}}
- **リポジトリ**: [ブランチ名]、[PRマージ済み/タグ作成済み等の状態]
- **次のアクション**: 次のサイクルを開始

**対応内容**: 実施内容（Issue番号付き）・変更対象・未対応事項（なければ「なし」）・次回の着手点を含める。情報不足時は「（コンテキスト情報不足のため省略）」。

**次のステップ**:
- Claude Code: `/aidlc inception` と指示
- その他: `steps/inception/01-setup.md` からステップファイルを順に読み込み

---
````

**必要に応じて前バージョンのファイルをコピー/参照**:
- `.aidlc/rules.md` → 全サイクル共通なので引き継がれます
- `.aidlc/cycles/vX.X.X/requirements/intent.md` → 新サイクルで参照して改善点を反映
- その他、引き継ぎたいファイルがあればコピー

セットアップ完了後、新しいセッションで Inception Phase を開始

---

### 8. ライフサイクルの継続
Inception → Construction → Operations → (次サイクル) を繰り返し、継続的に価値を提供
