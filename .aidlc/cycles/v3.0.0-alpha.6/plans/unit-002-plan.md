# Unit 002 実装計画: PR 整備 + release.md テンプレート + review ルーティング

## 対象 Unit

`002-pr-preparation-release-template-and-review-routing` — release フェーズ **Step 2「PR 整備」** を `steps/release.md` に実装する。PR 作成（既存時は更新）、`release.pr_number` の state.json 書き込み、`templates/release.md` 新規作成と release.md 成果物の生成、release-level review（premerge / integration / deploy）の perspective ルーティングを担う。

- **サイクル**: v3.0.0-alpha.6 / **depth_level**: standard / **automation_mode**: semi_auto / **review_mode**: required
- **依存 Unit**: 001（完了 / `steps/release.md` 骨格 + Step 1 が前提）
- **関連 Issue**: #736（部分対応 / Relates）

## スコープ

### 含まれるもの（本 Unit で実装）

1. **`steps/release.md` の Step 2「PR 整備」実装**（Unit 001 のプレースホルダを実装に差し替え）
   - PR 分岐: 未作成時は `gh pr create`、`early_pr: true`（define 時 Draft PR 済み）時は本文更新のみ。
   - PR 作成時に `release.pr_number` を `scripts/state-write.sh release.pr_number <N>` で書き込み、`scripts/state-validate.sh` で検証。
   - `release.md` 成果物を `templates/release.md` から生成。
   - Step 2 ゲートは「**PR ready 確認**」（ready 化操作そのものは Unit 003 / Step 3）。
2. **`templates/release.md` の新規作成**
   - セクション: PR 概要 / work item 完了一覧 / **review 結果サマリ（機械可読）** / CI 状態 / merge 記録。
   - **review 結果サマリは Unit 003 の semi_auto merge ゲートの入力契約**となるため、perspective ごと（premerge / integration / deploy）の結果・**未解決指摘数**・**最高重要度**・**merge blocker 有無**を機械可読に記録するセクションを含める（Unit 002→003 データ契約）。
3. **release-level review ルーティング**
   - `premerge` 常時 / `integration`（`status:done` 2 件以上）/ `deploy`（`size:risky` の done 1 件以上）。
   - 既存 reviewing スキル（`reviewing-operations-premerge` / `reviewing-construction-integration` / `reviewing-operations-deploy`）へ `review-routing.md` 経由で委譲。
   - review 結果は `release.md` に集約し `reviews/*.md` を生成しない（`data-model.md §8`）。

### 含まれないもの（境界 / 後続 Unit）

- PR の ready 化操作・`release.ready` 書き込み・merge（Unit 003 / Step 3）。
- `release.merge_approved` 書き込み・post-merge cleanup（Unit 003）。
- state.json schema 変更（既存 `release.pr_number` のみ書き込み。`ready`/`merge_approved` は触らない）。
- reviewing スキル本体の改修（9→1 統合）は行わない（既存スキルへ委譲のみ）。
- `SKILL.md` の `release` 公開フリップ・express 整合・新規テスト本格追加（Unit 004）。本 Unit は既存 v3 テスト green の sanity 確認に留める。

## 設計 SoT（再定義せず参照）

- `docs/v3/workflow.md §3.3`（Step 2）/ `§6`（review perspective / §6.1 実行条件・§6.2 size×review）
- `docs/v3/data-model.md §3`（`release.pr_number` 書き込みタイミング）/ `§8`（成果物要否）/ `§10`（release review は release.md 集約）
- `skills/aidlc/steps/common/review-routing.md §3`（CallerContext → skill_name / focus）/ `review-flow.md`（反復・指摘対応）

## 実装アプローチ

