# 論理設計: バックログ用Issueテンプレート

## 概要

GitHub Issue Forms（YAML形式）の配置構成と、セットアッププロンプトへのコピー処理追加を設計する。

**重要**: この論理設計では**コードは書かず**、構成とインターフェース定義のみを行います。

## ファイル配置設計

### スターターキット側（ソース）

```text
prompts/
├── package/
│   └── .github/
│       └── ISSUE_TEMPLATE/
│           ├── backlog.yml     # バックログ用テンプレート
│           ├── bug.yml         # バグ報告用テンプレート
│           └── feature.yml     # 機能要望用テンプレート
└── setup-prompt.md             # コピー処理追加対象
```

### プロジェクト側（デスティネーション）

```text
.github/
└── ISSUE_TEMPLATE/
    ├── backlog.yml
    ├── bug.yml
    └── feature.yml
```

## テンプレートファイル設計

### 形式: Issue Forms（YAML）

GitHubのIssue Forms機能を使用し、構造化されたフォームで入力を受け付ける。
必須項目のバリデーションが可能。

### 共通構造

```yaml
name: "[表示名（和英併記）]"
description: "[説明（和英併記）]"
title: "[PREFIX] "
labels: ["ラベル名"]
body:
  - type: textarea / input / dropdown / checkboxes / markdown
    id: フィールドID
    attributes:
      label: "ラベル（和英併記）"
      description: "説明（和英併記）"
      placeholder: "プレースホルダー"
    validations:
      required: true / false
```

### backlog.yml

- **name**: "Backlog / バックログ"
- **description**: "Record a task or idea for future implementation / 将来対応が必要な気づきや課題を記録"
- **title**: "[Backlog] "
- **labels**: ["backlog"]
- **フォームフィールド**:

| フィールド | type | required | 説明 |
|-----------|------|----------|------|
| summary | textarea | true | 概要 / Summary |
| details | textarea | false | 詳細 / Details |
| cycle | input | false | 発見サイクル / Discovery Cycle |
| phase | dropdown | false | 発見フェーズ / Discovery Phase (Inception/Construction/Operations/N/A) |
| priority | dropdown | true | 優先度 / Priority (High/Medium/Low) |
| solution | textarea | false | 対応案 / Proposed Solution |

### bug.yml

- **name**: "Bug Report / バグ報告"
- **description**: "Report a bug or unexpected behavior / バグや問題を報告"
- **title**: "[Bug] "
- **labels**: ["bug"]
- **フォームフィールド**:

| フィールド | type | required | 説明 |
|-----------|------|----------|------|
| summary | textarea | true | バグの概要 / Bug Summary |
| steps | textarea | true | 再現手順 / Steps to Reproduce |
| expected | textarea | true | 期待される動作 / Expected Behavior |
| actual | textarea | true | 実際の動作 / Actual Behavior |
| environment | textarea | false | 環境情報 / Environment |

### feature.yml

- **name**: "Feature Request / 機能要望"
- **description**: "Suggest a new feature or enhancement / 新機能や改善の要望"
- **title**: "[Feature] "
- **labels**: ["enhancement"]
- **フォームフィールド**:

| フィールド | type | required | 説明 |
|-----------|------|----------|------|
| summary | textarea | true | 機能の概要 / Feature Summary |
| motivation | textarea | true | 背景・動機 / Motivation |
| solution | textarea | true | 提案内容 / Proposed Solution |
| alternatives | textarea | false | 代替案 / Alternatives |

## セットアッププロンプト修正設計

### 追加位置

`prompts/setup-prompt.md` の「8. 共通ファイルの配置」セクションに、「8.2.4」の後、「8.3」の前に新しいサブセクションを追加。

### 追加セクション名

`8.2.5 GitHub Issueテンプレートのコピー`

### スターターキットパスの解決

セットアッププロンプトでは、スターターキットのパスは変数として事前に解決されている前提。
既存の処理（8.2.1〜8.2.4）で使用している `[スターターキットパス]` と同じ方式を踏襲。

```bash
# 既存のrsync処理と同様に、スターターキットパスを使用
# 例: ${STARTER_KIT_PATH} または直接パス指定
```

