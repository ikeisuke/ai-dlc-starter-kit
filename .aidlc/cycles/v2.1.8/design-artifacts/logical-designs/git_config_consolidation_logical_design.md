# 論理設計: Git関連設定キーの統合

## 概要

`read-config.sh` にエイリアス解決レイヤーを追加し、Git関連設定キーの旧→新統合を実現する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存の4階層マージアーキテクチャに「キー正規化レイヤー」を前段に追加するアダプターパターン。

`resolve_key()` は「与えられたキーを4階層から引く」責務に固定し、上位に `resolve_with_aliases()` オーケストレータを配置して正規化・フォールバック順序を管理する。

## コンポーネント構成

### 変更対象コンポーネント

```text
scripts/
├── read-config.sh              # resolve_with_aliases() 追加
└── lib/
    └── key-aliases.sh          # 【新規】エイリアスマップ定義（正本）

config/
└── defaults.toml               # [rules.git] 統合、旧セクション除去

skills/aidlc-setup/
├── config/
│   └── defaults.toml           # 同期
├── scripts/
│   └── detect-missing-keys.sh  # エイリアス考慮の欠落判定
└── templates/
    └── config.toml.template    # 新キー構成

steps/
├── common/
│   ├── preflight.md            # バッチキーリスト更新
│   └── commit-flow.md          # キー参照更新
├── inception/
│   └── 01-setup.md             # キー参照更新
└── construction/
    └── 01-setup.md             # キー参照更新
```

### コンポーネント詳細

#### lib/key-aliases.sh（新規）— エイリアスマップの正本

- **責務**: ��イリアスマッピングの唯一の定義場所。`normalize_key()` と `get_legacy_key()` ���提供
- **依存**: なし
- **利用者**: `read-config.sh`, `detect-missing-keys.sh`
- **公開インターフェース**:
  - `aidlc_normalize_key(key)`: legacy key → canonical key に正規化。canonical key はそのまま返す（冪等）
  - `aidlc_get_legacy_key(canonical_key)`: canonical key → legacy key を返す。マップにない場合は空文字

#### read-config.sh — resolve_with_aliases() 追加

- **責務**: `resolve_with_aliases()` オーケストレータで正規化→解決→フォールバックを管理
- **依存**: lib/bootstrap.sh, lib/validate.sh, lib/toml-reader.sh, **lib/key-aliases.sh**（新規）
- **公開インターフェース**: 変更なし（既存の引数・戻り値・終了コードを維持）
- **内部変更**: メイン処理で `resolve_key()` の代わりに `resolve_with_aliases()` を呼び出し

#### detect-missing-keys.sh — エイリアス考慮

- **責務**: defaults.toml のリーフキーの欠落を検出。エイリアス存在時は「移行推奨」として区別
- **依存**: **lib/key-aliases.sh**（新規）
- **変更**: 欠落判定時に `aidlc_get_legacy_key()` で旧キーの存在も確認。旧キー��存在する場合は `missing` ではなく `migrate` として出力

#### defaults.toml（スキ��側 + aidlc-setup側）

- **責務**: 全設定キーのデフォルト値定義
- **変更**: `[rules.git]` に新キーを追加、旧セクション除去

## スクリプトインターフェース設計

### lib/key-aliases.sh（新規）

#### 概要
エイリアスマッピングの正本を定義する共有ライブラリ。

#### エイリアスマップ��case文で実装）

| legacy key | canonical key |
|-----------|---------------|
| `rules.branch.mode` | `rules.git.branch_mode` |
| `rules.unit_branch.enabled` | `rules.git.unit_branch_enabled` |
| `rules.squash.enabled` | `rules.git.squash_enabled` |
| `rules.commit.ai_author` | `rules.git.ai_author` |
| `rules.commit.ai_author_auto_detect` | `rules.git.ai_author_auto_detect` |

> **廃止**: `rules.worktree.enabled` は `rules.git.branch_mode = "worktree"` で代替されたため、エイリアスマップに含まない。

#### 実装方式

`case`文で実装（POSIX互換、Bash 4+ の `declare -A` は不使用）。

```text
aidlc_normalize_key(key):
  case key:
    legacy_key_1 → canonical_key_1
    legacy_key_2 → canonical_key_2
    ...
    * → key（そのまま返す）

aidlc_get_legacy_key(canonical_key):
  case canonical_key:
    canonical_key_1 → legacy_key_1
    canonical_key_2 → legacy_key_2
    ...
    * → ""（空文字）
```

### read-config.sh（変更箇所のみ）

#### resolve_with_aliases() オーケストレータ（新規）

- **引数**: key（文字列）
- **戻り値**: 解決された値（strip_quotes適用済み、stdout出力）
- **終了コード**: 0=存在, 1=不在, 2=エラー
- **責務**: 正規化 → canonical keyで解決 → legacy keyでフォールバック

