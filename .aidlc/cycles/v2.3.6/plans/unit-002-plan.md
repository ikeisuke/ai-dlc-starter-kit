# Unit 002 実装計画 - write-history.sh マージ後呼び出しガード + 04-completion.md 禁止記述

## Unit 概要

`skills/aidlc/scripts/write-history.sh` に Operations Phase マージ後の呼び出しを検出・拒否するガードを実装し、併せて `skills/aidlc/steps/operations/04-completion.md` に「7.8〜7.13 以降で write-history.sh を呼ばない」明示的禁止記述を追加する。マージ後に発生する `history/operations.md` への未コミット追記（post-merge-sync.sh 前の差分残存）を防ぐ（#583-B / DR-001）。

## 完了条件チェックリスト

**Unit 定義「責務」由来**:

- [ ] `write-history.sh` に新引数 `--operations-stage`（有効値 `pre-merge` / `post-merge`、省略時は従来動作）が追加される。未定義値は exit 1（引数不正）で拒否する。
- [ ] 拒否判定の優先順位が DR-001 に従って実装される:
  - 第一条件: `--phase operations --operations-stage post-merge` が指定されたら即拒否（exit 3）。
  - 第二条件: 第一条件非該当時、`--phase operations` かつ `.aidlc/cycles/{{CYCLE}}/operations/progress.md` の `completion_gate_ready=true` が読め、かつ `gh pr view <pr_number> --json isDraft,state,mergedAt,number` で **`state=MERGED` かつ `mergedAt!=null` かつ 取得した `number` が要求 `prNumber` と一致** の AND 条件が満たされた場合に拒否（exit 3）。これは `phase-recovery-spec.md §5.3.4`（completion_done 判定）および §5.3.6（GitHubPullRequestGateway 信頼境界契約）と整合する。
  - それ以外: 従来動作（appended / created）。
- [ ] **エラー出力チャネル契約**: 拒否時は既存 `emit_error()`（`skills/aidlc/scripts/lib/validate.sh`）と同じ stdout チャネル**および** stderr の両方に、同一の機械可読メッセージ `error:post-merge-history-write-forbidden:<reason_code>:<診断>` を重複出力し、exit 3 で終了する（設計レビュー反映）。stdout 出力は既存 `emit_error` 互換（後方互換）、stderr 出力は Unit 定義 / Story 1.2 の受け入れ基準準拠。どちらのチャネルでも同一形式を保証する。診断メッセージは機械可読を維持し機密情報は含めない。
- [ ] 既存 exit code `1`（引数不正）/ `2`（I/O 失敗）の意味が維持され、exit `3` の新規割り当てによる破壊的影響がない。
- [ ] `--phase inception` / `--phase construction` の既存呼び出しは従来どおり appended / created を返し、exit 0 を維持する。
- [ ] `/write-history` スキル SKILL.md（`skills/write-history/SKILL.md`）の「出力」表に exit 3（`error:post-merge-history-write-forbidden`）が追記される。
- [ ] `write-history.sh` 冒頭コメントに exit 3 の意味と DR-001 への参照（または本 Unit の履歴リンク）が追記される。
- [ ] `skills/aidlc/steps/operations/04-completion.md` に「7.8〜7.13 以降で `write-history.sh` を呼ばない」明示的禁止記述と exit 3 の取り扱いが追加される。重複記述は避け 1 箇所に集約する。
- [ ] テスト整備: Story 1.2 の 5 ケース（`TC_POST_MERGE_REJECT_EXPLICIT` / `TC_POST_MERGE_REJECT_FALLBACK` / `TC_PRE_MERGE_GATE_READY_PASS` / `TC_PRE_MERGE_PASS` / `TC_INCEPTION_PASS`）が `skills/aidlc/scripts/tests/` 配下の回帰検証スクリプトで実行可能になる。

**関連 Issue「受け入れ基準」由来（#583 Story 1.2）**:

