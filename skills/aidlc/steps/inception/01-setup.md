# Inception Phase - セットアップ

## プロジェクト情報

### 技術スタック
このフェーズで決定

### ディレクトリ構成（フェーズ固有の追加）
- `.aidlc/cycles/{{CYCLE}}/`: サイクル固有成果物（Inception Phaseで作成）

### 開発ルール

**共通ルールは `steps/common/rules.md` を参照**

- **プロンプト履歴管理【重要】**: 履歴は `.aidlc/cycles/{{CYCLE}}/history/inception.md` に記録。

  **設定確認**: `.aidlc/config.toml` の `[rules.history]` セクションを確認
  - `level = "detailed"`: ステップ完了時に記録 + 修正差分も記録
  - `level = "standard"`: ステップ完了時に記録（デフォルト）
  - `level = "minimal"`: フェーズ完了時にまとめて記録

  **日時取得**:
  - 日時は `write-history.sh` が内部で自動取得します

  **履歴記録フォーマット**（detailed/standard共通）:
  ```bash
  scripts/write-history.sh \
      --cycle {{CYCLE}} \
      --phase inception \
      --step "[ステップ名]" \
      --content "[作業概要]" \
      --artifacts "[作成・更新したファイル]"
  ```

  **修正差分の記録**（level = "detailed" の場合のみ）:
  ユーザーからの修正依頼があった場合、以下を履歴に追記:
  ```markdown
  ### 修正履歴
  - **修正依頼**: [ユーザーからのフィードバック要約]
  - **変更点**: [修正前 → 修正後の要点]
  ```

**【次のアクション】** 今すぐ `steps/common/review-flow.md` を読み込んで、内容を確認してください。

  **AIレビュー対象タイミング**: Intent承認前、ユーザーストーリー承認前、Unit定義承認前

- **コンテキストリセット対応【重要】**: ユーザーから以下のような発言があった場合、現在の作業状態に応じた継続用プロンプトを提示する：
  - 「継続プロンプト」「リセットしたい」
  - 「コンテキストが溢れそう」「コンテキストオーバーフロー」
  - 「長くなってきた」「一旦区切りたい」
  - 「中断したい」「ここで止める」「一時停止」（明示的な中断指示）

  **対応手順**:
  1. 現在の作業状態を確認（どのステップか）
  2. progress.mdを更新（現在のステップを「進行中」のまま保持）
  3. 履歴記録（`history/inception.md` に中断状態を追記）
  4. session-state.mdを生成（`common/session-continuity.md` の「session-state.md の生成」セクションに従う）。**注意**: この手順は `automation_mode` に関係なく必ず実行する
  5. 継続用プロンプトを提示（下記フォーマット）

  ````markdown
  ---
  ## コンテキストリセット - 作業継続

  現在の作業状態を保存しました。コンテキストをリセットして作業を継続できます。

  **現在の状態**:
  - フェーズ: Inception Phase
  - ステップ: [ステップ名]

  **作業を継続するプロンプト**:
  ```
  サイクル {{CYCLE}} の Inception Phase を継続してください：
  /aidlc inception
  ```
  ---
  ````

**【次のアクション】** 今すぐ `steps/common/compaction.md` を読み込んで、内容を確認してください。

### フェーズの責務【重要】

**このフェーズで行うこと**:
- サイクルの作成とディレクトリ構造の初期化
- 要件の明確化（Intent作成）
- ユーザーストーリー作成
- Unit定義

**このフェーズで行わないこと（禁止）**:
- 実装コードを書く
- テストコードを書く
- 設計ドキュメントの詳細化（Construction Phaseで実施）

**承認なしにConstruction Phaseに進んではいけない**（`automation_mode=semi_auto` での自動承認を除く）

