# ユーザーストーリー

## Epic: コンテキストサイズ圧縮

### ストーリー 1: Reviewingスキル共通基盤抽出
**優先順位**: Must-have
**対象ファイル**: skills/reviewing-*/SKILL.md（9スキル）
**変更範囲**: 共通セクションの抽出、各SKILL.mdの簡素化

As a AI-DLC利用者
I want to Reviewingスキルの共通部分が一元管理されている
So that 長いセッションでもレビュー指示が途中で欠落せず、一貫した手順でレビューが実行される

**受け入れ基準**:
- [ ] 9つのReviewingスキルの共通セクション（実行コマンド・セッション継続・外部ツール関係・セルフレビューモード）が共通基盤ファイルに抽出されている
- [ ] 各ReviewingスキルのSKILL.mdには「レビュー観点」等の固有セクションのみが残っている
- [ ] 9スキルそれぞれを呼び出し、共通基盤が参照されてレビュー応答が開始できることを確認
- [ ] 共通基盤ファイルの変更が全9スキルに反映される構造になっている
- [ ] 共通基盤ファイルが存在しない場合、スキル呼び出し時に明示的なエラーメッセージが表示される
- **削減目標**: 20-25KB

**技術的考慮事項**:
- references/session-management.md（9コピー存在）のランタイム効果は0（1スキルしか呼ばれない）のため今回は対象外
- 共通基盤の参照方式（@参照 or Read指示）はConstruction Phaseで設計

---

### ストーリー 2: バージョンチェックロジック外部化
**優先順位**: Must-have
**対象ファイル**: skills/aidlc/steps/inception/01-setup.md（ステップ6a〜6d）
**変更範囲**: バージョン比較テーブルの `guides/version-check.md` への移動

As a AI-DLC利用者
I want to バージョンチェックの詳細ロジックがステップファイルから分離されている
So that Inception Phase開始時のコンテキスト消費が減り、セッション後半まで安定した応答品質が維持される

**受け入れ基準**:
- [ ] バージョン比較の5モード（THREE_WAY, REMOTE_LOCAL, SKILL_LOCAL, REMOTE_SKILL, SINGLE_OR_NONE）の条件分岐テーブルが `guides/version-check.md` に移動されている
- [ ] 01-setup.mdにはガイド参照指示（1-2行）のみが残り、ステップ6のバイト数が現状比80%以上削減されている
- [ ] バージョンチェックの動作が変更前と同一である（全5モードの代表パターンで確認）
- [ ] guides/version-check.md が存在しない場合、バージョンチェックをスキップして警告を表示する
- **削減目標**: 5-7KB

---

### ストーリー 3: プリフライトチェック圧縮
**優先順位**: Must-have
**対象ファイル**: skills/aidlc/steps/common/preflight.md
**変更範囲**: 手順5（オプションチェック）の冗長説明をテーブル圧縮

As a AI-DLC利用者
I want to プリフライトチェックの冗長な条件分岐説明がテーブル形式に圧縮されている
So that フェーズ開始時のコンテキスト消費が減り、作業本体に使えるコンテキスト量が増える

**受け入れ基準**:
- [ ] preflight.mdの手順5（オプションチェック）の冗長な自然言語説明がテーブル形式に圧縮されている
- [ ] preflight.mdの全体バイト数が現状（9,071B）から30%以上削減されている
- [ ] プリフライトチェックの出力フォーマットと判定結果が変更前と同一である
- [ ] 設定値取得に失敗した場合のフォールバック動作が維持されている
- **削減目標**: 3-5KB

---

### ストーリー 4: インラインテンプレート外部化
**優先順位**: Must-have
**対象ファイル**: skills/aidlc/steps/inception/05-completion.md, skills/aidlc/steps/common/review-flow.md
**変更範囲**: PR本文テンプレート・コンテキストリセットテンプレート・レビューサマリフォーマットの `templates/` 移動

As a AI-DLC利用者
I want to ステップファイル内のインラインテンプレートが `templates/` に分離されている
So that テンプレート修正時にステップファイル全体を再読込する必要がなく、保守変更時の不整合リスクが減る

