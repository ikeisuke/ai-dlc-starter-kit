# 論理設計: 設定基盤リファクタ

## 概要

aidlc.tomlの設定キー構造を統一し、read-config.shのデフォルト値レイヤー追加とキーマイグレーション（旧→新フォールバック）を実現する論理設計。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

レイヤードマージ方式（既存パターンの拡張）。read-config.sh の既存3階層に defaults.toml レイヤーを最低優先度で追加し、4階層マージに拡張する。

## コンポーネント構成

### ディレクトリ構成（変更後）

```text
prompts/
├── package/
│   ├── bin/
│   │   ├── read-config.sh             # 修正: 4階層マージ対応
│   │   ├── resolve-backlog-mode.sh    # 新規: バックログモード解決共通ロジック
│   │   ├── check-backlog-mode.sh      # 修正: resolve-backlog-mode.sh をsource
│   │   ├── env-info.sh                # 修正: resolve-backlog-mode.sh をsource
│   │   └── init-cycle-dir.sh          # 修正: resolve-backlog-mode.sh をsource
│   ├── config/
│   │   └── defaults.toml          # 新規: デフォルト値定義
│   └── prompts/
│       ├── construction.md        # 修正: [backlog]参照を[rules.backlog]に
│       ├── inception.md           # 修正: 同上
│       ├── operations.md          # 修正: 同上
│       └── common/
│           └── agents-rules.md    # 修正: 同上
├── setup/
│   └── templates/
│       └── aidlc.toml.template    # 修正: [backlog]→[rules.backlog]
└── setup-prompt.md                # 修正: [backlog]生成・参照を[rules.backlog]に
```

### コンポーネント詳細

#### read-config.sh（修正）

- **責務**: 設定値の4階層マージ読み込み
- **依存**: dasel（TOML解析）
- **変更点**: defaults.toml レイヤーを最低優先度（優先度0）として追加

#### resolve-backlog-mode.sh（新規）

- **責務**: バックログモード解決ロジックの共通実装
- **依存**: dasel（TOML解析）、grep/sed（dasel未インストール時のフォールバック）
- **公開関数**: `resolve_backlog_mode()` - 新キー優先・旧キーフォールバック・有効値バリデーション・競合警告を一箇所で実装
- **使用方法**: 他スクリプトから `source` して `resolve_backlog_mode` 関数を呼び出す

#### check-backlog-mode.sh（修正）

- **責務**: バックログモードの解決と出力
- **依存**: resolve-backlog-mode.sh（source）
- **変更点**: 個別の解決ロジックを削除し、`resolve_backlog_mode` 関数を呼び出す

#### env-info.sh（修正）

- **責務**: 依存ツール状態の一覧出力（`--setup` オプション時にバックログモード含む）
- **依存**: resolve-backlog-mode.sh（source）
- **変更点**: `get_backlog_mode()` を `resolve_backlog_mode` 呼び出しに置換

#### init-cycle-dir.sh（修正）

- **責務**: サイクルディレクトリの初期化（バックログモードに応じたディレクトリ作成）
- **依存**: resolve-backlog-mode.sh（source）
- **変更点**: `get_backlog_mode()` を `resolve_backlog_mode` 呼び出しに置換

#### defaults.toml（新規）

- **責務**: スターターキットのデフォルト値を集中定義
- **依存**: なし（read-config.sh から参照される）
- **配置**: `prompts/package/config/defaults.toml` → rsync → `docs/aidlc/config/defaults.toml`

## スクリプトインターフェース設計

### read-config.sh（修正後）

#### 概要

設定値を4階層マージで読み込み、最終値を出力する。

#### 引数（変更なし）

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `<key>` | 必須 | ドット区切りの設定キー |
| `--default <value>` | 任意 | キー不在時のデフォルト値 |

#### 4階層マージ順序（変更後）

| 優先度 | レイヤー | パス | required | 変更 |
|--------|---------|------|----------|------|
| 0（最低） | defaults | `docs/aidlc/config/defaults.toml` | No | **新規追加** |
| 1 | user | `~/.aidlc/config.toml` | No | 既存 |
| 2 | project | `docs/aidlc.toml` | Yes | 既存 |
| 3（最高） | local | `docs/aidlc.toml.local` | No | 既存 |

#### 実装方針

既存の3レイヤー読み込みロジック（HOME → PROJECT → LOCAL）の前に、defaults.toml レイヤーを追加する。