**【次のアクション】** 今すぐ `steps/common/phase-responsibilities.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `steps/common/progress-management.md` を読み込んで、内容を確認してください。

---

## あなたの役割

あなたはプロジェクトセットアップ担当者兼プロダクトマネージャー兼ビジネスアナリストです。
新しいサイクルのディレクトリ構造を作成し、要件を明確化してUnit定義まで完了します。

---

## 個人設定（オプション）

チーム共有設定を個人の好みで上書きできます:

| ファイル | 用途 | Git管理 |
|----------|------|---------|
| `.aidlc/config.toml` | プロジェクト共有設定 | Yes |
| `.aidlc/config.local.toml` | 個人設定（上書き用） | No（.gitignore） |

例: AIレビューを個人的に無効化
```toml
# .aidlc/config.local.toml
[rules.reviewing]
mode = "disabled"
```

詳細は `guides/config-merge.md` を参照。

---

## 最初に必ず実行すること

### Part 1: セットアップ

#### 1. プリフライトチェック

**【次のアクション】** 今すぐ `steps/common/preflight.md` を読み込んで、手順に従ってください。

環境チェック・設定値取得の結果がコンテキスト変数として保持されます。以降のステップではこれらの変数を参照してください。

**運用ルール**:

- プリフライト結果を会話コンテキストに保持し、以降のステップでは再実行しない
- ユーザーがコマンドをインストール/認証した場合のみ再チェック

#### 1a. Inception固有の追加情報取得

プリフライトチェック後に、Inception Phase固有の情報を取得する:

- **現在のブランチ**: `git branch --show-current` で取得し、`current_branch` として保持（サイクル判定に使用）
- **最新サイクル**: `ls -1 .aidlc/cycles/ 2>/dev/null | grep -E '^v[0-9]+' | sort -V | tail -1` で取得し、`latest_cycle` として保持（バージョン確認に使用）

**注記**: これらの情報はプリフライトのスコープ外のため、Inception固有のステップで個別に取得する。

#### 2. セッション判別設定【オプション】

`session-title` スキルが利用可能な場合に実行し、ターミナルのタブタイトルとバッジを設定する（macOS専用）。スキルが利用不可の場合はスキップして続行。

引数: `project.name`=ステップ1の出力、`cycle`=`current_branch` から抽出（不明時は空文字列）、`phase`=`Inception`

**注記**: `session-title` はスターターキット同梱ではありません。利用するには外部リポジトリからインストールが必要です。詳細は `guides/skill-usage-guide.md` を参照。

#### 3. デプロイ済みファイル確認

```bash
ls skills/aidlc/SKILL.md 2>/dev/null
```

出力があれば `DEPLOYED_EXISTS`、エラーなら `DEPLOYED_NOT_EXISTS` と判断。

**判定**:
- **DEPLOYED_EXISTS**: ステップ4（スターターキット開発リポジトリ判定）へ進む
- **DEPLOYED_NOT_EXISTS**: 以下のお知らせを表示し、ステップ4へ進む
  ```text
  【お知らせ】skills/aidlc/SKILL.md が見つかりません。

  AI-DLCスキルが未セットアップの可能性があります。
  `/aidlc setup` でセットアップを実行してください。
  現在のスキルファイルを使用しているため、処理を続行します。
  ```

#### 4. スターターキット開発リポジトリ判定

AIが `.aidlc/config.toml` をReadツールで読み取り、`[project]` セクションの `name` 値を確認。
**フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は空として扱う。

`name` が `ai-dlc-starter-kit` の場合は `STARTER_KIT_DEV`、それ以外は `USER_PROJECT` と判断。

**判定**:
- **STARTER_KIT_DEV**: 以下を表示し、ステップ5（追加ルール確認）へ進む（ステップ7はスキップ）
  ```text
  スターターキット開発リポジトリを検出しました。
  アップグレード案内はスキップします（開発リポジトリでは、次サイクルで変更を加えてリリースするためです）。
  ```
- **USER_PROJECT**: ステップ5（追加ルール確認）へ進む

#### 5. 追加ルール確認

`.aidlc/rules.md` が存在すれば読み込む

#### 7. スターターキットバージョン確認

**スキップ条件**: ステップ4で `STARTER_KIT_DEV` と判定された場合、このステップをスキップしてステップ8（サイクルモード確認）へ進む。

**アップグレードチェック設定の確認**:

`rules.md` の「アップグレードチェック設定」セクションに従い、設定値を取得する。

`false` の場合（デフォルト）: 以下を表示し、ステップ8（サイクルモード確認）へ進む:

```text
アップグレードチェックはスキップされました（rules.upgrade_check.enabled = false）。
```

`true` の場合: 以下のバージョン確認処理を実行する。

**最新バージョン取得**:

```bash
curl -s --max-time 5 https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/version.txt 2>/dev/null
```

AIがcurl出力から最新バージョンを取得（エラー時は空として扱う）。

**現在のバージョン取得**:
AIが `.aidlc/config.toml` をReadツールで読み取り、`starter_kit_version` の値を確認。
**フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は空として扱う。

**判定**:
- **最新バージョン取得失敗**: ステップ8（サイクルモード確認）へ進む
- **CURRENT_VERSION が空**: ステップ8（サイクルモード確認）へ進む（aidlc.tomlなし）
- **LATEST_VERSION > CURRENT_VERSION**: アップグレード推奨を表示
  ```text
  AI-DLCスターターキットの新しいバージョンが利用可能です。
  - 現在: [CURRENT_VERSION]
  - 最新: [LATEST_VERSION]

  アップグレードを推奨します。どうしますか？
  1. アップグレードする
  2. 現在のバージョンで続行する
  ```
  - **1 を選択**: セットアップを案内して終了
    ```text
    アップグレードするには、スターターキットの setup-prompt.md を読み込んでください。
    ```
  - **2 を選択**: ステップ8（サイクルモード確認）へ進む
- **LATEST_VERSION = CURRENT_VERSION**: 以下を表示し、ステップ8（サイクルモード確認）へ進む
  ```text
  アップグレードは不要です（現在最新バージョンです）。
  ```

#### 8. サイクルモード確認

`rules.cycle.mode` 設定を読み取り、コンテキスト変数 `cycle_mode` として保持する。

```bash
scripts/read-config.sh rules.cycle.mode
```

**読み取り失敗時**（終了コード2）: 以下の警告を表示し、`"default"` として扱う:

```text
【警告】rules.cycle.mode の読み取りに失敗しました。デフォルト（default）にフォールバックします。
```

**値の検証**:

- 有効値: `"default"`, `"named"`, `"ask"`
- 有効値以外の場合 → 以下の警告を表示し、`"default"` として扱う:

  ```text
  【警告】rules.cycle.mode の値 "[取得した値]" は無効です。有効値: default, named, ask
  デフォルト（default）にフォールバックします。
  ```

**モード別分岐ロジック**:

**mode = "named" の場合**:

まず、`.aidlc/cycles/` 配下の既存名前付きサイクル名を検出する:

```bash
ls -d .aidlc/cycles/*/ 2>/dev/null | xargs -I{} basename {} | grep -v '^v[0-9]' | grep -v '^backlog$' | grep -v '^backlog-completed$' | sort
```

**既存名前付きサイクル名が1件以上検出された場合**:

AskUserQuestion機能で選択肢を提示する（昇順表示、最後に「新規作成」オプション）:

```text
【名前付きサイクルモード】（rules.cycle.mode = "named"）
使用するサイクル名を選択してください：

1. {検出された名前1}
2. {検出された名前2}
...
N. 新規作成 - 新しいサイクル名を入力する
```

- 既存名を選択した場合: 選択された名前を `cycle_name` としてコンテキスト変数に保持し、ステップ10へ進む
- 「新規作成」を選択した場合: 下記の名前入力フローへ進む

**既存名前付きサイクル名が0件の場合、または検出に失敗した場合**:

サイクル名の入力を求める:

```text
【名前付きサイクルモード】（rules.cycle.mode = "named"）
サイクル名を入力してください（半角英小文字・数字・ハイフンのみ）。
例: waf, auth-system, feature-1
```

**バリデーション手順**:
1. 正規表現チェック: `^[a-z0-9][a-z0-9-]{0,63}$`
2. 禁止名チェック: `backlog`, `backlog-completed` は予約語のため使用不可
3. `v[0-9]` 開始チェック: `^v[0-9]` で始まる名前はバージョンディレクトリと混同されるため使用不可

**バリデーション失敗時**: パターン別エラーメッセージを表示し、再入力を求める:

- 正規表現不一致:
  ```text
  【エラー】サイクル名 "[入力値]" は無効です。
  有効な形式: 半角英小文字・数字・ハイフンのみ（先頭は英小文字または数字、最大64文字）
  例: waf, auth-system, feature-1
  ```
- 禁止名衝突（backlog, backlog-completed）:
  ```text
  【エラー】サイクル名 "[入力値]" は予約語のため使用できません。
  別の名前を入力してください。
  ```
- `v[0-9]` 開始:
  ```text
  【エラー】サイクル名 "[入力値]" は "v" + 数字で始まるため、バージョンディレクトリと混同される可能性があります。
  別の名前を入力してください（例: feature-v2, ver2 など）。
  ```

**バリデーション成功時**: `cycle_name` をコンテキスト変数として保持し、ステップ10へ進む。

**mode = "ask" の場合**:

AskUserQuestion機能で選択肢を提示:

```text
サイクルの種類を選択してください：
1. 通常サイクル（例: v1.0.0 - 従来形式）(推奨)
2. 名前付きサイクル（例: waf/v1.0.0 - 機能テーマごとに分類）
```

「1. 通常サイクル」選択時: `mode = "default"` と同じフローへ（名前入力なし）
「2. 名前付きサイクル」選択時: 上記 `mode = "named"` の名前入力フローへ

**mode = "default" の場合**:

変更なし。従来のフローで動作する（名前入力なし）。

#### 9. 名前付きサイクル継続確認

**スキップ条件**（以下のいずれかに該当する場合、このステップをスキップしてステップ10へ進む）:

- `cycle_name` が既に設定済みの場合（ステップ8で名前入力済みまたは既存名を選択済み）
- ステップ8で `mode = "ask"` から「1. 通常サイクル」を選択した場合
- `.aidlc/cycles/` 配下に名前付きサイクルディレクトリが0件の場合

**名前付きサイクルの検出**:

`.aidlc/cycles/` 配下のディレクトリのうち、以下の条件を**すべて**満たすものを名前付きサイクルとして検出する:

1. `v[0-9]` で始まらない（バージョンディレクトリではない）
2. `backlog` でも `backlog-completed` でもない（予約ディレクトリではない）

**検出された名前付きサイクルが1件以上の場合**:

AskUserQuestion機能で確認を提示する:

```text
既存の名前付きサイクルが見つかりました:
{検出された名前付きサイクルのディレクトリ名を列挙}

既存の名前付きサイクルを継続しますか？
1. いいえ - 新しいサイクルを開始する(推奨)
2. はい - 名前付きサイクルを継続する
```

**「2. はい」選択時**:

- 名前付きサイクルが1件の場合はそのサイクルを自動選択する
- 名前付きサイクルが複数ある場合は、AskUserQuestion機能でどのサイクルを継続するか選択を求める
- 選択された名前付きサイクル名を `cycle_name` としてコンテキスト変数に保持する
- `cycle_mode` を `"named"` に更新する（ステップ10以降の分岐との整合性を維持するため）
- ステップ10（サイクルバージョンの決定）へ進む（名前付きサイクルモードのバージョン提案フローが適用される）

**「1. いいえ」選択時**:

- ステップ10（サイクルバージョンの決定）へ進む（通常フロー）

#### 10. サイクルバージョンの決定

**10-1. コンテキスト表示**（バージョン提案前に実行）:

バックログと直近サイクルの情報を表示し、バージョン決定の判断材料を提供する。

**バックログ表示**:

```bash
scripts/check-open-issues.sh --limit 5
```

- エラー出力（`error:*`）の場合は「バックログ取得失敗」と警告を表示し、バックログ表示をスキップする
- このスクリプトはバックログ専用ではなくオープンIssue全件を返す。表示時に「オープンIssue」として案内する
- 取得結果が0件の場合は「バックログ項目なし」と表示する

以下の形式で表示する:

```text
【バックログ状況】（オープンIssue）
件数: N件
---
#123 タイトル1
#124 タイトル2
...（上位5件まで）
```

**直近サイクル表示**:

`cycle_name` が設定されている場合（名前付きサイクルモード）:
```bash
ls -d .aidlc/cycles/${cycle_name}/v*/ 2>/dev/null | sort -V | tail -3
```

`cycle_name` が未設定の場合（従来）:
```bash
ls -d .aidlc/cycles/v*/ 2>/dev/null | sort -V | tail -3
```

各サイクルディレクトリの `requirements/intent.md` を読み、「開発の目的」（`## 開発の目的` 見出し）セクションの最初の非空行を抽出する。以下の形式で表示する:

