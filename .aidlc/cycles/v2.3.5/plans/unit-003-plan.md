# Unit 003 実行計画: merge-pr `--skip-checks` オプション追加

## 対象Unit

- **Unit 定義**: `.aidlc/cycles/v2.3.5/story-artifacts/units/003-merge-pr-skip-checks.md`
- **関連Issue**: #575（[Feedback] operations-release.sh merge-pr がCIチェック未設定リポジトリで失敗する）
- **優先度**: High / 見積もり: S（Small）
- **依存する Unit**: Unit 002（同一ファイル `scripts/operations-release.sh` 更新のため並行禁止、完了済み）

## 背景・目的

### 現状の挙動（Unit 002 完了時点）

現行 `pr-ops.sh` の `cmd_merge()`（`skills/aidlc/scripts/pr-ops.sh` L277-287）は、CI チェック状態を以下の方法で取得する:

```bash
checks_output=$(gh pr checks "$pr_number" --required --json bucket --jq \
  '[.[].bucket] | if length == 0 then "pass" elif all(. == "pass") then "pass" elif any(. == "pending") then "pending" else "fail" end' \
  2>/dev/null) || true
checks_status="${checks_output:-unknown}"
```

取得に失敗（gh コマンドが非ゼロ exit、stderr 出力、ネットワーク障害、認証エラー等）した場合、`checks_output` は空となり `checks_status="unknown"` にフォールバックして `pr:<N>:error:checks-status-unknown` で exit 1 する（fail-closed）。

### 現状 `unknown` バケットの問題（レビュー指摘 #1 対応）

現状の `checks_status="unknown"` は `gh pr checks` のあらゆる非ゼロ exit をまとめてこのバケットに入れており、以下のような質の異なる原因が混在している:

| 真因 | 現状の分類 | 望ましい分類 |
|------|----------|-------------|
| 必須チェックが一つも設定されていないリポジトリ（stderr: `no checks reported`、exit 1） | `unknown` | `no-checks-configured`（CI 未設定: 安全にバイパス可能） |
| `gh` ネットワーク障害、GitHub API 500 系、認証失効 | `unknown` | `checks-query-failed`（原因不明: バイパス禁止） |

このままでは `--skip-checks` フラグを `unknown` 全体に適用した場合、ネットワーク障害や API 障害時にも CI をスキップしてマージされるリスクがある。Unit 定義の「安全性を損なわない」を満たすため、本 Unit では **`no-checks-configured` と `checks-query-failed` を分離**し、`--skip-checks` は前者のみに適用する。

### 問題の再現条件

`gh pr checks --required` は、必須チェックが一つも設定されていないリポジトリで `no checks reported` を stderr に出力し **exit 1** を返す。このとき stdout は空であり、上記の `|| true` でエラーを握りつぶした結果 `checks_output=""` → `checks_status="unknown"` → `error:checks-status-unknown` で中断する。この挙動は Issue #575 の「CIチェック未設定リポジトリで失敗する」に該当する。

### 本 Unit のゴール

- `pr-ops.sh cmd_merge()` の CI 状態取得ロジックを改修し、`gh pr checks` の stderr / exit code を捕捉して `no-checks-configured` と `checks-query-failed` を分離
- `operations-release.sh merge-pr` に `--skip-checks` フラグを追加し、`pr-ops.sh merge` に透過
- `--skip-checks` は **`no-checks-configured` の場合のみ** 即時マージを許可する（`checks-query-failed` / `fail` / `pending` は `--skip-checks` があっても従来通り）
- エラーメッセージを改善し、`--skip-checks` の存在と適用条件をユーザーに案内する
- **ドキュメント正本**: 実行フロー詳細は `steps/operations/operations-release.md` 7.13 節（既存正本）を更新。`steps/operations/03-release.md` は完了基準サマリの位置付けのため、必要に応じて軽微な参照のみ追加
- `guides/` 配下に挙動マトリクス含む新規ドキュメントを 1 箇所追加

### ドキュメント責務の整理（レビュー指摘 #2 対応）

`skills/aidlc/steps/operations/` の markdown は以下の責務分担になっている:

