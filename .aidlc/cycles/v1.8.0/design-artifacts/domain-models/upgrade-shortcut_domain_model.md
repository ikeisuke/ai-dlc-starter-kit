# ドメインモデル設計: 簡略指示「AIDLCアップデート」追加

## Unit情報

- **Unit名**: 簡略指示「AIDLCアップデート」追加
- **Unit番号**: 008
- **関連Issue**: #69

## 概要

`prompts/package/prompts/AGENTS.md`のフェーズ簡略指示テーブルに「AIDLCアップデート」の指示パターンを追加し、ユーザーが簡単な指示で環境更新を開始できるようにする。

**注意**: このプロジェクトではソースオブトゥルースは`prompts/package/`であり、`docs/aidlc/`はOperations Phaseでrsyncによりコピーされる。

## ドメインコンセプト

### 簡略指示（ShortcutCommand）

**定義**: ユーザーがAI-DLCのフェーズや機能を開始するために使用する短い指示パターン。

**属性**:

- 指示パターン（日本語/英語）
- 対応するアクション
- 読み込むプロンプトファイル

### 既存の簡略指示パターン

| カテゴリ | 日本語 | 英語 | アクション |
|----------|--------|------|------------|
| Inception | 「インセプション進めて」 | start inception | inception.md読み込み |
| Construction | 「コンストラクション進めて」 | start construction | construction.md読み込み |
| Operations | 「オペレーション進めて」 | start operations | operations.md読み込み |
| Setup | 「セットアップ」 | start setup | setup.md読み込み |

### 新規追加パターン

| カテゴリ | 日本語 | 英語 | アクション |
|----------|--------|------|------------|
| Upgrade | 「AIDLCアップデート」 | 「update aidlc」「start upgrade」 | prompts/setup-prompt.md読み込み |

**注意**: 「AIDLCアップデートして」等の表現揺れはAIが自然言語として解釈するため、テーブルには代表的なパターンのみ記載する。

## ビジネスルール

1. **命名規則の一貫性**: 既存パターンに準じた命名を使用
2. **日英両対応**: 日本語・英語両方の指示パターンを提供
3. **直感的な表現**: 「アップデート」「upgrade」など、ユーザーが直感的に理解できる表現を使用
4. **setupとupgradeの区別**:
   - `start setup` / 「セットアップ」: 新規サイクル開始（`docs/aidlc/prompts/setup.md`）
   - `start upgrade` / 「AIDLCアップデート」: 環境更新（`prompts/setup-prompt.md`）
   - 両者は目的が異なるため、混同しないよう説明を付加する

## 境界

### スコープ内

- `prompts/package/prompts/AGENTS.md`のテーブル更新
- テーブル列名「対応フェーズ」を「対応処理」に変更（アップグレードはフェーズではないため）

### スコープ外

- setup-prompt.mdの内容変更
- 新しいプロンプトファイルの作成
