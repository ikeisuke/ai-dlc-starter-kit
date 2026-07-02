# Unit: doctor `[phase]` / `[trace]` 領域実装 + 契約テスト

## 概要

v3 診断コマンド `doctor`（`skills/aidlc-v3/scripts/doctor.sh`）に `[phase]`（フェーズ導出の整合診断）と `[trace]`（design 必須 work item の design ファイル存在診断）の 2 領域を追加し、契約テスト（`test-doctor.sh`）を拡張する。doctor を shallow 9 領域から完全 11 領域へ拡張する実装の中核。read-only / 自動修正なしを維持する。

## 含まれるユーザーストーリー

- ストーリー 1: フェーズ導出の整合診断（`[phase]`）
- ストーリー 2: trace 整合（design 欠落）の診断（`[trace]`）
- ストーリー 3: `[phase]` / `[trace]` の契約テスト

## 責務

- `doctor.sh` に `diagnose_phase` 相当を追加: `data-model.md §5.1` の first-match 導出（complete → define → develop → release 可能）を code 化し、導出フェーズと根拠を `report phase <severity> <detail>` で出力。`complete` は `release.merge_approved=true` かつ gh による read-only PR merged 確認成功時のみ導出、確認不能時はフォールバック + WARN 併記。
- `doctor.sh` に `diagnose_trace` 相当を追加: `data-model.md §8` の size×depth_level マトリクスで design 要否を判定し、design 必須 work item に対応する `designs/<id>-<slug>.md` の存在を確認。欠落 / 不正組み合わせ（`risky × minimal`）は WARN（exit 0 維持）。
- 両領域を実行順序（`doctor.sh` の順序実行ブロック）へ組み込み、wrap 契約コメント・領域カウントを更新。
- 入力取得は既存スクリプト（`state-read.sh` / `work-item-status.sh`）と共有パーサ（`lib/frontmatter.sh` の `fm_scalar`）を再利用。depth_level は `read-config.sh rules.depth_level.level`（rc1 → standard フォールバック）。
- `test-doctor.sh` を拡張: `[phase]` 各導出ケース（define / develop / release 可能 / complete）+ 根拠検証、`[phase]` 異常系 WARN 分岐（`merge_approved=true` × gh 不可/PR 未 merged で complete 非導出 + WARN、`define_completed=false` × `done` work item 矛盾で安全側導出 + WARN）、`[trace]` 各ケース（必須×存在/欠落、不要、`normal × comprehensive`、`risky × minimal`、depth_level 未設定）、「全領域 OK」正常系を 11 領域化。
- `doctor.sh` ヘッダコメントの領域カウント（「9 領域」→「11 領域」）および wrap 契約コメントを実装の一部として更新する（公開ドキュメント側の表記統一は Unit 002 が担う）。

## 境界

- doctor.md / workflow.md / v3-renewal-plan.md の SoT ドキュメント反映は **Unit 002 の責務**（本 Unit は実装とテストに限定）。ただし `doctor.sh` ヘッダコメント内の領域カウント・wrap 契約コメントは実装の一部として本 Unit で更新する。
- フェーズ導出規則（`data-model.md §5`）/ size×depth 規則（§8）そのものの仕様変更はしない（既存規則の code 化のみ）。
- doctor の自動修正機能は実装しない（read-only 厳守）。
- trace chain 後段（reviews / journal / release / reflect）診断、intent refs / Traceability 意味検証は範囲外。

## 依存関係

### 依存する Unit

- なし（既存 `doctor.sh` / 依存スクリプト群は実装済み）

### 外部依存

- 既存スクリプト: `state-read.sh` / `work-item-status.sh` / `work-item-validate.sh` / `lib/frontmatter.sh`（再利用）
- `read-config.sh`（depth_level 取得）
- `git` / `gh`（gh は `[phase]` complete の PR merged 確認 / 既存 `[gh]` `[pr]` 領域と同様に read-only）
- `jq`（テストハーネス）

## 非機能要件（NFR）

- **パフォーマンス**: 既存 doctor と同等（依存スクリプトの read-only wrap のみ、追加 I/O は work item / designs ディレクトリの列挙程度）。
- **セキュリティ**: read-only。state.json / work item / config を書き換えない。
- **スケーラビリティ**: work item 件数に対し線形（既存 `[work-items]` と同等）。
- **可用性**: gh 不可 / オフライン時も `[phase]` はフォールバックで継続（complete 判定のみ degrade）。

## 技術的考慮事項

- 既存 wrap パターン（依存スクリプトの exit code / stdout prefix を severity に写像）を踏襲し、診断ロジックを領域関数内に閉じる。
- `report()` 契約（`printf '%-14s%-6s%s'` で `[area] severity detail`）を厳守し、`[phase]`（7文字）/ `[trace]`（7文字）が固定幅に収まることを確認。
- 新規パース禁止規約（`lib/frontmatter.sh:24-30`）を遵守。
- 総合 exit code 集約（`HAS_UNDIAGNOSABLE` > `HAS_ERROR` > OK）に WARN は exit 0、診断不能のみ exit 2 で反映。
- 契約テストは `assert_area <area> <severity>` で severity トークンを検証するため、出力契約を前提に設計。

## 関連Issue

- #741（doctor に `[phase]` / `[trace]` 領域を追加）
- Epic: #736（v3 リニューアル / Phase 6 必須 follow-up）

## 実装優先度

High

## 見積もり

中（doctor.sh への 2 領域追加 + test-doctor.sh 拡張 / 1 セッション程度）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-07-01
- **完了日**: 2026-07-01
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