| ファイル | 責務 | 本 Unit での位置付け |
|---------|------|-------------------|
| `operations-release.md` | ステップ7リリース準備の**実行フロー詳細の正本**（7.1-7.13 節が 111 行にわたって記載） | `--skip-checks` の適用条件・エラー対処を記載する主対象 |
| `03-release.md` | ステップ7の**完了基準サマリ**（39 行、「ステップ7が PR 準備完了」「全ステップ完了」「コンテキストリセット提示完了」のみ） | 更新不要（完了基準に影響なし）。Unit 定義の「03-release.md に記載」は実行フロー詳細の正本（`operations-release.md`）への更新として整合解釈する |

本計画では **`operations-release.md` を正本**とし、Unit 定義の記述（「03-release.md に記載」）との齟齬は「実行フロー詳細の正本は `operations-release.md`」という論理解釈で整合させる。Codex 指摘 #2 の「二重管理」は発生しない（`03-release.md` は完了基準サマリで実行フロー詳細を持たない）。

## スコープ（責務）

Unit 定義「責務」セクションの全項目を本計画のスコープとする。

- `scripts/operations-release.sh cmd_merge_pr()` に `--skip-checks` オプションを追加し、`pr-ops.sh merge` に透過
- `scripts/pr-ops.sh cmd_merge()` の CI 状態取得を改修し、`no-checks-configured` と `checks-query-failed` を分離
- `scripts/pr-ops.sh cmd_merge()` に `--skip-checks` 受領経路を追加し、`no-checks-configured` の場合のみ即時マージを許可
- CI 状態が `failed` / `pending` / `checks-query-failed` / 既知エラー系の場合、`--skip-checks` 指定の有無に関わらず従来通りエラー終了（安全性を損なわない）
- エラーメッセージに `--skip-checks` の存在と適用条件（「`no-checks-configured` のみ対象。`failed` / `pending` / `checks-query-failed` ではバイパスされません」）を案内
- `print_help_merge_pr()`（`operations-release.sh` L159-185）の Options 欄と Behavior 欄に `--skip-checks` の説明と適用条件を追加
- `scripts/pr-ops.sh` の `show_help()` 内 `merge` サブコマンドヘルプに `--skip-checks` の説明と適用条件を追加
- `steps/operations/operations-release.md` 7.13 節に `merge-pr` の前提条件と `--skip-checks` の適用条件を記載（正本）
- `skills/aidlc/guides/` 配下に `merge-pr` の挙動サマリ（挙動マトリクス含む）を 1 箇所追加

## 状態モデルの確定（レビュー指摘 #3 対応）

### CI チェック状態の分類（最終確定）

本 Unit 実装後の `pr-ops.sh cmd_merge()` における CI 状態は以下の 5 分類とする:

| 状態 | 判定条件 | 新規/既存 |
|------|---------|----------|
| `pass` | `gh pr checks --required --json bucket --jq ...` が `"pass"` を返す（全 required pass または required が 0 件で bucket 配列が空） | 既存 |
| `fail` | 上記 jq が `"fail"` を返す | 既存 |
| `pending` | 上記 jq が `"pending"` を返す | 既存 |
| `no-checks-configured` | `gh pr checks` が exit 1 かつ stderr に `no checks reported` を含む（required / 非 required を含めて reportable なチェックが一つもない状態） | **新規（unknown から分離）** |
| `checks-query-failed` | `gh pr checks` が非ゼロ exit かつ上記 `no-checks-configured` に該当しない（ネットワーク / API / 認証エラー等） | **新規（unknown から分離）** |

**注**: 現状の `"unknown"` バケットは本 Unit 以降は発生しない。既存の `error:checks-status-unknown` 出力コードは、後方互換のためにエイリアスとして `checks-query-failed` 経路で再利用する（詳細は「エラーコード契約」参照）。

### `--skip-checks` の適用マトリクス（最終契約）

| CI 状態 | `--skip-checks` なし | `--skip-checks` あり |
|---------|---------------------|---------------------|
| `pass` | 即時マージ | 即時マージ（フラグ無視） |
| `fail` | `pr:<N>:error:checks-failed` で exit 1 | `pr:<N>:error:checks-failed` で exit 1（**バイパス禁止**） |
| `pending` | auto-merge 設定 | auto-merge 設定（フラグ無視） |
| `no-checks-configured` | `pr:<N>:error:checks-status-unknown` で exit 1（メッセージ改善、`--skip-checks` 誘導） | **即時マージを試行**（本 Unit の新規挙動） |
| `checks-query-failed` | `pr:<N>:error:checks-status-unknown` で exit 1 | `pr:<N>:error:checks-status-unknown` で exit 1（**バイパス禁止**） |

