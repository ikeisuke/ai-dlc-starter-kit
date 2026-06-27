# ユーザーストーリー

## Epic: v3 release フロー（Phase 5）

`skills/aidlc-v3` に release フェーズを実装し、`define → develop` 済みのサイクルを「main に安全に取り込む」ところまで v3 単独の手順で到達できるようにする。設計 SoT: `docs/v3/workflow.md §3.3`（Step 1–4）/ `docs/v3/data-model.md §3・§5・§8`。

---

### ストーリー 1: リリース準備ゲート（全 work item 完了検出）
**優先順位**: Must-have

As a AI-DLC を使う開発者
I want to release 開始時に全 work item が完了（`done` / `withdrawn`）しているかを自動検出してほしい
So that 未完了の work item が残ったまま誤って PR 整備・merge に進むのを防げる

**受け入れ基準**:
- [ ] `steps/release.md` の Step 1 で、全 work item の frontmatter `status` が `done` または `withdrawn` のときのみ次ステップ（PR 整備）へ進む
- [ ] `pending` / `in_progress` / `blocked` の work item が 1 件でも残る場合、release を開始せず、未完了 work item の一覧（ID・status）を提示して停止する
- [ ] `define_completed: false`（または state.json 不在）の場合は release フェーズに入らず、define/develop への案内を表示する
- [ ] 完了判定には既存 `state-read.sh` / `work-item-validate.sh` を read-only で利用し、新たな状態書き込みは行わない
- [ ] git status / CI・test 状態の確認結果に応じた挙動が明記される:
  - dirty worktree（未コミット変更あり）→ 停止し、コミットを促す
  - test 失敗 → 停止する（release に進まない）
  - CI 失敗 → 停止する
  - CI 未実行 → 警告表示して続行可（Step 3 の merge 前 CI パス確認で再評価する）

**技術的考慮事項**:
フェーズ導出の正本は `data-model.md §5.1`。release.md は導出規則を再定義せず参照する。

---

### ストーリー 2: PR 整備と release.md 作成
**優先順位**: Must-have

As a AI-DLC を使う開発者
I want to release フェーズで PR を作成（既存時は更新）して ready 化し、その状態を state.json に記録してほしい
So that 複数 work item 完了後のレビュー・merge 準備を一貫した手順で進められる

**受け入れ基準**:
- [ ] PR 未作成時は作成、`early_pr: true`（define 時に Draft PR 作成済み）の場合は本文更新のみ行う分岐がある
- [ ] PR 本文を作成・更新し、`release.md`（成果物）を `templates/release.md` から作成する
- [ ] PR 作成時に `release.pr_number` を既存 `state-write.sh` 経由で state.json に書き込み、書き込み後に `state-validate.sh` で検証する
- [ ] Step 2 のゲートは「PR ready 確認」であり、PR の **ready 化操作と `release.ready` 書き込みは Step 3（ストーリー4）で行う**（`workflow.md §3.3` / `data-model.md §3.3`「`release.ready` は PR ready 化時に書き込み」と整合）
- [ ] state.json schema は変更しない（既存 3 フィールドのみ使用）
- [ ] `templates/release.md` が新規作成され、PR 概要・work item 完了一覧・review 結果サマリ・CI 状態・merge 記録のセクションを持つ

**技術的考慮事項**:
PR 操作（create/edit/ready）は `gh` 直接呼び出しを基本とし、原子性・テスト容易性のため最小限のラッパのみスクリプト化（Construction 設計判断）。

---

### ストーリー 3: release-level review ルーティング
**優先順位**: Must-have

As a AI-DLC を使う開発者
I want to release Step 2 で work item の状況に応じた観点のレビューが実行され、結果が release.md に集約されてほしい
So that merge 前に必要な観点（premerge / integration / deploy）の品質確認が抜けなく行われる

**受け入れ基準**:
- [ ] `premerge` perspective のレビューを **常時**実行する
- [ ] `integration` perspective を追加実行する条件: `status: done` の work item が **2 件以上**のとき（`withdrawn` は実装変更を伴わないためカウントに含めない）
- [ ] `deploy` perspective を追加実行する条件: frontmatter `size: risky` の work item が **1 件以上 `done`** で存在するとき（判定元は各 work item の frontmatter `size` / `status`）
- [ ] 各 review は既存 reviewing スキル（`reviewing-operations-premerge` / `reviewing-construction-integration` / `reviewing-operations-deploy`）へ `review-routing` 経由で委譲する（9→1 統合は後続 Phase のため Phase 5 では委譲）
- [ ] release-level review の結果は `release.md` に集約し、work item 単位の `reviews/*.md` には残さない（`data-model.md §8` 保存先契約）

