# ユーザーストーリー

## Epic 1: ドラフトPRワークフロー

### ストーリー 1.1: Inception完了時のドラフトPR作成
**優先順位**: Must-have

As a AI-DLC利用者
I want to Inception Phase完了時にドラフトPRを自動作成する
So that 複数Unitを並列開発する準備ができる

**受け入れ基準**:
- [ ] Inception Phase完了時にドラフトPR作成を提案する
- [ ] GitHub CLI（gh）の利用可否を確認する
- [ ] ドラフトPRのタイトルは「[WIP] cycle/vX.X.X」形式
- [ ] PR本文にサイクルの概要（Intent要約）を含める
- [ ] ドラフトPR作成後、URLを表示する

**技術的考慮事項**:
- GitHub CLIが利用不可の場合はスキップし、手動作成を案内
- PRテンプレート（.github/pull_request_template.md）があれば活用

---

### ストーリー 1.2: Unit完了時のPR作成とマージ
**優先順位**: Must-have

As a AI-DLC利用者
I want to 各Unit完了時にサイクルブランチへのPRを作成してマージする
So that Unit単位でレビューでき、進捗が可視化される

**受け入れ基準**:
- [ ] Construction Phase の各Unit完了時にPR作成を提案する
- [ ] PRはサイクルブランチ（cycle/vX.X.X）へ向ける
- [ ] ブランチ名は `cycle/vX.X.X/unit-NNN` 形式
- [ ] PR本文にUnit定義の要約を含める
- [ ] マージ後、Unitブランチを削除する

**技術的考慮事項**:
- 既にサイクルブランチで作業している場合はUnitブランチを新規作成
- PRマージはユーザーが承認した場合のみ実行

---

### ストーリー 1.3: Operations Phase開始前の全Unit完了確認
**優先順位**: Must-have

As a AI-DLC利用者
I want to Operations Phase開始前に全Unitが完了していることを確認する
So that 未完了Unitを残したままリリース準備を進めない

**受け入れ基準**:
- [ ] Operations Phase開始時に全Unit定義ファイルの実装状態を確認
- [ ] 未完了Unitがある場合は警告を表示し、継続確認する
- [ ] 全Unit完了の場合は次のステップへ進む

**技術的考慮事項**:
- Unit定義ファイルの「実装状態」セクションを参照
- 状態が「完了」でないUnitをリストアップ

---

### ストーリー 1.4: ドラフトPRのReady for Review化
**優先順位**: Must-have

As a AI-DLC利用者
I want to Operations Phase完了時にドラフトPRをReady for Reviewにする
So that レビュー・マージの準備が完了する

**受け入れ基準**:
- [ ] Operations Phase完了時（リリース準備後）にドラフトPRのReady化を提案
- [ ] `gh pr ready` コマンドでドラフト解除
- [ ] PR本文にサイクルの成果を追記（Unit一覧、変更ファイル等）

**技術的考慮事項**:
- GitHub CLIが利用不可の場合は手動操作を案内

---

## Epic 2: バックログ移行自動化

### ストーリー 2.1: 旧形式backlog.mdの自動移行
**優先順位**: Must-have

As a AI-DLC利用者
I want to アップグレード時に旧形式backlog.mdを新形式（個別ファイル）に自動移行する
So that 手動移行の手間を削減し、移行ミスを防止する

**受け入れ基準**:
- [ ] setup-prompt.md実行時に `docs/cycles/backlog.md` の存在を確認
- [ ] 存在する場合、移行処理を実行
- [ ] 各セクション（延期タスク、低優先度タスク等）を個別ファイルに分割
- [ ] ファイル名はprefix（feat-, chore-, rule-, refactor-）+ ケバブケース
- [ ] `docs/cycles/backlog/` に移動
- [ ] 移行後、元のbacklog.mdを削除

**技術的考慮事項**:
- Markdownセクション（### 見出し）単位で分割
- ファイル名生成ロジック（セクション名からケバブケース変換）
- メタデータ（発見日、発見サイクル、優先度）を保持

---

### ストーリー 2.2: 完了済みバックログの重複チェック
**優先順位**: Must-have

As a AI-DLC利用者
I want to バックログ移行前に完了済み項目かどうかをチェックする
So that 既に対応済みのタスクを誤って移行しない

**受け入れ基準**:
- [ ] backlog-completed.md および backlog-completed/*/ と照合
- [ ] 名称・内容が類似する項目を検出
- [ ] 類似項目がある場合、ユーザーに確認を求める
- [ ] ユーザーが「完了済み」と判断した項目は移行しない

**技術的考慮事項**:
- 類似度判定はAIによる文脈理解で実施
- ユーザーに判断材料（対応サイクル、完了日等）を提示

---

## Epic 3: セットアップ柔軟性向上

### ストーリー 3.1: アップグレードしない場合のコピー元参照案内
**優先順位**: Must-have

As a AI-DLC利用者
I want to アップグレードしない場合でもサイクル開始できるよう、コピー元を参照する案内を表示する
So that アップグレードを強制されず、柔軟にサイクルを開始できる

**受け入れ基準**:
- [ ] setup-prompt.md のケースC（バージョン同じ）で完了メッセージを修正
- [ ] `docs/aidlc/prompts/setup.md` の存在を確認
- [ ] 存在しない場合、`prompts/package/prompts/setup.md` を参照するよう案内
- [ ] 存在する場合、既存の案内（docs/aidlc/prompts/setup.md）を表示

**技術的考慮事項**:
- ファイル存在確認コマンド（`[ -f path ]`）を使用
- 案内メッセージを条件分岐で出し分け

---
