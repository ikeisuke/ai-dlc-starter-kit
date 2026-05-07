# Unit 004 ドメインモデル: helper の zsh source 互換性保証

## 概要

`skills/aidlc/scripts/lib/predecessor-issue.sh` の `__PRED_SCRIPT_DIR` 解決ロジックを zsh / bash 両対応に修正し、helper 6 ファイルの source 互換性を bats テストで保証するための **shell 互換性ドメイン**を定義する。AI エージェントが Claude Code のデフォルトシェル（zsh）から手順記述通りに `source` 経由で helper を呼び出した際、bash と同一の挙動が得られることを保証する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2 で行う。

## ドメイン語彙

### ShellRuntime（値オブジェクト）

shell 実行環境の種別。helper 内の SCRIPT_DIR 解決ロジックは ShellRuntime に応じて分岐する必要がある。

- **値**: `bash` / `zsh`
- **判定方法**: `[[ -n "${ZSH_VERSION:-}" ]]` で `zsh` を検出。`true` なら `zsh`、`false` なら `bash`（または `bash` 互換シェル）
- **不変条件**: 本 Unit の対象は `bash` と `zsh` の 2 値のみ。`sh` / `dash` / `fish` 等は scope 外（既存 helper の shebang `#!/usr/bin/env bash` がスクリプト実行時の bash 強制を担保。本 Unit が対象とするのは **`source` 経路でメインシェルが zsh の場合** のみ）

### ScriptDirInitPattern（値オブジェクト）

helper 先頭で SCRIPT_DIR を解決する初期化パターン。本 Unit は本パターンの **bash 単独依存** を **bash / zsh 両対応** に置換する。

- **現行（修正前）**: `SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)`
  - bash では `${BASH_SOURCE[0]}` が現スクリプトのパスを返す
  - zsh では `${BASH_SOURCE[0]}` が空文字 → `dirname --` が `.` を返す → SCRIPT_DIR が cwd になる（誤動作）
- **修正後（候補案）**: 設計フェーズで以下 2 案から 1 案を確定（`SourceResolutionStrategy` 参照）

### SourceResolutionStrategy（値オブジェクト）

zsh / bash 両対応の SCRIPT_DIR 解決戦略の候補集合。

| 戦略 ID | 名称 | 概要 | 採用前提 |
|--------|------|------|----------|
| **A** | 1 行併記方式 | `${BASH_SOURCE[0]:-${(%):-%N}}` で zsh の `%N` プロンプト展開を fallback として併記 | `${(%):-%N}` が bash でパースエラーにならないこと（要検証） |
| **B** | shell 判定分岐方式 | `[[ -n ${ZSH_VERSION:-} ]]` で zsh 検出 → zsh 用ブロックで `${(%):-%N}` を使用、bash 用ブロックは現行 `${BASH_SOURCE[0]}` 維持 | bash と zsh の構文が完全に独立するため確実 |

- **採用候補の不変条件**:
  - bash 3.2（macOS デフォルト）/ bash 4+ / zsh 5.9（macOS デフォルト）の 3 環境で構文エラーなく動作
  - `source <helper>` 経由で実行された場合、SCRIPT_DIR が helper ファイル自身のディレクトリの絶対パスとして解決される
  - 既存 bash 呼び出し経路の挙動（exit code / stdout / stderr）が完全互換
- **設計フェーズでの確定事項**: 案 A の bash 互換性を実機検証 → 失敗時は案 B にフォールバック

### HelperCompatibilityContract（集約）

helper 6 ファイルが満たすべき bash / zsh 両対応の互換性契約。

- **集約ルート**: 互換性契約全体
- **対象 helper（6 ファイル）**:
  - `aidlc-paths.sh`（leaf helper、SCRIPT_DIR 不使用）
  - `aidlc-validate.sh`（leaf helper、SCRIPT_DIR 不使用）
  - `aidlc-gh.sh`（leaf helper、SCRIPT_DIR 不使用）
  - `aidlc-spool.sh`（leaf helper、SCRIPT_DIR 不使用）
  - `predecessor-issue.sh`（**SCRIPT_DIR 使用、本 Unit の修正対象**）
  - `retrospective-issue.sh`（SCRIPT_DIR 使用、本 Unit の修正対象**外**、OUT_OF_SCOPE）
