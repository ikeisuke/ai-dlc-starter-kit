# 実装記録: Unit 001 v3 state スクリプト基盤

## 実装日時

2026-06-11（Construction Phase / Unit 001）

## 作成ファイル

### ソースコード

- `skills/aidlc-v3/scripts/state-validate.sh` - state.json schema 検証（検証 SoT）。必須フィールド・型・release サブフィールド存在/型・updated_at の ISO 8601 形式を検証。0=有効 / 1=無効 / 2=システムエラー
- `skills/aidlc-v3/scripts/state-read.sh` - state.json から指定フィールドを抽出（read-only）。has() で欠落と明示 null を区別
- `skills/aidlc-v3/scripts/state-write.sh` - 許可フィールドのみを atomic（temp file + validate + mv）に更新。updated_at を自動更新。依存 state-validate.sh の起動失敗を exit 2 に正規化

### テスト

- `skills/aidlc-v3/scripts/tests/test-state-scripts.sh` - 自己完結型テストハーネス（68 ケース）。正常系・異常系・終了コード 0/1/2・atomic 性・静的検査（bash -n / shellcheck）を網羅

### 設計ドキュメント

- `.aidlc/cycles/v3.0.0-alpha.2/design-artifacts/domain-models/unit_001_v3_state_scripts_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.2/design-artifacts/logical-designs/unit_001_v3_state_scripts_logical_design.md`

## ビルド結果

成功（シェルスクリプトのためビルドは構文・静的検査で代替）

```text
bash -n: state-validate.sh / state-read.sh / state-write.sh / test-state-scripts.sh いずれも通過
shellcheck: 全 4 ファイル 重大警告なし
```

## テスト結果

成功

- 実行テスト数: 68
- 成功: 68
- 失敗: 0

```text
== 静的検査（bash -n / shellcheck） ==  4 件 ok
== state-validate.sh ==                27 件 ok（必須欠落・型不正・release サブフィールド・ISO8601・JSON不正・exit2）
== state-read.sh ==                    14 件 ok（全 7 フィールド抽出・欠落/null 区別・exit2）
== state-write.sh ==                   23 件 ok（許可フィールド書込・updated_at 自動更新・許可外/型不正拒否・atomic・依存不備 exit2）
PASS: 68  FAIL: 0
```

## コードレビュー結果

- [x] セキュリティ: OK（ユーザー入力値は jq --arg/--argjson 経由で渡し、文字列結合・eval なし。全変数クォート）
- [x] コーディング規約: OK（終了コード規約 0/1/2 準拠、stderr/stdout 分離、set -euo pipefail）
- [x] エラーハンドリング: OK（jq 不在/読み取り不可/依存不備=exit2、バリデーション失敗=exit1、atomic 失敗時 trap cleanup）
- [x] テストカバレッジ: OK（68 ケース。3 値終了コード・atomic・静的検査を網羅）
- [x] ドキュメント: OK（各スクリプトヘッダに usage/終了コード/検証契約を記載）

## 技術的な決定事項

- **JSON 処理**: jq を唯一の JSON ツールとする（Unit 制約）。「JSON 妥当性 = jq が受理する入力」を検証契約として明文化（strict RFC 8259 parser の追加依存は不採用）
- **atomic write**: temp file を対象と同一ディレクトリに作成 → state-validate.sh で検証 → mv で置換。検証失敗時は temp 破棄・元ファイル保持。trap で temp 後始末
- **整数判定**: jq の `%` 演算子はオペランドを整数に切り捨てるため `1.5 % 1 == 0` となる罠を回避し、`floor` 一致比較で整数を判定（実装中スモークテストで検出・修正）
- **pr_number 入力厳格化**: 先頭ゼロ（001/-01）は jq が黙って 1 にコアースするため、`^(0|-?[1-9][0-9]*)$` で入力段階で拒否
- **updated_at**: write 時に現在 UTC へ自動更新。テスト再現性のため環境変数 `AIDLC_STATE_NOW` で上書き可能
- **作成/更新境界**: write は既存 state の更新専用。初期 state 生成は Phase 3（define フロー）へ defer

## 課題・改善点

- 初期 state.json 生成（define Step 4 相当）・状態遷移ルールの具体化は Phase 3（flow 実装）へ defer（intent スコープに整合）
- ISO 8601 検証は形式 + 基本範囲まで（実在日・うるう年判定はスコープ外）

## 状態

**完了**

## 備考

- v2 非影響を全コミットで確認（`skills/aidlc/` 配下の変更なし）。成果物は `skills/aidlc-v3/` および `.aidlc/cycles/` 配下に限定
