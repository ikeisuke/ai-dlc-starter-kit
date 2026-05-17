# 論理設計: operations-release.sh への validate_cycle 検証拡張

## 概要

`operations-release.sh` の `cmd_record_release_prep_commit` / `cmd_pr_ready` に `validate_cycle` 呼び出しを追加するための論理設計。実装コード自体は Phase 2 で作成する。

## アーキテクチャパターン

- **採用パターン**: CLI サブコマンドのパイプライン構造を維持。検証層（validation）→ 業務処理層（business logic）の責務分離を入口で強化
- **選定理由**: v2.6.3 Unit 002 で確立した `validate_cycle` 適用パターン（fail-fast 入口検証 + tab 区切り stderr フォーマット）を踏襲し、`operations-release.sh` 内の全 `--cycle` 受付サブコマンドで一貫した責務境界を維持する

## コンポーネント構成

### 既存ファイル変更

```text
skills/aidlc/scripts/operations-release.sh
├── source (既存) lib/validate.sh  ※ 変更なし
├── require_option_value()           ※ 変更なし
├── resolve_cycle_from_branch()      ※ 変更なし
├── cmd_pr_ready()                   ※ validate_cycle 呼び出し追加
├── cmd_record_release_prep_commit() ※ validate_cycle 呼び出し追加
└── cmd_squash_712()                 ※ 変更なし（v2.6.3 Unit 002 で導入済み）
```

### 新規ファイル

```text
tests/
├── operations-release-record-release-prep-commit-cycle-validation.bats  (新規)
└── operations-release-pr-ready-cycle-validation.bats                    (新規)
```

### コンポーネント詳細

#### `cmd_record_release_prep_commit`

- **責務**: `--cycle` 引数受付 → 検証 → progress.md 更新 → release_prep_commit 記録コミット
- **依存**: `validate_cycle`（lib/validate.sh）、`__operations_release_progress_path`、`git`
- **公開インターフェース**: CLI サブコマンド `record-release-prep-commit --cycle <value> [--dry-run]`
- **本 Unit での変更**: 既存の `-z "$cycle"` チェック直後に `validate_cycle "$cycle"` を挿入

#### `cmd_pr_ready`

- **責務シーケンス**: 引数受付 → body-file 検証（`--body-file` 指定時のみ）→ cycle 解決（`--cycle` 未指定なら `resolve_cycle_from_branch`）→ `validate_cycle` → `pr-ops.sh get-related-issues` → ドラフト PR の Ready 化 → 必要に応じて body 更新
- **依存**: `validate_cycle`、`resolve_cycle_from_branch`、`_pr_ready_validate_body_file`、`pr-ops.sh get-related-issues`、`gh pr` 系コマンド
- **公開インターフェース**: CLI サブコマンド `pr-ready [--cycle <value>] [--pr <num>] [--body-file <path>] [--dry-run]`
- **本 Unit での変更**: `_pr_ready_validate_body_file` 直後・cycle 解決直後・`pr-ops.sh get-related-issues` 呼び出し直前に `validate_cycle "$cycle"` を挿入（上記「責務シーケンス」と下記「検証順序」の単一仕様で記述。文書内の順序定義は本箇所と「検証順序」表のみが SoT）

## インターフェース設計

### スクリプトインターフェース設計

#### `operations-release.sh record-release-prep-commit`

##### 概要

