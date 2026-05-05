# Construction Phase 履歴: Unit 02

## 2026-05-05T11:29:09+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-retrospective-issue-only（retrospective Issue 一本化 + spool + mirror_state ラベル化）
- **ステップ**: Unit完了
- **実行内容**: # Construction Unit 002 履歴: retrospective Issue 一本化 + spool + mirror_state ラベル化

## 概要

`steps/operations/04-completion.md §1.5` を「ローカル `retrospective.md` 生成 + mirror Issue 起票」の二段構造から、最初から GitHub Issue 起票で完結する単一フローに刷新。`mirror_state` を Issue ラベルで保持し、`gh_status != available` 時は `cycles/{{CYCLE}}/history/retrospective-spool.md` にスプールして次回 `gh` 利用可能時に `scripts/retrospective-resend.sh` で再送する経路を提供。v2.5.0 の `retrospective.md` ファイル / `mirror_state` YAML 形式は読み取り側で互換維持。

## Phase 1: 設計

- ドメインモデル: RetrospectiveIssue 集約（状態遷移: prefilled → created → human_reviewed）/ SpoolEntry 集約（id/retry_target/partial_state.{local_created,mirror_created}）/ MirrorStateLabel 値オブジェクト / 純粋関数 `_pure_compose_body`
- 論理設計: `skills/aidlc/scripts/lib/retrospective-issue.sh` を中核ライブラリ化（公開関数 `retrospective_issue_create(path,path,string)` / `retrospective_body_compose(path,path,string)` + 純粋関数 `_pure_compose_body(string,string,string)` + spool I/O + mirror_state 双方向正規化）
- スプールフォーマット: NDJSON v1 + base64 + SHA256 + UUID + `flock` 5 秒タイムアウト + 一時ファイル + 原子的 `mv` 置換（曖昧性ゼロ + 排他更新 + partial 起票識別子で local 二重起票防止）
- exit code 規約: `failed → exit 1` / `created/skipped/spooled → exit 0` / 引数・spool 不正 → exit 2 を 3 資料統一
- 互換アダプタ層: `retrospective-generate.sh` / `retrospective-mirror.sh` の保証 / 非保証 / 廃止予定（v2.6.x 候補）を表形式で固定。`recorded:pending` は warn + `created` 互換扱いで非保証
- Unit 003 フック契約: 未定義時 no-op / prefill 失敗 → 空 YAML / update 失敗 → 警告のみで §1.5 継続を明文化
- 設計レビュー: codex 5 round / 20 件指摘（高 6 / 中 11 / 低 3）→ 全件解消 / `auto_approved`（千日手検出なし、各 round で別系統指摘を順次解消）

## Phase 2: 実装

- 新規: `lib/retrospective-issue.sh`（1042 行）/ `retrospective-resend.sh`（211 行、`--cycle` / `--dry-run` / `--strict` / SHA256 整合性検証 / partial 起票尊重）
- 互換アダプタ層化: `retrospective-generate.sh`（旧 stdout プレフィックス契約のみ保持 / v2.7.x で削除予定）
- §1.5 全面刷新: 新 Step 1-5 で再構成 / 旧フローは「旧仕様参考（撤廃済 / v2.5.0 実装）」セクションに残置
- セキュリティ強化: cycle 検証関数 `__retro_validate_cycle`（`^[A-Za-z0-9._-]+$` + 予約名拒否 / path traversal 防止）
- 信頼性強化: subshell + trap で lock_dir / tmp_path 自動 cleanup / mirror_state ラベル付け替え 3 回リトライ + 指数バックオフ + 失敗時 spool 退避 `mirror_state=pending`
- cap 判定経路: `AIDLC_RETRO_CURRENT_COUNT` / `AIDLC_RETRO_LIMIT` 環境変数による cap 判定追加（§1.5 から渡す）
- partial 起票尊重: `AIDLC_RETRO_FORCE_TARGET` / `AIDLC_RETRO_SKIP_LOCAL` 環境変数経由で local 二重起票防止
- コードレビュー: codex 6 件指摘（高 3 / 中 2 / 低 1）→ 全件即時反映 → `auto_approved`

## テスト

- tests/retrospective-body-compose.bats: 新規（共有契約 6.2 構造 / Unit 003 prefill 入力スキーマ受け入れ / `human_reviewed:false` 初期値 / `mirror_state` YAML 埋め込み）
- tests/retrospective-issue-create.bats: 新規（重複検出 / `feedback_mode` 別の起票先振り分け / `gh_status` 別動作 / cap 超過時のスキップ）
- tests/operations-04-completion-section1-5.bats: 新規（§1.5 ステップ呼び出し統合テスト）
- tests/retrospective-mirror/step-integration.bats: 既存追従更新（IS1/IS2/IS3 を新 §1.5 セクション見出しに追従）
- 既存テスト 9 件（F1, F3, F5-F7, GE1, GE1b, GE3, GE5, GE6, IS1-IS3）を互換アダプタ仕様変更に追従させる更新
- 統合レビュー: codex（read-only モード）/ 既存テスト退行 9 件 + 副次バグ 2 件（cycle path traversal sed 構文エラー / spool path 漏れ）→ 全件解消 → `auto_approved`
- 全 113 テスト pass / shellcheck warning ゼロ / `bin/check-bash-substitution.sh` violations 0（プロジェクト規約準拠）

## 意思決定記録（v2.5.1 サイクル decisions.md に追記）

- DR-011: `retrospective_body_compose` / `retrospective_issue_create` の I/F を path 渡し 3 引数 + 純粋関数 `_pure_compose_body` 内部公開で 3 資料統一
- DR-012: spool フォーマットを NDJSON + base64 + SHA256 + UUID + flock 排他に確定（Markdown 区切りは脆弱性のため不採用）
- DR-013: 互換アダプタ層 `recorded:pending` は warn + `created` 互換扱いで非保証（canonical 中間語彙 `legacy-deferred` は導入せず）
- DR-014: `retrospective-resend.sh` の exit code 規約を `failed が 1 件以上 → exit 1` / `created/skipped のみ → exit 0` / 引数・spool 不正 → exit 2 に確定
- DR-015: cycle 検証関数 `__retro_validate_cycle` を sed 前必須呼び出しとして共通化（互換アダプタ exit 2 を保証）

## 完了条件達成

Unit 責務 8 / Issue #590 partial 受け入れ基準 / Issue #592 partial（Unit 007）Issue 化対応 / Intent 主要設計判断 6.1-6.5 / NFR（冪等性 + 可用性 + 後方互換）/ 逆方向非依存検証 = すべて達成。

## 関連 Issue

- #590 partial（retrospective テンプレ + Operations Phase 自動生成、v2.5.0 で導入済 → 本 Unit で Issue 化により一本化）
- #592 partial（Unit 007 主因切り分け 3 分類、v2.5.0 で導入済 → Issue 化対応）

## 補足: 履歴ファイル遡及作成

本ファイルは Unit 002 完了コミット（5fcf7d83、2026-05-05T11:29:09+09:00）に履歴記録の漏れがあったため、後日（同日中）の補修コミットで遡及作成された。Unit 定義ファイル（`002-retrospective-issue-only.md`）の `## 実装状態` 更新も同時に補修している。

---
