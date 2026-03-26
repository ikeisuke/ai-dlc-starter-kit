# Unit 004 計画: rsync同期スクリプト

## 概要

`prompts/package/` から `docs/aidlc/` への rsync 同期を1コマンドで実行する `sync-package.sh` を作成する。

## 設計方針

### 同期方式

既存の setup-prompt.md ではサブディレクトリ単位（prompts/, templates/, guides/, bin/, skills/, kiro/）で個別にrsyncしているが、本スクリプトではディレクトリ全体を一括同期する。

理由:
- スタンドアロンスクリプトとして呼び出す場面では、ユーザーは「全体同期」を意図している
- サブディレクトリ追加時にスクリプト修正不要（保守性向上）

### rsyncオプション

デフォルト（`--delete` なし）:
```bash
rsync -a --checksum --itemize-changes \
  --exclude '.DS_Store' \
  prompts/package/ docs/aidlc/
```

`--delete` 指定時:
```bash
rsync -a --checksum --itemize-changes --delete \
  --exclude '.DS_Store' \
  prompts/package/ docs/aidlc/
```

- `-a`: アーカイブモード（パーミッション・タイムスタンプ保持）
- `--checksum`: ハッシュ比較でスキップ（タイムスタンプ差異を無視）
- `--itemize-changes`: 変更内容を記号形式で出力（`key:value` 変換用）
- `--delete`: 宛先のみに存在するファイルを削除（明示指定時のみ付与）
- `--exclude '.DS_Store'`: macOS固有ファイル除外

注: `-v`（verbose）は使用しない。rsyncの生出力はstdoutに混入させず、`--itemize-changes` の出力をパースして `key:value` 形式に変換する。

### itemize-changes 分類ルール

rsyncの `--itemize-changes` は `YXcstpoguax` 形式の記号列を出力する。本スクリプトでは以下のルールで分類する:

| 記号パターン | 分類 | 出力キー |
|-------------|------|---------|
| `>f+++++++++` | 新規作成 | `sync_added:<path>` |
| `>f` で始まり `+++` でない | 更新 | `sync_updated:<path>` |
| `*deleting` | 削除 | `sync_deleted:<path>` |
| `cd` で始まる（ディレクトリ） | スキップ | 出力しない |

### 出力形式

運用状態を返すスクリプト群（update-version.sh, check-issue-templates.sh, suggest-version.sh）の `key:value` フォーマットに準拠。stdoutは状態行のみとし、rsyncの生出力は混入させない。

成功時:
```text
sync:success
source:prompts/package/
destination:docs/aidlc/
sync_added:<filename>       (0個以上)
sync_updated:<filename>     (0個以上)
sync_deleted:<filename>     (0個以上)
```

dry-runモード:
```text
sync:dry-run
source:prompts/package/
destination:docs/aidlc/
sync_added:<filename>       (0個以上)
sync_updated:<filename>     (0個以上)
sync_deleted:<filename>     (0個以上)
```

### エラーハンドリング

引数エラー:
```text
error:unknown-option:<option>
error:missing-source-value
error:missing-dest-value
```

実行時エラー:
```text
error:rsync-not-installed
error:source-not-found
error:destination-not-found
error:rsync-failed
```

### 引数

| オプション | 必須 | 説明 |
|-----------|------|------|
| `--source <path>` | 任意 | ソースディレクトリ（デフォルト: `prompts/package/`） |
| `--dest <path>` | 任意 | 宛先ディレクトリ（デフォルト: `docs/aidlc/`） |
| `--delete` | 任意 | 宛先のみに存在するファイルを削除（明示指定時のみ有効） |
| `--dry-run` | 任意 | 実際の同期を行わず、差分を表示 |

`--delete` はデフォルト無効とし、明示指定時のみ有効化する。これにより `--dest` でカスタム宛先を指定した場合の意図しないファイル削除を防止する。

### 終了コード

- `0`: 正常終了（同期成功またはdry-run）
- `1`: エラー

## ファイル構成

| ファイル | 操作 | 備考 |
|---------|------|------|
| `prompts/package/bin/sync-package.sh` | 新規作成 | 単一ソース（マスター） |
| `docs/aidlc/bin/sync-package.sh` | rsyncコピー | 生成物（同期処理で自動反映） |

`docs/aidlc/bin/` 側は `prompts/package/bin/` からの同期生成物であり、直接編集しない。このスクリプト自体が同期を担うため、初回は手動コピー（または本スクリプトの初回実行）で配置する。

## テスト計画

1. dry-runで差分確認（変更なし時）
2. dry-runで差分確認（変更あり時）
3. 実際の同期実行（--delete なし）
4. 実際の同期実行（--delete あり）
5. ソースディレクトリ不在時のエラー
6. rsync不在時のエラー
7. 不明オプション指定時のエラー
8. --source / --dest カスタム指定
