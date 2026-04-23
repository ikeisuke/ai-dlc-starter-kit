# 論理設計: Unit 004 aidlc-setup の prompts/package/ 遺物純削除

## 概要

修正対象 2 ファイル（`skills/aidlc-setup/steps/01-detect.md` / `CHANGELOG.md`）の修正前後のテキスト差分と動作確認手順を定義する。本 Unit はマークダウン記述削除のみのため、コンポーネント構成・処理フロー等は採用しない。

**重要**: この論理設計では**コードは書かず**、テキスト差分とその位置のみを定義する。具体的なファイル編集は Phase 2 で行う。

## アーキテクチャパターン

ドキュメント純削除（Markdown）。プログラムロジックの変更を含まない。

## 修正対象ファイル一覧

### 1. skills/aidlc-setup/steps/01-detect.md

修正対象: L87-L93 周辺（L89-L91 削除 + 空行整理）

#### 修正前（L87-L93）

```text
**このセットアップは、対象プロジェクトのルートディレクトリで実行する必要があります。**

もし現在のディレクトリが `ai-dlc-starter-kit` リポジトリ内の場合:
- **メタ開発モード**: `prompts/package/` ディレクトリが存在する場合は、スターターキット自体の開発として続行できます
- **通常利用**: 対象プロジェクトのルートディレクトリに移動してから、このファイルのフルパスを指定して再度実行してください

### 早期判定（ユーザー確認の前に実行）
```

#### 修正後

```text
**このセットアップは、対象プロジェクトのルートディレクトリで実行する必要があります。**

### 早期判定（ユーザー確認の前に実行）
```

#### 差分（unified diff 形式）

```diff
 **このセットアップは、対象プロジェクトのルートディレクトリで実行する必要があります。**

-もし現在のディレクトリが `ai-dlc-starter-kit` リポジトリ内の場合:
-- **メタ開発モード**: `prompts/package/` ディレクトリが存在する場合は、スターターキット自体の開発として続行できます
-- **通常利用**: 対象プロジェクトのルートディレクトリに移動してから、このファイルのフルパスを指定して再度実行してください
-
 ### 早期判定（ユーザー確認の前に実行）
```

注: 削除前は L87 の後ろ、L89-L91 の前後に空行があり、それぞれの空行ブロックが連続するため、削除後は空行 1 行のみを残す（可読性・体裁統一）。

### 2. CHANGELOG.md

修正内容: v2.4.0 セクション既存 `### Changed` 節（Unit 003 で追加）の直後に `### Removed` 見出しと `#595` 節 1 項目を追加。

挿入位置: 既存 `### Changed` 末尾（L15 末尾）と `---`（L17）の間

#### 修正前（L10-L17）

```markdown
## [2.4.0] - 2026-04-XX

### Changed

- `bin/update-version.sh` の更新対象から `.aidlc/config.toml.starter_kit_version` を除外（hidden breaking change）。`starter_kit_version` は `aidlc-setup` / `aidlc-migrate` / 将来のアップグレード経路でのみ書き換わる「最後に実行した setup のバージョン」を表す値となり、リリース時の上書きが廃止される。これによりメタ開発リポジトリでバージョン三角検証（local / skill / remote）が正しく機能する（#596 / Unit 002 / Unit 003）
- `bin/update-version.sh` の出力フォーマットから `aidlc_toml_current` / `aidlc_toml_new` / `aidlc_toml:${VERSION}` 行を削除（hidden breaking change）。これらの行に依存する自動化や手順書を持つ利用者は v2.4.0 アップグレード時に追従修正が必要（#596 / Unit 002 / Unit 003）

---
```

#### 修正後（挿入版）

