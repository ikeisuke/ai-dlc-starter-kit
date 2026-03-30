# Unit 009 計画: ドキュメント・リンク整合

## 概要

スキル再編・削除の完了を受けて、ドキュメントとシンボリックリンクを新スキル構成（5スキル）に一致するように更新する。

**新スキル構成**（prompts/package/skills/）:

1. `reviewing-code` - コードレビュー
2. `reviewing-architecture` - アーキテクチャレビュー
3. `reviewing-security` - セキュリティレビュー
4. `versioning-with-jj` - jjバージョン管理
5. `upgrading-aidlc` - AI-DLCアップグレード

**旧スキル（削除済み）**: codex-review, claude-review, gemini-review, gh, aidlc-upgrade, jj

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/AGENTS.md` | スキル一覧テーブルを新構成に更新 |
| `prompts/package/guides/skill-usage-guide.md` | スキル構成説明を新構成に更新 |
| `prompts/setup-prompt.md` | スキル参照（ディレクトリ構成図、完了メッセージ等）を更新 |
| `docs/cycles/rules.md` | skill="codex" → 既に更新済み（確認のみ） |
| `docs/aidlc/skills/` | rsyncで新スキル構成に同期 |
| `.claude/skills/` | setup-ai-tools.shで新シンボリックリンクに更新 |

## 実装計画

### Phase 1: 設計

このUnitはドキュメント更新のみのため、設計省略。

### Phase 2: 実装

#### ステップ1: prompts/package/prompts/AGENTS.md の更新

- 「特定のAIツールを呼び出す」セクションのテーブルを削除し、新しいレビュースキル3つを記載
- 旧スキル4つ（codex-review, claude-review, gemini-review, gh）への参照を削除
- 「AI-DLCワークフロースキル」セクションにアップグレードスキル（upgrading-aidlc）とjjスキル（versioning-with-jj）を記載
- KiroCLI設定のresourcesパスも新スキル名に更新

#### ステップ2: prompts/package/guides/skill-usage-guide.md の更新

- ディレクトリ構成図を新スキル名に更新
- 利用可能なスキルのテーブルを新構成（5スキル）に更新
- Claude Codeのスキル呼び出し例を新スキル名に更新
- Codex CLI/Gemini CLI/KiroCLIの参照パスを新スキル名に更新
- 「プロジェクト独自スキルの追加」の命名規則テーブルを新スキル名に更新

#### ステップ3: prompts/setup-prompt.md の更新

- セクション8.2.7のディレクトリ構成図を新スキル名に更新
- セクション8.3の同期対象ファイル一覧を新スキル名に更新
- セクション10の完了メッセージを新スキル名に更新

#### ステップ4: docs/cycles/rules.md の確認

- `skill="codex"` が存在しないことを確認（既に更新済み）

#### ステップ5: シンボリックリンク更新

1. `docs/aidlc/skills/` にrsyncで新スキル構成を同期:
   ```bash
   rsync -av --checksum --delete prompts/package/skills/ docs/aidlc/skills/
   ```
2. `docs/aidlc/bin/setup-ai-tools.sh` を実行して `.claude/skills/` を更新
3. 結果を確認

## 完了条件チェックリスト

- [ ] `.claude/skills/` に reviewing-code、reviewing-architecture、reviewing-security、versioning-with-jj、upgrading-aidlc の5つのシンボリックリンクが存在する
- [ ] 各シンボリックリンクが `docs/aidlc/skills/` 配下を指している
- [ ] `prompts/package/prompts/AGENTS.md` のスキル一覧テーブルに新スキル3つ（reviewing-code, reviewing-architecture, reviewing-security）を記載済み
- [ ] `prompts/package/prompts/AGENTS.md` から旧スキル4つ（codex-review, claude-review, gemini-review, gh）を削除済み
- [ ] `prompts/package/guides/skill-usage-guide.md` にghスキルへの参照がない
- [ ] `prompts/package/guides/skill-usage-guide.md` に新構成5スキルが記載されている
- [ ] `prompts/setup-prompt.md` のシンボリックリンク参照が新スキル名に更新されている
- [ ] `docs/cycles/rules.md` に `skill="codex"` が存在しない

## 備考

- Unit定義の受け入れ基準では `jj` と記載されているが、実際のスキルディレクトリ名は `versioning-with-jj`（Unit 007でリネーム済み）のため、`versioning-with-jj` で進行（ユーザー承認済み）
- `docs/aidlc/` は `prompts/package/` のrsyncコピーのため、AGENTS.md等の編集は `prompts/package/` 側で行う
- `docs/cycles/rules.md` の `skill="codex"` は Unit 004 で既に新スキル名に更新済み
