# Unit 001 計画: pr-ready --body-file 空ファイル検証

## 対象

- Unit 定義: `.aidlc/cycles/v2.6.2/story-artifacts/units/001-fix-pr-ready-empty-body.md`
- 関連 Issue: #678
- 関連ストーリー: ストーリー 2

## 目的

`skills/aidlc/scripts/operations-release.sh` の `pr-ready --body-file <path>` および内部 `gh_pr_edit_body_with_fallback()`（REST PATCH fallback 経路）で 0 バイト / 不在ファイルを実行前に検出し、PR 本文 `null` 上書き事故を構造的に防止する。

## スコープ

### 含まれるもの

1. `cmd_pr_ready` の `--body-file <path>` パース完了直後に「不在 / 0 バイト」検証を追加する（**最早期検出**：dry-run / 非 dry-run / find-draft 前で一律 fail-fast）
2. `gh_pr_edit_body_with_fallback()` 内部にも同等の検証を再実施する（**二重防御**：`gh pr edit` 経路と REST PATCH fallback 経路の双方より前）
3. 共通検証ヘルパー `_pr_ready_validate_body_file()` を **必須** として導入し、検証ロジックの単一 SoT を保証する（inline 実装は禁止）。呼び出し側（`cmd_pr_ready` / `gh_pr_edit_body_with_fallback()`）はヘルパー戻り値の判定のみを担当する
4. 検証エラー時の機械可読メッセージを **tab 区切り** で stderr 出力する:
   - 不在: `error\tpr-ready:body-file-missing\t<path>`
   - 0 バイト: `error\tpr-ready:body-file-empty\t<path>` ＋人間可読の案内行（"本文が空です。--body-file の中身を確認してから再実行してください"）
5. 既存の `--body-file` 経路（正常本文あり）は従来通り動作する後方互換性を維持する
6. bats テスト追加:
   - `tests/operations-release-pr-ready-body-validate.bats`（新規）: `cmd_pr_ready` の `--body-file` 検証（不在 / 0 バイト / 正常）3 ケース。**0 バイト / 不在ケースでは `gh` shim が一度も呼ばれないこと（呼び出し回数 = 0）をログファイル等でアサート**する
   - 既存 `tests/operations-release-pr-edit-fallback.bats` に fallback 経路の二重防御テスト 2 ケース追加（不在 / 0 バイト）。同様に **`gh` shim 呼び出し回数 = 0** をアサート

### 含まれないもの

- 「極端に短い本文（warning）」: Issue #678 案 A の warning ラインは本 Unit 対象外
- 案 C「テンプレ生成 helper（build-pr-body 等）」: 別 Issue で defer
- `pr-ready` 以外のサブコマンドの検証強化

## 完了条件チェックリスト

### Unit 定義「責務」由来

- [ ] `pr-ready --body-file <path>` の 0 バイト / 不在検証が実装されている
- [ ] `gh_pr_edit_body_with_fallback()` 内で同等検証が再実施されている（二重防御）
- [ ] 検証エラー時に tab 区切り機械可読メッセージ（`error\t<error_code>\t<context>`）が stderr 出力される
- [ ] bats テストで「0 バイト / 不在 / 正常 / fallback 経路」の挙動が検証されている

### Issue #678 受け入れ基準（ストーリー 2）

- [ ] `<path>` 0 バイト時: exit 1 + stderr に `error\tpr-ready:body-file-empty\t<path>` および人間可読案内
- [ ] `<path>` 不在時: exit 1 + stderr に `error\tpr-ready:body-file-missing\t<path>`
- [ ] REST PATCH fallback 経路でも上記 2 条件が検証され停止する
- [ ] 本文ありの正常 `--body-file` 経路は従来通り動作（`gh pr edit` / REST PATCH 双方）
- [ ] 空ファイル実行時に `gh pr edit` / REST PATCH リクエスト自体が送信されない（**bats で `gh` shim の呼び出し回数 = 0 をアサート**することで外部副作用未発生を明示検証）
- [ ] bats テストで 0 バイト / 不在 / 通常 3 ケースの exit code と stderr を検証
- [ ] REST PATCH fallback 経路でも同等検証ロジックが動作することを確認するテスト追加（こちらも `gh` shim 呼び出し回数 = 0 を検証）

### 非機能要件

- [ ] 検証処理オーバーヘッド 100ms 未満（`wc -c` 1 回 + `[[ -e ]]` で十分軽量）
- [ ] エラー出力に `<path>` のみ含み、ファイル**内容**は出力しない（情報リーク防止）
- [ ] macOS / Linux 双方の bash で動作（`wc -c` を採用、`stat -c %s` は非可搬で不採用）

### Intent 制約

- [ ] 破壊的変更なし（正常経路は従来動作）
- [ ] ドッグフーディング特殊処理なし（consumer プロジェクトでも同一動作）
- [ ] コマンド置換 `$(...)` 新規導入なし

## 実装方針（概略）

1. **検証ヘルパー** `_pr_ready_validate_body_file()` を `operations-release.sh` 内に追加
   - 入力: `$1=path`, `$2=phase`（任意。`"primary"` / `"fallback"` を呼び出し元から渡し、共通エラーコード `pr-ready:body-file-*` を統一）
   - 戻り値: 不在 → 1, 0 バイト → 1, それ以外 → 0
   - 出力: tab 区切り stderr メッセージ
2. **`cmd_pr_ready`** の `--body-file` 値設定後（解決済み引数パースの直後）にヘルパー呼び出し
3. **`gh_pr_edit_body_with_fallback()`** 関数冒頭にもヘルパー呼び出し（二重防御）
4. **bats**: 既存 fallback テストの shim 構造を踏襲し、`pr-ready` cmd レベルの検証を別ファイルで先行検証

## 依存・前提

- `gh` CLI: 検証は実行前段階のため不要（fixture 駆動）
- bash + POSIX `wc`: macOS / Linux 双方で動作
- bats / shellcheck / shellharden: 既存テスト環境

## リスクと緩和

| リスク | 影響 | 緩和策 |
|--------|------|--------|
| 既存 AI 運用が空ファイル渡しに依存していた場合の影響 | 中 | CHANGELOG で品質改善として明示。既存正常運用は影響なし |
| `wc -c` の出力フォーマット差異（先頭空白） | 低 | `$(...)` 禁止のため `read` で先頭フィールドを取得する、または `[[ "$(stat ...)" ]]` ではなく `wc < file` で空白除去版を使う |
| fallback 経路の二重検証で誤った早期 return | 低 | 既存テスト「ケース 1〜N」が pass することを CI で確認 |

## 想定タイムライン

- Phase 1 設計: 〜0.5 時間（小規模、ドメインモデル軽量）
- Phase 2 実装: 〜1 時間（検証ヘルパー + 呼び出し 2 箇所 + bats）
- 完了処理: 〜0.5 時間

合計: 約 2 時間（Unit 見積もり 0.5〜1 日内）
