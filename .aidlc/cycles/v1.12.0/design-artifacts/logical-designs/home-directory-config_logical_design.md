# 論理設計: ユーザー共通設定

## 概要

3階層設定マージを実現するための論理設計。

## 責務境界

| コンポーネント | 責務 | 本Unitでの変更 |
|---------------|------|---------------|
| `read-config.sh` | 設定値の読み込み・マージ処理 | 3階層マージ対応 |
| `config-merge.md` | マージルールの説明・ユーザー向けドキュメント | 3階層の説明追加 |
| `inception.md` | セットアップフロー・ユーザー案内 | ~/.aidlc/作成案内追加 |

**責務分離の原則**:
- `read-config.sh`: 実装ロジック（how）
- `config-merge.md`: 仕様説明（what）
- `inception.md`: ユーザー案内（when/where）

## コンポーネント構成

### read-config.sh（修正）

既存の2階層マージを3階層に拡張。

```text
[入力]
- キー（必須）
- デフォルト値（オプション）

[処理フロー]
1. 引数パース
2. dasel存在確認
3. HOME設定読み込み ← 新規追加
   - $HOME未設定 → スキップ
   - ファイル不在 → スキップ
4. PROJECT設定読み込み（既存）
   - ファイル不在 → エラー（exit 2）
5. LOCAL設定読み込み（既存）
   - ファイル不在 → スキップ
6. 値出力

[出力]
- 設定値（stdout）
- 終了コード: 0=値あり, 1=キー不在, 2=エラー
```

### config-merge.md（修正）

設定ファイル階層表に`~/.aidlc/config.toml`を追加。

| ファイル | 用途 | Git管理 | 優先度 |
|----------|------|---------|--------|
| `~/.aidlc/config.toml` | ユーザー共通設定 | No | 低 |
| `docs/aidlc.toml` | プロジェクト共有設定 | Yes | 中 |
| `docs/aidlc.toml.local` | 個人設定（上書き用） | No | 高 |

### setup-prompt.md（修正）

初回セットアップ完了時に`~/.aidlc/`作成案内を追加。

**案内内容**:

- ディレクトリ作成: `mkdir -p ~/.aidlc`
- 設定ファイル作成: `touch ~/.aidlc/config.toml`
- 詳細は `docs/aidlc/guides/config-merge.md` を参照

## インターフェース

### read-config.sh

```bash
# 使用方法（変更なし）
docs/aidlc/bin/read-config.sh <key> [--default <value>]

# 例
docs/aidlc/bin/read-config.sh rules.mcp_review.mode
docs/aidlc/bin/read-config.sh rules.custom.foo --default "bar"
```

## 変更差分

### read-config.sh

1. **定数追加**:
   ```bash
   HOME_CONFIG_FILE="$HOME/.aidlc/config.toml"
   ```

2. **HOME設定読み込み処理追加**（PROJECT読み込み前）:
   ```bash
   # HOME設定読み込み
   if [[ -n "${HOME:-}" && -f "$HOME_CONFIG_FILE" ]]; then
       # get_value で読み込み、値があれば保持
   fi
   ```

3. **変数名調整**: コメントで3階層を明示

## パフォーマンス考慮

### 定量的根拠

| 操作 | 既存（2階層） | 変更後（3階層） | 増分 |
|------|--------------|----------------|------|
| ファイル存在確認 | 2回 | 3回 | +1回 |
| dasel呼び出し（最大） | 2回 | 3回 | +1回 |
| dasel呼び出し（HOME不在時） | 2回 | 2回 | 0回 |

### 最適化方針

- ファイル存在確認は`[[ -f "$file" ]]`で最小限（シェル組み込み、I/Oなし）
- ファイル不在時はdasel呼び出しなし（外部プロセス起動回避）
- `$HOME`未設定時は即座にスキップ（追加オーバーヘッドゼロ）

### NFR達成基準

- HOME設定ファイル不在時: 追加遅延なし（既存と同等）
- HOME設定ファイル存在時: dasel呼び出し+1回のみ（数ミリ秒程度）

## 制約事項

- **Windows非対応**: `$HOME`環境変数とUnixパス形式を前提。Windows対応は将来の別Unitで検討
