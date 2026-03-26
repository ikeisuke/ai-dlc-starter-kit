# 論理設計: Codex PRレビューIssue Comment承認検出

## 概要

`rules.md` のc判定ロジックにc-4（Issue Comment承認判定）を追加するための具体的な実装手順と挿入位置を定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存のc判定ロジックはパイプライン型（c-1→c-2→c-3の連鎖）。c-4はこのパイプラインの末尾に追加する拡張ポイントとして設計する。

## コンポーネント構成

### rules.md 内の判定フロー構成

```text
PRマージ前レビューコメント確認
├── 手順1: PRレビュー状態取得（a判定用）
├── 手順2: PRレビューコメント取得（b判定用）
├── 手順3: 未対応指摘の判定
│   ├── a. CHANGES_REQUESTED判定
│   ├── b. 未返信コメント判定
│   └── c. Codex PRレビュー状態判定
│       ├── c-1. Issue Comments取得 + @codex review コメント特定
│       │       出力: IssueCommentsDataset + ReviewRoundContext?
│       ├── c-2. リアクション取得・フィルタ
│       ├── c-3. リアクション判定（👍/👀）
│       └── c-4. Issue Comment承認判定【新規追加】
│               入力: IssueCommentsDataset + ReviewRoundContext
└── 手順4: 判定結果に応じた処理
```

### コンポーネント詳細

#### c-1の出力の明確化【既存の説明文を補足】

c-1は以下の2つの出力を持つ:
1. **ReviewRoundContext?**: 最新の`@codex review`コメントのID・`created_at`。コメントIDが取得できない場合はnull（c判定全体をスキップ）
2. **IssueCommentsDataset**: paginate結果のIssue Comments全件データ。c-4のフィルタリングで再利用

rules.mdでは「c-1で取得したIssue Commentsデータは、後続のc-4でも参照する」旨の注記を追加する。c-1のjqコマンド（`.id`抽出）は変更しない。

#### c-4. Issue Comment承認判定【新規】

- **責務**: IssueCommentsDatasetから、ReviewRoundContext以降のCodexボット承認コメントを検出
- **入力**: IssueCommentsDataset（c-1出力）+ ReviewRoundContext（c-1出力、必須）
- **前提条件**: ReviewRoundContextが存在すること。nullの場合はc-4を呼び出さない（既存ルール: c-1未特定時はc判定全体スキップ）
- **公開インターフェース**: 判定結果（`approved` | `none`）

## 処理フロー概要

### c-4の判定フロー

**前提**: c-3の判定が完了している。ReviewRoundContextが存在する。

**ステップ**:

1. **c-3結果の確認**: c-3が`approved`（👍リアクション）の場合 → c-4をスキップし`approved`を最終結果とする
2. **データ取得**: c-1で取得済みのIssueCommentsDatasetを使用（追加API呼び出し不要）
3. **フィルタリング**:
   - `user.login` == `chatgpt-codex-connector[bot]`
   - `created_at` >= ReviewRoundContext.latest_review_request_created_at
   - `body` が承認パターンにマッチ
4. **判定**:
   - マッチするコメントが1件以上 → `approved`
   - マッチなし → 状態変更なし（c-3の結果を維持）

**関与するコンポーネント**: c-1（データ供給）、c-3（前段判定）、c-4（承認判定）

### c判定全体の集約フロー

```text
c-1: Issue Comments取得 + @codex reviewコメント特定
  │  出力: IssueCommentsDataset + ReviewRoundContext?
  │  ReviewRoundContext が null → c判定全体スキップ（既存ルール）
  ↓
c-2: リアクション取得（c-2失敗時もc-4は実行可能）
  ↓
c-3: リアクション判定
  ├── 👍あり → approved（c-4スキップ）
  ├── 👀のみ → reviewing（c-4へ）
  └── なし or c-2失敗 → none（c-4へ）
  ↓
c-4: Issue Comment承認判定（c-3がapproved以外の場合のみ実行）
  ├── 承認コメントあり → approved
  ├── なし → c-3の結果を維持（reviewing or none）
  └── c-4失敗 → c-3の結果を保持
```

## rules.mdへの具体的な挿入位置

### 挿入位置1: c-1の説明文に注記追加

