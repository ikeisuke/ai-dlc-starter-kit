# ユーザーストーリー

## Epic: セットアップ体験とプロンプト構成の改善

### ストーリー 1: プロジェクトタイプの設定
**優先順位**: Should-have

As a AI-DLCを導入する開発者
I want to 初回セットアップ時にプロジェクトタイプを選択できる
So that Operations Phaseで配布ステップの要否が自動判断される

**受け入れ基準**:
- [ ] 初回セットアップ時にプロジェクトタイプを選択できる
- [ ] 選択したタイプが aidlc.toml に保存される
- [ ] Operations Phase開始時に未設定の場合は確認を促す
- [ ] 既存プロジェクトとの後方互換性が維持される

**技術的考慮事項**:
- setup-init.md にプロジェクトタイプ選択ステップを追加
- aidlc.toml テンプレートに project.type フィールドを追加
- operations.md で project.type を参照するロジックを追加

---

### ストーリー 2: 履歴保存タイミングの明確化
**優先順位**: Could-have

As a AI-DLCを使用する開発者
I want to 履歴記録のタイミングが明確である
So that 作業履歴が適切に残る

**受け入れ基準**:
- [ ] 履歴記録タイミングがドキュメントで明確化されている
- [ ] 各フェーズのプロンプトで一貫したルールが適用される

**技術的考慮事項**:
- 現状のタイミング（Unit完了時）を明文化するか、変更するか検討

---

### ストーリー 3: コミットメッセージにサイクル名を含める
**優先順位**: Could-have

As a AI-DLCを使用する開発者
I want to コミットメッセージにサイクル名が含まれる
So that Git履歴からどのサイクルの変更か分かる

**受け入れ基準**:
- [ ] コミットメッセージ形式が `feat: [vX.X.X] Unit NNN完了 - 説明` になる
- [ ] construction.md のコミットメッセージ例が更新される

**技術的考慮事項**:
- construction.md の「Unit完了時の必須作業」セクションを更新

---

### ストーリー 4: セットアップエントリーポイントの変更
**優先順位**: Should-have

As a AI-DLCを使用する開発者
I want to 通常サイクル開始時は docs/aidlc/prompts/setup.md が案内される
So that 毎回アップグレード確認をスキップできる

**受け入れ基準**:
- [ ] operations.md の次サイクル開始案内が docs/aidlc/prompts/setup.md になる
- [ ] アップグレード時のみ prompts/setup-prompt.md を使用する導線が明確

**技術的考慮事項**:
- operations.md の「次のサイクル開始」セクションを修正

---

### ストーリー 5: セットアッププロンプトの統合・整理
**優先順位**: Should-have

As a AI-DLCを使用する開発者
I want to セットアップ関連ファイルの責務が明確である
So that どのファイルを使えばよいか迷わない

**受け入れ基準**:
- [ ] 各ファイルの責務が明確に分離されている
- [ ] 重複が排除されている
- [ ] ドキュメントが更新されている

**技術的考慮事項**:
- prompts/setup-prompt.md, prompts/setup-init.md, prompts/package/prompts/setup.md の責務整理
- 必要に応じてファイル統合または削除
