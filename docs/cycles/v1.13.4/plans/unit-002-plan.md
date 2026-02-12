# Unit 002 計画: Codex skills compatibilityフィールド追加

## 概要

`codex-review/SKILL.md` のYAMLフロントマターに `compatibility` フィールドを追加し、Codex CLIのサンドボックス要件（ネットワークアクセス等）を明記する。

## 変更対象ファイル

- `prompts/package/skills/codex-review/SKILL.md`（メタ開発: こちらを編集）

## 背景

- Agent Skills Specification v1.0 では `compatibility` フィールド（最大500文字）が定義されている
- Codex CLIはOpenAI APIへのネットワークアクセスが必要
- `codex` コマンド自体がインストール済みである必要がある
- サンドボックスモード（`-s read-only`）で動作するため、ファイル書き込み権限は不要

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: ドキュメントのみの変更のため、設計省略を検討
2. **論理設計**: 同上

※ Unit定義の「技術的考慮事項」に基づき、本Unitはフィールド追加のみのため、設計は軽量に進める

### Phase 2: 実装

1. `prompts/package/skills/codex-review/SKILL.md` のフロントマターに `compatibility` フィールドを追加
2. AIレビュー実施（required）
3. 統合とレビュー

## compatibilityフィールド案

```yaml
compatibility: Requires codex CLI and network access (OpenAI API). Runs in read-only sandbox mode.
```

## 完了条件チェックリスト

- [ ] `codex-review/SKILL.md` にcompatibilityフィールドが追加されている
- [ ] ネットワークアクセス等のサンドボックス要件が明記されている
- [ ] Agent Skills Specification v1.0準拠の形式で記載されている（500文字以内）