### `no-checks-configured` 即時マージ経路の確定

`--skip-checks` 指定 + `no-checks-configured` の場合、`pass` 経路と**同一実装**の即時マージを実行する:

```bash
# --match-head-commit を必ず付与（race condition 防止）
gh pr merge "$pr_number" "$merge_flag" --match-head-commit "$head_sha"
```

エラーハンドリングは既存の `pass` 経路と同じとし、`not-found` / `not-mergeable` / `review-required` / `head-mismatch` / `unknown` を透過する。新規分岐を切らず既存関数を再利用することで、ロジックの二重化を防ぐ。

### エラーコード契約（機械可読な外部契約）

既存の `pr:<N>:error:checks-status-unknown` は後方互換のため維持する。**加えて**、呼び出し元（`operations-release.md` や他スクリプト）が機械可読に分岐できるよう、直後に **安定した `reason:` 補助行** を必ず出力する契約を導入する。

#### 出力フォーマット契約

`error:checks-status-unknown` 系エラー発生時、以下の 2 行を連続出力する（順序固定: error 行 → reason 行）:

```text
pr:<N>:error:checks-status-unknown
pr:<N>:reason:<reason_code>
```

`<reason_code>` の有効値（固定列挙）:

| `reason_code` | 意味 | `--skip-checks` の適用可否 |
|---------------|------|--------------------------|
| `no-checks-configured` | `gh pr checks` が exit 1 かつ stderr に `no checks reported` を含む | 可能（即時マージ経路へ） |
| `checks-query-failed` | `gh pr checks` が非ゼロ exit で上記に該当しない（ネットワーク / API / 認証エラー等） | 不可（バイパス禁止） |

#### 呼び出し元の分岐契約

`operations-release.md` 7.13 節は、`error:checks-status-unknown` を検出した場合、続く `reason:<reason_code>` 行を**機械可読**にパースして以下の通り分岐する:

- `reason:no-checks-configured` → `AskUserQuestion` で「`--skip-checks` を付与して再実行 / 中断」の 2 択を提示
- `reason:checks-query-failed` → `AskUserQuestion` で「再試行 / 中断」を提示（`--skip-checks` オプションは**提示しない**）

この契約により、ヒント文言に依存せず機械的な分岐が可能になる。ヒント行（日本語文言）は人間向け補助情報として併出力する。

#### ヒント行（人間向け、補助情報）

`reason:` 行に続けて、人間向けの説明を `hint:` 行で出力する（機械可読判定には使用しない）:

```text
pr:<N>:error:checks-status-unknown
pr:<N>:reason:no-checks-configured
pr:<N>:hint:この PR では必須 CI チェックが設定されていません。`--skip-checks` を付与すると CI をバイパスしてマージできます。
```

```text
pr:<N>:error:checks-status-unknown
pr:<N>:reason:checks-query-failed
pr:<N>:hint:CI チェック状態の取得に失敗しました（ネットワークまたは API エラー）。時間を置いて再試行してください。`--skip-checks` では回避できません。
```

詳細文言は設計フェーズで最終確定する。

## 変更対象ファイル（論理設計でさらに詰める）

- `skills/aidlc/scripts/pr-ops.sh`
  - `cmd_merge()` の CI 状態取得ロジック改修（L277-287 付近）:
    - `gh pr checks` の stderr を取得
    - exit code とメッセージから `no-checks-configured` / `checks-query-failed` を分離
  - `cmd_merge()` に `--skip-checks` 引数パーサを追加
  - `no-checks-configured` + `--skip-checks` 時の即時マージ経路を追加（`pass` 経路と同一の実装を呼び出し）
  - `show_help()` 内 `merge` サブコマンドのヘルプに `--skip-checks` 説明を追加（L48 付近）
  - `error:checks-status-unknown` 出力時に `reason:<code>` 行（機械可読）と `hint:<text>` 行（人間向け）を追加出力
