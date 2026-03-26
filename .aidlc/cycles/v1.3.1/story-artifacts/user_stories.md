# ユーザーストーリー

## Epic: Inception Phase効率化

---

### ストーリー 1: バックログ対応済みチェック
**優先順位**: Must-have

As a AIエージェント
I want to バックログ確認時に過去に対応済みかどうかを自動チェックしたい
So that 既に対応済みの項目を再度実装するリスクを排除できる

**受け入れ基準**:
- [ ] バックログ確認時にbacklog-completed.mdの内容と照合する
- [ ] 対応済みの項目があれば、その旨をユーザーに通知する
- [ ] ユーザーがバックログ項目を選択する際に、対応済み情報が参考になる

**技術的考慮事項**:
- backlog-completed.mdのパス: `docs/cycles/backlog-completed.md`
- 照合は項目名（タイトル）ベースで実施

---

### ストーリー 2: セットアップスキップ（サイクル自動作成）
**優先順位**: Must-have

As a 開発者
I want to アップグレード不要時にセットアップをスキップしてInception Phaseを直接開始したい
So that 開発開始までの時間を短縮できる

**受け入れ基準**:
- [ ] サイクルディレクトリが存在しない場合、自動作成を提案する
- [ ] ユーザーが承認すれば、サイクルディレクトリを作成する
- [ ] 作成されるディレクトリ構造はsetup-cycle.mdと同一
- [ ] history.md、backlog.mdも初期化される

**技術的考慮事項**:
- setup-cycle.mdのステップ4〜6の処理をinception.mdに移植
- 既存のsetup-cycle.mdとの整合性を維持

---

### ストーリー 3: 最新バージョン通知
**優先順位**: Must-have

As a 開発者
I want to Inception Phase開始時に新しいバージョンが利用可能か通知してほしい
So that アップグレードの判断ができる

**受け入れ基準**:
- [ ] prompts/package/version.txtとdocs/aidlc/version.txtを比較する
- [ ] バージョンが異なる場合、通知メッセージを表示する
- [ ] アップグレードは強制せず、通知のみ
- [ ] バージョンファイルが存在しない場合はスキップ

**技術的考慮事項**:
- version.txtの形式: 単純なバージョン文字列（例: 1.3.0）

---

### ストーリー 4: Dependabot PR確認
**優先順位**: Must-have

As a 開発者
I want to Inception Phase開始時にDependabot PRの有無を確認したい
So that セキュリティ更新を見落とさない

**受け入れ基準**:
- [ ] GitHub CLIでDependabot PRの一覧を取得する
- [ ] PRがある場合、一覧を表示する
- [ ] 今回のサイクルで対応するかどうかをユーザーに確認する
- [ ] GitHub CLIが利用できない場合はスキップ

**技術的考慮事項**:
- コマンド: `gh pr list --label "dependencies" --state open`
- GitHub CLIが未設定の場合のエラーハンドリング
