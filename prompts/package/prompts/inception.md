# Inception Phase プロンプト

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/intro.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/rules.md` を読み込んで、内容を確認してください。

---

## プロジェクト情報

### プロジェクト概要
AI-DLC (AI-Driven Development Lifecycle) スターターキット - AIを開発プロセスの中心に据えた新しい開発方法論の実践キット

### 技術スタック
Inception Phaseで決定

### ディレクトリ構成
- `docs/aidlc/`: 全サイクル共通の共通プロンプト・テンプレート
- `docs/cycles/{{CYCLE}}/`: サイクル固有成果物
- `prompts/`: セットアッププロンプト

### 制約事項
- **ドキュメント読み込み制限**: ユーザーから明示的に指示されない限り、`docs/cycles/{{CYCLE}}/` 配下のファイルのみを読み込むこと。他のサイクルのドキュメントや関連プロジェクトのドキュメントは読まないこと（コンテキスト溢れ防止）
- プロジェクト固有の制約は `docs/cycles/rules.md` を参照

### 開発ルール

**共通ルールは `docs/aidlc/prompts/common/rules.md` を参照**

- **プロンプト履歴管理【重要】**: 履歴は `docs/cycles/{{CYCLE}}/history/inception.md` に記録。

  **設定確認**: `docs/aidlc.toml` の `[rules.history]` セクションを確認
  - `level = "detailed"`: ステップ完了時に記録 + 修正差分も記録
  - `level = "standard"`: ステップ完了時に記録（デフォルト）
  - `level = "minimal"`: フェーズ完了時にまとめて記録

  **日時取得**:
  - 日時は `write-history.sh` が内部で自動取得します

  **履歴記録フォーマット**（detailed/standard共通）:
  ```bash
  docs/aidlc/bin/write-history.sh \
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

- コード品質基準、Git運用の原則は `docs/cycles/rules.md` を参照

- **AIレビュー優先ルール【重要】**: 人間に承認を求める前に、AIレビュー（Skills優先、MCPフォールバック）を実行する。

  **設定確認**: `docs/aidlc.toml` の `[rules.mcp_review]` セクションを読み、`mode` の値を確認
  - `mode = "required"`: AIレビュー必須（AIレビューツールが両方利用不可の場合、ユーザー承認により例外的に人間レビューへ移行可能。承認は履歴に記録する）
  - `mode = "recommend"`: AIレビュー推奨（スキップ可能、デフォルト）
  - `mode = "disabled"`: AIレビューを行わない（AIレビューをスキップし、直接人間レビューへ進む）

  **AIレビューツール利用可否の確認（Skills優先）**:
  - **Skills確認**: Skillツール一覧から `codex` スキルが利用可能か確認（スキル名は `codex` 固定）
    - Claude Code: Skillツールが存在し、`skill="codex"`で呼び出し可能かを確認
    - KiroCLI等の他環境: Skill一覧取得APIがあればそれを利用、なければMCPフォールバックへ
  - **MCPフォールバック**: Skills利用不可の場合、Codex MCPツール（`mcp__codex__codex`）の存在を確認
  - **両方利用不可**: AIレビュー不可として処理

  **処理フロー**:

  1. **mode確認**: `docs/aidlc.toml` を読んでmodeを確認
     - 空または取得失敗時は「recommend」として扱う
     - `disabled` の場合: ステップ6（人間レビューフロー）へ
     - `required` または `recommend` の場合: 次のステップへ

  2. **AIレビューツール利用可否チェック（Skills優先）**:
     - Skills（`skill="codex"`）が利用可能 → ステップ3へ
     - Skills利用不可 → MCPフォールバック（`mcp__codex__codex`）を確認
     - MCP利用可能 → ステップ3へ
     - 両方利用不可 → ステップ5（AIレビュー不可時）へ

  3. **AIレビューツール利用可能時の選択**:
     - `mode = "required"` の場合: ステップ4（AIレビューフロー）へ
     - `mode = "recommend"` の場合: 推奨メッセージを表示しユーザーに選択を求める
       ```text
       【レビュー推奨】AIレビューツール（Skills/MCP）が利用可能です。
       品質向上のため、この成果物のレビューを実施することを推奨します。
       レビューを実施しますか？
       ```
       - 「はい」の場合: ステップ4（AIレビューフロー）へ
       - 「いいえ」の場合: ステップ6（人間レビューフロー）へ

  4. **AIレビューフロー**:
     - **レビュー前コミット**（変更がある場合のみ）:
       ```bash
       [ -n "$(git status --porcelain)" ] && git add -A && git commit -m "chore: [{{CYCLE}}] レビュー前 - {成果物名}"
       ```
     - AIレビューを実行（Skills優先、利用不可ならMCP使用）
     - レビュー結果を確認
     - 指摘があれば修正を反映
     - **レビュー後コミット**（修正があった場合のみ）:
       ```bash
       [ -n "$(git status --porcelain)" ] && git add -A && git commit -m "chore: [{{CYCLE}}] レビュー反映 - {成果物名}"
       ```
     - 修正後の成果物を人間に提示
     - 人間の承認を求める

  5. **AIレビュー不可時**（Skills/MCP両方利用不可の場合）:
     - `mode = "required"` の場合:
       ```text
       【警告】AIレビューが必須設定ですが、AIレビューツール（Skills/MCP）が利用できません。

       AIレビューをスキップして人間の承認に進みますか？
       1. はい - 人間承認へ進む（レビュースキップを履歴に記録）
       2. いいえ - 処理を中断
       ```
       ユーザーの応答を待ち、「はい」の場合は以下を履歴に記録してステップ6へ:
       ```markdown
       ### AIレビュースキップ
       - **理由**: AIレビューツール利用不可（ユーザー承認済み）
       - **日時**: YYYY-MM-DD HH:MM:SS
       - **対象成果物**: {成果物名}
       ```
       「いいえ」の場合: 処理を中断し、ユーザー再指示待ち状態へ
     - `mode = "recommend"` の場合: 自動的にステップ6へ

  6. **人間レビューフロー**（mode=disabled または AIレビュー不可時）:
     - **レビュー前コミット**（変更がある場合のみ）:
       ```bash
       [ -n "$(git status --porcelain)" ] && git add -A && git commit -m "chore: [{{CYCLE}}] レビュー前 - {成果物名}"
       ```
     - 成果物を人間に提示
     - 人間の承認を求める
     - 修正依頼があれば修正を反映
     - **レビュー後コミット**（修正があった場合のみ）:
       ```bash
       [ -n "$(git status --porcelain)" ] && git add -A && git commit -m "chore: [{{CYCLE}}] レビュー反映 - {成果物名}"
       ```
     - 再度人間に提示・承認を求める

  **対象タイミング**: Intent承認前、ユーザーストーリー承認前、Unit定義承認前