- `skills/aidlc/scripts/operations-release.sh`
  - `cmd_merge_pr()` に `--skip-checks` フラグ処理を追加（L572-641）
  - `pr-ops.sh merge` 呼び出し時に `--skip-checks` を透過
  - `print_help_merge_pr()` の Options / Behavior / エラーコード欄を更新（L159-185）
- `skills/aidlc/steps/operations/operations-release.md`（実行フロー詳細の正本）
  - 7.13 節（L81-111）に `merge-pr` の前提条件（CI 必須チェックの有無判定）と `--skip-checks` の適用条件を追加
  - エラー対処フロー（L111）の補強として、`error:checks-status-unknown` 出力時に**機械可読な `reason:<code>` 行**を解釈し、`reason:no-checks-configured` の場合のみ `AskUserQuestion` で「`--skip-checks` で再実行 / 中断」の 2 択を提示、`reason:checks-query-failed` の場合は「再試行 / 中断」のみ提示する分岐を追加
- `skills/aidlc/steps/operations/03-release.md`（完了基準サマリ）
  - 更新不要（完了基準に影響なし）。Unit 定義との整合は本計画「ドキュメント責務の整理」セクションで解消済み
- `skills/aidlc/guides/merge-pr-usage.md`（新規ファイル、ファイル名は設計フェーズで最終確定）
  - `merge-pr` の挙動マトリクス（CI 状態 × `--skip-checks` の有無）
  - 使い分けガイダンス（`--skip-checks` を使うべきケース / 使ってはいけないケース）
  - CI 状態分類の判定フロー（`no-checks-configured` vs `checks-query-failed`）
  - 失敗時のエラーコード一覧とユーザー対応

## 完了条件チェックリスト

### 実装

- [ ] `scripts/pr-ops.sh cmd_merge()` の CI 状態取得を改修し、`no-checks-configured` / `checks-query-failed` を分離
- [ ] `scripts/pr-ops.sh cmd_merge()` に `--skip-checks` 引数パーサを追加
- [ ] `no-checks-configured` + `--skip-checks` 時の即時マージ経路を実装（`pass` 経路と同一ロジック、`--match-head-commit` 付与）
- [ ] `fail` / `pending` / `checks-query-failed` + `--skip-checks` が**必ず拒否される**ことを実装レベルで確認
- [ ] `scripts/operations-release.sh cmd_merge_pr()` に `--skip-checks` フラグ処理を追加
- [ ] `error:checks-status-unknown` 出力時に機械可読な `pr:<N>:reason:<code>` 行（`no-checks-configured` / `checks-query-failed`）と `pr:<N>:hint:<text>` 行（人間向け）を追加出力

### ドキュメント

- [ ] `print_help_merge_pr()` の Options / Behavior / エラーコード欄を更新
- [ ] `scripts/pr-ops.sh show_help()` 内 `merge` サブコマンドに `--skip-checks` 説明を追加
- [ ] `steps/operations/operations-release.md` 7.13 節を更新（前提条件と `--skip-checks` の適用条件）
- [ ] `guides/merge-pr-usage.md`（仮称、ファイル名は設計で確定）を新規作成（挙動マトリクス含む）

### テスト

- [ ] `skills/aidlc/scripts/tests/test_pr_ops_merge_skip_checks.sh`（仮称）を追加
  - [ ] `pass` + フラグなし / あり → 即時マージ
  - [ ] `fail` + フラグなし / あり → `error:checks-failed`
  - [ ] `pending` + フラグなし / あり → auto-merge 設定
  - [ ] `no-checks-configured` + フラグなし → `error:checks-status-unknown` + `reason:no-checks-configured` + `hint:...` 行出力
  - [ ] `no-checks-configured` + フラグあり → 即時マージ
  - [ ] `checks-query-failed` + フラグなし / あり → `error:checks-status-unknown` + `reason:checks-query-failed` + `hint:...` 行出力（バイパスされない）
  - [ ] 出力順序契約（error → reason → hint の順）が保持されることを検証
- [ ] 既存の `pr-ops.sh merge` 挙動の回帰確認（フラグなしの既存呼び出しが変わらないこと）
- [ ] `operations-release.sh merge-pr --help` の手動確認

### 完了基準

