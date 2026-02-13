# ユーザーストーリー

## 依存関係

```
ストーリー 1,2,3（新レビュースキル作成）→ ストーリー 4（レビューフロー更新）
ストーリー 1,2,3,4 → ストーリー 5（旧スキル削除）
ストーリー 4,5,6 → ストーリー 9（ドキュメント・リンク整合）
ストーリー 7,8 は独立して実施可能
```

## Epic 1: レビュースキルの再編

### ストーリー 1: コードレビュースキルの利用
**優先順位**: Must-have
**依存**: なし

As a AI-DLC利用者
I want to コードレビュー実行時に、コード品質に特化した観点（可読性、保守性、パフォーマンス、テスト品質）が自動的に提供される
So that レビューの焦点が明確になり、AI任せの曖昧なレビューよりも具体的な指摘が得られる

**受け入れ基準**:
- [ ] `prompts/package/skills/reviewing-code/SKILL.md` が存在する
- [ ] SKILL.md の frontmatter に `name: reviewing-code` と三人称の description が記載されている
- [ ] SKILL.md body にコード品質の観点チェックリスト（可読性、保守性、パフォーマンス、テスト品質の各項目）が記載されている
- [ ] SKILL.md body に Codex、Claude、Gemini の実行コマンド（各1コマンド以上）が記載されている
- [ ] references/ ディレクトリにセッション管理の詳細ファイルが1つ以上存在する

---

### ストーリー 2: アーキテクチャレビュースキルの利用
**優先順位**: Must-have
**依存**: なし

As a AI-DLC利用者
I want to アーキテクチャレビュー実行時に、設計に特化した観点（構造、パターン、API設計、依存関係）が自動的に提供される
So that 設計の妥当性を体系的に検証でき、構造的な問題を早期に発見できる

**受け入れ基準**:
- [ ] `prompts/package/skills/reviewing-architecture/SKILL.md` が存在する
- [ ] SKILL.md の frontmatter に `name: reviewing-architecture` と三人称の description が記載されている
- [ ] SKILL.md body にアーキテクチャ観点のチェックリスト（構造、パターン、API設計、依存関係の各項目）が記載されている
- [ ] SKILL.md body に Codex、Claude、Gemini の実行コマンド（各1コマンド以上）が記載されている
- [ ] references/ ディレクトリにセッション管理の詳細ファイルが1つ以上存在する

---

### ストーリー 3: セキュリティレビュースキルの利用
**優先順位**: Must-have
**依存**: なし

As a AI-DLC利用者
I want to セキュリティレビュー実行時に、セキュリティに特化した観点（OWASP Top 10、認証・認可、依存脆弱性）が自動的に提供される
So that セキュリティリスクを網羅的にチェックでき、脆弱性の見落としを防げる

**受け入れ基準**:
- [ ] `prompts/package/skills/reviewing-security/SKILL.md` が存在する
- [ ] SKILL.md の frontmatter に `name: reviewing-security` と三人称の description が記載されている
- [ ] SKILL.md body にセキュリティ観点のチェックリスト（OWASP Top 10、認証・認可、依存脆弱性の各項目）が記載されている
- [ ] SKILL.md body に Codex、Claude、Gemini の実行コマンド（各1コマンド以上）が記載されている
- [ ] references/ ディレクトリにセッション管理の詳細ファイルが1つ以上存在する

---

### ストーリー 4: レビューフローからの新スキル呼び出し
**優先順位**: Must-have
**依存**: ストーリー 1, 2, 3

As a AI-DLC利用者
I want to AI-DLCのレビューフロー（review-flow.md）から新しいレビュースキルが正しく呼び出される
So that 既存の開発ワークフローが途切れることなく、新しいレビュースキルに移行できる

**受け入れ基準**:
- [ ] `prompts/package/prompts/common/review-flow.md` 内の `skill="codex"` / `skill="claude"` / `skill="gemini"` が新スキル名に更新されている
- [ ] review-flow.md にレビュー種別（code/architecture/security）の選択ロジックが記載されている
- [ ] review-flow.md 内に `docs/aidlc.toml` の `[rules.reviewing].ai_tools` を参照してツールを選択する記述が存在する
- [ ] `docs/aidlc.toml` のセクション名が `[rules.reviewing]` にリネーム済みである

**技術的考慮事項**:
現在のreview-flow.mdはツール選択（codex/claude/gemini）のみ。新設計ではレビュー種別選択→ツール選択の2段階になる。

---

## Epic 2: 不要スキルの削除と整理