1. **Step 2 の構成**（release.md に節として実装 / Step 1 と同じ書式）:
   - 2-1 PR 解決（fail-closed / 重複作成防止 = レビュー #1）: `state-read.sh release.pr_number` を読み、
     (a) 値あり → その PR を更新（`gh pr edit`）/
     (b) `null` かつ同一 head branch の open PR が 1 件 → その番号を `release.pr_number` に書き込み（2-2）て更新 /
     (c) `null` かつ open PR なし → `gh pr create` で作成（2-2 で番号書込）/
     (d) 同一 head branch に open PR が複数 → **fail-closed で停止**（ユーザー解決）。
     `early_pr: true`（define 時 Draft PR）も (a)/(b) の経路で番号を確定し、**重複 PR を作らない**。
   - 2-2 `release.pr_number` 書き込み: PR 作成時 / (b) で番号確定時に `state-write.sh release.pr_number <N>`（exit 0=written / 1=validation / 2=system）→ `state-validate.sh` で `status:valid` 確認。
   - 2-3 release.md 生成: `templates/release.md` を起点に成果物を `.aidlc/cycles/<cycle>/release.md` に生成。
   - 2-4 release-level review ルーティング（caller_context 写像明記 = レビュー #4）: 実行条件（premerge 常時 / integration ≥2 done / deploy risky done≥1）を判定し、各 perspective を以下の写像で既存スキルへ委譲する。`review-routing.md` には `routing_review_mode = [rules.reviewing].mode`（config 値）を渡し、**perspective 名を `review_mode` 引数に渡さない**（混同回避）:

     | perspective | 実行条件 | caller_context | skill_name | focus |
     |-------------|---------|----------------|-----------|-------|
     | premerge | 常時 | PR マージ前 | `reviewing-operations-premerge` | code, security |
     | integration | `status:done` 2 件以上 | 統合とレビュー | `reviewing-construction-integration` | code |
     | deploy | `size:risky` の done 1 件以上 | デプロイ計画承認前 | `reviewing-operations-deploy` | architecture |

     結果を release.md の review 結果サマリ（機械可読 / 下記契約）に集約する。
   - 2-5 Step 2 ゲート: PR ready 確認（ready 化操作は Step 3 / Unit 003）。
2. **PR 操作**: `gh` 直接呼び出しを基本とし、ラッパは最小限（設計時判断）。PR 本文は file-based（`gh pr create/edit --body-file <file>`）。
3. **state.json 書き込み**: `release.pr_number` のみ。schema 不変。
4. **Bash ツール安全規約**: 手順内コマンド例に `$(...)` / backtick を使わない。
5. **gh 不在時（停止 = レビュー #2）**: PR・`release.pr_number` は release Step 2 の必須成果物であり Unit 003 の merge 入力でもあるため、`gh_status != available` 時は warn-continue ではなく**停止**する（PR 未確定では Step 2 完了不可）。例外として「ユーザーが既存 PR 番号を手動提示 → `gh pr view <N>` で存在確認 → `release.pr_number` 書き込み」が成立する場合のみ続行可。
6. **ドッグフーディング特殊処理を埋め込まない**。

## 変更ファイル

| ファイル | 操作 | 内容 |
|---------|------|------|
| `skills/aidlc-v3/steps/release.md` | 編集 | Step 2 プレースホルダを実装に差し替え |
| `skills/aidlc-v3/templates/release.md` | 新規作成 | PR 概要 / work item 完了一覧 / review 結果サマリ（機械可読）/ CI 状態 / merge 記録 |

- `SKILL.md` は変更しない（公開フリップは Unit 004）。
- state.json schema・既存スクリプトは変更しない（`release.pr_number` 書き込みは既存 `state-write.sh` 利用）。

## review 結果サマリ（機械可読 / Unit 002→003 データ契約）

`templates/release.md` の review 結果サマリは、Unit 003 の semi_auto merge ゲートが「高重要度未解決指摘なし」を判定する入力となる。**parse 安定性のため、固定マーカーで囲んだ機械可読ブロック（YAML）として定義する**（レビュー #3）。Unit 003 はこのブロックのみを読む:

```text
<!-- aidlc-release-review:start -->
schema_version: "1.0"
reviews:
  - perspective: premerge        # premerge | integration | deploy
    status: passed               # passed | failed | skipped
    unresolved_count: 0
    max_severity: none           # high | medium | low | none
    merge_blocker: false
    skip_reason: null            # status=skipped 時に理由文字列、それ以外は null
  - perspective: integration
    status: skipped
    unresolved_count: 0
    max_severity: none
    merge_blocker: false
    skip_reason: "done が 1 件のため未実行（条件: 2 件以上）"
merge_blocker_any: false         # いずれかの perspective が merge_blocker=true なら true
<!-- aidlc-release-review:end -->
```

