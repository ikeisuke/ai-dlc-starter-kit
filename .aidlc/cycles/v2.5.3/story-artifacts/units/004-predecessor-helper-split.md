# Unit: predecessor-issue.sh の retrospective-issue.sh 横依存解消（用途別 helper 独立化）

## 概要

`skills/aidlc/scripts/lib/predecessor-issue.sh` が `retrospective-issue.sh` を直接 source して関数を借用する横依存構造を解消する。借用関数（`__retro_validate_cycle` / `__retro_gh_status` / `_spool_extract_entries`）を責務別の独立 helper（`aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh`）に分離し、両ファイルがそれぞれ独立して新 helper を source する構造に再構成する。

## 含まれるユーザーストーリー

- ストーリー 4: predecessor-issue.sh の retrospective-issue.sh 横依存解消（#643）

## 責務

- 新規ファイル作成（境界 helper として責務分離）:
  - `skills/aidlc/scripts/lib/aidlc-validate.sh`: `__retro_validate_cycle` 系（cycle 命名・存在チェック）
  - `skills/aidlc/scripts/lib/aidlc-gh.sh`: `__retro_gh_status` 系（gh CLI 可用性）
  - `skills/aidlc/scripts/lib/aidlc-spool.sh`: `_spool_extract_entries` 系（NDJSON spool パース）
- `retrospective-issue.sh` から上記関数定義を削除し、新 helper を source する形に変更
- `predecessor-issue.sh` から `retrospective-issue.sh` の直接 source を撤去し、新 helper を source する形に変更
- 新 helper は他の retrospective 系 helper を `source` でも `.` (dot source) でも読み込まないこと（境界完全分離）
- 多重 source ガード（`__AIDLC_<NAME>_SH_LOADED=1`）を新 helper 群でも踏襲

## 境界

- 関数の物理配置のみが変わる。**関数名・引数・戻り値・stderr メッセージは同一を維持**（API 非破壊）
- 既存呼び出し元（`01-setup.md` §4a の AI エージェントロジック）は変更しない
- `_spool_append` / `_spool_remove_by_id` / `retrospective_collect_candidates` / `retrospective_issue_create` / `retrospective_body_compose` / `retrospective_prefill_hook` / `retrospective_update_hook` は本 Unit のスコープ外（retrospective-issue.sh 側に残置）
- AIDLC_PROJECT_ROOT 対応 path 解決は本 Unit のスコープ外（既に v2.5.2 Unit 003 で `aidlc-paths.sh` として独立済）
- retrospective-resend.sh / retrospective-llm-draft.sh / retrospective-human-review.sh は本 Unit のスコープ外

## 依存関係

### 依存する Unit

- なし（論理依存・実装順依存ともに完全独立 / 並行実装可能）

### 外部依存

- bash 4+ / 既存の多重 source ガードパターン
- `gh` CLI（`__retro_gh_status` の動作要件として既存）

## 非機能要件（NFR）

- **パフォーマンス**: source 構造の変更のみで関数実体は不変、性能影響なし
- **セキュリティ**: 既存の機密情報マスク・gh API 利用パターンを維持
- **スケーラビリティ**: 影響なし
- **可用性**: 影響なし
- **後方互換**: CLI 引数互換 / exit code 互換 / stderr 文言互換のすべてを維持。v2.5.2 サイクルでの呼び出しを再生して同等出力を得る回帰テスト合格

## 技術的考慮事項

- 関数移管時に retrospective-issue.sh 側で必要な内部 helper（例: 共有のロギング関数 `__retro_diag` 等）の二重定義は避ける。共通基盤関数も適切な helper に分類
- 多重 source ガードのフラグ命名: `__AIDLC_VALIDATE_SH_LOADED` / `__AIDLC_GH_SH_LOADED` / `__AIDLC_SPOOL_SH_LOADED`
- 各新 helper は単独で source 可能（他の helper への依存なし）
- 移管後の `retrospective-issue.sh` は新 helper 3 つを source する形になる（path/validation/gh/spool-parse の 4 helper 体制 / `aidlc-paths.sh` は v2.5.2 で独立済）
- 回帰テスト: v2.5.2 サイクル予測ハンドオフ（実際に予測したように `predecessor_resolve_issue v2.5.2` を実行）して、本サイクル開始時に実観測した NDJSON 出力（`milestone_and_label` resolution_path / 4 candidates）と同等の出力を得ることを合格基準とする

## 関連Issue

- #643（predecessor-issue.sh の retrospective-issue.sh 横依存解消）
- 関連（参考 / 既存独立例）: v2.5.2 Unit 003 で新設の `aidlc-paths.sh`

## 実装優先度

Medium（Should-have / refactor / 障害伝播リスク削減）

## 見積もり

- 設計フェーズ: 0.5 日（domain model / 関数分類 / 多重 source ガード設計）
- 実装フェーズ: 1.5 日（新 helper 3 ファイル作成 + retrospective-issue.sh / predecessor-issue.sh 改修 + 回帰テスト）
- 合計: **2 日**

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