- defaults.toml のパスは `DEFAULTS_CONFIG_FILE` 変数で管理
- パスの決定: スクリプト自身の位置から相対パスで `../config/defaults.toml` を解決
- ファイル不在時はスキップ（警告なし、オプションファイル）
- 読み取りエラー時はstderrに警告を出力しスキップ

#### 成功時出力（変更なし）

```text
[設定値]
```

- 終了コード: `0`

#### エラー時出力（変更なし）

- 終了コード: `1`（キー不在、デフォルトなし）
- 終了コード: `2`（エラー）

### resolve-backlog-mode.sh（新規）

#### 概要

バックログモード解決ロジックの共通実装。check-backlog-mode.sh、env-info.sh、init-cycle-dir.sh の3スクリプトから source して使用する。

#### 公開関数

`resolve_backlog_mode()` - 引数なし、stdoutにモード値を出力

#### バックログモード解決ロジック

```text
1. rules.backlog.mode を dasel で読み取り
2. 取得値が有効値（git/issue/git-only/issue-only）か検証
3. 有効値 → 採用
4. 不正値 or 未定義 → backlog.mode（旧キー）を dasel で読み取り
5. 旧キーの取得値が有効値か検証
6. 有効値 → 採用
7. 不正値 or 未定義 → デフォルト "git"
8. 新旧両方存在かつ値不一致 → stderrに警告出力（値は新キーを使用）
```

#### dasel未インストール時のフォールバック

dasel が使えない場合は grep/sed で解決する。この場合も同じ優先順序（新キー優先）を維持する。

```text
1. [rules.backlog] セクションから mode を grep で抽出
2. 取得値を検証
3. 有効値 → 採用
4. 不正値 or 未定義 → [backlog] セクションから mode を grep で抽出（旧キー）
5. 取得値を検証
6. 有効値 → 採用
7. 不正値 or 未定義 → デフォルト "git"
```

#### 成功時出力

```text
# 戻り値（stdout）: git, git-only, issue, issue-only のいずれか（デフォルト: git）
```

※ resolve-backlog-mode.sh 内部で解決されるため、呼び出し元に空値は返らない。

#### 競合警告出力（resolve-backlog-mode.sh から出力）

```text
Warning: Both [rules.backlog].mode and [backlog].mode exist with different values. Using [rules.backlog].mode.
```

- 出力先: stderr

### check-backlog-mode.sh（修正後）

#### 概要

resolve-backlog-mode.sh を source してバックログモードを出力する。

#### API契約の変更

- **変更前**: dasel未インストール時は `backlog_mode:` (空値) を出力し、AIにフォールバックを委ねる
- **変更後**: dasel未インストール時でも grep/sed で値解決し、常に `backlog_mode:[有効値]` を出力する
- **消費者への影響**: プロンプト側の空値フォールバック処理は不要になるが、既存の空値チェック分岐は残しても害はない（空値が来なくなるだけ）

#### 実装方針

resolve-backlog-mode.sh を source し、`resolve_backlog_mode` 関数の戻り値を `backlog_mode:` 形式で出力するだけのシンプルなラッパー。

### env-info.sh（修正後）

#### 概要

`get_backlog_mode()` を `resolve_backlog_mode` 呼び出しに置換する。

#### 変更点

- resolve-backlog-mode.sh を source
- `get_backlog_mode()` 関数の実装を `resolve_backlog_mode` 呼び出しに置換
- 出力キー名は変更なし: `backlog.mode:[値]`（後方互換のため出力形式は維持）

### init-cycle-dir.sh（修正後）

#### 概要

`get_backlog_mode()` を `resolve_backlog_mode` 呼び出しに置換する。

#### 変更点

- resolve-backlog-mode.sh を source
- `get_backlog_mode()` 関数の実装を `resolve_backlog_mode` 呼び出しに置換

## ファイル形式

### defaults.toml

```text
# AI-DLC Default Configuration
# このファイルはスターターキットのデフォルト値を定義します
# プロジェクトの docs/aidlc.toml で上書き可能です

[rules.squash]
enabled = false

[rules.jj]
enabled = false

[rules.feedback]
enabled = true

[rules.backlog]
mode = "git"

[rules.reviewing]
mode = "recommend"
tools = ["codex"]

[rules.worktree]
enabled = false

[rules.history]
level = "standard"

[rules.release]
changelog = false
version_tag = false

[rules.unit_branch]
enabled = false

[rules.linting]
markdown_lint = false

[rules.size_check]
enabled = true
max_bytes = 150000
max_lines = 1000
target_pattern = "*.md"

[rules.commit]
ai_author_auto_detect = true
```

