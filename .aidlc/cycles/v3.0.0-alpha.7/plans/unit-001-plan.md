# Unit 001 実装計画: squash-unit.sh 複数 --message 段落結合修正（#735）

## 対象

- **Unit**: 001-squash-unit-multi-message
- **関連 Issue**: Closes #735
- **対象ファイル**: `skills/aidlc/scripts/squash-unit.sh`（v2 ツール）
- **depth_level**: standard / **automation_mode**: semi_auto / **review_mode**: required

## 背景・原因（コード根拠）

`skills/aidlc/scripts/squash-unit.sh` を `--message` 複数指定で呼ぶと subject が失われ Co-Authored-By が二重出力される。

1. **後勝ち上書き**: `parse_args` の `--message` ハンドラ（88-95 行）が `MESSAGE="$2"` で後勝ち上書き。複数指定時は最後の値のみ残る。最後が `Co-Authored-By: ...` だと subject が消失する。
2. **Co-Authored-By 別経路の二重付与**: `squash_git`（717-721 行）/ `build_commit_message_file`（805-819 行, retroactive）が `extract_co_authors` で抽出した Co-Authored-By を `message` に常時連結する。`message` 側にも Co-Authored-By が含まれると二重出力になる。

## 実装方針

`git commit -m`（複数 -m）準拠の **段落結合** を採用する（Unit 境界で `--message-file` 新設はスコープ外と決定済み）。

### 変更1: `--message` 段落結合（parse_args）

- `MESSAGE="$2"` の後勝ち上書きを廃止し、累積結合に変更する。
- 1 個目 = subject、2 個目以降 = 空行区切りの本文段落（`git commit -m` 準拠 / `\n\n` 連結）。
- 単一 `--message` の既存挙動は不変（後方互換維持）。
- `--message` / `--message-file` 排他チェック（165 行）は `[[ -n "$MESSAGE" ]]` 判定のまま維持される。

### 変更2: Co-Authored-By 二重出力の解消（共有ヘルパ導入）

- `squash_git`（717-721 行）と `build_commit_message_file`（805-819 行, retroactive）の message + co_authors 連結ロジックを共有ヘルパ `compose_full_message(message, co_authors)` に **両経路とも必ず通す**形で集約する（経路間の挙動差を排除）。

**`compose_full_message` の契約（指摘#3 反映 / 固定）**:

- **入力**: 位置引数 2 つ（`$1=message`, `$2=co_authors`）。グローバル変数を読まない・書かない（純関数）。
- **出力**: stdout に完成メッセージを **末尾改行なし**で出力する（`printf '%s'` 系）。ファイル出力時の末尾改行付与は呼び出し側の責務（`build_commit_message_file` 側で従来どおり付与）。
- **連結規則**: `co_authors` が空 → message 単体。非空 → message に既出でない Co-Authored-By 行のみを抽出し、`message` + 空行（`\n\n`）+ 残余 co_authors（原文）を出力。残余が空（全て既出）→ message 単体。
- **dedup 比較キー（指摘#2 反映）**: 比較時のみ各行を **前後 trim**し、トレーラー名 `Co-Authored-By:` を **case-insensitive** に正規化して一致判定する（既存抽出 `grep -i "^Co-Authored-By:"` と整合）。**出力は原文を保持**（message 側既存行はそのまま、追加分は co_authors 原文）。値部分（名前・メール）は原文比較。

これにより `--message` 経由で渡された Co-Authored-By と `extract_co_authors` 抽出経路の二重出力を、大文字小文字差・前後空白差を含めて防ぐ。

### 変更3: `--help` 更新

- `--message <MESSAGE>` の説明を複数指定対応（段落結合）に更新する。

### 変更4: 回帰テスト追加（指摘#1/#4 反映）