**技術的考慮事項**:
review perspective マッピングの正本は `workflow.md §6` / `review-routing.md §3`。

---

### ストーリー 4: Merge 承認記録と merge 実行
**優先順位**: Must-have

As a AI-DLC を使う開発者
I want to merge 承認を merge 実行前に state.json へ記録してから merge してほしい
So that merge 後にブランチが消えても「誰が merge を承認したか」の証拠が残り、complete 判定が成立する

**受け入れ基準**:
- [ ] Step 3 で PR を **ready 化**し、`release.ready: true` を `state-write.sh` 経由で state.json に書き込む（`data-model.md §3.3`「`release.ready` は PR ready 化時に書き込み」）
- [ ] ready 化後に CI パスを確認してから merge する
- [ ] `release.merge_approved: true` を **merge 前の最終コミット**で state.json に書き込み、commit + push してから merge を実行する（`data-model.md §3.3` の書き込みタイミング契約）
- [ ] merge は `gh pr merge` で実行し、`merge_method` 設定（config）に従う
- [ ] merge 承認ゲートが `automation_mode` に応じて動作する:
  - `manual`: ユーザーの明示確認を必須とする（確認なしに merge しない）
  - `semi_auto`: 承認前提（CI green / release-level review に高重要度の未解決指摘なし / PR が未 merged）をすべて満たす場合に自動で `merge_approved` を書き込み merge する。いずれか未充足ならユーザー確認へフォールバックする
- [ ] complete 判定は `merge_approved`（state.json）と PR 実態（`gh pr view` で merged）の両方を要する旨が手順に明記され、release.md は導出規則を再定義しない

**技術的考慮事項**:
merge_approved 単独では complete としない（`data-model.md §5.1` 評価順 1）。

---

### ストーリー 5: Post-merge cleanup
**優先順位**: Must-have

As a AI-DLC を使う開発者
I want to merge 後にローカルブランチの後始末と journal への記録を行ってほしい
So that 次のサイクルに移る前にリポジトリ状態が整い、release の完了が記録に残る

**受け入れ基準**:
- [ ] Step 4 でローカルを統合先ブランチへ switch し、merge 済み feature branch を削除する
- [ ] `journal.md` に release 完了を追記する
- [ ] tag 作成は `version_tag` 設定が真のときのみ（opt-in）実行する
- [ ] changelog 追記は `changelog` 設定が真のときのみ（opt-in）実行する
- [ ] tag / changelog が opt-out（既定）でも release フローは正常完了する（core ワークフロー成立に不要）

**技術的考慮事項**:
GitHub Milestone close / GitHub Release 自動作成 / Projects 登録 / deploy checklist 強制は v3 core から外す（`workflow.md §3.3`）。

---

### ストーリー 6: SKILL.md 統合・express 整合・テスト
**優先順位**: Must-have

As a 本キットのドッグフーディング開発者
I want to `release` コマンドが実装済みになり、express 経路が release まで到達し、新規分のテストで品質が担保されてほしい
So that v3 が `define → develop → release` を通しで提供でき、Phase 6 の前提（v3 単独フルサイクル）が揃う

**受け入れ基準**:
- [ ] `SKILL.md` の `release` コマンドが「予約」から実装済みに更新され、ルーティング先 `steps/release.md` を指す
- [ ] express ラッパ（work item 1 つ・risky なし時の `define → develop → release` 連続実行）が release まで到達する記述になっている
- [ ] release フロー新規分の検証（scripts のユニット/契約テスト、または手順のドライ検証）が `scripts/tests/` に追加されている
- [ ] 既存 v3 テスト（`scripts/tests/`）が green を維持する
- [ ] state.json schema・フェーズ導出・review perspective の SoT（docs/v3）を本サイクルで再定義していないことを確認する

**技術的考慮事項**:
本サイクル自身の release は v2 Operations で行う（dogfooding は Phase 7）。
