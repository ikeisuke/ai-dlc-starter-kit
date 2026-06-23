# ドメインモデル: Unit 003 — CycleResolver 明示指定優先の回帰テスト（T6）

## 概要

v3 の cycle 解決という「ドメイン概念」が満たすべき不変条件を、回帰テストとして固定するためのモデル。production code は変更せず、既存仕様（`state.json` の `current_cycle` 明示指定一本化 / git 履歴非依存）を恒久的に保護する検証契約を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。テスト実装は Phase 2 で設計承認後に行う。

> 本 Unit はテスト追加が主体のため、DDD テンプレートの各概念（エンティティ / 値オブジェクト等）を「cycle 解決契約の検証対象」という文脈に適合させて記述する。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/scripts/state-read.sh` | cycle 解決入口の実挙動確認（`current_cycle` 読取 / git 非参照 / 終了コード 0/1/2 / 明示 null の扱い） |
| `skills/aidlc-v3/scripts/state-validate.sh` | `current_cycle` 必須・string 型必須の schema 検証責務の所在確認 |
| `skills/aidlc-v3/scripts/tests/test-state-scripts.sh` | 既存ハーネス様式（`make_valid_state` / `assert_rc` / `assert_out` / `mktemp -d`+`trap` / 先頭 `bash -n`・`shellcheck` 静的検査 / 終了コード規約）の踏襲元 |
| `.aidlc/cycles/v3.0.0-alpha.4/story-artifacts/units/003-cycle-resolution-regression-test.md` | 責務・境界（framework 側非対象 / production code 不変）の確認 |

### (b) 設計時に意識すべき挙動

- `state-read.sh current_cycle <file>` は `.aidlc/state.json` の `current_cycle` を jq で読み取り stdout に出力するのみ。**git コマンド呼び出しは一切なく、git 履歴・ファイル名・ディレクトリ走査順に依存しない**（コード上自明）。
- `current_cycle` キー**欠落**時: `has()` ベースのキー存在確認で `exit 1`（`error: field not present in state`）。
- `current_cycle` が**明示 `null`** 時: 欠落と区別し、`"null"` を出力して `exit 0`。
- ファイル不存在 / JSON 不正: `exit 1`。jq 未導入: `exit 2`。読み取り不可（permission）: `exit 2`。
- `state-validate.sh` は `current_cycle` 必須 + string 型必須（非 string は `exit 1`）。schema 妥当性は validate の責務であり read の責務ではない（責務分離）。
- 既存テスト `test-state-scripts.sh` は部分的に `current_cycle を読める`（`assert_out "v3.0.0"`）等をカバーするが、**git 履歴非依存の明示的検証は未カバー**。これが本 Unit の新規価値。

### (c) 既存実装に基づく代替案検討

| 方針 | 既存実装との適合性 | 採否 |
|------|------------------|------|
| `refactor`（既存 `test-state-scripts.sh` に追加） | 既存ハーネスを再利用できるが、308 行ファイルへ git サンドボックス構築という重いセットアップが混入し、関心（汎用 CRUD/終了コード vs cycle 解決/gitlog 非依存）が異なる | 却下（次点） |
| `extend`（新規 `test-cycle-resolution.sh`） | ハーネス様式（assert ヘルパ / fixture）を自己完結で再定義し、cycle 解決回帰を独立ファイルに分離。#733 P4 の回帰テストとして単独で指し示せる | **採用** |
| `replace`（既存テスト書き換え） | 既存テストの責務を壊す。スコープ外 | 却下 |

## エンティティ（検証対象の中心概念）

### CycleResolution（cycle 解決）

- **ID**: なし（プロセス的概念。入口は `state-read.sh current_cycle`）
- **属性**:
  - source: `.aidlc/state.json` の `current_cycle` フィールド（唯一の真実源 / single source of truth）
  - resolvedValue: string（解決結果。`current_cycle` の値そのもの）
- **振る舞い（回帰テストで固定する不変条件）**:
  - `resolve()`: `state.json` の `current_cycle` 値をそのまま返す。**git 履歴・周辺ファイル名・ディレクトリ走査順を一切参照しない**（gitlog 推定非依存 / RFC DG-6）。
  - 欠落時: 解決を行わず明示エラー（`exit 1`）で拒否する。

## 値オブジェクト

### ExplicitCurrentCycle（明示指定された cycle 値）

- **属性**: value: string（例: `"v3.0.0"`）
- **不変性**: 解決結果は入力 `state.json` の値で一意に決まり、外部環境（git 状態）で変動しない
- **等価性**: 文字列値の完全一致で判定（`assert_out` の期待値）

## 集約 / 不変条件（回帰テストが保護する範囲）

### CycleResolutionContract（cycle 解決契約）

- **集約ルート**: CycleResolution
- **含まれる要素**: ExplicitCurrentCycle / 解決の終了コード規約
- **境界**: v3 本体（`skills/aidlc-v3/scripts/`）の cycle 解決入口のみ。framework 側（`skills/aidlc/`）の CycleResolver は対象外（Intent 除外 / #733 P4 の実体は framework 側の可能性が高いが本サイクル GA スコープ外）
- **不変条件（テストで固定）**:
  1. **明示指定優先**: `current_cycle` が設定されていれば、解決結果はその値と一致する。
  2. **gitlog 非依存**: git 履歴・周辺ファイル名・ディレクトリが `current_cycle` と異なる値を含んでいても、解決結果は `state.json` の `current_cycle` 値に一致する（誤誘導に引きずられない）。
  3. **未設定時拒否**: `current_cycle` 欠落時、解決入口は明示エラー（`exit 1`）で拒否し、`state-validate.sh` も無効判定する。
  4. **欠落と明示 null の区別**: 明示 `null` は `"null"` 出力 + `exit 0`、欠落は `exit 1`。

## ドメインサービス

### GitlogDecoySandbox（gitlog 誤誘導サンドボックス / 本 Unit の中核検証手段）

- **責務**: 「cycle 解決が git 状態に影響されない」ことを**積極的に証明**するため、解決入口を意図的に騙そうとする環境を構築する
- **操作**:
  - `setup()`: `mktemp -d` でサンドボックス作成 → サブシェル `( cd "$sandbox" ... )` 内で `git init` + 環境非依存設定（`user.email` / `user.name` / `commit.gpgsign=false` を `git -c` で明示。`git -C` は使わない）→ `current_cycle` と**異なる** cycle 名（例 `v2.6.6` / `v1.0.0`）を含むコミット履歴・周辺ファイル/ディレクトリ（例 `.aidlc/cycles/v2.6.6/`）を作成
  - `teardown()`: `trap 'rm -rf' EXIT` で確実に除去

## リポジトリインターフェース

該当なし（テストはファイルシステム上の一時 `state.json` を直接生成し、`state-read.sh` / `state-validate.sh` を subprocess 起動する。永続化リポジトリ概念は持たない）。

## ユビキタス言語

- **cycle 解決（CycleResolution）**: 現在の作業サイクル識別子（`vX.Y.Z`）を決定する処理。v3 では `state.json` の `current_cycle` 読取に一本化されている
- **明示指定（explicit）**: `state.json` に書かれた `current_cycle` 値。唯一の真実源
- **gitlog 推定（gitlog inference）**: git 履歴・タグ・ファイル名から cycle を推測する旧来パターン。v3 では**排除済み**であり、本テストはその非導入を固定する
- **誤誘導要素（decoy）**: `current_cycle` と異なる cycle 名を含む git 履歴・ファイル。解決が引きずられないことを示すための仕掛け
- **回帰テスト固定（regression lock）**: 既存の正しい仕様を恒久的に保護し、将来の退行（gitlog 推定の再混入等）で赤になるようにすること

## 不明点と質問（設計中に記録）

[Question] なし。

[Answer] 計画（`plans/unit-003-plan.md`）で要件・アプローチが単一に確定し codex レビュー（2R / unresolved 0）済みのため、本設計に持ち越す未決事項はない。production code 不変・検証軸・サンドボックス手順は計画で確定済み。
