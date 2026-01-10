# ドメインモデル: Issue駆動バックログフロー

## 概要
バックログ管理におけるGitHub Issue連携の概念モデルを定義し、ローカルファイル管理との選択制を提供する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## エンティティ（Entity）

### BacklogItem（バックログアイテム）
- **ID**: スラッグ（例: `feature-user-auth`）- ファイル名およびIssue本文に記載
- **属性**:
  - title: String - バックログの件名
  - type: BacklogType - 種類（feature, bugfix, chore, refactor, docs, perf, security）
  - priority: Priority - 優先度（高, 中, 低）
  - discoveryDate: Date - 発見日
  - discoveryPhase: Phase - 発見フェーズ
  - discoveryCycle: String - 発見サイクル
  - description: String - 概要
  - details: String - 詳細
  - proposedAction: String - 対応案
  - issueNumber: Integer? - Issue駆動時のIssue番号（オプション）
- **振る舞い**:
  - createAsIssue(): 対応するGitHub Issueを作成（`backlog`ラベル必須）
  - createAsFile(): 対応するローカルファイルを作成
  - complete(): バックログを完了（Issueクローズ or ファイルを`backlog-completed/`へ移動）

### Issue（GitHub Issue）
- **ID**: number（GitHub Issue番号）
- **属性**:
  - title: String - Issueタイトル
  - body: String - Issue本文（スラッグを含む）
  - labels: Label[] - ラベル（`backlog`ラベル必須）
  - state: IssueState - 状態（open, closed）
- **振る舞い**:
  - close(): Issueをクローズ
- **必須ラベル**: `backlog` - バックログIssueの識別に使用

## 値オブジェクト（Value Object）

### BacklogMode（バックログ管理モード）
- **属性**: mode: String - "issue" | "git"
- **不変性**: 設定ファイル（`aidlc.toml`）で定義された初期値
- **等価性**: mode値が同じであれば等価
- **フォールバック動作**: Issue駆動選択時にGitHub CLI未認証の場合、警告を表示しGit駆動で動作（設定は変更しない）

### BacklogType（バックログ種類）
- **属性**: type: String - "feature" | "bugfix" | "chore" | "refactor" | "docs" | "perf" | "security"
- **不変性**: 作成時に決定され、変更不可
- **等価性**: type値が同じであれば等価

### Priority（優先度）
- **属性**: level: String - "高" | "中" | "低"
- **不変性**: 作成後に変更可能だが、変更時は新しい値オブジェクトを生成
- **等価性**: level値が同じであれば等価

## 集約（Aggregate）

### BacklogAggregate（バックログ集約）
- **集約ルート**: BacklogItem
- **含まれる要素**: BacklogItem, BacklogType, Priority
- **境界**: 単一のバックログアイテムとそのメタデータ
- **不変条件**:
  - typeは有効な種類のみ
  - priorityは有効な優先度のみ
  - discoveryDateはdiscoveryCycleと整合性を持つ

## ドメインサービス

### BacklogStorageService（バックログ保存サービス）
- **責務**: BacklogModeに応じた保存先の選択と保存処理
- **操作**:
  - save(backlogItem, mode): モードに応じてIssueまたはファイルとして保存
  - retrieve(mode): モードに応じた保存先からバックログを取得
  - close(backlogItem, mode): モードに応じた方法でバックログを完了

### BacklogReferenceService（バックログ参照サービス）
- **責務**: 両方の保存先（Issue + ファイル）を横断的に参照
- **操作**:
  - findAll(): GitHub Issueとローカルファイル両方からバックログを収集
  - findByType(type): 指定種類のバックログを検索

## リポジトリインターフェース

### IssueRepository
- **対象集約**: Issue（外部システム）
- **操作**:
  - create(issue) - `gh issue create` でIssue作成
  - find(number) - `gh issue view` でIssue取得
  - close(number) - `gh issue close` でIssueクローズ
  - list(labels) - `gh issue list` でIssue一覧取得

### FileBacklogRepository
- **対象集約**: BacklogAggregate
- **操作**:
  - save(backlogItem) - `docs/cycles/backlog/{type}-{slug}.md` として保存
  - find(slug) - ファイルからバックログ読み込み
  - moveToCompleted(slug, cycle) - `docs/cycles/backlog-completed/{cycle}/` へ移動
  - findAll() - `docs/cycles/backlog/` 配下の全ファイル取得

## ユビキタス言語

このドメインで使用する共通用語：

- **バックログ（Backlog）**: 将来対応すべき気づき・課題・機能要望の記録
- **バックログアイテム（Backlog Item）**: バックログの個々の項目
- **Issue駆動（Issue-driven）**: GitHub Issueを中心としたバックログ管理方式
- **Git駆動（Git-driven）**: ローカルファイルを中心としたバックログ管理方式（従来方式）
- **バックログモード（Backlog Mode）**: 保存先の選択（issue / git）
- **参照時両方確認**: どのモードでも、参照時はIssueとファイル両方を確認する原則

## 不明点と質問（設計中に記録）

なし（Unit定義で要件が明確に定義されている）
