# Inception Phase 意思決定記録 - v2.6.6

本サイクルで Inception Phase 中に行った重要な意思決定を記録する。Construction / Operations Phase で参照される。

---

## DR-001: サイクルバージョンを v2.6.6（patch）に決定

- **日付**: 2026-05-18
- **背景**: 前サイクル v2.6.5 完了直後。候補は patch (v2.6.6) / minor (v2.7.0) / major (v3.0.0)。当初 minor を仮置きしたが、ユーザー指示により patch に確定
- **意思決定**: v2.6.6 (patch) を採用
- **理由**:
  - 既定動作変更（集約 retrospective Issue 廃止）は含むが、後方互換オプション `rules.retrospective.aggregate_issue_enabled = true` で旧動作を完全復元可能
  - API 破壊変更なし（`retrospective_api_*` シグネチャ不変）
  - `predecessor_resolve_issue` の既存 5 経路は維持（経路追加のみ）
  - #715 (minor 想定 Issue の patch サブセット適用パターン SoT 化) の実証実例として位置付ける
- **影響**: Milestone は `v2.6.6` で作成。リリース判定時にリリースノートで「集約 Issue 既定 off」を必須告知
- **関連**: Intent §「patch リリースの妥当性」+「patch として許容する条件」5 必須要件

---

## DR-002: `aggregate_issue_enabled` 既定値を `false` に決定（T 中心アウトプットを新既定動作とする）

- **日付**: 2026-05-18
- **背景**: ユーザー要望「Tの Issue を作るのが目的。KPT 集約 Issue 化が目的化している」を構造改善として実現するため、既定動作を T 中心に切り替えるか opt-in に留めるかが論点
- **意思決定**: 既定値 `false`（T ループ起票が新既定動作）。`true` 明示時に旧動作（集約 Issue 起票）を復元
- **理由**:
  - 既定値 `true` のままだと「ユーザーが明示設定しない限り旧構造のまま」となり、目的化解消が形骸化
  - 既定値 `false` + opt-in 復元によって patch リリースの後方互換を保ちつつ、新規ユーザーに新構造を提供
  - #710 (CLOSED / minor 想定) の本体を patch で先取りする方針と整合
- **影響**: `config/defaults.toml`（aidlc / aidlc-setup 両側）に `false` を追加。リリースノート 3 項目必須告知（既定変更 / opt-in 復元手順 / predecessor 解決経路）
- **関連**: Intent SC-02 / SC-04、Unit 001

---

## DR-003: §1.2.5 セルフレビュー差し戻しループ上限 = 3 回、上限到達時 `selfreview-capped` 警告ラベル付与で起票許可

- **日付**: 2026-05-18
- **背景**: セルフレビュー差し戻しを「強制ブロック」にするか「警告 + 起票許可」にするかが論点
- **意思決定**: 上限 3 回 + 警告ラベル付与で打ち切り（強制ブロックなし）
- **理由**:
  - review-flow.md の 5R 上限と比較してセルフレビューは軽量化（3 回）
  - 差し戻し無限ループを防ぐ + 上限到達でも T Issue は起票（追跡放棄を防止）+ ラベルで「セルフレビュー上限到達」が後段からも見える
  - 差し戻し上限値の config 可能化は v2.7.0+ defer（patch スコープを狭く保つ）
- **影響**: Unit 002 で実装。`selfreview-capped` ラベルは runtime 自動作成 fail-safe + 権限不足時 fail-fast で本サイクル必達
- **関連**: Intent Q2（確定済）、SC-05、Unit 002

---

## DR-004: 一次情報三層検証 helper の jsonl は file path 引数渡し opt-in のみ採用（自動検出は v2.7.0+ defer）

- **日付**: 2026-05-18
- **背景**: #652 (振り返り 3 層検証 skill 化) の jsonl 経路は本サイクル内で完全実装すべきか、引数 opt-in までで Close するかが論点
- **意思決定**: file path 引数渡しの opt-in のみで Close。自動検出・パーミッション自動付与・ホームディレクトリ走査は v2.7.0+ defer
- **理由**:
  - jsonl 自動検出はパーミッション設計 / プライバシー考慮 / cross-platform path 差分など独立要件が多く、patch スコープに収まらない
  - 引数 opt-in までで「振り返りの深さ担保」目的（推測値混入予防）は達成可能
  - #652 本文の受入基準は「引数 opt-in で 3 source + jsonl 統合可能」までで満たせる
- **影響**: Unit 003 のスコープ確定。#652 PR Comment に「引数 opt-in までの完全実装で Close、自動検出は v2.7.0+ defer」を記載
- **関連**: Intent SC-07、Unit 003

---

## DR-005: Unit 数 4 固定、Unit 4 内サブ責務を 4A / 4B / 4C に分割（実行順序: 4A/4B 並列、4C は両者完了後）