- [ ] `--phase operations --operations-stage post-merge` と `--dry-run` を組み合わせた場合も拒否され、exit 3 が返る（dry-run でも未コミット差分を発生させない）。
- [ ] `operations/progress.md` が存在しない／`completion_gate_ready` 行が空のケース、または `gh pr view` が失敗／PR が `state!=MERGED`／`mergedAt=null`／`number` 不一致のケースでは、第二条件を不成立（false）と判定し従来動作を維持する（偽陽性排除）。
- [ ] `gh` 実行失敗時（`cli_runtime_error` 等）は第二条件を undecidable 扱いとし、従来動作（appended / created）を継続する（DR-001 確定）。`§5.3.6` の必須フィールド欠損時の undecidable 扱いにも準拠する。
- [ ] `gh pr view` 呼び出しがガード判定中に最大 1 回に留まる（無駄な再実行を避ける実装最適化）。テストで呼び出し回数を fake `gh` により検証する。
- [ ] 拒否時の機械可読エラーコード（`error:post-merge-history-write-forbidden`）が Story 1.2 受け入れ基準どおり stdout に出力される（エラー出力チャネル契約に従う）。

## 実装方針

### Phase 1（設計）の扱い

`depth_level=standard` のため通常どおり設計ドキュメントを作成する。本 Unit はシェルスクリプト拡張 + 手順書追記 + スキル SKILL.md 追記の複合であり、以下を成果物とする:

- **ドメインモデル**: `.aidlc/cycles/v2.3.6/design-artifacts/domain-models/unit_002_write_history_post_merge_guard_domain_model.md`
  - 概念: Phase / OperationsStage / GuardDecision / PostMergeIndicator
  - ガード判定のドメインルール（DR-001 の第一条件 / 第二条件 / AND 評価 / undecidable 扱い）を明文化
- **論理設計**: `.aidlc/cycles/v2.3.6/design-artifacts/logical-designs/unit_002_write_history_post_merge_guard_logical_design.md`
  - 関数分解: `validate_operations_stage()` / `evaluate_post_merge_guard()` / `read_progress_slot()` / `query_pr_state()` / `emit_post_merge_rejection()`
  - 引数パース拡張・exit code 割り当て・**エラー出力フォーマットの具体化（設計レビュー反映: stdout の `emit_error` 拡張 + stderr への同一メッセージ重複出力の両チャネル契約）**
  - テストフィクスチャとテストケースの配置方針（`skills/aidlc/scripts/tests/` 配下）
- **設計レビュー**: `reviewing-construction-design` スキル（優先 codex）で実施する（`review_mode=required`）。
- **設計承認**: ゲート承認（`automation_mode=semi_auto` → フォールバック条件非該当なら `auto_approved`）。

### Phase 2（実装）の作業内容

1. **`write-history.sh` 拡張**:
   - `--operations-stage` 引数パース追加（`pre-merge` / `post-merge` のみ許容、それ以外は exit 1）。
   - 既存バリデーション後、`evaluate_post_merge_guard` 関数でガード判定を実施。
   - `exit 3` 時は履歴ファイルに書き込みを発生させず、`emit_post_merge_rejection` が stdout と stderr の両方に `error:post-merge-history-write-forbidden:<reason_code>:<診断>` を重複出力する（設計レビュー反映）。
   - `--dry-run` 時も拒否判定は行い、exit 3 で終了する（ファイル書き込みもシミュレーションもしない）。
2. **`completion_gate_ready` 読取（`read_progress_slot()` 契約）**:
   - `operations/progress.md` から `phase-recovery-spec.md §5.3.5` の grammar に従って読み取る。**本 Unit の対応サブセット**:
     - `key=value` 形式、値前後の空白トリム
     - キーが複数回現れた場合は **最初の出現値を採用**（spec §5.3.5 規則）
     - 値の boolean は `true`/`false` 小文字固定（それ以外は `format_error` 扱いで第二条件不成立）
     - 値の integer（`pr_number`）は `^[1-9][0-9]*$` のみ許容（0・負数・非数値は不成立扱い）
     - 未知キーは無視、行頭 `#` はコメントで無視
     - **本 Unit で対応しないサブセット**（明示的に宣言）: 1 行内カンマ区切り併記・grammar version HTML コメント検証（これらは復帰判定側 `ArtifactsStateRepository` の責務であり、本ガードは `completion_gate_ready` と `pr_number` のみを独立行から取得すれば十分）
   - ファイル不在時・行不在時・値が `true` 以外・grammar 不整合時は第二条件不成立扱い（undecidable を黙示的 false にマップする保守寄りの挙動）。
