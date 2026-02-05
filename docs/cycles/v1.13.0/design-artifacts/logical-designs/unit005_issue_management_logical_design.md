# 論理設計: Issue管理プロセス改善

## 概要

AI-DLCの各フェーズプロンプトにIssue管理セクションを追加し、ステータスラベルによる進捗管理とPRマージ時の自動クローズを実現する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコードはImplementation Phase（コード生成ステップ）で作成します。

## アーキテクチャパターン

プロンプト駆動型ドキュメント設計。各フェーズのプロンプトに一貫したIssue管理セクションを追加し、ガイドドキュメントで運用詳細を定義する。

## コンポーネント構成

### ファイル構成

```text
prompts/package/
├── prompts/
│   ├── inception.md      # Issue管理セクション追加、サイクルPRテンプレート修正
│   ├── construction.md   # Issue管理セクション追加、Unit PRテンプレート修正
│   └── operations.md     # Issue管理セクション追加、PRマージ説明追加
├── guides/
│   └── issue-management.md  # 新規作成: ステータスラベル定義と運用ガイド
└── bin/
    ├── issue-ops.sh           # 修正: remove-label, set-status サブコマンド追加
    └── label-cycle-issues.sh  # 変更なし（サイクルラベル付与のみ）
```

### コンポーネント詳細

#### 1. issue-management.md（新規作成）

- **責務**: ステータスラベルの定義、状態遷移、運用フローの詳細説明
- **依存**: なし（独立ガイドドキュメント）
- **参照元**: 各フェーズプロンプトから参照

**構成**:

```text
# Issue管理ガイド
├── 概要
├── ステータスラベル定義
│   ├── ラベル一覧（status:backlog, status:in-progress, status:blocked, status:waiting-for-review）
│   ├── 状態遷移図
│   └── ラベル作成コマンド
├── フェーズ別操作フロー
│   ├── Inception Phase
│   ├── Construction Phase
│   └── Operations Phase
├── PRとIssueの紐付け
│   ├── サイクルPRでのCloses記載
│   ├── Unit PRでの参照記載
│   └── 自動クローズの仕組み
└── トラブルシューティング
```

#### 2. inception.md（修正）

- **責務**: Inception PhaseでのIssue管理操作を定義
- **修正箇所**:
  1. Issue管理セクション追加（ステップ13近辺）
  2. ドラフトPR作成テンプレート修正（808-820行目付近）

**Issue管理セクション追加内容**:

- 対応Issue選択後のサイクルラベル付与
- ステータスラベル（status:backlog）の初期設定（オプション）

**ドラフトPRテンプレート修正**:

- 現在:
  ```markdown
  ## サイクル概要
  [Intentから抽出した1-2文の概要]

  ## 含まれるUnit
  [Unit定義ファイルから一覧を生成]
  ```

- 修正後:
  ```markdown
  ## サイクル概要
  [Intentから抽出した1-2文の概要]

  ## 含まれるUnit
  [Unit定義ファイルから一覧を生成]

  ## Closes
  [Unit定義ファイルの関連Issueから抽出]
  - Closes #XX
  - Closes #YY
  ```

#### 3. construction.md（修正）

- **責務**: Construction PhaseでのIssue管理操作を定義
- **修正箇所**:
  1. Issue管理セクション追加（Unit開始時の操作）
  2. ドラフトPRテンプレート修正（391-405行目付近）

**Issue管理セクション追加内容**:

- Unit開始時: ステータスを `status:in-progress` に遷移
- ブロック発生時: ステータスを `status:blocked` に遷移
- Unit完了時: ステータスを `status:waiting-for-review` に遷移

**ドラフトPRテンプレート修正**:

- 現在（Unit PR）:
  ```markdown
  ## Unit概要
  [Unit定義から抽出した概要]

  ---
  :construction: このPRは作業中です。Unit完了時にレビュー依頼を行います。
  ```

- 修正後:
  ```markdown
  ## Unit概要
  [Unit定義から抽出した概要]

  ## 関連Issue
  - #XX（参照のみ、サイクルPRでCloses）

  ---
  :construction: このPRは作業中です。Unit完了時にレビュー依頼を行います。
  ```

#### 4. operations.md（修正）

