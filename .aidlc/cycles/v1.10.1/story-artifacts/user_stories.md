# ユーザーストーリー

## Epic 1: ドキュメント整備

### ストーリー 1: README.mdのバージョン一覧の並び順修正 (#130)

**優先順位**: Must-have

As a AI-DLCスターターキットの利用者
I want to README.mdのバージョン一覧が一貫した順序で表示される
So that バージョン情報を素早く見つけて参照できる

**受け入れ基準**:
- [ ] バージョン一覧がセマンティックバージョン順（降順: 新しい順）でソートされている
- [ ] すべてのバージョンエントリが同じフォーマットで記載されている

**技術的考慮事項**:
- 対象ファイル: `README.md`
- セマンティックバージョン比較でソート（v1.10.0 > v1.9.0）

---

## Epic 2: 運用フロー改善

### ストーリー 2: PRマージ時のsquash使用を明示的に確認するフロー (#134)

**優先順位**: Must-have

As a AI-DLCを使用する開発者
I want to PRマージ時にマージ方法を明示的に選択できる
So that 意図しないコミット履歴の圧縮を防止できる

**受け入れ基準**:
- [ ] Operations Phaseのステップ6.5で、マージ方法を選択するフローが追加されている
- [ ] 選択肢として「通常マージ」「Squashマージ」「Rebaseマージ」が提示される
- [ ] 「通常マージ（コミット履歴を保持）」が推奨オプションとして最初に表示される

**技術的考慮事項**:
- 対象ファイル: `prompts/package/prompts/operations.md`
- AskUserQuestion形式での選択UIを想定

---

### ストーリー 3: Codex Skill反復レビュー時のresume使用を明確化 (#132)

**優先順位**: Must-have

As a Codex Skillを使用する開発者
I want to 反復レビュー時にresumeコマンドを使うべきことが明記されている
So that 前回のコンテキストを保持したまま効率的にレビューを継続できる

**受け入れ基準**:
- [ ] 「反復レビュー時のルール」セクションがSkillファイルに追加されている
- [ ] session idの確認・記録方法が明記されている
- [ ] resumeを使うべき場面が強調されている
- [ ] 反復レビューの流れが例示されている

**技術的考慮事項**:
- 対象ファイル: `prompts/package/skills/codex/SKILL.md`
- 既存の反復レビューフローとの整合性を確認

---

## Epic 3: Skills拡張

### ストーリー 4: gh (GitHub CLI) Skillの追加 (#123)

**優先順位**: Should-have

As a GitHub CLIを使用する開発者
I want to gh操作がAIスキルとして利用できる
So that AIとの協調作業でGitHub操作を効率的に実行できる

**受け入れ基準**:
- [ ] `prompts/package/skills/gh/SKILL.md` が作成されている
- [ ] Issue操作（作成、一覧、表示、クローズ）がカバーされている
- [ ] PR操作（作成、一覧、表示、マージ）がカバーされている
- [ ] 他のSkills（codex, claude, gemini）と同様の形式で記載されている

**技術的考慮事項**:
- 既存Skillsの形式を踏襲
- gh CLIの主要コマンドをカバー

---

### ストーリー 5: jj (Jujutsu) Skillの追加 (#124)

**優先順位**: Should-have

As a Jujutsu (jj) を使用する開発者
I want to jj操作がAIスキルとして利用できる
So that AIとの協調作業でバージョン管理操作を効率的に実行できる

**受け入れ基準**:
- [ ] `prompts/package/skills/jj/SKILL.md` が作成されている
- [ ] jjの基本操作（status, log, describe, new）がカバーされている
- [ ] git互換コマンド（fetch, push）がカバーされている
- [ ] co-locationモードでの使用方法が記載されている
- [ ] 既存の `docs/aidlc/guides/jj-support.md` の内容が活用されている

**技術的考慮事項**:
- 既存の `jj-support.md` ガイドを参照・活用
- gitコマンドとの対照表を含める
