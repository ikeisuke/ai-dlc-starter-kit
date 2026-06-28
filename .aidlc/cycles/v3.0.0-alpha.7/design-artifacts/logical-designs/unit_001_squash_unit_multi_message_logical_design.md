# 論理設計: Unit 001 squash-unit.sh 複数 --message 段落結合修正

## 概要

`squash-unit.sh` の `--message` 段落結合化と Co-Authored-By 重複排除を、既存関数構造への最小侵襲な変更と共有ヘルパ導入で実現する論理設計。

**重要**: 本論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体コードは Phase 2 で作成する。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc/scripts/squash-unit.sh` | `parse_args` の `--message` ハンドラ（88-95 行）、`squash_git`（717-721 行）/ `build_commit_message_file`（805-819 行）の連結ロジック、`extract_co_authors` / `extract_co_authors_for_range`（`grep -i "^Co-Authored-By:"` + `sort -u`）の抽出規約と関数構造を把握 |
| `bin/tests/squash-unit/internal_ci_checks_config_driven.bats` | 既存 bats の source 規約（`${REPO_ROOT}/skills/aidlc/scripts/squash-unit.sh`）・setup/teardown・実行コマンド慣習を把握し、新規テストを同配置・同規約に揃える |

### (b) 設計時に意識すべき挙動

- `squash_git`（717-721 行）と `build_commit_message_file`（805-819 行）は **message + co_authors の連結を別々に手組み**しており、合成点が 2 つに分散している（経路間で挙動差が生じやすい）。
- `extract_co_authors*` は `grep -i`（case-insensitive 抽出）+ `sort -u`（**raw 行比較**）。`Co-Authored-By:` と `co-authored-by:` のような case 差は `sort -u` で一意化されず残る。
- `build_commit_message_file` はファイル出力のため**末尾改行を付与**（`printf '%s\n'`）。`squash_git` は `git commit -m "$full_message"` で末尾改行に依存しない。改行契約を経路間で揃える必要がある。
- 後方互換: 単一 `--message` / `--message-file` / `--dry-run` / retroactive 各経路の既存挙動を壊さない。

### (c) 既存実装に基づく代替案検討

| 方針 | 既存実装との適合性 | 判定 |
|------|------------------|------|
| `refactor`: 2 つの連結手組みを純関数 `compose_full_message` に集約 + `--message` 累積結合 | 合成点を 1 つに収束させ経路差・二重付与を構造的に排除。抽出側は不変で最小侵襲 | **採用** |
| `extend`: `--message-file` 経路に複数 message を集約 | Unit 境界でスコープ外決定済み。既存 `--message-file` と二重化 | 却下 |
| `replace`: メッセージ組み立てを別モジュール化 | 影響範囲が Unit スコープ超過・回帰リスク大 | 却下 |

## アーキテクチャパターン

- **既存手続き型 bash スクリプトの局所リファクタリング**。新規アーキテクチャは導入しない。
- メッセージ合成の重複ロジック（通常経路 `squash_git` / retroactive 経路 `build_commit_message_file`）を**単一の純関数ヘルパ `compose_full_message` に抽出**（DRY / 単一責務）。両経路を必ず同ヘルパへ収束させ、経路間の挙動差を排除する。

## コンポーネント構成

### 変更対象（`skills/aidlc/scripts/squash-unit.sh`）

```text
squash-unit.sh
├── parse_args()                  [変更] --message ハンドラを段落結合化
├── compose_full_message()        [新規] message + co_authors 合成（純関数 / 唯一の合成点）
├── squash_git()                  [変更] full_message 組み立てを compose_full_message へ委譲
├── build_commit_message_file()   [変更] 同上（retroactive 経路）
└── show_help()                   [変更] --message 説明を複数指定対応に更新
```

### コンポーネント詳細

#### `parse_args()`（変更）

- **責務**: 引数解析。`--message` を後勝ち上書きから**累積段落結合**に変更。
- **依存**: なし（グローバル `MESSAGE` を構築）。
- **変更点**: `--message` case の `MESSAGE="$2"` を「`MESSAGE` 空なら `$2`、非空なら `MESSAGE`+`$'\n\n'`+`$2`」に変更。`--message-file` 排他チェック（`[[ -n "$MESSAGE" ]]`）は不変で機能する。

#### `compose_full_message()`（新規 / 唯一の合成点）

- **責務**: `message` と `co_authors` から Co-Authored-By 重複を排除した最終メッセージを生成。
- **依存**: なし（**純関数**。グローバル変数を読まない・書かない）。
- **公開インターフェース**: 下記「コマンド」参照。

#### `squash_git()`（変更）

- **責務**: 通常 squash（amend / reset --soft）。
- **変更点**: 717-721 行の `full_message` 手組みを `full_message=$(compose_full_message "$message" "$co_authors")` に置換。amend（target_count==1）/ reset --soft（>=2）双方が同一 `full_message` を共有する既存構造は不変。

#### `build_commit_message_file()`（変更）

- **責務**: retroactive 経路のコミットメッセージファイル生成。
- **変更点**: 812-816 行の if 分岐（co_authors 有無での printf 出し分け）を `compose_full_message` 委譲に置換。ファイル末尾改行は本関数側で付与（`printf '%s\n' "$(compose_full_message ...)"`）。

#### `show_help()`（変更）

- **責務**: ヘルプ表示。`--message` の説明を複数指定（段落結合）対応に更新。

## スクリプトインターフェース設計

### compose_full_message（新規関数）

#### 概要

message 本文に co_authors を結合し、message に既出の Co-Authored-By 行を重複排除する純関数。通常・retroactive 両経路の唯一の合成点。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `$1` (message) | 必須 | 段落結合済みのコミットメッセージ本文（subject + 本文段落） |
| `$2` (co_authors) | 必須 | 改行区切りの Co-Authored-By 行群（`extract_co_authors*` の出力 / 空文字可） |

#### 成功時出力

```text
<最終コミットメッセージ（末尾改行なし）>
```

- 終了コード: `0`
- 出力先: **stdout**
- 契約:
  - グローバル変数を読まない・書かない（純関数）
  - 末尾改行を**付与しない**（ファイル出力時の改行は呼び出し側責務）
  - `co_authors` 空 or 残余空 → `message` を原文のまま出力
  - dedup 比較キー（正規化）= ①行全体 trim ②トレーラ名 `Co-Authored-By:` を case-insensitive 化 ③コロン直後の連続空白を単一空白に畳む ④値部は前後 trim 後に比較。**出力は採用行の原文を保持**。message 側既出に加え `co_authors` 内部の重複も `seen` 蓄積で一意化

#### dedup 判定の処理フロー

1. `co_authors` が空 → `printf '%s' "$message"` で即時返却。
2. `message` の各行を dedup 比較キー（trim + トレーラ名 case-insensitive 正規化）に変換した集合 `seen` を初期構築。
3. `co_authors` の各行について、正規化キーが `seen` に**含まれない**場合のみ「残余」に原文で追加し、**同時にそのキーを `seen` に追加**する（空行はスキップ）。これにより message 側既出だけでなく **`co_authors` 内部の case 差・空白差重複も一意化**される（既存 `sort -u` の raw 比較で残る重複を吸収）。
4. 残余が空 → `message` 単体。非空 → `message` + `\n\n` + 残余（改行連結、末尾改行なし）。

### --message（変更後の引数仕様）

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--message <MSG>` | `--message-file` と排他。**非 dry-run 時は必須 / dry-run 時は任意**（既存挙動: `--dry-run` では `MESSAGE` 空を許容） | squash 後コミットメッセージ。**複数回指定可**（`git commit -m` 準拠で 1 個目=件名、2 個目以降=空行区切りの本文段落として段落結合） |

