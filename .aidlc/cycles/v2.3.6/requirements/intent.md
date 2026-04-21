# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit v2.3.6（patch サイクル）

## 開発の目的

以下 2 件の patch 級 Issue を解消する。

1. **#583 [Feedback] operations-release.md §7.6 に release_gate_ready 反映指示がなく、progress.md がマージ前完結しない**
   - パターン A: 固定スロット（`release_gate_ready` / `completion_gate_ready` / `pr_number`）を §7.7 最終コミットに確実に含めるよう、`skills/aidlc/steps/operations/operations-release.md` §7.6（および同節から参照される §7.2–§7.6 の手順補足が必要な箇所）へ明示的な更新ステップを追加する。
   - パターン B: マージ後（7.8〜7.13 以降）の `/write-history` 呼び出しによる `history/operations.md` 追記を防ぐため、`skills/aidlc/scripts/write-history.sh` に Operations Phase ポストマージ呼び出しの検知・拒否ガードを追加し、`skills/aidlc/steps/operations/04-completion.md` に「write-history.sh をマージ後に呼ばない」明示的禁止記述を加える。
2. **#565 [Backlog] Inception progress.md の Part/ステップ命名を統一する**
   - `inception_progress_template.md` を含む progress.md 表記の「ステップ1〜N」統一。
   - 参照側（`phase-recovery-spec.md` §5.1 の progress.md 状態参照文脈 / `steps/inception/index.md` のチェックポイント表 / Inception の step ファイル本文 / `task-management.md` / 各 verify-*-recovery.sh のフィクスチャ生成）の progress.md 表記のみ命名を追従更新する。`session-continuity.md` は旧命名参照を含まないため対象外（`rg` 検出時のみ追従）。
3. **Draft PR 時の GitHub Actions ジョブスキップ（サイクル追加要件、DR-004）**
   - ドラフト PR ではレビュー確定前の試行差分で runner を消費しないよう、`pull_request` トリガーのワークフロー（`pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml`）で Draft の間は job を `skipped` 状態にとどめ（runner は起動せず分単位を消費しない）、`ready_for_review` 時に初回実行する構成へ変更する。workflow run 自体は `types` 該当イベントで作成され得るが、ジョブが `skipped` ステータスになることで runner リソースは消費しない。`auto-tag.yml`（push トリガー）は対象外。

## ターゲットユーザー

- AI-DLC Starter Kit を利用してプロダクト開発する開発者チーム
- メタ開発者（スターターキット自体の改善を行う本リポジトリの開発者）

## ビジネス価値

- Operations Phase の「マージ前完結契約」が手順書レベルで確実に機能し、post-merge clean-up で未コミット差分に迷うケースが解消する。
- 固定スロットの反映漏れが 7.8 以降に発生せず、session-continuity / 復帰判定の新形式判定源が main ブランチ上で常に機能する。
- Inception progress.md の命名が一貫し、進捗表の認知負荷が下がる。
- `steps/inception/index.md` / `phase-recovery-spec.md` の progress.md 状態参照文脈における表記が揃い、ドキュメント相互整合性が向上する（checkpoint 名称 `completion_done` 等は変更しない）。

## 成功基準

1. **#583-A**: `skills/aidlc/steps/operations/operations-release.md` の §7.6 に、固定スロット更新（`release_gate_ready=true` / `completion_gate_ready=true` / `pr_number=<PR番号>`）を §7.7 最終コミットに含めるステップが明示される。併せて §7.2–§7.6 で参照すべき固定スロット反映ポイントも整合的に更新される。
2. **#583-B（Intent 固定契約）**: `skills/aidlc/scripts/write-history.sh` に以下の挙動を持つガードが実装される。
   - **入力源**: 呼び出し引数（`--phase` / 新規 `--operations-stage`）を主とする。補助として `.aidlc/cycles/{{CYCLE}}/operations/progress.md` の `completion_gate_ready` と `gh pr view` による GitHub PR 実態確認（`state=MERGED`）の **AND 条件**を参照する（DR-001 参照）。
   - **拒否条件**: 第一条件 `--phase=operations` かつ `--operations-stage=post-merge`、または第二条件 `--phase=operations` かつ `completion_gate_ready=true` かつ `gh pr view` で PR が `state=MERGED` と確認できる場合。
   - **返却**: 標準エラーに `error:post-merge-history-write-forbidden` 形式のメッセージを出力し、exit code `3` で拒否（`1=引数不正` / `2=I/O 失敗` とは区別）。
   - **非拒否**: `phase` が `inception` / `construction` の通常呼び出し、および Operations でも 7.7 以前の呼び出し（PR 未マージ）は従来動作を維持する。`gh` 実行失敗時（`cli_runtime_error` 等）は第二条件を undecidable 扱いとし、従来動作（appended / created）を継続する。
