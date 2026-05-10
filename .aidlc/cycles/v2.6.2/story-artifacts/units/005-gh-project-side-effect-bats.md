# Unit: Unit 006 副作用 bats テスト整備（gh API モックフレームワーク）

## 概要

v2.6.0 Unit 006 で defer された 4 スクリプト（`setup-github-project.sh` / `migrate-issue-524.sh` / `probe-github-project.sh` / `audit-github-project.sh`）の本体動作（副作用）を bats でテストするための gh API モックフレームワークを整備し、各スクリプトの正常系・異常系を網羅する。Phase 1（モック基盤）→ Phase 2（4 スクリプトテスト）の段階完了で進める。Issue #683（v2.6.0 Unit 006 R1 codex 指摘 #3 の defer）。

## 含まれるユーザーストーリー

- ストーリー 5: Unit 006 副作用 bats テスト整備（gh API モックフレームワーク）

## 責務

- **Phase 1**: `bin/tests/gh-project/_helpers.bash`（または等価ファイル）に gh API モックヘルパー新設。fixture JSON で擬装可能な API: `gh project list` / `create` / `field-list` / `item-add` / `item-list` / `item-edit`
- **Phase 2**: 4 つの bats ファイル（setup / migrate / probe / audit）追加、それぞれの本体動作（subcommand orchestrator / dry-run diff / sandbox cleanup / SLA 判定 / probe-evidence 不在時 exit 5 等）を網羅
- 既存 28 件の引数 / エラー系テストとの並存確認
- 想定外引数で fail する未モック API 検出機構

## 境界

- モック対象 API は v2.6.0 Unit 006 計画書記載の 4 スクリプトが必要とする最小限に限定（YAGNI / Intent 制約事項）
- `gh` 全 API のフルモック構築は対象外
- `dasel` / 他 CLI のモック化は必要時のみ最小限で実装

## 依存関係

### 依存する Unit

- ストーリー間依存マトリクスに従い **Unit 004（gh-project-cli options 差分同期）を先に完了することを推奨**（同一サイクル内の順序前提）。順序前提が崩れた場合は本 Unit Phase 2 で options 差分同期テストを追加する形で吸収する

### 外部依存

- v2.6.0 Unit 006 で整備された 4 スクリプト本体（`setup-github-project.sh` / `migrate-issue-524.sh` / `probe-github-project.sh` / `audit-github-project.sh`）
- bats / shellcheck / shellharden（既存テスト環境）
- bash + jq / dasel（fixture JSON 操作）

## 非機能要件（NFR）

- **保守性**: 新規 API モックを追加する際の改修コストが小さい（ヘルパーの拡張ポイントが明確）
- **検出力**: 未モック API 呼び出し時にテストヘルパーが明示的に fail
- **保証性**: 既存 28 件 + 新規追加分が `make test` 相当で全件 green

## 技術的考慮事項

- モック実装方針: (a) PATH override で `gh` を wrapper script に置換、(b) bash function override（`gh () { ... }` を bats setup で定義）、(c) wrapper script を一時 PATH に配置、のいずれか。Construction 設計レビューで確定
- fixture JSON は `bin/tests/gh-project/fixtures/` 等に配置し、各テストが必要な API レスポンスを参照できる構造にする
- Phase 1 完了マーカー: モックヘルパーが `setup-github-project.sh.bats` 1 本（最小スイート）から呼び出せ、想定外引数で fail することが確認できる
- Phase 2 完了マーカー: 4 つの bats ファイルすべてがモック基盤上で pass、既存と並存
- 既存テストとの命名衝突を避けるため、bats ファイル名は `<script-name>.bats`（例: `setup-github-project.bats`）形式で統一

## Unit 004 / 005 の責務境界

- **Unit 004 の Done 条件**: options 差分同期ロジックの **機能テスト**（差分計算 / 追加 API 呼び出し / dry-run / strict / soft の挙動）を最小スイートで網羅。Unit 004 完了時点でロジック自体は検証済み
- **Unit 005 の Done 条件**: 副作用モック基盤の整備と 4 スクリプト本体動作の **回帰テスト** 担保。Unit 004 で追加された options 差分同期ロジックの回帰検証も Phase 2 のスコープに含めるが、機能完成判定そのものは Unit 004 が担う（Unit 005 は回帰防止のみ）

## Intent 制約適合

- **破壊的変更なし**: 本 Unit はテスト追加のみで本体動作を変更しない。既存 28 件のテストとの並存を確認
- **ドッグフーディング特殊処理禁止**: モックヘルパーは consumer プロジェクトでも動作する汎用形式（PATH override / function override 等）で実装
- **コマンド置換禁止**: テストヘルパー / fixture 操作で `$(...)` 形式のコマンド置換を新規導入しない

## 関連Issue

- #683（type:defer-from-review, priority:medium / v2.6.0 Unit 006 R1 #3）

## 実装優先度

Medium

## 見積もり

2〜3 日。Phase 1（モック基盤整備）に 0.5〜1 日、Phase 2（4 スクリプトテスト）に 1.5〜2 日。Phase 2 は 4 スクリプトを 2 グループに分けて段階完了することも可能（setup + migrate / probe + audit）。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
