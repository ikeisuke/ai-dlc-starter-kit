# 論理設計: inception.mdサイズ最適化

## 概要

inception.mdのファイルサイズを最適化するための具体的な変更設計。外部ファイル構成、ヘルパースクリプトのインターフェース、置換パターンを定義する。

**重要**: この論理設計では**コードは書かず**、構成とインターフェース定義のみを行います。

## コンポーネント構成

### ファイル構成（変更後）

```text
prompts/package/
├── prompts/
│   └── inception.md          # 最適化後（目標: 730行以下）
├── guides/
│   ├── (既存ファイル)
│   └── ios-version-update.md # 新規: iOSバージョン更新ガイド
└── bin/
    ├── (既存スクリプト)
    ├── check-dependabot-prs.sh # 新規: Dependabot PR一覧取得
    └── check-open-issues.sh    # 新規: オープンIssue一覧取得
```

### コンポーネント詳細

#### ios-version-update.md

- **責務**: iOSプロジェクト向けバージョン更新手順の提供
- **参照元**: inception.md（完了時の必須作業セクション）
- **内容**:
  - 前提条件確認
  - バージョン更新提案メッセージ
  - 更新手順（バージョン確認、更新、履歴記録）
  - 注意事項

#### check-dependabot-prs.sh

- **責務**: Dependabot PRの一覧取得
- **呼び出し元**: inception.md（ステップ4）
- **入力**: なし
- **出力**: PR一覧（標準出力）またはエラーメッセージ

#### check-open-issues.sh

- **責務**: オープンIssueの一覧取得
- **呼び出し元**: inception.md（ステップ5）
- **入力**: オプションで件数指定（デフォルト10件）
- **出力**: Issue一覧（標準出力）またはエラーメッセージ

## インターフェース設計

### ヘルパースクリプト

#### check-dependabot-prs.sh

```text
用途: Dependabot PRの一覧を取得
使用法: docs/aidlc/bin/check-dependabot-prs.sh
出力形式:
  - PRあり: gh pr listの出力（PR番号、タイトル、状態）
  - PRなし: "dependabot_prs:none"
  - エラー: "error:[エラー内容]"
終了コード:
  - 0: 正常終了（PRの有無に関わらず）
  - 1: エラー（gh未インストール等）
```

#### check-open-issues.sh

```text
用途: オープンIssueの一覧を取得
使用法: docs/aidlc/bin/check-open-issues.sh [--limit N]
パラメータ:
  --limit N: 取得件数（デフォルト: 10）
出力形式:
  - Issueあり: gh issue listの出力（Issue番号、タイトル、ラベル）
  - Issueなし: "open_issues:none"
  - エラー: "error:[エラー内容]"
終了コード:
  - 0: 正常終了（Issueの有無に関わらず）
  - 1: エラー（gh未インストール等）
```

## 置換パターン

### 1. iOSバージョン更新セクション

**変更前**（649-703行、55行）:
```markdown
### 2. iOSバージョン更新【project.type=iosの場合のみ】

**前提条件確認**:
...（詳細な手順書、約55行）...
```

**変更後**（5行）:
```markdown
### 2. iOSバージョン更新【project.type=iosの場合のみ】

詳細な手順は `docs/aidlc/guides/ios-version-update.md` を参照。
```

**削減効果**: 約50行

### 2. Dependabot PR確認

**変更前**（372-399行の一部）:
```markdown
**`gh:available` の場合のみ**:
```bash
gh pr list --label "dependencies" --state open
```
```

**変更後**:
```markdown
**`gh:available` の場合のみ**:
```bash
docs/aidlc/bin/check-dependabot-prs.sh
```
```

**削減効果**: スクリプト化による保守性向上（行数削減は軽微）

### 3. GitHub Issue確認

**変更前**（400-427行の一部）:
```markdown
**`gh:available` の場合のみ**:
```bash
gh issue list --state open --limit 10
```
```

**変更後**:
```markdown
**`gh:available` の場合のみ**:
```bash
docs/aidlc/bin/check-open-issues.sh
```
```

**削減効果**: スクリプト化による保守性向上（行数削減は軽微）

### 4. 冗長な説明の簡略化

**対象**: セットアップコンテキスト確認セクション（290-340行の一部）

**変更方針**:
- 「重複質問回避のロジック」セクション内の詳細説明を表形式に統合
- 例外条件、ログ/説明文、カテゴリ判定の手順を簡潔化

**削減効果**: 約25行

## 処理フロー概要

### 外部化後のinception.md参照フロー

1. AIがinception.mdを読み込む
2. iOSバージョン更新が必要な場合、外部ガイドへの参照を検出
3. AIが必要に応じて`docs/aidlc/guides/ios-version-update.md`を読み込む
4. Dependabot/Issue確認時、ヘルパースクリプトを実行

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: AIのコンテキスト消費を10%以上削減
- **対応策**: 812行 → 730行以下（約85行削減、10.5%削減）

### 可用性

- **要件**: 最適化後も全機能が正常動作すること
- **対応策**:
  - 外部ファイルへの明確な参照パス記載
  - ヘルパースクリプトのエラーハンドリング
  - 既存フローの変更なし（参照方式のみ変更）

## 技術選定

- **言語**: Bash（ヘルパースクリプト）
- **形式**: Markdown（ガイドドキュメント）
- **依存**: GitHub CLI（gh）

## 実装上の注意事項

- 外部ファイルのパスは`docs/aidlc/`形式で記載（rsync後のパス）
- ヘルパースクリプトはgh利用可否のチェックを含める
- 既存の機能・フローは変更しない（参照方式のみ変更）

## 削減見積もりサマリー

| 変更内容 | 削減行数 |
|---------|---------|
| iOSバージョン更新外部化 | 約50行 |
| ヘルパースクリプト化 | 約10行 |
| 説明の簡略化 | 約25行 |
| **合計** | **約85行** |

**最終目標**: 812行 → 727行（約85行削減、10.5%削減）

## 不明点と質問

なし（ドメインモデル設計で解決済み）
