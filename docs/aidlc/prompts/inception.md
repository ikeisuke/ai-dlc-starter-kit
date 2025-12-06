# Inception Phase プロンプト

---

## AI-DLC手法の要約

AI-DLCは、AIを開発の中心に据えた新しい開発手法です。従来のSDLCやAgileが「人間中心・長期サイクル」を前提としているのに対し、AI-DLCは「AI主導・短サイクル」で開発を推進します。

**主要原則**:
- **会話の反転**: AIが作業計画を提示し、人間が承認・判断する
- **設計技法の統合**: DDD・BDD・TDDをAIが自動適用
- **冪等性の保証**: 各ステップで既存成果物を確認し、差分のみ更新

**3つのフェーズ**: Inception（要件定義）→ Construction（実装）→ Operations（運用）
- **Inception**: Intentを具体的なUnitに分解し、ユーザーストーリーを作成
- **Construction**: ドメイン設計・論理設計・コード・テストを生成
- **Operations**: デプロイ・監視・運用を実施

**主要アーティファクト**:
- **Intent**: 開発の目的と狙い
- **Unit**: 独立した価値提供ブロック（Epic/Subdomainに相当）
- **Domain Design**: DDDに従ったビジネスロジックの構造化
- **Logical Design**: 非機能要件を反映した設計層

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
- プロジェクト固有の制約は `docs/aidlc/prompts/additional-rules.md` を参照

### 開発ルール
- **人間の承認プロセス【重要】**: 計画作成後、必ず以下を実行する
  1. 計画ファイルのパスをユーザーに提示
  2. 「この計画で進めてよろしいですか？」と明示的に質問
  3. ユーザーが「承認」「OK」「進めてください」などの肯定的な返答をするまで待機
  4. **承認なしで次のステップを開始してはいけない**

- **質問と回答の記録【重要】**: 独自の判断をせず、不明点はドキュメントに `[Question]` タグで記録し `[Answer]` タグを配置、ユーザーに回答を求める。**一問一答形式で対話する**：1つの質問をして回答を待ち、回答を得てから次の質問をする。**複数の質問をまとめて提示してはいけない**

- **Gitコミットのタイミング【必須】**: 以下のタイミングで**必ず**Gitコミットを作成する
  1. セットアップ完了時
  2. Inception Phase完了時
  3. 各Unit完了時
  4. Operations Phase完了時

  コミットメッセージは変更内容を明確に記述

- **プロンプト履歴管理【重要】**: history.mdファイルは初回セットアップ時に作成され、以降は必ずファイル末尾に追記（既存履歴を絶対に削除・上書きしない）。追記方法は Bash heredoc (`cat <<EOF | tee -a docs/cycles/{{CYCLE}}/history.md`)。日時取得の推奨方法:
  ```bash
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
  cat <<EOF | tee -a docs/cycles/{{CYCLE}}/history.md
  ---
  ## ${TIMESTAMP}
  ...
  EOF
  ```
  記録項目: 日時、フェーズ名、実行内容、プロンプト、成果物、備考

- コード品質基準、Git運用の原則は `docs/aidlc/prompts/additional-rules.md` を参照

- **気づきの記録【重要】**: 作業中に別Unitや将来のサイクルに関連する改善点・問題点に気づいた場合、`docs/cycles/{{CYCLE}}/backlog.md` の「このサイクルで発見した項目」セクションに記録する。現在の作業を中断せず、記録後に作業を継続する。

- **コンテキストリセット対応【重要】**: ユーザーから以下のような発言があった場合、現在の作業状態に応じた継続用プロンプトを提示する：
  - 「継続プロンプト」「リセットしたい」
  - 「コンテキストが溢れそう」「コンテキストオーバーフロー」
  - 「長くなってきた」「一旦区切りたい」

  **対応手順**:
  1. 現在の作業状態を確認（どのステップか）
  2. progress.mdを更新（現在のステップを「進行中」のまま保持）
  3. 履歴記録（history.mdに中断状態を追記）
  4. 継続用プロンプトを提示（下記フォーマット）

  ```markdown
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
  ```

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

## 最初に必ず実行すること（5ステップ）

### 1. サイクル存在確認
`docs/cycles/{{CYCLE}}/` の存在を確認：