3. **#583-B（記述）**: `skills/aidlc/steps/operations/04-completion.md` に「7.8〜7.13 以降で `write-history.sh` を呼ばない」明示的禁止記述が追加される。
4. **#565-1**: `skills/aidlc/templates/inception_progress_template.md` が「ステップ1〜N」統一命名になる。
5. **#565-2**（対象列挙）: 以下のファイル群で progress.md 表記・参照が新命名に整合する。他のファイルに旧命名参照が残った場合も本サイクル内で追従する（完了条件: `rg "Part [0-9]+"` / `rg "^\|\s*完了処理"`（テーブル行先頭の「完了処理」）/ `rg "ステップ[0-9]+-[0-9]+"`（旧「ステップ1-5」表記）が **progress.md 進捗テーブル文脈**で 0 ヒットになる。ただし `phase-recovery-spec.md` の `completion_done` など checkpoint 名称（意味論ラベル）は本サイクルの変更対象外とする）。
   - `skills/aidlc/templates/inception_progress_template.md`
   - `skills/aidlc/steps/inception/index.md`
   - `skills/aidlc/steps/inception/01-setup.md`
   - `skills/aidlc/steps/inception/02-preparation.md`
   - `skills/aidlc/steps/inception/04-stories-units.md`
   - `skills/aidlc/steps/inception/05-completion.md`
   - `skills/aidlc/steps/common/phase-recovery-spec.md`（progress.md 状態参照文脈のみ、checkpoint 名称は非対象）
   - `skills/aidlc/steps/common/task-management.md`
   - `skills/aidlc/scripts/verify-inception-recovery.sh`（フィクスチャ生成関数）
   - `skills/aidlc/scripts/verify-construction-recovery.sh` / `verify-operations-recovery.sh`（Inception 進捗参照分のみ）
6. **検証**: 新サイクル開始時に `inception/progress.md` が統一命名で生成され、セミオート復帰判定が正常に機能する（`verify-inception-recovery.sh` 全シナリオ合格）。
7. **後方互換**: `v1.x〜v2.3.5` の既存 `inception/progress.md` を読み取って復帰判定が動作することを、フィクスチャまたはスポット検証で確認する（旧命名 `Part` 表記を含む progress.md を読み込み可能）。
8. **CHANGELOG**: リリースノートに v2.3.6 エントリを追加する。
9. **Draft PR スキップ（Unit 004）**: `.github/workflows/pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml` の 3 本で、`on.pull_request.types` に `[opened, synchronize, reopened, ready_for_review]` を明記し、`jobs.*.if: github.event.pull_request.draft == false` の二段ガードを適用する。Draft PR では workflow run が作成されても該当ジョブが `skipped` 状態になり、runner 分単位を消費しない。`ready_for_review` 遷移時に初回実行される（runner が起動し `in_progress` → `completed` 経由で成功/失敗判定される）。既存の paths フィルタは維持する。

## 期限とマイルストーン

- patch リリースのため、単一サイクル内でマージまで完結する（予算: 小）。
- 各 Unit は 1〜2 日で完結する粒度を想定する。

## 制約事項

- patch リリース（v2.3.6）のため、破壊的仕様変更・公開 API 変更は行わない。
- `RecoveryJudgmentService.judge()` / `PhaseResolver` の契約シグネチャは変更しない。
- `phase-recovery-spec.md` の `completion_done` など checkpoint 名称は変更しない（意味論の維持）。
- `skills/aidlc/` プラグイン外への参照・依存は追加しない。
- `.aidlc/rules.md` のメタ開発原則（スキル内リソース編集は `skills/aidlc/` 相対、スキル実行時はベース相対）を遵守する。

## 含まれるもの

- `#583-A` `skills/aidlc/steps/operations/operations-release.md` §7.6（および関連節）への固定スロット反映ステップ追加。
- `#583-B` `skills/aidlc/scripts/write-history.sh` へのマージ後呼び出しガード追加（成功基準 2 の契約）、および `skills/aidlc/steps/operations/04-completion.md` への禁止記述追加。
- `#565-1` `inception_progress_template.md` の「ステップ1〜N」統一命名。
- `#565-2` 成功基準 5 に列挙した参照ファイル群の追従更新。
- 命名変更後の進捗判定検証（`verify-inception-recovery.sh` 全シナリオ合格と、既存 v1.x〜v2.3.5 サイクルに対するスポット検証）。
- リリースノート / CHANGELOG への v2.3.6 エントリ追加。
- `Unit 004` `.github/workflows/pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml` の 3 本に Draft PR スキップの二段ガード（`types` + ジョブレベル `if`）を導入する（Draft 中はジョブ `skipped` 扱いで runner を消費しない）。

## 含まれないもの

- `#581` Operations 復帰判定 new_format 実装完成（別サイクル）。
- `#582` cycle 関連ファイルの別リポジトリ分離（別サイクル）。
- `#573` 旧キーの自動移行（別サイクル）。
- `#568` 原始人プロンプト検討（別サイクル）。
- `rules.linting.enabled` などの設定キー体系変更。
- session-continuity の復帰判定 API シグネチャ変更（契約維持）。
- Operations Phase 04-completion.md のマージ前完結契約の破壊的変更（追加ガード以外の修正はしない）。
- `phase-recovery-spec.md` の checkpoint 名称（`completion_done` 等）の改名。
- write-history.sh における exit code `1`（引数不正）/ `2`（I/O 失敗）の既存意味の変更。

## 不明点と質問（Inception Phase中に記録）

[Question] `#583-B` の Operations ステップ判定は progress.md の固定スロット状態（`release_gate_ready` / `completion_gate_ready`）を内部参照して行うか、呼び出し引数のみで判定するか？
[Answer] DR-001（`decisions.md`）で確定。第一条件 `--operations-stage=post-merge`、第二条件 `completion_gate_ready=true` AND `gh pr view` で `state=MERGED` の AND 判定。`completion_gate_ready` 単独は pre-merge でも真になり得るため、post-merge 識別には GitHub 実態確認との AND が必要。

[Question] `#565` の命名統一で `phase-recovery-spec.md` の checkpoint 名称（`completion_done` や「完了処理セクション」の語）を変更する必要はあるか？
[Answer] 成功基準 5 および「含まれないもの」で明示したとおり、checkpoint 名称は意味論維持のため変更対象外。変更対象は進捗テーブル参照文脈のみ。
