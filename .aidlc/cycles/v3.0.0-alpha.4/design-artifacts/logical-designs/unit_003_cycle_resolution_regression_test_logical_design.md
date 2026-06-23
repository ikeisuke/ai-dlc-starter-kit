# 論理設計: Unit 003 — CycleResolver 明示指定優先の回帰テスト（T6）

## 概要

新規テストスクリプト `skills/aidlc-v3/scripts/tests/test-cycle-resolution.sh` の構成・テストケース・サンドボックス手順を定義する。`state.json` の `current_cycle` 明示指定一本化（git 履歴非依存）を回帰テストとして固定する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的なテストコードは Phase 2 で作成する。

## アーキテクチャパターン

**自己完結型 bash テストハーネス**（既存 `test-state-scripts.sh` 様式の踏襲）。外部テストフレームワーク非依存（`jq` のみ前提）。理由: v3 の `skills/aidlc-v3/scripts/tests/*.sh` は CI ランナーに集約されておらず開発時にローカル直接実行する設計のため、既存の自己完結スタイルと一貫させる。

## コンポーネント構成

### レイヤー / モジュール構成

```text
test-cycle-resolution.sh（新規 / 自己完結）
├── 前提・環境
│   ├── jq 存在チェック（未導入 → exit 2）
│   ├── SCRIPT_DIR / SCRIPTS_DIR 解決（BASH_SOURCE 起点）
│   ├── READ（state-read.sh）/ VALIDATE（state-validate.sh）パス定数
│   └── TMPDIR_TEST = mktemp -d + trap 'rm -rf' EXIT
├── ヘルパ（既存様式を自己完結で再定義）
│   ├── make_valid_state <path>      … current_cycle="v3.0.0" の有効 state 生成
│   ├── assert_rc <expected> <desc> -- <cmd...>
│   ├── assert_out <expected> <desc> -- <cmd...>
│   └── make_gitlog_decoy_sandbox <out_state_path> <cycle_value> … 誤誘導 git 環境構築
├── 静的検査
│   └── bash -n（対象 READ/VALIDATE）+ shellcheck（導入時のみ）
└── テスト群（§テストケース表）
    ├── A. 明示指定優先
    ├── B. gitlog 非依存（中核）
    └── C. 未設定/欠落・明示 null 区別
    └── サマリ出力 + 終了コード（0=全成功 / 1=失敗あり / 2=前提不備）
```

### コンポーネント詳細

#### make_gitlog_decoy_sandbox（中核ヘルパ）

- **責務**: 「cycle 解決が git 状態に影響されない」ことを積極的に証明するため、`current_cycle` と異なる cycle 名で git 履歴・周辺ファイルを汚染したサンドボックスを作り、その中に検証用 `state.json` を配置する
- **依存**: `git` / `mktemp`
- **公開インターフェース（概念）**: 入力 = 出力先 state パス・state に書く cycle 値 / 出力 = 誤誘導要素を含むサンドボックスパスと配置済み state.json
- **規約**: git 操作は **サブシェル `( cd "$sandbox" || exit 2; ... )` 内**で実行し `git -C` を使わない（AGENTS.md「git はカレントディレクトリで実行 / `-C` 不使用」）。`git -c user.email=... -c user.name=... -c commit.gpgsign=false` で環境非依存化

#### assert_rc / assert_out / make_valid_state

- **責務**: 既存 `test-state-scripts.sh` と同一セマンティクスのアサート・fixture。PASS/FAIL カウンタを加算
- **依存**: なし（self-contained。既存ハーネスは framework 非依存方針のため共通 source 化しない）

## スクリプトインターフェース設計

### test-cycle-resolution.sh

#### 概要

v3 cycle 解決（`state-read.sh current_cycle`）が `state.json` 明示指定を唯一の真実源とし git 履歴非依存であることを固定する回帰テスト。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| （なし） | - | 引数なしで全テストを実行 |

#### 成功時出力

```text
== 静的検査（bash -n / shellcheck） ==
  ok   : ...
== cycle 解決: 明示指定優先 ==
  ok   : ...
== cycle 解決: gitlog 非依存 ==
  ok   : ...
== cycle 解決: 未設定/欠落・明示 null ==
  ok   : ...

PASS=N FAIL=0
```

- 終了コード: `0`（全テスト成功）
- 出力先: stdout

#### エラー時出力

```text
  FAIL : <説明> (expected ..., got ...)
PASS=.. FAIL=..
```

- 終了コード: `1`（失敗あり） / `2`（前提不備: jq 未導入）
- 出力先: stdout（サマリ）/ stderr（前提不備の SKIP 通知）

#### 使用コマンド

```bash
# 直接実行
bash skills/aidlc-v3/scripts/tests/test-cycle-resolution.sh
```

## データモデル概要

### ファイル形式: 検証用 state.json（一時生成）

- **形式**: JSON（`make_valid_state` / 誤誘導サンドボックス内に生成）
- **主要フィールド**:
  - `schema_version`: string（`"3.0"`）
  - `current_cycle`: string | null | （欠落）- 解決対象。テストケースごとに値を差し替える
  - `define_completed`: bool
  - `release`: object（`pr_number` / `ready` / `merge_approved`）
  - `updated_at`: string

## 処理フロー概要

### テストケース表（実装契約）

