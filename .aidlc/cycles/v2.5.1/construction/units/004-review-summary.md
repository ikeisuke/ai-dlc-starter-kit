# レビューサマリ: Unit 004 predecessor handoff の Issue 検索化

## 基本情報

- **サイクル**: v2.5.1
- **フェーズ**: Construction
- **対象**: Unit 004 predecessor handoff の Issue 検索化

---

## Set 1: 2026-05-05（計画レビュー）

- **レビュー種別**: 計画レビュー（reviewing-construction-plan）
- **使用ツール**: codex（read-only モード）
- **反復回数**: 4（指摘 3 → 1 → 1 → 0 件 / 千日手検出なし）
- **結論**: 指摘 0 件 / `auto_approved`（review_mode=required × automation_mode=semi_auto × unresolved_count=0 × フォールバック非該当）

### 指摘一覧

| # | 重要度 | focus | round | 内容 | 対応 | バックログ |
|---|--------|-------|-------|------|------|-----------|
| 1 | 高 | architecture | 1 | 判定順の本文に v2.5.0 互換 fallback の実行位置が明示されておらず、spool fallback との前後関係が受け入れ基準レベルで曖昧 | 修正済み（§「フォールバック判定順（統一優先順位表）」を 1 本のテーブル化: 経路 1 / 1' / 2 / 3 / 4 = Issue 検索 / label fallback / spool fallback / v2.5.0 互換 fallback / warn-continue / BATS ケースもこの 7 ケースで直接検証） | - |
| 2 | 中 | consistency | 1 | テンプレ削除方針が「削除」or「残存時 warn 許容」で二重定義 | 修正済み（「本 Unit のコミットで物理削除必須」に単一化 / 残存時 warn は §4a 実行時検出ロジックのみ / テストでは削除を必須として検証） | - |
| 3 | 中 | architecture | 1 | spool 読み取りで Unit 002 公開関数非提供時に Unit 004 側で `partial_state` 直接解釈する案があり密結合余地 | 修正済み（Unit 002 既存 `_spool_extract_entries`（line 602）を source して使用 / Unit 004 側は NDJSON 各行から `jq -r .issue_url` までに留める / 不足時は Unit 002 へ reader 公開関数追加を先に依頼する運用必須化） | - |
| 4 | 中 | consistency | 2 | line 33 に「テンプレ削除（または存在時 warn）」が残存し再度二重定義 | 修正済み（line 33-34 を「本 Unit のコミットで物理削除必須」表現に書き換え / 3 箇所の物理削除必須記述と完全整合） | - |
| 5 | 低 | consistency | 3 | テンプレ削除対象パスの表記不一致（`templates/...` vs `skills/aidlc/templates/...`） | 修正済み（4 箇所すべて `skills/aidlc/templates/predecessor_retrospective.md` に統一） | - |

### サマリ

- 高: 1 件（解消済 1）
- 中: 3 件（解消済 3）
- 低: 1 件（解消済 1）
- **合計**: 5 件指摘 → 全件解消（unresolved_count=0）
- 千日手検出: なし（各 round で別系統または前 round 修正の取りこぼしの指摘）
- 反復 4 回（review-flow.md の上限 3 回を超過した round 4 は指摘軽減傾向のため継続実施 / round 4 で指摘 0 件確認）

### シグナル

