# 論理設計: Unit 004 predecessor-issue.sh の retrospective-issue.sh 横依存解消

## 概要

3 関数（`__retro_validate_cycle` / `__retro_gh_status` / `_spool_extract_entries`）を独立 helper（`aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`）に分離し、`retrospective-issue.sh` / `predecessor-issue.sh` 双方が新 helper を独立して source する構造に再構成。

## アーキテクチャパターン

**Strangler Fig 的 関数移管 + 同一コミット切替**: 元 source から関数定義を切り出し、新 helper に配置。元 source 側を関数定義削除 + 新 helper source 化に切り替え、消費者側も同時に切り替え。中間状態を作らない（Round 1 指摘 #4）。

## コンポーネント構成

```text
新規 helper 群（aidlc-validate.sh / aidlc-gh.sh / aidlc-spool.sh）
├── aidlc-validate.sh
│   ├── 多重 source ガード: __AIDLC_VALIDATE_SH_LOADED
│   └── __retro_validate_cycle(cycle) -> 0/2 + stderr
├── aidlc-gh.sh
│   ├── 多重 source ガード: __AIDLC_GH_SH_LOADED
│   └── __retro_gh_status() -> stdout: available|unavailable|not-installed
└── aidlc-spool.sh
    ├── 多重 source ガード: __AIDLC_SPOOL_SH_LOADED
    └── _spool_extract_entries(spool_path) -> stdout: NDJSON

既存ファイル改修
├── retrospective-issue.sh
│   ├── source: aidlc-paths.sh + aidlc-validate.sh + aidlc-gh.sh + aidlc-spool.sh（順序固定）
│   ├── 関数定義削除: __retro_validate_cycle / __retro_gh_status / _spool_extract_entries
│   └── 残置（不変）: retrospective_dialog_token_*, retrospective_issue_create + verify 組込, retrospective_body_compose 等
└── predecessor-issue.sh
    ├── source 撤去: retrospective-issue.sh への直接 source
    └── source 追加: aidlc-paths.sh + aidlc-validate.sh + aidlc-gh.sh + aidlc-spool.sh（順序固定）
```

## インターフェース設計（移管後の関数契約）

### `__retro_validate_cycle(cycle)`（aidlc-validate.sh）

- 入力: `cycle` 文字列
- 戻り値: 0（有効）/ 2（無効） — **移管前と同一**（元 retrospective-issue.sh の実装も exit 2）
- stderr: 無効時に `error\tcycle_invalid\t<reason>` 等（移管前と同一）

### `__retro_gh_status()`（aidlc-gh.sh）

- 入力: なし
- stdout: `available` / `unavailable` / `not-installed`
- exit code: 常に 0

### `_spool_extract_entries(spool_path)`（aidlc-spool.sh）

- 入力: spool ファイルパス
- stdout: NDJSON 形式（1 エントリ 1 行）
- exit code: 0（成功）/ 2（spool 不在 / フォーマット不正）

> **重要**: 関数名・引数・戻り値・exit code・stderr 文言はすべて移管前と同一（API 完全互換）。

## source 読込順序（不変条件）

`retrospective-issue.sh` 冒頭での order:

```bash
source "${SCRIPT_DIR}/aidlc-paths.sh"      # (1) 既存
source "${SCRIPT_DIR}/aidlc-validate.sh"   # (2) 新規
source "${SCRIPT_DIR}/aidlc-gh.sh"         # (3) 新規
source "${SCRIPT_DIR}/aidlc-spool.sh"      # (4) 新規
```

`predecessor-issue.sh` も同順序。各新 helper は他 helper を source しない（境界完全分離）。

## NFR への対応

- **パフォーマンス**: source 構造変更のみで関数実体不変、性能影響なし
- **セキュリティ**: 既存マスク・gh API 利用パターン維持
- **後方互換**: API 完全互換（関数名・引数・exit code・stderr）
- **可用性**: 影響なし

## 不変条件（Unit 001 申し送り保持）

| AC | 検証コマンド | 期待結果 |
|----|------------|---------|
| AC-U004-RETRO-GUARD-IMMUTABLE-1（関数定義保持） | `grep -E "^retrospective_dialog_token_(record_response\|verify)\(\)" skills/aidlc/scripts/lib/retrospective-issue.sh` | 各関数定義 1 行ずつヒット（合計 2 件以上） |
| AC-U004-RETRO-GUARD-IMMUTABLE-1（verify 呼出保持 / 設計レビュー Round 1 指摘 #1 反映） | `awk '/^retrospective_issue_create\(\)/,/^}/' skills/aidlc/scripts/lib/retrospective-issue.sh \| grep -c "retrospective_dialog_token_verify"` | **1 以上**（`retrospective_issue_create` 関数本体内に verify 呼出が必ず存在） |
| AC-U004-RETRO-GUARD-IMMUTABLE-2 | `grep -EHn "retrospective_dialog_token" skills/aidlc/scripts/lib/aidlc-validate.sh skills/aidlc/scripts/lib/aidlc-gh.sh skills/aidlc/scripts/lib/aidlc-spool.sh` | 0 件（新 helper には Unit 001 関数を含めない） |

## 不変条件（Unit 004 自身 / AC-U004(c)）

| AC | 検証コマンド | 期待結果 |
|----|------------|---------|
| AC-U004(c) 相互 source 禁止 | `grep -EHn "^(source\|\.)[[:space:]]+.*(retrospective-issue\|predecessor-issue)\.sh" skills/aidlc/scripts/lib/aidlc-validate.sh skills/aidlc/scripts/lib/aidlc-gh.sh skills/aidlc/scripts/lib/aidlc-spool.sh` | 0 件 |

## 実装上の注意

- 関数本体は **完全コピー**（コメント含む）。改変は `__retro_diag` 等のヘルパ関数依存を整理する範囲に限る
- `__retro_diag` の扱い（**案 A 確定 / 設計レビュー Round 1 指摘 #2 反映**）: 各新 helper（`aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`）に **同一実装を複製** する。境界完全分離を最優先とし、共通基盤への依存を増やさない（小関数のため DRY 違反は許容範囲）。`aidlc-paths.sh` への移管（案 B）は採用しない
- 多重 source ガードのフラグ命名: `__AIDLC_VALIDATE_SH_LOADED` / `__AIDLC_GH_SH_LOADED` / `__AIDLC_SPOOL_SH_LOADED`
- 関数移管後の retrospective-issue.sh の関数列順序は変更しない（diff 最小化）

## 不明点と質問

[Question] `__retro_diag` 関数の扱い

[Answer] **案 A（各新 helper に同一実装を複製）で確定**（設計レビュー Round 1 指摘 #2 反映）。`__retro_diag` は stderr 出力ヘルパで小関数（3 行程度）のため、各 helper に複製しても保守コストは僅少。境界完全分離（観点 3 の不変条件）と整合する案 A を採用する。案 B（`aidlc-paths.sh` への移管）は `aidlc-paths.sh` への実行時依存を増やすため不採用。
