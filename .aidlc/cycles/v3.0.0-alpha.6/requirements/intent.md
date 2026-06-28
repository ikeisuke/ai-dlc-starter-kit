# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit — v3 リニューアル Phase 5「release フロー」

## 開発の目的

v3（`skills/aidlc-v3`）に **release フェーズ**を実装し、`define → develop` まで進んだサイクルを「main に安全に取り込む」ところまで v3 単独の手順で到達できるようにする。これは Epic #736「v3 リニューアル Phase 4–7 完遂ロードマップ」の Phase 5 にあたり、設計 SoT は `docs/v3-renewal-plan.md`「Phase 5: release」および `docs/v3/workflow.md §3.3` / `docs/v3/data-model.md §3・§5`。

Phase 4（develop normal/risky 分岐）までで「実装」までは v3 で回せるが、release フローが未実装のため work item 完了後に PR 整備・review・merge・post-merge を v3 の手順で扱えない。本サイクルでこの最後の歯抜けを埋め、Phase 6（reflect + doctor）完了後の「v3 単独フルサイクル完走」の前提を揃える。

## ターゲットユーザー

- **AI-DLC を使う開発者**: `/aidlc-v3 release`（および将来の `/aidlc release`）で、複数 work item 完了後に PR を整備し安全に main へ merge できる。
- **本キットのドッグフーディング開発者（自分）**: Phase 7 で v3 を本流化する前提として、release フローの完成を必要とする。

## ビジネス価値

- v3 が `define → develop → release` の 3 フェーズを通しで提供できるようになり、Phase 6 完了後の「v3 をスキルとして使える」状態に一歩近づく。
- v2 の Operations Phase（多数の step / script / 固定スロット）に対し、release を `release.md`（〜150–200 行）+ 既存 state スクリプト再利用 + 既存 reviewing スキルへのルーティングで構成し、v3 設計目標「読み込み量・成果物数の削減」を release フェーズでも実証する。
- `release.merge_approved` の merge 前記録により、merge 後にブランチが消えても「誰が merge を承認したか」の証拠が state.json に残る監査性を担保する。

## 成功基準

- `skills/aidlc-v3/steps/release.md` が新規作成され、`docs/v3/workflow.md §3.3` の Step 1–4（リリース準備 / PR 整備 / Merge 承認+実行 / Post-merge）を手順として記述している。
- 全 work item 完了（`done` / `withdrawn` のみ）を `work-item-validate.sh` 等で検出でき、未完了（`pending` / `in_progress` / `blocked`）が残る場合は release を開始しないゲートがある。
- PR を作成（`early_pr: true` 時は更新のみ）し、ready 化できる。`release.pr_number` / `release.ready` を `state-write.sh` 経由で state.json に記録できる。
- merge 前の最終コミットで `release.merge_approved: true` を記録し、その後 merge を実行する手順がある（`data-model.md §3.3` の書き込みタイミング契約に準拠）。
- merge 後の cleanup（ローカル branch 更新 / feature branch 削除 / journal.md への release 完了追記）ができる。tag（`version_tag`）・changelog（`changelog`）は config による opt-in。
- `templates/release.md`（release 成果物テンプレート）が新規作成されている。
- release Step 2 の review が perspective ルーティング（常時 `premerge` / 複数 work item 完了時 `integration` / risky 時 `deploy`）に従う。release-level review の結果は `release.md` に集約し、work item 単位の `reviews/*.md` には残さない（`data-model.md §8` 成果物保存先契約）。
- `SKILL.md` の `release` コマンドが「予約」から実装済みに更新され、ルーティング先 `steps/release.md` を指す。
- 既存 v3 テスト（`scripts/tests/`）が green を維持し、release フロー新規分の検証（scripts のユニット/契約テスト、または手順のドライ検証）が追加されている。

## 期限とマイルストーン

- サイクル: **v3.0.0-alpha.6**（Phase 5 = 1 サイクル / Epic #736）。
- 後続: Phase 6（reflect + doctor）→ v3.0.0-alpha.7、Phase 7（dogfooding + 本流化）。
- 本サイクルは Inception → Construction → Operations を通常どおり v2（`/aidlc`）で進行する。

## 含まれるもの（スコープ）

