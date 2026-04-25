# Unit 001 実装計画: Operations 7.13 merge_method 設定保存ガード追加

## 対象

- Unit 定義: `.aidlc/cycles/v2.4.1/story-artifacts/units/001-operations-merge-method-save-guard.md`
- 対象 Issue: #601
- 主対象ファイル: `skills/aidlc/steps/operations/operations-release.md`（§7.13 L91-118 周辺）
- 整合確認: `skills/aidlc/steps/operations/04-completion.md`（L42）・`skills/aidlc/steps/operations/02-deploy.md`（L168-184）

## スコープ

Operations Phase §7.13 の `merge_method=ask` フローで、`write-config.sh` 実行後に `.aidlc/config.toml` の未コミット差分を検出し、ユーザーに 3 択（コミット+push / follow-up PR / 破棄）を提示する案B（マージ前コミット+push フロー明示）を実装する。

## 実装方針

### Phase 1（設計）

- **ドメインモデル設計**: 対象ファイルの改訂なので通常の「ドメインエンティティ」設計ではなく、対象となる Markdown 手順書のセクション構造と「case（3 分岐）」の状態遷移モデルを設計する
- **論理設計**: ガード挿入位置、`AskUserQuestion` 呼び出し形式、3 分岐の各手順（bash コマンド例、ユーザーへのガイダンス文言）、終了条件チェックを疑似コード/フローで記述

### Phase 2（実装）

- **改訂対象**: `operations-release.md` §7.13 L91-118 周辺
- **挿入位置**: 「設定保存フロー【ユーザー選択】」の `scripts/write-config.sh` 実行直後（L106 以降）、「マージ実行確認」の前段
- **追加内容**:
  - 未コミット差分検出ガード（`git diff --quiet .aidlc/config.toml` または `git status --porcelain .aidlc/config.toml`）
  - `AskUserQuestion` による 3 択提示
  - 各分岐の手順（コミット+push / follow-up PR / 破棄）
  - 各分岐の終了条件（PR 反映確認 / follow-up PR 番号記録 / 差分ゼロ確認）
- **「案B を採用した」旨の明示**: 該当ブロック先頭にコメントまたは説明文を追加

### Phase 2b（検証）

- 3 分岐の walkthrough: 既存の 7.13 以降フロー（マージ実行確認・マージ実行）上で矛盾なく成立することを手順書読み合わせで確認
- jailrun v0.3.1 再発ケース追試: `merge_method=ask` + 保存選択 + マージ直前に設定差分残存のケースを手順レベルで追試

### Phase 3（完了処理）

- **設計／コード／統合 AI レビュー承認**: `review-flow.md` に従い 3 種のレビューを実施、全て `auto_approved` または修正反映で承認完了
- **Unit 定義ファイル状態更新**: `story-artifacts/units/001-operations-merge-method-save-guard.md` の実装状態を「完了」に更新、完了日を記録
- **履歴記録**: `/write-history` スキルで `.aidlc/cycles/v2.4.1/history/construction_unit01.md` に追記
- **Markdownlint 実行**: `markdown_lint=true` のため、改訂した Markdown ファイル（`operations-release.md`）を対象に lint を実行、違反なしを確認
- **Squash 実行**: `squash_enabled=true` のため `/squash-unit` スキル経由で Unit 001 の中間コミットを UNIT_COMPLETE 形式に統合
- **Git コミット**: Squash 後の状態確認、force-push が必要な場合はユーザー承認を得る

## 完了条件チェックリスト

- [ ] `operations-release.md` §7.13 に `write-config.sh` 実行直後のガード手順が追加されている
- [ ] `AskUserQuestion` で 3 択（コミット+push / follow-up PR / 破棄）が提示されている
- [ ] 3 分岐それぞれの具体手順（bash コマンド + ユーザーガイダンス）が記述されている
- [ ] 3 分岐それぞれの終了条件が手順書内に明示されている（PR 反映確認 / follow-up PR 番号記録 / 差分ゼロ確認）
- [ ] 「案B を採用した」旨がコメントまたは説明文で明示されている
- [ ] `04-completion.md` L42 の post-merge 改変禁止ルールとの整合が保たれている（規則の拡張や破壊なし）
- [ ] `02-deploy.md` L168-184 のサブステップ索引の注記が整合している
- [ ] `automation_mode` に関わらず（`manual` / `semi_auto` / `full_auto` のすべて）`AskUserQuestion` が対話必須として動作する（ユーザー選択種別のため常に対話必須。既存の 7.13 ドキュメントと整合）
- [ ] 3 分岐 walkthrough で既存 7.13 以降フローとの矛盾が存在しないことを確認
- [ ] jailrun v0.3.1 再発ケースの追試で差分が残らないことを確認
- [ ] 設計 AI レビュー承認
- [ ] コード AI レビュー承認
- [ ] 統合 AI レビュー承認
- [ ] Unit 定義ファイル状態を「完了」に更新
- [ ] 履歴記録（`construction_unit01.md`）
- [ ] Markdownlint 実行（`markdown_lint=true`）
- [ ] Squash 実行（`squash_enabled=true`）
- [ ] Git コミット

## 依存関係

依存する Unit: なし。他 Unit と独立並列実装可能。

## 見積もり

- Phase 1（設計）: 0.25〜0.5 日
- Phase 2（実装）: 0.25〜0.5 日
- Phase 2b（検証）: 0.25 日（上限を 0.25 日に圧縮し、Unit 定義の合計 1.5 日上限に収める）
- Phase 3（完了処理）: 0.25 日

合計: 1〜1.5 日規模（Intent / Unit 定義の見積もり 0.75〜1.5 日上限と整合）

## リスク・留意点

- **副次影響のリスク**: `operations-release.md` §7.13 は Operations Phase の中核ステップ。ガード挿入位置を誤ると既存フロー（特にマージ実行確認との前後関係）を破壊する可能性あり → 3 分岐 walkthrough で必ず確認
- **`git status` / `git diff` のコマンド選定**: 検出精度（`.aidlc/config.toml` 限定かトップレベル全体か）を論理設計で明確化する
- **follow-up PR 手順の具体化**: jailrun v0.3.1 の実運用手順（`git stash` → 新ブランチ → PR 作成）をリファレンス化するが、ユーザー環境によっては `gh auth` 不可のケースがあるため手動 fallback を併記
- **`automation_mode=semi_auto` での挙動**: ユーザー選択種別のため `automation_mode` に関わらず対話必須。既存の 7.13 notes と整合（既に明示されている）