3. **`gh pr view` 呼び出し（`query_pr_state()` 契約）**:
   - `pr_number` は `read_progress_slot()` が返した整数値を使用。未取得時・0/負/非整数時は第二条件不成立（gh 呼び出しを発生させない）。
   - 呼び出しコマンド: `gh pr view <pr_number> --json isDraft,state,mergedAt,number` で `phase-recovery-spec.md §5.3.6` の信頼境界契約に従う。
   - 判定: `state == "MERGED" AND mergedAt != null AND number == <要求 pr_number>` の全てを満たすとき post-merge 成立。
   - **必須フィールド欠損時（`isDraft` / `state` / `number` のいずれかが null or 欠損）** または **未知 `state` 値** または **number 不一致** は undecidable 扱いとし従来動作継続（§5.3.6 準拠、安全側）。
   - 失敗時（非ゼロ終了 / 出力パース不能）は undecidable 扱い → 従来動作継続。呼び出しは 1 回限り（関数内キャッシュ化）。
4. **SKILL.md / help / コメント更新**:
   - `skills/write-history/SKILL.md` の以下を更新:
     - 引数表に `--operations-stage <pre-merge|post-merge>` を追記（省略時は従来動作、未定義値は exit 1）
     - 出力表に exit 3（`error:post-merge-history-write-forbidden`）を追記
     - Operations Phase 呼び出し例（`--operations-stage pre-merge` の正常例）を追加し、7.8〜7.13 以降は本スキル呼び出しが exit 3 で拒否される旨を注記
   - `write-history.sh` 冒頭コメント / help メッセージ（`show_help()`）に `--operations-stage` 追加・exit 3 の意味・DR-001 参照を追記（SKILL.md と同契約）。
5. **`04-completion.md` 禁止記述追加**:
   - §5 以降の適切な位置に「7.8〜7.13 以降で `write-history.sh` を呼ばない」旨の明示的禁止と exit 3 拒否動作を追記。重複しないように 1 箇所に集約。
6. **テスト整備**:
   - `skills/aidlc/scripts/tests/test_write_history_post_merge_guard.sh` を新設し、以下のケースを実装:
     - **Story 1.2 受け入れ基準 5 ケース**:
       - `TC_POST_MERGE_REJECT_EXPLICIT`: `--phase operations --operations-stage post-merge` → exit 3 + 指定エラーコード。
       - `TC_POST_MERGE_REJECT_FALLBACK`: `completion_gate_ready=true` + `gh` が `state=MERGED, mergedAt!=null, number==pr_number` を返すフィクスチャで `--phase operations` のみ → exit 3。
       - `TC_PRE_MERGE_GATE_READY_PASS`: `completion_gate_ready=true` だが `gh` が `state=OPEN` を返すケースで `--phase operations` → appended（第二条件不成立）。
       - `TC_PRE_MERGE_PASS`: `--phase operations --operations-stage pre-merge` → appended。
       - `TC_INCEPTION_PASS`: `--phase inception` → 既存動作維持。
     - **境界・異常系 追加ケース（Codex レビュー指摘 #4 対応）**:
       - `TC_POST_MERGE_REJECT_DRY_RUN`: `--phase operations --operations-stage post-merge --dry-run` → exit 3（dry-run でも拒否）。
       - `TC_FALLBACK_GH_FAILURE_PASS`: `gh pr view` 非ゼロ終了（`cli_runtime_error`）を模擬 → 第二条件 undecidable → appended（従来動作継続）。
       - `TC_FALLBACK_PROGRESS_MISSING_PASS`: `operations/progress.md` 不在 → 第二条件不成立 → appended。
       - `TC_INVALID_OPERATIONS_STAGE`: `--operations-stage unknown-value` → exit 1（引数不正、exit 3 ではない）。
       - `TC_GH_CALLED_ONCE`: `--phase operations` でガード判定時、fake `gh` が 1 回だけ呼ばれることを検証（実装最適化契約）。
       - `TC_FALLBACK_MERGED_AT_NULL_PASS`: `state=MERGED` だが `mergedAt=null` → undecidable → appended（§5.3.6 準拠）。
       - `TC_FALLBACK_NUMBER_MISMATCH_PASS`: `gh` 応答の `number` が要求 `pr_number` と不一致 → undecidable → appended（§5.3.6 準拠）。
   - `gh` 呼び出しは `PATH` 先頭に fake `gh` スクリプトを置く方式で差し替える（呼び出し回数検証のためカウンタファイルを使用）。詳細実装は論理設計で固定。
   - フィクスチャとして一時 `progress.md` と fake `gh` を用意するヘルパー関数を追加（`mktemp -d` によるサンドボックス + クリーンアップ）。
