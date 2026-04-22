# 論理設計: Unit 001 pr-ops 空配列展開 bug 修正

## 概要

`cmd_get_related_issues` 関数内の `closes_list` / `relates_list` / `all_list` の 3 配列について、`closes_list` と `relates_list` の空・非空の組み合わせ 4 形態（2×2）と各形態での出力期待値、および修正前後の挙動差分を表形式で定義する。

**重要**: この論理設計では**コードは書かず**、配列状態と出力契約のみを定義する。具体的なコード修正は Phase 2 で行う。

## アーキテクチャパターン

bash スクリプト関数（純粋関数）。`set -euo pipefail` 環境下で動作する。レイヤー分離・モジュール構成等は採用しない（既存実装の局所修正）。

## コンポーネント構成

`pr-ops.sh:207-253` の `cmd_get_related_issues` 関数のみが対象。他のコンポーネントへの変更はなし。

### 関数内部の配列構成

| 配列名 | 型 | 役割 | 構築タイミング |
|--------|-----|------|--------------|
| `closes_list` | `local -a` | 完全対応 Issue 番号（`#NNN` 形式の文字列要素） | Unit 定義ファイル走査ループで `+=` で追加 |
| `relates_list` | `local -a` | 部分対応 Issue 番号 | 同上 |
| `all_list` | `local -a` | `closes_list + relates_list`（重複除去前） | ループ後に結合 |

## インターフェース設計

### スクリプトインターフェース: `pr-ops.sh get-related-issues <cycle>`

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `<cycle>` | 必須 | サイクル名（`v2.4.0` 等）。`${AIDLC_CYCLES}/${cycle}/story-artifacts/units/` を走査対象とする |

#### 成功時出力

```text
issues:<all_csv または none>
closes:<closes_csv または none>
relates:<relates_csv または none>
```

- 終了コード: `0`
- 出力先: stdout
- csv は重複除去後 `sort -u | tr '\n' ','` で生成（ASCII ソート順）

#### エラー時出力

```text
error:units-dir-not-found
```

- 終了コード: `1`
- 出力先: stdout（既存挙動を維持）

## 配列状態遷移表（核心）

`closes_list` と `relates_list` の空・非空の組み合わせ 4 形態（2×2）と、修正前後の挙動・期待出力、テストケース対応:

| 形態 | `closes_list` | `relates_list` | 修正前挙動（bug） | 修正後 `all_list` 構築 | 修正後期待出力 | テストケース |
|------|---------------|----------------|-----------------|----------------------|----------------|------------|
| **形態 A: 両配列空** | `()`（空） | `()`（空） | **fail**: `closes_list[@]: unbound variable` | `()`（空、両ガードで何も追加しない） | `issues:none` / `closes:none` / `relates:none` | ケース 1 |
| **形態 B: closes のみ非空** | `(#1 #2)` | `()`（空） | **fail**: `relates_list[@]: unbound variable` | `(#1 #2)`（closes ガードで追加、relates ガードでスキップ） | `issues:#1,#2` / `closes:#1,#2` / `relates:none` | ケース 2 |
| **形態 C: relates のみ非空** | `()`（空） | `(#3 #4)` | **fail**: `closes_list[@]: unbound variable` | `(#3 #4)`（closes ガードでスキップ、relates ガードで追加） | `issues:#3,#4` / `closes:none` / `relates:#3,#4` | ケース 3 |
| **形態 D: 両配列非空** | `(#1 #2)` | `(#3 #4)` | **success**（既存唯一の安全形態） | `(#1 #2 #3 #4)`（両ガードで追加） | `issues:#1,#2,#3,#4` / `closes:#1,#2` / `relates:#3,#4` | ケース 4 |

### 修正前 failure matrix の根拠

bash 3.2 の `set -u` 環境では、宣言済み配列であっても要素 0 個の状態で `"${arr[@]}"` 展開を行うと `unbound variable` エラーとなる。修正前コード:

