# Unit 005 ドメインモデル: `squash-unit.sh` の CI 構造チェックスクリプト設定駆動化

## 概要

`squash-unit.sh` から starter kit 固有のチェックスクリプト名（`check-skill-references` / `check-bash-substitution` / `check-test-isolation`）を完全排除し、`.aidlc/config.toml` の `[rules.squash.internal_ci_checks].scripts` 設定キー経由で動的にチェック群を解決する軽量ドメインモデル。CLAUDE.md「設計原則 § ドッグフーディング特殊処理を本体に埋めない」原則を本体スクリプトレベルで実現する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2 で行う。

## 主要概念

### InternalCiCheckRegistry（内部 CI チェック レジストリ）

`squash-unit.sh` が Unit 完了時に opt-in 実行する CI 構造チェックスクリプト群を表す概念。設定駆動化により、本体スクリプトはこのレジストリの「現在の構成」を `.aidlc/config.toml` 経由でクエリし、`bin/check-*.sh` のファイル名を直接知らない。

| 属性 | 型 | 意味 |
|------|----|------|
| `scripts` | `List<RepoRelativeScriptPath>` | 実行対象スクリプトのリポジトリルート相対パス列。順序は実行順 |
| `loadingState` | `enum { resolved, no_config, config_read_error, invalid_format, empty_config }` | 設定読取の結果状態 |

**解決元（優先順位）**: `read-config.sh` の 4 階層マージ結果（defaults / user-global / project-shared / project-local）。本 Unit では `defaults.toml` には設定を入れず、starter kit リポジトリの `.aidlc/config.toml`（project-shared）に明示する方針。

### CiCheckEntry（個別チェックエントリ）

`InternalCiCheckRegistry.scripts` の各要素。リポジトリルート相対パスとして表現される単一スクリプトの実行可否判定単位。

| 属性 | 型 | 意味 |
|------|----|------|
| `path` | `String`（リポジトリルート相対）| 例: `bin/check-skill-references.sh` |
| `validity` | `enum { valid, invalid_path, not_found }` | パス正規化 + 実体存在チェック結果 |
| `executionResult` | `enum { not_executed, success, failed }` | 実行結果（valid かつ not_found でない場合のみ評価対象）|

**不変条件**: `path` は以下の 4 条件をすべて満たす場合のみ `valid`:

1. 空文字でない
2. 絶対パスでない（`/` で始まらない）
3. パス traversal を含まない（`..` を含まない）
4. 許容文字セット `[A-Za-z0-9_./-]+` に収まる

いずれかに反する場合は `invalid_path` として個別 skip + 警告。

### SkipReason（skip 理由値オブジェクト）

集約 skip / 個別 skip の発生理由を表す不変な値オブジェクト。安定トークンの reason サフィックスとして観測可能。

| reason 値 | スコープ | 発生条件 |
|----------|---------|---------|
| `no-config` | 集約 skip | `read-config.sh` exit 1（設定セクション不在 = consumer プロジェクト想定）|
| `config-read-error` | 集約 skip | `read-config.sh` exit 2（実行系エラー: dasel 未インストール / TOML 破損等）|
| `invalid-config-format` | 集約 skip | `parse_config_array()` が想定外フォーマット入力を検出 |
| `empty-config` | 集約 skip | 設定値が `[]`（空配列）|
| `no-script-present` | 集約 skip | 設定リスト内の全エントリが `invalid_path` または `not_found` |
| `invalid-path` | 個別 skip | `CiCheckEntry.validity == invalid_path` |
| `script-not-found` | 個別 skip | `CiCheckEntry.validity == not_found` |

**reason の分離方針**（設計レビュー Round 1 指摘 #2 反映）: 設定不在（`no-config`）と実行系エラー（`config-read-error`）は明確に分離する。両者を同じ reason に畳み込むと、運用時に「設定がない（consumer プロジェクト）」と「設定読取で障害が起きている（要対応）」が観測上区別できなくなり可観測性が低下する。

**等価性**: 文字列 reason 値の同一性。

### StableTokenContract（安定トークン出力契約）

`run_internal_ci_checks_or_skip()` の stdout 出力規約。CI ログ集約 / 監視 / bats テストから観測される境界契約。

| 出力種別 | 形式 | 行数 |
|---------|------|------|
| 集約 skip | `squash:info:internal-ci-checks-skipped`（必須 1 行目）+ `squash:info:internal-ci-checks-skipped:reason=<reason>`（必須 2 行目）| 2 行固定 |
| 個別 skip（不正パス）| `squash:warn:internal-ci-check-skipped:reason=invalid-path:script=<entry>` | 1 行 |
| 個別 skip（実体不在）| `squash:info:internal-ci-check-skipped:reason=script-not-found:script=<entry>` | 1 行 |
| チェック失敗（既存）| `squash:error:<basename>-failed` | 1 行 |

**不変条件**:

- 既存トークン `squash:info:internal-ci-checks-skipped` は 1 行目として常に出力する（既存 grep ルールの後方互換）
- reason は別行固定（suffix 形式は採用しない / 計画レビュー Round 2 で確定）

### ConfigArrayParser（設定配列パーサ）

`read-config.sh` の現行配列出力形式（Python 風 list literal `['a', 'b']`）を改行区切りの行配列にデコードする責務を持つ局所ヘルパ概念。`run_internal_ci_checks_or_skip()` から `read-config.sh` の生出力形式を隠蔽するレイヤー境界として配置。

