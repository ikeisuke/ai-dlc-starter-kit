# 実装記録: Unit 006 Operations Phase へ Milestone close + 紐付け確認 + fallback 作成を組込み

## 実装日時

2026-04-23

## 作成・修正ファイル

### スキルステップ（修正）

- `skills/aidlc/steps/operations/01-setup.md` ステップ10 直後に新規ステップ11「Milestone 紐付け確認・fallback 判定」(11-1: 5 ケース判定 + fallback 作成 / 11-2: Issue 紐付け補完 3 分岐 + LINK_FAILED 蓄積 / 11-3: PR 紐付け補完 3 分岐 + ステップ11 末尾集約判定 exit 1) 追加
- `skills/aidlc/steps/operations/04-completion.md` ステップ5「PRマージ後の手順」末尾に新規ステップ5.5「Milestone close」(5 ケース判定 / open=1 のみ close 実行 / closed=1&open=0 は already-closed 扱い / 失敗時 exit 1 + 手動コマンド案内 / `gh_status != available` 時 exit 1 + REST API 直叩き手動代替手順) 追加
- `skills/aidlc/steps/operations/index.md` §2.8 「gh_status 分岐」表を 2 行 → 3 行に拡張（Milestone close 例外契約 を表内に追加）し、補助契約として「`gh_status = available` 時の Milestone 紐付け補完失敗 → exit 1」を別セクションで追記

### 設計ドキュメント

- `.aidlc/cycles/v2.4.0/plans/unit-006-plan.md`
- `.aidlc/cycles/v2.4.0/design-artifacts/domain-models/unit_006_operations_milestone_close_domain_model.md`
- `.aidlc/cycles/v2.4.0/design-artifacts/logical-designs/unit_006_operations_milestone_close_logical_design.md`

## ビルド結果

該当なし（Markdown 編集のみ、機能変更は GitHub 側 API 操作）。

## テスト結果

自動テストなし（Markdown 編集のため）。代わりに plan / logical design の動作確認手順で検証:

| 検証項目 | 結果 |
|---------|------|
| 01-setup ステップ11 見出し追加 | OK (1 件) |
| 01-setup milestone:{{CYCLE}}:fallback-created | OK (1 件) |
| 01-setup milestone:{{CYCLE}}:exists:number | OK (1 件) |
| 01-setup CLOSED_COUNT >= 1 (5 ケース判定) | OK (≥1) |
| 04-completion ステップ5.5 見出し追加 | OK (1 件) |
| 04-completion milestone:{{CYCLE}}:closed:number | OK (1 件) |
| 04-completion milestone:{{CYCLE}}:already-closed:number | OK (1 件) |
| 04-completion ERROR: Milestone close 失敗 | OK (1 件) |
| 04-completion CLOSED_COUNT >= 1 (5 ケース判定 setup と同じ判定基盤) | OK (2 件) |
| 04-completion ERROR: Milestone .* が見つかりません (open=0 closed=0 停止) | OK (1 件) |
| 04-completion マージ前完結契約準拠 | OK (1 件) |
| 04-completion GitHub 側操作のみ | OK (2 件) |

## コードレビュー結果

- [x] セキュリティ: OK（機密情報なし、`gh api` は OWNER/REPO 動的解決）
- [x] コーディング規約: OK（既存 Markdown スタイル踏襲、bash コメントスタイル踏襲、表形式維持）
- [x] エラーハンドリング: 5 ケース判定で重複作成・命名衝突・混在・運用異常を停止、PATCH フォールバックで権限/環境差分対応、close 失敗時に exit 1 + 手動コマンド案内、`gh_status != available` 時に exit 1（サイクル未完結防止）、link-failed が 1 件以上ある場合に exit 1（紐付け未達のまま close しない契約）
- [x] テストカバレッジ: 該当なし（自動テスト不要、Markdown 整合性 grep で代替）
- [x] ドキュメント: OK（plan / domain model / logical design / index.md §2.8 中央契約と完全整合。round 3 で plan / logical design の 3 ファイル化、§2.8 補助契約の条件ラベル修正により round 4 で整合確認済み）

