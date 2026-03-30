# ユーザーストーリー

## Epic 1: バックログ管理の安定化

### ストーリー 1: backlogラベル自動作成
**優先順位**: Must-have
**関連**: #23

As a AI-DLC利用者
I want to Issue駆動バックログ使用時にbacklogラベルが自動作成される
So that ラベル未作成によるエラーを回避できる

**受け入れ基準**:
- [ ] setup.mdにbacklogラベル存在確認ロジックが追加されている
- [ ] ラベルが存在しない場合、自動作成される
- [ ] 既存ラベルがある場合はスキップされる

---

### ストーリー 2: バックログモード設定の反映
**優先順位**: Must-have
**関連**: #24

As a AI-DLC利用者
I want to aidlc.tomlのbacklog.mode設定がセットアップ時に正しく読み込まれる
So that 設定に応じた適切なバックログ管理方式が使用される

**受け入れ基準**:
- [ ] 原因が特定されている
- [ ] setup.mdでbacklog.mode設定を参照するロジックが追加されている
- [ ] mode=issueの場合、GitHub Issueでバックログを管理する
- [ ] mode=gitの場合、ローカルファイルでバックログを管理する

---

## Epic 2: Claude Code連携強化

### ストーリー 3: AskUserQuestion推奨オプション順序
**優先順位**: Should-have
**関連**: #25

As a Claude Code利用者
I want to AskUserQuestionの選択肢で推奨オプションが一番上に表示される
So that 直感的に推奨を選択できる

**受け入れ基準**:
- [ ] CLAUDE.mdに選択肢順序のルールが追記されている
- [ ] 推奨オプションには「（推奨）」が付与されることが明記されている

---

## Epic 3: プロンプト品質向上

### ストーリー 4: AIレビュー反復プロセス
**優先順位**: Should-have
**関連**: chore-ai-review-iteration

As a AI-DLC利用者
I want to AIレビュー後の修正→再レビューのループが明文化される
So that レビュー品質が向上し、指摘の見落としが減る

**受け入れ基準**:
- [ ] construction.mdのAIレビューフローに反復プロセスが追記されている
- [ ] 「指摘がなくなるまで繰り返す」ことが明記されている

---

### ストーリー 5: 複合コマンド削減
**優先順位**: Should-have
**関連**: chore-reduce-compound-commands

As a AI-DLC利用者
I want to プロンプト内の複合コマンドが削減され、事前確認が集約される
So that 許可リスト運用時の承認回数が減り、実行がスムーズになる

**受け入れ基準**:
- [ ] 事前確認（gh auth status等）がフェーズ/Unit開始時にまとめて実行される
- [ ] 複合コマンド（&&, ||）が可能な限り単一コマンドに分解されている
- [ ] 対象: setup.md, inception.md, construction.md, operations.md

---

### ストーリー 6: Unitブランチ設定統合
**優先順位**: Should-have
**関連**: chore-unit-branch-setting-integration

As a AI-DLC利用者
I want to aidlc.tomlの[rules.unit_branch].enabled設定がconstruction.mdに反映される
So that 設定に応じてUnitブランチ作成の確認がスキップされる

**受け入れ基準**:
- [ ] construction.mdで[rules.unit_branch].enabled設定を参照している
- [ ] enabled=falseの場合、Unitブランチ作成確認をスキップする

---

## Epic 4: 新機能（小規模）

### ストーリー 7: iOSバージョン更新タイミング
**優先順位**: Could-have
**関連**: feature-ios-version-inception-phase

As a iOSアプリ開発者
I want to バージョン更新をInception Phaseで実施するオプションがある
So that Construction Phase中のTestFlight配布に対応できる

**受け入れ基準**:
- [ ] aidlc.tomlにproject.type設定が追加されている
- [ ] project.type=iosの場合、Inception Phaseでバージョン更新を提案する
- [ ] 従来のOperations Phase更新も引き続きサポートする

---

### ストーリー 8: jjサポート有効化フラグ
**優先順位**: Could-have
**関連**: feature-jj-enabled-flag

As a jj利用者
I want to [rules.jj].enabledフラグでjjサポートを有効化できる
So that プロンプトがjjコマンドを優先的に案内してくれる

**受け入れ基準**:
- [ ] aidlc.tomlに[rules.jj].enabled設定が追加されている
- [ ] enabled=trueの場合、gitの代わりにjjコマンドを案内する
- [ ] enabled=false（デフォルト）の場合、従来通りgitを使用する
