# 論理設計: setup_kiro_agent 実ファイルマージ対応

## 概要

setup_kiro_agent()の実ファイル検出時にallowedCommandsの差分マージを行う。setup_claude_permissions()のアーキテクチャパターンを踏襲し、Kiro固有のJSON構造に適応する。

**重要**: このドキュメントでは設計のみ記述し、実装コードは書かない。

## コンポーネント構成

### 変更対象

- **ファイル**: `prompts/package/bin/setup-ai-tools.sh`
- **関数**:
  - `setup_kiro_agent()` — 既存関数の改修（実ファイル時のマージロジック追加）
  - `_generate_kiro_template()` — **新規関数**（Kiroテンプレート生成）
  - `_apply_kiro_merge()` — **新規関数**（マージ結果処理共通化）
  - `_merge_kiro_commands_jq()` — **新規関数**（jqベースマージ）
  - `_merge_kiro_commands_python()` — **新規関数**（Python3フォールバック）

### 再利用する既存関数

- `_detect_json_state()` — JSON状態判定
- `_write_atomic()` — 原子的書き込み

### 変更しないもの

- symlink管理ロジック（ファイル不在時・symlink時の処理）
- setup_claude_permissions() および関連関数
- .kiro/agents/aidlc.json 以外のファイル操作

## _generate_kiro_template() 設計

### 責務

Kiroテンプレートの完全なJSON構造を stdout に出力する。

### ソースオブトゥルース

`$AIDLC_DIR/kiro/agents/aidlc.json` を `cat` で読み込んで出力する。heredoc埋め込みは行わない。これはsymlink管理で使用するテンプレートファイルと同一であり、定義の二重管理を防止する。

**注意**: マージ時に `toolsSettings.shell.allowedCommands` のみを差分対象とし、他のフィールドは既存ファイルの値を保持する。

## _merge_kiro_commands_jq() 設計

### インターフェース

- **引数**: `$1` — 既存ファイルパス
- **出力**: stdout=純粋なマージ済みJSON（メタデータなし）、stderr=`new_count skipped_count`（スペース区切り）
- **戻り値**: 0=新規追加あり、1=全パターン既存、2=エラー（スキーマ不正含む）
- **前提**: jq が利用可能
- **スキーマ検証**: `.toolsSettings.shell.allowedCommands` が配列でない場合は return 2

### 内部フロー

```text
_merge_kiro_commands_jq(existing_file)
│
├─ _generate_kiro_template() → テンプレートJSON取得
├─ テンプレートから .toolsSettings.shell.allowedCommands を抽出
│
├─ スキーマ検証:
│  ├─ .toolsSettings.shell.allowedCommands の型チェック
│  ├─ null または未定義 → 空配列として補完（正常続行）
│  └─ 文字列・オブジェクト・数値・真偽値 → 不正型として return 2
│
├─ jq で既存ファイルを処理:
│  ├─ .toolsSettings.shell.allowedCommands // [] → $existing
│  ├─ ($defaults - $existing) → $new_candidates（set-difference）
│  │
│  ├─ ワイルドカード抽出: $existing から末尾が "*" のパターン
│  │
│  ├─ 包含チェック:
│  │  ├─ 各 $candidate について:
│  │  │  ├─ $candidate 自体が "*" で終わる → 通常の候補として扱う（ワイルドカード同士の包含もチェック）
│  │  │  └─ $wildcards のいずれかのプレフィックス（"*" を除いた部分）で $candidate が始まるか
│  │  │     ├─ はい → 包含される（スキップ）
│  │  │     └─ いいえ → 追加対象
│  │  └─ → $new（追加対象リスト）
│  │
│  ├─ $skipped = len($new_candidates) - len($new)
│  └─ $existing に $new を追加（JSONにメタデータは付加しない）
│
├─ stderr に "new_count skipped_count" を出力（スペース区切り）
└─ return: 0 (追加あり) / 1 (追加なし) / 2 (エラー)
```

### ワイルドカード包含チェックの詳細

Claude Code版との差異:

| 項目 | Claude Code (_merge_permissions_jq) | Kiro (_merge_kiro_commands_jq) |
|------|--------------------------------------|-------------------------------|
| パターン形式 | `Type(path:*)` | `command *` |
| ワイルドカード判定 | `endswith(":*)")` | `endswith("*")` |
| プレフィックス抽出 | Type分離 + `rtrimstr(":*)")` | `rtrimstr("*")` |
| 包含判定 | Type一致 AND パスprefix一致 | 文字列prefix一致 |

**具体例**:
- 既存: `["git checkout *", "ls *"]`
- テンプレート候補: `["git checkout -b", "git checkout *", "ls -la", "cat *"]`
- set-difference 後: `["git checkout -b", "cat *"]`（`git checkout *` と `ls -la`（`ls *`包含ではない） は除外/チェック対象）

