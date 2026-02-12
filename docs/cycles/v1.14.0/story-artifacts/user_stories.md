# ユーザーストーリー

## Epic 1: レビュースキルの再編

### ストーリー 1: コードレビュースキルの利用
**優先順位**: Must-have

As a AI-DLC利用者
I want to コードレビュー実行時に、コード品質に特化した観点（可読性、保守性、パフォーマンス、テスト品質）が自動的に提供される
So that レビューの焦点が明確になり、AI任せの曖昧なレビューよりも具体的な指摘が得られる

**受け入れ基準**:
- [ ] `reviewing-code` スキルが存在し、SKILL.md にコード品質のチェックリストが記載されている
- [ ] SKILL.md からCodex、Claude、Geminiの3ツールを呼び出せるコマンドが記載されている
- [ ] セッション管理の詳細がreferences/に配置されている
- [ ] `skill="reviewing-code"` で呼び出しが可能である

---

### ストーリー 2: アーキテクチャレビュースキルの利用
**優先順位**: Must-have

As a AI-DLC利用者
I want to アーキテクチャレビュー実行時に、設計に特化した観点（構造、パターン、API設計、依存関係）が自動的に提供される
So that 設計の妥当性を体系的に検証でき、構造的な問題を早期に発見できる

**受け入れ基準**:
- [ ] `reviewing-architecture` スキルが存在し、SKILL.md にアーキテクチャ観点のチェックリストが記載されている
- [ ] SKILL.md からCodex、Claude、Geminiの3ツールを呼び出せるコマンドが記載されている
- [ ] セッション管理の詳細がreferences/に配置されている
- [ ] `skill="reviewing-architecture"` で呼び出しが可能である

---

### ストーリー 3: セキュリティレビュースキルの利用
**優先順位**: Must-have

As a AI-DLC利用者
I want to セキュリティレビュー実行時に、セキュリティに特化した観点（OWASP Top 10、認証・認可、依存脆弱性）が自動的に提供される
So that セキュリティリスクを網羅的にチェックでき、脆弱性の見落としを防げる

**受け入れ基準**:
- [ ] `reviewing-security` スキルが存在し、SKILL.md にセキュリティ観点のチェックリストが記載されている
- [ ] SKILL.md からCodex、Claude、Geminiの3ツールを呼び出せるコマンドが記載されている
- [ ] セッション管理の詳細がreferences/に配置されている
- [ ] `skill="reviewing-security"` で呼び出しが可能である

---

### ストーリー 4: レビューフローからの新スキル呼び出し
**優先順位**: Must-have

As a AI-DLC利用者
I want to AI-DLCのレビューフロー（review-flow.md）から新しいレビュースキルが正しく呼び出される
So that 既存の開発ワークフローが途切れることなく、新しいレビュースキルに移行できる

**受け入れ基準**:
- [ ] review-flow.md の `skill="codex"` 等が新スキル名（reviewing-code / reviewing-architecture / reviewing-security）に更新されている
- [ ] ai_tools設定（Codex/Claude/Gemini）による優先順位選択が引き続き動作する
- [ ] レビュー種別の選択ロジックがreview-flow.mdに追加されている

**技術的考慮事項**:
現在のreview-flow.mdはツール選択（codex/claude/gemini）のみ。新設計ではレビュー種別選択→ツール選択の2段階になる。

---

## Epic 2: 不要スキルの削除と整理

### ストーリー 5: 旧レビュースキルの削除
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to codex-review、claude-review、gemini-reviewの3スキルが削除される
So that 旧スキルと新スキルが混在せず、保守対象が明確になる

**受け入れ基準**:
- [ ] `prompts/package/skills/` から codex-review、claude-review、gemini-review ディレクトリが削除されている
- [ ] `.claude/skills/` から対応するシンボリックリンクが削除されている
- [ ] AGENTS.md、skill-usage-guide.md から旧スキル名への参照がすべて除去されている

---

### ストーリー 6: ghスキルの削除
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to ghスキルが削除される
So that AIが既に知っている知識の冗長なスキルが排除され、スキル一覧がシンプルになる

**受け入れ基準**:
- [ ] `prompts/package/skills/gh/` ディレクトリが削除されている
- [ ] `.claude/skills/gh` シンボリックリンクが削除されている
- [ ] AGENTS.md、skill-usage-guide.md から gh スキルへの参照がすべて除去されている
- [ ] AI-DLCプロンプト内の `gh:available` 判定ロジックは影響を受けない（スキルに依存していないことを確認済み）

---

## Epic 3: 既存スキルの改善

### ストーリー 7: jjスキルのベストプラクティス準拠
**優先順位**: Should-have

As a AI-DLC利用者
I want to jjスキルがagentskills.io仕様に準拠した構造になっている
So that スキルの自動選択精度が向上し、必要なコンテキストだけが効率的に読み込まれる

**受け入れ基準**:
- [ ] SKILL.md の frontmatter が agentskills.io 仕様を満たしている（name: 小文字英数字+ハイフン、description: 三人称）
- [ ] Git対照表（約40行）がreferences/に分離されている
- [ ] SKILL.md body が500行以下である

---

### ストーリー 8: aidlc-upgradeスキルの改善
**優先順位**: Should-have

As a 外部プロジェクトのAI-DLC利用者
I want to `/aidlc-upgrade` 実行時に `prompts/setup-prompt.md` が不在の場合、再帰検索なしで `docs/aidlc.toml` 経由でパスを解決する
So that 無駄な検索が発生せず、効率的にアップグレードが開始される

**受け入れ基準**:
- [ ] SKILL.md にsetup-prompt.md検索の最適化フローが記載されている（1. 存在確認 → 2. 不在なら即aidlc.toml経由）
- [ ] SKILL.md の frontmatter が agentskills.io 仕様を満たしている
- [ ] 関連Issue #181 の要件を満たしている

---

## Epic 4: 関連ファイルの整合性確保

### ストーリー 9: シンボリックリンクとドキュメントの更新
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to `.claude/skills/` のシンボリックリンク、AGENTS.md、skill-usage-guide.md、setup-prompt.md が新スキル構成と一致している
So that セットアップ時やアップグレード時にスキルが正しく配置される

**受け入れ基準**:
- [ ] `.claude/skills/` に reviewing-code、reviewing-architecture、reviewing-security、jj、aidlc-upgrade の5つのシンボリックリンクが存在する
- [ ] AGENTS.md のスキル一覧テーブルが新構成に更新されている
- [ ] skill-usage-guide.md のスキル構成説明が新構成に更新されている
- [ ] setup-prompt.md のシンボリックリンク作成処理が新スキル名に更新されている
- [ ] docs/cycles/rules.md の `skill="codex"` が新スキル名に更新されている