```text
【直近サイクル】
| サイクル | Intent要約 |
|----------|------------|
| v1.18.2  | aidlc-setup.shの信頼性向上 |
| v1.18.1  | ... |
| v1.18.0  | ... |
```

- `requirements/intent.md` が存在しない場合は「（Intent不明）」と表示する
- 「開発の目的」見出しが存在しない、または見出し直後に非空行がない場合も「（Intent不明）」と表示する
- サイクルディレクトリが0件の場合は「直近サイクルなし」と表示する
- 3件未満の場合は存在する分だけ表示する

**10-2. バージョン提案**:

```bash
scripts/suggest-version.sh
```

**出力例**:
```text
branch_version:v1.12.1
latest_cycle:v1.12.0
suggested_patch:v1.12.1
suggested_minor:v1.13.0
suggested_major:v2.0.0
all_cycles:v1.12.0,v1.11.0,feature-auth,waf/v1.0.0,waf/v1.1.0
```

**注**: `all_cycles` には名前付きサイクル（`waf/v1.0.0` 等）も含まれる。名前付きサイクルは `${cycle_name}/${version}` 形式でリストされる。

**AIの判断フロー**:

**`cycle_name` が設定されている場合（名前付きサイクルモード）**:

1. `suggest-version.sh` を実行して `all_cycles` を取得
2. `all_cycles` をカンマで分割し、各トークンをtrimしてから `${cycle_name}/v*` にマッチするものを抽出
3. マッチしたバージョンがある場合: 最新バージョンを基準にpatch/minor/majorを再計算して選択肢を提示
4. マッチしたバージョンがない場合（名前付きサイクルの初回）: `v1.0.0` を提案
5. ユーザーが選択または入力したバージョンで `{{CYCLE}}` を `${cycle_name}/${version}` 形式で組み立て
6. 組み立てた `{{CYCLE}}` が `all_cycles` のカンマ分割・trim済みトークンに完全一致する場合: 「このサイクルは既に使用されています」エラーを表示して再選択

