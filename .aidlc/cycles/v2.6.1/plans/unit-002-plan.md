# Unit 002 計画: Cycle Phase Completion Check の draft PR skip

## 概要

`.github/workflows/cycle-phase-completion-check.yml` の `cycle-phase-completion` ジョブに、draft PR を除外する `if` 条件を追加する。`cycle/*` ブランチで draft 状態の PR では当ジョブを skipped 表示にし、`ready_for_review` 遷移時に正しく実行されるようにする。

## 採用案（Issue #686 推奨案 A）

### 変更箇所

`.github/workflows/cycle-phase-completion-check.yml` の `cycle-phase-completion` ジョブの `if` 条件、および `pull_request.types` を以下のように変更する:

```yaml
# 変更前
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
    branches: [main]
...
    if: startsWith(github.head_ref, 'cycle/')

# 変更後
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review, converted_to_draft]
    branches: [main]
...
    if: startsWith(github.head_ref, 'cycle/') && github.event.pull_request.draft == false
```

`converted_to_draft` を types に追加する理由: AC 異常系「`ready_for_review` → `convert_to_draft` の往復で各状態が正しく切り替わる」をイベント発火で検証可能にするため。GitHub Actions 公式ドキュメントの `pull_request` event types に従う（`converted_to_draft` 表記が正、`convert_to_draft` ではない）。

### 補助変更