リリース準備コミットの SHA を `.aidlc/cycles/<cycle>/operations/progress.md` に追記または更新する。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--cycle <value>` | 必須 | サイクル名（`v2.6.4` / `cycle_name/version` 等） |
| `--dry-run` | 任意 | 副作用なしで処理内容のみ出力 |

##### 検証順序（本 Unit で確定）

1. 引数パース（`require_option_value` で空値拒否）
2. `[[ -z "$cycle" ]]` → `record-release-prep-commit:error:cycle-required`（既存）
3. **`validate_cycle "$cycle"` → 失敗時 `error\trecord-release-prep-commit:invalid-cycle\t<value>` + exit 1**（本 Unit で追加）
4. `__operations_release_progress_path "$cycle"` でパス展開（以降は既存処理）

##### 成功時出力

```text
release_prep_commit:recorded:<full_sha>
# or
release_prep_commit:updated:<full_sha>
# or
release_prep_commit:already-recorded:<full_sha>
```

- 終了コード: `0`
- 出力先: stdout

##### エラー時出力

```text
record-release-prep-commit:error:missing-value:--cycle      # 引数欠落
record-release-prep-commit:error:cycle-required             # --cycle 未指定
error<TAB>record-release-prep-commit:invalid-cycle<TAB><value>  # 本 Unit で追加
error<TAB>record-release-prep-commit:progress-not-found<TAB><path>  # 既存
error<TAB>record-release-prep-commit:git-rev-parse-failed<TAB><detail>  # 既存
error<TAB>record-release-prep-commit:write-failed<TAB><detail>  # 既存
error<TAB>record-release-prep-commit:commit-failed<TAB><detail>  # 既存
```

- 終了コード: `1`（不正引数 / I/O 失敗）
- 出力先: stderr

#### `operations-release.sh pr-ready`

##### 概要

ドラフト PR の Ready 化と body 更新を行う。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--cycle <value>` | 任意 | サイクル名。未指定時は `resolve_cycle_from_branch` で解決 |
| `--pr <number>` | 任意 | PR 番号。未指定時は `find-draft` で探索 |
| `--body-file <path>` | 任意 | PR 本文ファイル |
| `--dry-run` | 任意 | 副作用なしで処理内容のみ出力 |

##### 検証順序（本 Unit で確定）

1. 引数パース（`require_option_value` で空値拒否）
2. `_pr_ready_validate_body_file "$body_file"`（既存、`--body-file` 指定時のみ）
3. `[[ -z "$cycle" ]]` → `cycle=$(resolve_cycle_from_branch)`（既存）
4. **`validate_cycle "$cycle"` → 失敗時 `error\tpr-ready:invalid-cycle\t<value>` + exit 1**（本 Unit で追加）
5. `pr-ops.sh get-related-issues "$cycle"`（以降は既存処理）

##### 成功時出力

```text
pr:found:<num>:<url>
pr:not-found
pr:ready:<num>
pr:fallback:rest-patch:<num>
# 等、既存契約のまま
```

- 終了コード: `0`
- 出力先: stdout

##### エラー時出力

```text
pr-ready:error:missing-value:--cycle                # 既存
pr-ready:error:unknown-option:<opt>                 # 既存
error<TAB>pr-ready:body-file-empty<TAB><path>       # 既存
error<TAB>pr-ready:body-file-missing<TAB><path>     # 既存
error<TAB>pr-ready:invalid-cycle<TAB><value>        # 本 Unit で追加
pr-ready:error:body-file-required                   # 既存
```

- 終了コード: `1`
- 出力先: stderr

## bats テスト設計

### 新規ファイル 1: `tests/operations-release-record-release-prep-commit-cycle-validation.bats`

#### 概要

`cmd_record_release_prep_commit` の `--cycle` 引数検証を網羅する。

#### ヘッダー

- `bats_require_minimum_version 1.5.0`
- 設計 SoT: 本ドキュメントへのパス参照を冒頭コメントで明示

#### setup / teardown

`tests/operations-release-squash712-cycle-validation.bats` のパターンを踏襲（一時 git リポジトリ + .aidlc/config.toml + progress.md フィクスチャ）。

#### テストケース一覧

| # | テスト名 | 入力 | 期待 |
|---|---------|------|------|
| 1 | 正常 cycle で従来挙動（回帰なし） | `--cycle v2.6.4` + 既存 progress.md | exit 0, `release_prep_commit:recorded:<sha>` 形式の stdout |
| 2 | パストラバーサル | `--cycle ../etc` | exit 1, stderr に `record-release-prep-commit:invalid-cycle` + `../etc` |
| 3 | 先頭スラッシュ | `--cycle /abs/path` | exit 1, stderr に `invalid-cycle` |
| 4 | 空白を含む | `--cycle 'v2.6 4'` | exit 1, stderr に `invalid-cycle` |
| 5 | 制御文字（tab） | `--cycle $'v2.6\t4'` | exit 1, stderr に `invalid-cycle` |
| 6 | 形式不一致（大文字） | `--cycle V2.6.4` | exit 1, stderr に `invalid-cycle` |
| 7 | `--cycle` 未指定 | （引数なし） | exit 1, stderr に `cycle-required`（既存経路、invalid-cycle ではない） |
| 8 | `--cycle ""` 空値 | `--cycle ''` | exit 1, stderr に `missing-value:--cycle`（既存経路、invalid-cycle ではない） |

