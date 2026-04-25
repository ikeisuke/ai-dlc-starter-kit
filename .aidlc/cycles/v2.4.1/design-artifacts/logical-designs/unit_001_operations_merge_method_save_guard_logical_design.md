# 論理設計: Unit 001 - Operations 7.13 merge_method 設定保存ガード

## 概要

Operations Phase §7.13 の `merge_method=ask` 分岐における「設定保存直後の未コミット差分ガード」の挿入位置、インターフェース、3 分岐の具体手順を論理レベルで定義する。本 Unit はコード追加ではなく `skills/aidlc/steps/operations/operations-release.md` の改訂であるため、論理設計は Markdown の構造追加・分岐フロー・bash スニペット仕様として記述する。

**重要**: この論理設計ではコードは書かず、追記する手順書の構造・フロー・bash 呼び出しパターンの仕様のみを定義する。実際の Markdown 追記は Phase 2 で行う。

## アーキテクチャパターン

手順書駆動型ワークフロー（Markdown procedural guide）。`operations-release.md` §7.13 は AI エージェントが逐次解釈して実行するシーケンシャルなステップ集合であり、本 Unit は 1 段階（未コミット差分検出ガード）を挿入する。

## 改訂構造

### 現状の §7.13 章節構成（L91-154）

```text
## 7.13 PR マージ【重要】
├── [本文: PR 本文 Closes 確認、admin バイパス案内]
├── **マージ方法の確定**
├── **設定保存フロー【ユーザー選択】**（merge_method=ask のみ）
│   ├── 保存可否（AskUserQuestion: いいえ / はい）
│   ├── 保存先選択（local / project）
│   └── scripts/write-config.sh rules.git.merge_method "<値>" --scope <...>
├── **マージ実行確認【ユーザー選択】**
├── scripts/operations-release.sh merge-pr
└── **error:checks-status-unknown 検出時の分岐**
```

### 改訂後の章節構成（本 Unit で追加）

```text
## 7.13 PR マージ【重要】
├── [本文]
├── **マージ方法の確定**
├── **設定保存フロー【ユーザー選択】**（merge_method=ask のみ）
│   ├── 保存可否
│   ├── 保存先選択
│   └── scripts/write-config.sh 実行
├── **【本 Unit 新設】未コミット差分検出ガード【案B: マージ前コミット+push フロー明示】**
│   ├── 検出ロジック（git diff --quiet）
│   ├── 分岐選択（AskUserQuestion: コミット+push / follow-up PR / 破棄）
│   ├── 分岐 A: コミット+push 手順 + 終了条件
│   ├── 分岐 B: follow-up PR 手順 + 終了条件
│   └── 分岐 C: 破棄 手順 + 終了条件
├── **マージ実行確認【ユーザー選択】**
├── scripts/operations-release.sh merge-pr
└── **error:checks-status-unknown 検出時の分岐**
```

### 新設セクションの位置付け

- **親セクション**: `## 7.13 PR マージ【重要】` 配下の H3 相当の段落ブロック
- **配置点**: `**設定保存フロー【ユーザー選択】**` の直後、`**マージ実行確認【ユーザー選択】**` の直前
- **スキップ条件**: 本ガードは `merge_method=ask` + 「保存 はい」+ `scope=project` を選択したときのみ評価される。以下のケースはガードを発火させずスキップする（副作用なし）:
  - `merge_method=merge/squash/rebase` 固定（`write-config.sh` 未実行）
  - `merge_method=ask` + 「保存 いいえ」（`write-config.sh` 未実行）
  - `merge_method=ask` + 「保存 はい」+ `scope=local`（`.aidlc/config.local.toml` は `.gitignore` 対象で tracked 差分なし）

## 論理フロー

### 検出ロジック（分岐判定）

```text
前提: `write-config.sh --scope project` が直前に実行されたことを想定（S2b-project 到達）。scope=local 選択時はトリガされない

1. git diff --quiet -- .aidlc/config.toml
   - exit 0（差分なし）→ スキップしてマージ実行確認へ進む（S4 に到達。理論上は write-config 失敗や no-op の稀なケース）
   - exit 1（差分あり）→ 本ガード発動、AskUserQuestion を提示

注: `git diff --quiet` を採用する理由
- exit code で差分有無を機械判定できる
- `git status --porcelain` は出力パースが必要で AI エージェントの誤読リスクがある
- `-- .aidlc/config.toml` でパス限定し、他ファイルの未コミット差分（progress.md 等）を巻き込まない
- `.aidlc/config.local.toml` は `.gitignore` 対象のため本ロジックでは検出されない（scope=local 選択時の副作用なしスキップを自然に実現）
```

