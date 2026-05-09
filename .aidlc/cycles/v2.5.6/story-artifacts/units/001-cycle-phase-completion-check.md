# Unit: cycle/* PR の 3 Phase 完了 CI ガード追加（A）

## 概要

cycle/* ブランチの PR マージ前に Inception/Construction/Operations 3 Phase の完了状態を CI で自動検証し、不完全状態のサイクルが main に取り込まれる事故を防ぐ。

## 含まれるユーザーストーリー

- ストーリー 1: cycle/* PR で 3 Phase 完了を CI で強制したい（A）

## 責務

**[A-1 実装責務] チェックスクリプト + CI**:
- `bin/check-cycle-phase-completion.sh <cycle>` の新規作成（CLI + `--help` 提供）
- 3 Phase の完了状態を以下基準で検証する関数群:
  - Inception: progress.md の全ステップ完了/スキップ
  - Construction: units/*.md の「実装状態」が完了/取り下げ
  - Operations: progress.md ステップ7完了 + 固定スロット 3 つ + pr_number 一致
- `.github/workflows/cycle-phase-completion-check.yml`（または既存 workflow への job 追加）の新設
- ローカル dry-run コマンドの提供
- bats テスト（5 ケース: completion / Inception 未完 / Construction 未完 / Operations スロット欠損 / pr_number 不一致）
- Repository Ruleset / Branch protection 必須化手順の doc 化（`docs/` 配下、`gh api` スクリプト化と UI 手順の両論併記）

**[A-2 適用責務] Repository Ruleset 必須化**:
- 上記 doc に従い、Operations Phase 完了直前に Repository Ruleset / Branch protection で当該 CI チェックを必須化:
  - **通常完了経路**: `gh api` REST/GraphQL でスクリプト化適用、または管理者が UI 操作で適用。適用証跡（設定 JSON / スクリーンショット）を `docs/` または PR description に保存
  - **暫定完了経路**: 上記が UI 手動作業のみで本サイクル中に管理者適用未完了となる場合、Operations Phase 完了直前に AskUserQuestion で「暫定完了承認」を取得し、follow-up Issue 起票 + 適用予定マイルストーン明記。本経路適用時は Unit 状態を「完了（暫定）」とし、`実装状態` セクションに暫定理由を記録

## 境界

- cycle/* 以外のブランチパターンへの CI ガード拡張は対象外
- 既存 workflow（pr-check / migration-tests / auto-tag / skill-reference-check）の改修は対象外
- A-2 の暫定完了経路を取った場合の follow-up Issue（次サイクル v2.5.7 等での Ruleset 適用作業）は本 Unit の境界外

## 依存関係

### 依存する Unit
- なし

### 外部依存
- GitHub Actions（`pull_request` イベント）
- `gh` CLI（PR 番号取得 / API 呼び出し）
- `dasel`（progress.md TOML 値取得） または `awk` 直接パース

## 非機能要件（NFR）

- **パフォーマンス**: CI ジョブ実行時間 30 秒以内（軽量チェックのみ）
- **セキュリティ**: PR head_ref 由来の値を eval せず、文字列比較とサニタイズに限定
- **可用性**: 既存 workflow と独立、コンフリクトなし

## 技術的考慮事項

- 既存 progress.md / units/ パース helper の有無を Construction 設計時に調査（重複ロジック生成を避ける）
- `pr_number` 検証は `${{ github.event.pull_request.number }}` または `gh api repos/:owner/:repo/pulls/:number` で取得
- ローカル dry-run と CI 実行の挙動分岐の有無は設計時に判断（Intent Question として残置）

## 関連Issue

- #672

## 実装優先度

High（Must、Intent A）

## 見積もり

中（CI workflow + check スクリプト + bats テスト + doc）。0.5 〜 1 日（メタ開発リポジトリ既存資産再利用前提）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