- **責務**: Operations PhaseでのIssue管理操作を定義
- **修正箇所**:
  1. Issue管理セクション追加
  2. PRマージセクション（779行目付近）に自動クローズ説明追加
  3. サイクルPR Ready化時のCloses確認

**Issue管理セクション追加内容**:

- リリース前のIssueステータス確認
- PRマージ時の自動クローズ説明
- 残存Issue確認と次サイクル引き継ぎ

**PRマージセクション追加内容**:

```text
**自動クローズについて**:
PRがマージされると、PR本文に `Closes #XX` と記載されたIssueは自動的にクローズされます。

**マージ前の確認**:
- サイクルPRの「Closes」セクションに全対応Issueが記載されているか確認
- 記載漏れがある場合は、PR本文を編集して追加
```

#### 5. issue-ops.sh（修正）

- **責務**: ステータスラベル操作機能の追加
- **既存機能**:
  - `label <issue_number> <label_name>` - ラベル追加
  - `close <issue_number>` - Issueクローズ
- **追加機能**:
  - `remove-label <issue_number> <label_name>` - ラベル削除
  - `set-status <issue_number> <status>` - ステータスラベル設定（排他制御付き）

**コマンドインターフェース**:

```bash
# 既存
./issue-ops.sh label 123 "cycle:v1.13.0"
./issue-ops.sh close 123

# 追加: ラベル削除
./issue-ops.sh remove-label 123 "status:backlog"

# 追加: ステータス設定（既存status:*を削除してから付与）
./issue-ops.sh set-status 123 in-progress
```

**出力形式**:

```text
# ラベル削除
issue:123:removed-label:status:backlog

# ステータス設定（削除→追加）
issue:123:status-updated:in-progress
```

**set-statusの動作**:

1. 指定Issueの既存 `status:*` ラベルを取得
2. 既存ステータスラベルを削除
3. 新しい `status:<status>` ラベルを追加

#### 6. label-cycle-issues.sh（変更なし）

- **責務**: サイクルラベルの一括付与（既存機能のまま）
- **変更**: なし（ステータスラベルは `issue-ops.sh set-status` で個別に操作）

## インターフェース設計

### コマンド（issue-ops.sh - 追加機能）

#### remove-label サブコマンド

- **パラメータ**:
  - issue_number: Integer - Issue番号（必須）
  - label_name: String - 削除するラベル名（必須）
- **戻り値**:
  - 成功時: `issue:<number>:removed-label:<label_name>`
  - エラー時: `issue:<number>:error:<reason>`（既存契約に従う）
- **副作用**: GitHub Issueからラベルを削除

**エラーケース**:
- Issue not found: `issue:<number>:error:not-found`
- Label not found: `issue:<number>:error:label-not-found`（ラベルが存在しない場合）
- gh未認証: `issue:<number>:error:gh-not-authenticated`

#### set-status サブコマンド

- **パラメータ**:
  - issue_number: Integer - Issue番号（必須）
  - status: StatusValue - ステータス値（必須）
- **戻り値**:
  - 成功時: `issue:<number>:status-updated:<status>`
  - エラー時: `issue:<number>:error:<reason>`（既存契約に従う）
- **副作用**: 既存ステータスラベルを削除し、新しいステータスラベルを付与

**実装詳細**:

1. **既存ステータスラベル取得**:
   ```bash
   gh issue view <issue_number> --json labels --jq '.labels[].name | select(startswith("status:"))'
   ```
2. **既存ステータスラベル削除**: 取得したラベルに対して `gh issue edit --remove-label`
3. **新ステータスラベル追加**: `gh issue edit --add-label "status:<status>"`

**エラーケース**:
- Issue not found: `issue:<number>:error:not-found`
- gh未認証: `issue:<number>:error:gh-not-authenticated`
- その他: `issue:<number>:error:unknown`

**StatusValue**:

- `backlog` → `status:backlog`
- `in-progress` → `status:in-progress`
- `blocked` → `status:blocked`
- `waiting-for-review` → `status:waiting-for-review`

### コマンド（label-cycle-issues.sh - 既存）

#### label-cycle-issues.sh

- **パラメータ**:
  - CYCLE: String - サイクル名（必須）
- **戻り値**: 処理結果（stdout）
- **副作用**: サイクル内の全関連Issueにサイクルラベルを付与
- **変更**: なし

## 処理フロー概要

### Inception Phase: サイクルPR作成フロー

**ステップ**:

1. Unit定義ファイルから関連Issue番号を抽出
2. 各Issue番号を `Closes #XX` 形式でリスト化
3. PRテンプレートに「Closes」セクションとして追加
4. `gh pr create` で PR作成