### 3 分岐の論理仕様

#### 分岐 A: コミット+push

```text
1. git add .aidlc/config.toml
2. git commit -m "chore: persist merge_method=<値> for {{CYCLE}}"
   - コミットメッセージは commit-flow.md の既存命名体系と重複しないよう chore スコープで作成
   - 複数行必要時は -m を重ねる（ヒアドキュメント禁止）
3. git push origin HEAD
   - 失敗時（rejected）: ユーザーに手動 pull + rebase を案内（本ガード外）

終了条件:
- git log origin/<branch> に当該コミットが含まれる（ユーザーが gh pr view で確認）
- 以降マージ実行確認に進む（S4 到達）
```

#### 分岐 B: follow-up PR

```text
前提: {DEFAULT_BRANCH} は `.aidlc/config.toml` の [rules.git] セクション、または `git remote show origin` の HEAD branch 行から解決する（本ガード実行前に確定済み）。{PR_NUMBER} は現サイクルの PR 番号

1. 一時退避: git stash push -m "{{CYCLE}}: merge_method follow-up" -- .aidlc/config.toml
2. 現在ブランチのコミット漏れ確認: git status
3. ブランチ名衝突確認: git show-ref --quiet refs/heads/chore/persist-merge-method-{{CYCLE}}
   - exit 0（既存あり）: suffix 付与（例: chore/persist-merge-method-{{CYCLE}}-<timestamp|short-sha>）で採用ブランチ名を確定
   - exit 1（未存在）: chore/persist-merge-method-{{CYCLE}} を採用ブランチ名とする
4. 新ブランチ作成: git checkout -b "<採用ブランチ名>" "origin/{DEFAULT_BRANCH}"
5. stash 適用: git stash pop
6. ステージング: git add .aidlc/config.toml
7. コミット: git commit -m "chore: persist merge_method for {{CYCLE}} (follow-up)"
8. リモート push: git push -u origin "<採用ブランチ名>"
9. PR 作成: gh pr create --draft --base "{DEFAULT_BRANCH}" --head "<採用ブランチ名>" --title "chore: persist merge_method for {{CYCLE}}" --body "Related to #{PR_NUMBER} — follow-up for merge_method persistence."
   - PR 本文には Closes は含めない（本 PR は設定変更のみで Issue を閉じない）
   - 長文本文が必要な場合のみ `mktemp` で一時ファイルを生成 → Write で本文を書き込み → `--body-file <生成パス>` に切り替え（終了後に一時ファイル削除）
10. 現サイクルブランチに復帰: git checkout "cycle/{{CYCLE}}"
11. /write-history スキルで follow-up PR 番号を operations.md に記録

終了条件（完了時に全てを満たすこと）:
- 現サイクルブランチに .aidlc/config.toml の未コミット差分なし（git status 確認）
- follow-up PR 番号が確定している（PR 番号不明のまま S4 に進むことは禁止、INV-2 参照）
- follow-up PR 番号が history/operations.md に記録済み
- 以降マージ実行確認に進む（S4 到達）

ユーザー環境差分の fallback:
- **gh auth 未認証**: 手順 8 までを実行（push 済み）。手順 9 は手動で PR 作成することを案内。**この場合、本分岐を「完了」扱いにせず、ユーザーが PR 番号を `AskUserQuestion` の補足として入力してから S4 に進む**（PR 番号未確定のまま S4 到達は禁止、INV-2 遵守）。手順 11 は確定後の PR 番号で記録
- **stash 不可（未コミットが他にも多数）**: 本分岐を中断し、分岐 C（破棄）または手動対応をユーザーに再選択させる
- **{DEFAULT_BRANCH} 解決不可**: `git remote show origin` の HEAD branch 行または `.aidlc/config.toml` の設定値が取得できない場合、本分岐を中断しユーザーに手動対応を依頼する
```

#### 分岐 C: 破棄

```text
1. git restore -- .aidlc/config.toml
   - パス限定で `.aidlc/config.toml` のみ巻き戻す（他ファイルの未コミット差分を保護）
2. git status --porcelain .aidlc/config.toml で差分ゼロを確認（空行であればクリーン）

終了条件:
- .aidlc/config.toml の未コミット差分なし（git status --porcelain で空行）
- 以降マージ実行確認に進む（S4 到達）
- 注: 「破棄」選択時は write-config.sh で書き込まれた値が巻き戻されるため、次回 merge_method=ask 時に再度保存選択が可能
```

## インターフェース仕様

### AskUserQuestion 呼び出し仕様

