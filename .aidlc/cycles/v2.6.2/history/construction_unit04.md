# Construction Phase 履歴: Unit 04

## 2026-05-12T08:48:22+09:00

- **フェーズ**: Construction Phase
- **Unit**: 04-gh-project-cli-options-sync（gh-project-cli ensure-fields の field options 差分同期）
- **ステップ**: Unit完了処理
- **実行内容**: Unit 004 完了 - gh-project-cli ensure-fields の field options 差分同期実装（spec.yaml 改訂後の冪等同期）

## 主要な変更

1. `bin/gh-project-cli.sh`
   - `_emit_warn` ヘルパー追加（`_emit_error` と同形式 JSON / stderr / exit せず）
   - `_sync_field_options` ヘルパー追加（JSON 配列 I/F / strict + extraneous fail-fast / dry-run / soft の各モード対応 / option 名サニタイズ）
   - `_subcmd_ensure_fields` の `field:exists` 分岐に options 差分同期呼出を追加（spec.options が array 形式の field のみ。dynamic / null は素通り）
2. `bin/tests/gh-project/ensure_fields_options_sync.bats`（新規 14 ケース、全 pass）
   - no-op / 1 件追加 / 複数追加 / strict 既存余分 fail-fast / strict 双方向差分 fail-fast / soft 既存余分 / dry-run + 追加 / dry-run + 既存余分 / strict + API 失敗 / soft + API 失敗 / strict + 部分成功後失敗 / option 名サニタイズ 2 件 / dynamic field スキップ
   - gh / yq / dasel モックを fixture 経由で注入。GraphQL 呼出は option=<name> 単位で 1 行/呼出 にログ正規化
3. `.aidlc/cycles/v2.6.2/story-artifacts/units/004-gh-project-cli-options-sync.md`
   - 「Intent 制約適合」の「コマンド置換」項目を改訂（AI Bash プロンプト経由および git commit -m 内のみ禁止 / 既存スクリプト内部の `$(...)` は許容）

## AI レビュー完了（対象タイミング: 統合とレビュー）

- 計画レビュー: codex Round 1 で 5 件（高 2 / 中 2 / 低 1）→ Round 2 で 3 件 → Round 3 で全解消（指摘0件）
- 設計レビュー: codex Round 1 で 3 件（高 1 / 中 2）→ Round 2 で 2 件 → Round 3 で全解消（指摘0件）
- コードレビュー: codex Round 1 で 3 件（中 2 / 低 1）→ Round 2 で全解消（指摘0件）
- 統合レビュー: codex Round 1 で指摘0件、完了条件全 19 項目達成

## 関連 Issue

- 解決: #682（type:defer-from-review / priority:medium / v2.6.0 Unit 006 R1 #2 の defer）
- 関連先行: v2.6.0 Unit 006 R1 #2（#673）

## 決定事項

- 意思決定記録: 対象なし（ユーザー選択を伴う 2 択以上の意思決定は発生せず、全て AI レビュー指摘起点の技術整合性修正）
- **成果物**:
  - `.aidlc/cycles/v2.6.2/plans/unit-004-plan.md`
  - `.aidlc/cycles/v2.6.2/design-artifacts/domain-models/unit_004_gh_project_cli_options_sync_domain_model.md`
  - `.aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_004_gh_project_cli_options_sync_logical_design.md`
  - `bin/gh-project-cli.sh`
  - `bin/tests/gh-project/ensure_fields_options_sync.bats`

---

## 補足（short note）

Unit 004 完了: ensure-fields に options 差分同期ロジック追加。strict + extraneous は fail-fast、JSON 配列 I/F、option 名サニタイズ。bats 14 ケース全 pass。Issue #682 解決。