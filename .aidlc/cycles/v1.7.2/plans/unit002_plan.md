# Unit 002: jjサポート - 設定とドキュメント 計画

## 概要

jjサポートのための設定テンプレート修正とドキュメント改善を行う。

## 対象ストーリー

- ストーリー 2-1: setup-prompt.mdへの[rules.jj]追加 (#40)
- ストーリー 2-3: jj-support.mdへの説明追加 (#43)

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup-prompt.md` | aidlc.tomlテンプレートに[rules.jj]セクションを追加（セクション7.2） |
| `prompts/setup-prompt.md` | 設定マイグレーションに[rules.jj]を追加（セクション7.4） |
| `prompts/package/guides/jj-support.md` | 「gitとjjの考え方の違い」セクションを追加 |

## 作成される成果物

| ファイル | 説明 |
|---------|------|
| `docs/cycles/v1.7.2/design-artifacts/domain-models/unit002_domain_model.md` | ドメインモデル設計 |
| `docs/cycles/v1.7.2/design-artifacts/logical-designs/unit002_logical_design.md` | 論理設計 |
| `docs/cycles/v1.7.2/construction/units/unit002_implementation.md` | 実装記録 |

## 詳細計画

### 1. setup-prompt.md の修正（セクション7.2: テンプレート）

**場所**: セクション7.2「aidlc.toml の内容」内のテンプレート

**追加内容**:
```toml
[rules.jj]
# jjサポート設定（v1.7.2で追加）
# enabled: true | false
# - true: プロンプト内でjj-support.md参照を案内
# - false: 従来のgitコマンドを使用（デフォルト）
enabled = false
```

**挿入位置**: `[rules.history]` セクションの後、`[rules.custom]` セクションの前

### 1.1 setup-prompt.md の修正（セクション7.4: マイグレーション）

**場所**: セクション7.4「設定マイグレーション【アップグレードモードのみ】」

**追加内容**: `[rules.jj]` セクションのマイグレーションスクリプト（既存の `[backlog]` マイグレーションと同様のパターン）

### 2. jj-support.md の修正

**追加セクション**: 「gitとjjの考え方の違い」

**追加内容**:
- ワーキングコピーの扱いの違い
- コミットタイミングの違い
- ブランチ vs ブックマークの概念
- フロー比較図（ASCII図）

**挿入位置**: 「## 前提条件」セクションの後、「## jjの特徴と利点」セクションの前

## 実装手順

1. Phase 1: 設計
   - ドメインモデル設計（簡略化）
   - 論理設計
   - 設計レビュー

2. Phase 2: 実装
   - setup-prompt.md セクション7.2 の修正（テンプレート）
   - setup-prompt.md セクション7.4 の修正（マイグレーション）
   - jj-support.md の修正
   - テスト（markdownlint）
   - コミット

## スコープ外

- `enabled=true` 時のプロンプト動作変更は別Unit/サイクルで対応
- 現時点ではユーザーが手動でjj-support.mdを参照

## 注意事項

- `docs/aidlc/` は直接編集禁止。`prompts/package/` を編集すること
- Operations Phaseでrsyncにより `docs/aidlc/` に反映される