AI レビュー: plan 3 反復 + design 2 反復で auto_approved 適格達成。implementation レビューは codex で 5 反復実施:

- **round 1**: P2×2 + P3×1 検出
  - P2-1: 04-completion 5.5 の `gh_status != available` 時のメッセージが「スキップする」と「`gh api` を実行してください」の矛盾（gh 利用不可なのに `gh api` を案内）→ exit 1 + REST API 直叩き / GitHub UI 手動代替手順に修正
  - P2-2: 01-setup ステップ11-2/11-3 の link-failed が `>&2` の警告のみで後段ステップ（04-completion 5.5 close）を実施可能だった → `LINK_FAILED` 蓄積 + ステップ11 末尾集約判定で exit 1 する契約に修正（bash here-string `<<< "$ISSUE_NUMBERS"` で同シェルコンテキスト維持）
  - P3: 本実装記録が round 1 時点で「auto_approved 適格 / 課題なし」と過大評価していた
- **round 2**: P2×2 + P3×1 検出（実装ステップ修正だけでは不十分、設計正本との不整合が残存）
  - P2-1: `skills/aidlc/steps/operations/index.md` §2.8 中央契約が旧仕様（`available` 以外は一律スキップ）のままだった → Milestone close 例外契約を §2.8 表に追加。round 2 時点では暫定的に表 4 行化していたが、round 3 で条件ラベル誤りを指摘され、round 3 → 4 で「3 行表 + 補助契約セクション」の最終形に再構成
  - P2-2: `unit-006-plan.md` / `unit_006_operations_milestone_close_logical_design.md` のコード断片に round 1 修正が未反映（`echo | while`, `link-failed` 警告のみ, 5.5 「skip + gh api 案内」が残存）→ plan / logical design 双方を実装に揃えて更新
  - P3: round 2 時点でも実装記録が運用穴を反映していなかった
- **round 3**: P2×4 検出（中央契約と plan/logical design スコープの不整合が残存）
  - P2-1: index.md §2.8 表 4 行目「`available` 以外（例外: Milestone 紐付け補完失敗）」のラベルが実処理（`gh_status = available` 経路でのみ発動）と逆 → 補助契約セクションとして分離・条件を実装通りに修正
  - P2-2: plan 冒頭「以下 2 ファイルを更新する」と「ファイル変更一覧」が `index.md` §2.8 変更を含まず → 3 ファイル化、変更一覧に index.md §2.8 行を追加
  - P2-3: logical design 「修正対象 2 ファイル」「ファイル変更一覧」も同様に index.md 抜け → 3 ファイル化、§2.8 例外契約の設計仕様を明示記載
  - P2-4: 実装記録が round 3 時点で「unresolved=0 / auto_approved 適格達成」と矛盾した自己評価をしていた
- **round 4**: P2×1 検出（実装記録の表現が古かった）
  - P2-1: 実装記録 L13 「表を 2 行 → 4 行」の表現が `index.md §2.8` 実体（3 行表 + 補助契約セクション）と不整合 → 実装記録 L13 / L59 を最終形に更新
- **round 5**: round 4 修正の整合性検証 → `auto_approved` 適格達成（unresolved=0）。実装ステップ・index.md §2.8・plan・logical design・実装記録の 5 文書間で整合性確保

## 技術的な決定事項

