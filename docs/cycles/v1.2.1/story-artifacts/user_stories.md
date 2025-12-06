# ユーザーストーリー

## Epic: AI-DLC運用品質向上

### ストーリー 1: セットアップ時のプロジェクト情報まとめて確認
**優先順位**: Should-have

As a AI-DLC利用者
I want to セットアップ時にプロジェクト情報をまとめて確認できる
So that 一問一答形式より効率的にセットアップを完了できる

**受け入れ基準**:
- [ ] setup-init.mdでデフォルト値を一覧表示する
- [ ] 変更があるものだけ指定できる形式になっている
- [ ] 既存の一問一答形式から移行されている

**技術的考慮事項**:
- prompts/setup-init.md の質問セクションを修正
- デフォルト値の表示形式を検討

---

### ストーリー 2: Operations Phaseでのバックログ完了項目自動移動
**優先順位**: Should-have

As a AI-DLC利用者
I want to Operations Phase完了時にバックログの完了項目が自動的にbacklog-completed.mdに移動される
So that バックログが常に整理された状態を維持できる

**受け入れ基準**:
- [ ] operations.mdにバックログ完了項目移動の手順が追加されている
- [ ] 該当サイクルで対応した項目を特定できる
- [ ] backlog.mdからbacklog-completed.mdへの移動が明確に指示されている

**技術的考慮事項**:
- prompts/package/prompts/operations.md の完了時処理に追加
- バックログ項目の特定方法（Intent/Unit定義との照合）

---

### ストーリー 3: Construction Phaseが自身のprogressを作成
**優先順位**: Could-have

As a AI-DLC利用者
I want to Construction Phaseが開始時に自身のprogress.mdを作成する
So that 各フェーズが自分の責務範囲のファイルを管理できる

**受け入れ基準**:
- [ ] Inception Phaseからconstruction/progress.md作成を削除
- [ ] Construction Phase開始時にprogress.mdを作成するよう変更
- [ ] Unit一覧はInception Phaseで作成したUnit定義から読み取る

**技術的考慮事項**:
- prompts/package/prompts/inception.md のステップ6を修正
- prompts/package/prompts/construction.md の初期化処理を追加

---

### ストーリー 4: デグレファイルの復元
**優先順位**: Could-have

As a AI-DLC利用者
I want to v1.2.0で欠落したファイルが復元される
So that AI-DLCの全機能が正常に動作する

**受け入れ基準**:
- [ ] prompt-reference-guide.md が prompts/package/prompts/ に存在する
- [ ] operations関連ファイルが適切に配置されている、または参照が削除されている

**技術的考慮事項**:
- v1.1.0のsetup/common.mdからprompt-reference-guide.mdの内容を復元
- setup-init.mdのoperations/README.md参照を確認
