# Unit 004 論理設計: predecessor handoff の Issue 検索化

## 1. 設計方針

| パターン / 原則 | 適用箇所 | 目的 |
|----------------|---------|------|
| **Strategy Pattern**（経路ごとの解決ロジックを別関数化） | 5 経路（Milestone+label / label-fallback / spool / v2.5.0-compat / warn-continue）の各 strategy 関数 | 判定順分岐とロジック実装を分離、テスト容易性確保 |
| **Pure Function**（純粋関数の内部公開） | `_pure_classify_resolution_path` / `_pure_format_query_args` / `_pure_sort_by_closed_at_desc` | 副作用なしでテスト最大化（Unit 002 / Unit 003 の `_pure_*` パターン踏襲） |
| **Adapter Pattern**（gh CLI への薄いラッパー） | `__pred_gh_query` / `__pred_read_spool_issue_url` | `gh` CLI 仕様変更や mock 化を局所化 |
| **Single Source of Truth**（命名規約 / バリデーション） | Intent §6.1 / Unit 002 `__retro_validate_cycle` / `__retro_gh_status` を借用 | 重複実装を避け一貫性確保 |

## 2. ファイル構成

| ファイル | 種別 | 提供 |
|---------|------|------|
| `skills/aidlc/scripts/lib/predecessor-issue.sh` | 新規 | `predecessor_resolve_issue` 公開 + 純粋関数群 + strategy 関数群 |
| `skills/aidlc/steps/inception/01-setup.md` | 改修 | §4a を Issue 検索 + 統一優先順位表 + spool fallback + v2.5.0 互換 fallback + warn-continue に書き換え |
| `skills/aidlc/templates/predecessor_retrospective.md` | 削除 | 物理削除（テンプレ廃止） |
| `tests/predecessor-issue-handoff.bats` | 新規 | 経路 1/1'/2/3/4 + 各複数件分岐 + バリデーション失敗 + Unit 002 `_spool_extract_entries` 連携 |

## 3. 公開 I/F（`predecessor-issue.sh`）

### 3.1 `predecessor_resolve_issue(prev_cycle: String) -> 0 | 1 | 2`

**入力**: 前サイクルのバージョン名（例: `v2.5.0`）。

**責務**: 候補集合の取得 + 解決経路の確定 + 1 件採用 / 0 件 → 次経路移行のみを担う**純ロジック関数**。AskUserQuestion 起動 / 対話 I/O は一切行わない（AI エージェント側の責務 / Unit 003 の責務分離パターン踏襲）。

**出力（stdout）**: 解決結果を NDJSON 1 行で出力（呼出側がパース）

```json
{"resolution_path": "milestone_and_label|label_fallback|spool_fallback|v2_5_0_compat|warn_continue",
 "issue_url": "https://...|null",
 "file_path": "cycles/.../retrospective.md|null",
 "source_milestone": "v2.5.0|null",
 "candidates": [{"url": "...", "title": "...", "closedAt": "..."}, ...]}
```

- 1 件確定時: `issue_url` に単一 URL / `candidates` は 1 要素配列
- 複数件確定（経路 1 / 1'）時: `issue_url` は `null` / `candidates` に全候補を `closedAt` 降順で格納（AI エージェント側が AskUserQuestion で選択）
- 経路 3 採用時: `issue_url` は `null` / `file_path` 設定 / `candidates` 空
- 経路 4 採用時: `issue_url` / `file_path` ともに `null` / `candidates` 空

**stderr**: `<level>\t<code>\t<detail>` フォーマット

**exit code**:
- 0: 成功（継続可能エラーで fallback 経路を取った場合も含む / 経路 4 で warn 出力した場合も含む）
- 1: 継続不能エラー（`gh` 致命的エラー: `__retro_gh_status` 自体が起動不能 / spool 読み取り I/O エラー / awk/jq 内部エラー）
- 2: 引数エラー（`prev_cycle` 不正 / `__retro_validate_cycle` 失敗）

**継続可能 vs 継続不能の分類**: domain model §7「例外と境界」テーブルを参照。`predecessor_gh_error` (warn) は exit 0 + spool fallback / `predecessor_gh_fatal` (error) は exit 1。

### 3.2 内部関数（`_` prefix or `__pred_` prefix）

```text
_pure_classify_resolution_path(gh_status, milestone_enabled, query_count, spool_exists, compat_file_exists) -> ResolutionPath
_pure_format_query_args(prev_cycle, milestone_enabled) -> List<String>
_pure_sort_by_closed_at_desc(issues_json) -> List<Issue>  # 並び替えのみ / 自動選択しない
__pred_gh_query(prev_cycle, milestone_enabled) -> IssueQueryResult
__pred_read_spool_issue_url(spool_path) -> Option<URL>
__pred_read_compat_file(prev_cycle) -> Option<Path>
__pred_diag(level, code, detail) -> stderr
```

