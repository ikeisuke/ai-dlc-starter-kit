# 論理設計: deprecation準備

## 概要

後方互換性コードのdeprecation管理を実現するためのドキュメント構成と警告コメント形式を設計する。

**重要**: この論理設計では**コードは書かず**、構成と形式の定義のみを行います。

## アーキテクチャパターン

ドキュメント中心のdeprecation管理。AIプロンプト内でのコメントによる警告とCHANGELOG.mdによるユーザー通知を組み合わせる。

## コンポーネント構成

### ドキュメント構成

```text
prompts/package/
├── deprecation.md          # [新規] deprecation対象一覧（集中管理）
└── prompts/
    ├── construction.md     # [修正] progress.md参照に警告追加
    └── setup.md            # [修正] バックログ移行セクションに警告追加
```

### コンポーネント詳細

#### deprecation.md

- **責務**: すべてのdeprecation対象を一元管理
- **依存**: なし
- **公開インターフェース**: 開発者・利用者向けの参照ドキュメント

#### construction.md（修正箇所）

- **責務**: Construction Phase実行手順の提供
- **修正対象**: 後方互換性セクション（progress.md参照箇所、273-277行目付近）
- **警告形式**: blockquote警告（`> **DEPRECATED...**`）

#### setup.md（修正箇所）

- **責務**: セットアップ手順の提供
- **修正対象**: 旧形式バックログ移行セクション（504行目以降）
- **警告形式**: blockquote警告（`> **DEPRECATED...**`）

## 警告コメント形式

### 非推奨警告（ドキュメント内）

```markdown
> **DEPRECATED (v1.9.0)**: この機能は v2.0.0 で削除予定です。
> 詳細は `prompts/package/deprecation.md` を参照してください。
```

### 完全なセクション非推奨

```markdown
> **DEPRECATED (v1.9.0)**: このセクション全体が v2.0.0 で削除予定です。
> 新規プロジェクトでは影響ありません。
> 詳細は `prompts/package/deprecation.md` を参照してください。
```

## データモデル概要

### ファイル形式: deprecation.md

- **形式**: Markdown
- **主要セクション**:
  - 概要: deprecation方針の説明
  - 対象一覧: 各deprecation項目の詳細
  - 移行ガイド: 推奨される対応方法

### deprecation項目の構造

**ID形式**: `{feature-name}-{version}`（例: `progress-md-fallback-v1.9.0`）

```markdown
## [項目ID] [機能名]

- **非推奨バージョン**: v1.9.0
- **削除予定バージョン**: v2.0.0
- **説明**: [機能の説明と具体的な対象]
- **影響ファイル**:
  - `path/to/file1.md`
  - `path/to/file2.md`
- **移行ガイド**: [代替手段または「対応不要」]
```

**必須属性**: 非推奨バージョン、削除予定バージョン、説明、影響ファイル、移行ガイド

## 処理フロー概要

### deprecation対象の追加フロー

**ステップ**:

1. deprecation.mdに新規項目を追加
2. 対象ファイルに警告コメントを追加
3. CHANGELOG.mdのDeprecatedセクションに記載

**関与するファイル**: deprecation.md, 対象ファイル, CHANGELOG.md

### 削除時のフロー（v2.0.0で実施予定）

**ステップ**:

1. deprecation.mdから項目を削除（または「削除済み」に変更）
2. 対象ファイルから非推奨コード/セクションを削除
3. CHANGELOG.mdのRemovedセクションに記載

## 非機能要件（NFR）への対応

このUnitに該当するNFRはありません。ドキュメント作業のため。

## 技術選定

- **言語**: Markdown
- **フレームワーク**: なし
- **ツール**: なし（手動編集）

## 実装上の注意事項

- `prompts/package/`を編集すること（`docs/aidlc/`は直接編集禁止）
- 警告メッセージは利用者が理解しやすい表現にする
- 削除予定バージョン（v2.0.0）を明確に記載する
- 新規プロジェクトには影響がないことを明記する

## 不明点と質問

現時点で不明点はありません。Issue #80の内容と既存ファイルを確認の上設計しました。
