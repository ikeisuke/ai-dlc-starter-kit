# Unit: gh-project-cli ensure-fields の field options 差分同期

## 概要

`bin/gh-project-cli.sh _subcmd_ensure_fields` の `field:exists` 分岐に options 差分同期ロジックを追加し、spec.yaml 改訂後の再実行で新 option が既存 field に追加される（冪等同期）動作を実現する。v2.6.0 Unit 006 R1 codex 指摘 #2 の defer。

## 含まれるユーザーストーリー

- ストーリー 4: gh-project-cli ensure-fields の field options 差分同期

## 責務

- `_subcmd_ensure_fields` の `field:exists` 分岐拡張
- 既存 field の `.options[].name` 取得 + spec 側 `fields[*].options` との差分計算
- 差分 option を `bin/lib/gh-project-repo.sh::gh_project_repo_add_field_option` で順次追加
- dry-run / strict / soft 各モードの正しい動作
- 同期処理の出力フォーマット定義（`field:<name>:options-added:<count>:names=<n1>,<n2>,...`）
- bats テスト追加（差分なし / 1 件追加 / 複数追加 / 全件既存（no-op） + dry-run / strict / soft）

## 境界

- options 差分の **追加方向のみ**（spec → 既存への片方向）。既存 options を spec から削除するのは本 Unit 対象外（strict モードは検出のみ実施）
- field 自体の create / delete は既存実装に委譲（変更なし）
- option 順序の保証は本 Unit 対象外（GitHub Projects API の仕様上、テストは集合一致で判定）

## 依存関係

### 依存する Unit

- なし

### 外部依存

- v2.6.0 Unit 006 で整備された `bin/gh-project-cli.sh` / `bin/lib/gh-project-repo.sh` 本体
- `gh project field-list` / `gh project field-edit`（gh CLI ProjectsV2 API）
- bats / shellcheck / shellharden（既存テスト環境）
- `gh-project-repo.sh::gh_project_repo_add_field_option` ヘルパー（既存）

## 非機能要件（NFR）

- **冪等性**: 同一 spec で複数回実行しても結果が変わらない（既存 options 検出 → no-op）
- **可観測性**: 追加した option 名と件数が stdout に明示される
- **モード対応**: dry-run / strict / soft の各モードが既存の他 subcommand と一貫した動作をする

## 技術的考慮事項

- 差分計算は集合演算（spec - existing）で実装。順序非依存
- strict モード: spec にない既存 options を検出した場合 exit 非 0（情報出力 + 警告）
- soft モード: API 呼び出し失敗を warn 扱いで継続（既存挙動踏襲）
- dry-run: option 追加 API は呼ばず、追加予定一覧のみ出力
- 関連設計: `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md` § gh-project-repo.sh
- 推奨実装順序: 本 Unit を先に完了 → Unit 005（bats モック整備）で **副作用モック基盤と 4 スクリプト本体動作の回帰担保**。順序前提が崩れた場合は Unit 005 Phase 2 で options 差分同期の回帰テストを吸収する

## Unit 004 / 005 の責務境界

- **Unit 004 の Done 条件**: options 差分同期ロジックの **機能テスト**（差分計算 / 追加 API 呼び出し / dry-run / strict / soft の挙動）を最小スイートで網羅。本 Unit 完了時点でロジック自体は検証済み
- **Unit 005 の Done 条件**: 副作用モック基盤の整備と 4 スクリプト本体動作の **回帰テスト** 担保。Unit 004 で追加された options 差分同期ロジックの回帰検証も Phase 2 のスコープに含めるが、機能完成判定そのものは Unit 004 が担う

## Intent 制約適合

- **破壊的変更なし**: 既存 `field:create` 経路は変更しない。`field:exists` 分岐への加算のみで、既存設定の挙動を維持
- **ドッグフーディング特殊処理禁止**: 自リポジトリ判定による分岐は導入しない。consumer プロジェクトでも同一の差分同期ロジックが動作する
- **コマンド置換禁止**: 実装内で `$(...)` 形式のコマンド置換を新規導入しない（既存 `gh-project-cli.sh` の規約踏襲）

## 関連Issue

- #682（type:defer-from-review, priority:medium / v2.6.0 Unit 006 R1 #2）

## 実装優先度

Medium

## 見積もり

0.5〜1 日。差分同期ロジック自体はシンプル、dry-run / strict / soft 各モードの整合性検証 + bats fixture（GitHub API モックの最小スイート）が大半。**実装順序は user_stories.md の依存マトリクスに従い 004 → 005**（004 を先に完了し、Unit 005 Phase 2 で options 差分同期の回帰テストを担保）。順序前提が崩れた場合の吸収先は Unit 005 側のみとする。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
