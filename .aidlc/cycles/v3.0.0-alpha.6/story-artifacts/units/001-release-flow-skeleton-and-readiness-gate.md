# Unit: release フロー骨格 + リリース準備ゲート

## 概要

`skills/aidlc-v3/steps/release.md` を新規作成し、release フェーズの骨格（Step 1–4 の章立て・パス解決・スクリプト契約の書式）と Step 1「リリース準備」を実装する。本 Unit は後続 Unit（PR 整備・merge・統合）の土台。`SKILL.md` の `release` コマンドを「予約」から「実装済み」に切り替える**利用者向け公開フリップは Unit 004 に集約**する（Step 1–4 とテストが揃ってから有効化するため）。

## 含まれるユーザーストーリー

- ストーリー 1: リリース準備ゲート（全 work item 完了検出）

## 責務

- `steps/release.md` の新規作成（`steps/define.md` / `steps/develop.md` の「Step + ゲート + 成果物 + スクリプト契約」書式を踏襲）。Step 1–4 の章立て骨格を置き、Step 1 を実装する。
- Step 1「リリース準備」: 全 work item の frontmatter `status` が `done` / `withdrawn` であることを `state-read.sh` / `work-item-validate.sh`（read-only）で検出。未完了（`pending` / `in_progress` / `blocked`）が残る場合は一覧提示して停止。`define_completed: false`／state.json 不在時は release に入らず define/develop へ案内。
- git status / CI・test 状態確認とその後の挙動（dirty/test失敗/CI失敗=停止、CI未実行=警告継続）を Step 1 に明記。

## 境界

- `SKILL.md` の `release` コマンドの「予約→実装済み」公開フリップ・express 整合は扱わない（Unit 004）。Unit 001 は `steps/release.md` 骨格の作成までに留め、利用者向けコマンド有効化は行わない。
- PR 作成・ready 化・release.md 作成・review ルーティング（Unit 002）は扱わない。
- merge 承認・実行・post-merge cleanup（Unit 003）は扱わない。
- express ラッパ整合の検証・新規テスト追加・回帰（Unit 004）は扱わない。
- フェーズ導出規則・state.json schema の定義は行わない（`docs/v3/data-model.md §3・§5` を参照するのみ）。

## 依存関係

### 依存する Unit

- なし（本 Unit が release フロー実装の起点）

### 外部依存

- 既存 `skills/aidlc-v3/scripts/state-read.sh` / `work-item-validate.sh`（read-only 利用）
- 設計 SoT: `docs/v3/workflow.md §3.3`（Step 1）/ `docs/v3/data-model.md §5`（フェーズ導出）

## 非機能要件（NFR）

- **保守性**: release.md は SoT（data-model/workflow）を再定義せず参照する。
- **互換性**: 既存 v3 テストを壊さない。state.json への書き込みは行わない（read-only）。
- **クロスプラットフォーム**: 手順内のコマンド例は macOS / Linux 両対応。

## 技術的考慮事項

- `steps/define.md` / `steps/develop.md` の構造をお手本に、各 Step に「ゲート(★)」「成果物」「スクリプト usage/exit code 契約」を付す。
- Bash ツール安全規約（`$(...)` / backtick 禁止）を手順内コマンド例にも適用。

## 関連Issue

- #736（部分対応 / Relates）

## 実装優先度

High

## 見積もり

0.5〜1 日（release.md 骨格 + Step 1）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
