# Session Continuity

フェーズ再開時の進捗復元とコンパクション復帰の共通手順。復帰判定は `steps/common/phase-recovery-spec.md` の `judge()` 契約に従う。

## フェーズ別の進捗源

各フェーズの進捗源は `RecoveryJudgmentService.judge()` が内部で参照する実装データである。呼び出し層は `judge()` の戻り値 `PhaseRecoveryJudgment` を消費する形で進捗源を参照する。

| フェーズ | 復元元 | `judge()` 内部参照先 |
|---------|--------|-------------------|
| Inception | `inception/progress.md` + `judge()` 契約経由の `step_id` 決定 | `steps/inception/index.md`（binding） + `phase-recovery-spec.md` §5.1（規範仕様） |
| Construction | Unit定義ファイル（`story-artifacts/units/*.md`）の「実装状態」セクション（Stage 1 / Unit 特定） + `history/construction_unit{NN}.md`（Stage 2 / Step 特定） + `judge()` 契約経由の `step_id` 決定 | `steps/construction/index.md`（binding） + `phase-recovery-spec.md` §5.2（規範仕様） |
| Operations | `operations/progress.md`（直線評価） + `history/operations.md`（bootstrap 判定 / release_done / completion_done 評価で参照） + `judge()` 契約経由の `step_id` 決定 | `steps/operations/index.md`（binding） + `phase-recovery-spec.md` §5.3（規範仕様） |

## コンパクション復帰

コンパクション復帰と判定された場合は `steps/common/compaction.md` を読み込む。`compaction.md` の「復帰フローの確認手順」で `judge()` 契約を介した判定を行う。
