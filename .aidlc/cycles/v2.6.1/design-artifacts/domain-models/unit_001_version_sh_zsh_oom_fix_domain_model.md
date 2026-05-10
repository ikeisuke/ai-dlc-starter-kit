# Unit 001 ドメインモデル: version.sh zsh OOM クラッシュ修正

## 概要

`version.sh` の責務はシンプルで、複雑なドメインオブジェクトを持たない。本ドキュメントでは「version 取得契約」と「呼び出し経路の責務分離」を整理する軽量モデルとして記述する。

## ドメイン境界

本 Unit が扱うドメインは以下の境界に閉じる:

- **入力境界**: `marketplace.json` のファイルパス（外部システムからの位置参照）
- **出力境界**: `marketplace.json.metadata.version` の値（SemVer 文字列）+ 終了コード（0/1/2 の 3 値）
- **依存境界**: dasel v3 / jq（外部 CLI）/ bash（実行環境）

## 主要エンティティ

### VersionContract（version 取得契約 - 概念オブジェクト）

| 属性 | 型 | 説明 |
|------|------|------|
| `source_path` | filesystem path | `marketplace.json` の絶対 / 相対パス |
| `extraction_tool` | enum {dasel, jq, none} | 抽出に使うツール（dasel 優先 / jq フォールバック / 双方不在） |
| `version_value` | SemVer string | 抽出されたバージョン文字列（成功時） |
| `error_kind` | enum {missing-json-path, marketplace-json-not-found, marketplace-json-read-failed, dasel-and-jq-unavailable, metadata-version-missing-or-empty, metadata-version-invalid-semver} | エラー種別（失敗時） |
| `exit_code` | integer {0, 1, 2} | 0=成功 / 1=コンテンツエラー / 2=実行環境エラー |

VersionContract はステートレスで、毎回 `read_marketplace_version()` 関数呼び出しによって生成される。永続化は行わない。

### InvocationRoute（呼び出し経路 - 概念オブジェクト）

| 属性 | 値 | 説明 |
|------|------|------|
| `route_id` | `cli_mode_bash` | `bash <path> <json_path>` 形式（**新規追加 / 必須サポート**） |
| `route_id` | `subprocess_source` | `bash -c "source <path>; read_marketplace_version <args>"` 形式（**必須サポート**） |
| `route_id` | `direct_source` | 既存の bash スクリプトから `source <path>` で関数取り込み（**互換維持**） |
| `route_id` | `interactive_zsh_source` | ユーザーが対話 zsh シェルで手動 `source` し関数を直接呼び出す（**非対象、SKILL.md で注意書き**） |

**経路安全性**:

| route_id | OOM リスク（zsh 環境） | 本 Unit での扱い |
|----------|---------------------|----------------|
| `cli_mode_bash` | なし（bash プロセスで実行） | 必須サポート、AI エージェント誘導の主経路 |
| `subprocess_source` | なし（bash プロセスで実行） | 必須サポート、互換 |
| `direct_source` | なし（bash スクリプトから呼ばれる前提、shebang が bash） | 互換維持、変更なし |
| `interactive_zsh_source` | あり（zsh `command_not_found_handler` 競合） | 非対象、注意書きで案内 |

## 責務の分離

### `read_marketplace_version()` 関数（業務ロジック層）

- 単一責務: `marketplace.json` から `metadata.version` を抽出して検証する
- 入力: `marketplace.json` のパス
- 出力: stdout（version 文字列）/ stderr（エラー詳細）/ 終了コード
- 不変条件: 関数定義は変更せず、本 Unit ではガードの追加のみ

### CLI モードガード（薄い委譲層 / 新規）

- 単一責務: `bash <path>` 形式の呼び出しを `read_marketplace_version()` への引数透過に委譲する
- 入力: コマンドライン引数 `$@`
- 出力: `read_marketplace_version "$@"` の結果をそのまま返す
- 配置: `version.sh` の末尾（既存関数定義の後）

### SKILL.md「バージョン表示」セクション（呼び出し誘導層 / 改訂）

- 単一責務: AI エージェントに対して必須サポート経路と非対象経路を区別して提示する
- 入力: ユーザーが `/aidlc v` を実行
- 出力: 安全な経路で version 取得を実行する手順
- 不変条件: marketplace.json.metadata.version を SoT とする方針は変更しない（DR-001 / DR-002 / v2.6.0 Unit 001 の決定を維持）

## 不変条件（Invariants）

1. **SoT 不変**: version の正本は `marketplace.json.metadata.version`。本 Unit でこの方針は変更しない
2. **後方互換性**: 既存の `source` 経由呼び出しは破壊されない（CLI モードガードは `${BASH_SOURCE[0]} == $0` で `source` 時は実行されない）
3. **エラー契約不変**: 終了コード規約（0/1/2）と stderr メッセージ形式は変更しない
4. **責務境界不変**: 業務ロジックは `read_marketplace_version()` に集約、CLI ガードは薄い委譲のみ

## 状態遷移

VersionContract は単一トランザクション（呼び出し 1 回）で生成・破棄されるため、状態遷移は持たない。

InvocationRoute はリクエスト時に `${BASH_SOURCE[0]} == $0` の評価で動的に決定される（永続的な状態を持たない）。

## ドメインイベント（comprehensive レベルでのみ追加）

`depth_level=standard` のため本セクションは省略する。