- **不変条件（ContractAssertion）**:
  1. `bash -c "source <helper>"` が exit 0
  2. `zsh -c "source <helper>"` が exit 0
  3. SCRIPT_DIR を持つ helper（`predecessor-issue.sh` / `retrospective-issue.sh`）は、source 後に SCRIPT_DIR 系変数（`__PRED_SCRIPT_DIR` / `__RETRO_ISSUE_SCRIPT_DIR`）が空でない有効な絶対パスとして解決される
- **境界**:
  - `predecessor-issue.sh` のみ修正可（DR-001 準拠）
  - 他 5 helper への構造変更（コード修正）禁止。`retrospective-issue.sh` の同種バグは OUT_OF_SCOPE バックログ Issue として next-cycle 候補化

### OutOfScopeDetection（ドメインポリシー）

`retrospective-issue.sh` の zsh source 失敗を OUT_OF_SCOPE として判定するドメインポリシー（判定責務のみ、運用アクションは含まない）。

- **責務**: bats テストの観測結果（`bash_exit_status` / `zsh_exit_status` / `script_dir_value`）から OUT_OF_SCOPE 該当性を判定し、判定結果イベントを返す
- **判定インターフェース**: `evaluate(target_helper, observation) -> OutOfScopeJudgment`
- **戻り値（`OutOfScopeJudgment`）**:
  - `target_helper`: helper 名（例: `retrospective-issue.sh`）
  - `is_out_of_scope`: bool（true = OUT_OF_SCOPE 該当）
  - `reason`: `zsh_source_compat_failure` 等の理由コード
  - `evidence`: 観測値（exit status / SCRIPT_DIR 値）
- **判定ルール**: `target_helper ∈ {retrospective-issue.sh}` かつ `observation.zsh_exit_status != 0` のとき `is_out_of_scope=true`
- **不変条件**:
  - `retrospective-issue.sh` 自体への構造変更（コード修正）は **絶対禁止**（DR-001）
  - 本ポリシーは判定責務に限定し、Issue 起票 / skip マーカー反映 / 履歴更新の運用アクションは含まない（責務分離）
- **境界**: 本ポリシーが判定した `OutOfScopeJudgment` を消費して運用アクションを実行する責務は **実装層 / Construction 手順** に分離する（論理設計の「処理フロー概要」「実装上の注意事項」参照）

### TestObservation（値オブジェクト）

bats テストでの観測項目（Asserting されるべきデータ）。

| 観測項目 | 値域 | 検証方法 |
|---------|------|---------|
| `bash_exit_status` | `0` 必須 | `run bash -c "source <helper>"` の `$status` |
| `zsh_exit_status` | `0` 必須（OUT_OF_SCOPE 時 `skip`） | `run zsh -c "source <helper>"` の `$status` |
| `script_dir_value` | 空でない有効な絶対パス（SCRIPT_DIR 持ちの helper のみ） | `bash/zsh -c "source <helper> && printf '%s' \"$SCRIPT_DIR_VAR\""` の stdout |

## 終了コード規約

`skills/aidlc/guides/exit-code-convention.md` の規約（`0=成功 / 1=バリデーションエラー / 2=システムエラー`）に従う。

| exit code | 意味 | 用途（本 Unit / `predecessor-issue.sh` の文脈） |
|-----------|------|------|
| `0` | 成功 | 正常完了（warn を含む。stdout の `status:warning` 等で通知） |
| `1` | バリデーションエラー | 引数不正、入力値検証失敗（cycle 文字列の path traversal 等） |
| `2` | システムエラー | 外部コマンド失敗、環境エラー（gh CLI 不在等） |

**API 契約の維持**: 公開関数 `predecessor_resolve_issue` の **シグネチャ・出力 NDJSON フォーマット・stderr 診断フォーマット** は本 Unit の修正対象外（DR-001 不変条件）。SCRIPT_DIR 解決ロジックの変更のみが本 Unit のスコープ。

**既存実装の挙動とガイド規約の関係**:

- 既存 `predecessor-issue.sh` のソースコメント（5〜7 行目）は `1=継続不能エラー / 2=引数エラー` と記述しており、ガイド規約（`1=バリデーションエラー / 2=システムエラー`）との **意味の対応がやや異なる**（cycle 検証失敗で `return 2` を返す挙動はガイドの `2=システムエラー` と乖離）
- 本 Unit は SCRIPT_DIR 解決ロジック修正のみがスコープのため、既存実装の終了コード返却挙動 / コメント記述の修正は **本 Unit の対象外**（OUT_OF_SCOPE 候補）
- 設計上の終了コード意味定義は **ガイド規約準拠** とし、既存挙動との不整合は OUT_OF_SCOPE バックログ Issue 候補として next-cycle 以降で対応する

