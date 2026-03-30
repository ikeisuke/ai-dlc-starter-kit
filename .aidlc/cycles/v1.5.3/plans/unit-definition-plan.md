# Unit定義計画

## サイクル: v1.5.3

## 概要

11件のユーザーストーリーを8つのUnitに分解する。

---

## Unit一覧

| 番号 | Unit名 | 含まれるストーリー | 依存関係 | 優先度 |
|-----|--------|------------------|---------|-------|
| 001 | shell-compatibility | 1.1 | なし | High |
| 002 | backward-compatibility | 1.2 | なし | High |
| 003 | cycle-name-auto-detection | 1.3, 2.3 | なし | High |
| 004 | upgrade-flow-improvement | 1.4 | 002 | Medium |
| 005 | worktree-improvement | 1.5, 1.6 | なし | High |
| 006 | ai-review-enhancement | 2.1, 2.2 | なし | High |
| 007 | cicd-setup | 3.1 | なし | Medium |
| 008 | monitoring-setup | 3.2 | 007 | Low |

---

## 依存関係図

```
001-shell-compatibility ──────────────────────┐
                                              │
002-backward-compatibility ──┬────────────────┼── 並列実行可能
                             │                │
003-cycle-name-auto-detection┼────────────────┤
                             │                │
005-worktree-improvement ────┼────────────────┤
                             │                │
006-ai-review-enhancement ───┼────────────────┤
                             │                │
007-cicd-setup ──────────────┘                │
                                              │
004-upgrade-flow-improvement ←── 002完了後    │
                                              │
008-monitoring-setup ←── 007完了後            │
```

---

## Unit詳細

### Unit 001: shell-compatibility
**セットアップスクリプトのシェル互換性修正**

- **ストーリー**: 1.1 zsh互換性の確保
- **対象ファイル**: prompts/setup-prompt.md, prompts/package/prompts/setup.md
- **作業内容**: grep -oP を grep -E + sed に置き換え

---

### Unit 002: backward-compatibility
**v1.5.1後方互換性の確保**

- **ストーリー**: 1.2 v1.5.1後方互換性の確保
- **対象ファイル**: prompts/setup-prompt.md
- **作業内容**: スターターキット内のsetup.mdを参照するよう修正

---

### Unit 003: cycle-name-auto-detection
**サイクル名の自動検出と引き継ぎ**

- **ストーリー**: 1.3 サイクル名の自動引き継ぎ, 2.3 ブランチ名からのバージョン自動推測
- **対象ファイル**: prompts/setup-prompt.md, prompts/package/prompts/setup.md, prompts/package/prompts/inception.md
- **作業内容**:
  - ブランチ名からバージョン推測ロジック追加
  - 完了メッセージにサイクル名を含める

---

### Unit 004: upgrade-flow-improvement
**アップグレード後の動作改善**

- **ストーリー**: 1.4 アップグレード後の動作改善
- **依存**: Unit 002 (後方互換性修正が前提)
- **対象ファイル**: prompts/setup-prompt.md
- **作業内容**: アップグレード完了後の自動サイクル開始を抑止

---

### Unit 005: worktree-improvement
**worktree機能の改善**

- **ストーリー**: 1.5 worktreeディレクトリ構造の改善, 1.6 AIによるworktree自動作成
- **対象ファイル**: prompts/setup-prompt.md, prompts/package/prompts/setup.md
- **作業内容**:
  - 正しいworktree作成コマンドへの修正
  - AIによる自動作成機能追加
  - フォールバック動作の実装

---

### Unit 006: ai-review-enhancement
**AIレビュー機能の強化**

- **ストーリー**: 2.1 AIレビュー必須設定の確実な実行, 2.2 人間承認前のAIレビュー自動化
- **対象ファイル**: prompts/package/prompts/inception.md, prompts/package/prompts/construction.md, prompts/package/prompts/operations.md
- **作業内容**:
  - mode=required時の強制実行ロジック追加
  - 承認前のAIレビュー自動化

---

### Unit 007: cicd-setup
**CI/CD構築**

- **ストーリー**: 3.1 CI/CD構築
- **対象ファイル**: .github/workflows/ (新規作成)
- **作業内容**:
  - PRチェック用ワークフロー作成
  - Markdownリンター設定

---

### Unit 008: monitoring-setup
**監視・分析の案内**

- **ストーリー**: 3.2 監視・分析の案内
- **依存**: Unit 007 (CI/CDが基盤)
- **対象ファイル**: ドキュメント (新規または追記)
- **作業内容**: GitHub Insightsの活用案内を記載

---

## 実行順序の提案

**フェーズ1（並列実行可能）**:
- 001-shell-compatibility
- 002-backward-compatibility
- 003-cycle-name-auto-detection
- 005-worktree-improvement
- 006-ai-review-enhancement
- 007-cicd-setup

**フェーズ2（依存関係あり）**:
- 004-upgrade-flow-improvement (002完了後)
- 008-monitoring-setup (007完了後)