- [ ] 計画レビュー Codex 承認（auto_approved）
- [ ] 設計レビュー Codex 承認（auto_approved）
- [ ] コードレビュー Codex 承認（auto_approved）
- [ ] 統合レビュー Codex 承認（auto_approved）
- [ ] 全テスト PASS
- [ ] 設計・実装整合性チェック完了
- [ ] Unit 定義ファイルの実装状態を「完了」に更新
- [ ] 履歴記録（`/write-history`）完了
- [ ] squash 完了 → commit 完了

## 依存 / 前提

- Unit 002 完了済み（`scripts/operations-release.sh` 改修が衝突なく適用可能）
- `gh` CLI（`gh pr checks --required --json bucket`、`gh pr merge --match-head-commit` の挙動に依存）
- `pr-ops.sh` 出力規約（`pr:<N>:<status>:...`）は維持（本 Unit で破壊的変更は行わない）。`error:checks-status-unknown` エラーコードは後方互換のため維持し、機械可読な `reason:<code>` 行と人間向け `hint:<text>` 行を追加出力するのみ

## リスクと対策

| リスク | 影響 | 対策 |
|--------|------|------|
| `--skip-checks` の誤用により `fail` / `pending` でもマージされる | 高（本 Unit の安全性契約違反） | マトリクステストで `fail` / `pending` + `--skip-checks` が必ず拒否されることを検証 |
| `checks-query-failed`（ネットワーク障害等）が `--skip-checks` でバイパスされる | 高（本 Unit の安全性契約違反） | `gh pr checks` の stderr / exit code を明示的に捕捉し、`no checks reported` を含む場合のみ `no-checks-configured` と判定。それ以外は必ず `checks-query-failed` とする。マトリクステストで検証 |
| `--match-head-commit` 不在で race condition が発生 | 中 | `no-checks-configured` 経路も `pass` と同じ即時マージ実装を呼び出し、`--match-head-commit` 付与を強制 |
| `gh` CLI のバージョン差分で `no checks reported` の stderr 文言が変わる | 中 | 既知の文言（`no checks reported`）を含むかを判定し、文言マッチに失敗した場合は安全側に `checks-query-failed` に倒す |
| ファイル命名が既存 guides 規則と不整合 | 低 | 既存（`backlog-management.md`, `config-merge.md` 等）のハイフン区切り小文字規則に合わせ `merge-pr-usage.md` を第一候補とし、設計で最終確定 |
| `pr-ops.sh` のエラー出力フォーマット変更が他スクリプトに波及 | 中 | 既存の `pr:<N>:error:checks-status-unknown` プレフィックスを維持し、ヒントは別行（`hint:...`）で出力 |

## スコープ外（Unit 定義「境界」セクション準拠）

- `operations-release.sh` の他サブコマンド（`verify-git` 等）の変更
- CI ステータス判定ロジック全体の再設計（本 Unit は `unknown` バケットの分離までで、それ以外の判定ロジックは維持）
- `failed` / `pending` / `checks-query-failed` ケースのスキップ機能（安全性確保のため対象外）
- `gh` CLI バージョン固定・依存ライブラリ変更
- `03-release.md`（完了基準サマリ）の実行フロー詳細化（本 Unit の責務外、Unit 定義との齟齬は「ドキュメント責務の整理」で解消）

## 参照

- Unit 定義: `.aidlc/cycles/v2.3.5/story-artifacts/units/003-merge-pr-skip-checks.md`
- Issue: #575
- 既存スクリプト:
  - `skills/aidlc/scripts/operations-release.sh`（L159-185, L572-641）
  - `skills/aidlc/scripts/pr-ops.sh`（L48, L258-337）
- 既存ドキュメント:
  - `skills/aidlc/steps/operations/operations-release.md`（L81-111、実行フロー詳細の正本）
  - `skills/aidlc/steps/operations/03-release.md`（完了基準サマリ、本 Unit では更新なし）
  - `skills/aidlc/guides/`（既存命名規則の参照元: `backlog-management.md`, `config-merge.md`, `branch-protection.md` 等）
- `gh pr checks` 仕様:
  - `--json` フラグ使用時の `bucket` 値: `pass` / `fail` / `pending` / `skipping` / `cancel`
  - exit code 8: Checks pending
  - 必須チェック未設定時: stderr `no checks reported` + exit 1