**関与するコンポーネント**: inception.md

### Construction Phase: Unit開始時ステータス更新フロー

**ステップ**:

1. Unit定義ファイルから関連Issue番号を取得
2. 各Issue番号に対して `issue-ops.sh set-status <issue_number> in-progress` を実行
   - 内部で既存の `status:*` ラベルを削除
   - 新しい `status:in-progress` ラベルを付与

**関与するコンポーネント**: construction.md, issue-ops.sh

### Construction Phase: ブロック発生時ステータス更新フロー

**ステップ**:

1. ブロックが発生したIssue番号を特定
2. `issue-ops.sh set-status <issue_number> blocked` を実行
3. ブロック解除時は `issue-ops.sh set-status <issue_number> in-progress` で復帰

**関与するコンポーネント**: construction.md, issue-ops.sh

### Construction Phase: Unit完了時ステータス更新フロー

**ステップ**:

1. Unit定義ファイルから関連Issue番号を取得
2. 各Issue番号に対して `issue-ops.sh set-status <issue_number> waiting-for-review` を実行

**関与するコンポーネント**: construction.md, issue-ops.sh

### Operations Phase: PRマージ時自動クローズフロー

**ステップ**:

1. サイクルPRの「Closes」セクションを確認
2. 記載漏れがないか確認（Unit定義と照合）
3. PRマージ実行
4. GitHub自動クローズによりIssueがクローズ

**関与するコンポーネント**: operations.md

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: N/A（プロンプト修正のみ）
- **対応策**: N/A

### セキュリティ

- **要件**: N/A
- **対応策**: N/A

### スケーラビリティ

- **要件**: N/A
- **対応策**: N/A

### 可用性

- **要件**: N/A
- **対応策**: N/A

## 技術選定

- **言語**: Markdown（プロンプト）、Bash（スクリプト）
- **ツール**: GitHub CLI (gh)

## 実装上の注意事項

- label-cycle-issues.sh の修正は軽微に抑える（既存機能への影響を最小化）
- ステータスラベルの排他制御（同時に1つのみ）はスクリプトで実現
- サイクルPRの「Closes」セクションは手動確認を推奨（自動生成の場合は確認ステップを追加）

## 変更箇所サマリ

| ファイル | 変更箇所 | 変更内容 |
|---------|---------|---------|
| inception.md | 808-820行目付近 | サイクルPRテンプレートにCloses追加 |
| inception.md | ステップ13付近 | Issue管理セクション追加（ラベル付与タイミング） |
| construction.md | 391-405行目付近 | Unit PRテンプレートに関連Issue参照追加 |
| construction.md | Unit開始/完了時 | Issue管理セクション追加（ステータス遷移） |
| operations.md | 779行目付近 | PRマージ時の自動クローズ説明追加 |
| operations.md | 6.6付近 | サイクルPR Ready化時のCloses確認 |
| issue-ops.sh | 新規サブコマンド | remove-label, set-status 追加 |
| label-cycle-issues.sh | 変更なし | サイクルラベル付与のみ（既存維持） |
| issue-management.md | 新規作成 | ステータスラベル定義と運用ガイド |

## 不明点と質問（設計中に記録）

[Question] ステータスラベルの排他制御をどこで実現するか？
[Answer] issue-ops.shの set-status サブコマンドで実現。付与前に既存status:*ラベルを取得・削除してから新ラベルを付与

[Question] サイクルPRのCloses記載は自動生成か手動か？
[Answer] 自動生成（Unit定義から抽出）+ 手動確認ステップを設ける

[Question] Unit単位のステータス更新をどう実現するか？（AIレビュー指摘）
[Answer] label-cycle-issues.sh（サイクル単位）ではなく、issue-ops.sh set-status（Issue単位）を使用。Unit定義から抽出したIssue番号に対して個別に実行