**修正**: set-difference は完全一致で除外するため:
- `git checkout *` は既存に完全一致 → 除外
- `ls -la` は既存に完全一致なし → 候補
- `git checkout -b` は既存に完全一致なし → 候補
- `cat *` は既存に完全一致なし → 候補
- 包含チェック: `git checkout -b` は `git checkout *` に包含（`git checkout ` で始まる） → スキップ
- 包含チェック: `ls -la` は `ls *` に包含（`ls ` で始まる） → スキップ
- 包含チェック: `cat *` は既存ワイルドカードに包含されない → 追加
- 結果: `["cat *"]` が追加、stderr に `1 2` を出力（new=1, skipped=2）

## _merge_kiro_commands_python() 設計

_merge_kiro_commands_jq() と同一ロジックをPython3で実装。

### ワイルドカード包含チェック

```text
def is_covered_by_wildcard(candidate, wildcards):
    for wc in wildcards:
        if not wc.endswith("*"):
            continue
        prefix = wc[:-1]  # "*" を除去
        if candidate.startswith(prefix):
            return True
    return False
```

## setup_kiro_agent() フロー設計（改修版）

```text
setup_kiro_agent()
│
├─ テンプレートファイル存在確認（既存）
├─ .kiro/agents ディレクトリ作成（既存）
│
├─ ファイル不在 → symlink作成（既存、変更なし）
├─ symlink → リンク先確認・修復（既存、変更なし）
│
└─ 実ファイル（else節を改修）
   ├─ _detect_json_state() → state
   │  ※ ファイルは存在するため absent にはならない
   │
   ├─ invalid: バックアップ → _generate_kiro_template | _write_atomic → 再作成
   ├─ unknown: Warning出力（jq/python3不在）
   │
   └─ valid: _apply_kiro_merge() を呼び出し
      └─ 最後の行が result 種別、それ以前がメッセージ出力

_apply_kiro_merge(target_file)
├─ jq利用可能? → _merge_kiro_commands_jq()
├─ python3利用可能? → _merge_kiro_commands_python()
├─ いずれも不在 → "degraded" を返す
│
└─ マージ結果処理:
   ├─ rc=0: _write_atomic → Updated メッセージ → "updated"
   ├─ rc=1: Skipped メッセージ → "skipped"
   └─ rc=2: Warning メッセージ → "failed"
```

### 結果契約

setup_claude_permissions() と同一の契約を踏襲する:

- **結果種別**: `created` | `updated` | `skipped` | `degraded` | `failed`
- **出力**: 全経路で `echo "result:<result>"` を出力（symlink分岐含む）
- **戻り値**: `created|updated|skipped|degraded` → return 0、`failed` → return 1

| 状態/処理結果 | result | 戻り値 |
|-------------|--------|-------|
| ファイル不在 → symlink作成 | created | 0 |
| symlink → リンク先正常 | skipped | 0 |
| symlink → リンク先修復 | updated | 0 |
| 実ファイル: invalid → バックアップ+再作成成功 | created | 0 |
| 実ファイル: valid → マージで新規追加あり | updated | 0 |
| 実ファイル: valid → 全パターン既存 | skipped | 0 |
| 実ファイル: valid → マージエラー（rc=2） | failed | 1 |
| 実ファイル: unknown（jq/python3不在） | degraded | 0 |
| 書き込み失敗 | failed | 1 |

### 実ファイル判定の注意

現在の `else` 節に入る条件:
- `[ ! -e "$AGENT_PATH" ]` が false（ファイルが存在）
- `[ -L "$AGENT_PATH" ]` が false（symlinkでない）
→ 実体のある通常ファイル

この条件下で `_detect_json_state()` を呼ぶと:
- ファイルは存在するため `absent` にはならない
- `valid` / `invalid` / `unknown` のいずれかになる

到達不能な `absent` ブランチは実装しない（到達不能コードの排除）。

## テスト戦略

### テスト対象シナリオ

1. **新規追加あり**: テンプレートに既存ファイルにないコマンドがある場合
2. **全パターン既存**: テンプレートのコマンドがすべて既存ファイルに含まれる場合
3. **ワイルドカード包含**: 既存の `git *` が テンプレートの `git checkout *` をカバーする場合
4. **空のallowedCommands**: 既存ファイルに allowedCommands がない場合（null/未定義 → 空配列補完）
5. **スキーマ不正**: allowedCommands がオブジェクト等の不正型の場合（return 2）
6. **_generate_kiro_template単体**: テンプレートが有効なJSONを生成するか

### テスト実装方法

- 一時ディレクトリでテスト用JSONファイルを作成
- _merge_kiro_commands_jq / _merge_kiro_commands_python を個別にテスト
- setup_kiro_agent() の統合テストはファイルシステム操作を含む
