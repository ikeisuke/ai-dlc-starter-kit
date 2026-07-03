# ドメインモデル: Unit 001 squash-unit.sh 複数 --message 段落結合修正

## 概要

`squash-unit.sh` のコミットメッセージ組み立てドメインを、複数 `--message`（段落結合）と Co-Authored-By トレーラの重複排除を一貫して扱えるようモデル化する。

**重要**: 本ドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2 で行う。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc/scripts/squash-unit.sh` | `parse_args` の `--message` ハンドラ、`squash_git` / `build_commit_message_file` の message+co_authors 連結ロジック、`extract_co_authors` / `extract_co_authors_for_range` の抽出規約を把握 |
| `bin/tests/squash-unit/internal_ci_checks_config_driven.bats` | 既存 bats テストの source 規約（`${REPO_ROOT}/skills/aidlc/scripts/squash-unit.sh`）・配置・setup/teardown 慣習を把握 |

### (b) 設計時に意識すべき挙動

- `--message` ハンドラ（88-95 行）は現状 `MESSAGE="$2"` の**後勝ち上書き**。複数指定で最後の値のみ残り subject が消失する。
- Co-Authored-By は**2 経路**で組み立てられる:
  - 通常: `squash_git`（717-721 行）が `message` + `\n\n` + `co_authors` を連結。
  - retroactive: `build_commit_message_file`（805-819 行）が `printf '%s\n\n%s\n'` でファイル出力。
- `co_authors` の抽出は `extract_co_authors*` が `git log --format=%b ... | grep -i "^Co-Authored-By:" | sort -u`。**case-insensitive 抽出**かつ `sort -u`（行全体・原文ベース）で重複排除済み。ただし `message` 側に同一トレーラがある場合の重複は未対応。
- `--message` / `--message-file` は排他（165 行、`[[ -n "$MESSAGE" ]]` 判定）。`--message-file` 経由の `MESSAGE` は `cat` 結果（複数行・段落をそのまま保持）。
- 後方互換: 単一 `--message`・`--message-file`・`--dry-run`・retroactive 各経路の既存挙動を壊さないこと。
- amend 経路（target_count==1）と reset --soft 経路（target_count>=2）の両方が `squash_git` 内で `full_message` を共有。

### (c) 既存実装に基づく代替案検討

| 方針 | 既存実装との適合性 | 判定 |
|------|------------------|------|
| `refactor`（`--message` を累積結合 + 連結ロジックを共有ヘルパ `compose_full_message` に集約） | 既存の 2 連結経路を 1 ヘルパに収束させ挙動差を排除。抽出側 `extract_co_authors*` は不変で済む | **採用** |
| `extend`（`--message-file` 経路を新設し複数 message をファイルで受ける） | Unit 境界で「`--message-file` 新設はスコープ外」と決定済み。既存 `--message-file` と二重化し複雑度増 | 却下 |
| `replace`（メッセージ組み立て全体を別スクリプト/ライブラリ化） | 影響範囲が Unit スコープを大きく超過。回帰リスク大 | 却下 |

## 値オブジェクト（Value Object）

### CommitMessage（コミットメッセージ）

- **属性**:
  - `subject`: string - 1 個目の `--message`（コミット件名）
  - `body_paragraphs`: string[] - 2 個目以降の `--message`（本文段落）
- **不変性**: 組み立て後の文字列は連結時点で確定。`git commit -m` 準拠で段落は空行（`\n\n`）区切り。
- **等価性**: subject + body_paragraphs の並びで等価判定。
- **生成規則**: 単一 `--message` → `subject` のみ（`body_paragraphs` 空、後方互換）。`--message-file` → ファイル内容を 1 つの文字列として `MESSAGE` に保持（段落構造は呼び出し側責務）。

### CoAuthorTrailer（Co-Authored-By トレーラ）

- **属性**: `raw_line`: string - `Co-Authored-By: Name <email>` の 1 行（原文）
- **不変性**: 抽出後の原文を保持（出力は常に原文）。
- **等価性（dedup 比較キー）**: 以下の正規化を施した文字列が一致する場合に同一トレーラと判定する。**出力は常に原文を保持**（既存コミットの表記を改変しない）:
  1. 行全体を前後 trim
  2. トレーラ名 `Co-Authored-By:`（コロンまで）を **case-insensitive**（小文字化）で正規化
  3. **コロン直後の連続空白を単一空白に畳む**（`Co-Authored-By:  Alice` と `co-authored-by: Alice` を同一視）
  4. 値部（Name <email>）は前後 trim 後に比較（値内部の表記はそのまま）

  これにより `Co-Authored-By: Alice <a>` と `co-authored-by:  Alice <a>` を重複排除できる。

## ドメインサービス

### MessageComposer（メッセージ合成サービス）

- **責務**: `CommitMessage`（既に段落結合済みの `message` 文字列）と `CoAuthorTrailer` 集合（`co_authors` 文字列）から、Co-Authored-By 重複を排除した最終コミットメッセージ文字列を生成する。**通常経路・retroactive 経路の唯一の合成点**。
- **操作**:
  - `compose(message, co_authors) -> full_message`:
    - `co_authors` 空 → `message` をそのまま返す
    - 非空 → `message` 由来の Co-Authored-By 行を dedup 比較キーで正規化した集合 `seen` を初期集合とし、`co_authors` の各行を走査。正規化キーが `seen` に**未出**のもののみ残余に原文で追加し、**採用と同時に同一キーを `seen` に追加**する（→ `co_authors` 内部の case 差・空白差重複も一意化される。既存 `sort -u` の raw 比較では残る重複をここで吸収）
    - 残余を `message` + `\n\n` + 残余 で連結
    - 残余が空（全既出）→ `message` をそのまま返す
    - 出力は末尾改行を含まない（ファイル出力時の改行付与は呼び出し側責務）

### MessageAccumulator（--message 累積）

- **責務**: `parse_args` 内で複数 `--message` を受け取り、`git commit -m` 準拠の段落結合で `MESSAGE` を構築する。
- **操作**: `append(current_message, new_value) -> message`:
  - `current_message` 空 → `new_value`（subject）
  - 非空 → `current_message` + `\n\n` + `new_value`（本文段落追加）

## ユビキタス言語

- **段落結合（paragraph join）**: 複数 `--message` を `git commit -m` と同様に空行（`\n\n`）区切りで連結すること。1 個目=subject、2 個目以降=本文段落。
- **Co-Authored-By 二重出力**: `message` 側（`--message` 経由）と抽出経路（`extract_co_authors*`）の双方に同一トレーラが含まれ、最終メッセージに重複出現する事象。
- **dedup 比較キー**: 重複判定に用いる正規化済みキー（①行全体 trim ②トレーラ名 `Co-Authored-By:` case-insensitive ③コロン直後の連続空白を単一空白に畳む ④値部は前後 trim 後に比較）。出力は常に採用行の原文を保持。
- **合成点（composition point）**: message と co_authors を連結する唯一の関数（`compose_full_message`）。通常・retroactive 両経路が必ず通る。

## 不明点と質問（設計中に記録）

[Question] なし（要件・アプローチとも確定済み。計画レビュー Round 2 で指摘0件）
[Answer] -