| 操作 | 入力 | 出力 / 戻り値 |
|------|------|--------------|
| `parse(rawString)` | `read-config.sh` の生出力（例: `['a', 'b']` / `[]` / 空文字列）| stdout: 改行区切り行配列（空配列・空文字列は 0 行）/ exit 0 |
| `parse(rawString)` | 想定外フォーマット（例: 配列開始 `[` がない / 閉じ括弧 `]` がない / コードインジェクション疑いの制御文字混入）| stdout なし / exit 1（呼び出し元は `invalid-config-format` reason で集約 skip） |

**入力フォーマット契約**（設計レビュー Round 1 指摘 #3 反映）: `parse_config_array()` は「`read-config.sh` の Python 風 list literal 出力」のみを正規入力として受け付ける。具体的には以下のいずれか:

1. 空文字列（`read-config.sh` exit 1 の出力なしケース、ただし呼び出し元が exit 0 と取り違えた場合の防御）→ 0 行出力 / exit 0
2. `[]`（空配列）→ 0 行出力 / exit 0
3. `['<entry>'(, '<entry>')*]`（1 件以上の要素を持つ配列）→ N 行出力 / exit 0
4. 上記のいずれにも該当しない → 0 行出力 / exit 1（不正フォーマット）

不正フォーマット検出時は呼び出し元（`run_internal_ci_checks_or_skip`）が `config-read-error` ではなく専用の `invalid-config-format` reason で集約 skip する。これにより設定読取エラー（exit 2）と設定値そのものの破損を観測上区別できる。

**将来の置換条件**: `read-config.sh` 側に `--format=lines` 等の配列安全出力モードが追加された段階で、本パーサは削除され、`read-config.sh` の直接出力に置き換えられる。これにより設定読取層がシリアライズ責務を負い、ドメイン処理層（`squash-unit.sh`）からシリアライズ知識を排除する移行が完了する。

## 状態遷移

`run_internal_ci_checks_or_skip()` の呼び出し時に、`InternalCiCheckRegistry.loadingState` の遷移と各 `CiCheckEntry` の評価状態遷移が連動する。

```text
[呼び出し]
  ↓
[read-config.sh 呼び出し] → exit 2 → loadingState=config_read_error → 警告 + 集約 skip(reason=config-read-error) + return 0
  ↓ exit 1
loadingState=no_config → 集約 skip(reason=no-config) + return 0
  ↓ exit 0
[parse_config_array で配列化] → exit 1 → loadingState=invalid_format → 警告 + 集約 skip(reason=invalid-config-format) + return 0
  ↓ exit 0 / 0 行 → loadingState=empty_config → 集約 skip(reason=empty-config) + return 0
  ↓ exit 0 / ≥1 行
loadingState=resolved
  ↓
[各 CiCheckEntry を順次評価]
  各エントリ:
    [パス正規化チェック] → 不正 → validity=invalid_path → 個別 skip 警告
                       → 妥当
    [リポジトリルート相対パスで実体存在チェック] → 不在 → validity=not_found → 個別 skip 情報
                                              → 存在 → validity=valid
    [bash 実行] → 成功 → executionResult=success
              → 失敗 → executionResult=failed → 集約エラートークン + return 2
  ↓
[全エントリ valid==invalid_path or not_found のみ] → 集約 skip(reason=no-script-present) + return 0
[いずれか valid==valid で success のみ] → return 0（成功 / 静音）
```

## 依存関係

- **上位**: `squash-unit.sh::main()`（呼び出し元）→ `run_internal_ci_checks_or_skip()` のエラー / 成功で squash 続行可否を判断
- **本体**: `run_internal_ci_checks_or_skip()` → `parse_config_array()`（局所ヘルパ）/ `read-config.sh`（外部スクリプト経由）
- **下位**: 各 `CiCheckEntry.path` が指す `bin/check-*.sh` スクリプト（bash 実行）

依存方向は単方向（上位 → 本体 → 下位 / 外部）。循環依存なし。`parse_config_array()` は `squash-unit.sh` 内に閉じた局所ヘルパであり、外部から参照されない（将来 `read-config.sh --format=lines` 移行時に削除可能）。

## ユビキタス言語

- **opt-in シグナル**: 設定リスト内の各エントリのファイル存在自体を「実行する / しない」のシグナルとして扱う方式。v2.6.0 Unit 007 で導入
- **集約 skip**: 全チェックスクリプトが何らかの理由で実行されなかった状態。1 件以上の info ログと安定トークン 2 行を出力
- **個別 skip**: 一部のチェックスクリプトのみが skip された状態。集約トークンは出力しない
- **starter kit リポジトリ**: ai-dlc-starter-kit 自身の git リポジトリ（dogfooding 環境）
- **consumer プロジェクト**: starter kit を AI-DLC スキルとして利用する任意のプロジェクト
- **ドッグフーディング特殊処理**: starter kit 自身と consumer プロジェクトの両方で同じスクリプトが実行される際、本体スクリプト内に「自リポジトリが starter kit 自身か」を判定する分岐ロジック。CLAUDE.md「設計原則」で禁止
- **公開 API スクリプト層**: Unit 004 で確立した、`scripts/read-config.sh` を全スキルから参照可能とする例外規定。本 Unit では同層の `read-config.sh` を `squash-unit.sh` から呼ぶ

## 不明点と質問

[Question] 設計に関する不明点はあるか
[Answer] 計画レビュー Round 1〜4 で論点整理済み（設定不在契約 / 配列パース責務 / テスト配置 / トークン形式 / `..` 排除条件）。本ドメインモデルでは追加の不明点なし。
