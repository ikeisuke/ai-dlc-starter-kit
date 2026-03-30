# 論理設計: パス参照一括更新・aidlc_dir設定廃止

## 置換ルール

### ルール1: ガイド参照の正規化

- 対象パターン: `{{aidlc_dir}}/guides/{filename}`
- 置換先: `guides/{filename}`
- 対象ファイル: `skills/aidlc/steps/` 配下の全Markdownファイル
- 検証: `grep -r '{{aidlc_dir}}' skills/aidlc/steps/` が0件

### ルール2: 未存在ファイル参照の削除

- 対象パターン: `{{aidlc_dir}}/bug-response-flow.md`
- 対応: 参照を含む行またはセクションを削除
- 対象ファイル:
  - `steps/construction/04-completion.md`
  - `steps/operations/01-setup.md`
  - `steps/operations/04-completion.md`
- 理由: `bug-response-flow.md` は `skills/aidlc/guides/` に存在しない

### ルール3: ディレクトリ参照の更新

- 対象: `steps/common/project-info.md` の `{{aidlc_dir}}/` 行
- 対応: v2構造を反映した記述に更新（`skills/aidlc/` ベース）

### ルール4: プリフライト仕様の更新

- `preflight.md` から以下を除去:
  - `read-config.sh --keys` 呼び出し内の `paths.aidlc_dir`
  - コンテキスト変数テーブルの `aidlc_dir` 行
  - 結果提示フォーマットの `aidlc_dir: {value}` 行

## 影響範囲

| 変更層 | 影響 | リスク |
|-------|------|-------|
| ステップファイル（Markdown） | パス表記の変更。実行時の動作に影響なし | 低（テキスト置換のみ） |
| プリフライト仕様（Markdown） | AIエージェントの設定取得動作が変わる | 低（表示のみの変更） |
| 設定ファイル | **変更しない** | なし |
| スクリプト | **変更しない** | なし |

## 変更しない理由（設定キー残置）

`paths.aidlc_dir` は以下のスクリプトチェーンで使用されている:

```
config.toml/defaults.toml
  └─ bootstrap.sh (_aidlc_resolve_docs_dir)
       └─ AIDLC_DOCS_DIR
            ├─ check-setup-type.sh
            └─ migrate-config.sh
```

設定キーを削除すると `bootstrap.sh` が `warn:aidlc-docs-dir-fallback` を出力し `docs/aidlc` にフォールバックする。これは存在しないディレクトリであり、依存スクリプトが誤動作する。Unit 003 で `bootstrap.sh` を `AIDLC_PLUGIN_ROOT` ベースに修正した上で同時に削除する。
