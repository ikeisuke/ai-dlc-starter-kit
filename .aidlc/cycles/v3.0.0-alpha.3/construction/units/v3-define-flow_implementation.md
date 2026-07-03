# 実装記録: Unit 001 v3 define フロー実行実装

## 実装日時
2026-06-13 〜 2026-06-14

## 作成ファイル

### ソースコード
- `skills/aidlc-v3/scripts/state-init.sh` - 初期 `state.json` skeleton を atomic に create-only 生成（temp→validate→`ln`）。current_cycle 入力健全性ガード（`^[A-Za-z0-9][A-Za-z0-9._-]*$`）。終了コード規約 0/1/2。
- `skills/aidlc-v3/scripts/work-item-validate.sh` - work item `*.md` を data-model §4 で検証する読み取り専用ゲート実体（define Step 4-2）。必須 6 キー / enum / 型（assigned string\|null・dependencies array）/ id-filename 整合 / 本文 6 セクション / dependencies 実在 ID / 任意 expected_status。`read_scalar` ヘルパでスカラー抽出を balanced-quote に統一。
- `skills/aidlc-v3/steps/define.md` - define フローを skeleton から実行手順へ書き換え。Step 4 を「成果物配置 → 検証ゲート（work-item-validate.sh）→ state-init → state-write → branch/commit」のゲート先行 fail-fast 順に規定。

### テスト
- `skills/aidlc-v3/scripts/tests/test-define-flow.sh` - 自己完結サンドボックス検証（mktemp -d / jq+git）。state-init.sh 単体（終了コード 0/1/2・create-only・入力健全性・race 代替）/ work item 検証ゲート全項目（enum / 型 / 配列要素構文 / 引用符バランス / id-filename / セクション / 依存実在 / expected_status 分岐）/ define Step 4 e2e（新規ブランチ・skip 経路・ゲート失敗 fail-fast）。計 75 件。

### 設計ドキュメント
- .aidlc/cycles/v3.0.0-alpha.3/design-artifacts/domain-models/unit_001_v3_define_flow_domain_model.md（WorkItemValidator サービス追加）
- .aidlc/cycles/v3.0.0-alpha.3/design-artifacts/logical-designs/unit_001_v3_define_flow_logical_design.md（Step 4 ゲート先行 fail-fast / work-item-validate.sh 追加）

## ビルド結果
成功（シェルスクリプトのため静的検査で代替）

```text
shellcheck: state-init.sh / work-item-validate.sh / test-define-flow.sh すべてクリーン（重大警告なし）
bash -n: 構文エラーなし
```

## テスト結果
成功

- 実行テスト数: 143（test-define-flow.sh 75 + test-state-scripts.sh 68）
- 成功: 143
- 失敗: 0

```text
test-define-flow.sh: PASS 75 / FAIL 0
test-state-scripts.sh（回帰）: PASS 68 / FAIL 0
markdownlint（define.md / 設計 2 件 / review-summary）: 0 error
```

## コードレビュー結果
- [x] セキュリティ: OK（state.json は atomic 操作のみ / create-only ガードで誤上書き防止 / 読み取り専用検証）
- [x] コーディング規約: OK（既存 state-*.sh と一致 / `set -euo pipefail` / 終了コード 0/1/2 / result-out local namespace 規約準拠）
- [x] エラーハンドリング: OK（外部コマンド失敗を exit 2 に正規化 / 検証失敗を exit 1）
- [x] テストカバレッジ: OK（終了コード規約・境界・malformed YAML クラス・e2e fail-fast を網羅）
- [x] ドキュメント: OK（define.md 実行手順化 / 設計-実装整合 / review-summary Set 1-3）

## 技術的な決定事項
- **初期 state.json は state-init.sh を新設**（state-write.sh は更新専用契約のため）。確定操作は create-only の `ln`（state-write の atomic-replace `mv` と分岐）で TOCTOU を排除。
- **work item 検証ゲートを実体スクリプト work-item-validate.sh に隔離**（統合レビュー R1 #2）。`state-validate.sh` が state.json を検証するのと対称。define.md にプロース手順を埋めず再利用可能な安全境界スクリプトとした。
- **Step 4 はゲート先行 fail-fast**: 検証ゲートを state-init より前に置き、不正 work item では state.json も branch も生成しない。集約不変条件「define_completed=true 時に全 work item §4 準拠」を担保。
- **malformed YAML 耐性はクラス単位で統一**（統合レビュー R3/R4/R5 千日手 → R5 でクラス一括修正）。`read_scalar` ヘルパで status/size/risk/id/dependencies のスカラー抽出を「引用符なし or 両端引用符付き」に統一し、片側引用符・不正区切りを exit 1。
- **ドッグフーディング特殊処理を本体に埋めない**: define.md は consumer 通常フロー（cycle ブランチ新規作成）を正本とし、既存ブランチ skip は汎用分岐で表現。

## 課題・改善点
- 引用符バランス以外の malformed YAML クラス（タブインデント / 重複キー / ブロックスカラー `|` `>` / フロースタイル等）への耐性は本サイクルでは追わない（統合レビュー R6 で別クラス指摘なし / 千日手ユーザー判断で確認 R6 完了 → backlog defer 不要と確定）。work item は固定テンプレートから AI 生成されるため現実的脅威が低い。将来必要なら YAML パーサ導入を含めて別 Unit で検討。
- schema_version の値互換性検証は Unit 004（#731）スコープ（統合レビュー R1 #1 スコープ記録）。

## 状態
**完了**

## 備考
- 統合レビュー（codex）R1〜R6: 計 8 件修正 + #1 スコープ記録、R6 指摘0件 clean。千日手判断（R3/R4/R5 同一クラス 3 連続）はクラス一括修正 + ユーザー判断（確認 R6 実行）で解消。詳細は `construction/units/001-review-summary.md` Set 3。
- v2 非影響: 変更は `skills/aidlc-v3/` と当該 cycle dir に限定（`skills/aidlc/` 非影響）。