```markdown
## [2.4.0] - 2026-04-XX

### Changed

- `bin/update-version.sh` の更新対象から `.aidlc/config.toml.starter_kit_version` を除外（hidden breaking change）。`starter_kit_version` は `aidlc-setup` / `aidlc-migrate` / 将来のアップグレード経路でのみ書き換わる「最後に実行した setup のバージョン」を表す値となり、リリース時の上書きが廃止される。これによりメタ開発リポジトリでバージョン三角検証（local / skill / remote）が正しく機能する（#596 / Unit 002 / Unit 003）
- `bin/update-version.sh` の出力フォーマットから `aidlc_toml_current` / `aidlc_toml_new` / `aidlc_toml:${VERSION}` 行を削除（hidden breaking change）。これらの行に依存する自動化や手順書を持つ利用者は v2.4.0 アップグレード時に追従修正が必要（#596 / Unit 002 / Unit 003）

### Removed

- `skills/aidlc-setup/steps/01-detect.md` から `prompts/package/` ディレクトリへの言及（メタ開発モード判定の旧条件）を純削除。`prompts/package/` は v2.0.5 で削除済み（#449）であり、判定式として無効だった。代替判定条件（例: `version.txt` + `.claude-plugin/` ベース）の追加は本 Unit 対象外であり、必要性が確認された場合は v2.5.0 以降のバックログ Issue で別扱いとする（#595 / Unit 004）

---
```

注: Keep a Changelog 標準順序（Added / Changed / Deprecated / Removed / Fixed / Security）に準拠して `### Changed` の直後に `### Removed` を配置する。後続 Unit 001 完了処理（`### Fixed` の `#588` 節）/ Unit 005/006/007（`### Added` 等）が必要に応じて他見出しを追加する余地を残す。

## 動作確認手順

plan「動作確認手順」セクション L76-L153 を **原文転記** する（節構成・コメント・期待値注記まで完全一致）。

---

Unit 定義 L15-L19 の 3 ケース + 影響評価で追加した (d) ケースを **実 fixture ベース** で検証する。`/aidlc setup` の完全実行ではなく、削除後 01-detect.md の早期判定セクション（L93 以降）の **分岐条件述語** を fixture 上で確認することにスコープを限定する（分岐遷移そのものではない）。

### 検証スコープ限定

本 Unit のスコープは **L89-L91 純削除と、早期判定 #1/#3 の分岐条件述語の成立確認** までである。早期判定 #1 内の 1a バージョン比較フロー（dasel 取得・version.txt 比較・アップグレードモード遷移メッセージ）の検証は本 Unit 対象外（既存挙動として維持される）。

### Fixture 準備

```bash
# (a) メタ開発リポジトリ dev worktree（config.toml 既存）
FIXTURE_A=/Users/keisuke/repos/github.com/ikeisuke/ai-dlc-starter-kit/.worktree/dev
test -f "$FIXTURE_A/.aidlc/config.toml" && echo "(a) ok"

# (b) 外部プロジェクト想定 + config.toml あり
FIXTURE_B=$(mktemp -d /tmp/aidlc-setup-test-b.XXXXXX)
mkdir -p "$FIXTURE_B/.aidlc"
printf '[project]\nname = "test-b"\nstarter_kit_version = "2.4.0"\n' > "$FIXTURE_B/.aidlc/config.toml"
test -f "$FIXTURE_B/.aidlc/config.toml" && echo "(b) ok"

# (c) 外部プロジェクト想定 + config.toml / v1 toml なし
FIXTURE_C=$(mktemp -d /tmp/aidlc-setup-test-c.XXXXXX)
echo "(c) prepared at $FIXTURE_C"

# (d) ai-dlc-starter-kit 配下シミュレーション + config.toml なし（メタ開発新規セットアップ前を想定）
# パス文字列に `ai-dlc-starter-kit` を含むのは「ケース (d) の説明用ラベル」であり、
# 現行 01-detect.md はパス判定をしていないため挙動には影響しない
FIXTURE_D=$(mktemp -d /tmp/aidlc-setup-test-d-ai-dlc-starter-kit.XXXXXX)
echo "(d) prepared at $FIXTURE_D"
```

### 期待分岐検証

各 fixture について、削除後 01-detect.md の早期判定セクションを評価する:

