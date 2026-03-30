# ドメインモデル: setup_kiro_agent 実ファイルマージ対応

## 概要

setup_kiro_agent()に実ファイル（ユーザーカスタマイズ済み .kiro/agents/aidlc.json）のallowedCommands差分マージロジックを追加する。既存の setup_claude_permissions() と同等のパターン（状態検出 → マージ → 原子的書き込み）を適用するが、Kiro固有のJSON構造に適応する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

### setup_kiro_agent 関数（既存・改修）

- **責務**: .kiro/agents/aidlc.json のセットアップ（symlink管理 + 実ファイルマージ）
- **現在のフロー**:
  1. ファイル不在: symlink作成
  2. symlink: リンク先確認・修復
  3. 実ファイル: Warning出力のみ（**ここを改修**）
- **改善後のフロー（実ファイルの場合）**:
  1. `_detect_json_state()` でJSON状態を判定
  2. 状態に応じた処理（absent/invalid/unknown/valid）
  3. valid の場合: マージロジックを呼び出し

### _generate_kiro_template 関数（新規）

- **責務**: Kiroテンプレートの完全なJSONを取得して stdout に出力する
- **ソースオブトゥルース**: `$AIDLC_DIR/kiro/agents/aidlc.json`（symlink先と同一）を `cat` で読み込む。heredoc埋め込みは行わない
- **出力**: テンプレートファイルの完全なJSON文字列
- **副作用**: なし

### _merge_kiro_commands_jq 関数（新規）

- **責務**: jqを使用して既存ファイルとテンプレートのallowedCommandsを差分マージ
- **入力**: 既存ファイルパス
- **出力**: stdout=純粋なマージ済みJSON（メタデータを含まない）、stderr=`new_count skipped_count`（スペース区切り）
- **戻り値**: 0=新規追加あり、1=全パターン既存、2=エラー
- **スキーマ検証**: `.toolsSettings.shell.allowedCommands` が null/未定義の場合は空配列として補完。文字列・オブジェクト・数値・真偽値の場合は不正型として return 2（エラー）

### _merge_kiro_commands_python 関数（新規）

- **責務**: Python3フォールバック。_merge_kiro_commands_jqと同一ロジック
- **入出力**: _merge_kiro_commands_jqと同一

## ドメインサービス

### allowedCommands マージサービス

- **入力**: 既存allowedCommands配列、テンプレートallowedCommands配列
- **処理**:
  1. テンプレートから既存に含まれないパターンを候補として抽出（set-difference）
  2. 既存配列からワイルドカードパターン（末尾が `*`）を抽出
  3. 各候補について、既存ワイルドカードに包含されるかチェック
  4. 包含されない候補のみを追加対象とする
- **出力**: マージ済みJSON（stdout、メタデータなし）+ 件数情報（stderr）

### ワイルドカード包含チェック

Kiroのパターンは単純文字列（例: `git checkout *`）。Claude Codeの`Type(pattern:*)`形式とは異なる。

- **ワイルドカード検出**: 末尾が `*` のパターン
- **包含判定**: 候補パターンが既存ワイルドカードの `*` を除いたプレフィックスで始まるか
  - 例: 既存に `git checkout *` がある場合、候補 `git checkout -b` は包含される（`git checkout ` で始まる）
  - 例: 既存に `git *` がある場合、候補 `git checkout *` は包含される（`git ` で始まる）

### deniedCommands の扱い

- **マージ対象外**: deniedCommands はセキュリティポリシーとしてテンプレートのみで管理
- **理由**: ユーザーが意図的に deniedCommands を変更している場合、テンプレートで上書きすべきでない
- setup_claude_permissions() の ask マージに相当する機能は Kiro 側では不要（deniedCommands は追加マージのリスクが高い）

## JSON構造の差異

| 項目 | Claude Code (.claude/settings.json) | Kiro (.kiro/agents/aidlc.json) |
|------|--------------------------------------|--------------------------------|
| マージ対象パス | `.permissions.allow` | `.toolsSettings.shell.allowedCommands` |
| パターン形式 | `Type(pattern:*)` | `command *`（単純文字列） |
| ワイルドカード検出 | `endswith(":*)")` | `endswith("*")` |
| 包含判定 | Type一致 + パスprefix | 文字列prefix |
| 追加マージ対象 | allow + ask | allowedCommands のみ |

## 不変条件

1. symlink状態のファイルは従来通りsymlink管理を維持（マージロジックは実ファイルにのみ適用）
2. jq/python3 どちらも不在の場合は Warning 出力のみ（degraded）
3. 既存の allowedCommands は削除しない（追加のみ）
4. 原子的書き込みにより部分更新を防止（_write_atomic 再利用）
5. マージ対象は `toolsSettings.shell.allowedCommands` のみ（他のフィールドは保持）

## ユビキタス言語

- **実ファイル**: symlinkでなく実体のあるファイル（ユーザーがカスタマイズ済み）
- **テンプレートパターン**: AI-DLCが提供するデフォルトのallowedCommandsリスト
- **差分マージ**: テンプレートにあり既存ファイルにないパターンを追加する処理
- **ワイルドカード包含**: 既存のワイルドカードパターンが候補パターンをカバーしている状態
