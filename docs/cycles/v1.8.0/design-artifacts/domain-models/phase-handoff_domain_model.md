# ドメインモデル: フェーズ間連携

## 概要

セットアップフェーズで決定した情報をインセプションフェーズに引き継ぐための概念モデル。

## ユビキタス言語

| 用語 | 定義 |
|------|------|
| SetupContext | セットアップで決定した情報を保持するドキュメント |
| ConfirmedQuestion | セットアップ中にユーザーに確認した質問と回答のペア |
| PhaseHandoff | フェーズ間での情報引き継ぎプロセス |

## エンティティ

### SetupContext

セットアップで決定した全情報を集約するドキュメント。

**属性**:

| 属性名 | 型 | 説明 | 空値の扱い |
|--------|------|------|------------|
| cycleName | string | サイクル名（例: v1.8.0） | 必須（空不可） |
| targetIssues | string | 対応予定のIssue番号（カンマ区切り、例: `#1, #2`） | 「なし」または空文字 |
| scopeSummary | string | スコープの要約 | 「なし」または空文字 |
| confirmedQuestions | ConfirmedQuestion[] | 確認済み質問リスト | 空配列（セクション自体を省略可） |
| additionalNotes | string | インセプションへの引継ぎ事項 | 「なし」または空文字 |

**Markdown表現との対応**:

- `targetIssues`: Markdownでは `#1, #2, #3` のようなカンマ区切り文字列として記載
- 「なし」と記載された場合、または空の場合は「未設定」として扱う
- confirmedQuestions: Markdownでは `- **Q**: ... - **A**: ...` 形式のリストとして記載

**ライフサイクル**:

- 生成: セットアップ完了時（サイクルディレクトリ作成後）
- 参照: インセプション開始時
- 更新: なし（読み取り専用）

### ConfirmedQuestion

セットアップ中にユーザーに確認した質問と回答。

**属性**:

| 属性名 | 型 | 説明 |
|--------|------|------|
| question | string | 質問内容 |
| answer | string | ユーザーの回答 |

## 値オブジェクト

なし（このモデルはシンプルなため、値オブジェクトは不要）

## 集約

### SetupContext（集約ルート）

SetupContextが集約ルートとして、ConfirmedQuestionを管理する。

```text
SetupContext
├── cycleName (必須)
├── targetIssues (カンマ区切り文字列)
├── scopeSummary
├── confirmedQuestions[]
│   ├── question
│   └── answer
└── additionalNotes
```

## ドメインサービス

なし（ファイルI/Oは論理設計で扱う）

## ドメインルール

1. **SetupContext生成タイミング**: サイクルディレクトリ作成完了後、Gitコミット前に生成
2. **必須項目**: cycleName は必須、他は任意
3. **重複防止**: 既にSetupContextが存在する場合は上書きしない（冪等性）
4. **後方互換性**: SetupContextが存在しない場合でもインセプションは正常に動作する
