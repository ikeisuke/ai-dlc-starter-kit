# Unit: reviewing-code スキル作成

## 概要
コード品質に特化したレビュースキル `reviewing-code` を新規作成する。可読性、保守性、パフォーマンス、テスト品質の観点チェックリストと、Codex/Claude/Geminiの実行コマンドを含むSKILL.mdを作成する。

## 含まれるユーザーストーリー
- ストーリー 1: コードレビュースキルの利用

## 責務
- `prompts/package/skills/reviewing-code/SKILL.md` の作成
- agentskills.io frontmatter仕様準拠（name: reviewing-code、description: 三人称）
- コード品質観点チェックリスト（可読性、保守性、パフォーマンス、テスト品質）
- Codex/Claude/Geminiの実行コマンド記載
- `references/` ディレクトリにセッション管理の詳細ファイル配置

## 境界
- アーキテクチャ観点・セキュリティ観点は含まない（Unit 002, 003で対応）
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
- 既存3スキル（codex-review, claude-review, gemini-review）のツール呼び出し情報を統合
- セッション管理（resume）の詳細はreferences/に分離し、SKILL.md本体は簡潔に保つ
- compatibilityフィールドでClaude Code対応を明記

## 受け入れ基準
- [ ] `test -d prompts/package/skills/reviewing-code` でディレクトリが存在する
- [ ] `test -f prompts/package/skills/reviewing-code/SKILL.md` でSKILL.mdが存在する
- [ ] SKILL.md frontmatterに `name: reviewing-code` が記載されている
- [ ] SKILL.md frontmatterのdescriptionが三人称で記述されている（"I" や "You" で始まらない）
- [ ] SKILL.md bodyにコード品質観点チェックリスト（可読性、保守性、パフォーマンス、テスト品質）が記載されている
- [ ] SKILL.md bodyにCodex、Claude、Geminiの実行コマンドが各1つ以上記載されている
- [ ] `ls prompts/package/skills/reviewing-code/references/` で1ファイル以上存在する
- [ ] `wc -l < prompts/package/skills/reviewing-code/SKILL.md` が500以下である

## 実装優先度
High

## 見積もり
0.5日（SKILL.md作成 + references 1ファイル。既存3スキルからの情報統合が主作業）

---
## 実装状態

- **状態**: 進行中
- **開始日**: 2026-02-13
- **完了日**: -
- **担当**: @claude
