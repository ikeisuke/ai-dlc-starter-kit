# 論理設計: Kiroエージェント許可設定セットアップ

## 概要

`setup_kiro_agent`関数を拡張し、ファイル状態に応じた許可設定のセットアップロジックを実装する。

**重要**: このドキュメントでは**コードは書かず**、コンポーネント構成とインターフェースの定義のみを行います。

## アーキテクチャパターン

既存の`setup_claude_permissions`関数と同様のパターンを採用:
- 状態判定 → 分岐処理 → マージ or 新規作成
- jq優先 / python3フォールバックのデュアルツール方式

## コンポーネント構成

### 1. テンプレートファイル更新: `prompts/package/kiro/agents/aidlc.json`

現在のテンプレート:
```json
{
  "name": "aidlc",
  "description": "...",
  "tools": ["@builtin"],
  "resources": [...]
}
```

追加するプロパティ:
- `allowedTools`: AI-DLCワークフローで使用するKiroツールの一覧
- `toolsSettings.execute_bash.allowedCommands`: bash実行の許可コマンドパターン（docs/aidlc/bin/*, git操作等）
- `toolsSettings.execute_bash.autoAllowReadonly`: true（読み取り専用操作の自動許可）

許可設定の内容は `aidlc-poc.json` を参考に、AI-DLCワークフローに必要な最小限のツール・コマンドを定義する。

### 2. `setup_kiro_agent` 関数の拡張

**現行のフロー**:
1. テンプレートファイル存在確認
2. `.kiro/agents/` ディレクトリ作成
3. ファイル不在 → symlink作成
4. symlink → リンク先確認・修復
5. 実ファイル → 警告（"exists as file, cannot replace"）

**拡張後のフロー**:
1. テンプレートファイル存在確認（変更なし）
2. `.kiro/agents/` ディレクトリ作成（変更なし）
3. ファイル不在 → symlink作成（変更なし）
4. symlink → リンク先確認・修復（変更なし。テンプレート自体に許可設定が含まれるため追加処理不要）
5. **実ファイル → JSON検証 → 有効ならマージ、無効なら警告**（変更）

### 3. 新規関数: `_generate_kiro_permissions_template`

テンプレートファイルから許可設定部分（allowedTools, toolsSettings, autoAllowReadonly）を抽出するJSON生成関数。

**出力**: 許可設定のJSONオブジェクト（stdout）— `{"allowedTools": [...], "toolsSettings": {"execute_bash": {"allowedCommands": [...], "autoAllowReadonly": true}}}`

### 4. 新規関数: `_merge_kiro_permissions_jq`

jqを使用したKiro許可設定マージ関数。

**入力**: 既存JSONファイルパス
**出力**: マージ済みJSON文字列（stdout）、新規追加数（stderr）
**戻り値**: 0=新規パターンあり, 1=全て既存, 2=エラー

**マージロジック**:
- `allowedTools`: set-difference（テンプレートにあって既存にないツールを追加）
- `toolsSettings.execute_bash.allowedCommands`: set-difference（テンプレートにあって既存にないコマンドを追加）
- `toolsSettings.execute_bash.autoAllowReadonly`: テンプレートの値で設定（未設定時のみ）
- `toolsSettings` の `execute_bash` 以外のキー: マージ対象外（既存を維持）
- その他のトップレベルプロパティ（name, description, tools, resources）: 既存を維持（マージ対象外）

### 5. 新規関数: `_merge_kiro_permissions_python`

python3を使用したKiro許可設定マージ関数（jq不在時のフォールバック）。
`_merge_kiro_permissions_jq`と同一のインターフェース・マージロジック。

### 6. `setup_kiro_agent` 実ファイル分岐の詳細

```
実ファイル検出
  ├─ JSON検証（_detect_json_state 既存関数を再利用）
  │   ├─ valid → マージ処理
  │   │   ├─ jq利用可能 → _merge_kiro_permissions_jq
  │   │   └─ python3利用可能 → _merge_kiro_permissions_python
  │   │   └─ どちらも不在 → 警告 + degraded
  │   ├─ invalid → 警告（"Invalid JSON, skipping permission merge"）
  │   └─ unknown → 警告（"jq/python3 not found"）
  └─ 結果出力
```

## インターフェース定義

### _generate_kiro_permissions_template

```
入力: なし（テンプレートファイルからcat）
出力(stdout): JSON文字列 {"allowedTools": [...], "toolsSettings": {...}, "autoAllowReadonly": true}
戻り値: 0=成功
```

### _merge_kiro_permissions_jq / _merge_kiro_permissions_python

```
入力: $1 = 既存JSONファイルパス
出力(stdout): マージ済みJSON文字列
出力(stderr): 新規追加数
戻り値: 0=新規パターンあり, 1=全て既存, 2=エラー
```

## 既存関数の再利用

| 既存関数 | 再利用方法 |
|---------|-----------|
| `_detect_json_state` | 実ファイルのJSON検証に使用 |
| `_write_atomic` | マージ結果の書き込みに使用 |

## 設計判断

1. **テンプレートに許可設定を直接含める**: テンプレートがSource of Truthとなり、symlink方式ではテンプレート更新で自動反映される
2. **Claude Codeと同様のマージ戦略**: set-differenceマージにより既存のユーザーカスタマイズを保護
3. **既存関数の再利用**: `_detect_json_state`と`_write_atomic`を再利用し、コードの一貫性を維持
4. **許可設定の抽出関数を分離**: `_generate_kiro_permissions_template`として分離し、テスト容易性を確保
