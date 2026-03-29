# 論理設計: KiroCLIインストーラー

## 概要

KiroCLIエージェント設定ファイルをユーザー環境に配置するインストーラースキルのインターフェース設計。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

2層分離パターン（オーケストレーション層 + 実行層）。既存スキル（squash-unit等）と同じ構造。

## コンポーネント構成

```text
skills/install-kiro-agent/
├── SKILL.md                      # オーケストレーション層（対話制御）
└── bin/
    └── install-kiro-agent.sh     # 実行層（副作用処理）
```

### コンポーネント詳細

#### SKILL.md（オーケストレーション層）

- **責務**: スキルメタ情報、対話制御（上書き確認）、エラー時の手動コマンド案内
- **依存**: install-kiro-agent.sh、skills/aidlc/templates/kiro/agents/aidlc.json
- **公開インターフェース**: スキル呼び出し（引数なし）

#### install-kiro-agent.sh（実行層）

- **責務**: ファイル配置の副作用処理のみ。対話制御を行わない
- **依存**: cp, diff, mkdir, which（標準コマンドのみ）
- **公開インターフェース**: CLI引数による制御

## スクリプトインターフェース設計

### install-kiro-agent.sh

#### 概要

テンプレートファイルを指定ディレクトリにコピーし、結果をstdoutに出力する。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--source` | 必須 | テンプレートファイルのパス |
| `--target-dir` | 任意 | 配置先ディレクトリ（デフォルト: `~/.kiro/agents`） |
| `--force` | 任意 | 既存ファイルを強制上書き（バックアップ作成後） |

#### 成功時出力

```text
status:success
```

または（kiro未導入時）:

```text
status:warning
message:kiro CLI not found. File installed but not verified.
```

または（同一内容でno-op時）:

```text
status:skipped
message:File already up to date.
```

- 終了コード: `0`
- 出力先: stdout

#### エラー時出力

```text
reason:{reason_code}
```

- 終了コード: `1`（バリデーションエラー）+ reason コード:
  - `reason:source_missing` — テンプレート不存在
  - `reason:overwrite_required` — 既存ファイルあり（差分あり、force=false）
  - `reason:invalid_argument` — 引数不正
- 終了コード: `2`（システムエラー）+ reason コード:
  - `reason:mkdir_failed` — ディレクトリ作成失敗
  - `reason:copy_failed` — ファイルコピー失敗（権限不足等）
- reason は stdout に出力（SKILL.md が機械判定に使用）
- 人間向けエラー説明は stderr に出力

#### 処理フロー

1. 引数パース・バリデーション
2. `--source` ファイル存在確認 → 不在: exit 1
3. `--target-dir` 存在確認 → 不在: `mkdir -p` で作成 → 失敗: exit 2
4. 配置先ファイル存在確認
   - 不在: ステップ5へ
   - 存在: `diff -q` で比較
     - 同一: `status:skipped` → exit 0
     - 差分あり + `--force`なし: stderr にメッセージ → exit 1
     - 差分あり + `--force`: `.bak.$(date +%Y%m%d%H%M%S)` 形式で一意バックアップ作成 → ステップ5へ
5. `cp` でコピー → 失敗: exit 2
6. `command -v kiro` で確認 → 成功: `status:success` / 失敗: `status:warning`

## SKILL.md フロー設計

1. テンプレートパスの解決（スキルベースディレクトリからの相対パス → 絶対パス）
2. `install-kiro-agent.sh --source <path>` を実行
3. 結果分岐:
   - `status:success` → 成功メッセージ表示
   - `status:warning` → 成功 + kiro未導入の案内表示
   - `status:skipped` → 「既に最新です」表示
   - exit 1（上書き拒否）→ 差分表示 → ユーザーに上書き確認 → 「はい」なら `--force` で再実行
   - exit 2 → 手動コピーコマンドを表示

### 手動コピーコマンド案内（exit 2時）

```text
自動配置に失敗しました。以下のコマンドで手動配置してください:

mkdir -p ~/.kiro/agents
cp <source_path> ~/.kiro/agents/aidlc.json
```

## 非機能要件（NFR）への対応

### セキュリティ

- 既存設定を壊さない: 上書き前にバックアップ作成（`.bak`）
- 権限不足時は中断し手動コマンドを案内

## 技術選定

- **言語**: Bash（POSIX互換シェルスクリプト）
- **依存コマンド**: cp, diff, mkdir, command（全てPOSIX標準）。`kiro` は任意の追加確認用（verify失敗はwarningでありインストール成功を覆さない）

## 実装上の注意事項

- `~/.kiro/agents/` はホームディレクトリ展開が必要（`$HOME` を使用）
- サンドボックス環境ではホームディレクトリへの書き込みが制限される可能性がある
- テンプレートパスはSKILL.md側で絶対パスに解決してからスクリプトに渡す
