# Construction Phase 履歴: Unit 04

## 2026-05-05T15:30:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 04-predecessor-issue-handoff（predecessor handoff の Issue 検索化）
- **ステップ**: Unit 完了
- **実行内容**: # Construction Unit 004 履歴: predecessor handoff の Issue 検索化

## 概要

新サイクル Inception 開始時、前サイクル振り返りをファイル参照ではなく **GitHub Issue 検索**（Milestone + `retrospective` ラベル AND 検索）で取得するように刷新。判定順を厳密化（経路 1 / 1' / 2 / 3 / 4 = Milestone+label / label fallback / spool / v2.5.0 互換 / warn-continue）し、`predecessor_retrospective.md` テンプレを物理削除。境界保護として Unit 001/002/003 の logic は変更せず、Unit 002 の `_spool_extract_entries` / `__retro_validate_cycle` / `__retro_gh_status` を source して借用（密結合回避）。

## Phase 1: 設計

- ドメインモデル: PredecessorReference（集約 / resolution_path + issue_url + file_path + source_milestone）/ ResolutionPath 5 経路 enum / IssueQueryResult / SpoolEntry（Unit 002 ライブラリ参照）
- 純粋関数: `_pure_classify_resolution_path` / `_pure_format_query_args` / `_pure_sort_by_closed_at_desc`（並び替えのみ / 自動採用しない / 確認は AI エージェント側）
- 責務分離: `predecessor_resolve_issue` は候補集合 + 推奨候補 + 解決経路の確定までを純ロジックで実施 / AskUserQuestion 起動は 01-setup §4a の AI エージェント側責務（Unit 003 で確立した責務分離パターン踏襲）
- gh_status canonical: `available | unavailable | not-installed`（Unit 002 `__retro_gh_status` 完全一致）
- gh エラー 2 段階分類: 一時エラー（warn / spool fallback / exit 0）/ 致命的エラー（error / 即終了 / exit 1）
- NDJSON フィールド命名: `closedAt`（GitHub gh CLI canonical）/ 関数名 snake_case（bash 慣習）の二系統
- spool reader: `__pred_read_spool_issue_url`（内部関数 / Unit 002 `_spool_extract_entries` を source）
- 計画レビュー: codex 4 round / 5 件指摘（高 1 / 中 3 / 低 1）→ 全件解消 / `auto_approved`
- 設計レビュー: codex 4 round / 8 件指摘（高 3 / 中 3 / 低 2）→ 全件解消 / `auto_approved`

## Phase 2: 実装

- 新規: `skills/aidlc/scripts/lib/predecessor-issue.sh` 311 行
  - 公開関数 `predecessor_resolve_issue(prev_cycle)` → NDJSON 1 行で `{resolution_path, issue_url, file_path, source_milestone, candidates: [...]}` を返却
  - 純粋関数 3 つ + 内部関数 4 つ（`__pred_gh_query` / `__pred_read_spool_issue_url` / `__pred_read_compat_file` / `__pred_emit_result`）+ 診断ヘルパ `__pred_diag`
  - 多重 source ガード `__AIDLC_PREDECESSOR_ISSUE_SH_LOADED`
  - `__PRED_SCRIPT_DIR` を guard 外側に無条件初期化（事前 source 時の path 解決安全化 / 統合レビュー round 1 で対応）
- 改修: `skills/aidlc/steps/inception/01-setup.md §4a` を完全置換（手動配置案内 → `predecessor_resolve_issue` 起動 / 5 経路解決テーブル / NDJSON 解釈手順 / AskUserQuestion 責務記述）
- 削除: `skills/aidlc/templates/predecessor_retrospective.md`（物理削除 / `git rm` / P14 テストで検証）
- 改修: `skills/aidlc/steps/operations/04-completion.md`（テンプレ削除に伴う dangling 参照 4 箇所を Issue ベース + `predecessor_resolve_issue` 5 経路に書換 / 統合レビュー round 1 で対応）
- 改修: `tests/retrospective/step-integration.bats` IS8 grep を `predecessor_resolve_issue` に変更
- 改修: `tests/retrospective/template-structure.bats` T5 削除（P14 で同等検証済）
- 改修: `.github/workflows/migration-tests.yml` PATHS_REGEX に `tests/predecessor-issue-handoff.bats` + `01-setup.md` 追加 / bats 実行リスト更新 / 削除済テンプレへの REGEX エントリを除去
- セキュリティ: jq `--arg`/`--argjson` で cycle / json 文字列を渡す形式（コマンドインジェクション対策）/ label fallback で title による cycle 完全一致絞り込み（v2.5.0 と v2.5.0-rc1 の誤マッチ防止 / コードレビュー round 1 で対応）

