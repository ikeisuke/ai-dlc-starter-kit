---
name: install-kiro-agent
description: >
  KiroCLIエージェント設定ファイル（aidlc.json）をインストールするスキル。
  ~/.kiro/agents/ にエージェント設定を配置する。
  Use when the user says "install kiro agent", "kiroインストール", "kiroエージェント設定", "install-kiro-agent".
---

# KiroCLIエージェントインストーラー

KiroCLIエージェント設定ファイル（`aidlc.json`）を `~/.kiro/agents/` に配置します。

## 実行手順

### 1. パスの解決

スキルベースディレクトリを基準に、テンプレートとスクリプトの絶対パスを解決する。

1. **スクリプト絶対パス**: `<スキルベースディレクトリ>/bin/install-kiro-agent.sh`
2. **テンプレート絶対パス**: `<プロジェクトルート>/skills/aidlc/templates/kiro/agents/aidlc.json`

テンプレートの存在確認:

```bash
ls <テンプレート絶対パス>
```

テンプレートが見つからない場合:

```text
【エラー】テンプレートファイルが見つかりません。
AI-DLCスキルが正しくインストールされていることを確認してください。
```

### 2. インストール実行

```bash
<スクリプト絶対パス> --source <テンプレート絶対パス>
```

### 3. 結果に応じた対応

stdout の出力を確認し、以下の分岐で対応する。

#### `status:success`（exit 0）

```text
✓ KiroCLIエージェント設定をインストールしました。
  配置先: ~/.kiro/agents/aidlc.json
```

#### `status:warning`（exit 0）

```text
✓ KiroCLIエージェント設定を配置しました。
  配置先: ~/.kiro/agents/aidlc.json

⚠ KiroCLI が見つかりません。KiroCLI をインストール後に設定が認識されます。
```

#### `status:skipped`（exit 0）

```text
ℹ エージェント設定は既に最新です。変更はありません。
```

#### `reason:overwrite_required`（exit 1）

既存ファイルとの差分を表示し、ユーザーに確認する。

```bash
diff <テンプレート絶対パス> ~/.kiro/agents/aidlc.json
```

```text
既存のエージェント設定と差分があります（上記参照）。

上書きしますか？（バックアップが自動作成されます）
1. はい - 上書きする（推奨）
2. いいえ - 現在の設定を維持する
```

「はい」の場合: `--force` を付けて再実行

```bash
bin/install-kiro-agent.sh --source <テンプレート絶対パス> --force
```

#### `reason:source_missing`（exit 1）

```text
【エラー】テンプレートファイルが見つかりません: <パス>
AI-DLCスキルが正しくインストールされていることを確認してください。
```

#### exit 2（システムエラー）

手動コピーコマンドを案内する。

```text
【エラー】自動配置に失敗しました。

以下のコマンドで手動配置してください:

  mkdir -p ~/.kiro/agents
  cp <テンプレート絶対パス> ~/.kiro/agents/aidlc.json
```

## パス解決

- `bin/` で始まるパスはスキルのベースディレクトリ（このSKILL.mdと同じディレクトリ）からの相対パスとして解決する
- Bashコマンドで `bin/` 配下のスクリプトを実行する場合は、解決した絶対パスを使用すること
