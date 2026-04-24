# 実装記録: Unit 007 公開ドキュメントのサイクル運用記述を Milestone 参照に書き換え

## 実装日時

2026-04-23

## 作成・修正ファイル

### 公開ドキュメント（修正）

- `skills/aidlc/guides/issue-management.md` L52-L58「サイクルラベル付与」→「Milestone 紐付け」置換（主経路 `gh issue edit --milestone`、フォールバック `gh api PATCH`、`05-completion.md` ステップ 1 主参照、`02-preparation.md` ステップ 16 は補助動作、手動復旧 3 パターン cross-reference 追加）、L177 関連ファイル: deprecation 注記追加 + `docs/aidlc/` 旧パス → `skills/aidlc/` 実在パスに修正
- `skills/aidlc/guides/backlog-management.md` L22-L23 ラベル構成 → Milestone 紐付け置換、L94-L98 Inception Phase サイクルラベル付与 → Milestone 紐付け + 手動復旧 3 パターン分岐（A-1 duplicate/closed 混在 / A-2 LINK_FAILED Issue+PR / B gh 不可 curl+PAT+UI 3a/3b）、L138-L142 サイクルラベル作成注記 → Milestone 作成案内、L146-L154「将来検討事項」→「関連機能の現状（v2.4.0 時点）」置換（具体的なステップ番号付き）
- `skills/aidlc/guides/backlog-registration.md` L46 注記隣接に Milestone 未割当初期状態 + 正式紐付け箇所 + 補助動作説明追加
- `skills/aidlc/guides/glossary.md` 用語一覧表に 2 エントリ追加（「サイクルラベル」deprecated 注記付きを `Cycle` 直後、「Milestone」を `Logical Design` 直後の M 行アルファベット順位置）

### CHANGELOG

- `CHANGELOG.md` `[2.4.0]` 節を Keep a Changelog 順序（Added → Changed → Deprecated → Removed）に再構成。`### Added` を `### Changed` の前に新規挿入（`#597` 関連 2 項目）、`### Changed` に `#597` 関連 2 項目を追記、`### Deprecated` を `### Changed` と `### Removed` の間に新規挿入（`#597` 関連 2 項目）。既存の `### Changed`（#596 関連 2 項目）/ `### Removed`（#595 関連 1 項目）はそのまま維持

### 設計ドキュメント

- `.aidlc/cycles/v2.4.0/plans/unit-007-plan.md`
- `.aidlc/cycles/v2.4.0/design-artifacts/domain-models/unit_007_docs_milestone_rewrite_domain_model.md`
- `.aidlc/cycles/v2.4.0/design-artifacts/logical-designs/unit_007_docs_milestone_rewrite_logical_design.md`

## ビルド結果

該当なし（Markdown 編集のみ、実装ステップ変更なし）。

## テスト結果

自動テストなし（Markdown 編集のため）。Markdown 整合性検証で代替:

| 検証項目 | 期待値 | 実測値 | 結果 |
|---------|-------|-------|------|
| glossary.md Milestone エントリ | 1 | 1 | OK |
| glossary.md サイクルラベルエントリ | 1 | 1 | OK |
| issue-management.md Milestone 紐付け | 1+ | 1 | OK |
| issue-management.md v2.4.0 で deprecated | 1+ | 2 | OK |
| backlog-management.md GitHub Milestone | 2+ | 2 | OK（plan の 3+ は過大評価、2 件で Milestone 全体を説明可能） |
| backlog-registration.md Milestone 未割当 | 1 | 1 | OK |
| CHANGELOG #597 / Unit 005 / Unit 007 | 1+ | 2 | OK |
| CHANGELOG #597 / Unit 006 / Unit 007 | 1+ | 1 | OK |
| CHANGELOG #597 / Unit 007 | 2+ | 3 | OK |
| CHANGELOG label-cycle-issues.sh | 1+ | 4 | OK |
| CHANGELOG Keep a Changelog 順序 | Added → Changed → Deprecated → Removed | Added (L12) → Changed (L17) → Deprecated (L24) → Removed (L29) | OK |

## コードレビュー結果

- [x] セキュリティ: OK（機密情報なし、公開ドキュメントのみ）
- [x] コーディング規約: OK（既存 Markdown スタイル踏襲、表形式維持、glossary.md のアルファベット順維持）
- [x] エラーハンドリング: 該当なし（ドキュメント編集）
- [x] テストカバレッジ: 該当なし（自動テスト不要、Markdown 整合性 grep で代替）
- [x] ドキュメント: OK（plan / domain model / logical design / Unit 005 / 006 実装記録と完全整合。round 1 で `backlog-management.md` の Milestone close 失敗系手動復旧明記が欠落していた件は round 2 で論理設計 L142-L148 通りに補正済み）