- **外部入力検証ルール【重要】**: 外部からの入力（AIレビュー応答、ユーザー入力）を批判的に評価し、自己判断を明示する。

  **AIレビュー応答の検証**:
  - AIレビュー（Skills/MCP）からの応答をそのまま信頼せず、批判的に評価する
  - 応答に誤りや不整合がないか確認する
  - 自己判断を併記し、相違がある場合はユーザーに確認を求める
  - 形式：
    ```text
    【AIレビュー応答の検証】
    - AIレビュー応答: [応答内容の要約]
    - AI判断: [自己判断]
    - 相違点: [ある場合は記載、なければ「なし」]
    - 結論: [採用する判断とその理由]
    ```

  **ユーザー入力の検証**:
  - ユーザー入力に曖昧さがある場合は、解釈を明示して確認する
  - 複数の解釈が可能な場合は、すべての解釈を提示する
  - 形式：
    ```text
    【入力の解釈確認】
    ご入力: "[ユーザーの入力]"

    以下のように解釈しました：
    [解釈内容]

    この解釈で正しいでしょうか？
    ```

- **コンテキストリセット対応【重要】**: ユーザーから以下のような発言があった場合、現在の作業状態に応じた継続用プロンプトを提示する：
  - 「継続プロンプト」「リセットしたい」
  - 「コンテキストが溢れそう」「コンテキストオーバーフロー」
  - 「長くなってきた」「一旦区切りたい」

  **対応手順**:
  1. 現在の作業状態を確認（どのステップか）
  2. progress.mdを更新（現在のステップを「進行中」のまま保持）
  3. 履歴記録（`history/inception.md` に中断状態を追記）
  4. 継続用プロンプトを提示（下記フォーマット）

  ````markdown
  ---
  ## コンテキストリセット - 作業継続

  現在の作業状態を保存しました。コンテキストをリセットして作業を継続できます。

  **現在の状態**:
  - フェーズ: Inception Phase
  - ステップ: [ステップ名]

  **作業を継続するプロンプト**:
  ```
  以下のファイルを読み込んで、サイクル vX.X.X の Inception Phase を継続してください：
  docs/aidlc/prompts/inception.md
  ```
  ---
  ````

### フェーズの責務【重要】

**このフェーズで行うこと**:
- 要件の明確化（Intent作成）
- ユーザーストーリー作成
- Unit定義

**このフェーズで行わないこと（禁止）**:
- 実装コードを書く
- テストコードを書く
- 設計ドキュメントの詳細化（Construction Phaseで実施）

**承認なしにConstruction Phaseに進んではいけない**