### aidlc.toml 変更差分（概要）

`[backlog]` セクション（行129-136）を削除し、`[rules.backlog]` として `[rules]` 配下に移動する。

### aidlc.toml.template 変更差分（概要）

テンプレート内の `[backlog]` セクションを `[rules.backlog]` に変更する。

### setup-prompt.md 変更差分（概要）

- マイグレーションスクリプト内の `[backlog]` セクション生成を `[rules.backlog]` に変更
- `[backlog].mode` の参照を `[rules.backlog].mode` に変更
- grep判定条件の `^\[backlog\]` を `^\[rules\.backlog\]` に変更（旧形式のマイグレーション分岐も追加）

### プロンプト・ガイド変更差分（概要）

5ファイル7箇所の `[backlog]` / `[backlog].mode` 参照テキストを `[rules.backlog]` / `[rules.backlog].mode` に更新する。

| ファイル | 箇所数 |
|--------|--------|
| `prompts/package/prompts/construction.md` | 1 |
| `prompts/package/prompts/inception.md` | 2 |
| `prompts/package/prompts/operations.md` | 1 |
| `prompts/package/prompts/common/agents-rules.md` | 1 |
| `prompts/package/guides/backlog-management.md` | 2 |

## 処理フロー概要

### 設定値読み込みフロー（read-config.sh）

**ステップ**:

1. 引数パース（key, --default）
2. dasel存在確認
3. プロジェクト設定ファイル存在確認
4. **defaults.toml から値を取得（新規ステップ）**
5. HOME設定から値を取得
6. プロジェクト設定から値を取得
7. LOCAL設定から値を取得
8. 最終値の出力（strip_quotes処理含む）

**関与するコンポーネント**: read-config.sh, defaults.toml

### バックログモード解決フロー（check-backlog-mode.sh）

**ステップ**:

1. dasel存在確認
2. 設定ファイル存在確認
3. `rules.backlog.mode`（新キー）を読み取り
4. 有効値バリデーション
5. 不正値/未定義の場合: `backlog.mode`（旧キー）を読み取り
6. 有効値バリデーション
7. 不正値/未定義の場合: デフォルト `git` を使用
8. 新旧競合チェック → 警告出力
9. `backlog_mode:[値]` を出力

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 設定読み取りの応答時間に体感的な変化がないこと
- **対応策**: defaults.toml の読み取りは既存レイヤーと同じ方式（dasel呼び出し1回追加のみ）。defaults.toml が小さいファイルのため影響は軽微

### スケーラビリティ

- **要件**: 新しい設定キーの追加が容易であること
- **対応策**: defaults.toml にキーを追加するだけで、read-config.sh の変更は不要。backlog.mode 系のキーマイグレーションは `resolve-backlog-mode.sh` に一元追加。他のキーのマイグレーションが必要な場合は個別対応

## 技術選定

- **言語**: Bash
- **ツール**: dasel（TOML解析）、grep/sed（dasel未インストール時のフォールバック）

## 実装上の注意事項

- **prompts/package/ を編集**: `docs/aidlc/` は rsync コピーのため直接編集しない
- **defaults.toml のパス解決**: スクリプト自身の位置（`$0` または `BASH_SOURCE`）から相対パスで解決。`readlink -f` が macOS で使えない場合を考慮
- **出力形式の後方互換**: env-info.sh の `backlog.mode:[値]` 出力は変更しない（消費者への影響を避ける）
- **テストマトリクス**: 7パターン（新キーのみ / 旧キーのみ / 両方一致 / 両方不一致 / 両方なし / 新キー不正+旧キー有効 / 新旧とも不正）

## 既知の制限事項

- **read-config.sh の型契約**: 現在スカラー値前提で設計されており、配列値（例: `tools = ["codex"]`）取得時の出力形式は dasel の出力に依存する。defaults.toml に配列値が含まれるが、呼び出し側で適切にパースする責務は変わらない。この制限は既存のものであり、本Unitで新たに導入されるものではない。

## 不明点と質問（設計中に記録）

（なし - 計画承認時に仕様は確定済み）