7. **コードレビュー**: `reviewing-construction-code` スキル（優先 codex）で実施。
8. **統合レビュー**: ビルド・テスト完了後に `reviewing-construction-integration` スキルで実施。

### 境界外（本 Unit では扱わない）

- `operations-release.md` §7.6 への固定スロット反映ステップ追加（Unit 001 で完了済み）。
- `phase-recovery-spec.md` 本体の仕様記述変更（参照のみ）。
- Inception progress.md 命名統一・CHANGELOG 追記（Unit 003）。
- Draft PR Actions スキップ（Unit 004）。
- `--operations-stage` の追加拡張（`ready-for-review` 等）は本 Unit では扱わない（YAGNI）。
- `/write-history` スキル SKILL.md の引数仕様破壊的変更（既存引数はそのまま維持、`--operations-stage` の新規追加のみ）。

## 影響範囲

- 変更ファイル（予想）:
  - `skills/aidlc/scripts/write-history.sh`（引数追加 + ガード実装 + 冒頭コメント更新 + help メッセージ更新）
  - `skills/write-history/SKILL.md`（引数表に `--operations-stage` 追加 + 出力表に exit 3 追記 + Operations 呼び出し例追加）
  - `skills/aidlc/steps/operations/04-completion.md`（禁止記述追加）
  - `skills/aidlc/scripts/tests/test_write_history_post_merge_guard.sh`（新規テストスクリプト）
  - 必要に応じて `skills/aidlc/scripts/lib/` 配下にヘルパー追加（例: `read_progress_slot` / `query_pr_state`）。
- コマンド/スクリプト変更: 上記テストスクリプト追加のみ。既存テスト挙動は維持する。
- 下流影響:
  - Operations Phase を次回以降実施する AI エージェントがマージ後に誤って `/write-history` を呼んでも exit 3 で拒否される。
  - Inception / Construction Phase の既存呼び出しには影響しない。
  - 外部プロジェクト（Visitory 等）でも同じスキルを使う場合、同じガードが効く。

## 見積もり

1 日（Unit 定義の見積もりと同じ）

## 依存関係

- 依存する Unit: なし（Unit 001 とは独立に着手可能。技術的にも運用上も並列実装可能だが、本サイクルでは Unit 001 完了後 → Unit 002 の順で進行）。
- 外部依存: なし（シェルスクリプト + 手順書 + スキル SKILL.md のみ）。

## 参考資料

- Issue #583（本文 + 提案 3）
- ストーリー 1.2（`story-artifacts/user_stories.md` 行 39–79）
- DR-001（`inception/decisions.md`）
- `phase-recovery-spec.md §5.3.5`（固定スロット grammar 正規定義）
- Unit 001 計画（参考フォーマット）
