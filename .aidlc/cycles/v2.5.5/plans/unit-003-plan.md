# Unit 003 計画: Construction Unit 完了処理 step5↔step8 分裂の構造的予防

## 概要

Construction Phase の Unit 完了処理において、ステップ 5（履歴記録 / `write-history`）の成果物がステップ 8（Git コミット）の commit に含まれず、別 commit に分裂する事故を構造的に予防する。提案 A（文書整合）+ B（チェックリスト追加）+ C（write-history 警告）の三層化で多重防御を実現し、v1.15.1 cycle で発生した 5 Unit × 2 commit = 10 commit 分裂 + rebase fixup（破壊的操作）の再発を防ぐ。

## 関連 Issue

- #654（[Feedback] Unit 完了処理のステップ 5（履歴記録）と ステップ 8（コミット）の関係が曖昧で commit が分裂しやすい）
- 関連 DR: DR-002（write-history.sh 自身が判定主体）

## 責務分離原則（三層化）

| レイヤ | 役割 | ファイル |
|--------|------|---------|
| 提案 A: 文書整合 | ステップ 5/8 の関係を「履歴ファイルを必ず Unit 完了 commit に含める」と明示 | `skills/aidlc/steps/construction/04-completion.md`（ステップ 5 / ステップ 8 / 完了基準） |
| 提案 B: チェックリスト | コミット前確認に「履歴ファイル staged 確認」項目追加 + ドライラン手順 3 点固定 | `skills/aidlc/steps/common/commit-flow.md` |
| 提案 C: 警告経路 | write-history.sh の **`check_history_staged_status()` 専用関数**（`--mode base` 正常終了フック）が staged 確認 + 警告出力。インターフェース契約は次節「warning 契約」を SoT とする | `skills/aidlc/scripts/write-history.sh` |
| テスト | write-history.sh 警告経路の動作確認（unstaged → 警告 / staged → 警告なし / git diff 失敗 → 警告スキップ） | `tests/write-history-history-staged-warning.bats`（新規） |
| 履歴 | 実装進捗・三層防御の構造記録 | `.aidlc/cycles/v2.5.5/history/construction_unit03.md` |

**ドリフト防止策**:

- 提案 A / B / C は独立して動作する（読み飛ばし耐性）。1 層の見落としを他層で補完
- write-history.sh 警告は `exit 0` 維持で後方互換性完全保持（既存 caller の処理を破壊しない）

### warning 契約（Round 1 指摘 #1 対応 / SoT）

write-history.sh の staged 警告は以下の契約を持ち、Unit 定義 / 計画 / 設計 / 実装 / テスト fixture 期待値はすべて本契約を SoT として参照する:

| 項目 | 契約 |
|------|------|
| 出力先 | **stderr 一本化**（stdout は既存 `history:<path>:created/appended` 出力のみ、警告は混在させない） |
| 文言フォーマット | `warning: history file unstaged: <絶対パス>`（半角スペース区切り、コロン 2 個） |
| exit code | **0 維持**（既存 caller の挙動を破壊しない後方互換契約） |
| トリガー条件 | `--mode base` 通常パス完了直後 + `git diff --cached --name-only -- "$filepath"` の出力に `$filepath` が含まれない（unstaged 判定） |
| 警告スキップ条件 | `git diff` 自体が exit 非 0（git リポジトリ外 等）の場合は警告スキップ + exit 0 維持（後方互換性保護） |
| 適用 mode | `--mode base` のみ。`--mode unit-complete-short-note` / `--mode operations-round` には適用しない（mode 固有の別経路を妨げない） |

> **Unit 定義との整合**: Unit 定義「責務」セクションでは「stdout/stderr に出力」と表現されているが、本計画では **stderr 一本化** に確定する。実装インターフェース統一のための解釈確定であり、Unit 定義の「stdout/stderr」は「(stderr を含む) 標準的な警告出力チャネル」の意図と読み替える（Unit 履歴で経緯を記録）。

### レイヤー間トレーサビリティ（Round 1 指摘 #3 対応）

提案 A / B（文書）が提案 C（実装）の挙動を参照する形を取り、ドキュメントドリフトを抑制する:

- `04-completion.md` ステップ 5 注記内に「判定主体は `scripts/write-history.sh`（DR-002）。警告契約は計画ファイル `unit-003-plan.md` § warning 契約 を参照」を追記
- `commit-flow.md` のチェックリスト項目に「履歴ファイル staged 確認（**自動判定**: `write-history.sh` が `--mode base` 完了時に stderr 警告を出力。詳細は `scripts/write-history.sh` の `check_history_staged_status()` を参照）」を追記
- ドリフト検知用の grep クエリを論理設計の「検証クエリ」セクションで定義（`grep "DR-002\|check_history_staged_status\|warning: history file unstaged" <対象ファイル群>` で文書 / 実装 / テストの整合を機械的にチェック）