- `review_detected=true`
- `deferred_count=0`
- `resolved_count=5`
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`

### 主要な合意事項（Unit 004 設計フェーズ以降への引き継ぎ）

1. **判定順の canonical 表記**: 経路 1（Milestone+label）/ 1'（label fallback / milestone_enabled=false）/ 2（spool）/ 3（v2.5.0 retrospective.md 互換）/ 4（warn+continue）の 5 経路。BATS は各経路 + 複数件分岐を直接検証（7 ケース）
2. **spool 読み取り責務**: Unit 002 の `_spool_extract_entries` を source して NDJSON 各行を取得 → Unit 004 では `jq -r .issue_url` 程度の最小フィールド抽出のみ。spool 内部構造（`partial_state.*`）は Unit 004 で直接解釈しない
3. **テンプレ削除**: `skills/aidlc/templates/predecessor_retrospective.md` を本 Unit のコミットで物理削除必須。実行時残存検出 warn は §4a 実装ロジックの責務
4. **コンテキスト変数**: 経路 1 / 1' / 2 採用時のみ `predecessor_retrospective_issue_url` 設定 / 経路 3 は `predecessor_retrospective_file_path` のみ / 経路 4 はすべて未設定

---

## Set 2: 2026-05-05（設計レビュー）

- **レビュー種別**: 設計レビュー（reviewing-construction-design）
- **使用ツール**: codex（read-only モード）
- **反復回数**: 4（指摘 4 → 2 → 2 → 0 件 / 千日手検出なし）
- **結論**: 指摘 0 件 / `auto_approved`

### 指摘一覧

| # | 重要度 | focus | round | 内容 | 対応 | バックログ |
|---|--------|-------|-------|------|------|-----------|
| 1 | 高 | consistency | 1 | gh_status 値域不一致（`unauthenticated` vs Unit 002 実装の `not-installed`） | 修正済み（domain §1 / §3.1 を `available\|unavailable\|not-installed` に統一） | - |
| 2 | 高 | consistency | 1 | gh エラー扱いが domain (warn+fallback) と logical (exit 1) で衝突 | 修正済み（domain §7 を継続可能/継続不能 2 段階分類のテーブル化 / logical §5 stderr 診断コード表に exit code 列追加 / `predecessor_gh_error` warn = exit 0 / `predecessor_gh_fatal` error = exit 1） | - |
| 3 | 中 | architecture | 1 | AskUserQuestion 起動責務がモジュール側か AI エージェント側か曖昧 | 修正済み（resolver は候補集合 + 推奨候補を NDJSON で返す純ロジックに固定 / AskUserQuestion 起動は 01-setup §4a の AI エージェント側責務として明示 / Unit 003 の責務分離パターン踏襲） | - |
| 4 | 低 | consistency | 1 | 経路 1' の挙動が「最新採用」or「確認必須」で曖昧 | 修正済み（純粋関数を `_pure_sort_by_closed_at_desc` にリネーム / 並び替えのみ / 自動採用しない / 確認は AI エージェント側で必須） | - |
| 5 | 高 | consistency | 2 | round 1 修正後も `_pure_select_latest_by_closed_at` の旧名残存 | 修正済み（domain §8 + logical §1 の 2 箇所を `_pure_sort_by_closed_at_desc` に統一） | - |
| 6 | 中 | consistency | 2 | NDJSON フィールド名 `closed_at` / `closedAt` 混在 | 修正済み（GitHub gh CLI ネイティブ表記 `closedAt` に全文書統一 / 関数名は bash 慣習で snake_case 維持の二系統に整理） | - |
| 7 | 中 | consistency | 3 | Unit 004 関連文書全体（intent.md / user_stories / plans / units）で `closedAt` 混在 | 修正済み（GitHub canonical の `closedAt` に統一 / intent.md は Inception 成果物のため変更せず、設計を逆方向に倒すアプローチで全体整合） | - |
| 8 | 低 | consistency | 3 | spool reader 関数名不一致（`predecessor_read_spool_issue_url` vs `__pred_read_spool_issue_url`） | 修正済み（内部関数として `__pred_read_spool_issue_url` に統一 / `__pred_` prefix） | - |

### サマリ

- 高: 3 件（解消済 3）
- 中: 3 件（解消済 3）
- 低: 2 件（解消済 2）
- **合計**: 8 件指摘 → 全件解消（unresolved_count=0）
- 千日手検出: なし
- 反復 4 回（review-flow.md の上限 3 回を超過した round 4 は指摘軽減傾向のため継続実施 / round 4 で指摘 0 件確認）

### シグナル

- `review_detected=true`
- `deferred_count=0`
- `resolved_count=8`
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`

### 主要な合意事項（Unit 004 実装フェーズ以降への引き継ぎ）

1. **gh_status canonical**: `available | unavailable | not-installed`（Unit 002 `__retro_gh_status` 完全一致）
2. **gh エラー 2 段階分類**: 一時エラー（warn / spool fallback）= exit 0 / 致命的エラー（error / 即終了）= exit 1
3. **AskUserQuestion 責務分離**: `predecessor_resolve_issue` は候補リストを NDJSON で返す純ロジック。対話 I/O は 01-setup AI エージェント層
4. **NDJSON フィールド命名**: `closedAt`（camelCase / GitHub gh CLI canonical）/ 関数名は snake_case（bash 慣習）の二系統
5. **spool reader**: `__pred_read_spool_issue_url`（内部関数 / Unit 002 `_spool_extract_entries` を source）

---

## Set 3: 2026-05-05（コードレビュー）

- **レビュー種別**: コードレビュー（reviewing-construction-code）
- **使用ツール**: codex（read-only モード / `codex review --base main`）
- **反復回数**: 2（指摘 3 → 2 件 / Unit 004 領域は 0 件で終結）
- **結論**: Unit 004 領域 `unresolved_count=0` / `auto_approved` / Unit 002 領域指摘は backlog 移送

### 指摘一覧