- **parse 契約（境界明確化 = レビュー R2 #3）**: マーカー間（`<!-- aidlc-release-review:start -->` の**次行**から `<!-- aidlc-release-review:end -->` の**前行**まで）は**純 YAML のみ**とし、Unit 003 はその範囲をそのまま YAML として parse する。マーカー間に markdown コードフェンス（` ``` `）・見出し・他の装飾を置かない（上記の ` ```text ` フェンスは本計画書での提示用であり、`templates/release.md` 内ではマーカーと純 YAML のみを配置する）。
- **必須フィールド**: `schema_version` / 各 review の `perspective` / `status` / `unresolved_count` / `max_severity` / `merge_blocker` / `skip_reason` / トップレベル `merge_blocker_any`。
- **merge_blocker の定義**: 当該 perspective に高重要度（`high`）の未解決指摘があれば `true`。
- **欠損時挙動（Unit 003 側契約）**: マーカー不在・マーカー間が純 YAML として parse 不能・必須フィールド欠落・enum 外の値は **fail-closed**（Unit 003 の semi_auto 自動 merge を許可せずユーザー確認へフォールバック）。本 Unit はテンプレートに当該ブロックを必ず生成する責務を持つ。

## テスト方針

- 新規テストファイルの本格追加は Unit 004。本 Unit では release.md Step 2 手順が依存する既存スクリプト（`state-write.sh` / `state-validate.sh` / `state-read.sh`）の挙動が前提どおりであることを確認し、既存 v3 テスト 7 スイートを実行して green（回帰ゼロ）を sanity 確認する。
- `gh` 依存部分はドライ検証（実 PR を作らない）で扱い、ネットワーク非依存にする。

## NFR

- **互換性**: state.json schema 不変。書き込みは `release.pr_number` のみ。既存 v3 テスト green 維持。
- **保守性**: PR 操作は `gh` 直接 + 最小ラッパ。review perspective マッピングの正本は `workflow.md §6` / `review-routing.md §3`（再定義せず参照）。
- **セキュリティ**: PR 本文・release.md に機密情報を含めない（review-flow のマスク方針準用 / file-based body）。
- **クロスプラットフォーム**: コマンド例は macOS / Linux 両対応。

## 完了条件チェックリスト

- [ ] `steps/release.md` の Step 2「PR 整備」が実装され、Unit 001 のプレースホルダが実装に置き換わっている
- [ ] PR 解決が fail-closed で実装されている（pr_number あり=更新 / null+open PR 1 件=番号採用更新 / null+PR なし=作成 / 複数=停止）。`early_pr` で重複 PR を作らない
- [ ] PR 作成 / 番号確定時に `release.pr_number` を `state-write.sh` で書き込み `state-validate.sh` で検証する手順がある
- [ ] `templates/release.md` が新規作成され、PR 概要 / work item 完了一覧 / review 結果サマリ / CI 状態 / merge 記録のセクションを持つ
- [ ] review 結果サマリが固定マーカー付き機械可読ブロック（YAML）で、`schema_version`/`perspective`/`status(passed|failed|skipped)`/`unresolved_count`/`max_severity(high|medium|low|none)`/`merge_blocker`/`skip_reason`/`merge_blocker_any` を持つ（Unit 002→003 契約 / 欠損時 fail-closed）
- [ ] release.md 成果物をテンプレートから生成する手順がある
- [ ] release-level review ルーティングが perspective→caller_context 写像（premerge→PR マージ前 / integration→統合とレビュー / deploy→デプロイ計画承認前）で既存スキルに委譲され、`routing_review_mode=[rules.reviewing].mode` を渡す（perspective 名を `review_mode` に渡さない）
- [ ] review 結果は release.md に集約し `reviews/*.md` を生成しない（data-model §8）
- [ ] Step 2 ゲートが「PR ready 確認」であり、ready 化・merge は本 Unit で扱っていない（Unit 003 境界遵守）
- [ ] state.json schema 変更なし（`release.pr_number` のみ書き込み）
- [ ] `gh_status != available` 時は停止（PR 未確定で Step 2 完了不可 / 手動 PR 番号提示 + `gh pr view` 確認の例外のみ続行）
- [ ] Bash ツール安全規約（`$(...)` / backtick 不使用）を手順内コマンド例に適用
- [ ] SoT（docs/v3）を再定義していない / 既存 v3 テスト green（回帰ゼロ）

## 見積もり

1 日（PR 整備 + template + review ルーティング）