**`cycle_name` が未設定の場合（従来フロー）**:

1. `branch_version` が設定されている場合: そのバージョンを提案
2. そうでない場合: `suggested_*` から選択肢を提示し、「カスタム名を入力する」も選択肢に含める
3. 「カスタム名を入力する」が選択された場合: ユーザーに自由入力を求める（例: `feature-auth`, `2026-03`）
4. 選択または入力されたサイクル名が `all_cycles` のカンマ分割・trim済みトークンに完全一致する場合: エラー表示して再選択

#### 11. ブランチ確認【推奨】

現在のブランチを確認し、サイクル用ブランチでの作業を推奨：

```bash
git branch --show-current
```

**判定**:
- **main または master の場合**: ブランチ作成方式の設定を確認し、方式に応じて処理

  **11-1. ブランチ作成方式の読み取り**:

  ```bash
  scripts/read-config.sh rules.branch.mode
  ```

  **読み取り失敗時**（終了コード2: daselエラー等）: 以下の警告を表示し、`"ask"` として扱う:
  ```text
  【警告】rules.branch.mode の読み取りに失敗しました。デフォルト（ask）にフォールバックします。
  ```

  **11-2. mode 値の検証**:
  - 有効値: `"branch"`, `"worktree"`, `"ask"`
  - 有効値以外の場合 → 以下の警告を表示し、`"ask"` として扱う:
    ```text
    【警告】rules.branch.mode の値 "[取得した値]" は無効です。有効値: branch, worktree, ask
    デフォルト（ask）にフォールバックします。
    ```

  **11-3. mode に応じた分岐**:

  **mode = "branch" の場合**:
  ```text
  設定に基づき、ブランチ方式で自動作成します（rules.branch.mode = "branch"）。
  ```
  → `scripts/setup-branch.sh {{CYCLE}} branch` を実行

  **mode = "worktree" の場合**:
  まず worktree 機能の有効性を確認:
  ```bash
  scripts/read-config.sh rules.worktree.enabled
  ```
  読み取り失敗時（終了コード2）は `"false"` として扱う。
  - **`true` の場合**:
    ```text
    設定に基づき、worktree方式で自動作成します（rules.branch.mode = "worktree"）。
    ```
    → `scripts/setup-branch.sh {{CYCLE}} worktree` を実行
  - **`true` 以外の場合**:
    ```text
    【警告】rules.branch.mode = "worktree" ですが、rules.worktree.enabled が true ではありません。
    ブランチ方式にフォールバックします。
    ```
    → `scripts/setup-branch.sh {{CYCLE}} branch` を実行

  **mode = "ask" の場合**（デフォルト）:
  現行通りユーザーに質問:
  ```text
  現在 main/master ブランチで作業しています。
  サイクル用ブランチで作業することを推奨します。

  1. worktreeを使用して新しい作業ディレクトリを作成する
  2. 新しいブランチを作成して切り替える
  3. 現在のブランチで続行する（非推奨）

  どれを選択しますか？
  ```

  選択に応じてスクリプトを実行:
  ```bash
  # ブランチ作成の場合
  scripts/setup-branch.sh {{CYCLE}} branch

  # worktree作成の場合
  scripts/setup-branch.sh {{CYCLE}} worktree
  ```

  **出力例（成功時）**:
  ```text
  status:success
  branch:cycle/v1.12.1
  worktree_path:.worktree/cycle-v1.12.1
  message:新しいブランチ cycle/v1.12.1 でworktreeを作成しました
  main_status:up-to-date
  ```

  **出力例（エラー時）**:
  ```text
  status:error
  branch:cycle/v1.12.1
  worktree_path:.worktree/cycle-v1.12.1
  message:worktreeの作成に失敗しました
  error_code:worktree-creation-failed
  ```

  エラー時は `status:error` でエラーを検出し、`error_code:<code>` でエラー種別を判定する。

  worktree作成の詳細は `guides/worktree-usage.md` を参照。

  **11-4. main最新化チェック結果の表示**（setup-branch.sh実行する全経路 — branch/worktree/ask — に共通で適用）:

  setup-branch.sh実行後、出力に含まれる `main_status:` 行をパースして以下のメッセージを表示する:

  - `main_status:up-to-date`:
    ```text
    mainブランチは最新です。
    ```
  - `main_status:behind`:
    ```text
    【警告】mainブランチに未取り込みの変更があります。
    サイクル開始前にmainの変更を取り込むことを推奨します。
    → git merge origin/main または git rebase origin/main
    ```
  - `main_status:fetch-failed`:
    ```text
    【情報】リモートの確認に失敗しました（オフライン環境等）。処理を続行します。
    ```
  - `main_status:` 行が出力に含まれない場合: 表示なし（従来互換）

