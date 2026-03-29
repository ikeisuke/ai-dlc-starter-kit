# 論理設計: バージョン検証一元化

## 概要

`read_starter_kit_version()` にmatch_count検証を統合し、`update-version.sh` から重複ロジックを排除する。

**重要**: この論理設計では**コードは書かず**、インターフェース定義のみを行います。

## アーキテクチャパターン

共有ライブラリパターン。`version.sh` が共通関数を提供し、呼び出し側スクリプトがsourceして使用する。

## コンポーネント構成

```text
skills/aidlc/scripts/lib/
└── version.sh          ← 共通ライブラリ（変更対象）

bin/
└── update-version.sh   ← 呼び出し側（変更対象）
```

## スクリプトインターフェース設計

### read_starter_kit_version()（version.sh内の関数 — 検証付き読み取り、拡張）

#### 概要
config.tomlからstarter_kit_versionを読み取り、キーの一意性と値の存在を検証して返す。関数名は既存互換のため据え置きだが、実質は「検証付き読み取り」である。

#### 引数
| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `$1` (config_path) | 必須 | config.tomlのファイルパス |

#### 成功時出力
```text
{バージョン文字列}
```
- 終了コード: `0`
- 出力先: stdout

#### エラー時出力
- 終了コード: `1` — キー不在（0件）、複数キー存在（2件以上）、または値が空
- 終了コード: `2` — ファイル読取エラー（ファイル不在、sedエラー）
- 出力先: stderrへの出力なし（呼び出し側がエラーメッセージを制御）

#### 内部処理フロー（変更後）

1. ファイル存在確認 → 不在なら return 2
2. **match_count検証（新規）**: `grep -c` で `starter_kit_version` キーの出現回数を取得
   - 0件 → return 1（キー不在）
   - 2件以上 → return 1（フォーマット不正）
3. sedで値を抽出 → sedエラーなら return 2
4. 値が空 → return 1
5. stdoutに値を出力 → return 0

### update-version.sh（変更後の呼び出しフロー）

#### 現在の処理（L86-100）

```text
L87: _current_version_txt=$(cat version.txt)
L92: _current_aidlc_toml=$(sed -n '...' .aidlc/config.toml)  ← 重複
L96: _match_count=$(grep -c '...' .aidlc/config.toml)        ← 重複
L97: if [[ "$_match_count" -ne 1 ]] || [[ -z "..." ]]        ← 重複
L98:     echo "error:invalid-config-toml-format"
```

#### 変更後の処理

```text
L87: _current_version_txt=$(cat version.txt)                  ← 変更なし
L92: _current_aidlc_toml を read_starter_kit_version() で取得  ← 置換
     終了コードに基づくエラーメッセージ出力:
       1 → "error:invalid-config-toml-format"
       2 → "error:config-toml-read-failed"
L96-100: 削除（match_count検証は関数内に統合済み）
```

#### エラーコードマッピング

| read_starter_kit_version() 終了コード | update-version.sh のエラー出力 |
|------|------|
| 0 | （正常続行） |
| 1 | `error:invalid-config-toml-format` |
| 2 | `error:config-toml-read-failed` |

## スコープ外事項（AIレビュー指摘の記録）

以下はレビューで指摘されたが、本Unitのスコープ外として対応しない:

1. **update-version.shのエラー出力先（暫定契約）**: 終了コード規約ではstderrだが、既存の`error:xxx`はstdoutに出力。後方互換性のため本Unitでは既存形式を維持する（暫定契約）。移行条件: 呼び出し側がstdoutパースに依存している箇所を棚卸し後、stderr移行を実施する（別サイクルで対応）
2. **書き込みロジックの統合**: `write_starter_kit_version()` をライブラリに追加すべきだが、本Unitの責務は読み取り・検証の一元化のみ
3. **関数名のリネーム**: `read_starter_kit_version()` は検証も行うため `read_valid_starter_kit_version()` が適切だが、既存呼び出し元への影響が大きいため現状維持

## 非機能要件（NFR）への対応

- **パフォーマンス**: 該当なし（grep 1回追加のみ）
- **セキュリティ**: 該当なし
- **後方互換性**: update-version.sh の既存エラー出力形式（stdout + `error:xxx`）・終了コードは変更なし。終了コード規約との不整合は既存の問題であり、本Unitで対応しない

## 技術選定

- **言語**: Bash
- **使用コマンド**: grep, sed（既存と同一）

## 実装上の注意事項

- `read_starter_kit_version()` のmatch_count検証では `grep -c '^[[:space:]]*starter_kit_version[[:space:]]*='` を使用（update-version.sh L96と同一パターン）
- `set -euo pipefail` 環境下でのgrepの終了コード（0件マッチ時にexit 1）に注意。`|| true` で吸収するか、呼び出し方を調整
- 既存の終了コード体系（0/1/2）を維持し、新しい終了コードを追加しない
