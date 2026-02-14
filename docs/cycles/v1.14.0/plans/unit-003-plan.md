# Unit 003 計画: reviewing-security スキル作成

## 概要

セキュリティに特化したレビュースキル `reviewing-security` を新規作成する。
Unit 001 (reviewing-code)、Unit 002 (reviewing-architecture) と同様の構造を踏襲し、
セキュリティ固有の観点（OWASP Top 10、認証・認可、依存脆弱性）を記載する。

## 変更対象ファイル

### 新規作成

- `prompts/package/skills/reviewing-security/SKILL.md` - メインスキルファイル
- `prompts/package/skills/reviewing-security/references/session-management.md` - セッション管理ガイド

## 実装計画

### Phase 1: 設計

Unit 001/002と同じ構造のため、設計フェーズは軽量に実施。

1. **ドメインモデル設計**: SKILL.mdのfrontmatter仕様、セキュリティ観点チェックリストの項目定義
2. **論理設計**: ファイル構造、Progressive Disclosure（references/への詳細分離）
3. **設計レビュー**: AIレビュー実施

### Phase 2: 実装

1. **SKILL.md作成**:
   - frontmatter: name, description, argument-hint, compatibility, allowed-tools
   - レビュー観点: OWASP Top 10、認証・認可、依存脆弱性
   - 実行コマンド: Codex, Claude Code, Gemini
   - セッション継続: 各ツールのresume方法

2. **references/session-management.md作成**:
   - Unit 001/002と同一内容（共通パターン）

3. **テスト/検証**:
   - ファイル存在確認
   - frontmatter検証
   - 行数制限（500行以下）確認

## 完了条件チェックリスト

- [ ] `prompts/package/skills/reviewing-security/` ディレクトリが存在する
- [ ] `prompts/package/skills/reviewing-security/SKILL.md` が存在する
- [ ] SKILL.md frontmatterに `name: reviewing-security` が記載されている
- [ ] SKILL.md frontmatterのdescriptionが三人称で記述されている
- [ ] SKILL.md frontmatterにargument-hint, compatibility, allowed-toolsが記載されている（既存スキルとの構造的一貫性）
- [ ] SKILL.md bodyにセキュリティ観点チェックリスト（OWASP Top 10、認証・認可、依存脆弱性）が記載されている
- [ ] SKILL.md bodyにCodex、Claude、Geminiの実行コマンドが各1つ以上記載されている
- [ ] SKILL.md bodyが「レビュー観点」→「実行コマンド」→「セッション継続」のセクション構成（既存スキルと同一構造）
- [ ] `prompts/package/skills/reviewing-security/references/session-management.md` が存在する
- [ ] SKILL.mdが500行以下である