| # | 群 | ケース | 手順概要 | 期待 |
|---|----|--------|---------|------|
| 1 | A 明示指定優先 | `current_cycle="v3.0.0"` を read | `make_valid_state` → `READ current_cycle` | `assert_out "v3.0.0"` / rc=0 |
| 2 | A 明示指定優先 | `current_cycle="v9.9.9"`（任意値）を read | valid state を jq で `v9.9.9` に変更 → read | `assert_out "v9.9.9"` / rc=0 |
| 3 | B gitlog 非依存 | git 履歴・周辺に `v2.6.6` 誤誘導、state.json は `v3.0.0` | `make_gitlog_decoy_sandbox <state> v3.0.0`（内部で別 cycle 名 commit + `.aidlc/cycles/v2.6.6/` 等を作成）→ read | `assert_out "v3.0.0"`（`v2.6.6` にならない）/ rc=0 |
| 4 | B gitlog 非依存 | 同サンドボックスで state.json を `v9.9.9` に変更 | jq で `current_cycle=v9.9.9` に上書き → read | `assert_out "v9.9.9"` / rc=0 |
| 5 | C 未設定拒否 | `current_cycle` キー欠落 | valid state から `del(.current_cycle)` → read | `assert_rc 1`（state-read） |
| 6 | C 未設定拒否 | `current_cycle` 欠落 | 同上の欠落 state → validate | `assert_rc 1`（state-validate 無効） |
| 7 | C 明示 null 区別 | `current_cycle: null` | jq で `current_cycle=null` → read | `assert_out "null"` / rc=0（欠落と区別） |

**関与するコンポーネント**: `state-read.sh`（ケース 1-5,7）/ `state-validate.sh`（ケース 6）/ `make_gitlog_decoy_sandbox`（ケース 3-4）/ `make_valid_state`（ケース 1,2,5,6,7）

> ケース最終数・文言は実装時に微調整可。ただし「明示指定優先」「gitlog 非依存（誤誘導 git 環境で証明）」「未設定拒否」「明示 null 区別」の 4 観点は必須（完了条件）。

### gitlog 非依存サンドボックス構築フロー（ケース 3-4 / 中核）

**ステップ**:
1. `sandbox="$(mktemp -d)"`（テスト先頭の `TMPDIR_TEST` 配下またはケース内 mktemp。`trap` で除去）
2. サブシェル `( cd "$sandbox" || exit 2; ... )` 内で:
   - `git init -q`
   - 誤誘導: `mkdir -p .aidlc/cycles/v2.6.6` 等の別 cycle 名ディレクトリ/ファイルを作成し `git add` → `git -c user.email=t@example.com -c user.name=test -c commit.gpgsign=false commit -q -m "work on v2.6.6"`（コミットメッセージにも別 cycle 名）
   - 必要なら追加コミットでディレクトリ走査順の誤誘導を増やす
3. サンドボックス内 `.aidlc/state.json` に `current_cycle: "v3.0.0"`（誤誘導と異なる値）を生成
4. `READ current_cycle "$sandbox/.aidlc/state.json"` → `assert_out "v3.0.0"`（git 履歴の `v2.6.6` に引きずられない）
5. ケース 4: 同 state.json を `v9.9.9` に書き換えて再 read → `assert_out "v9.9.9"`（解決が state.json driven であることの二重確認）

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: テスト追加のみ（実行時間影響は軽微 / Unit 定義 NFR）
- **対応策**: git サンドボックスは最小コミット数。`mktemp` + `trap` で後始末

### セキュリティ
- **要件**: 特になし（Unit 定義 NFR）
- **対応策**: サンドボックスは一時領域に閉じる。機密情報なし

### 可用性
- **要件**: 既存テスト緑を維持（Unit 定義 NFR）
- **対応策**: 新規ファイルのため既存テストへ非侵襲。v3 全スイート + 既存 check 緑を完了条件化

## 技術選定
- **言語**: bash（3.2 / 4.0+ 互換 / `set -uo pipefail`）
- **依存**: `jq`（前提 / 未導入は `exit 2` で SKIP）、`git`、`mktemp`、`sed`/`cat`（fixture 生成）
- **フレームワーク**: なし（自己完結ハーネス）

## 実装上の注意事項

- **git サンドボックスの環境非依存**: グローバル `user.name`/`user.email` 未設定や `commit.gpgsign=true` 環境でも commit が成功するよう `git -c` で明示設定。CI/ローカル両対応。
- **`git -C` 不使用**: サンドボックス git 操作はサブシェル `cd` 内で実行（AGENTS.md 規約）。テスト本体のカレントディレクトリを汚染しないようサブシェルに閉じ込める。
- **`mktemp`/`trap` の後始末**: 既存ハーネス踏襲で `trap 'rm -rf "$TMPDIR_TEST"' EXIT`。ケース内 mktemp も最終的に除去されるよう配置。
- **コマンド置換禁止規約（Bash ツール経由）**: テストスクリプト内部のコマンド置換（`sandbox="$(mktemp -d)"` 等）はファイル実行であり CLAUDE.md の「Bash ツール引数文字列」規約の対象外。ただし AI エージェントが Bash ツールでテストを起動する際の引数や commit message には `$(...)`/backtick を含めない。
- **production code 不変**: `state-read.sh` 等は変更しない。テスト作成過程で想定外挙動（gitlog 推定の残骸等）を発見した場合は独自修正せずユーザー報告（計画 §4.5）。

## 不明点と質問（設計中に記録）

[Question] なし。

[Answer] 計画（codex 2R レビュー済み / unresolved 0）でアプローチが単一確定済み。テストケース表・サンドボックス手順・命名（`test-cycle-resolution.sh`）・`git -C` 不使用方針まで確定しており、論理設計に持ち越す未決事項はない。
