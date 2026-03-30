# セッション管理ガイド

## 反復レビューの原則

反復レビュー時は**必ずセッション継続**を使用する。

| 場面 | セッション継続 | 理由 |
|------|----------------|------|
| 反復レビュー（2回目以降） | 必須 | 前回の指摘内容を踏まえた継続レビューが必要 |
| 指摘への追加質問 | 必須 | 指摘の文脈を保持したまま深掘りできる |
| 修正後の再レビュー | 必須 | 修正箇所と元の指摘の関連を理解できる |
| 別のUnitや独立したレビュー対象 | 不要 | 新しいコンテキストで開始すべき |

## Codex

### 基本コマンド

```bash
codex exec -s read-only -C <project_directory> "<レビュー指示>"
```

### セッション継続

```bash
codex exec resume <session-id> "<追加指示>"
```

- セッションIDは前回の実行結果の末尾に表示される（例: `session id: xxx`）
- resumeを使用すると、前回のセッション設定（`-C`、`-s`等）が継承される

### パラメータ

| パラメータ | 説明 |
|-----------|------|
| `-s read-only` | 読み取り専用サンドボックス（レビュー用） |
| `-C <dir>` | 対象プロジェクトのディレクトリ |
| `"<request>"` | レビュー指示（日本語可） |

### 反復レビューの流れ

```text
[1回目] codex exec -s read-only -C . "コードをレビューしてください"
        → 指摘あり、session id: abc123

[修正を実施]

[2回目] codex exec resume abc123 "指摘を修正しました。再度レビューしてください"
        → 追加指摘あり

[修正を実施]

[3回目] codex exec resume abc123 "追加の修正を行いました。確認してください"
        → 指摘なし、レビュー完了
```

## Claude Code

### 基本コマンド

```bash
claude -p --output-format stream-json "<レビュー指示>"
```

`stream-json` を使用することで、長いレビューでも途中イベントが出力され、無応答に見える状態を避けられる。

### セッション継続

```bash
claude --session-id <uuid> -p --output-format stream-json "<追加指示>"
```

意図しないセッションの混同を防ぐため、`-c` (continue) ではなく `--session-id` を使用する。

### パラメータ

| パラメータ | 説明 |
|-----------|------|
| `-p` / `--print` | 非対話モードで実行し結果を表示 |
| `--output-format stream-json` | JSON Lines形式でストリーミング出力（推奨） |
| `--session-id <uuid>` | 特定のセッションIDを指定して再開 |
| `"<request>"` | レビュー指示（日本語可） |

### 反復レビューの流れ

```text
[1回目] claude -p --output-format stream-json "コードをレビューしてください"
        → 指摘あり、session id確認

[修正を実施]

[2回目] claude --session-id <uuid> -p --output-format stream-json "指摘を修正しました。再度レビューしてください"
        → 追加指摘あり

[修正を実施]

[3回目] claude --session-id <uuid> -p --output-format stream-json "追加の修正を行いました。確認してください"
        → 指摘なし、レビュー完了
```

### 既知の制限事項

- **レスポンス未返却**: `--output-format stream-json` なしで大きなファイルをレビューすると、処理完了まで一切の出力がなく無反応に見えることがある。必ず `--output-format stream-json` を使用すること
- **指摘の非決定性**: 反復レビュー時に修正箇所と無関係な「言い回しの改善」指摘が毎回変わることがある。構造的な問題や論理的な誤りなど重要度の高い指摘を優先的に対応する

## Gemini

### 基本コマンド

```bash
gemini -p "<レビュー指示>" --sandbox
```

### セッション継続

```bash
gemini --resume <session_index> -p "<追加指示>"
```

セッション番号は一覧で確認:

```bash
gemini --list-sessions
```

### パラメータ

| パラメータ | 説明 |
|-----------|------|
| `-p "<request>"` | レビュー指示（日本語可） |
| `--sandbox` | サンドボックスモード（レビュー用） |
| `-r, --resume` | セッションの再開（インデックス番号） |
| `--list-sessions` | 利用可能なセッション一覧を表示 |

### 反復レビューの流れ

```text
[1回目] gemini -p "コードをレビューしてください" --sandbox
        → 指摘あり

[セッション一覧確認]
gemini --list-sessions

[修正を実施]

[2回目] gemini --resume <番号> -p "指摘を修正しました。再度レビューしてください"
        → 追加指摘あり

[修正を実施]

[3回目] gemini --resume <番号> -p "追加の修正を行いました。確認してください"
        → 指摘なし、レビュー完了
```