1. **責任分離（01-setup ステップ11 vs 04-completion ステップ5.5）**: setup 側は「Operations 開始時の Milestone 状態確認・fallback 救済」、completion 側は「PR マージ後の Milestone close 確定処理」
2. **5 ケース判定の 3 配置で同一判定基盤、2 ケース動作差分**: open=0 closed=0 は Unit 005 = 通常作成 / Unit 006 setup 11-1 = fallback 作成 / Unit 006 completion 5.5 = エラー停止、open=0 closed=1 は Unit 005 / Unit 006 setup 11-1 = エラー停止 / Unit 006 completion 5.5 = already-closed 成功扱い
3. **冪等補完原則（Issue/PR 紐付け）**: 3 分岐（empty / {{CYCLE}} / 他 Milestone）で empty 時のみ PATCH、他 Milestone は警告のみで付け替えない（NFR「1 Issue = 1 Milestone 制約に整合」を厳守）
4. **マージ前完結契約準拠**: 04-completion ステップ5.5 は GitHub 側操作のみで `.aidlc/cycles/{{CYCLE}}/**` 配下のファイルは更新しない。`write-history.sh` ガード（exit 3）にも影響しない
5. **already-closed 厳密判定**: `CLOSED_COUNT == 1 && OPEN_COUNT == 0` の厳密判定で多重 closed を見逃さない（closed=2 は後続 elif でエラー停止）
6. **awk Issue 抽出ロジック**: Unit 005 と同一（`label-cycle-issues.sh` の extract_issue_numbers() ベース、対応形式 5 種維持）
7. **PR 紐付けは Issue API 経由**: GitHub 仕様（PR は Issue の特殊形）
8. **`gh_status != available` 時 exit 1 契約（04-completion 5.5）** [round 2 追加]: gh CLI 不可時に「スキップ」では Milestone close 未実施のままサイクル完了させてしまうため、exit 1 で停止し、REST API 直叩き（curl + PAT）または GitHub UI 上での手動 close 手順を提示する
9. **link-failed 集約判定 exit 1 契約（01-setup ステップ11）** [round 2 追加]: ステップ11-2 / 11-3 の Issue / PR 紐付け補完で 1 件でも失敗があれば、ステップ11 末尾で `LINK_FAILED` を集約判定して exit 1 する。bash here-string `<<< "$ISSUE_NUMBERS"` を使用するのは `echo | while` だとサブシェルで `LINK_FAILED` が親シェルに伝播しないため。link-failed 解消まで 04-completion 5.5 を実施しない契約とする（紐付け未達のまま close するとサイクル可視化が不完全になるため）

## 課題・改善点

なし（Unit スコープは完了。round 1 で検出された運用穴 2 件は round 2 で修正済み、本記録「コードレビュー結果」と「技術的な決定事項 8 / 9」に明記）。CHANGELOG `#597` 節への Unit 006 関連記載は Unit 007 で実施。

## 状態

**完了**

## 備考

- Issue #597 の Unit A 担当部分は本 Unit でサイクル PR (#599) マージ時に部分対応として進捗。完全 close は Unit 007（Unit C）完了後（Unit 005 / Unit 006 / Unit 007 の 3 Unit すべて完了が条件）
- 影響範囲: 3 ファイル（01-setup.md +130 行 / 04-completion.md +70 行 / index.md §2.8 +6 行）
- リスクレベル: Low-Medium（Markdown 追加のみ、機能変更は GitHub 側 API 操作。v2.5.0 以降の最初の Operations Phase で実運用検証）
- 関連: Unit 005（Inception 側 Milestone 作成、完了済み）/ Unit 007（ドキュメント更新 + CHANGELOG `#597` 節、依存後）

## Unit 007 への引き継ぎ事項【重要】

**Unit 007 の受け入れ基準に追加すべき項目**: CHANGELOG `#597` 節に以下の Operations Phase 側追加機能の記載を含めること:

> - Operations Phase に Milestone close + 紐付け確認 + fallback 作成手順を追加（`skills/aidlc/steps/operations/01-setup.md` ステップ11 / `04-completion.md` ステップ5.5）。マージ前完結契約準拠（GitHub 側操作のみ）、5 ケース判定で誤再オープン防止、冪等補完原則で 1 Issue = 1 Milestone 制約遵守（#597 / Unit 006 / Unit 007）

Unit 006 では Operations Phase Markdown ステップ追加のみ実施済み（CHANGELOG への記載は Unit 007 の責務、本ファイルの「Unit 007 への引き継ぎ事項」セクションで委譲明記）。