- **サイクルブランチの場合**（`cycle/` プレフィックスで始まるブランチ）: 次のステップへ進行

- **それ以外のブランチまたはdetached HEAD**:

  現在のブランチがサイクル用ブランチ（`cycle/`プレフィックス）でない場合、AskUserQuestion機能でサイクルブランチへの切り替えを提案する:

  まず、既存のサイクルブランチを検出する:
  ```bash
  git branch --list "cycle/*" --format="%(refname:short)"
  ```

  **既存のサイクルブランチがある場合**:
  ```text
  現在のブランチはサイクル用ブランチではありません。
  サイクル用ブランチで作業することを推奨します。

  1. 新しいサイクルブランチを作成する(推奨)
  2. 既存のサイクルブランチに切り替える
  3. 現在のブランチで続行する（非推奨）
  ```

  - 「1. 新しいサイクルブランチを作成する」選択時: 上記の main/master ブランチの場合と同じブランチ作成フロー（11-1〜11-4）を実行
  - 「2. 既存のサイクルブランチに切り替える」選択時: 検出されたサイクルブランチをAskUserQuestionで一覧表示し、選択されたブランチに `git checkout` で切り替える。切り替えに失敗した場合（未コミット変更との衝突等）は以下を表示:
    ```text
    【エラー】ブランチの切り替えに失敗しました。
    未コミットの変更がある場合は、先にコミットまたはstashしてから再度実行してください。
    ```
  - 「3. 現在のブランチで続行する」選択時: 次のステップへ進行

  **既存のサイクルブランチがない場合**:
  ```text
  現在のブランチはサイクル用ブランチではありません。
  サイクル用ブランチで作業することを推奨します。

  1. 新しいサイクルブランチを作成する(推奨)
  2. 現在のブランチで続行する（非推奨）
  ```

  - 「1. 新しいサイクルブランチを作成する」選択時: 上記の main/master ブランチの場合と同じブランチ作成フロー（11-1〜11-4）を実行
  - 「2. 現在のブランチで続行する」選択時: 次のステップへ進行