| # | 重要度 | focus | round | 内容 | 対応 | バックログ |
|---|--------|-------|-------|------|------|-----------|
| 1 | 高 | correctness | 1 | `__pred_gh_query` の label fallback で `--milestone` フィルタ無効化のみ実施し title での `prev_cycle` 絞り込み欠落 → 他 cycle の retrospective Issue が誤マッチ | 修正済み（jq post-filter 追加 / `Retrospective: <cycle>` 完全一致 + 末尾空白 prefix の 2 通り許容 / v2.5.0 と v2.5.0-rc1 の誤マッチ防止 / P18 BATS テストで 3 cycle 共存ケース検証） | - |
| 2 | 中 | correctness | 1 | `retrospective-resend.sh` `--cycle` 引数で `__retro_validate_cycle` 呼出なく path traversal 余地（Unit 002 領域） | 未修正（Unit 002 領域 / 本 Unit スコープ外）| Issue 作成: retrospective-resend `--cycle` 検証 + missing value 拒否 |
| 3 | 中 | correctness | 1 | `retrospective-resend.sh` `--cycle` 引数の missing value チェックなし → 自動 fallback で誤 cycle 操作余地（Unit 002 領域） | 未修正（Unit 002 領域 / 本 Unit スコープ外）| 同上（バックログにマージ） |
| 4 | 中 | correctness | 2 | `retrospective_issue_create` `target=both` 時の重複検出が `local_repo` のみで mirror 側の重複検出欠落（Unit 002 領域） | 未修正（Unit 002 領域 / 本 Unit スコープ外）| Issue 作成: retrospective both-target duplicate check |

### サマリ

- 高: 1 件（Unit 004 領域 / 解消済 1）
- 中: 3 件（すべて Unit 002 領域 / `deferred_count=3` でバックログ Issue 化）
- **Unit 004 領域合計**: 1 件指摘 → 全件解消（unresolved_count=0）
- 千日手検出: なし
- 反復 2 回（review-flow.md 上限 3 回未満で終結）

### シグナル

- `review_detected=true`
- `deferred_count=3`（Unit 002 領域指摘 / バックログ Issue で追跡）
- `resolved_count=1`（Unit 004 領域 1 件）
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`

### Backlog 移送する指摘（Unit 002 領域）

1. `retrospective-resend.sh` `--cycle` 引数検証
   - path traversal 防止: `__retro_validate_cycle` 呼出追加
   - missing value 拒否: `--cycle` 直後の token が無い / 別フラグの場合は exit 2
2. `retrospective_issue_create` `target=both` 時の mirror duplicate check
   - 現状 `local_repo` のみ検査 → mirror 側重複時に重複起票発生
   - 修正方針: `target=both` の場合 local + mirror 両方で `_gh_find_duplicate` 呼出

---

## Set 4: 2026-05-05（統合レビュー）

- **レビュー種別**: 統合レビュー（reviewing-construction-integration）
- **使用ツール**: codex（read-only モード / `codex exec -s read-only`）
- **反復回数**: 2（指摘 2 → 0 件 / `INTEGRATION CLEAN ROUND 2` 取得）
- **結論**: 指摘 0 件 / `auto_approved`

### 指摘一覧

| # | 重要度 | focus | round | 内容 | 対応 | バックログ |
|---|--------|-------|-------|------|------|-----------|
| 1 | 中 | architecture | 1 | `__PRED_SCRIPT_DIR` の事前未初期化リスク（retrospective-issue.sh 事前 source 時に空文字 → read-config.sh 経路が `/../read-config.sh` で解決失敗 → milestone_enabled=true silently default） | 修正済み（source guard 外側に `__PRED_SCRIPT_DIR=$(cd ...)` を無条件初期化 / read-config.sh 呼出は fallback 不要に） | - |
| 2 | 中 | consistency | 1 | 04-completion.md L77/87/363/640 + step-integration.bats L59 で削除済 `predecessor_retrospective.md` への dangling 参照（テンプレ削除に伴う論理的整合性違反） | 修正済み（04-completion.md §1.3 3 分岐表 + テンプレリスト + §1.6 + 末尾 4 箇所すべて Issue ベース + `predecessor_resolve_issue` 5 経路に書換 / step-integration.bats IS8 の grep を `predecessor_resolve_issue` に変更） | - |

### サマリ

- 中: 2 件（解消済 2）
- **合計**: 2 件指摘 → 全件解消（unresolved_count=0）
- 千日手検出: なし
- 反復 2 回（review-flow.md 上限 3 回未満で終結）

### シグナル

- `review_detected=true`
- `deferred_count=0`
- `resolved_count=2`
- `unresolved_count=0`
- セミオートゲート判定: `auto_approved`
- `INTEGRATION CLEAN ROUND 2` を codex 統合レビューで取得

### 主要な合意事項（Unit 004 完了処理 / 04-completion phase へ引き継ぎ）

1. **Unit 004 単体 DoD 達成**: predecessor-issue.sh + 15 BATS テスト + 01-setup §4a + テンプレ物理削除 + migration-tests.yml 更新 + shellcheck warn0 + `$()` 規約準拠
2. **境界跨ぎ更新**: 04-completion.md / step-integration.bats は Unit 002 領域だが、テンプレ削除の必然的な consequential cleanup として Unit 004 で実施（Unit 004 plan の「Unit 002 reference-only」は logic 変更禁止であり dangling reference 削除は対象外と解釈）
3. **deferred 残**: Set 3 で挙げた Unit 002 領域 3 件は `deferred_count=3` として review-summary に記録 / バックログ Issue 化はユーザー判断に委ねる（権限境界）
4. **回帰確認済**: 全 305 BATS テスト pass（Unit 004 新規 15 + 既存 290）