```text
question: "設定保存後の .aidlc/config.toml に未コミット差分が残っています。どのように処理しますか？"
header: "差分ガード"
options:
  - label: "コミット+push（現 PR に反映）"
    description: "現サイクルブランチに追加コミットして push、PR 本文に反映させる"
  - label: "follow-up PR で対応"
    description: "設定変更を別ブランチ + 新規 PR に切り出し、現 PR は差分なしでマージ可能にする"
  - label: "破棄（設定変更を取り消す）"
    description: "git restore で config.toml を巻き戻し、未コミット差分を解消する"
```

### bash コマンド使用パターン（要約）

| 分岐 | 主要コマンド |
|------|------------|
| 検出 | `git diff --quiet -- .aidlc/config.toml` |
| A | `git add`, `git commit -m`, `git push` |
| B | `git stash push`, `git show-ref --quiet`, `git checkout -b ... origin/{DEFAULT_BRANCH}`, `git stash pop`, `git add`, `git commit -m`, `git push -u`, `gh pr create --draft --base {DEFAULT_BRANCH} --head <ブランチ> --body "..."`（長文時のみ `--body-file`）, `git checkout`, `/write-history` |
| C | `git restore --`, `git status --porcelain` |

注: 各 bash コマンドは `$()` / backtick を使用しない（プロジェクトルール準拠）。

### 「案B を採用した」旨の明示

新設セクション先頭に以下の注記を追加する（1-2 行）:

```markdown
> **本ガードについて**: Issue #601（Operations 7.13 merge_method 設定保存が PR に追従しない）に対する案B（マージ前コミット+push フロー明示）の実装。案A（Inception 側で merge_method を事前確定）は大規模リファクタリングのため v2.5.0 以降で別途検討。
```

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 手順書改訂のみで実行時間への影響なし（Unit 定義より）
- **対応策**: `git diff --quiet` 1 回 + `AskUserQuestion` 1 回（差分検出時のみ）。runtime overhead は無視できる

### セキュリティ
- **要件**: `.aidlc/config.toml` の内容はコミットする値に限定し、機密情報を含まない前提を維持（Unit 定義より）
- **対応策**: コミットメッセージに `merge_method=<値>` の値（`merge` / `squash` / `rebase`）を含めるが、これらは非機密値のみ。`.aidlc/config.local.toml`（個人設定、git 管理外）は本ガードの対象外

### スケーラビリティ / 可用性
- **要件**: 該当なし / `gh_status != available` の分岐は既存仕様を維持
- **対応策**: `gh_status != available` のときは §7.13 の前段で手動案内に分岐済みのため、本ガードには到達しない

## 実装上の注意事項

- **パス限定の徹底**: `git diff --quiet`、`git restore` ともに `-- .aidlc/config.toml` でパス限定。他ファイル（progress.md, history 等）の未コミット差分を巻き込まない
- **`git stash` のパス限定**: 分岐 B では `git stash push -- .aidlc/config.toml` で対象ファイルを限定。全 stash は事故の原因になる
- **follow-up PR のブランチ名衝突**: 同サイクル内で複数回実行されると `chore/persist-merge-method-{{CYCLE}}` が衝突する可能性。衝突時の扱い（suffix 付与 / ユーザー確認）は実装時に決定（ブランチ存在確認 `git show-ref --quiet refs/heads/<name>` を前置）
- **ユーザー環境差分**: `gh auth` 未認証環境では分岐 B の PR 作成を手動案内にフォールバック
- **commit-flow.md の既存ルール**: 本ガードで発生するコミットは UNIT_COMPLETE / INCEPTION_COMPLETE 等の定型メッセージには該当しないため、chore スコープで独自メッセージとする。commit-flow.md のコミット前確認チェックリストには該当せず

## 技術選定

- **対象ファイル形式**: Markdown（既存 `operations-release.md` への追記）
- **bash コマンド**: 既存の `git` / `gh` コマンドのみ使用。新規スクリプト追加なし
- **テンプレート**: SKILL.md「AskUserQuestion 使用ルール」の「ユーザー選択」種別に従う

## 不明点と質問（設計中に記録）

[Question] 分岐 B の follow-up PR で、現 PR との関係を PR 本文にどう書くか？
[Answer] PR 本文のテンプレートに「Related to #<現PR番号> — follow-up for merge_method persistence」を含める。具体的な文言は Phase 2 実装時に決定。

[Question] 分岐 A のコミットメッセージに Unit-Number trailer を付けるか？
[Answer] 付けない。本コミットは Operations Phase 内のガード処理であり、Construction Unit 完了時の commit-flow.md 体系には属さない。chore スコープの単発コミットとする。