| ケース | 検証コマンド | 期待結果 |
|--------|------------|---------|
| (a) | `test -f "$FIXTURE_A/.aidlc/config.toml"` | exit 0 → 早期判定 #1「`.aidlc/config.toml` が存在する場合」の前提条件が成立（1a 以降のバージョン比較・遷移メッセージは本 Unit 検証対象外） |
| (b) | `test -f "$FIXTURE_B/.aidlc/config.toml"` | exit 0 → 早期判定 #1 の前提条件が成立（同上） |
| (c) | `! test -f "$FIXTURE_C/.aidlc/config.toml" && ! test -f "$FIXTURE_C/docs/aidlc.toml" && ! test -f "$FIXTURE_C/docs/aidlc/project.toml"` | exit 0（3 条件全て不在）→ 早期判定 #3「いずれも存在しない場合 → 初回セットアップ」の前提条件が成立 |
| (d) | `! test -f "$FIXTURE_D/.aidlc/config.toml" && ! test -f "$FIXTURE_D/docs/aidlc.toml" && ! test -f "$FIXTURE_D/docs/aidlc/project.toml"` | exit 0（3 条件全て不在）→ 早期判定 #3 の前提条件が成立 |

(c) と (d) の判定式は同一（`ai-dlc-starter-kit` パス文字列はラベルのみで挙動には影響しない）。(d) における旧 L89-L91 文言喪失の影響は、本「分岐条件述語の確認」では検出できないため、後述「削除内容直接検証」の文言差分確認手順で代替する。

### 削除内容直接検証

削除後の 01-detect.md に対して:

```bash
grep -c "prompts/package" skills/aidlc-setup/steps/01-detect.md  # 期待値: 0
grep -c "メタ開発モード" skills/aidlc-setup/steps/01-detect.md   # 期待値: 0
grep -c "ai-dlc-starter-kit.*リポジトリ内の場合" skills/aidlc-setup/steps/01-detect.md  # 期待値: 0
```

### 早期判定セクション残存確認

削除影響が L93 以降に及んでいないことを確認:

```bash
# 早期判定見出しが残存
grep -c "### 早期判定（ユーザー確認の前に実行）" skills/aidlc-setup/steps/01-detect.md  # 期待値: 1
# 早期判定 #1 が残存
grep -c "1\. \`.aidlc/config.toml\` が存在する場合" skills/aidlc-setup/steps/01-detect.md  # 期待値: 1
# 早期判定 #3 が残存
grep -c "3\. いずれも存在しない場合" skills/aidlc-setup/steps/01-detect.md  # 期待値: 1
```

### CHANGELOG 検証

```bash
grep -c "Unit 004" CHANGELOG.md     # 期待値: 既存 Unit 004 言及数 + 1
grep -c "prompts/package" CHANGELOG.md  # 期待値: 既存数（v2.0.5 既存記録）+ 1（v2.4.0 #595 節）
# v2.4.0 セクションに #595 節があるか
awk '/^## \[2.4.0\]/,/^## \[2.3.6\]/' CHANGELOG.md | grep -c "#595"  # 期待値: 1
```

### Fixture クリーンアップ

```bash
rm -rf "$FIXTURE_B" "$FIXTURE_C" "$FIXTURE_D"
```

## 整合性

### Unit 003 完了状態との整合

- CHANGELOG v2.4.0 セクション骨組み（`## [2.4.0] - 2026-04-XX` ヘッダ + `### Changed` + `#596` 節 2 項目）は Unit 003 で既に追加済み（commit 2ca41bf7）
- 本 Unit 004 では `### Changed` 節の直後に `### Removed` 見出しを新規追加し、`#595` 節 1 項目を記載
- `---` 区切り（L17）はそのまま維持される

### 削除影響評価との整合

- plan「削除に伴う影響評価」表 (a)/(b)/(c)/(d) の挙動マトリクス通り
- 動作確認手順は plan の検証スコープ「分岐条件述語の成立確認まで」に揃える
- (d) ケースの旧 L89-L91 文言喪失影響は「削除内容直接検証」の grep で代替検出

## 不明点と質問

なし（plan 段階で codex AI レビュー 5 反復を経て検証スコープ・動作確認手順を確定済み）。
