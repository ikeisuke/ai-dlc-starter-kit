# 既存コード分析 - v1.15.1

## #192: Kiro .kiro/skills/ 標準呼び出し対応への移行

### 現状

- `.kiro/agents/aidlc.json` が `docs/aidlc/kiro/agents/aidlc.json` へのシンボリックリンクとして存在
- Kiroはスキルを `skill://docs/aidlc/skills/*/SKILL.md` パターンで参照している
- **`.kiro/skills/` ディレクトリは未作成**
- Claude Codeは `.claude/skills/` に `docs/aidlc/skills/` へのシンボリックリンクを配置

### スキルディレクトリ構成

```text
docs/aidlc/skills/
├── reviewing-architecture/  （SKILL.md + references/）
├── reviewing-code/          （SKILL.md + references/）
├── reviewing-security/      （SKILL.md + references/）
├── upgrading-aidlc/         （SKILL.md + references/）
└── versioning-with-jj/      （SKILL.md + references/）

.claude/skills/              （シンボリックリンク）
├── reviewing-architecture@ → ../../docs/aidlc/skills/reviewing-architecture
├── reviewing-code@          → ...
├── reviewing-security@      → ...
├── upgrading-aidlc@         → ...
└── versioning-with-jj@      → ...
```

### 対応方針

- `.kiro/skills/` ディレクトリを作成し、`docs/aidlc/skills/` へのシンボリックリンクを配置
- `.kiro/agents/aidlc.json` を更新（Kiro標準スキル発見方式に対応）
- Kiroの `.kiro/skills/` 仕様を調査して標準準拠
- Claude Code側の既存構成は変更なし

### 影響ファイル

- `.kiro/skills/`（新規作成）
- `.kiro/agents/aidlc.json` → `docs/aidlc/kiro/agents/aidlc.json`
- セットアップスクリプト（`.kiro/skills/` シンボリックリンク作成の追加）

---

## #191: AIDLC専用レビュースキル

### 現状

- 既存レビュースキル: `reviewing-code`, `reviewing-architecture`, `reviewing-security`
- すべてコード・アーキテクチャ・セキュリティ観点のレビュー
- Inception Phase成果物（Intent、ユーザーストーリー、Unit定義）専用のレビューは存在しない
- `review-flow.md` のCallerContextマッピングにInception Phase用エントリなし

### 既存スキル形式

```yaml
---
name: reviewing-[type]
description: [説明]
argument-hint: [引数ヒント]
compatibility: Requires codex CLI, claude CLI, or gemini CLI.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---
```

### 不足しているもの

- Intent用レビュー観点: 目的の明確さ、実現可能性、成功基準の測定可能性
- ユーザーストーリー用レビュー観点: INVEST原則、受入条件の妥当性、ユーザー価値
- Unit定義用レビュー観点: 依存関係の正確性、スコープ境界の明確さ、見積もり妥当性
- `review-flow.md` のCallerContextマッピング更新

### 影響ファイル

- `prompts/package/skills/reviewing-inception/SKILL.md`（新規作成）
- `prompts/package/prompts/common/review-flow.md`（CallerContext追加）
- `docs/cycles/rules.md`（スキル一覧更新）

---

## #189: upgrading-aidlc ローカル探索ステップ省略

### 現状

現在のワークフロー（2ステップ）:

1. **ローカル探索**: `prompts/setup-prompt.md` の存在確認 → 存在すれば読み込み
2. **スターターキットリポジトリ解決**: `docs/aidlc.toml` の `starter_kit_repo` 経由でパス解決

### 問題点

- ローカル探索は不要。`setup-prompt.md` は常にスターターキットリポジトリに存在する
- ステップ1が冗長で、スターターキット開発リポジトリ（自身）でのみ意味がある

### 対応方針

- ステップ1（ローカル探索）を削除
- 常にステップ2（スターターキットリポジトリから取得）を実行

### 影響ファイル

- `prompts/package/skills/upgrading-aidlc/SKILL.md`（ステップ1の削除）

---

## #190: migrate-backlog.sh macOS sed互換性エラー

### 現状

`generate_slug()` 関数（60行目）で日本語文字範囲を使用:

```bash
sed 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g'
```

macOS BSD sedでは `一-龯`, `ぁ-ん`, `ァ-ヶ` のUnicode文字範囲が無効。

### エラー

```text
sed: 1: "s/[^a-z0-9一-龯ぁ-…": RE error: invalid character range
```

### 対応方針

`sed` を `perl` に置換（Unicodeサポートが確実）:

```bash
perl -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g'
```

### 影響ファイル

- `prompts/package/bin/migrate-backlog.sh`（60行目）
