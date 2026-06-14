# 実装記録: Unit 002 work-item-next.sh（依存解決による次 work item 選定）

## 実装日時
2026-06-14

## 作成ファイル

### ソースコード
- `skills/aidlc-v3/scripts/work-item-next.sh` - work-items を走査し data-model §5.2 + resume 優先で次着手 work item を決定的に 1 件選定する読み取り専用スクリプト。出力 `next:<id>:<size>:<path>` / `next:none`。`id_lt`（数値優先 id 昇順）/ `wi_scalar`（スカラー抽出）/ `wi_deps`（依存配列パース）/ `status_of_id`（線形探索）。macOS bash 3.2 互換（連想配列不使用）。

### テスト
- `skills/aidlc-v3/scripts/tests/test-work-item-next.sh` - 自己完結サンドボックス（mktemp -d）。終了コード 0/1/2 / 候補 status 規約 / 境界 (a)-(e) / blocked 依存非充足 / resume 優先（複数 in_progress WARN）/ id 数値昇順（2 vs 10）/ 空依存 vacuous / 複数依存 AND / size 同梱出力。計 27 件。

### 設計ドキュメント
- .aidlc/cycles/v3.0.0-alpha.3/design-artifacts/domain-models/unit_002_work_item_next_domain_model.md
- .aidlc/cycles/v3.0.0-alpha.3/design-artifacts/logical-designs/unit_002_work_item_next_logical_design.md

## ビルド結果
成功（シェルスクリプトのため静的検査で代替）

```text
shellcheck: work-item-next.sh / test-work-item-next.sh クリーン（重大警告なし）
bash -n: 構文エラーなし
```

## テスト結果
成功

- 実行テスト数: 27（test-work-item-next.sh）/ 回帰: 75（test-define-flow.sh）+ 68（test-state-scripts.sh）
- 成功: 全件
- 失敗: 0

```text
test-work-item-next.sh: PASS 27 / FAIL 0
回帰: test-define-flow.sh PASS 75 / test-state-scripts.sh PASS 68
markdownlint: 0 error
```

## コードレビュー結果
- [x] セキュリティ: OK（読み取り専用 / 状態変更なし / パスは引数 dir + filename 連結のみ）
- [x] コーディング規約: OK（既存 scripts と一致 / `set -euo pipefail` / 終了コード 0/1/2 / result-out 関数 local namespace 化 / bash 3.2 互換）
- [x] エラーハンドリング: OK（引数/dir 不在=exit 1 / 読み取り不可=exit 2 / 候補なし=exit 0 + next:none）
- [x] テストカバレッジ: OK（境界 (a)-(e) / 終了コード / resume / id 数値昇順を網羅）
- [x] ドキュメント: OK（設計-実装整合 / review-summary Set 1-3）

## 技術的な決定事項
- **D1 パース独自実装**: `work-item-validate.sh`（Unit 001）を変更せず、next.sh 内に最小限のスカラー/配列パースを実装。validate（検証 = malformed で exit 1）と next（選定 = validate 済み前提の読み取り）はエラー意味論が異なり、共有 lib 化は tested code 再オープン + 結合を生むため defer（3 consumer ルール）。
- **D2 resume 優先**: in_progress work item があれば最小 id を返す（中断再開）。複数 in_progress は異常として WARN（develop の 1 件ずつ前提と整合）。
- **id 昇順は数値優先**: glob 辞書順依存を排し `id_lt`（数字のみなら `10#...` base-10 数値昇順 / それ以外文字列昇順）で `2 < 10` を正す（コードレビュー R1）。
- **候補なしは exit 0（next:none）**: 選定不能を正常系とし、develop が release 可能（§5.1 評価順 4）等へ分岐できる。exit 1 は入力エラー限定。
- **size 同梱出力**: `next:<id>:<size>:<path>` で Unit 003 が tiny 確認の再パース不要（計画レビュー指摘 #2）。

## 課題・改善点
- frontmatter パースの共有 lib 化は 3 例目の consumer 出現時に検討（YAGNI / 現状は work-item-validate.sh と next.sh の 2 例で重複は小さい）。
- 複数候補時の AI 優先度提案 + 人間選択は Unit 003（develop）の手順層の責務（本 Unit は決定的 1 件返却）。

## 状態
**完了**

## 備考
- 統合レビュー（codex）設計 R3 clean / コード R2 clean / 統合 R2 clean、計 5 件修正。詳細は `construction/units/002-review-summary.md`。
- v2 非影響: 変更は `skills/aidlc-v3/` と当該 cycle dir に限定（`skills/aidlc/` 非影響 / Unit 001 の work-item-validate.sh 非変更）。
