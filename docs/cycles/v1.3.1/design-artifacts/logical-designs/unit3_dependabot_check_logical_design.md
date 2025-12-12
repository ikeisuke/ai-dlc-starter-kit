# 論理設計: Dependabot PR確認（軽量版）

## 概要

inception.mdにDependabot PR確認手順を追加するための論理設計。プロンプト修正のため、Markdownの構造と挿入位置を定義する。

**注意**: このUnitはプロンプト修正のみでコード実装がないため、軽量版論理設計としてMarkdown構造と手順フローを定義する。

## 変更対象ファイル

### ファイルパス
```
prompts/package/prompts/inception.md
```

### 変更箇所

**挿入位置**: 「### 2. 追加ルール確認」と「### 3. バックログ確認」の間

**現在の構造**（行269-271付近）:
```markdown
### 2. 追加ルール確認
`docs/cycles/rules.md` が存在すれば読み込む

### 3. バックログ確認
```

**変更後の構造**:
```markdown
### 2. 追加ルール確認
`docs/cycles/rules.md` が存在すれば読み込む

### 2.5. Dependabot PR確認

[新規追加する手順]

### 3. バックログ確認
```

## 追加するMarkdown構造

```markdown
### 2.5. Dependabot PR確認

GitHub CLIでDependabot PRの有無を確認：

```bash
# GitHub CLIの利用可否確認
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    gh pr list --label "dependencies" --state open
else
    echo "SKIP: GitHub CLI not available or not authenticated"
fi
```

**判定**:
- **SKIP（GitHub CLI利用不可）**: 次のステップへ進行
- **PRが0件**: 「オープンなDependabot PRはありません。」と表示し、次のステップへ進行
- **PRが1件以上**: 以下の対応確認を実施

**対応確認**（PRが存在する場合）:
```
以下のDependabot PRがあります：

[PR一覧表示]

これらのPRを今回のサイクルで対応しますか？
1. はい - Unit定義に追加する
2. いいえ - 今回は対応しない（後で個別に対応）
```

- **1を選択**: ユーザーストーリーとUnit定義に「Dependabot PR対応」を追加することを案内
- **2を選択**: 次のステップへ進行
```

## 処理フロー

### フローチャート

```
開始
  │
  ▼
GitHub CLI利用可否確認
(command -v gh && gh auth status)
  │
  ├─[利用不可]──▶ スキップメッセージ表示 ──▶ 次のステップへ
  │
  ▼[利用可能]
Dependabot PR一覧取得
(gh pr list --label "dependencies" --state open)
  │
  ├─[0件]──▶ 「PRなし」メッセージ表示 ──▶ 次のステップへ
  │
  ▼[1件以上]
PR一覧表示
  │
  ▼
対応確認の質問
  │
  ├─[はい]──▶ Unit追加案内 ──▶ 次のステップへ
  │
  ▼[いいえ]
次のステップへ
```

## 非機能要件への対応

### 可用性
- **要件**: GitHub CLIが利用できない場合はスキップ
- **対応策**:
  - `command -v gh` でコマンド存在確認
  - `gh auth status` で認証状態確認
  - エラー時はスキップして処理を継続

### エラーハンドリング

| エラーケース | 対応 |
|------------|------|
| ghコマンドが存在しない | スキップ |
| 認証されていない | スキップ + メッセージ |
| ネットワークエラー | スキップ + メッセージ |
| dependenciesラベルが存在しない | 空の結果（正常） |

## 技術選定

- **ツール**: GitHub CLI（gh）
- **シェル**: Bash
- **ドキュメント形式**: Markdown

## 実装上の注意事項

1. **プロンプト編集先**: `prompts/package/prompts/inception.md` を編集する（`docs/aidlc/prompts/inception.md` ではない）
2. **既存手順との整合性**: ステップ番号を「2.5」とし、既存の番号体系を崩さない
3. **エラーハンドリング**: GitHub CLI未設定の環境でもInception Phaseが正常に進行できるようにする

## 不明点と質問

なし（Unit定義で要件が明確）

---

作成日: 2025-12-12