## テスト

- tests/predecessor-issue-handoff.bats: 新規 15 件
  - P1: 経路 1 / Issue 1 件で自動採用
  - P2: 経路 1 / 複数件で candidates 配列 closedAt 降順出力（対話起動しない）
  - P3: 経路 1 / 0 件 → 経路 2 移行
  - P7: gh 不可 + spool 存在 → 経路 2 直接遷移
  - P8: gh 不可 + spool 不在 + 互換ファイル → 経路 3
  - P9: gh 利用可能 / Issue 0 件 + spool 不在 + 互換ファイル → 経路 3
  - P10: 全経路 0 件 / warn_continue
  - P11: gh_status=unavailable で 1/1' スキップ → 経路 4
  - P12 / P12b: prev_cycle 不正 / 引数欠落 → exit 2
  - P14: テンプレ物理削除確認
  - P15-P17: 純粋関数 3 種の単体検証
  - P18: label fallback で他 cycle Issue を除外（v2.5.0 / v2.5.0-rc1 / v2.4.0 共存ケース）
- 既存テスト退行ゼロ: 全 305 BATS pass（既存 290 + 新規 15）
- セキュリティ: テスト teardown が `rm -rf .aidlc/cycles/${PREV_CYCLE}` で実リポジトリ v2.5.0 履歴を破壊する致命的バグを発見 → `cd "$TMP"` で TMP 配下に閉じ込めて修正
- shellcheck warning 0 / `bin/check-bash-substitution.sh` 違反 0

## レビュー（4 セット）

- Set 1（計画 / codex 4 round）: 5 件指摘（高 1 / 中 3 / 低 1）→ 全件解消
- Set 2（設計 / codex 4 round）: 8 件指摘（高 3 / 中 3 / 低 2）→ 全件解消
- Set 3（コード / codex 2 round）: 4 件指摘（Unit 004 領域 1 件 = 解消 / Unit 002 領域 3 件 = backlog defer）→ Unit 004 unresolved=0
- Set 4（統合 / codex 2 round）: 2 件指摘（中 2 / `__PRED_SCRIPT_DIR` robustness + 04-completion 整合）→ 全件解消 / `INTEGRATION CLEAN ROUND 2` 取得

## 主要決定

- DR-020: gh_status 値域は `available | unavailable | not-installed`（Unit 002 と完全一致 / canonical 文字列）
- DR-021: gh エラーは継続可能（exit 0 / spool fallback）/ 継続不能（exit 1 / 即終了）の 2 段階分類
- DR-022: 複数件ヒット時 hook 関数は候補リストを NDJSON で返すのみ / AskUserQuestion 起動は AI エージェント前段手順
- DR-023: NDJSON フィールド命名は GitHub gh CLI canonical の `closedAt`（camelCase）/ bash 関数名は snake_case 二系統
- DR-024: テンプレ削除は本 Unit のコミットレベルで物理削除必須（残存時 warn は §4a 実装ロジックのみ）
- DR-025: spool 読取は Unit 002 `_spool_extract_entries` を source して借用 / partial_state 等の内部構造を Unit 004 で直接解釈しない
- DR-026: 04-completion.md 分岐 (b) はテンプレ削除に伴い「次サイクル Inception §4a で `predecessor_resolve_issue` が解決」する Issue ベース handoff に書換（Unit 004 の consequential cleanup として境界跨ぎ更新）

## バックログ移送（Unit 002 領域 / Set 3 で defer）

1. `retrospective-resend.sh` `--cycle` 引数の `__retro_validate_cycle` 検証 + missing value 拒否（path traversal + auto-detect fallback 暴発防止）
2. `retrospective_issue_create` `target=both` 時の mirror duplicate check（local のみ検査 → mirror 重複時に重複起票発生）

## DoD 達成状況

- [x] `predecessor_resolve_issue` 5 経路の判定順実装 + NDJSON 出力
- [x] BATS 15 件 pass
- [x] 01-setup §4a 完全置換
- [x] テンプレ物理削除（git rm 済 / P14 検証済）
- [x] migration-tests.yml 整合（PATHS_REGEX + bats 実行リスト）
- [x] 04-completion / step-integration dangling 参照解消
- [x] shellcheck warning 0 / `$()` 規約準拠
- [x] 全 305 BATS pass（回帰ゼロ）
- [x] 4 セットレビュー全 auto_approved（unresolved_count=0）

## 次の Unit

Unit 005（#616 マージ前 write-history 追加コミット漏れガード / 並列着手可能 / Unit 001/002 主要改修後を推奨）。
