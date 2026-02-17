# ユーザーストーリー - v1.15.1

## Epic: スキル管理の標準化とツール互換性改善

### ストーリー 1: Kiro標準スキル呼び出し対応 (#192)
**優先順位**: Should-have

As a Kiroユーザー
I want to `.kiro/skills/` ディレクトリからAI-DLCのスキルを標準方式で呼び出せるようにしたい
So that Kiroのネイティブスキル発見機能を利用でき、設定の手間が減る

**受け入れ基準**:
- [ ] `.kiro/skills/` ディレクトリが作成され、既存5スキルへのシンボリックリンクが配置されている
- [ ] Kiro CLIからスキルが `skill://` 参照で発見・呼び出し可能である
- [ ] `.kiro/agents/aidlc.json` がKiro標準スキル発見方式に更新されている
- [ ] Claude Code側の既存スキル呼び出し（`.claude/skills/` 経由）が変更なく動作する
- [ ] セットアップスクリプトに `.kiro/skills/` シンボリックリンク作成処理が追加されている

**技術的考慮事項**:
- Kiroの `.kiro/skills/` 標準仕様を調査し準拠する必要がある
- `docs/aidlc/skills/` をソースとし、`.kiro/skills/` と `.claude/skills/` の両方からシンボリックリンクで参照する構成
- セットアップ時のシンボリックリンク作成はべき等に実装

---

### ストーリー 2: AIDLC専用レビュースキル作成 (#191)
**優先順位**: Should-have

As a AI-DLC利用開発者
I want to Inception Phaseの成果物（Intent、ユーザーストーリー、Unit定義）を専用の観点でAIレビューしたい
So that 要件定義段階の品質が向上し、Construction Phaseでの手戻りが減る

**受け入れ基準**:
- [ ] `reviewing-inception` スキルが作成され、Intent・ユーザーストーリー・Unit定義のレビュー観点が定義されている
- [ ] Intent用レビュー観点として「目的の明確さ」「スコープの妥当性」「成功基準の測定可能性」が含まれている
- [ ] ユーザーストーリー用レビュー観点として「INVEST原則への準拠」「受入条件の具体性・検証可能性」が含まれている
- [ ] Unit定義用レビュー観点として「依存関係の正確性」「スコープ境界の明確さ」が含まれている
- [ ] `review-flow.md` のCallerContextマッピングテーブルにInception Phase用エントリが追加されている
- [ ] 既存レビュースキル（code, architecture, security）と同じ形式（YAML frontmatter + Markdown）で作成されている

**技術的考慮事項**:
- 既存スキル形式に準拠して作成（YAML frontmatter: name, description, argument-hint, compatibility, allowed-tools）
- `session-management.md` は既存スキルから共有（シンボリックリンクまたはコピー）
- `prompts/package/skills/` に作成し、Operations Phaseでrsync反映

---

### ストーリー 3: upgrading-aidlcスキル簡略化 (#189)
**優先順位**: Could-have

As a AI-DLC利用開発者
I want to アップグレード時のsetup-prompt.md取得が直接スターターキットリポジトリから行われるようにしたい
So that 不要なローカル探索ステップが省略され、アップグレードフローが簡潔になる

**受け入れ基準**:
- [ ] upgrading-aidlcスキル実行時に `prompts/setup-prompt.md` のローカル探索ステップが実行されない
- [ ] スターターキットリポジトリから直接 `setup-prompt.md` が取得される
- [ ] `docs/aidlc.toml` の `starter_kit_repo` 設定を使用してパス解決される
- [ ] スターターキット開発リポジトリ（self）でもアップグレードフローが正常に動作する

**技術的考慮事項**:
- `prompts/package/skills/upgrading-aidlc/SKILL.md` のステップ1（ローカル探索）を削除
- ステップ2（スターターキットリポジトリ解決）のみ残す
- フロー説明テキストの整合性を維持

---

### ストーリー 4: migrate-backlog.sh macOS sed互換性修正 (#190)
**優先順位**: Could-have

As a macOSユーザー
I want to `migrate-backlog.sh --dry-run` が日本語タイトルを含むバックログでもエラーなく動作するようにしたい
So that gitモード利用時のバックログ移行が正常に完了する

**受け入れ基準**:
- [ ] `migrate-backlog.sh --dry-run` がmacOS（BSD sed）環境で `RE error: invalid character range` エラーなく完了する
- [ ] 日本語タイトル（漢字・ひらがな・カタカナ混在）を含むバックログのスラッグ生成が正常に行われる
- [ ] Linux（GNU sed）環境でも同一の動作結果が得られる
- [ ] `generate_slug()` 関数の出力がASCII + 日本語文字 + ハイフンの組み合わせである

**技術的考慮事項**:
- `sed` を `perl` に置換（`perl -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g'`）
- perlはmacOS標準搭載のため追加依存なし
- `prompts/package/bin/migrate-backlog.sh` の60行目を修正