### 提案 D の取り扱い（OUT_OF_SCOPE）

提案 D（ステップ 8 への `git add` 明示手順追加）は提案 A の自然な帰結として吸収するため、独立記述しない。ステップ 8 のコミット前確認に「履歴ファイル staged 確認」（提案 B）が含まれることで、ユーザーは `git add` の必要性に自然に気付く。Intent §「除外するもの」に明記済み（ルール重複・矛盾の回避）。

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/steps/construction/04-completion.md` | 改修（提案 A） | ステップ 5（履歴記録）と ステップ 8（Gitコミット）の説明に「履歴ファイルを必ず Unit 完了 commit に含める」旨の注記を追加。完了基準にも整合性表現を追加 |
| `skills/aidlc/steps/common/commit-flow.md` | 改修（提案 B） | 「コミット前確認チェックリスト」に「履歴ファイル staged 確認」項目を追加。ドライラン手順を 3 点固定で文書化（**(d-1)** write-history 実行手順への参照、**(d-2)** `git status` または `git diff --cached --name-only` で staged 確認、**(d-3)** 履歴ファイル `git add` 確認） |
| `skills/aidlc/scripts/write-history.sh` | 改修（提案 C） | **`check_history_staged_status()` 専用関数を新規定義**し、`main` 関数の `--mode base` 正常終了フック（最終 `echo "history:..."` 直前または `exit 0` 直前）から呼び出す。関数内で `git diff --cached --name-only -- "$filepath"` で staged 判定し、unstaged 時に warning 契約に従って stderr 出力。`git diff` 失敗時は警告スキップで exit 0 維持。**実装位置を「行番号」ではなく「base 完了フック」で記述する** |
| `tests/write-history-history-staged-warning.bats` | 新規作成（テスト） | write-history.sh の `--mode base` 経路で 3 ケース検証: (a) unstaged → stderr 警告 + exit 0 / (b) staged → 警告なし + exit 0 / (c) git diff 失敗（git リポジトリ外）→ 警告スキップ + exit 0 |
| `.aidlc/cycles/v2.5.5/history/construction_unit03.md` | 新規作成 | Unit 003 進捗履歴（変更ファイル / レビュー round / 検証結果 / 三層防御の有効性） |

## 実装計画

### Phase 1（設計）

設計成果物として以下を作成する:

- ドメインモデル（`design-artifacts/domain-models/unit_003_construction_history_commit_split_prevention_domain_model.md`）: `履歴ファイル staged 状態` のドメイン語彙整理（staged / unstaged / 警告レベル / git diff 失敗時の安全側挙動）。多重防御パターンの構造図化
- 論理設計（`design-artifacts/logical-designs/unit_003_construction_history_commit_split_prevention_logical_design.md`）: 04-completion.md / commit-flow.md / write-history.sh の各改修箇所の文言確定、bats テスト構造、検証 grep クエリ

`depth_level=standard` のため Phase 1 はスキップしない。設計レビュー（`reviewing-construction-design`）を 5R 内で実施する。

### Phase 2（実装）

実装順序:

1. `04-completion.md` 改修（提案 A: ステップ 5/8 注記 + 完了基準補足 + DR-002 / `check_history_staged_status()` 参照リンク）
2. `commit-flow.md` 改修（提案 B: チェックリスト 1 項目追加 + ドライラン手順 3 点固定 + 自動判定への参照）
3. `write-history.sh` 改修（提案 C: `check_history_staged_status()` 関数新規定義 + `--mode base` 完了フックから呼び出し）
4. `tests/write-history-history-staged-warning.bats` 新規作成（3 ケース、warning 契約 SoT を期待値とする）
5. テスト実行（既存テストへの regression 確認を併せて）
6. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）
7. 履歴記録 + ドリフト検知 grep クエリ実行ログ記録

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| write-history.sh が git リポジトリ外で実行される | `git diff --cached --name-only` が exit 非 0 を返す。stderr を捨てて警告スキップし exit 0 維持 |
| `filepath` がリポジトリ外（絶対パス指定で別ディレクトリを指す） | `git diff --cached --name-only -- "$filepath"` は空を返す（ファイルが index に含まれないため）。本仕様では unstaged として警告出力（後続の `git add` ガイドが妥当） |
| 警告メッセージの機密情報リスク | 履歴ファイルパスのみ含み、機密情報は含まれない |
| 既存 caller の挙動変化 | 警告は stderr 出力のみ、exit 0 維持。stdout の `history:<path>:created/appended` 出力は既存通り。caller が stderr を grep していなければ挙動不変 |
| commit-flow.md チェックリストの文言衝突 | 既存項目のリネーム / 削除は行わず、追加のみ。重複検出のため `grep -n "履歴ファイル" commit-flow.md` で既存表現と差別化 |

## NFR

- **パフォーマンス**: write-history.sh 末尾に `git diff` 1 回追加。実行時間影響無視可能（< 100ms 想定）
- **セキュリティ**: 該当なし（履歴ファイルパスは機密情報を含まない、既存 write-history 出力と同レベル）
- **後方互換**: write-history.sh は exit 0 / stdout 出力契約を維持。stderr 警告のみ追加で caller への影響なし

## 完了条件チェックリスト

### 機能整合（提案 A: 04-completion.md）

- [ ] `04-completion.md` ステップ 5 の説明に「履歴ファイルを必ず Unit 完了 commit に含める」旨の注記が含まれている
- [ ] `04-completion.md` ステップ 8 の説明に同等の注記または「ステップ 5 で作成された履歴ファイルが staged されていることを確認」が含まれている
- [ ] `04-completion.md` 完了基準に履歴ファイル整合性表現が追加されている

### 機能整合（提案 B: commit-flow.md）

- [ ] `commit-flow.md` のコミット前確認チェックリストに「履歴ファイル staged 確認」項目が 1 項目以上追加されている
- [ ] ドライラン手順 3 点固定（(d-1) write-history 実行参照 / (d-2) `git status` または `git diff --cached --name-only` / (d-3) `git add` 確認）が記載されている

### 機能整合（提案 C: write-history.sh）

- [ ] `write-history.sh` に `check_history_staged_status()` 関数が新規定義されている（`main` 末尾インライン記述ではなく専用関数）
- [ ] `main` の `--mode base` 正常終了フックから `check_history_staged_status()` が呼び出されている
- [ ] warning 契約 SoT に従い、unstaged 検出時に `warning: history file unstaged: <絶対パス>` が **stderr のみ** に出力される（stdout 出力なし）
- [ ] `git diff` 失敗時は警告スキップで exit 0 維持
- [ ] 既存 stdout 出力（`history:<path>:created/appended`）に影響なし
- [ ] `--mode unit-complete-short-note` / `--mode operations-round` には警告経路を適用しない（mode 固有経路を妨げない）

### テスト

- [ ] `tests/write-history-history-staged-warning.bats` が新規作成され、以下 3 ケースを含む:
  - (a) unstaged → stderr に `warning: history file unstaged: <絶対パス>` を出力 + exit 0（stdout 側には warning が含まれないことも assert）
  - (b) staged → stderr に warning なし + exit 0
  - (c) git diff 失敗（git リポジトリ外）→ stderr に warning なし + exit 0（警告スキップ）
- [ ] 既存 bats テストが PASS（regression なし）

### ドリフト検知（Round 1 指摘 #3 対応）

- [ ] 文書 / 実装 / テスト相互参照の grep 検知:
  - `grep -nE "DR-002\\|check_history_staged_status\\|warning: history file unstaged" skills/aidlc/steps/construction/04-completion.md skills/aidlc/steps/common/commit-flow.md skills/aidlc/scripts/write-history.sh tests/write-history-history-staged-warning.bats` を実行し、各ファイルに少なくとも 1 つのキーワードがヒットすることを確認
  - 結果を Unit 履歴 `construction_unit03.md` に記録

### 履歴

- [ ] `.aidlc/cycles/v2.5.5/history/construction_unit03.md` が新規作成され、変更ファイル / レビュー round / 検証結果 / 三層防御の有効性が記録されている

### 品質ゲート

- [ ] AI レビュー（`reviewing-construction-design` / `reviewing-construction-code` / `reviewing-construction-integration`）が完了条件を満たす
- [ ] markdownlint が変更対象 markdown ファイルで pass

## 見積もり

- 設計フェーズ: 0.25 日（domain model / logical design / 各改修箇所の文言確定）
- 実装フェーズ: 0.75 日（文書 2 ファイル改修 + write-history.sh 警告経路 + bats 3 ケース + レビュー）
- 合計: **1 日**（Unit 定義の見積もり「2〜3 時間」よりやや多めだが、3 ファイル改修 + テスト追加の合計として妥当）
