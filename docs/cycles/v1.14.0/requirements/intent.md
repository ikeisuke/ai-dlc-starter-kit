# Intent（開発意図）

## プロジェクト名
AI-DLC スキル整理・agentskills.io準拠

## 開発の目的
AI-DLCスターターキットのスキル群を agentskills.io 仕様およびベストプラクティスに準拠した形に整理・再構成する。現状は個別に乱立しているレビュースキル（codex-review、claude-review、gemini-review）をレビュー種別ごとに再編し、各レビューに適切な観点（コンテキスト）を提供できるようにする。また、不要なスキル（gh）の削除とプロンプト調整、残存スキル（jj、aidlc-upgrade）のベストプラクティス準拠を行う。

## ターゲットユーザー
- AI-DLCスターターキットの利用者（AI-DLCを導入しているプロジェクトの開発者）
- AI-DLCスターターキット自体の開発者

## ビジネス価値
- **レビュー品質の向上**: レビュー種別（アーキテクチャ/コード/セキュリティ）に応じた観点を提供することで、AI任せの曖昧なレビューから、焦点の定まったレビューへ改善
- **スキルDiscoveryの精度向上**: 種別ごとにスキルを分割することで、エージェントがタスクに応じた適切なスキルを自動選択できる
- **Progressive Disclosure**: agentskills.io のパターンに沿い、必要なコンテキストだけを必要な時に読み込む構造にすることで、コンテキストウィンドウの効率的な利用を実現
- **拡張性**: ユーザーが新しいレビュースキル（例: reviewing-accessibility）をディレクトリ追加だけで拡張可能
- **gh依存の整理**: ghスキルを削除し、プロンプト全体でghが使えない場合のフローを改善

## 成功基準
- `prompts/package/skills/` に reviewing-code、reviewing-architecture、reviewing-security ディレクトリが存在し、各 SKILL.md が agentskills.io frontmatter仕様（name/description必須、name: 小文字英数字+ハイフン64文字以内）を満たしている
- 各レビュースキルの SKILL.md にレビュー観点（チェックリスト形式）が記載されている
- 各レビュースキルの SKILL.md にCodex/Claude/Geminiの呼び出しコマンドが記載されている
- `prompts/package/skills/` から codex-review、claude-review、gemini-review、gh ディレクトリが削除されている
- `.claude/skills/` のシンボリックリンクが新スキル構成と一致している（reviewing-code、reviewing-architecture、reviewing-security、jj、aidlc-upgrade の5リンク）
- review-flow.md の `skill="codex"` 等の呼び出しが新スキル名に更新されている
- jjスキルの SKILL.md が agentskills.io frontmatter仕様を満たし、description が三人称で記述されている
- aidlc-upgradeスキルが、外部プロジェクトで `prompts/setup-prompt.md` 不在時に再帰検索なしで `docs/aidlc.toml` 経由で解決するフローになっている（#181）

## 期限とマイルストーン
v1.14.0 サイクル内で完了

## 制約事項
- `docs/aidlc/` は `prompts/package/` の rsync コピーであるため、スキルの編集は `prompts/package/skills/` で行う（メタ開発ルール）
- 既存の review-flow.md（AIレビューフロー）との整合性を保つ
- 後方互換性: 既存の `skill="codex"` 等の呼び出しが影響を受ける場合、review-flow.md等の関連ファイルも更新する
- agentskills.io 仕様（https://agentskills.io/specification）: SKILL.md body は500行以下を推奨
- agentskills.io ベストプラクティス（https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices）

## スコープ

### 含まれるもの
1. **レビュースキル再編（3スキル新規作成）**
   - **reviewing-code**: コード品質レビュー（可読性、保守性、パフォーマンス、テスト品質）
   - **reviewing-architecture**: アーキテクチャレビュー（構造、パターン、API設計、依存関係）
   - **reviewing-security**: セキュリティレビュー（OWASP、認証・認可、依存脆弱性）
   - 各スキルにツール呼び出し情報（Codex/Claude/Gemini）を含む
   - セッション管理等の詳細はreferencesに配置
2. **codex-review、claude-review、gemini-review スキル削除**
3. **gh スキル削除 + プロンプト調整**: `prompts/package/skills/gh/` 削除、以下のプロンプトでgh未使用時の分岐を改善:
   - `prompts/package/prompts/inception.md`
   - `prompts/package/prompts/construction.md`
   - `prompts/package/prompts/operations.md`
   - `prompts/package/prompts/AGENTS.md`
4. **jj スキル改善**: agentskills.io ベストプラクティス準拠（description三人称化、frontmatter整備）
5. **aidlc-upgrade スキル改善**: #181 対応（setup-prompt.md検索効率化）+ agentskills.io ベストプラクティス準拠
6. **関連ファイル更新**:
   - `prompts/package/prompts/common/review-flow.md`: スキル呼び出し名の更新
   - `prompts/package/prompts/AGENTS.md`: スキル一覧の更新
   - `prompts/package/guides/skill-usage-guide.md`: スキル構成説明の更新
   - `.claude/skills/`: シンボリックリンクの再構成（旧スキル削除、新スキル追加）

### 明示的に除外するもの
- 新規レビュースキルの追加（上記3種以外、例: reviewing-accessibility）
- AI-DLCフェーズ自体のスキル化（#116 は今回対象外）
- セミオートモード（#164）
- GitHub Projects連携（#31）

## 不明点と質問（Inception Phase中に記録）

[Question] レビュースキルの命名は reviewing-code / reviewing-architecture / reviewing-security でよいか？
[Answer] はい。agentskills.ioのベストプラクティス（gerund form推奨）に従い、種別ごとに分割する方針で決定。Discovery精度の向上と拡張性を重視。

[Question] レビュースキル統合か分割か？
[Answer] 分割。agentskills.ioベストプラクティスに従い、descriptionの焦点を絞ることでDiscovery精度を優先。ツール呼び出し情報の軽微な重複は許容。

[Question] ツール固有のreferencesファイルの重複をどう扱うか？
[Answer] 各SKILL.md本体に数行のツール呼び出し方法を埋め込み、セッション管理等の詳細のみreferencesに配置。重複は最小限に抑える。