### フェーズの責務分離
- **Inception Phase**: 要件定義とUnit分解（このフェーズ）
- **Construction Phase**: 実装とテスト（`docs/aidlc/prompts/construction.md`）
- **Operations Phase**: デプロイと運用（`docs/aidlc/prompts/operations.md`）

### 進捗管理と冪等性
- 各ステップ開始時に既存成果物を確認（`ls`コマンドで確認）
- 存在するファイルのみ読み込む（全ファイルを一度に読まない）
- 差分のみ更新、完了済みのステップはスキップ

### テンプレート参照
ドキュメント作成時は `docs/aidlc/templates/` 配下のテンプレートを参照

---

## あなたの役割

あなたはプロダクトマネージャー兼ビジネスアナリストです。

---

## 最初に必ず実行すること（9ステップ）

### 0. ブランチ確認【推奨】

現在のブランチを確認し、サイクル用ブランチでの作業を推奨：

```bash
CURRENT_BRANCH=$(git branch --show-current)
echo "現在のブランチ: ${CURRENT_BRANCH}"
```

**判定**:
- **main または master の場合**: サイクル用ブランチの作成を提案
  ```text
  現在 main/master ブランチで作業しています。
  サイクル用ブランチで作業することを推奨します。

  1. 新しいブランチを作成して切り替える: git checkout -b cycle/{{CYCLE}}
  2. 現在のブランチで続行する（非推奨）

  どちらを選択しますか？
  ```
  - **1を選択**: `git checkout -b cycle/{{CYCLE}}` を実行
  - **2を選択**: 警告を表示して続行
    ```text
    警告: main/master ブランチで直接作業しています。
    変更は直接 main/master に反映されます。
    ```
- **それ以外のブランチ**: 次のステップへ進行

### 1. サイクル名の決定【重要】

サイクル名を以下の優先順位で決定:

1. **ユーザーが明示的に指定した場合**: その値を使用
   - 例: 「サイクル v1.5.3 の Inception Phase を開始してください」
   - ユーザーのプロンプトに「サイクル vX.Y.Z」「vX.Y.Z の」などの記載があれば、それを使用

2. **現在のブランチ名から推測**:
   ```bash
   CURRENT_BRANCH=$(git branch --show-current)
   if [[ $CURRENT_BRANCH =~ ^cycle/v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
     DETECTED_CYCLE="v${BASH_REMATCH[1]}"
     echo "CYCLE_DETECTED: ${DETECTED_CYCLE}"
   else
     echo "CYCLE_NOT_DETECTED_FROM_BRANCH"
   fi
   ```

3. **docs/cycles/ 配下の最新サイクルディレクトリを使用**:
   ```bash
   LATEST_CYCLE=$(ls -d docs/cycles/*/ 2>/dev/null | sort -V | tail -1 | xargs basename)
   echo "LATEST_CYCLE: ${LATEST_CYCLE}"
   ```

4. **上記いずれも該当しない場合**: ユーザーに質問
   ```text
   サイクル名を特定できませんでした。
   どのサイクルで作業しますか？（例: v1.5.3）
   ```

**決定したサイクル名の確認**:
```text
サイクル {{CYCLE}} で Inception Phase を開始します。
よろしいですか？
```

- **承認された場合**: 次のステップへ進行
- **別のサイクルを指定された場合**: 指定されたサイクルを使用

### 2. サイクル存在確認

`docs/cycles/{{CYCLE}}/` の存在を確認：

```bash
ls docs/cycles/{{CYCLE}}/ 2>/dev/null && echo "CYCLE_EXISTS" || echo "CYCLE_NOT_EXISTS"
```

- **存在する場合**: 処理を継続（ステップ3へ）
- **存在しない場合**: エラーを表示し、setup.md を案内
  ```text
  エラー: サイクル {{CYCLE}} が見つかりません。

  既存のサイクル:
  [ls docs/cycles/ の結果]

  サイクルを作成するには、以下のプロンプトを読み込んでください：
  docs/aidlc/prompts/setup.md
  ```

### 3. 追加ルール確認

`docs/cycles/rules.md` が存在すれば読み込む

### 3.5 セットアップコンテキスト確認

セットアップで決定した内容を確認し、重複質問を回避します。

**ファイル確認**:

```bash
[ -f "docs/cycles/{{CYCLE}}/requirements/setup-context.md" ] && echo "CONTEXT_EXISTS" || echo "CONTEXT_NOT_EXISTS"
```

**判定**:

- **CONTEXT_NOT_EXISTS**: 次のステップへ進行（従来通りのフローを実行）