## 境界（再掲）

- **修正対象は `predecessor-issue.sh` の 1 ファイルに限定**（DR-001 準拠）
- 他 5 helper（`aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` / `retrospective-issue.sh`）は**テスト追加のみで構造変更しない**
- helper の責務分離（v2.5.3 Unit 004 の延長）は本 Unit のスコープ外
- Inception / Construction Phase の他 helper（`feedback-mode.sh` / `validate-git.sh` 等）への zsh 互換性確認・修正はスコープ外
- ステップファイル（手順記述）の `source` コマンド表記の bash 強制（`bash -c "source ..."` への統一）はスコープ外（次サイクル候補）
- 多重 source ガード（`__AIDLC_<NAME>_SH_LOADED=1`）への変更なし
- `predecessor_resolve_issue` 公開関数のシグネチャ・出力 NDJSON フォーマット・stderr 診断フォーマットに変更なし

## 集約ルートとレイヤ責務

| レイヤ | 責務 | ファイル |
|--------|------|---------|
| 集約ルート | `HelperCompatibilityContract` の検証実行 | `tests/aidlc-helpers-zsh-source.bats`（新規） |
| エンティティ | `predecessor-issue.sh` の SCRIPT_DIR 解決（`SourceResolutionStrategy` 適用） | `skills/aidlc/scripts/lib/predecessor-issue.sh`（修正） |
| 値オブジェクト | `ShellRuntime` 検出 / `ScriptDirInitPattern` 適用 | `predecessor-issue.sh` 内の SCRIPT_DIR 初期化ブロック |
| ドメインポリシー（判定責務のみ） | `OutOfScopeDetection.evaluate` で OUT_OF_SCOPE 該当性を判定し `OutOfScopeJudgment` を返す（**運用アクションを含まない**） | bats テストでの観測結果を入力とした判定ロジック |
| 実装層 / Construction 手順（運用アクション） | `OutOfScopeJudgment` を消費して Issue 起票 / skip マーカー反映 / 履歴記録を実行（**ドメイン層から分離**） | bats テストの `skip` 反映 / `gh issue create` 実行 / 履歴ファイル更新（論理設計「OUT_OF_SCOPE 後段運用フロー」参照） |
| 履歴 | 実装進捗・採用案・OUT_OF_SCOPE 判定結果の記録 | `.aidlc/cycles/v2.5.4/history/construction_unit04.md`（新規） |

## ユビキタス言語

- **SCRIPT_DIR**: helper 自身のディレクトリの絶対パス。helper が依存する他 helper を相対パスで source するための起点
- **source 経路**: `source <file>` または `. <file>` で実行されるシェルスクリプト読み込み経路。**メインシェルの種別（bash / zsh）に依存**する点が `bash <file>`（bash 強制実行）と異なる
- **shebang 強制**: `#!/usr/bin/env bash` を含む経路。`source` 経由では shebang が無視されるため、本 Unit の対象外
- **leaf helper**: 他 helper を source しない helper（`aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`）。SCRIPT_DIR を持たないため bug の影響なし
- **OUT_OF_SCOPE**: 本 Unit のスコープ外として next-cycle 以降に対応する判定。バックログ Issue 起票で証跡を残す
- **DR-001 不変条件**: 修正対象を `predecessor-issue.sh` の 1 ファイルに限定する patch スコープ保護契約

## 関連ドメインとの境界

- **`retrospective-issue.sh`**: 同一の SCRIPT_DIR 解決パターン（`${BASH_SOURCE[0]}` ベース）を持つため zsh source で同種バグの可能性が高い。本 Unit では検出のみ（テスト追加）で**修正しない**（DR-001 準拠）
- **`tests/aidlc-helpers-migration.bats`**: 既存の移管契約テスト。本 Unit の zsh 互換性テストとは責務分離（移管契約 vs zsh 互換性）し、新規 `tests/aidlc-helpers-zsh-source.bats` に分離する
- **AI-DLC ステップファイル（手順記述）**: helper を `source` で呼び出す箇所（Inception §4a / Operations §1.5 等）。本 Unit の修正により AI エージェントが zsh デフォルトの環境でも手順記述通りに動作することを保証する