### 処理フロー

```text
1. プロジェクトの .github/ISSUE_TEMPLATE/ 状態確認
2. 状態に応じた処理分岐
   a. ディレクトリが存在しない → 新規作成
   b. 同名ファイルが存在 → ユーザー確認（上書き/スキップ/個別）
   c. 同名ファイルが存在しない → コピー
3. 結果報告
```

### 状態確認コマンド

```bash
# .github/ISSUE_TEMPLATE/ の存在と内容確認
if [ -d ".github/ISSUE_TEMPLATE" ]; then
    ls .github/ISSUE_TEMPLATE/
    echo "ISSUE_TEMPLATE_EXISTS"
else
    echo "ISSUE_TEMPLATE_NOT_EXISTS"
fi
```

### コピー処理設計

#### ケース1: ディレクトリが存在しない

```bash
mkdir -p .github/ISSUE_TEMPLATE
cp [スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/*.yml .github/ISSUE_TEMPLATE/
```

**ユーザー確認不要**: 新規作成なので自動実行。

#### ケース2: 同名ファイルが存在する場合

**まず競合ファイルを特定**:
```bash
CONFLICT_FILES=""
for file in backlog.yml bug.yml feature.yml; do
    if [ -f ".github/ISSUE_TEMPLATE/$file" ]; then
        CONFLICT_FILES="${CONFLICT_FILES}${file} "
    fi
done
```

**ユーザー確認メッセージ**:
```text
警告: 以下のIssueテンプレートが既に存在します：

[競合ファイル一覧]

選択してください:
1. 上書きする（すべて置き換え）
2. スキップする（既存を保持、新規のみ追加）
3. 個別に確認する

どれを選択しますか？
```

**選択1: 上書き**:
```bash
cp -f [スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/*.yml .github/ISSUE_TEMPLATE/
```

**選択2: スキップ**:
```bash
for file in backlog.yml bug.yml feature.yml; do
    if [ ! -f ".github/ISSUE_TEMPLATE/$file" ]; then
        cp "[スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/$file" ".github/ISSUE_TEMPLATE/"
    fi
done
```

**選択3: 個別確認**:

競合ファイルごとに以下を繰り返す:

```text
ファイル: [ファイル名]

[上書き / スキップ] を選択してください:
```

各ファイルの選択結果を記録し、選択に応じてコピーまたはスキップを実行。

#### ケース3: 同名ファイルが存在しない

```bash
# 存在しないファイルのみコピー
for file in backlog.yml bug.yml feature.yml; do
    if [ ! -f ".github/ISSUE_TEMPLATE/$file" ]; then
        cp "[スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/$file" ".github/ISSUE_TEMPLATE/"
    fi
done
```

**ユーザー確認不要**: 競合がないので自動実行。

### 結果報告

```text
GitHub Issueテンプレートの配置が完了しました：

| ファイル | 状態 |
|----------|------|
| backlog.yml | [新規作成 / スキップ / 上書き] |
| bug.yml | [新規作成 / スキップ / 上書き] |
| feature.yml | [新規作成 / スキップ / 上書き] |
```

## 非機能要件への対応

### 可用性

- **要件**: GitHub CLI非依存
- **対応**: テンプレートのコピーは標準シェルコマンド（cp, mkdir）のみ使用
- **補足**: Issue作成・連携機能はUnit 005で別途実装

## 技術選定

- **テンプレート形式**: Issue Forms（YAML）
- **コピー処理**: シェルスクリプト（bash）
- **依存**: なし（標準コマンドのみ）

## 実装上の注意事項

- ファイル拡張子は `.yml` を使用（`.yaml` も可だが統一のため `.yml`）
- YAMLの構文エラーに注意（GitHubでパースエラーになる）
- `labels` は配列形式で指定（例: `["backlog"]`）
- `assignees` は省略（リポジトリごとにユーザーが異なるため）
- Issue Formsは公開リポジトリでのみ動作（プライベートでは従来のMarkdownテンプレートとして扱われる）

## 不明点と質問

（なし - レビュー指摘を反映済み）