#### 解決フロー

1. `aidlc_normalize_key(key)` で入力キーをcanonical keyに正規化
2. `resolve_key(canonical_key)` で4階層マージ解決を試行
3. canonical keyで値が見つからない場合:
   a. `aidlc_get_legacy_key(canonical_key)` でlegacy keyを取得
   b. legacy keyが空でなければ `resolve_key(legacy_key)` で旧キーフォールバック
4. いずれかで見つかった値を返す

**責務分離のポイント**:
- `resolve_key()`: 4階層マ���ジ専用（変更なし）
- `resolve_with_aliases()`: エイリアス���決 + フォールバック順序管理
- `lib/key-aliases.sh`: マッピング定義のみ

### detect-missing-keys.sh（変更箇所のみ）

#### 欠落判定フロー（変更後���

1. defaults.toml のリーフキーを列挙（既存ロジック）
2. 各キーについて config.toml での存在を確認（既存ロジック）
3. **新規**: 不在の場合、`aidlc_get_legacy_key(key)` で legacy key を取得
4. legacy key が存在し、config.toml に legacy key が存在する場合 → `migrate`（移行推奨）
5. どちらも不在 → `missing`（欠落）

#### 出力形式（変更後）

```text
missing:rules.some.new_key          # 完全に欠落
migrate:rules.git.squash_enabled    # 旧キー(rules.squash.enabled)で充足済み、移行推奨
```

## データモデル概要

### defaults.toml（変更後の `[rules.git]` セクション）

```text
[rules.git]
commit_on_unit_complete = true      # 既存
commit_on_phase_complete = true     # 既存
branch_mode = "ask"                 # 旧: rules.branch.mode
worktree_enabled = false            # 旧: rules.worktree.enabled
unit_branch_enabled = false         # 旧: rules.unit_branch.enabled
squash_enabled = false              # 旧: rules.squash.enabled
ai_author = ""                      # 旧: rules.commit.ai_author
ai_author_auto_detect = true        # 旧: rules.commit.ai_author_auto_detect
```

除去するセクション: `[rules.branch]`, `[rules.worktree]`, `[rules.unit_branch]`, `[rules.squash]`, `[rules.commit]`

### config.toml.template（新規生成時の正本）

新規プロジェクトでは `[rules.git]` セクションのみ生成。旧セクションは生成しない。

## 処理フロー概要

### キー解決フロー

1. ユーザー/プロンプトが `read-config.sh rules.squash.enabled` を呼び出し
2. メイン処理 → `resolve_with_aliases("rules.squash.enabled")`
3. `aidlc_normalize_key("rules.squash.enabled")` → `"rules.git.squash_enabled"`
4. `resolve_key("rules.git.squash_enabled")` で4階層マージ解決
5. 新キーで見つからない → `aidlc_get_legacy_key("rules.git.squash_enabled")` → `"rules.squash.enabled"`
6. `resolve_key("rules.squash.enabled")` で旧キーフォールバック
7. 値を出力

### 欠落キー検出フロー

1. `detect-missing-keys.sh` が defaults.toml のリーフキーを列挙
2. defaults.toml には新キーのみ存在（旧セクション除去済み）
3. `rules.git.squash_enabled` が config.toml に不在 → `aidlc_get_legacy_key()` で `rules.squash.enabled` を取得
4. `rules.squash.enabled` が config.toml に存在 → `migrate:rules.git.squash_enabled` を出力
5. setup側は `migrate` 結果に対して「旧キーから新キーへの移行を推奨」メッセージを表示

## 非機能要件（NFR）への対応

### パフォーマンス
- `aidlc_normalize_key()` は case 文のルックアップのみ。実行時間増加は無視できる範囲

### 可用性
- エイリアスマップにないキーはそのまま通過（既存動作を維持）
- dasel v2/v3 両対応は既存の toml-reader.sh に委譲（変更なし）

## 技術選定

- **言語**: Bash（既存スクリプトの拡張、POSIX互換の case 文使用）
- **依存ツール**: dasel v2/v3（既存依存、変更なし）

## 実装上の注意事項

- エイリアスマップは `case` 文で実装（`declare -A` は不使用、POSIX互換性確保）
- `resolve_key()` は変更しない（4階層マージ専用の責務を維持）
- `resolve_with_aliases()` が正規化とフォールバック順序を管理（密結合を回避）
- `lib/key-aliases.sh` がエイリアス定義の単一責任点（read-config.sh と detect-missing-keys.sh で共有）
- ステップファイル（.md）の参照更新は、AIプロンプト上の文字列置換のため、パーサーの変更は不要

## 不明点と質問

（なし - 設計レビュー指摘対応済み）
