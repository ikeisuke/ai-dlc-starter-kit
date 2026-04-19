# レビューサマリ: Unit 002 - write-history.sh マージ後呼び出しガード + 04-completion.md 禁止記述

## 基本情報

- **サイクル**: v2.3.6
- **フェーズ**: Construction
- **対象**: Unit 002（`skills/aidlc/scripts/write-history.sh` ガード追加 / `skills/write-history/SKILL.md` / `skills/aidlc/steps/operations/04-completion.md`）

---

## Set 1: 2026-04-19 20:53:34 (Unit 002 設計 AI レビュー)

- **レビュー種別**: 設計（focus: architecture）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘0件

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | ドメインモデル / 論理設計のエラー出力チャネル契約（stdout 固定）が Unit 定義 / Story 1.2 受け入れ基準（stderr 要件）および既存 `emit_error()`（stdout 出力）と不整合 | 修正済み（logical_design.md `emit_post_merge_rejection`・NFR 明確性・エラー時出力節 / domain_model.md GuardDecision・集約境界・ユビキタス言語を「stdout と stderr の両方に同一機械可読メッセージを重複出力」に統一し、Unit 定義 / Story の stderr 要件と既存 emit_error の stdout 互換を両立する正式契約を明記） | - |
| 2 | 中 | `read_progress_slot` の対応範囲が `phase-recovery-spec.md §5.3.5` 完全準拠を謳いつつ、1 行カンマ区切り・grammar version・コメント等は非対応で、新形式記述を偽陰性扱いするリスク | 修正済み（logical_design.md §read_progress_slot / domain_model.md ProgressSlotReader を「意図的サブセット」として明示し、Unit 001 で規定した手順書の独立行記述運用前提と 04-completion.md §5 未コミット差分検出による二重防御を許容根拠として記述、§5.3.5 完全準拠は `ArtifactsStateRepository` の責務として切り出す境界を明確化） | - |
| 3 | 中 | `evaluate_post_merge_guard(..., pr_number_from_progress)` に未使用引数が残り、guard 内部で `read_progress_slot` を再呼び出しするため層分離が曖昧。`query_pr_state` の ad-hoc 文字列返却も guard 層に再パース責務を残す | 修正済み（logical_design.md §ガード判定層 / §処理フロー / シーケンス図を更新し、guard は正規化済み入力のみ受領、main 側で `read_progress_slot` / `query_pr_state` を先行実行、`query_pr_state` は `GUARD_PR_STATE` 等の正規化済みシェル変数セットで返却、gh 呼び出し最大 1 回の条件ガードを main 側にも追加） | - |

---

## Set 2: 2026-04-19 21:15:00 (Unit 002 コード AI レビュー)

- **レビュー種別**: コード（focus: code, security）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘0件

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `test_write_history_post_merge_guard.sh` L142 `run_guard_test()` が stdout/stderr を `2>&1` で束ねているため、「stdout と stderr の両方に同一メッセージを出す」契約を回帰テストで担保できていない。片チャネルだけに出てもテストが通るリスク | 修正済み（test_write_history_post_merge_guard.sh に `run_guard_test_split()` を追加し、TC_POST_MERGE_REJECT_EXPLICIT / TC_POST_MERGE_REJECT_FALLBACK / TC_POST_MERGE_REJECT_DRY_RUN の 3 ケースで stdout / stderr を個別に取得して両方の機械可読メッセージ存在を assert するように改修。reject 契約の両チャネル出力を回帰テストで明示的に検証） | - |
| 2 | 中（security） | fake gh が受け取った argv を検証せず常に固定 JSON を返すため、`gh pr view <pr_number> --json isDraft,state,mergedAt,number` という呼び出し契約の崩れや将来の pr_number サニタイズ抜けを検知できない | 修正済み（`setup_fake_gh()` を argv 検証版に強化: subcommand `pr view`、`pr_number` が `^[1-9][0-9]*$` に合致、`--json isDraft,state,mergedAt,number` の一致を検証し、逸脱時は exit 2 で失敗させる。加えて argv ログファイルに全引数を `\0` 区切りで記録し監査可能にした） | - |
| 3 | 低 | 未使用の `run_write_history()` ヘルパーが `AIDLC_CYCLES` 差し替え前提で残っており、実際の `bootstrap.sh` は `AIDLC_PROJECT_ROOT` から再計算するため実挙動と説明が不一致 | 修正済み（未使用ヘルパー `run_write_history()` を削除） | - |
| 4 | 低 | `skills/write-history/SKILL.md` の引数表で `--content` / `--content-file` が両方「Yes（排他）」と記載され、「両方必須だが同時指定不可」という矛盾した読み方を招く | 修正済み（SKILL.md L27-28 を「片方必須」表記に変更し、各行の説明で排他関係を明示） | - |

---

## Set 3: 2026-04-19 21:30:00 (Unit 002 統合 AI レビュー)

- **レビュー種別**: 統合（focus: code）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: 指摘0件

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | `read_progress_slot()` が `phase-recovery-spec.md §5.3.5` の「`#` 以降はコメント」を実装しておらず、`completion_gate_ready=true # done` や `pr_number=581 # merged` を値ごと取り込むため、運用中にコメント付き固定スロットが書かれた場合に第二条件が偽になって post-merge 誤呼び出しを見逃すリスク | 修正済み（write-history.sh L159 の sed パイプラインに `s/[[:space:]]*#.*$//` を追加し `#` 以降を除去。test_write_history_post_merge_guard.sh に `TC_POST_MERGE_REJECT_WITH_INLINE_COMMENT` を追加し inline comment 付き `completion_gate_ready=true # マージ前完結 / pr_number=581 # PR 番号` で第二条件が成立することを回帰検証。全 26 ケース PASS）。ドメインモデル / 論理設計の parser 仕様記述も inline comment 対応を明記 | - |
| 2 | 中 | 計画書・Unit 定義が stdout 主契約のままで、実装・設計・レビューサマリの「stdout+stderr 両出力」契約と文書間で不整合。さらに Unit 定義 L67 の実装状態が「未着手」のままで進行中の実態と乖離 | 修正済み（plans/unit-002-plan.md L16, L43, L53 を stdout+stderr 両チャネル契約に統一、Unit 定義 L13 を「標準出力と標準エラーの両方に同一機械可読メッセージ」に更新、L41 「診断性」節も両チャネル `<diagnostics>` フィールド付記に修正。Unit 定義の実装状態を「進行中」に更新し、担当・開始日を記録。完了処理（タスク #18）で「完了」に遷移させる運用） | - |

---
