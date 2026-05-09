# ドメインモデル: aidlc-setup の starter_kit_version-only 差分 no-op スキップ

## 概要

`aidlc-setup` のアップグレードコンテキストにおける「適用変更の検出」と「starter_kit_version 値更新の条件分岐」を扱う。本モデルは構造と責務のみを定義する。

## 境界（Bounded Context）

`Upgrade No-Op Detection Context`:

- 適用前後の `.aidlc/config.toml` の状態変化を検出する
- 変化の種別を「starter_kit_version の値更新のみ / それ以外」に分類する
- starter_kit_version 値更新の実行可否を `should_update_starter_kit_version` フラグとして返す

**Unit 境界外**:

- `setup-ai-tools.sh` (`.claude/settings.json`) の更新判定（独立責務）
- `migrate-backlog.sh` (`.aidlc/cycles/`) の判定
- `aidlc-migrate` の v1→v2 マイグレーション判定

## エンティティ

### UpgradeRun

- **ID**: 暗黙（セッション単位）
- **属性**:
  - `migrate_config_result`: MigrateConfigResult - migrate-config.sh の構造化出力
  - `detect_missing_applied`: boolean - detect-missing-keys.sh + 対話結果で実際にキーが追加されたか
- **振る舞い**:
  - `isNoOp()`: 上記 2 値から `noop=true|false` を導出
  - `decideStarterKitVersionUpdate()`: `noop=true` → `should_update_starter_kit_version=false` / `noop=false` → `true`

## 値オブジェクト

### MigrateConfigResult

- **属性**:
  - `migrated`: integer - 実際に migrate された数
  - `skipped`: integer - skip された数
  - `warnings`: integer - 警告数
- **不変性**: スクリプト 1 回実行ごとに固定
- **等価性**: 3 値全一致

### NoOpDecision（指摘 #2 反映 / 成功時のみ表現）

- **属性**:
  - `noop`: boolean
  - `reason`: enum {`no-changes`, `migrate-config-changed`, `missing-keys-applied`}
- **不変性**: 判定後は変更不可

> **注**: `invalid-input` は Domain 層の値オブジェクトには含めない。Application 層が入力解析エラーを検知した時点で判定をスキップし、`error_code` を別フィールドとして上位に伝播する（論理設計の出力契約参照）。これにより Domain と Error Handling の責務を分離する。

## 集約

### UpgradeNoOpDecision

- **集約ルート**: UpgradeRun
- **含まれる要素**: MigrateConfigResult, NoOpDecision
- **境界**: アップグレードランの 1 サイクル
- **不変条件**:
  - `noop=true` ⟺ `migrate_config_result.migrated == 0 && migrate_config_result.warnings == 0 && detect_missing_applied == false`
  - `reason=no-changes` ⟺ `noop=true`
  - `noop=false` の場合 `reason ∈ {migrate-config-changed, missing-keys-applied}`
  - 入力解析失敗（invalid-input）は Application 層のエラーパスで処理され、`NoOpDecision` 値オブジェクトは生成されない（指摘 #2 反映）

## ドメインサービス

### NoOpPolicy（指摘 #1 反映 / Domain 層に限定）

- **責務**: noop 判定の純粋なビジネスルール（手順制御は持たない）
- **操作**:
  - `decide(migrated: int, warnings: int, missing_applied: bool) -> NoOpDecision`
- **不変条件**: 同一入力に対して同一出力を返す純関数

> **注**: 手順制御（ステップ順序）と既存スクリプト出力のパース処理は Application 層に分離する（後述「アプリケーション層責務（参考）」）。Domain 層には判定規則のみを置く。

## アプリケーション層責務（参考 / Domain 層外 / 指摘 #1 反映）

論理設計（`unit_004_aidlc_setup_no_op_skip_logical_design.md`）で詳述する以下の責務はインフラ / アプリケーション層に属し、本ドメインモデルの直接の構成要素ではない。

- **UpgradeFlowController（Application Service）**: `02-generate-config.md` のステップ順序制御（7.4 → 7.4b → 7.4c → 7.3 条件実行）
- **MigrateConfigResultParser（Infrastructure / 解析）**: `migrate-config.sh` の `result:` 行を MigrateConfigResult 値オブジェクトに変換するパーサー
- **DetectMissingKeysAggregator（Infrastructure / 集約）**: `detect-missing-keys.sh` の対話結果を `missing_applied: bool` に集約するロジック

これらは `NoOpPolicy.decide()` を呼び出すクライアントであり、Domain 層の判定規則には立ち入らない。

## ファクトリ

なし（既存スクリプト + シェル関数で十分）

## ユビキタス言語

- **No-Op アップグレード**: アップグレード走行で `.aidlc/config.toml` に `starter_kit_version` 以外の差分が発生しないケース
- **適用変更（Applied Change）**: migrate-config.sh によるセクション追加 / detect-missing-keys.sh + 対話追加で発生する config.toml への変更
- **should_update_starter_kit_version**: 7.3 の実行可否を表す boolean フラグ
- **判定の正本（Single Source of Truth）**: noop 判定は migrate-config.sh の `result:` 行と detect-missing-keys.sh + 対話結果の 2 入力に集約

## 不明点と質問

[Question] `migrate-config.sh` の `warnings>0` を no-op に含めるか除外するか。
[Answer] 除外する（noop=false 扱い）。warnings は「ユーザー対応が必要」を意味し、実質的な変更がなくても starter_kit_version を更新して整合性を確保すべき。本 Unit の noop 判定では `migrated==0 AND warnings==0` の AND 条件を採用する。

[Question] `detect-missing-keys.sh` のユーザー応答（追加 / スキップ）をどのように呼び出し側で集約するか。
[Answer] `02-generate-config.md` のステップ 7.4b 完了時点で、AI agent が「追加が実際に行われたか」を boolean 変数 `detect_missing_applied` (0|1) として保持する。`AskUserQuestion` で「追加する」を選択 + 実際にキーが追加された場合のみ 1。「スキップ」「欠落キー 0 件」の場合は 0。

[Question] フォールバック発生時（exit 2 = `invalid-input`）の挙動を確認。
[Answer] 通常フロー（既存挙動）に倒す。`should_update_starter_kit_version=true` として 7.3 を実行。警告を表示してユーザーに状況を伝える。