```text
local -a all_list=("${closes_list[@]}" "${relates_list[@]}")
```

は `closes_list` と `relates_list` のどちらか一方でも空の場合に必ず失敗する。**修正前に安全に動作するのは形態 D（両配列非空）のみ**。

実際の Issue #588 の発生条件「関連 Issue がない場合」は形態 A に対応するが、本修正は形態 A/B/C のすべてを救済する設計とする（B/C は実質的に「Unit 定義に `closes` / `relates` のいずれか片方しか含まれない」サイクルで発生する未顕在化 bug）。

**注**: 形態 D で `closes_list` と `relates_list` に同一 Issue 番号が含まれる場合、`issues:` 行は `sort -u` により重複除去される（既存挙動を維持）。

## 修正対象ロジック

### 修正前（bug あり、`pr-ops.sh:244-248`）

```text
# 後方互換: 全Issue結合
local -a all_list=("${closes_list[@]}" "${relates_list[@]}")
if [[ ${#all_list[@]} -gt 0 ]]; then
    all_csv=$(printf '%s\n' "${all_list[@]}" | sort -u | tr '\n' ',' | sed 's/,$//')
fi
```

**問題**: bash 3.2 の `set -u` 環境では `closes_list` または `relates_list` のいずれか一方でも空の場合（形態 A/B/C）に `"${arr[@]}"` 展開が `unbound variable` を出す。安全に動作するのは形態 D のみ（前節 failure matrix 参照）。

### 修正後（空ガード形式）

```text
# 後方互換: 全Issue結合（空配列展開を set -u 環境で安全化）
local -a all_list=()
if [[ ${#closes_list[@]} -gt 0 ]]; then
    all_list+=("${closes_list[@]}")
fi
if [[ ${#relates_list[@]} -gt 0 ]]; then
    all_list+=("${relates_list[@]}")
fi
if [[ ${#all_list[@]} -gt 0 ]]; then
    all_csv=$(printf '%s\n' "${all_list[@]}" | sort -u | tr '\n' ',' | sed 's/,$//')
fi
```

**効果**: 形態 A で `all_list` を空配列のまま保持。`${#all_list[@]} -gt 0` ガードで `printf` を呼ばずスキップ。`all_csv` 未代入のため、後段の `${all_csv:-none}` で `none` フォールバック。

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 配列展開ガード追加分のオーバーヘッドのみ（無視できるレベル）
- **対応策**: 既存ループ構造に変更なし。条件分岐 2 つ追加のみ

### セキュリティ

- **要件**: 入力エスケープ・サニタイズに変更なし
- **対応策**: 既存正規表現マッチ（`pr-ops.sh:227-231`）を変更しない

### 可用性（既存契約の維持）

- **要件**: `issues:` / `closes:` / `relates:` の 3 行出力契約と `none` フォールバック挙動を完全維持
- **対応策**: 形態 A〜D の全パターンを単体テスト 4 ケースで検証、orchestration 経由を回帰テストで検証

## 技術選定

- **言語**: bash 3.2+（macOS `/bin/bash` 3.2.57 / GNU bash 4.x / 5.x 全対応）
- **テストフレームワーク**: bash 直接実行（`bash test_*.sh`）。既存スタイルに合わせる
- **gh スタブ**: `test_operations_release_merge_pr_empty_args.sh:22-33` のスタブパターンを踏襲

## 実装上の注意事項

- bash 4+ 専用構文（`mapfile` / `readarray` / 連想配列等）を導入しない
- 既存 L237/L240/L246 の `${#xxx[@]} -gt 0` ガードパターンと完全に一貫した形式を使用
- スタブ `gh` は呼び出し履歴を記録ファイルに追記し、テスト assertion で内容検証する形式とする

## 不明点と質問

なし（修正方針は計画フェーズで codex AI レビュー 3 反復を経て確定済み）。