- 新規 **`bin/tests/squash-unit/message_compose.bats`**（bats 形式）。既存 `bin/tests/squash-unit/internal_ci_checks_config_driven.bats` と同配置・同規約に従い、`source "${REPO_ROOT}/skills/aidlc/scripts/squash-unit.sh"` で関数をロードする（正しいパス・確立済み配置）。
- 実行コマンド: `bats bin/tests/squash-unit/message_compose.bats`。
- **配置変更の理由**: 当初案の `skills/aidlc/scripts/tests/*.sh` は plain-shell かつ同配下の `test_root_commit_helpers.sh` が破損パス（`../bin/squash-unit.sh`）を参照しており回帰母集団として信頼できない。`bin/tests/squash-unit/` は squash-unit.sh の実行系テストの確立済み配置（正しい source パス・bats 形式・ローカルで緑）であり、こちらに統一する。
- テストケース:
  1. **複数 `--message` 段落結合（#735 再現 / 統合）**: 一時 git リポジトリで実 squash 実行。subject 保持 + 本文段落が空行区切りで結合されることを検証。
  2. **Co-Authored-By 二重出力なし（通常経路）**: 中間コミットに Co-Authored-By がある状態で、最後の `--message` に Co-Authored-By を渡しても最終メッセージで Co-Authored-By が 1 回のみ + subject 保持。
  3. **単一 `--message` 後方互換**: 既存挙動不変。
  4. **`compose_full_message` 純関数ユニット**: dedup（完全一致 / 大文字小文字差 / 前後空白差）・空 co_authors・全既出ケース。stdout 末尾改行なし契約も検証。
  5. **`build_commit_message_file` 直接テスト（retroactive 経路 / 指摘#4）**: message 側に Co-Authored-By を含めた状態で関数を直接呼び、生成ファイル内容に Co-Authored-By が重複しないことを検証（通常経路だけ直して retroactive 経路に二重付与が残る実装漏れを検出）。

## 完了条件チェックリスト

Unit 定義「責務」セクション由来:

- [ ] `parse_args` の `--message` ハンドラを後勝ち上書きから段落結合（git commit 準拠）に変更
- [ ] Co-Authored-By トレーラの別経路付与と最後の `--message` の二重出力を解消
- [ ] 複数 `--message` / Co-Authored-By 重複の回帰テストを追加（**配置は `bin/tests/squash-unit/message_compose.bats` に補正** — Unit 責務/Issue#735 記載の `skills/aidlc/scripts/tests/` は CI 非実行かつ同配下に破損テストがあるため、確立済み・実行可能な bats 配置に変更。テスト追加という責務本旨は不変）
- [ ] `--help` の `--message` 説明を複数指定対応に更新
- [ ] 単一 `--message` の後方互換を維持
- [ ] v2 ツール（`skills/aidlc/`）のみ修正、v3 サブシステムに触れない
- [ ] 既存テストが回帰しない（新規テスト緑 + 既存テストへの悪影響なし）

## スコープ外（Unit 境界）

- `--message-file` 経路の新設（段落結合方針を採用）
- v3 サブシステム（`skills/aidlc-v3/`）への変更

## 発見事項（スコープ外・要バックログ判断）

- 既存テスト `skills/aidlc/scripts/tests/test_root_commit_helpers.sh` が `../bin/squash-unit.sh`（存在しないパス）を参照しており壊れている（関数未定義で command not found）。#735 のスコープ外の別問題。本 Unit では新規テストで正しいパスを使用し、既存破損の修正可否はバックログ起票で判断する。

## リスク・考慮事項

- Bash ツール経由のコマンド置換禁止規約（#697）: スクリプトファイル内の `$(...)` は CI チェック（`bin/check-bash-substitution.sh` = markdown コードブロック対象）の対象外で問題ないが、AI が Bash ツール引数に `$(...)` を渡さない運用は厳守。
- dedup の完全一致判定: Co-Authored-By 行の前後空白差異による誤判定を避ける（trim 方針を設計で確定）。