### 新規ファイル 2: `tests/operations-release-pr-ready-cycle-validation.bats`

#### 概要

`cmd_pr_ready` の `--cycle` 引数検証を網羅する。

#### setup / teardown

一時 git リポジトリを `cycle/v2.6.4` ブランチで初期化（`resolve_cycle_from_branch` の挙動検証のため）。gh の mock は最小限（dry-run 主体）。

#### テストケース一覧

| # | テスト名 | 入力 | 期待 |
|---|---------|------|------|
| 1 | 正常 cycle で従来挙動（回帰なし） | `--cycle v2.6.4 --dry-run --pr 999` | exit 0, validation で停止しない |
| 2 | パストラバーサル | `--cycle ../etc --dry-run` | exit 1, stderr に `pr-ready:invalid-cycle` + `../etc` |
| 3 | 先頭スラッシュ | `--cycle /abs/path --dry-run` | exit 1, stderr に `invalid-cycle` |
| 4 | 空白を含む | `--cycle 'v2.6 4' --dry-run` | exit 1, stderr に `invalid-cycle` |
| 5 | 制御文字（tab） | `--cycle $'v2.6\t4' --dry-run` | exit 1, stderr に `invalid-cycle` |
| 6 | 形式不一致（大文字） | `--cycle V2.6.4 --dry-run` | exit 1, stderr に `invalid-cycle` |
| 7 | `--cycle` 未指定 + `cycle/v2.6.4` ブランチ | `--dry-run --pr 999`（branch 解決経路） | exit 0, validation で停止しない |
| 8 | `--cycle` 未指定 + 非 cycle ブランチ（例 `feature/x`） | `--dry-run --pr 999` | exit 1, stderr に `pr-ready:invalid-cycle`（解決結果が空文字 → 拒否） |
| 9 | `--cycle ""` 空値 | `--cycle '' --dry-run` | exit 1, stderr に `missing-value:--cycle`（既存経路、invalid-cycle ではない） |

#### 既存 bats への影響

- `tests/operations-release-pr-ready-body-validate.bats`: 既存テストは `--cycle v2.6.2` 等の正常 cycle を使用しているため回帰なし
- `tests/operations-release-pr-edit-fallback.bats`: 同上
- `tests/operations-release-squash712-*.bats`: cmd_squash_712 への変更なしのため回帰なし
- `tests/migration/*.bats`: operations-release.sh の cycle 引数を使う経路なし（事前確認）

## 依存方向

```text
operations-release.sh (CLI 入口)
  ├─→ lib/validate.sh::validate_cycle    (検証)
  ├─→ __operations_release_progress_path (パス展開)
  ├─→ pr-ops.sh get-related-issues       (外部スクリプト)
  └─→ git / gh                           (外部 CLI)
```

- 依存方向は CLI 入口（高位）→ ライブラリ・外部ツール（低位）への一方向
- 循環依存なし
- 検証層は業務処理層より上流に位置（fail-fast）

## エラー伝播

- `validate_cycle` 失敗 → exit 1（即時、後続処理に進まない）
- `validate_cycle` 通過後の I/O 失敗（git / gh / sed 等）→ 既存のエラーハンドリング（変更なし）

## ロギング / 履歴

- `validate_cycle` 失敗時の stderr 出力フォーマットは tab 区切り（`error\t<subcommand>:invalid-cycle\t<value>`）で v2.6.3 Unit 002 と完全に同形
- DRY_RUN モードでも検証は実行する（実行前検証目的、v2.6.3 Unit 002 と同方針）

## 不明点と質問

[Question] DRY_RUN モードで `validate_cycle` 失敗時の動作は通常モードと同じで良いか
[Answer] OK。DRY_RUN は副作用回避のためのフラグであり、引数検証は副作用ではないため通常モードと同じ exit 1 を返す（v2.6.3 Unit 002 と整合）。

[Question] `cmd_pr_ready` の bats #8（非 cycle ブランチ）テストでは何のブランチ名を使うか
[Answer] `feature/x` または `main`。`resolve_cycle_from_branch` は `^cycle/(.+)$` 正規表現に一致しないと空文字を返すため、`feature/x` で確実に空文字 → `validate_cycle` で `invalid-cycle` 経路を再現できる。
