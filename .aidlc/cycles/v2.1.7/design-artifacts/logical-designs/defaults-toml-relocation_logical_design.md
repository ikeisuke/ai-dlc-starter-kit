# 論理設計: defaults.toml参照のスキル間依存ルール準拠

## 変更1: defaults.tomlのコピー

正本 `skills/aidlc/config/defaults.toml` を配布用コピー `skills/aidlc-setup/config/defaults.toml` にコピーする。TOML設定値は変更しない。正本表示の同期用コメントのみ追加する。

### 同期規約
- **正本**: `skills/aidlc/config/defaults.toml`
- **コピー**: `skills/aidlc-setup/config/defaults.toml`
- **更新契機**: 正本が更新された時にメタ開発チームが手動同期
- **検証**: リリース前に `diff` で差分0を確認（成功基準 #526-4）

## 変更2: 02-generate-config.md のパス解決ロジック修正

### 変更前（L379付近）
```markdown
**defaults.toml パスの解決**: `aidlc` スキルのベースディレクトリ配下の `config/defaults.toml` を Read ツールで存在確認し、存在すればそのパスを使用する。`aidlc` スキルのベースディレクトリは `aidlc-setup` スキルの親ディレクトリではなく、`aidlc` スキルのインストール先を基準とする。見つからない場合は「defaults.toml が見つかりません。欠落キー検出をスキップします。」と表示してこのステップをスキップする。
```

### 変更後
```markdown
**defaults.toml パスの解決**: `aidlc-setup` スキルのベースディレクトリ配下の `config/defaults.toml` を Read ツールで存在確認し、存在すればそのパスを使用する。見つからない場合は「defaults.toml が見つかりません。欠落キー検出をスキップします。」と表示してこのステップをスキップする。
```

## API境界（入力契約）

### 02-generate-config.md → detect-missing-keys.sh
- **呼び出し元の責務**: `config/defaults.toml` のパスを自スキルのベースディレクトリから解決し、`--defaults` 引数に渡す
- **前提条件**: `config/defaults.toml` が自スキルのベースディレクトリ配下に存在すること
- **不在時の動作**: 呼び出し元（02-generate-config.md）がReadツールで存在確認し、不在の場合はスキップメッセージを表示して `detect-missing-keys.sh` を呼び出さない
- **正常系で保証される入力**: 有効なTOMLファイルパス（正本と同一内容）

### 変更のポイント
- 参照先を `aidlc` スキル → `aidlc-setup` スキル（自スキル）に変更
- `aidlc` スキルのインストール先を基準とする旨の記述を削除
- エラー時のスキップ動作は維持（既存の異常系動作を保持）
- `detect-missing-keys.sh` の `--defaults` 引数に渡すパスの出所が変わるのみ

## 変更しないもの
- `detect-missing-keys.sh` のスクリプトロジック
- `aidlc` スキル内のファイル
- 欠落キー検出の入出力フォーマット
