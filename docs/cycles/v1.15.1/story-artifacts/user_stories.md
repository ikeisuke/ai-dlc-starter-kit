# ユーザーストーリー - v1.15.1

## Epic: スキル管理の標準化とツール互換性改善

### ストーリー 1: Kiro標準スキル呼び出し対応 (#192)
**優先順位**: Should-have

As a Kiroユーザー
I want to `.kiro/skills/` ディレクトリからAI-DLCのスキルを標準方式で呼び出せるようにしたい
So that Kiroのネイティブスキル発見機能を利用でき、設定の手間が減る

**受け入れ基準**:
- [ ] `.kiro/skills/` ディレクトリが作成され、既存5スキル（reviewing-architecture, reviewing-code, reviewing-security, upgrading-aidlc, versioning-with-jj）へのシンボリックリンクが配置されている
- [ ] Kiro CLIで `kiro-cli --agent aidlc` を起動し、`.kiro/skills/` 内のスキルが自動発見されてスキル一覧に表示される
- [ ] `.kiro/agents/aidlc.json` がKiro標準スキル発見方式に更新され、`skill://` リソースパターンが `.kiro/skills/` を参照している
- [ ] Claude Codeで `skill="reviewing-code"` 等の既存スキル呼び出しが `.claude/skills/` シンボリックリンク経由で従来通り動作する
- [ ] セットアップスクリプト実行後に `.kiro/skills/` 配下にシンボリックリンクが作成されており、`ls -la .kiro/skills/` で5件のリンクが確認できる

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
- [ ] `reviewing-inception` スキルが `prompts/package/skills/reviewing-inception/SKILL.md` に作成されている
- [ ] Intent用レビュー観点として「目的の明確さ」「スコープの妥当性」「成功基準の測定可能性」が定義されている
- [ ] ユーザーストーリー用レビュー観点として「INVEST原則への準拠」「受入条件の具体性・検証可能性」が定義されている
- [ ] Unit定義用レビュー観点として「依存関係の正確性」「スコープ境界の明確さ」が定義されている
- [ ] `review-flow.md` のCallerContextマッピングテーブルに「Intent承認前 → inception」「ユーザーストーリー承認前 → inception」「Unit定義承認前 → inception」が追加されている
- [ ] 既存レビュースキルと同じ形式（YAML frontmatter: name, description, argument-hint, compatibility, allowed-tools + Markdownレビュー観点）で作成されている
- [ ] Inception Phaseプロンプトの「AIレビュー対象タイミング」（Intent承認前、ユーザーストーリー承認前、Unit定義承認前）で `skill="reviewing-inception"` が呼び出される

**技術的考慮事項**:
- 既存スキル形式に準拠して作成（YAML frontmatter: name, description, argument-hint, compatibility, allowed-tools）
- `session-management.md` は既存スキルから共有（シンボリックリンクまたはコピー）
- `prompts/package/skills/` に作成し、Operations Phaseでrsync反映
- Unit分割時にスキル本体作成とreview-flow統合を分けることを検討

---

### ストーリー 3: upgrading-aidlcスキル簡略化 (#189)
**優先順位**: Could-have

As a AI-DLC利用開発者
I want to アップグレード時のsetup-prompt.md取得が直接スターターキットリポジトリから行われるようにしたい
So that 不要なローカル探索ステップが省略され、アップグレードフローが簡潔になる

**受け入れ基準**:
- [ ] `prompts/package/skills/upgrading-aidlc/SKILL.md` からローカル探索ステップ（`prompts/setup-prompt.md` の存在確認）が削除されている
- [ ] スキル実行時に `docs/aidlc.toml` の `starter_kit_repo` 設定を使用して、スターターキットリポジトリから直接 `setup-prompt.md` が取得される
- [ ] `/upgrading-aidlc` スキルを実行し、ローカルに `prompts/setup-prompt.md` が存在しない外部プロジェクトでもスキルが正常完了する
- [ ] スターターキット開発リポジトリ（`prompts/setup-prompt.md` が存在する環境）でも `/upgrading-aidlc` が正常に動作する

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
- [ ] `prompts/package/bin/migrate-backlog.sh` の `generate_slug()` 関数で `sed` の代わりに `perl` を使用している
- [ ] macOS（BSD sed）環境で `docs/aidlc/bin/migrate-backlog.sh --dry-run` を実行し、`RE error: invalid character range` エラーが発生しない
- [ ] 日本語タイトル（例: 「サムネイルストリップの安定化」）を含むバックログのスラッグが `サムネイルストリップの安定化` → `サムネイルストリップの安定化` のように正常に生成される
- [ ] Linux（GNU sed）環境でも `migrate-backlog.sh --dry-run` が同一結果で完了する

**技術的考慮事項**:
- `sed` を `perl -pe` に置換（`perl -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g'`）
- perlはmacOS標準搭載のため追加依存なし
- `prompts/package/bin/migrate-backlog.sh` の60行目を修正
