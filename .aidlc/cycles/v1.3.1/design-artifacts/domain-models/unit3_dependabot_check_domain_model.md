# ドメインモデル: Dependabot PR確認（軽量版）

## 概要

Inception Phase開始時にDependabot PRの有無を確認し、セキュリティ更新の見落としを防止するプロンプト手順を定義する。

**注意**: このUnitはプロンプト修正のみでコード実装がないため、軽量版ドメインモデル設計として手順のフローと責務を定義する。

## プロンプト構造の責務

### 追加する手順

**手順名**: ステップ2.5: Dependabot PR確認

**責務**:
- GitHub CLIを使用してDependabot PRの一覧を取得する
- PRが存在する場合、ユーザーに一覧を表示する
- 今回のサイクルで対応するかどうかをユーザーに確認する

**境界**:
- PRのマージやクローズは行わない（確認と通知のみ）
- Dependabot以外のPRは対象外
- GitHub CLIが利用できない場合はスキップ

## フロー定義

### 正常フロー

```
1. GitHub CLIの利用可否確認
   ↓（利用可能）
2. Dependabot PRの一覧取得
   コマンド: gh pr list --label "dependencies" --state open
   ↓（PR存在）
3. PR一覧をユーザーに表示
   ↓
4. 対応確認の質問
   「これらのDependabot PRを今回のサイクルで対応しますか？」
   ↓
5. ユーザー回答に応じた処理
   - はい → Unit追加またはバックログ記録を案内
   - いいえ → 次のステップへ進行
```

### 代替フロー

**GitHub CLI利用不可の場合**:
```
1. GitHub CLIの利用可否確認
   ↓（利用不可 or エラー）
2. スキップメッセージ表示
   「GitHub CLIが利用できないため、Dependabot PR確認をスキップします。」
   ↓
3. 次のステップへ進行
```

**PRが存在しない場合**:
```
1. GitHub CLIの利用可否確認
   ↓（利用可能）
2. Dependabot PRの一覧取得
   ↓（PR 0件）
3. 確認完了メッセージ
   「オープンなDependabot PRはありません。」
   ↓
4. 次のステップへ進行
```

## 挿入位置

**現在の構造**:
- ステップ1: サイクル存在確認
- ステップ2: 追加ルール確認
- ステップ3: バックログ確認
- ステップ4: 進捗管理ファイル確認
- ステップ5: 既存成果物の確認

**変更後の構造**:
- ステップ1: サイクル存在確認
- ステップ2: 追加ルール確認
- **ステップ2.5: Dependabot PR確認** ← 新規追加
- ステップ3: バックログ確認
- ステップ4: 進捗管理ファイル確認
- ステップ5: 既存成果物の確認

## 技術的考慮事項

### GitHub CLIコマンド

```bash
gh pr list --label "dependencies" --state open --json number,title,url,createdAt --jq '.[] | "- #\(.number): \(.title) (\(.createdAt[:10]))"'
```

**フォールバック（--jqが使えない場合）**:
```bash
gh pr list --label "dependencies" --state open
```

### エラーハンドリング

- `gh`コマンドが存在しない → スキップ
- 認証エラー → スキップ + 警告メッセージ
- ネットワークエラー → スキップ + 警告メッセージ

## ユビキタス言語

- **Dependabot PR**: GitHubのDependabotが自動生成した依存関係更新のプルリクエスト
- **dependencies ラベル**: Dependabot PRに自動付与されるGitHubラベル
- **GitHub CLI（gh）**: GitHubの公式コマンドラインツール

## 不明点と質問

なし（Unit定義で要件が明確）

---

作成日: 2025-12-12
