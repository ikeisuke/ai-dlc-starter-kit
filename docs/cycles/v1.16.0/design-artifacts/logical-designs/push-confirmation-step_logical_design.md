# 論理設計: PRマージ前のリモート同期確認ステップ追加

## 概要

Operations Phaseプロンプト（`prompts/package/prompts/operations.md`）にステップ 6.6.6 を挿入するための構造設計を行う。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存のOperations Phaseプロンプトのステップ構造パターンに準拠。6.6.5（コミット漏れ確認）と同様のフォーマットを使用する。

## コンポーネント構成

### 変更箇所一覧

```text
prompts/package/prompts/operations.md
├── サブステップ一覧（`#### 6.6.5` の直後の番号リスト）
│   └── 6.6.6 リモート同期確認 を追加
├── ステップ 6.6.5 本文（「空（変更なし）」行）
│   └── 「次のステップ（6.7 PRマージ）」→「次のステップ（6.6.6 リモート同期確認）」に更新
└── ステップ 6.6.6 本文（`#### 6.6.5` セクション末尾と `#### 6.7` の間に挿入）
    └── リモート同期確認の本文を追加
```

## 挿入するステップの構造設計

### ステップ見出し

```text
#### 6.6.6 リモート同期確認【必須】
```

### 本文構造（6.6.5のフォーマットに準拠）

1. **説明文**: ステップの目的を1文で記述
2. **確認コマンド**: 4段階
   - Step 0: リモート名解決（upstreamから動的取得、未設定時は `origin` フォールバック）
   - Step A: `git fetch {remote}`（リモート最新化）
   - Step B: リモート追跡ブランチ解決（`@{u}` 優先、フォールバック `{remote}/{branch}`）
   - Step C: `git log {remote_ref}..HEAD --oneline`（未push検出）
3. **結果に応じた対応**: コマンド失敗/空/非空で分岐
4. **エラーハンドリング**: fetch失敗時、リモート追跡ブランチ未検出時、git log失敗時

### 確認コマンド詳細

**Step 0: リモート名解決**

```bash
# upstreamのリモート名を取得（例: origin, upstream）
REMOTE=$(git config branch.$(git branch --show-current).remote 2>/dev/null)
if [ -z "$REMOTE" ]; then
  REMOTE="origin"
fi
```

- upstreamが設定されている場合: そのリモート名を使用（`@{u}` と一貫性を保つ）
- 未設定の場合: `origin` にフォールバック

**Step A: リモート最新化**

```bash
git fetch $REMOTE
```

- 失敗時: エラーメッセージ + マージ停止

**Step B: リモート追跡ブランチ解決**

```bash
# upstream tracking branchの確認
git rev-parse --abbrev-ref @{u} 2>/dev/null
```

- 成功時: `REMOTE_REF="$(git rev-parse --abbrev-ref @{u})"` を設定
- 失敗時: `$REMOTE/$(git branch --show-current)` にフォールバック
  - 存在確認: `git show-ref --verify refs/remotes/$REMOTE/$(git branch --show-current)` で判定
  - 存在する場合: `REMOTE_REF="$REMOTE/$(git branch --show-current)"` を設定
  - 存在しない場合: マージ停止 + 手動push確認を案内（`git log` コマンドは案内しない）

出力: `REMOTE_REF`（Step Cで使用）

**Step C: 未pushコミット検出**

```bash
git log $REMOTE_REF..HEAD --oneline
```

- コマンド失敗（終了コード非0）: エラーメッセージ + マージ停止

### 結果に応じた対応

- **コマンド失敗**: エラーメッセージ + マージ停止（remote_ref解決異常への安全策）
- **空（差分なし）**: 次のステップ（6.7 PRマージ）へ進む
- **非空（未pushコミットあり）**: 警告メッセージ + push実行を促す + マージ停止（再実行必須）

### 警告メッセージフォーマット（未pushコミットあり）

```text
【警告】リモートにpushされていないコミットがあります。

未pushコミット:
{git log の実行結果}

PRマージ前にpushしてください：
git push {remote} {branch}

push完了後、再度このステップを実行してください。
リモートとの同期が確認できるまでPRマージに進まないでください。
```

### fetch失敗時のエラーメッセージ

```text
【エラー】git fetch {remote} に失敗しました。

ネットワーク接続を確認し、以下を実行してください：
1. ネットワーク接続を確認
2. `git fetch {remote}` を手動で実行
3. 成功後、再度このステップを実行

リモートとの同期が確認できるまでPRマージに進まないでください。
```

### リモート追跡ブランチ未検出時のメッセージ

```text
【エラー】リモート追跡ブランチが特定できません。

upstream tracking branch (`@{u}`) が未設定で、
`{remote}/{branch}` も存在しません。

PRマージ前に以下を確認してください：
1. `git push -u {remote} {branch}` でリモートにpushする
2. push完了後、再度このステップを実行

リモートとの同期が確認できるまでPRマージに進まないでください。
```

### git log失敗時のエラーメッセージ

```text
【エラー】未pushコミットの確認に失敗しました。

コマンド `git log {remote_ref}..HEAD --oneline` がエラーを返しました。

リモート参照の状態を手動で確認し、問題を解決してから再度このステップを実行してください。
```

## サブステップ一覧の更新

### 変更前（`#### 6.6.5` 行の後のサブステップ一覧）

```text
8. 6.6 ドラフトPR Ready化
9. 6.6.5 コミット漏れ確認
10. 6.7 PRマージ
```

### 変更後

```text
8. 6.6 ドラフトPR Ready化
9. 6.6.5 コミット漏れ確認
10. 6.6.6 リモート同期確認
11. 6.7 PRマージ
```

## 6.6.5 本文の参照更新

### 変更前

```text
- **空（変更なし）**: 次のステップ（6.7 PRマージ）へ進む
```

### 変更後

```text
- **空（変更なし）**: 次のステップ（6.6.6 リモート同期確認）へ進む
```

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: `git fetch` + `git log` の実行時間（数秒以内）
- **対応策**: 標準のgitコマンドを使用。ネットワーク遅延の影響はfetchのみ

### セキュリティ
- **要件**: 該当なし
- **対応策**: 該当なし

## 実装上の注意事項

- 編集対象は `prompts/package/prompts/operations.md`（メタ開発ルール: `docs/aidlc/` は直接編集しない）
- 6.6.5のフォーマット（見出し、確認コマンド、結果分岐、注意事項）に準拠すること
- jj環境への配慮: 本ステップはgitコマンドを直接使用するが、既存の6.6.5も同様にgitコマンド直書きのためパターンに整合
- `gh:available` への依存なし: このステップはgitコマンドのみ使用するため、gh CLIの有無に関わらず常に実行する（6.6.5と同じパターン）
- リモート名は動的解決: `git config branch.{branch}.remote` でupstreamのリモート名を取得し、未設定時のみ `origin` フォールバック