**11-5. rules.md再読み込み【ブランチ切り替え時】**（全ブランチ切り替え経路に共通で適用）:

ステップ11でブランチ切り替えが発生した場合（setup-branch.sh実行 または git checkout実行の経路を通った場合）、ステップ5（追加ルール確認）を再実行する。

**条件**: ブランチ切り替えが発生した場合のみ実行。サイクルブランチに既にいた場合、または「現在のブランチで続行する」を選択した場合はスキップ。

**動作**: ステップ5と同じ手順（`.aidlc/rules.md` が存在すれば読み込む）を再実行し、切り替え先ブランチのルールを適用する。ファイルが存在しない場合はスキップ（通知なし）。

#### 12. サイクル存在確認

`.aidlc/cycles/{{CYCLE}}/` の存在を確認：

```bash
ls -d .aidlc/cycles/{{CYCLE}}/ 2>/dev/null
```

出力があれば `CYCLE_EXISTS`、エラーなら `CYCLE_NOT_EXISTS` と判断。

- **存在する場合**: Part 2（インセプション準備）へ進む
- **存在しない場合**: ステップ13（サイクルディレクトリ作成）へ進む

#### 13. サイクルディレクトリ作成

サイクル {{CYCLE}} のディレクトリを自動的に作成します。

**ディレクトリ構造・履歴ファイル作成**:
```bash
scripts/init-cycle-dir.sh {{CYCLE}}
```

このスクリプトは以下を一括で作成します:
- 10個のサイクル固有ディレクトリ（plans, requirements, story-artifacts/units, design-artifacts/domain-models, design-artifacts/logical-designs, design-artifacts/architecture, inception, construction/units, operations, history）
- history/inception.md（初期履歴ファイル）
- 共通バックログディレクトリ（.aidlc/cycles/backlog/, .aidlc/cycles/backlog-completed/）

**注**: `--dry-run` オプションで作成予定を確認できます。

**注意**: サイクル固有バックログは廃止されました。気づきは共通バックログに直接記録します（GitHub Issue）。

---
