# Unit 004 計画: read-config.sh ドキュメント更新

## 概要

read-config.sh の最新インターフェース（`--keys` オプション等）をドキュメントに反映する。
現在のドキュメントは単一キーモード（`<key> [--default <value>]`）のみ記載されており、
バッチモード（`--keys`）の説明が欠落している。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/guides/config-merge.md` | `--keys` オプションの説明・使用例を追加、エラー動作の記載 |
| `prompts/package/prompts/common/rules.md` | 使用例を最新インターフェースに更新 |

**注意**: `docs/aidlc/` は rsync コピーのため直接編集しない。`prompts/package/` を編集する。`docs/aidlc/` への同期は Operations Phase の `/upgrading-aidlc` で実施される。

**スコープ外**: config-merge.md の階層数記載（現在「3階層」）と read-config.sh 実装（4階層: defaults.toml 含む）の不一致は、本Unitのスコープ外とする。必要に応じて別途バックログに記録する。

## 実装計画

### Phase 1: 設計

本Unitはドキュメント追記のみであり、設計フェーズの対象外（設計省略）。
ドメインモデル・論理設計は不要。

### Phase 2: 実装

#### ステップ1: config-merge.md の更新

1. 「read-config.sh の使用方法」セクションに `--keys` オプションの説明を追加:
   - バッチモードの構文: `read-config.sh --keys <key1> [key2] ...`
   - 出力フォーマット: `key:value` 形式（1行1キー）
   - `--keys` と `--default` の排他性の説明
   - `--keys` と位置引数 `<key>` の排他性の説明
2. 使用例を追加:
   - 複数キーの一括取得例
   - 出力例
3. エラー動作セクションを追加/更新:
   - `--keys` モードでのキー不在時の挙動（スキップされる）
   - 全キー不在時の終了コード（1）
   - エラー発生時の終了コード（2）

#### ステップ2: rules.md の更新

1. 「設定読み込み【重要】」セクションの使用例に `--keys` オプションの例を追加
2. 両モード（単一キー / バッチモード）の使い分け指針を簡潔に記載

#### ステップ3: 確認

1. 追記内容が read-config.sh の実際のインターフェースと整合しているか確認
2. markdownlint 実行

## 完了条件チェックリスト

- [ ] config-merge.md に --keys オプションの説明・使用例が追加されている
- [ ] rules.md の使用例が最新インターフェースに更新されている
- [ ] エラー動作の記載がある
