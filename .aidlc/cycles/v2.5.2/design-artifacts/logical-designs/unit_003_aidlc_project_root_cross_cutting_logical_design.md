# 論理設計: AIDLC_PROJECT_ROOT 横断 path resolution リファクタ

## 概要

`skills/aidlc/scripts/lib/aidlc-paths.sh` を新設し、producer/consumer の path 解決ロジックを単一の helper 関数 `aidlc_cycle_path` に集約する。3 ファイル（`retrospective-issue.sh` / `predecessor-issue.sh` / `retrospective-resend.sh`）の path 算出を helper 経由に統一し、producer/consumer 整合性を確保する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコードは Phase 2 で作成します。

## アーキテクチャパターン

**採用パターン**: Layered Library Pattern（既存の `skills/aidlc/scripts/lib/` 配下と同一構造）

**選定理由**:
- 既存の `retrospective-issue.sh` / `predecessor-issue.sh` / `bootstrap.sh` 等が同パターン（`scripts/lib/*.sh` を `source` で共有）であり、整合性が高い
- 多重 source ガード `__AIDLC_*_LOADED` のパターンが確立しており、新規 helper も同パターンで導入可能
- helper は純粋関数（副作用なし）として実装するため、別パターン（CQRS や Hexagonal）は不要

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc/scripts/
├── lib/
│   ├── aidlc-paths.sh          # 【新規】path resolution helper
│   ├── retrospective-issue.sh  # 【改修】producer (__retro_spool_path)
│   └── predecessor-issue.sh    # 【改修】consumer (compat_path / spool_path)
└── retrospective-resend.sh     # 【改修】consumer (SPOOL_PATH)

bin/tests/
└── aidlc-paths/                # 【新規】BATS テスト
    ├── aidlc_cycle_path.bats           # helper 単体テスト
    └── consumer_integration.bats       # producer/consumer ブラックボックス検証
