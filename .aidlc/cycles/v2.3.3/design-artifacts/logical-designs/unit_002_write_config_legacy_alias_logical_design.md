# 論理設計: write-config.shレガシーエイリアス対応

## 概要
write-config.shにkey-aliases.shを導入し、レガシーキー重複書き込み防止ロジックを実装する論理設計。

## アーキテクチャパターン
パイプライン処理パターン: 入力キー → 正規化 → 書き込み先解決 → 書き込み実行。read-config.shの既存パターン（resolve_with_aliases）に倣い、書き込み側も同じkey-aliases.shに依存する一方向依存構造。

## コンポーネント構成

### モジュール構成

```text
scripts/
├── write-config.sh          ← 修正対象
│   ├── resolve_write_target()  ← 新規関数
│   ├── key_exists_in_section() ← 新規関数
│   └── update_existing_key()   ← 既存関数（section引数追加）
└── lib/
    ├── key-aliases.sh        ← 既存（source追加）
    └── bootstrap.sh          ← 既存（変更なし）
```

### コンポーネント詳細

#### key_exists_in_section()
- **責務**: TOMLファイル内の特定セクション配下にleafキーが存在するかを判定
- **依存**: なし（純粋な文字列検索）
- **公開インターフェース**: `key_exists_in_section(file, section, leaf) → 0(存在) / 1(不在)`

#### resolve_write_target()
- **責務**: 入力キーとファイル状態から書き込み先（section, leaf, action）を決定
- **依存**: key-aliases.sh（`aidlc_normalize_key`, `aidlc_get_legacy_key`）、`key_exists_in_section()`
- **公開インターフェース**: `resolve_write_target(input_key, file)` → stdout にタブ区切り `section\tleaf\taction` を出力。戻り値 0=成功

## スクリプトインターフェース設計

### write-config.sh（既存インターフェース、変更なし）

#### 概要
設定値をTOMLファイルに書き込む。

#### 引数
| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `key` | 必須 | ドット区切りの設定キー |
| `value` | 必須 | 設定値 |
| `--scope` | 任意 | 書き込み先スコープ（デフォルト: `local`） |
| `--dry-run` | 任意 | 書き込みせず対象情報を表示 |

#### 成功時出力
```text
config:written:{file}:{input_key}={value}
```
- 終了コード: `0`
- 出力キーは入力キーをそのまま使用（canonical変換しない。後方互換性を維持）

#### dry-run時出力
```text
config:dry-run:{file}:{input_key}={value}:action={action}
```
- `action`: `update` / `update_legacy` / `create`
- 終了コード: `0`
- 出力キーは入力キーをそのまま使用

#### エラー時出力
```text
config:error:{error_type}:{message}
```
- 終了コード: `1`（書き込み失敗）、`2`（引数エラー）

### 内部関数: key_exists_in_section()

#### 概要
TOMLファイル内のセクション範囲を特定し、その中にリーフキーが存在するか判定する。

#### 引数
| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `$1` (file) | 必須 | TOMLファイルパス |
| `$2` (section) | 必須 | セクションキー（例: `rules.git`） |
| `$3` (leaf) | 必須 | リーフキー（例: `branch_mode`） |

#### 戻り値
- `0`: セクション内にリーフが存在
- `1`: 存在しない

#### 実装方針
1. ファイル内で `[{section}]` ヘッダーの行番号を特定
2. 次のセクションヘッダー（`[...]`）の行番号を特定（末尾ならファイル終端）
3. その範囲内で `^{leaf} *= *` にマッチする行を検索

### 内部関数: resolve_write_target()

#### 概要
入力キーを正規化し、ファイル内の既存キー状態に基づき書き込み先を決定する。

#### 引数
| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `$1` (input_key) | 必須 | ユーザー入力のキー |
| `$2` (file) | 必須 | TOMLファイルパス |

#### 出力（stdout、タブ区切り）
```text
{section}\t{leaf}\t{action}
```
- `action`: `update` / `update_legacy` / `create`
- 呼び出し側で `read -r section leaf action` で受け取る

#### 戻り値
- `0`: 成功（stdoutに結果を出力���

#### 決定ロジック
```text
1. canonical_key = aidlc_normalize_key(input_key)
2. legacy_key = aidlc_get_legacy_key(canonical_key)
3. canonical_section = canonical_key の section 部分
4. canonical_leaf = canonical_key の leaf 部分
5. if key_exists_in_section(file, canonical_section, canonical_leaf):
     → printf '%s\t%s\t%s\n' canonical_section canonical_leaf "update"
6. elif legacy_key is not empty:
     legacy_section = legacy_key の section 部分
     legacy_leaf = legacy_key の leaf 部分
     if key_exists_in_section(file, legacy_section, legacy_leaf):
       → printf '%s\t%s\t%s\n' legacy_section legacy_leaf "update_legacy"
     else:
       → printf '%s\t%s\t%s\n' canonical_section canonical_leaf "create"
7. else:
     → printf '%s\t%s\t%s\n' canonical_section canonical_leaf "create"
```

**注**: ステップ6の内側elseで「alias対象キーだが両方不在」のケースを明示的にcreate（canonical）に振る。

## 処理フロー概要

### 書き込みフロー

1. 引数パース（既存、変更なし）
2. バリデーション（既存、変更なし）
3. ファイルパス決定（既存、変更なし）
4. **[新規] `resolve_write_target(KEY, TARGET_FILE)` を呼び出し → `read -r WRITE_SECTION WRITE_LEAF WRITE_ACTION`**
5. dry-run: 解決結果を出力して終了（出力キーは入力KEYのまま）
6. ファイル準備（既存、変更なし）
7. `WRITE_ACTION` に応じた書き込み:
   - `update` / `update_legacy`: `update_existing_key(file, WRITE_SECTION, WRITE_LEAF, value)`（section-aware更新）
   - `create` + セクション存在: セクション直後に追加
   - `create` + セクション不在: ファイル末尾にセクション+キー追加
8. 結果出力（出力キーは入力KEYのまま）

## 非機能要件（NFR）への対応

### 後方互換性
- 既存のwrite-config.shインターフェース（引数、終了コード、出力フォーマット）は変更しない
- エイリアス非対象のキーは従来と同一の動作を保証

### 一貫性
- read-config.shと同じkey-aliases.shを使用し、キー解決の一貫性を保つ
- read側: canonical優先でfallback読み取り / write側: ファイル内既存キーに合わせて書き込み

## 技術選定
- **言語**: Bash
- **依存ツール**: grep, sed（既存のwrite-config.shと同じ）
- **共有ライブラリ**: key-aliases.sh（既存）

## 実装上の注意事項
- `key_exists_in_section()` のセクション範囲特定で、ネストされたTOMLテーブル（`[rules.git]` 内に `[rules.git.sub]` がある場合）は現行config.tomlの構造では発生しないが、完全一致で検索する
- `update_existing_key()` をsection-awareに変更: `key_exists_in_section()` と同じセクション境界ロジックを使い、対象セクション範囲内でのみsed置換を行う。シグネチャは `update_existing_key(file, section, leaf, value)` に変更
- sed置換のリーフキー名に正規表現メタ文字が含まれる可能性は低い（キーバリデーション済み）が、必要に応じてエスケープ
- macOS/Linux互換のsed -i処理は既存の `update_existing_key()` パターンを踏襲