- **日付**: 2026-05-18
- **背景**: 当初ストーリー 4 を 1 ストーリー / 1 Unit としていたが、Round 1 Stories レビュー指摘で INVEST Small/Independent 違反が顕在化。ストーリー 6 化と Unit 4 維持のどちらを優先するかが論点
- **意思決定**: ストーリー数 6 (1 / 2 / 3 / 4A / 4B / 4C) / Unit 数 4 固定（マッピング: Unit 4 = ストーリー 4A + 4B + 4C）。Unit 4 内の実行順序は 4A/4B 並列 + 4C 検証フェーズ依存
- **理由**:
  - Intent で「Unit 数 4 固定」を確定済（変更時は Construction Phase 開始前に DR 必須）
  - ストーリー 6 化で失敗時の切り分け単位を細かくしつつ、Unit 数を維持して見積もり / 履歴記録の安定性を担保
  - Unit 4 内のサブ責務ごとに完了ゲート（チェックリスト）を設けて実装の独立性を運用上担保
- **影響**: Construction Phase 開始時に Unit 4 内 4A/4B/4C のサブ責務を並列・順次で進める。各サブ責務完了ゲート pass を Unit 4 完了条件とする
- **関連**: Intent「期限とマイルストーン」、user_stories マッピング表、Unit 004 完了ゲート

---

## DR-006: SC-04 同等性オラクルを 5 項目に拡張（タイトル / 本文見出し集合 / 本文正規化比較 / ラベル集合 / cap 判定）

- **日付**: 2026-05-18
- **背景**: 当初 SC-04 オラクルは 4 項目（タイトル / 見出し集合 / ラベル / cap）。Round 2 Stories レビュー指摘で「見出し配下の本文が変わっても検知できない」意味差分の盲点を指摘
- **意思決定**: 5 項目目に「各見出し配下の本文の正規化比較（ゆらぎ項目を `normalize_volatile()` で除外した上で完全一致 / または本文全体の正規化ハッシュ一致）」を追加
- **理由**: 見出し集合一致のみでは本文意味差分（誤訳・項目欠落等）を検知できない。`normalize_volatile()` でタイムスタンプ / セッション ID / 環境固有パス等のゆらぎ項目を除外することで安定比較を実現
- **影響**: Unit 001 で `normalize_volatile()` の抽出規則を定義 + fixture 整備
- **関連**: Intent SC-04、Unit 001

---

## DR-007: `predecessor_resolve_issue` 新動作経路サブ分岐名を `t_issue_milestone_scope` / `t_issue_label_fallback` に決定（既存 5 経路名と衝突しない名前空間）

- **日付**: 2026-05-18
- **背景**: 新動作経路（集約 Issue 不在 + retrospective ラベル付き T Issue 1 件以上で発火）の内部サブ分岐名が当初「milestone+label / label_fallback」と既存 5 経路名と被っており、Round 3 Stories レビュー指摘で命名衝突によるテスト解釈ぶれリスクを指摘
- **意思決定**: サブ分岐名を `t_issue_milestone_scope`（milestone + retrospective ラベル両一致）/ `t_issue_label_fallback`（milestone 不一致 + retrospective ラベル一致）の名前空間に変更。**正式名称は Construction Phase で確定**（実装言語の命名規約に合わせる余地を残す）
- **理由**: 既存 5 経路（`milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue`）と語彙衝突を回避し、bats テストでの `resolution_path` 期待値の解釈ぶれを排除
- **影響**: Unit 004 サブ責務 4B で正式名称確定 + bats 命名整合
- **関連**: Intent SC-09、Unit 004 サブ責務 4B

---

## DR-008: #710 / #715 を Comment、#704 / #652 を Closes として PR 記載に振り分け

- **日付**: 2026-05-18
- **背景**: 関連 Issue の Close vs Comment の振り分け（特に minor 想定 / CLOSED 済 Issue の扱い）
- **意思決定**:
  - **Closes**: #704（Retrospective skill セルフレビュー観点不在）、#652（三層検証 helper skill 化 / 引数 opt-in までで Close）
  - **Comment**: #710（CLOSED / 方針親 Issue / 本サイクルが本体を patch サブセット適用で先取りした旨を記録）、#715（OPEN / patch サブセット適用パターン SoT 化 / 本サイクル自体が実例提供）
- **理由**:
  - #710 は既に CLOSED 済のため再 OPEN せず Comment で進捗を残す
  - #715 は本サイクルでは「実例提供」のみで SoT 化本体は別サイクル defer のため Close せず Comment
  - #704 / #652 は本サイクルで対応スコープが完結
- **影響**: Operations Phase §7 リリース準備で PR 本文に上記記載を確認
- **関連**: Intent「関連 Issue」、Unit 004 サブ責務 4C