```

### コンポーネント詳細

#### `lib/aidlc-paths.sh`（新規）

- **責務**: AIDLC_PROJECT_ROOT を考慮した cycle 配下 path の文字列生成（ドメインサービス `AidlcCyclePathResolver` の実装）
- **依存**: なし（純粋関数 / 標準コマンドのみ使用）
- **公開インターフェース**:
  - `aidlc_cycle_path <cycle> <subpath>` → stdout に解決済み path を 1 行で出力
- **多重 source ガード**: `__AIDLC_PATHS_SH_LOADED=1`

#### `lib/retrospective-issue.sh`（改修 / producer）

- **責務**: retrospective spool の生成・操作（既存）。本 Unit では `__retro_spool_path` を helper 経由化のみ行う
- **依存**: `lib/aidlc-paths.sh`（新規追加）
- **公開インターフェース**: 不変（既存の `__retro_spool_path` の戻り値文字列は変更されないが、生成方式が helper 経由に変わる）
- **改修方針**: ファイル冒頭の多重 source ガード直後に `aidlc-paths.sh` を `source`。`__retro_spool_path` 関数本体を helper 呼び出しに置き換え

#### `lib/predecessor-issue.sh`（改修 / consumer）

- **責務**: predecessor handoff の Issue 検索（既存）
- **依存**: `lib/retrospective-issue.sh`（既存）+ `lib/aidlc-paths.sh`（新規追加）
- **公開インターフェース**: 不変（`predecessor_resolve_issue` の NDJSON 出力は変更なし）
- **改修方針**:
  - ファイル冒頭で `aidlc-paths.sh` を `source`（明示性重視。`retrospective-issue.sh` 経由で間接到達可能だが冗長 source は idempotent）
  - `__pred_read_compat_file` 内の `compat_path` 算出を helper 経由に変更
  - `predecessor_resolve_issue` 内の `spool_path` / `compat_path` 算出を helper 経由に変更

#### `retrospective-resend.sh`（改修 / consumer）

- **責務**: spool 再送 CLI（既存）
- **依存**: `lib/retrospective-issue.sh`（既存）+ `lib/aidlc-paths.sh`（新規追加 / 経由 source）
- **公開インターフェース**: 不変（CLI 引数 / 終了コード / 出力フォーマット変更なし）
- **改修方針**: `SPOOL_PATH` 算出のみ helper 経由に変更
- **AIDLC_PROJECT_ROOT 保証範囲（IF 制約 / 重要）**: 本 Unit では **`--cycle` 明示時のみ** path 解決の AIDLC_PROJECT_ROOT 整合を保証する。**`--cycle` 省略時の cycle 自動決定経路（`:71` `[[ ! -d ".aidlc/cycles" ]]` / `:75` `ls -1 .aidlc/cycles ...`）は cwd 直書き前提のまま**であり、AIDLC_PROJECT_ROOT 設定下で別ルートディレクトリの cycle を見られない不整合が残る。本制約は計画書 §4 の残存直書き path 一覧および follow-up Issue #644 として明示的に切り出されている（次サイクル以降の backlog）

#### `bin/tests/aidlc-paths/aidlc_cycle_path.bats`（新規）

- **責務**: helper 単体テスト
- **依存**: `bats-core`, `lib/aidlc-paths.sh`
- **テストマトリクス**:
  - AIDLC_PROJECT_ROOT 未設定 / 空文字 / 絶対パス / 相対パス / 末尾空白
  - 引数不足（cycle 空 / subpath 未指定）

#### `bin/tests/aidlc-paths/consumer_integration.bats`（新規）

- **責務**: producer/consumer のブラックボックス検証
- **判定主軸（primary）**: 構造化出力 — `predecessor_resolve_issue` の **NDJSON `file_path` フィールド**を主判定とする（公開 IF / 構造化されており文言変更耐性が高い）
- **判定補助（secondary）**: `retrospective-resend.sh` の **stderr `path=` トークン**は `error\tspool-not-found\tcycle=$CYCLE\tpath=$SPOOL_PATH` の公開 stderr フォーマット内であり、補助チェックとして使用する。文言変更で BATS が壊れた場合は NDJSON 主判定を優先し、stderr アサートは更新する方針
- **依存**: `bats-core`, 3 改修済みファイル, fixture `<root>/.aidlc/cycles/v9.9.9/operations/retrospective.md`

## インターフェース設計

## スクリプトインターフェース設計

### `aidlc-paths.sh`（library）

#### 概要

AIDLC_PROJECT_ROOT を考慮した cycle 配下 path の文字列生成 helper。

#### 公開関数: `aidlc_cycle_path <cycle> <subpath>`

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `cycle` | 必須 | cycle 識別子（例: `v2.5.2`）。空文字は引数エラー |
| `subpath` | 必須 | cycle 配下の相対 path（例: `history/retrospective-spool.md`）。未指定は引数エラー |

#### 成功時出力

```text
<解決済み path 文字列>
```

- 終了コード: `0`
- 出力先: stdout（改行 1 つ付き）

**動作仕様**:

| AIDLC_PROJECT_ROOT 値 | 出力例（cycle=v2.5.2, subpath=history/spool.md）|
|----------------------|------------------------------------------------|
| 未設定 / 空文字 | `.aidlc/cycles/v2.5.2/history/spool.md` |
| `/abs/path` | `/abs/path/.aidlc/cycles/v2.5.2/history/spool.md` |
| `../rel` | `../rel/.aidlc/cycles/v2.5.2/history/spool.md`（trim / 絶対化なし） |
| `/p ` (末尾空白) | `/p /.aidlc/cycles/v2.5.2/history/spool.md`（trim なし） |

#### エラー時出力

```text
error\taidlc_paths_invalid_cycle\t<msg>
error\taidlc_paths_invalid_subpath\t<msg>
```

- 終了コード: `2`（引数エラー）
- 出力先: stderr

> **終了コード規約の選定理由**: `skills/aidlc/guides/exit-code-convention.md` の規範では「引数エラー = exit 1」だが、本 Unit が依存する retrospective 系の既存実装（`retrospective-issue.sh` ヘッダ `2 - 引数エラー / fatal`、`__retro_validate_cycle` の `return 2`、`retrospective-resend.sh` ヘッダ `2  Argument error`）はすべて引数エラーを `exit 2` として運用している。`aidlc-paths.sh` は同 lib 配下の helper であり、既存系列との整合を優先して `exit 2` を採用する。規約 guide との乖離は本 Unit のスコープ外（共通規約改定は別サイクルの backlog 候補）。

#### 使用コマンド

```bash
# library として source する（直接実行は想定しない）
source "${SCRIPT_DIR}/lib/aidlc-paths.sh"
SPOOL_PATH=$(aidlc_cycle_path "$CYCLE" "history/retrospective-spool.md")
```

### 改修対象 3 ファイルの修正前後（差分指針）

#### `lib/retrospective-issue.sh`

修正前（line 505-514）:

```bash
__retro_spool_path() {
    local cycle="$1"
    if [[ -n "${AIDLC_PROJECT_ROOT:-}" ]]; then
        printf '%s/.aidlc/cycles/%s/history/retrospective-spool.md\n' "$AIDLC_PROJECT_ROOT" "$cycle"
    else
        printf '.aidlc/cycles/%s/history/retrospective-spool.md\n' "$cycle"
    fi
}
```

修正後:

```bash
__retro_spool_path() {
    local cycle="$1"
    aidlc_cycle_path "$cycle" "history/retrospective-spool.md"
}
```

#### `lib/predecessor-issue.sh`

修正対象 1（`__pred_read_compat_file` 内 / line 181）:

```bash
local compat_path=".aidlc/cycles/${prev_cycle}/operations/retrospective.md"
# ↓ 修正後
local compat_path
compat_path=$(aidlc_cycle_path "$prev_cycle" "operations/retrospective.md")
```

修正対象 2（`predecessor_resolve_issue` 内 / line 248-249）:

```bash
local spool_path=".aidlc/cycles/${prev_cycle}/history/retrospective-spool.md"
local compat_path=".aidlc/cycles/${prev_cycle}/operations/retrospective.md"
# ↓ 修正後
local spool_path compat_path
spool_path=$(aidlc_cycle_path "$prev_cycle" "history/retrospective-spool.md")
compat_path=$(aidlc_cycle_path "$prev_cycle" "operations/retrospective.md")
```

#### `retrospective-resend.sh`

修正対象（line 87）:

```bash
SPOOL_PATH=".aidlc/cycles/$CYCLE/history/retrospective-spool.md"
# ↓ 修正後
SPOOL_PATH=$(aidlc_cycle_path "$CYCLE" "history/retrospective-spool.md")
```

## データモデル概要

該当なし（永続化スキーマや新規ファイル形式の追加なし）。

## 処理フロー概要

### ユースケース 1: producer による path 解決（spool 書き込み時）

**ステップ**:

1. `retrospective-issue.sh` 内の任意の関数（例: `_spool_append`）が `__retro_spool_path "$cycle"` を呼び出す
2. `__retro_spool_path` が `aidlc_cycle_path "$cycle" "history/retrospective-spool.md"` を呼び出す
3. `aidlc_cycle_path` が `AIDLC_PROJECT_ROOT` を読み取り、設定有無に応じて path を生成
4. stdout に path 文字列が出力され、呼び出し側で `local` 変数に格納される

**関与するコンポーネント**: `retrospective-issue.sh`, `aidlc-paths.sh`

### ユースケース 2: consumer による path 解決（resend 起動時）

**ステップ**:

1. `retrospective-resend.sh` が CLI 引数 / cycle 自動決定で `CYCLE` を確定
2. `SPOOL_PATH=$(aidlc_cycle_path "$CYCLE" "history/retrospective-spool.md")` で path 取得
3. ファイル存在チェック（`[[ ! -f "$SPOOL_PATH" ]]`）→ 存在しなければエラー、存在すれば後続処理

**関与するコンポーネント**: `retrospective-resend.sh`, `aidlc-paths.sh`

### ユースケース 3: producer/consumer の path 整合性確認（BATS）

**ステップ**:

1. テスト fixture: `AIDLC_PROJECT_ROOT=/tmp/t1` を export
2. fixture cycle dir 作成: `mkdir -p /tmp/t1/.aidlc/cycles/v9.9.9/operations` + `touch retrospective.md`
3. producer 側の path: `__retro_spool_path "v9.9.9"` の stdout を取得
4. consumer 側の path: `predecessor_resolve_issue v9.9.9` の NDJSON `file_path` を取得
5. `INV-1`（同一 root/cycle/subpath で同一 path）の検証

**関与するコンポーネント**: `aidlc-paths.sh`, `retrospective-issue.sh`, `predecessor-issue.sh`, BATS

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: helper 関数呼び出しはミリ秒未満（path 連結のみ）
- **対応策**: bash 内蔵の `printf` のみ使用。外部コマンド呼び出しなし。サブシェル `$(...)` 起動コストのみ

### セキュリティ

- **要件**: helper は AIDLC_PROJECT_ROOT の値をそのまま展開する。shell 注入懸念があれば呼び出し側で quote する責務（DR-007）
- **対応策**: helper は受け取った値を `printf '%s/...'` でフォーマット。bash 引数展開の通常ルールに従う。呼び出し側は `local var=$(aidlc_cycle_path "$cycle" "$subpath")` のように常にダブルクォートで囲む（既存実装と整合）

### スケーラビリティ

- **要件**: 対象外（CLI helper のため）
- **対応策**: 該当なし

### 可用性

- **要件**: 後方互換性を維持（AIDLC_PROJECT_ROOT 未設定時は v2.5.1 と完全一致）
- **対応策**: `__retro_spool_path` の現行ロジックを `aidlc_cycle_path` に内部移植する形でリファクタ。文字列出力を比較する BATS で動作不変を確認

## 技術選定

- **言語**: `bash` 4 以上（Unit 定義「外部依存」より）
- **フレームワーク**: なし（POSIX shell + bash 拡張）
- **ライブラリ**: なし（標準コマンド `printf` のみ）
- **テストフレームワーク**: `bats-core`（既存 `bin/tests/check-test-isolation/` と同一）

## 実装上の注意事項

- **DR-007 遵守**: helper は path 連結のみ。trim・正規化・絶対化・存在チェックを追加してはならない
- **多重 source ガード**: `__AIDLC_PATHS_SH_LOADED=1` を採用（既存 `__AIDLC_*_LOADED` パターン準拠）
- **BASH_SOURCE 自己解決**: 既存 `predecessor-issue.sh` と同パターンを採用（library 自身が自己位置を取得）
- **冗長 source の許容**: 3 改修ファイルすべてで `aidlc-paths.sh` を明示 source（多重 source ガードにより副作用なし）。明示性 > 簡潔性で意思決定
- **check-test-isolation 対応**: 新規 BATS は `cd "$BATS_TEST_TMPDIR"` を `setup` または各 `@test` 冒頭に必ず置く（cwd 依存パターン violation を発生させない）
- **check-bash-substitution 対応**: 本ファイル群は `bin/*.sh` 配下ではないため本チェックの対象外（Unit 002 計画書の整理通り）。ただし `aidlc-paths.sh` は steps 配下ではないため `$()` 使用に制約はない（標準的な Bash 慣用句として `local var=$(aidlc_cycle_path ...)` を許容）
- **CHANGELOG 反映**: v2.5.2 セクションに 1 行追記（計画書 §6 のテキスト）

## 不明点と質問

該当なし。