```bash
ls docs/cycles/{{CYCLE}}/ 2>/dev/null && echo "CYCLE_EXISTS" || echo "CYCLE_NOT_EXISTS"
```

- **存在しない場合**: エラーを表示し、既存サイクル一覧を提示
  ```
  エラー: サイクル {{CYCLE}} が見つかりません。

  既存のサイクル:
  [ls docs/cycles/ の結果]

  セットアップを実行してサイクルを作成してください。
  ```
- **存在する場合**: 処理を継続

### 2. 追加ルール確認
`docs/aidlc/prompts/additional-rules.md` が存在すれば読み込む

### 3. バックログ確認
`docs/cycles/backlog.md` の存在を確認：

- **存在しない場合**: スキップ
- **存在する場合**: 内容を確認し、ユーザーに質問
  ```
  前サイクルからのバックログがあります。確認しますか？
  ```
  「はい」の場合はバックログ内容を表示し、今回のサイクルで対応する項目を確認

### 4. 進捗管理ファイル確認【重要】

`docs/cycles/{{CYCLE}}/inception/progress.md` が存在するか確認：

- **存在する場合**: 読み込んで完了済みステップを確認、未完了ステップから再開
- **存在しない場合**: 初回実行として、フロー開始前にprogress.mdを作成（全ステップ「未着手」）

### 5. 既存成果物の確認（冪等性の保証）

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
- **一問一答形式**: 1つの質問をして回答を待ち、複数の質問をまとめて提示しない
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
- `docs/cycles/{{CYCLE}}/story-artifacts/user_stories.md` を作成（テンプレート: `docs/aidlc/templates/user_stories_template.md`）
- **ステップ完了時**: progress.mdでステップ3を「完了」に更新、完了日を記録

### ステップ4: Unit定義【重要】

- **ステップ開始時**: progress.mdでステップ4を「進行中」に更新
- ユーザーストーリーを独立した価値提供ブロック（Unit）に分解
- **各Unitの依存関係を明確に記載**（どのUnitが先に完了している必要があるか）
- 依存関係がない場合は「なし」と明記
- 依存関係は Construction Phase での実行順判断に使用される
- 各Unitは `docs/cycles/{{CYCLE}}/story-artifacts/units/<unit_name>.md` に作成（テンプレート: `docs/aidlc/templates/unit_definition_template.md`）
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

- すべての成果物作成
- 技術スタック決定（greenfieldの場合）

---

## 完了時の必須作業【重要】

### 1. 履歴記録
`docs/cycles/{{CYCLE}}/history.md` に履歴を追記（heredoc使用、日時は `date '+%Y-%m-%d %H:%M:%S'` で取得）

### 2. Gitコミット
Inception Phaseで作成したすべてのファイル（**inception/progress.md、history.mdを含む**）をコミット

コミットメッセージ例:
```
feat: Inception Phase完了 - Intent、ユーザーストーリー、Unit定義、進捗管理ファイルを作成
```

---

## 次のステップ【コンテキストリセット推奨】

Inception Phaseが完了しました。コンテキストをリセットして次のステップを開始することを推奨します。

**理由**: 長い会話履歴はAIの応答品質を低下させる可能性があります。新しいセッションで開始することで、最適なパフォーマンスを維持できます。

**Construction Phaseを開始するプロンプト**:

```markdown
以下のファイルを読み込んで、サイクル vX.X.X の Construction Phase を開始してください：
docs/aidlc/prompts/construction.md
```

---

## このフェーズに戻る場合【バックトラック】

Construction PhaseやOperations Phaseから戻ってきた場合の手順：

### 1. progress.md確認
`docs/cycles/{{CYCLE}}/inception/progress.md` を読み込み、完了済みステップを確認

### 2. 既存成果物読み込み
`docs/cycles/{{CYCLE}}/story-artifacts/user_stories.md` と既存Unit定義を確認

### 3. 差分作業
ステップ3（ユーザーストーリー作成）またはステップ4（Unit定義）から再開し、新しいストーリー・Unit定義を追加

### 4. progress.md更新
construction/progress.mdに新しいUnitを追加

### 5. 履歴記録とコミット
Inception Phaseの変更を記録

**完了後、Construction Phaseに戻る場合**: `docs/aidlc/prompts/construction.md` を読み込み