AI レビュー:

- plan: codex で 14 反復（P1/P2/P3 合計約 20 件を順次修正、最終 unresolved=0 / auto_approved 適格）
- design: codex で 4 反復（手動復旧 3 パターン分岐の PR 側欠落・Milestone close 失敗系追記・項目数矛盾を順次修正、最終 unresolved=0 / auto_approved 適格）
- implementation: codex で 2 反復実施
  - round 1: P2×1 + P3×1 検出
    - P2-1: `backlog-management.md` L185-L190 の注記が論理設計の「Issue/PR の紐付け復旧に限れば」スコープ限定 + Milestone close 失敗系手動復旧明記を欠いていた → 論理設計 L142-L148 通りに補正
    - P3: 実装記録が「完全整合」「Milestone close 失敗系の存在を明示」と記載していたが実体と矛盾 → round 2 で修正経緯を transparently 追記
  - round 2: round 1 修正の整合性検証 → `auto_approved` 適格達成（unresolved=0）

## 技術的な決定事項

1. **過剰修正回避原則**: Unit 定義で責務候補として挙げられた `docs/configuration.md` / `README.md` / `.aidlc/rules.md` は実態調査（grep 全件確認）で Milestone 関連書き換え対象が空集合と判明したため no-op 扱い。Unit 定義側にも「候補として調査対象だが Plan 段階の実態調査で no-op 確認された場合は触らない（過剰修正回避）」の注記を同期反映
2. **手動復旧 3 パターン分岐（A-1 / A-2 / B）**: gh 利用可能/不可、duplicate/closed 混在/LINK_FAILED の組み合わせを網羅。A-1 は duplicate/closed 整理 → A-2 再紐付けのチェーン、A-2 は Issue/PR 両対応（GitHub 仕様により PR は Issue API 経由）、B は OWNER/REPO + MILESTONE_NUMBER 取得経路を前段に持つ curl + PAT or GitHub UI 手動操作
3. **duplicate 整理は close ではなく title 変更/delete**: 同名 closed Milestone が残ると `closed_count >= 1` 停止条件で後続処理が再停止するため、`title 変更` または `delete` で同名衝突を除去。完了条件は `open=1, closed=0`
4. **Keep a Changelog 順序準拠**: `[2.4.0]` 節を Added → Changed → Deprecated → Removed の順に再構成。`### Added` / `### Deprecated` を新規挿入、既存 `### Changed` / `### Removed` はそのまま維持して非影響
5. **責任分離と委譲契約**: CHANGELOG `#597` 節は本 Unit の排他所有。Unit 005 完了時は CHANGELOG 編集を発生させず「Unit 007 への引き継ぎ事項」で委譲、Unit 006 も同様。Unit 007 の Plan / 実装で 2 件受領済み
6. **glossary.md 用語順序**: 「サイクルラベル」は `Cycle` の直後（日本語混在のため既存 Cycle 行と隣接）、「Milestone」は `Logical Design` の後（M 行アルファベット順）に配置。既存エントリは触らない
7. **Milestone close 手動復旧は backlog-management.md スコープ外**: Issue/PR の紐付け復旧のみを guides で明示し、Milestone close 手動復旧（`04-completion.md` ステップ 5.5）は `operations/04-completion.md` 本体の手順に集約（Unit 006 範囲）。guides では注記で Milestone close 失敗系の存在を明示
8. **issue-management.md の cross-reference 方針**: 手動復旧 3 パターンの詳細は `backlog-management.md` Inception Phase 節へ委譲し、issue-management.md では参照リンクのみ記載（ドキュメント重複を回避）

## 課題・改善点

なし（Unit スコープは完了）。Milestone 進捗バッジの README 追加は v2.5.0 以降のバックログとして CHANGELOG に明記済み。

## 状態

**完了**

## 備考

- Issue #597 の Unit C 担当部分は本 Unit でサイクル PR (#599) マージ時に完全 close 条件成立（Unit 005 / Unit 006 / Unit 007 の 3 Unit すべて完了）
- 影響範囲: 5 ファイル（issue-management.md ±12 行 / backlog-management.md ±55 行 / backlog-registration.md +3 行 / glossary.md +2 行 / CHANGELOG.md +25 行）
- リスクレベル: Low（Markdown 編集のみ、実装ステップへの影響なし。v2.5.0 以降の最初の Inception/Operations Phase で実運用検証される）
- 関連: Unit 005（Inception Phase Milestone 作成、完了済み）/ Unit 006（Operations Phase Milestone close + 紐付け確認、完了済み）