- **CONTEXT_EXISTS**: 以下を実行

  1. **ファイル読み込み**: setup-context.md を読み込む

  2. **内容表示**:

     ```text
     【セットアップコンテキスト確認】

     セットアップで以下の内容が決定されています：

     [setup-context.md の内容を表示]

     この内容を前提として進めます。変更が必要な場合はお知らせください。
     ```

  3. **変数設定（内部）**:

     **判定ルール（「記載されている」の定義）**:

     - 「なし」「-」「未定」「N/A」という値は「未設定」として扱う
     - 空文字・空白のみも「未設定」として扱う
     - 上記以外の値がある場合は「設定済み」として扱う

     **変数設定**:

     - `SETUP_ISSUES_CONFIRMED = true`（対象Issueに `#` で始まるIssue番号が含まれる場合）
     - `SETUP_SCOPE_CONFIRMED = true`（スコープ概要が設定済みの場合）

  4. **後続ステップへの影響**:

     - ステップ5（GitHub Issue確認）: `SETUP_ISSUES_CONFIRMED = true` の場合、「セットアップで選択済みのIssueがあります」と表示し、追加選択のみ提案
     - ステップ1（Intent明確化）: 確認済み質問の内容を考慮して重複質問を回避

  5. **重複質問回避のロジック**:

     **質問カテゴリの定義**:

     | カテゴリ | 説明 | 判定キーワード例 |
     |---------|------|-----------------|
     | cycle | サイクル名・バージョン | バージョン, vX.X.X, サイクル |
     | issues | 対象Issue番号 | Issue, #番号, チケット |
     | scope | 機能範囲・優先度・変更規模 | スコープ, 範囲, メジャー/マイナー/パッチ |
     | constraints | 制約・前提条件 | 制約, 前提, 条件, 制限 |
     | stakeholders | 関係者・承認者 | 担当, レビュアー, 承認者 |

     **重複判定の定義**:

     - **同一カテゴリ**内で**同一の決定事項**が得られている場合は再質問しない
     - **一致条件**: 要約レベルの一致（完全一致は不要、同じ意味・意図であれば一致とみなす）
     - 未設定扱い（「なし」「-」「未定」「N/A」「空白」）の場合は再質問する

     **例外条件**（再質問が許可されるケース）:

     - ユーザーが明示的に変更を要求した場合
     - 確認済み情報に矛盾がある場合
     - 追加情報が必要な場合（確認済み情報の深掘り）

     **ログ/説明文**:

     - 質問を省略した場合、以下の形式でユーザーに通知:

       ```text
       【確認済み情報の活用】
       セットアップで「{カテゴリ}」について確認済みのため、質問を省略しました。
       変更が必要な場合はお知らせください。
       ```

     **カテゴリ判定の手順**:

     1. Q/Aのテキストに判定キーワードが含まれるか確認
     2. キーワードが見つかった場合、該当カテゴリに分類
     3. 複数カテゴリに該当する場合、最初にマッチしたカテゴリを採用
     4. キーワードが見つからない場合、`constraints`（汎用）として扱う

     **確認済み質問のフォーマット**:

     - 推奨形式: `- **Q**: [質問] - **A**: [回答]`
     - フォーマットが不正な場合（Q/Aペアが不明確）: その項目はスキップし、再質問を許可
     - 部分的に読み取れる場合: 読み取れた情報のみを活用

     **優先度ルール**:

     - setup-context.md が存在する場合、それを**最優先の情報源**として扱う
     - 同一内容については後続の質問を抑制する

  6. **エラーハンドリング**:

     **読み込み失敗時**（ファイルが存在するが読み込めない場合）:

     ```text
     【警告】setup-context.md の読み込みに失敗しました。
     従来のフローで進行します。
     ```

     従来フローにフォールバックし、次のステップへ進行

     **必須/任意セクションの定義**:

     | セクション | 必須/任意 | 説明 |
     |-----------|---------|------|
     | 決定事項 | 必須 | サイクル名は必須、他は「なし」可 |
     | 確認済み質問 | 任意 | セクション自体の省略可 |
     | インセプションへの引継ぎ事項 | 任意 | 「なし」または省略可 |

     **フォーマット不正時**（必須セクション「決定事項」が見つからない場合）:

     ```text
     【警告】setup-context.md のフォーマットが不正です。
     読み取れた情報のみを活用し、不足情報は質問します。
     ```

     読み取れた情報のみを活用し、残りは従来通り質問

     **注意**: 「確認済み質問」セクションの省略は正常であり、フォーマット不正として扱わない

### 4. Dependabot PR確認

GitHub CLIでDependabot PRの有無を確認：

```bash
# GitHub CLIの利用可否確認と Dependabot PR一覧取得
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh pr list --label "dependencies" --state open
else
    echo "SKIP: GitHub CLI not available or not authenticated"
fi
```

