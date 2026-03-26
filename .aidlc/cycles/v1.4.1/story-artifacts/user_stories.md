# ユーザーストーリー

## Epic: 開発体験向上のための微調整

### ストーリー 1: コマンドラインツールのプロジェクトタイプ追加
**優先順位**: Should-have

As a AI-DLC スターターキットのユーザー
I want to コマンドラインツールをプロジェクトタイプとして選択できる
So that CLI ツール開発時に適切な Operations Phase 処理を受けられる

**受け入れ基準**:
- [ ] operations_progress_template.md に cli プロジェクトタイプが追加されている
- [ ] operations.md で cli の配布ステップ処理が定義されている
- [ ] cli はデスクトップアプリに準じた扱い（配布ステップ実施）

**技術的考慮事項**:
- 関連ファイル: operations.md, operations_progress_template.md

---

### ストーリー 2: workaround 実施時のバックログ追加ルール
**優先順位**: Should-have

As a AI-DLC スターターキットのユーザー
I want to その場しのぎの対応をする際に本質的な対応をバックログに記録するルールがある
So that 技術的負債を可視化し、将来的な対応を促進できる

**受け入れ基準**:
- [ ] construction.md に workaround 実施時のルールセクションが追加されている
- [ ] workaround 実施時は本質的な対応をバックログに記録することが必須化されている
- [ ] コード内に TODO コメント（バックログファイル名を参照）を残すルールが追加されている

**技術的考慮事項**:
- 関連ファイル: construction.md, rules.md

---

### ストーリー 3: README.md 読み込み時にリンクを辿る
**優先順位**: Could-have

As a AI-DLC スターターキットのユーザー
I want to セットアップ時に README.md のリンク先ドキュメントも読み込まれる
So that プロジェクトの全体像を把握しやすくなる

**受け入れ基準**:
- [ ] setup-init.md に README.md 読み込み時のリンク辿りルールが追加されている
- [ ] プロジェクト内部のドキュメントリンクが検出される
- [ ] コンテキスト理解に必要なリンクが自動的に辿られる

**技術的考慮事項**:
- 関連ファイル: setup-init.md
- 外部リンクは辿らない（プロジェクト内部のみ）

---

### ストーリー 4: Unit 定義ファイルに実行順序番号を付与
**優先順位**: Should-have

As a AI-DLC スターターキットのユーザー
I want to Unit 定義ファイル名に実行順序番号が付与される
So that 依存関係の実行順序が一目でわかる

**受け入れ基準**:
- [ ] ファイル名形式が `{NNN}-{unit-name}.md` になっている
- [ ] 番号は依存関係の実行順序が早いものほど小さい値
- [ ] 連番の重複は許可されない
- [ ] inception.md と construction.md に番号付けルールが追加されている

**技術的考慮事項**:
- 関連ファイル: inception.md, construction.md, unit_definition_template.md

---

### ストーリー 5: コミットハッシュのファイル記録を廃止
**優先順位**: Must-have

As a AI-DLC スターターキットのユーザー
I want to コミットハッシュをファイルに記録する機能が廃止される
So that 無駄なワークフロー（コミット → ハッシュ取得 → ファイル更新 → 再コミット）が不要になる

**受け入れ基準**:
- [ ] unit_definition_template.md からコミットフィールドと注意書きが削除されている
- [ ] 関連するプロンプトからコミットハッシュ記録に関する記述が削除されている

**技術的考慮事項**:
- 関連ファイル: unit_definition_template.md
- 必要であれば `git log` で履歴を参照する運用に変更
