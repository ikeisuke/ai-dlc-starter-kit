# Unit: reviewing-security スキル作成

## 概要
セキュリティに特化したレビュースキル `reviewing-security` を新規作成する。OWASP Top 10、認証・認可、依存脆弱性の観点チェックリストと、Codex/Claude/Geminiの実行コマンドを含むSKILL.mdを作成する。

## 含まれるユーザーストーリー
- ストーリー 3: セキュリティレビュースキルの利用

## 責務
- `prompts/package/skills/reviewing-security/SKILL.md` の作成
- agentskills.io frontmatter仕様準拠（name: reviewing-security、description: 三人称）
- セキュリティ観点チェックリスト（OWASP Top 10、認証・認可、依存脆弱性）
- Codex/Claude/Geminiの実行コマンド記載
- `references/` ディレクトリにセッション管理の詳細ファイル配置

## 境界
- コード品質観点・アーキテクチャ観点は含まない（Unit 001, 002で対応）
- review-flow.mdの更新は含まない（Unit 004で対応）
- シンボリックリンクの作成は含まない（Unit 009で対応）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- agentskills.io仕様（https://agentskills.io/specification）
- agentskills.ioベストプラクティス（https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices）
- 既存スキル（codex-review, claude-review, gemini-review）のツール呼び出し情報

## 非機能要件（NFR）
- **SKILL.md行数**: 500行以下（agentskills.io推奨）
- **Progressive Disclosure**: 詳細情報はreferences/に配置

## 技術的考慮事項
- Unit 001と同様のSKILL.md構造を踏襲（ツール呼び出し部分は共通パターン）
- セキュリティ固有の観点（OWASP Top 10、認証・認可、依存脆弱性）を重点的に記載

## 実装優先度
High

## 見積もり
小規模（SKILL.md + references 1ファイル以上）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