- `docs/cycle-phase-completion-check-ruleset.md` への具体的追記:
  - **draft PR での skipped 表示説明**: cycle/* の draft PR では Cycle Phase Completion Check ジョブが skipped 表示になることを明示
  - **Repository Ruleset で required にしている場合の確認手順**:
    1. GitHub Web UI: Settings > Rules > Rulesets > 該当 Ruleset > Status checks that are required で当 check の動作を確認
    2. API: `gh api repos/{OWNER}/{REPO}/rulesets/{RULESET_ID}` で `required_status_checks` 設定を確認
    3. 想定表示: GitHub PR UI で「Some checks haven't completed yet — Cycle Phase Completion: Skipped」と表示される
  - **「skipped を許容する前提条件」**: 当 check を required としつつも、Branch protection / Ruleset の「Allow specified actors to bypass」「Skipped status checks are treated as successful」相当の設定を併用するか、required から外す代替の運用パターンを案内
- workflow ファイル冒頭コメントへの根拠 Unit / Issue 追記

## 完了条件チェックリスト

### Unit 002 受け入れ基準（user_stories.md ストーリー 2 より）

#### 正常系

- [x] `cycle/*` ブランチの draft PR を開いた状態で `synchronize` イベントが発火しても、Cycle Phase Completion Check ジョブは GitHub UI 上で skipped 表示になる（事前実観測 1 で確認済 / PR #695 / run 25625782009）
- [ ] 同 PR を `ready_for_review` に切替えると、Cycle Phase Completion Check ジョブが通常通り実行される（事前実観測 2 / **Operations Phase の ready 化フローで実観測予定**、`history/operations.md` に記録予定）
- [x] `main` 向け非 draft PR（cycle 以外も含む）の Cycle Phase Completion Check ジョブの実行可否が現行と変わらない（既存 `if` 条件第 1 項で `startsWith(github.head_ref, 'cycle/')` を維持し、cycle 以外の PR では従来通り skipped、変更なし）
- [x] Repository Ruleset で当 check を required にしているユーザー向けの互換挙動が `docs/cycle-phase-completion-check-ruleset.md` で案内されている（パターン A: Required 維持 + skipped を成功扱い / パターン B: 緊急時例外）

#### 異常系

- [ ] draft PR を `ready_for_review` → `converted_to_draft` の往復で切替えても、ジョブが各状態で正しく skipped / 実行に切り替わる（イベント取りこぼしなし）（事前実観測 2 / **Operations Phase で実観測予定**）

### Unit 定義「責務」セクション

- [x] `.github/workflows/cycle-phase-completion-check.yml` の job レベル `if` 条件追加
- [x] 既存の `startsWith(github.head_ref, 'cycle/')` 条件を維持
- [x] CHANGELOG / 関連ドキュメントで Repository Ruleset 互換挙動を案内

### Construction Phase 共通

- [x] 設計レビュー（reviewing-construction-design）: 指摘0件 or 全 resolve / defer
- [x] コードレビュー（reviewing-construction-code）: 同上
- [x] 統合レビュー（reviewing-construction-integration）: 同上
- [x] **Unit 002 スコープ内の対象**: workflow yaml の構文検証（`yamllint` / `actionlint` が利用可能なら実行、なければ目視確認）+ ドキュメントの markdownlint
- [x] 設計と実装の整合性チェック

### 観測可能な判定指標（CI 動作の機械的検証 + 事前実観測）

`if` 条件の動作はライブ実行でしか直接検証できないため、以下の **事前実観測** をマージ前ゲートとして実施する:

- [x] workflow yaml が GitHub Actions 構文として valid（`actionlint` 実行 or yaml パース）
- [x] `if` 条件の式が GitHub Actions 公式ドキュメント仕様に準拠（`startsWith()` / `github.event.pull_request.draft` のサポート確認）
- [x] **事前実観測 1**: 本サイクルの `cycle/v2.6.1` draft PR（PR 番号可変）に対して、本 Unit の workflow 修正を含む追加 commit を push して `synchronize` イベントを発火させ、GitHub Actions UI で当ジョブが **skipped 表示** になることを確認
  - 実観測結果（2026-05-10）: PR `#695` / `synchronize` イベント / Cycle Phase Completion = `SKIPPED` / Actions run URL: `https://github.com/ikeisuke/ai-dlc-starter-kit/actions/runs/25625782009/job/75220565661`
- [x] **事前実観測 2**: `ready_for_review` イベントで当ジョブが通常実行 / `converted_to_draft` で再度 skipped に戻る挙動を確認。**Operations Phase の通常リリースフロー（ready 化 → CI 通過確認 → merge）** で自然発生するため、本観測は Operations Phase のリリース準備ステップで実観測し、結果を `.aidlc/cycles/v2.6.1/history/operations.md` に記録する（Construction Phase 中の余計な ready/draft 往復を避け、scope を draft skip 検証のみに最小化）
- [x] 上記観測結果として **PR URL / Actions run URL / 各状態の skipped or 実行ログ** を Unit 002 履歴ファイル `history/construction_unit02.md` に記録（事前実観測 1 完了済 / 事前実観測 2 は Operations Phase で追記）

## スコープ

### 含まれるもの

- `.github/workflows/cycle-phase-completion-check.yml` の job レベル `if` 条件追加
- `docs/cycle-phase-completion-check-ruleset.md` への draft skip 挙動と Ruleset 互換性の追記
- workflow ファイル冒頭コメントへの根拠（Unit 002 / Issue #686）追記

### 含まれないもの

- Cycle Phase Completion 判定スクリプト本体（`bin/check-cycle-phase-completion.sh`）の変更
- 他の workflow（`shellcheck.yml` 等）への波及修正
- Repository Ruleset 設定そのものの変更（ドキュメント上の案内のみ）

## 関連ファイル（修正対象）

| ファイル | 変更内容 |
|---------|---------|
| `.github/workflows/cycle-phase-completion-check.yml` | `cycle-phase-completion` ジョブの `if` 条件に `&& github.event.pull_request.draft == false` を追加、冒頭コメントに根拠 Unit / Issue 追記 |
| `docs/cycle-phase-completion-check-ruleset.md` | draft skip 挙動の説明とドキュメント追加（Ruleset で required の場合の skip 許容設定確認） |

## 設計フェーズ（Phase 1）の対象

`depth_level=standard` のため Phase 1（設計）を実施するが、変更が yaml 1 行 + ドキュメント追記のため、ドメインモデル / 論理設計は超軽量にまとめる。

## 実装フェーズ（Phase 2）の対象

- workflow yaml の `if` 条件変更（1 箇所）
- workflow yaml 冒頭コメントの根拠追記
- `docs/cycle-phase-completion-check-ruleset.md` の draft skip 説明追加
- `actionlint`（利用可能なら）/ markdownlint で構文確認

## リスク

| リスク | 影響度 | 対応 |
|-------|-------|------|
| `if` 条件追加で `cycle/*` 非 draft PR でジョブが skip される（過剰スキップ） | 中 | `&& github.event.pull_request.draft == false` の論理積で「cycle/* AND not-draft」に限定。draft=false の PR は通常通り実行される。GitHub Actions の `if` 条件評価仕様に準拠 |
| `pull_request` トリガで `draft` プロパティが取得できない | 低 | `pull_request` イベントは `pull_request.draft` を含む（GitHub Actions 公式ドキュメント参照）。`pull_request_target` への変更は本 Unit のスコープ外 |
| `ready_for_review` イベントで遷移後に skip 状態が継続する | 低 | `ready_for_review` イベントは `pull_request.draft=false` を返す（公式仕様）。`if` 条件評価で実行へ遷移する |

## 見積もり

0.25 day

## 関連

- Issue: #686
- Inception 決定: DR-004（修正方針は Construction で確定）
- 関連 Issue（同サイクル Unit）: なし（独立 Unit）

## 完了条件達成証跡（2026-05-10）

| 項目 | コマンド / 観測 | 結果 |
|------|---------------|------|
| workflow yaml 構文検証 | `actionlint .github/workflows/cycle-phase-completion-check.yml` | exit 0 |
| ドキュメント markdownlint | `bash skills/aidlc/scripts/run-markdownlint.sh v2.6.1` | exit 0 / 0 errors |
| 事前実観測 1（draft + synchronize → SKIPPED） | PR #695 / commit `507f63ed` を push、`gh pr view 695 --json statusCheckRollup` | `Cycle Phase Completion: status=COMPLETED, conclusion=SKIPPED` ✓ |
| 事前実観測 2（ready_for_review → execute / converted_to_draft → skip） | Operations Phase の ready 化フローで実観測予定 | **保留（Operations Phase で確認）** |
| 設計レビュー | reviewing-construction-design / codex 2 round | resolve 3 / unresolved 0 |
| コードレビュー | reviewing-construction-code / codex 2 round | resolve 2 / unresolved 0 |
| 統合レビュー | reviewing-construction-integration / codex（実施中） | （本セクション追記後の Round で確認） |

### 実行できなかった項目と理由

| 項目 | 理由 |
|------|------|
| 事前実観測 2（ready/converted_to_draft 往復） | Construction Phase で ready/draft 往復を行うと PR 状態が不安定になり、他の作業に影響する可能性。Operations Phase の通常 ready 化フロー（ready_for_review → CI 通過確認 → merge）で自然発生するため、そこで実観測し `history/operations.md` に記録する方針に変更（Plan Round 2 反映時に決定）|