## 4. 統一優先順位表（実装フロー）

```
[predecessor_resolve_issue(prev_cycle)]
  1. __retro_validate_cycle(prev_cycle) → 失敗 → exit 2 (predecessor_invalid_cycle)
  2. gh_status = __retro_gh_status()
  3. milestone_enabled = read-config.sh project.milestone_enabled (default: true)
  4. spool_path = "cycles/${prev_cycle}/history/retrospective-spool.md"
  5. compat_path = "cycles/${prev_cycle}/operations/retrospective.md"
  6. spool_exists, compat_file_exists を事前計算
  7. 経路 1 試行（gh_status=available × milestone_enabled=true）
     - __pred_gh_query で Issue 検索
     - count=1: 自動採用 → 経路 1 確定 → exit 0（issue_url 単一値）
     - count≥2: 候補リスト全体（closedAt 降順ソート）を NDJSON 出力 → AI エージェント側で AskUserQuestion 起動 → exit 0（candidates 配列 / issue_url=null）
     - count=0: 次経路へ
  8. 経路 1' 試行（gh_status=available × milestone_enabled=false）
     - 同上（label のみ検索）→ count≥2 でも候補リスト出力（closedAt 降順 / AI エージェント側で必ず確認 / 自動採用しない）
  9. 経路 2 試行（spool fallback）
     - __pred_read_spool_issue_url(spool_path) → Some(URL): 経路 2 確定 / None: 次経路
 10. 経路 3 試行（v2.5.0 互換）
     - compat_file_exists=true: 経路 3 確定（file_path 設定）/ false: 次経路
 11. 経路 4: warn + continue（exit 0 / コンテキスト変数すべて未設定）
 12. NDJSON で結果を stdout に出力
```

## 5. stderr 診断コード一覧

| level | code | 発生条件 | exit code |
|-------|------|---------|-----------|
| info | predecessor_resolved_milestone_label | 経路 1 確定（1 件採用） | 0 |
| info | predecessor_resolved_label_fallback | 経路 1' 確定（1 件採用） | 0 |
| info | predecessor_resolved_spool | 経路 2 確定 | 0 |
| info | predecessor_resolved_compat | 経路 3 確定 | 0 |
| info | predecessor_candidates_emitted | 経路 1 / 1' で複数件ヒット → AI エージェントへ候補リストを引き渡し | 0 |
| warn | predecessor_no_reference | 経路 4（全経路 0 件 / continue） | 0 |
| warn | predecessor_gh_error | gh CLI 一時エラー（継続可能）→ spool fallback へ移行 | 0 |
| warn | predecessor_spool_invalid | spool 形式不正（継続可能）→ v2.5.0 互換へ移行 | 0 |
| error | predecessor_invalid_cycle | `__retro_validate_cycle` 失敗（引数エラー） | 2 |
| error | predecessor_gh_fatal | gh CLI 致命的エラー（継続不能 / `__retro_gh_status` 起動不能等） | 1 |
| error | predecessor_io_error | spool / 互換ファイル I/O エラー（継続不能） | 1 |

## 6. 01-setup.md §4a の改修方針

### 6.1 削除対象

- `predecessor_retrospective.md` 関連の手動配置案内（line 80-95 周辺の bash スニペット含む）
- 旧フローの 3 分岐（分岐 (a) / (b) / (c) ）への言及

### 6.2 追加対象

- 統一優先順位表（経路 1 / 1' / 2 / 3 / 4）の説明
- `predecessor_resolve_issue` 呼び出しの bash スニペット（呼出層では純ロジックのみ実行 / 対話 I/O は AI エージェント層）
  ```bash
  source skills/aidlc/scripts/lib/predecessor-issue.sh
  result_json=$(predecessor_resolve_issue "${PREV_CYCLE}")
  predecessor_retrospective_issue_url=$(printf '%s' "$result_json" | jq -r '.issue_url // empty')
  predecessor_retrospective_file_path=$(printf '%s' "$result_json" | jq -r '.file_path // empty')
  candidates_count=$(printf '%s' "$result_json" | jq -r '.candidates | length')
  ```
- AI エージェント側のアクション分岐（責務分離）:
  - `issue_url` が単一値 → そのまま採用、`gh issue view` で本文取得して Intent 前提として参照
  - `issue_url=null` × `candidates_count >= 2` → **AskUserQuestion を起動**して候補リストから選択。選択された URL を `predecessor_retrospective_issue_url` に再設定（候補は `closedAt` 降順 / 必ず確認を通す）
  - `file_path` が設定済み → Read ツールで読み取り、Intent 前提として参照
  - すべて未設定（経路 4） → predecessor 参照なしで継続（warn 表示）

### 6.3 残存テンプレ警告

