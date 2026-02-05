# ユーザーストーリー

## Epic 1: バグ修正

### ストーリー 1: suggest-version.shのalpha/betaなしバージョン対応
**優先順位**: Must-have
**関連Issue**: #161

As a AI-DLC開発者
I want to alpha/betaサフィックスなしのバージョン（例: v2.0.0）でもsuggest-version.shが正常動作すること
So that プレリリースフェーズを経ないバージョンでもサイクルを開始できる

**受け入れ基準**:
- [ ] ブランチ名 `cycle/v2.0.0` で `suggest-version.sh` を実行してもエラーが発生しない
- [ ] 出力に `branch_version:v2.0.0` が含まれる
- [ ] 出力に `suggested_patch:v2.0.1`、`suggested_minor:v2.1.0`、`suggested_major:v3.0.0` が含まれる
- [ ] 検証手順: テスト用ブランチ `cycle/v2.0.0` を作成（既存の場合は削除してから作成）し、`docs/aidlc/bin/suggest-version.sh` を実行して上記出力を確認

**技術的考慮事項**:
- 現在のスクリプトは `alpha` 変数が未定義の場合にエラーとなる
- バージョン解析ロジックでalpha/beta部分をオプショナルとして扱う必要がある

---

## Epic 2: ワークフロー改善

### ストーリー 2: PRマージ後のcheckout失敗防止
**優先順位**: Must-have
**関連Issue**: #167

As a AI-DLC開発者
I want to Operations PhaseのPRマージ後にgit checkout mainが失敗しないこと
So that リリース手順を中断なく完了できる

**受け入れ基準**:
- [ ] operations.mdの「リリース準備」セクション内に、PRマージ前にprogress.md更新をコミットする手順が含まれる
- [ ] 具体的に以下の順序が明記されている: 1) progress.mdを「完了」に更新、2) progress.mdをgit addしてcommit、3) PRマージ、4) checkout main
- [ ] 検証方法: operations.mdを読み、上記順序が明確に記載されていることを確認

**技術的考慮事項**:
- 現在の手順ではPRマージ後にprogress.mdを更新しているため、checkoutが失敗する

---

### ストーリー 3: Unit完了時のコミット確認
**優先順位**: Should-have
**関連Issue**: #166

As a AI-DLC開発者
I want to Unit完了時に未コミット変更がないか確認されること
So that 作業漏れを防止できる

**受け入れ基準**:
- [ ] construction.mdの「Unit完了時の必須作業」セクションに「`git status` で未コミット変更がないことを確認」というステップがある
- [ ] 未コミット変更がある場合は「コミットしてから次へ進む」という指示がある
- [ ] 検証方法: construction.mdを読み、上記ステップと指示が存在することを確認

**技術的考慮事項**:
- Unit完了時のチェックリストに追加するシンプルな変更

---

### ストーリー 4: 旧形式バックログ移行のアップグレード処理への移動
**優先順位**: Should-have
**関連Issue**: #163

As a AI-DLC開発者
I want to 旧形式バックログ移行がInception Phaseではなくアップグレード時のみ実行されること
So that 毎サイクル開始時に不要な確認が発生しない

**受け入れ基準**:
- [ ] inception.mdに「旧形式バックログ移行」に関する記述（`migrate-backlog.sh` の呼び出し）が存在しない
- [ ] setup-prompt.mdのアップグレードセクションに `migrate-backlog.sh --dry-run` の実行手順がある
- [ ] setup-prompt.mdで移行実行は「旧形式ファイル（`docs/cycles/backlog.md`）が存在する場合のみ」と条件が明記されている
- [ ] 検証方法: inception.mdとsetup-prompt.mdを読み、上記条件を確認

**技術的考慮事項**:
- inception.mdのステップ10を削除
- setup-prompt.mdのアップグレードフローに移行処理を追加
- 新規インストール時は旧形式ファイルが存在しないため、自動的にスキップされる

---

## Epic 3: ドキュメント・テンプレート強化

### ストーリー 5: AskUserQuestion機能の使用ガイド強化
**優先順位**: Should-have
**関連Issue**: #168

As a AI-DLC開発者
I want to AskUserQuestion機能を使用すべき場面が明確にドキュメント化されていること
So that AIがAskUserQuestion機能を適切に使用し、ユーザー体験が向上する

**受け入れ基準**:
- [ ] CLAUDE.mdの「AskUserQuestion機能の活用」セクションに「**必ず使用すべき場面**」という見出しがある
- [ ] 必ず使用すべき場面として最低3項目がリスト化されている（例: Yes/No確認、複数選択肢からの選択、優先度選択など）
- [ ] 各項目に具体例（括弧内に実際の質問例）が含まれている
- [ ] 検証方法: CLAUDE.mdを読み、上記構造と内容が存在することを確認

**技術的考慮事項**:
- 既存の記載を強化し、より具体的なガイダンスを提供

---

### ストーリー 6: 論理設計テンプレートのスクリプトインターフェース設計ガイド追加
**優先順位**: Should-have
**関連Issue**: #165

As a AI-DLC開発者
I want to 論理設計でスクリプトを追加・修正する際のインターフェース記載ガイドがあること
So that スクリプトの出力形式やエラー処理が一貫して設計される

**受け入れ基準**:
- [ ] logical_design_template.mdに「## スクリプトインターフェース設計」見出しがある
- [ ] 「### 成功時出力」サブセクションがあり、出力形式の例が含まれる
- [ ] 「### エラー時出力」サブセクションがあり、エラー形式の例が含まれる
- [ ] 「### 使用コマンド」サブセクションがあり、実装で使用するコマンドの記載ガイドがある
- [ ] 検証方法: logical_design_template.mdを読み、上記構造が存在することを確認

**技術的考慮事項**:
- AIレビューで指摘されたインターフェース詳細の記載漏れを防止するためのガイド

---

### ストーリー 7: アップグレード完了メッセージの更新
**優先順位**: Could-have
**関連Issue**: #160

As a AI-DLC開発者
I want to アップグレード完了後に正しい次のステップが案内されること
So that アップグレード後のワークフローがスムーズになる

**受け入れ基準**:
- [ ] setup-prompt.mdのアップグレード完了メッセージに「start inception」または「インセプション進めて」が含まれる
- [ ] 古い案内文言「start setup」が完了メッセージセクションに存在しない
- [ ] 検証方法: setup-prompt.mdの完了メッセージセクションを読み、上記を確認

**技術的考慮事項**:
- v1.12.0でSetup PhaseがInception Phaseに統合されたことを反映

---

## Epic 4: 機能追加

### ストーリー 8: アップグレード処理のスキル化
**優先順位**: Should-have
**関連Issue**: #133(部分)

As a AI-DLC開発者
I want to `/upgrade` コマンドでアップグレードを開始できること
So that アップグレード処理を簡単に呼び出せる

**受け入れ基準**:
- [ ] `docs/aidlc/skills/upgrade/SKILL.md` ファイルが存在する
- [ ] SKILL.mdに「## 実行方法」セクションがあり、`prompts/setup-prompt.md` を読み込むよう指示がある
- [ ] SKILL.mdに「## 使用タイミング」セクションがあり、「スターターキットの新しいバージョンにアップグレードしたい時」と記載がある
- [ ] AGENTS.mdの「### 特定のAIツールを呼び出す」表にupgradeスキルの行が追加されている
- [ ] 検証方法: 上記ファイルを読み、構造と内容を確認

**技術的考慮事項**:
- 既存のcodex-review等のスキル構造を参考にする
- スキルはsetup-prompt.mdへのリダイレクト的な役割