**受け入れ基準**:
- [ ] 05-completion.mdのPR本文テンプレート（~2.5KB）が `templates/` に移動されている
- [ ] 05-completion.mdのコンテキストリセットテンプレート（~1KB）が `templates/` に移動されている
- [ ] review-flow.mdのレビューサマリSetフォーマット（~500B）が `templates/` に移動されている
- [ ] 移動後のテンプレート参照先ファイルが存在し、Readツールで読み込み可能である
- [ ] テンプレート参照先が存在しない場合、エラーメッセージを表示して処理を続行する
- **削減目標**: 3-5KB

---

### ストーリー 5: 先読み指示パターン廃止
**優先順位**: Must-have
**対象ファイル**: skills/aidlc/steps/inception/01-setup.md, skills/aidlc/steps/construction/01-setup.md, skills/aidlc/steps/operations/01-setup.md, その他完了処理ファイル
**変更範囲**: 「【次のアクション】今すぐ読み込んで」パターンの削除（ワークフロー制御指示は維持）

As a AI-DLC利用者
I want to ステップファイル内の冗長な先読み指示が削除されている
So that ステップファイルの内容が簡潔になり、AIエージェントが本来の手順に集中できる

**受け入れ基準**:
- [ ] SKILL.mdのステップ4で一括読み込みされるファイルへの先読み指示（「今すぐ～を読み込んで」パターン）が削除されている
- [ ] タスクリスト作成指示・Squashフロー読み込み指示など、ワークフロー制御に必要な指示は維持されている
- [ ] 先読み指示削除後、Inception/Construction/Operationsの各代表フローで必要ファイル未読エラーが発生しないことを確認
- [ ] SKILL.mdのステップ4で一括読み込み対象に含まれないファイル（commit-flow.mdのSquashフロー等、必要時参照のファイル）への指示は削除せず維持する
- **削減目標**: 1-2KB

---

## Epic: 付随改善

### ストーリー 6: 設定体系の一貫性改善
**優先順位**: Should-have
**対象ファイル**: skills/aidlc-setup/templates/config.toml.template, skills/aidlc/config/defaults.toml, skills/aidlc-setup/config/defaults.toml
**変更範囲**: lintingキー名統一、defaults.tomlコメント更新

As a AI-DLC利用者
I want to linting関連の設定キーがファイル間で統一され、設定ファイルのコメントが正確である
So that 設定変更時に混乱せず、正しい上書き方法で設定をカスタマイズできる

**受け入れ基準**:
- [ ] `config.toml.template` のキーが `markdown_lint` から `enabled` に変更されている
- [ ] `defaults.toml`（aidlc/aidlc-setup両方）のキーが `enabled` で統一されている
- [ ] preflight.mdのフォールバックロジック（旧キー `markdown_lint` → 新キー `enabled`）が正常動作する
- [ ] 既存の `config.toml` で `markdown_lint = true` と設定しているユーザーの互換性が維持される（フォールバックで `enabled=true` として読み取られる）
- [ ] `aidlc/config/defaults.toml` の先頭コメントが「`.aidlc/config.toml` で上書き可能」に更新されている
- [ ] `aidlc-setup/config/defaults.toml` の先頭コメントも同様に更新されている

---

### ストーリー 7: 判断時の情報提示ルール追加
**優先順位**: Should-have
**対象ファイル**: skills/aidlc/steps/common/agents-rules.md
**変更範囲**: 「質問と深掘り」セクションへのルール追加

As a AI-DLC利用者
I want to AIエージェントが判断を求める際に必要な情報を事前提示する
So that 自分で詳細を調べる手間なく、的確な意思決定ができる

**受け入れ基準**:
- [ ] `agents-rules.md` の「質問と深掘り」セクションに「判断に必要な情報の事前提示」ルールが追加されている
- [ ] ルールに具体例が含まれている（Issue選択時はIssue本文の要約を提示、スコープ決定時は影響範囲を提示等）
- [ ] 追加ルールが既存の一問一答形式の質問フローに統合可能である（質問前に情報提示→質問の順序で運用）
- [ ] 情報取得に失敗した場合（API失敗等）は、取得できた情報のみで質問を続行する