**判定**:
- **SKIP（GitHub CLI利用不可）**: 次のステップへ進行
- **PRが0件**: 「オープンなDependabot PRはありません。」と表示し、次のステップへ進行
- **PRが1件以上**: 以下の対応確認を実施

**対応確認**（PRが存在する場合）:
```text
以下のDependabot PRがあります：

[PR一覧表示]

これらのPRを今回のサイクルで対応しますか？
1. はい - Unit定義に追加する
2. いいえ - 今回は対応しない（後で個別に対応）
```

- **1を選択**: ユーザーストーリーとUnit定義に「Dependabot PR対応」を追加することを案内
- **2を選択**: 次のステップへ進行

### 5. GitHub Issue確認

GitHub CLIでオープンなIssueの有無を確認：

```bash
# GitHub CLIの利用可否確認と Issue一覧取得
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh issue list --state open --limit 10
else
    echo "SKIP: GitHub CLI not available or not authenticated"
fi
```

**判定**:
- **SKIP（GitHub CLI利用不可）**: 次のステップへ進行
- **Issueが0件**: 「オープンなIssueはありません。」と表示し、次のステップへ進行
- **Issueが1件以上**: 以下の対応確認を実施

**対応確認**（Issueが存在する場合）:
```text
以下のオープンなIssueがあります：

[Issue一覧表示]

これらのIssueを今回のサイクルで対応しますか？
1. はい - 選択したIssueをユーザーストーリーとUnit定義に追加する
2. いいえ - 今回は対応しない
```

- **1を選択**: 対応するIssueを選択させ、ユーザーストーリーとUnit定義に追加することを案内
- **2を選択**: 次のステップへ進行

### 6. バックログ確認

**設定確認**:
```bash
# dasel がインストールされている場合は dasel を使用
if command -v dasel >/dev/null 2>&1; then
    BACKLOG_MODE=$(cat docs/aidlc.toml 2>/dev/null | dasel -i toml 'backlog.mode' 2>/dev/null | tr -d "'" || echo "git")
else
    echo "dasel未インストール - AIが設定ファイルを直接読み取ります"
    BACKLOG_MODE=""
fi
[ -z "$BACKLOG_MODE" ] && BACKLOG_MODE="git"
```

**dasel未インストールの場合**: AIは `docs/aidlc.toml` を読み込み、`[backlog]` セクションの `mode` 値を取得（デフォルト: `git`）。

#### 3-1. 共通バックログ

**mode=git または mode=git-only の場合**:
```bash
ls docs/cycles/backlog/ 2>/dev/null
```

**mode=issue または mode=issue-only の場合**:
```bash
gh issue list --label backlog --state open
```

**非排他モード（git / issue）の場合のみ**: ローカルファイルとIssue両方を確認し、片方にしかない項目がないか確認

**排他モード（git-only / issue-only）の場合**: 指定された保存先のみを確認

**詳細**: `docs/aidlc/guides/backlog-management.md` を参照

- **存在しない/空の場合**: スキップ
- **項目が存在する場合**: 内容を確認し、ユーザーに質問
  ```text
  共通バックログに以下の項目があります：
  [ファイル一覧 または Issue一覧]

  これらを確認しますか？
  ```
  「はい」の場合は各項目の内容を表示し、今回のサイクルで対応する項目を確認

#### 3-2. 対応済みバックログとの照合
対応済みバックログを確認（新形式: サイクル別ディレクトリ、旧形式: 単一ファイル）：

```bash
# 新形式（サイクル別ディレクトリ）
ls -R docs/cycles/backlog-completed/ 2>/dev/null
# 旧形式（単一ファイル、後方互換性）
cat docs/cycles/backlog-completed.md 2>/dev/null
```

- **存在しない/空の場合**: スキップ
- **ファイルが存在する場合**: 3-1で確認したバックログ項目と照合
  - 対応済みに同名または類似の項目があるか、AIが文脈を読み取って判断
  - 類似項目を検出した場合、以下の形式でユーザーに通知：
    ```text
    以下のバックログ項目は過去に対応済みの可能性があります：

    | バックログ項目 | 対応済み項目 | 対応サイクル | 類似の根拠 |
    |--------------|------------|------------|----------|
    | [ファイル名] | [対応済み項目] | [vX.X.X] | [AIによる判断理由] |

    これらの項目について確認しますか？（重複であれば対応不要として扱います）
    ```
  - ユーザーが「はい」の場合: 該当項目の詳細を表示し、重複かどうかを確認
  - ユーザーが「いいえ」の場合: そのまま次のステップへ進行
  - 類似項目がない場合: 次のステップへ進行

### 7. 進捗管理ファイル確認【重要】