- ステップ実行時に `skills/aidlc/templates/predecessor_retrospective.md` が残存していたら stderr `warn\tpredecessor_template_residual\t...` を出力（自動削除はしない）

## 7. テストケース（`tests/predecessor-issue-handoff.bats`）

| ID | 観点 | 動作 |
|----|------|------|
| P1 | 経路 1 / 1 件 / 自動採用 | gh_status=available × milestone_enabled=true × Issue 1 件 → exit 0 / NDJSON `resolution_path=milestone_and_label, issue_url=...` / candidates 1 要素 |
| P2 | 経路 1 / ≥ 2 件 / 候補リスト出力 | gh モックで複数件返却 → exit 0 / NDJSON `issue_url=null, candidates=[...]` / `info\tpredecessor_candidates_emitted` / 関数本体は対話起動しない（AskUserQuestion は AI エージェント側責務） |
| P3 | 経路 1 / 0 件 → 経路 2 移行 | gh モックで 0 件 + spool 存在 → 経路 2 採用 / `info\tpredecessor_resolved_spool` |
| P4 | 経路 1' / 1 件 / milestone_enabled=false | label 単独検索 1 件 → 経路 1' 確定 |
| P5 | 経路 1' / ≥ 2 件 / closedAt 降順並び替えのみ | label のみ + 複数件 → `_pure_sort_by_closed_at_desc` で並び替えた候補リスト出力 / 関数は自動採用しない（AI エージェント側で確認必須） |
| P6 | 経路 1' / 0 件 → 経路 2 移行 | label のみ + 0 件 + spool 存在 → 経路 2 |
| P7 | 経路 2 / spool ファイル存在 / URL 取得成功 | gh 不可 + spool 存在 + Unit 002 `_spool_extract_entries` 経由 → 経路 2 確定 |
| P8 | 経路 2 / spool 不在 → 経路 3 移行 | gh 不可 + spool 不在 + 互換ファイル存在 → 経路 3 |
| P9 | 経路 3 / 互換ファイル存在 | 1/1'/2 すべて 0 件 + 互換ファイル存在 → 経路 3 確定（file_path 設定） |
| P10 | 経路 4 / 全経路 0 件 / warn + continue | すべて 0 件 / exit 0 / `warn\tpredecessor_no_reference` |
| P11 | gh_status=unavailable で経路 2 直接遷移 | gh 不可 + spool 存在 → 経路 2（経路 1/1' をスキップ） |
| P12 | prev_cycle 不正で exit 2 | `prev_cycle="../../etc/passwd"` → `__retro_validate_cycle` 失敗 → exit 2 |
| P13 | spool 形式不正で経路 2 失敗 → 経路 3 移行 | spool ヘッダ不正（Unit 002 が exit 2）→ Unit 004 で次経路へフォールバック |
| P14 | テンプレ削除確認 | `skills/aidlc/templates/predecessor_retrospective.md` が存在しないことを assert |

## 8. リスク緩和

- **R1（Issue 検索のレート制限）**: `--limit 50` で打ち切り + 結果は `closedAt` 降順並び替え後に上位を提示
- **R2（spool 内部構造への依存）**: 必ず `_spool_extract_entries` 経由 / Unit 004 では `jq -r .issue_url` のみ抽出 / 不足時は Unit 002 へ reader 公開関数追加を依頼
- **R3（milestone_enabled 設定の解決経路分散）**: `read-config.sh project.milestone_enabled` で統一参照
- **R4（v2.5.0 互換 fallback の優先順位）**: §4 の統一優先順位表で固定 + BATS で 5 経路すべて verify
- **R5（gh issue list --state all 仕様）**: BATS モックで closed Milestone 配下 Issue の取得経路を verify

## 9. 完了条件チェックリストとの対応

| Plan 完了条件 | 設計対応箇所 |
|--------------|-------------|
| 統一優先順位表 1/1'/2/3/4 で §4a 書き換え | §6.2（実装方針） |
| `predecessor_retrospective.md` 関連手動配置案内が grep で 0 件 | §6.1（削除対象） |
| `skills/aidlc/templates/predecessor_retrospective.md` 物理削除 | §2 ファイル構成（削除） |
| 経路 1 / 1' / 2 / 3 / 4 BATS 検証 | §7 P1-P11 |
| `gh_status != available` で経路 2 直接遷移 | §7 P11 |
| コンテキスト変数の経路別設定 | §6.2（呼出 bash スニペット） |
| DR-005 整合 | §3.1（公開 I/F）+ §6.2 |
| 判断 6.1 整合 | §1 設計方針（Single Source of Truth） |
| Unit 002 中核ライブラリの参照のみ | §3.2 / §1 / I4 |
| `bin/check-bash-substitution.sh` 規約 | 実装側で `printf` 経由 + `_pure_*` 関数を活用 |