c-1の既存説明の後に以下の注記を追加:

```text
**注**: c-1で取得したIssue Commentsデータは、c-4（Issue Comment承認判定）でも参照する。
```

### 挿入位置2: c-3の後、手順4の前

現在の構成:
```text
   c-3. 判定（👍優先）:
   - +1 リアクションが存在 → 承認済み
   - eyes リアクションのみ → レビュー進行中
   - リアクションなし → スキップ

4. 判定結果に応じた処理:
```

変更後の構成:
```text
   c-3. 判定（👍優先）:
   - +1 リアクションが存在（eyesの有無に関わらず） → 「✓ Codex PRレビュー: 承認済み（👍）」と表示（c-4をスキップ）
   - eyes リアクションのみ → c-4へ
   - Codexボットからのリアクションなし → c-4へ

   c-4. Issue Comment承認判定（c-3でapproved以外の場合のみ実行）:
   [c-4の内容]

4. 判定結果に応じた処理:
```

### 承認パターンの正規表現

```text
Didn't find any major issues
```

- `test()` 関数（jqの場合）で本文に対してマッチ
- 大文字小文字は区別する（Codexの出力は固定フレーズのため）
- 将来パターン追加時は同一形式で列挙する

### c-4で使用するjqフィルタの設計方針

IssueCommentsDatasetに対して以下のフィルタを適用:

```text
フィルタ条件:
1. .user.login == "chatgpt-codex-connector[bot]"
2. .created_at >= {ReviewRoundContext.latest_review_request_created_at}
3. .body | test("Didn't find any major issues")
```

### エラーハンドリングの統合（フォールバック行列）

各サブ判定の失敗時のフォールバック方針を統一的に定義:

| 失敗箇所 | 他のc判定への影響 | フォールバック動作 | 表示メッセージ |
|----------|-----------------|-------------------|---------------|
| c-1失敗 | c-2/c-3/c-4全て実行不可 | 既存ルール通り手動確認誘導 | 既存メッセージ |
| c-2失敗 | c-3は`none`扱い、**c-4は実行可能**（c-1データで独立動作） | c-4の結果で判定 | 「⚠ リアクション取得に失敗しました。コメントベースの判定結果のみで続行します」（既存） |
| c-3 none | c-4へフォールスルー | c-4の結果で判定 | （表示なし、通常フロー） |
| c-4失敗 | - | c-3の結果を保持 | 「⚠ コメントベースの承認判定に失敗しました。リアクション判定の結果のみで続行します」 |
| c-2失敗 + c-4失敗 | c判定全体が判定不能 | a/b判定のみで続行 | 上記c-2/c-4それぞれのメッセージを表示 |

**原則**: 利用可能な判定結果を最大限残す。c-2とc-4は独立したデータソースに依存するため、一方の失敗が他方をブロックしない。

既存のAPI失敗時の注記を更新:

```text
**注**: 上記エラーハンドリングはステップ1-2（PRレビュー/コメント取得）とc-1（コメント特定）のAPI失敗に適用される。c-2（リアクション取得）およびc-4（コメント承認判定）の失敗は補助判定の失敗であり、利用可能な他のc判定結果を保持して続行する。全てのc判定が失敗した場合はa/b判定のみで続行可能（手動確認は不要）。
```

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 該当なし（プロンプト変更のみ）
- **対応策**: c-1で取得済みIssueCommentsDatasetを再利用し、追加API呼び出しを回避

### セキュリティ
- **要件**: 該当なし

### 可用性
- **要件**: API失敗時のフォールバックあり
- **対応策**: 上記フォールバック行列に従い、利用可能な判定結果を最大限残す

## 実装上の注意事項

- c-1のjqコマンドは変更しない（`.id`抽出のまま）。AIエージェントはc-1のpaginate結果をIssueCommentsDatasetとして保持し、c-4のフィルタリングで参照する。rules.mdにはその旨の注記を追加
- 承認パターンの正規表現は拡張可能な形式（リスト形式）で記述する
- c-3の既存出力メッセージ（「✓ Codex PRレビュー: 承認済み（👍）」等）はそのまま維持
- c-4で承認検出時の出力メッセージは既存メッセージと形式を統一する

## 不明点と質問（設計中に記録）

なし