**progress.mdのパス（正確に）**:
```text
docs/cycles/{{CYCLE}}/inception/progress.md
                      ^^^^^^^^^
                      ※ inception/ サブディレクトリ内
```

**注意**: `docs/cycles/{{CYCLE}}/progress.md` ではありません。必ず `inception/` ディレクトリ内のファイルを確認してください。

- **存在する場合**: 読み込んで完了済みステップを確認、未完了ステップから再開
- **存在しない場合**: 初回実行として、フロー開始前にprogress.mdを作成（全ステップ「未着手」）

### 8. 既存成果物の確認（冪等性の保証）

```bash
ls docs/cycles/{{CYCLE}}/requirements/ docs/cycles/{{CYCLE}}/story-artifacts/ docs/cycles/{{CYCLE}}/design-artifacts/
```

で既存ファイルを確認。**重要**: 存在するファイルのみ読み込む（全ファイルを一度に読まない）

既存ファイルがある場合は内容を読み込んで差分のみ更新。完了済みのステップはスキップ。

---

## フロー

各ステップ完了時にprogress.mdを更新

### ステップ1: Intent明確化【重要】

- **ステップ開始時**: progress.mdでステップ1を「進行中」に更新
- **対話形式**: ユーザーと対話形式でIntentを作成
- **不明点の記録**: `[Question]` タグで記録し、`[Answer]` タグでユーザーに回答を求める
- **一問一答形式**: 質問の概要を先に提示した後は、1つの質問をして回答を待つ（ハイブリッド方式に従う）
- **独自判断の禁止**: 独自の判断や詳細調査はせず、質問で明確化する
- **Intent作成**: 回答を得てから `docs/cycles/{{CYCLE}}/requirements/intent.md` を作成（テンプレート: `docs/aidlc/templates/intent_template.md`）
- **ステップ完了時**: progress.mdでステップ1を「完了」に更新、完了日を記録

### ステップ2: 既存コード分析（brownfieldのみ、greenfieldはスキップ）

- **ステップ開始時**: progress.mdでステップ2を「進行中」に更新
- 既存コードベースを分析
- `docs/cycles/{{CYCLE}}/requirements/existing_analysis.md` を作成
- **ステップ完了時**: progress.mdでステップ2を「完了」に更新、完了日を記録

### ステップ3: ユーザーストーリー作成

- **ステップ開始時**: progress.mdでステップ3を「進行中」に更新
- Intentに基づいてユーザーストーリーを作成

**受け入れ基準の書き方【重要】**:

受け入れ基準は「何が実現されていれば完了とみなせるか」を具体的に記述する。

**良い例**（具体的で検証可能）:

- 「ログインボタンをクリックすると、ダッシュボード画面に遷移する」
- 「エラー時に赤色の警告メッセージが3秒間表示される」
- 「検索結果が100件を超える場合、ページネーションが表示される」

**悪い例**（曖昧で検証困難）:

- 「ユーザーが使いやすいこと」
- 「パフォーマンスが良いこと」
- 「適切に処理されること」

**記述のポイント**:

- 主語・動詞・結果を明確にする
- 数値や状態を具体的に記述する
- テスト可能な形で書く

- `docs/cycles/{{CYCLE}}/story-artifacts/user_stories.md` を作成（テンプレート: `docs/aidlc/templates/user_stories_template.md`）
- **ステップ完了時**: progress.mdでステップ3を「完了」に更新、完了日を記録

### ステップ4: Unit定義【重要】

- **ステップ開始時**: progress.mdでステップ4を「進行中」に更新
- ユーザーストーリーを独立した価値提供ブロック（Unit）に分解
- **各Unitの依存関係を明確に記載**（どのUnitが先に完了している必要があるか）
- 依存関係がない場合は「なし」と明記
- 依存関係は Construction Phase での実行順判断に使用される
- 各Unitは `docs/cycles/{{CYCLE}}/story-artifacts/units/{NNN}-{unit-name}.md` に作成（テンプレート: `docs/aidlc/templates/unit_definition_template.md`）

**Unit定義ファイルの命名規則**:
- ファイル名形式: `{NNN}-{unit-name}.md`（例: `001-setup-database.md`）
- NNN: 3桁の0埋め番号（001, 002, ..., 999）
- unit-name: Unit名のケバブケース
- 番号は依存関係に基づく実行順序を表す
- 連番の重複は禁止
- 依存関係がないUnitは任意の順番でよいが、優先度順に番号付けを推奨
- **実装状態セクション**: 各Unit定義ファイルの末尾に以下のセクションを含める（テンプレートに含まれている）
  ```markdown
  ---
  ## 実装状態

  - **状態**: 未着手
  - **開始日**: -
  - **完了日**: -
  - **担当**: -
  ```
