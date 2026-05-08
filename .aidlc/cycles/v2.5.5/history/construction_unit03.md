# Construction Phase Unit 003 履歴

## Unit 概要

- **Unit**: 003 — Construction Unit 完了処理 step5↔step8 分裂の構造的予防
- **関連 Issue**: #654 / DR-002（write-history.sh 自身が判定主体）
- **担当**: AI-DLC エージェント
- **着手日**: 2026-05-08
- **完了日**: 2026-05-08

## 概要

`steps/construction/04-completion.md` ステップ 5（履歴記録）と ステップ 8（コミット）の関係を文書整合 + commit-flow チェックリスト + write-history 警告経路の三層化で構造的予防する。v1.15.1 cycle で発生した 5 Unit × 2 commit = 10 commit 分裂 + rebase fixup（破壊的操作）の再発を防ぐ。

## 変更ファイル一覧

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/scripts/write-history.sh` | 改修（line 512-571 関数追加 + line 1037-1041 呼び出し） | `check_history_staged_status()` 専用関数を新規定義し、`main` の `--mode base` 正常終了フックから呼び出し。symlink 解決 + repo-root 相対正規化 + grep -Fxq 完全一致判定。warning 契約に従い stderr 一本化、exit 0 維持 |
| `skills/aidlc/steps/construction/04-completion.md` | 改修（line 80-91 / 144-147） | ステップ 5（履歴記録）に「履歴ファイルを必ず Unit 完了 commit に含める」整合性注記 + DR-002 / `check_history_staged_status()` 参照を追加。ステップ 8（Gitコミット）に事前確認手順（`git status` / `git diff --cached --name-only` 経由）を追加 |
| `skills/aidlc/steps/common/commit-flow.md` | 改修（line 118-135） | コミット前確認チェックリストに「履歴ファイル staged 確認」項目を追加（自動判定への参照を含む）。「履歴ファイル staged 確認のドライラン手順」セクション追加（(d-1) write-history 実行 / (d-2) staged 確認 / (d-3) 未 staged 時の対応） |
| `tests/write-history-history-staged-warning.bats` | 新規作成（3 ケース） | (a) unstaged → stderr warning（完全一致 assert）+ exit 0 / (b) staged → 警告なし + exit 0 / (c) git リポジトリ外 → 警告スキップ + exit 0 |
| `.aidlc/cycles/v2.5.5/plans/unit-003-plan.md` | 新規作成 | Unit 003 計画（三層防御 + warning 契約 SoT + ドリフト検知 + フォローアップ事項） |
| `.aidlc/cycles/v2.5.5/design-artifacts/domain-models/unit_003_construction_history_commit_split_prevention_domain_model.md` | 新規作成 | ドメインモデル（StagedStatus 正規化契約 / HistoryStagedStatusChecker / 多重防御の独立性再定義 / A/B 共通故障モード明示） |
| `.aidlc/cycles/v2.5.5/design-artifacts/logical-designs/unit_003_construction_history_commit_split_prevention_logical_design.md` | 新規作成 | 論理設計（4 ステップ正規化 pseudo / fixture / 検証クエリ / B 層機械判定化将来拡張点） |

## レビュー履歴

### 計画レビュー（reviewing-construction-plan）

| Round | 指摘件数 | 対応 |
|-------|---------|------|
| Round 1 | 3 件（中 2 / 低 1） | 全件修正対応（#1: warning 契約 SoT セクション追加で stderr 一本化明文化 / #2: check_history_staged_status() 関数化と base 完了フック記述に書き換え / #3: レイヤー間トレーサビリティ + ドリフト検知 grep 追加） |
| Round 2 | 0 件 | 2R clean、auto_approved |

### 設計レビュー（reviewing-construction-design）

| Round | 指摘件数 | 対応 |
|-------|---------|------|
| Round 1 | 2 件（高 1 / 中 1） | 全件修正対応（#1: StagedStatus 判定方式に repo-root 相対正規化の 4 ステップ明記 + 論理設計 pseudo 統一 / #2: 多重防御の独立性を「実装主体 / 検知トリガー / 失敗モード」表で再定義、A/B 共通故障モード明示、B 層機械判定化を将来拡張として追記） |
| Round 2 | 0 件 | 2R clean、auto_approved |

### コードレビュー（reviewing-construction-code）

| Round | 指摘件数 | 対応 |
|-------|---------|------|
| Round 1 | 2 件（高 1 / 中 1） | 全件修正対応（#1: `\|\| true` + `$?` パターンを `if ! cmd; then ... fi` に書き換え、判定不能スキップを正しく機能させる / #2: bats Case (b) を `! grep -qF "warning..."` 必須 assert に再設計） |
| Round 2 | 0 件 | 2R clean、auto_approved |

### 統合レビュー（reviewing-construction-integration）

| Round | 指摘件数 | 対応 |
|-------|---------|------|
| Round 1 | 2 件（中 1 / 低 1） | 全件修正対応（#1: Case (a) で HISTORY_PATH 抽出 + `grep -Fxq` 完全一致 assert に強化 / #2: Case (b) に「仕様妥協の明示」コメント追加、過去 index 登録があれば staged 判定の妥協を運用前提と併記） |
| Round 2 | 0 件 | 2R clean、auto_approved |

## 検証結果

### テスト

- `bats tests/write-history-history-staged-warning.bats`: 3 ケースすべて PASS
  - (a) unstaged → stderr warning 完全一致 + exit 0
  - (b) staged → 警告なし + exit 0
  - (c) git リポジトリ外 → 警告スキップ + exit 0
- `bats tests/write-history-modes.bats`: 15/15 PASS（regression なし）
- `bats tests/aidlc-helpers-zsh-source.bats`: 6/6 PASS（regression なし）
- bash 構文チェック (`bash -n skills/aidlc/scripts/write-history.sh`): OK

### ドリフト検知 grep（4 ファイル相互参照）

| ファイル | キーワードヒット |
|---------|----------------|
| `skills/aidlc/steps/construction/04-completion.md` | DR-002, check_history_staged_status, warning: history file unstaged（line 84, 87, 146）|
| `skills/aidlc/steps/common/commit-flow.md` | DR-002, check_history_staged_status, 履歴ファイル staged（line 126, 128）|
| `skills/aidlc/scripts/write-history.sh` | check_history_staged_status, warning: history file unstaged, DR-002（line 512, 517, 520, 567, 1038）|
| `tests/write-history-history-staged-warning.bats` | check_history_staged_status, warning: history file unstaged, DR-002（line 2, 9, 81 他）|

すべてのファイルで相互参照キーワードが検出されたため、ドキュメントドリフト検知ルールに合致。

## 三層防御の独立性（ドメインモデル §「多重防御の意味」より）

| 層 | 実装主体 | 検知トリガー | 主な失敗モード |
|----|---------|------------|--------------|
| A | 文書（04-completion.md）/ 人間の読み手 | ステップ 5/8 説明文を読む | 文書未参照、ドキュメントドリフト |
| B | 文書（commit-flow.md チェックリスト）/ 人間の手動確認 | コミット前チェックリスト実行 | 手順スキップ |
| C | 実装（write-history.sh / `check_history_staged_status()`）/ 自動判定 | `--mode base` 完了時に git diff で機械判定 | git リポジトリ外実行 |

A / B 層の共通故障モード（同種依存）を明示し、真の独立性は A 系（人間）と C 系（機械）の 2 系統である事実を記録。

## 仕様妥協（統合レビュー Round 1 指摘 #2 対応）

`check_history_staged_status` の判定は「`git diff --cached --name-only` の出力に対象パスが含まれるか」で行う。これは「過去に一度でも index に登録されていれば staged 判定」となり、**write-history 2 回目 append 後の最新変更が staged 済みかまでは検証しない**。理由:

- step5↔step8 分裂の主因は「初回 write-history で履歴ファイルを作成 → git add 漏れ → commit に含まれない」のパターン
- 上記主因に対しては「初回 append + git add → 2 回目 append → commit」の運用が想定され、初回 add 時に index 登録があれば以降の append でも warning なし（追加 add は人間の自然な操作）
- 「最新変更も staged」を厳密に検証する仕様にすると、append のたびに warning が出て本来の警告意図が薄れる

本妥協は計画書 § warning 契約および bats Case (b) コメントに明記。

## フォローアップ事項

### B 層の機械判定化（将来拡張点）

A / B 層は人間確認に依存し独立性が不完全。pre-commit hook（`.git/hooks/pre-commit`）で履歴ファイル更新があったが staged されていない場合に commit を中断する半自動化が、より強固な防御層となる。本 Unit ではスコープ外（次サイクル候補）。詳細は論理設計 §「将来拡張点」参照。トリガー: 同種事故再発、または開発者からの要望発生時。

### symlink 解決の依存

macOS の `/tmp` → `/private/tmp` 等の symlink 経由パスでも判定が成立するよう、`pwd -P` で実体パス化してから比較する仕様。コードレビュー Round 1 修正 + bats Case (a) で実証済み。`realpath` は POSIX 非標準のため不採用。

## 完了条件チェックリスト充足状況

| 区分 | 項目 | 状態 |
|------|------|------|
| 機能整合 A | 04-completion.md ステップ 5 注記追加 | ✓ |
| 機能整合 A | 04-completion.md ステップ 8 事前確認追加 | ✓ |
| 機能整合 B | commit-flow.md チェックリスト項目追加 | ✓ |
| 機能整合 B | ドライラン手順 3 点固定 | ✓（(d-1)/(d-2)/(d-3)）|
| 機能整合 C | check_history_staged_status() 専用関数定義 | ✓（write-history.sh:520） |
| 機能整合 C | --mode base 完了フックから呼び出し | ✓（write-history.sh:1041） |
| 機能整合 C | warning 契約準拠の stderr 出力 | ✓（line 567 完全一致 SoT 文言） |
| 機能整合 C | git diff 失敗時の warning スキップ | ✓ |
| 機能整合 C | exit 0 維持 | ✓ |
| 機能整合 C | --mode unit-complete-short-note / operations-round 非適用 | ✓（line 1040 if 文で base 限定） |
| テスト | 3 ケース実装 + PASS | ✓ |
| テスト | regression なし | ✓（既存 21 ケース全 PASS） |
| ドリフト検知 | 4 ファイル相互参照 grep | ✓ |
| 履歴 | 本ファイル新規作成 | ✓ |
| 品質ゲート | AI レビュー 4 種すべて 2R clean | ✓ |
| 品質ゲート | markdownlint | （完了処理ステップで実施） |

## 備考

- 4 種レビュー全て Round 2 で clean 達成。defer Issue 起票なし
- 三層防御の構造的設計と独立性検討は将来同種課題（commit 分裂系）の reference design として活用可能
- DR-002 の「write-history.sh 自身が判定主体」を文書 / 実装 / テストの相互参照で固定