## 処理フロー概要

### 複数 --message + Co-Authored-By のメッセージ生成（通常経路）

**ステップ**:
1. `parse_args` が複数 `--message` を段落結合し `MESSAGE` を構築（subject + 本文段落）。
2. `extract_co_authors` が中間コミット範囲から Co-Authored-By を抽出（`grep -i` + `sort -u`）し `CO_AUTHORS` へ。
3. `squash_git` が `compose_full_message "$MESSAGE" "$CO_AUTHORS"` を呼び、重複排除済み `full_message` を取得。
4. `git commit (--amend) -m "$full_message"` でコミット。

**関与するコンポーネント**: `parse_args` / `extract_co_authors` / `compose_full_message` / `squash_git`

### retroactive 経路

`squash_retroactive_git` → `extract_co_authors_for_range` → `build_commit_message_file`（内部で `compose_full_message` 委譲）→ rebase reword。**通常経路と同一の合成点を通る**ため二重付与が構造的に発生しない。

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 任意個数の `--message` を段落結合可能（Unit NFR）。
- **対応策**: 累積結合は O(n)。`compose_full_message` の dedup は co_authors 行数 × message 行数の線形走査で、件数は実用上小（数行）。

### セキュリティ
- **要件**: コミットメッセージに機密情報を混入させない（Unit NFR）。
- **対応策**: ヘルパは入力文字列をそのまま扱い、新たな外部入力経路を追加しない。dedup は文字列比較のみで外部コマンド実行を増やさない。

### 可用性 / 後方互換
- **要件**: 単一 `--message` の既存挙動維持（Unit 境界）。
- **対応策**: `parse_args` は `MESSAGE` 空時に `$2` をそのまま代入（単一指定は従来同値）。`compose_full_message` は co_authors 空・既出なしの場合に従来と同一出力（`message` + `\n\n` + co_authors）。

## 技術選定

- **言語**: bash（既存スクリプト準拠 / `set -euo pipefail`）。
- **テスト**: bats-core（既存 `bin/tests/squash-unit/` 配置・規約準拠）。
- **新規ライブラリ**: なし。

## 実装上の注意事項

- **dedup 比較の堅牢性**: トレーラ名の case 差（`Co-authored-by:`）・前後空白差で重複が漏れないよう、比較時のみ正規化する。出力は原文保持（既存コミットの表記を改変しない）。
- **末尾改行契約の厳守**: `compose_full_message` は末尾改行を付けない。`squash_git`（`-m` 渡し）はそのまま、`build_commit_message_file`（ファイル）は呼び出し側で `\n` 付与。両経路で改行挙動差を出さない。
- **コマンド置換規約（#697）**: スクリプトファイル内の `$(...)` は許容（CI の `bin/check-bash-substitution.sh` は markdown コードブロック対象）。ただし AI が Bash ツール引数に `$(...)` を渡さないこと。
- **ガイド照合**: 終了コード規約 `guides/exit-code-convention.md` と整合（本変更は終了コードのセマンティクスを変更しない / 既存トークン出力を維持）。
- **既存テスト破損の非対応**: `skills/aidlc/scripts/tests/test_root_commit_helpers.sh` の破損（`../bin/squash-unit.sh` 参照）は本 Unit スコープ外。新規テストは `bin/tests/squash-unit/` の正しい配置を使用。

## 不明点と質問（設計中に記録）

[Question] なし（計画レビュー Round 2 で指摘0件 / 要件・アプローチ確定済み）
[Answer] -