### ストーリー 5: 旧レビュースキルの削除
**優先順位**: Must-have
**依存**: ストーリー 1, 2, 3, 4（新スキル作成とレビューフロー更新が完了している必要がある）

As a AI-DLCスターターキット開発者
I want to codex-review、claude-review、gemini-reviewの3スキルが削除される
So that 旧スキルと新スキルが混在せず、保守対象が明確になる

**受け入れ基準**:
- [ ] `prompts/package/skills/` から codex-review、claude-review、gemini-review ディレクトリが存在しない
- [ ] `.claude/skills/` から codex-review、claude-review、gemini-review のシンボリックリンクが存在しない
- [ ] `grep -r "codex-review\|claude-review\|gemini-review" prompts/package/` で旧スキル名がヒットしない（CHANGELOG除く）

---

### ストーリー 6: ghスキルの削除
**優先順位**: Must-have
**依存**: なし

As a AI-DLCスターターキット開発者
I want to ghスキルが削除される
So that AIが既に知っている知識の冗長なスキルが排除され、スキル一覧がシンプルになる

**受け入れ基準**:
- [ ] `prompts/package/skills/gh/` ディレクトリが存在しない
- [ ] `.claude/skills/gh` シンボリックリンクが存在しない
- [ ] `grep -r '"gh"' prompts/package/guides/skill-usage-guide.md` でghスキルへの参照がヒットしない
- [ ] `grep -r "skill.*gh" prompts/package/prompts/` でghスキルを呼び出すロジックがヒットしない（`gh:available` 判定はスキル非依存のため影響なし）

---

## Epic 3: 既存スキルの改善

### ストーリー 7: jjスキルのベストプラクティス準拠
**優先順位**: Should-have
**依存**: なし

As a AI-DLC利用者
I want to jjスキルがagentskills.io仕様に準拠した構造になっている
So that スキルの自動選択精度が向上し、必要なコンテキストだけが効率的に読み込まれる

**受け入れ基準**:
- [ ] SKILL.md の frontmatter の name が小文字英数字+ハイフンのみで構成されている
- [ ] SKILL.md の frontmatter の description が三人称で記述されている（"I" や "You" で始まらない）
- [ ] Git対照表がreferences/ディレクトリ内の別ファイルに分離されている
- [ ] SKILL.md body が500行以下である（`wc -l` で確認）

---

### ストーリー 8: aidlc-upgradeスキルの改善
**優先順位**: Should-have
**依存**: なし

As a 外部プロジェクトのAI-DLC利用者
I want to `/aidlc-upgrade` 実行時に `prompts/setup-prompt.md` が不在の場合、再帰検索なしで `docs/aidlc.toml` 経由でパスを解決する
So that 無駄な検索が発生せず、効率的にアップグレードが開始される

**受け入れ基準**:
- [ ] SKILL.md に検索フローが記載されている: (1) `prompts/setup-prompt.md` の存在確認を1回実行 (2) 存在しない場合は `docs/aidlc.toml` から `ghq root` 経由のパスを解決 (3) Glob等の再帰検索は行わない
- [ ] SKILL.md の frontmatter の description が三人称で記述されている
- [ ] SKILL.md の frontmatter が agentskills.io 仕様を満たしている（name: 小文字英数字+ハイフン）

---

## Epic 4: 関連ファイルの整合性確保

### ストーリー 9: シンボリックリンクとドキュメントの更新
**優先順位**: Must-have
**依存**: ストーリー 4, 5, 6（スキル再編・削除が完了している必要がある）

As a AI-DLCスターターキット開発者
I want to `.claude/skills/` のシンボリックリンク、AGENTS.md、skill-usage-guide.md、setup-prompt.md が新スキル構成と一致している
So that セットアップ時やアップグレード時にスキルが正しく配置される

**受け入れ基準**:
- [ ] `.claude/skills/` に reviewing-code、reviewing-architecture、reviewing-security、jj、aidlc-upgrade の5つのシンボリックリンクが存在し、それぞれ `docs/aidlc/skills/` 配下を指している
- [ ] `prompts/package/prompts/AGENTS.md` のスキル一覧テーブルに reviewing-code、reviewing-architecture、reviewing-security が記載されている
- [ ] `prompts/package/guides/skill-usage-guide.md` のスキル構成説明が新構成（5スキル）に更新されている
- [ ] `prompts/setup-prompt.md` のシンボリックリンク作成処理が新スキル名（5スキル）に更新されている
- [ ] `docs/cycles/rules.md` の `skill="codex"` が新スキル名に更新されている
