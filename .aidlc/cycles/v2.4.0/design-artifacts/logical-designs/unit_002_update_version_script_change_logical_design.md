# 論理設計: Unit 002 update-version.sh 挙動変更

## 概要

`bin/update-version.sh` の修正前後の出力形式・処理フロー差分を表形式で定義し、削除対象コード行を一覧化する。`.aidlc/config.toml` の **妥当性検証専用読み取り** の位置付けを明示する。

**重要**: この論理設計では**コードは書かず**、変更前後のインターフェース差分と削除対象範囲のみを定義する。具体的なコード修正は Phase 2 で行う。

## アーキテクチャパターン

bash スクリプト（手続き的）。レイヤー分離・モジュール構成等は採用しない（既存実装の局所変更）。

## コンポーネント構成

`bin/update-version.sh` のみが対象。共通ライブラリ `skills/aidlc/scripts/lib/version.sh`（`read_starter_kit_version` / `validate_semver` / `strip_v_prefix`）への変更はなし。

## インターフェース設計

### スクリプトインターフェース: `bin/update-version.sh`

#### 引数（変更なし）

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--version <version>` | 必須 | バージョン番号（v プレフィックス可） |
| `--dry-run` | 任意 | 書き込みを行わず変更内容を表示 |

#### dry-run 出力の差分

両 skill ファイルが存在する場合の例（`skill_*_version_*` 行は対応ファイルが存在する場合のみ出力、`bin/update-version.sh:95-100, 125-131` の条件分岐に依存）。

修正前:

```text
version_update:dry-run
version_txt_current:<old>
version_txt_new:<new>
aidlc_toml_current:<old>      ← 削除
aidlc_toml_new:<new>          ← 削除
skill_aidlc_version_current:<old>   （skills/aidlc/version.txt 存在時のみ）
skill_aidlc_version_new:<new>       （同上）
skill_setup_version_current:<old>   （skills/aidlc-setup/version.txt 存在時のみ）
skill_setup_version_new:<new>       （同上）
```

修正後:

```text
version_update:dry-run
version_txt_current:<old>
version_txt_new:<new>
skill_aidlc_version_current:<old>   （skills/aidlc/version.txt 存在時のみ）
skill_aidlc_version_new:<new>       （同上）
skill_setup_version_current:<old>   （skills/aidlc-setup/version.txt 存在時のみ）
skill_setup_version_new:<new>       （同上）
```

#### 成功出力の差分

両 skill ファイルが存在する場合の例（`skill_*_version` 行は対応ファイルが存在する場合のみ出力、`bin/update-version.sh:198-199` の条件分岐に依存）。

修正前:

```text
version_update:success
version_txt:<new>
aidlc_toml:<new>              ← 削除
skill_aidlc_version:<new>     （skills/aidlc/version.txt 存在時のみ）
skill_setup_version:<new>     （skills/aidlc-setup/version.txt 存在時のみ）
```

修正後:

```text
version_update:success
version_txt:<new>
skill_aidlc_version:<new>     （skills/aidlc/version.txt 存在時のみ）
skill_setup_version:<new>     （skills/aidlc-setup/version.txt 存在時のみ）
```

#### エラー出力（変更なし）

| エラー | 維持/削除 | 理由 |
|-------|---------|------|
| `error:version-lib-not-found` | 維持 | lib/version.sh 不在チェック（L33-L37） |
| `error:missing-version` | 維持 | 引数チェック |
| `error:missing-version-value` | 維持 | 引数チェック |
| `error:unknown-option:<opt>` | 維持 | 引数チェック |
| `error:invalid-version-format` | 維持 | semver 検証 |
| `error:version-txt-not-found` | 維持 | 入力存在チェック |
| `error:config-toml-not-found` | **維持**（責務通り） | リポジトリ整合性検証 |
| `error:config-toml-read-failed` | **維持**（妥当性検証専用） | unreadable / file not found 検出契約維持（read_starter_kit_version return code 2） |
| `error:invalid-config-toml-format` | **維持**（妥当性検証専用） | starter_kit_version 行の異常検出契約維持（read_starter_kit_version return code 1: キー欠落 / 重複 / 空値 / 引用符不一致） |
| `error:config-toml-write-failed` | **削除** | 書き込み廃止により発生しない |
| `error:version-txt-read-failed` | 維持 | 入力読み取り検証 |
| `error:mktemp-failed` | 維持 | 一時ファイル作成失敗 |
| `error:backup-failed` | 維持 | バックアップ作成失敗 |
| `error:version-txt-write-failed` | 維持 | version.txt 書き込み失敗 |
| `error:skill-aidlc-version-write-failed` | 維持 | skill 書き込み失敗 |
| `error:skill-setup-version-write-failed` | 維持 | skill 書き込み失敗 |

## 削除対象コード一覧

### 修正前後の差分（行番号は修正前のもの）

| 行番号（修正前） | 修正前のコード | 修正後の状態 |
|----------------|--------------|------------|
| L108-L117 | `_current_aidlc_toml=$(read_starter_kit_version ".aidlc/config.toml")` | **維持**（妥当性検証専用、コードコメントで明示） |
| L123 | `echo "aidlc_toml_current:${_current_aidlc_toml}"` | **削除** |
| L124 | `echo "aidlc_toml_new:${VERSION}"` | **削除** |
| L138 | `_tmp_toml=$(mktemp ./.aidlc/config.toml.XXXXXX) ...` | **削除** |
| L142 | `_tmp_skill_aidlc=$(mktemp "$_skill_aidlc_version.XXXXXX") \|\| { \rm -f "$_tmp_version" "$_tmp_toml"; ... }` | **修正**: cleanup から `$_tmp_toml` 削除 → `\rm -f "$_tmp_version"` |
| L145 | `_tmp_skill_setup=$(mktemp "$_skill_setup_version.XXXXXX") \|\| { \rm -f "$_tmp_version" "$_tmp_toml" "$_tmp_skill_aidlc"; ... }` | **修正**: cleanup から `$_tmp_toml` 削除 → `\rm -f "$_tmp_version" "$_tmp_skill_aidlc"` |
| L147 | `trap '\rm -f "$_tmp_version" "$_tmp_toml" "$_tmp_skill_aidlc" "$_tmp_skill_setup" "${_bak_version:-}" "${_bak_toml:-}"' EXIT` | **修正**: `_tmp_toml` / `_bak_toml` 参照を除く |
| L151 | `sed "s/^[[:space:]]*starter_kit_version[[:space:]]*=.*/.../" .aidlc/config.toml > "$_tmp_toml" \|\| ...` | **削除** |
| L161 | `_bak_toml=$(mktemp) \|\| { \rm -f "$_bak_version"; ... }` | **削除** + 直前の `_bak_version` mktemp 失敗時の cleanup から削除 |
| L163 | `\cp .aidlc/config.toml "$_bak_toml" \|\| { ... }` | **削除** |
| L178 | `\cp "$_bak_toml" .aidlc/config.toml 2>/dev/null \|\| true` | **削除** |
| L181 | `\rm -f "$_bak_version" "$_bak_toml" "$_bak_skill_aidlc" "$_bak_skill_setup"` | **修正**: `_bak_toml` 参照を除く |
| L185 | `\mv "$_tmp_toml" .aidlc/config.toml \|\| { echo ...; _rollback; exit 1; }` | **削除** |
| L192 | `\rm -f "$_bak_version" "$_bak_toml" "$_bak_skill_aidlc" "$_bak_skill_setup"` | **修正**: `_bak_toml` 参照を除く |
| L197 | `echo "aidlc_toml:${VERSION}"` | **削除** |

## 処理フロー差分

### 修正前のアトミック更新シーケンス（両 skill ファイル存在時）

```text
1. 一時ファイル作成 (最大 4 ファイル: version, toml, skill_aidlc, skill_setup)
2. バックアップ作成 (最大 4 ファイル)
3. mv 最大 4 回 (version → toml → skill_aidlc → skill_setup)
4. 失敗時は _rollback で対応ファイル復元
5. 成功時はバックアップ削除
```

### 修正後のアトミック更新シーケンス（条件付き）

mv 段階数は `skills/*/version.txt` の存在有無により 1〜3 段階に変動する:

| skill ファイル状態 | mv 段階数 | mv 順序 | テスト対応 |
|-------------------|-----------|--------|---------|
| 両 skill ファイル存在（本リポジトリ標準状態） | 3 段階 | `version → skill_aidlc → skill_setup` | ケース 6a (2段階目失敗) / 6b (3段階目失敗) |
| skills/aidlc/version.txt のみ存在 | 2 段階 | `version → skill_aidlc` | （本サイクルでは検証対象外、Unit 002 のスコープは標準状態を前提） |
| skills/aidlc-setup/version.txt のみ存在 | 2 段階 | `version → skill_setup` | （同上） |
| 両 skill ファイル不在 | 1 段階 | `version` のみ | （同上） |

**ロールバック整合性テスト前提**: 本リポジトリは両 skill ファイルが存在する標準状態のため、テストケース 6a / 6b は標準 3 段階フローを前提に実装する。fixture セットアップで両 skill ファイルを作成する。

```text
1. 一時ファイル作成 (1〜3 ファイル: version + 存在する skill 分)
2. バックアップ作成 (1〜3 ファイル)
3. mv 1〜3 回 (version → 存在する skill 分)
4. 失敗時は _rollback で対応ファイル復元
5. 成功時はバックアップ削除
```

## 非機能要件（NFR）への対応

### パフォーマンス

- 本リポジトリ標準状態（両 skill ファイル存在）では mv 4 回 → 3 回、書き込み 1 回削減
- 一般化すると mv `2+N` 回 → `1+N` 回（N=存在する skill ファイル数、最大 2）。toml 書き込み 1 回が削減されるため、いずれの構成でも書き込み 1 回削減で高速化（無視できるレベル）

### セキュリティ

- ファイルパーミッション・所有権の変更なし
- バックアップ削除タイミング（成功時即削除、失敗時は trap 経由削除）は既存通り

### 可用性

- 既存契約（出力フォーマット以外）を維持: `set -euo pipefail` / アトミック更新 / ロールバック処理 / 存在チェック / 読み取り検証エラー

## 技術選定

- **言語**: bash 3.2+（macOS `/bin/bash` 3.2.57 / GNU bash 4.x / 5.x 全対応）
- **テストフレームワーク**: bash 直接実行（既存スタイル）
- **mv スタブ**: `PATH` 先頭に偽 `mv` を配置する Unit 001 と同等パターン

## 実装上の注意事項

- `_tmp_toml` / `_bak_toml` の変数定義・参照を完全削除（残骸はコードレビューで検出されるリスク。L138, L142, L145, L147, L151, L161, L163, L178, L181, L185, L192 の全箇所を確認）
- trap 文の引用符バランスを保つ
- `_current_aidlc_toml` 残置時はコードコメントで「妥当性検証専用、変数値は出力に使用しない」と明示し、未使用変数として後続改修で削除されないように防御
- L161 の `_bak_toml=$(mktemp) || { \rm -f "$_bak_version"; ... }` 削除に伴い、L160 の `_bak_version=$(mktemp) || { echo "error:mktemp-failed"; exit 1; }` の cleanup チェーンが分断されないよう検証
- L142, L145 の cleanup 分岐から `$_tmp_toml` 参照を削除する際、構文を `\rm -f "$_tmp_version"` (L142) / `\rm -f "$_tmp_version" "$_tmp_skill_aidlc"` (L145) に正確に変更

## 不明点と質問

なし（修正方針は計画フェーズで codex AI レビュー 3 反復を経て確定済み）。