- `skills/aidlc-v3/steps/release.md` の新規作成（workflow.md §3.3 Step 1–4 / data-model.md §3・§5 を正本として参照）。
- `skills/aidlc-v3/templates/release.md` の新規作成。
- release フローでの state.json 書き込み手順（`release.pr_number` / `release.ready` / `release.merge_approved`）— 既存 `state-write.sh` / `state-read.sh` / `state-validate.sh` を再利用。スキーマ変更はしない。
- PR 整備（作成 or 更新 / ready 化）・merge 実行・post-merge cleanup の手順。tag / changelog は opt-in。必要に応じた release 補助スクリプト（`gh` 操作の薄いラッパ / state 更新の原子化）。
- release Step 2 review の perspective ルーティング（premerge 常時 / integration 複数時 / deploy risky 時）— 既存 reviewing スキルへ委譲。review 結果は `release.md` に集約（`reviews/*.md` 非生成 / `data-model.md §8`）。
- `SKILL.md` の `release` コマンドを実装済みに更新（ルーティング・express ラッパ整合）。
- 新規分のテスト追加と既存テストの green 維持。

## 含まれないもの（非スコープ）

- v2（`skills/aidlc`）側の変更・置換・本流化（Phase 7）。
- 9 reviewing スキルの `aidlc-review`（9→1）統合実装（後続 Phase / RFC §1 課題 3）。Phase 5 は既存 reviewing スキルを呼び出す。
- `reflect`（Retrospective）フローの実装（Phase 6）。
- `doctor.sh` / status 表示拡充（Phase 6）。
- alpha.6 自身のリリースを v3 release フローで実行すること（= dogfooding は Phase 7）。本サイクルの実リリースは v2 Operations で行う。
- state.json schema の拡張・変更（release 3 フィールドは確定済み。新フィールドが必要と判明した場合はスコープ外として別途確認）。
- GitHub Milestone close / GitHub Release 自動作成 / Projects 登録 / deploy checklist 強制 / monitoring 強制（v3 で core から外す方針 / workflow.md §3.3）。

## 既存機能との関連

- **既存 v3 資産の再利用**: `state-read.sh` / `state-write.sh` / `state-validate.sh` / `work-item-validate.sh`（read-only 確認）を再利用。
- **define/develop 手順がお手本**: `steps/define.md` / `steps/develop.md` の「Step + ゲート + 成果物 + スクリプト契約」書式を踏襲。
- **v2 Operations が設計参考**: `operations-release.md` / `operations-release.sh` / `pr_body_template.md` を構造参考（コード直接流用は非推奨、v3 では新規実装）。
- **express ラッパ整合**: SKILL.md の express 経路が release を参照済みのため、release.md 実装で初めて連続実行が release まで到達する。

## 制約事項

- **設計 SoT 厳守**: フェーズ導出（`data-model.md §5`）・state.json フィールド契約（§3）・review perspective（`workflow.md §6`）は本サイクルで再定義せず参照する。
- **merge_approved 記録タイミング**: merge 前の最終コミットで `true` を記録（§3.3）。
- **Bash ツール安全規約**: `$(...)` / backtick のコマンド置換禁止（CLAUDE.md / Issue #697）。result-out 関数の local 命名規約遵守。
- **クロスプラットフォーム**: 新規スクリプトは macOS / Linux 両対応（BSD/GNU 差に注意）。
- **review_mode=required**: 成果物承認前に codex レビュー必須。

## トレーサビリティ

- Relates to #736（Epic: v3 リニューアル Phase 4–7 完遂ロードマップ / Phase 5）
- 設計 SoT: `docs/v3-renewal-plan.md`「Phase 5: release」/ `docs/v3/workflow.md §3.3・§6` / `docs/v3/data-model.md §3・§5・§8`

## 不明点と質問（Inception Phase中に記録）

[Question] release フローで PR 操作（create/ready/merge）を `gh` 直接呼び出しで release.md に書くか、新規補助スクリプト（v2 の `operations-release.sh` 相当の薄いラッパ）に切り出すか。
[Answer]（Construction の設計判断とする）v3 設計目標「成果物数削減」を踏まえ、まず release.md からの `gh` 直接呼び出し + `state-write.sh` を基本とし、原子性・再試行・テスト容易性のために最小限のラッパが必要な箇所のみスクリプト化する方針。Unit 設計時に確定。

[Question] release Step 2 の review は既存 v2 reviewing スキル（`reviewing-operations-premerge` 等）をそのまま呼ぶ理解でよいか。
[Answer] よい。9→1 統合（aidlc-review）は後続 Phase のため、Phase 5 では既存 reviewing スキルへ `review-routing` 経由で委譲する（develop の code/design review と同じ方式）。