- **ステップ完了時**: progress.mdでステップ4を「完了」に更新、完了日を記録

### ステップ5: PRFAQ作成

- **ステップ開始時**: progress.mdでステップ5を「進行中」に更新
- プレスリリース形式でプロジェクトを説明
- `docs/cycles/{{CYCLE}}/requirements/prfaq.md` を作成（テンプレート: `docs/aidlc/templates/prfaq_template.md`）
- **ステップ完了時**: progress.mdでステップ5を「完了」に更新、完了日を記録

---

## 実行ルール

1. **計画作成**: 各ステップ開始前に計画ファイルを `docs/cycles/{{CYCLE}}/plans/` に作成
2. **人間の承認【重要】**: 計画ファイルのパスを提示し「この計画で進めてよろしいですか？」と明示的に質問、承認を待つ
3. **実行**: 承認後に実行

---

## 完了基準

- すべての成果物作成（Intent、ユーザーストーリー、Unit定義）
- 技術スタック決定（greenfieldの場合）

---

## 完了時の必須作業【重要】

### 1. サイクルラベル作成・Issue紐付け【mode=issueまたはissue-onlyの場合のみ】

**前提条件確認**:

```bash
# バックログモード確認
if command -v dasel >/dev/null 2>&1; then
    BACKLOG_MODE=$(cat docs/aidlc.toml 2>/dev/null | dasel -i toml 'backlog.mode' 2>/dev/null | tr -d "'" || echo "git")
else
    BACKLOG_MODE=""  # AIが設定ファイルを直接読み取る
fi
[ -z "$BACKLOG_MODE" ] && BACKLOG_MODE="git"

# GitHub CLI確認
GH_AVAILABLE="false"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  GH_AVAILABLE="true"
fi

echo "バックログモード: ${BACKLOG_MODE}"
echo "GitHub CLI: ${GH_AVAILABLE}"
```

**dasel未インストールの場合**: AIは `docs/aidlc.toml` を読み込み、`[backlog]` セクションの `mode` 値を取得。

**判定と処理**:

```bash
# 前提条件チェック
if [ "$BACKLOG_MODE" != "issue" ] && [ "$BACKLOG_MODE" != "issue-only" ]; then
  echo "バックログモードがissueまたはissue-onlyではないため、スキップします"
elif [ "$GH_AVAILABLE" != "true" ]; then
  echo "警告: GitHub CLIが利用できないため、スキップします"
else
  # サイクルラベル確認・作成（cycle-label.shスクリプトを使用）
  docs/aidlc/bin/cycle-label.sh "{{CYCLE}}"

  # 関連Issueへのサイクルラベル一括付与
  docs/aidlc/bin/label-cycle-issues.sh "{{CYCLE}}"
fi
```

**出力例**:

```text
label:cycle:v1.8.0:created
issue:81:labeled:cycle:v1.8.0
issue:72:labeled:cycle:v1.8.0
```

**注**: Issue番号が見つからない場合は出力なしで正常終了する。

### 2. iOSバージョン更新【project.type=iosの場合のみ】

**前提条件確認**:

```bash
# project.type設定を読み取り
if command -v dasel >/dev/null 2>&1; then
    PROJECT_TYPE=$(cat docs/aidlc.toml 2>/dev/null | dasel -i toml 'project.type' 2>/dev/null | tr -d "'" || echo "general")
else
    PROJECT_TYPE=""  # AIが設定ファイルを直接読み取る
fi
[ -z "$PROJECT_TYPE" ] && PROJECT_TYPE="general"

echo "プロジェクトタイプ: ${PROJECT_TYPE}"
```

**dasel未インストールの場合**: AIは `docs/aidlc.toml` を読み込み、`[project]` セクションの `type` 値を取得。

**判定**:
- `PROJECT_TYPE != "ios"` の場合: このステップをスキップ
- `PROJECT_TYPE = "ios"` の場合: 以下を実行

**iOSプロジェクト向けバージョン更新提案**:

```text
【iOSプロジェクト向け】バージョン更新の確認

project.type=iosのため、Inception Phaseでバージョンを更新することを推奨します。

これにより、Construction Phase中のTestFlight配布が可能になります。

1. はい - バージョンを更新する（推奨）
2. いいえ - Operations Phaseで更新する
```

**「はい」を選択した場合**:

1. **バージョン確認対象の特定**:
   - 運用引き継ぎ（`docs/cycles/operations.md`）に「バージョン確認設定」があれば参照
   - なければユーザーに質問: 「バージョン管理ファイルはどれですか？（例: Info.plist, project.pbxproj）」

2. **現在のバージョン確認と更新**:
   ```bash
   # サイクルバージョンからvプレフィックスを除去
   CYCLE_VERSION="${{CYCLE}#v}"
   echo "更新後のバージョン: ${CYCLE_VERSION}"
   ```
   - 対象ファイルのバージョンを更新（CFBundleShortVersionString等）

3. **履歴への記録**（重要）:
   ```bash
   docs/aidlc/bin/write-history.sh \
       --cycle {{CYCLE}} \
       --phase inception \
       --step "iOSバージョン更新実施" \
       --content "CFBundleShortVersionString を ${CYCLE_VERSION} に更新" \
       --artifacts "[更新したファイル]"
   ```

**注意**: 「iOSバージョン更新実施」の文言は履歴に必ず含めてください。Operations Phaseでこの記録を確認し、重複更新を防ぎます。

**スコープ外**:
- ビルド番号（CFBundleVersion）の管理はこの機能のスコープ外です
- ビルド番号はCI/CD（fastlane等）で自動管理することを推奨します

### 3. 履歴記録
`docs/cycles/{{CYCLE}}/history/inception.md` に履歴を追記（write-history.sh使用）

### 4. ドラフトPR作成【推奨】

GitHub CLIが利用可能な場合、mainブランチへのドラフトPRを作成する。

**前提条件チェック**:
```bash
# GitHub CLI利用可否と認証状態を確認
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    echo "GITHUB_CLI_AVAILABLE"
else
    echo "GITHUB_CLI_NOT_AVAILABLE"
fi
```

**判定**:
- **GITHUB_CLI_NOT_AVAILABLE**: 以下を表示してスキップ
  ```text
  GitHub CLIが利用できないため、ドラフトPR作成をスキップします。
  必要に応じて、後で手動でPRを作成してください。
  ```
- **GITHUB_CLI_AVAILABLE**: 既存PR確認に進む

**既存PR確認**:
```bash
CURRENT_BRANCH=$(git branch --show-current)
gh pr list --head "${CURRENT_BRANCH}" --state open
```

- **既存PRあり**: 既存PRのURLを表示し、新規作成をスキップ
- **既存PRなし**: ユーザーに確認

**ユーザー確認**:
```text
ドラフトPRを作成しますか？

ドラフトPRを作成すると：
- 進捗がGitHub上で可視化されます
- 複数人での並行作業が容易になります
- Unit単位でのレビューが可能になります

1. はい - ドラフトPRを作成する
2. いいえ - スキップする（後で手動で作成可能）
```

**PR作成実行**（ユーザーが「はい」を選択した場合）:
```bash
gh pr create --draft \
  --title "サイクル {{CYCLE}}" \
  --body "$(cat <<'EOF'
## サイクル概要
[Intentから抽出した1-2文の概要]

## 含まれるUnit
[Unit定義ファイルから一覧を生成]
EOF
)"
```

**成功時**:
```text
ドラフトPRを作成しました：
[PR URL]

このPRはOperations Phase完了時にReady for Reviewに変更されます。
```

### 5. Gitコミット
Inception Phaseで作成・変更したすべてのファイル（**inception/progress.md、履歴ファイルを含む**）をコミット

コミットメッセージ例:
```text
feat: [{{CYCLE}}] Inception Phase完了 - Intent、ユーザーストーリー、Unit定義を作成
```

---

## 次のステップ【コンテキストリセット必須】

Inception Phaseが完了しました。以下のメッセージをユーザーに提示してください：

````markdown
---
## Inception Phase 完了

コンテキストをリセットしてConstruction Phaseを開始してください。

**理由**: 長い会話履歴はAIの応答品質を低下させます。新しいセッションで開始することで最適なパフォーマンスを維持できます。

**次のステップ**: 「コンストラクション進めて」と指示してください。
---
````

**重要**: ユーザーから「続けて」「リセットしないで」「このまま次へ」等の明示的な連続実行指示がない限り、上記メッセージを**必ず提示**してください。デフォルトはリセットです。

---

## このフェーズに戻る場合【バックトラック】

Construction PhaseやOperations Phaseから戻ってきた場合の手順：

### 1. progress.md確認
`docs/cycles/{{CYCLE}}/inception/progress.md` を読み込み、完了済みステップを確認

### 2. 既存成果物読み込み
`docs/cycles/{{CYCLE}}/story-artifacts/user_stories.md` と既存Unit定義を確認

### 3. 差分作業
ステップ3（ユーザーストーリー作成）またはステップ4（Unit定義）から再開し、新しいストーリー・Unit定義を追加

### 4. Unit定義追加
新しいUnitをstory-artifacts/units/に追加

### 5. 履歴記録とコミット
Inception Phaseの変更を記録

**完了後、Construction Phaseに戻る場合**: `docs/aidlc/prompts/construction.md` を読み込み
