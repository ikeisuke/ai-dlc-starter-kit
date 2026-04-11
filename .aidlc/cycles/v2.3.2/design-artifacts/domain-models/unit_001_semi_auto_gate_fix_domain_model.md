# ドメインモデル: semi_autoゲート承認修正

## 概要

全フェ���ズのステップファイルにおけるゲート承認ポイントの分類と、��セミオートゲート判定」参��の明示化パターンを定義する。

## エンティティ

### InteractionPoint（���話ポイント）

ステップファイル内でユーザーとの対話が発生する箇所。

- **属性**:
  - phase: Phase - 所属フェーズ（Inception/Construction/Operations）
  - step_file: String - ステップファイルパス
  - location: String - ファイル内の位置（ステップ番号等）
  - interaction_type: InteractionType - 対話種別
  - current_reference: String | null - 現在のセミオートゲート判定への参照記述
- **振る舞い**:
  - needsReference(): Boolean - セミオートゲート判定への参照が必要か判定
  - hasValidReference(): Boolean - 有効な��照が存在するか判定

## 値オブジェクト

### InteractionType

SKILL.mdの「AskUserQuestion使用ルール」テーブルで定義された3分類。

| 値 | 説明 | semi_auto時の扱い |
|----|------|------------------|
| `gate_approval` | ゲート承認 | セミオートゲート仕��に従う（auto_approved / fallback） |
| `user_selection` | ユーザー選択 | 常にAskUserQuestion（自動化対象外） |
| `information_gathering` | 情報収集 | 常にAskUserQuestion（自動化対象外） |

### GateReference（ゲート参照パターン）

ステップファイル内に記述するセミオートゲート判定への参照。

- **正規パターン**: `**セミオートゲート判定**: steps/{phase}/index.md の「2.x automation_mode 分岐」に従う（詳細: common/rules-automation.md）。`

## 集約

### PhaseGateMap（フェーズ別ゲートマップ）

各フェーズのindex.mdで定義されたゲート発生箇所と、ステップファイル内の実装箇所の対応関係。

- **集約ルート**: PhaseGateMap
- **不変条件**: index.mdのゲート発生箇所が、ステップファイル内のGateReference記述で網羅されている（1:N対応可。Operations ステップ2〜6のように、indexの1行が複数ステップに展開される場合がある）

## 全InteractionPointの分類結果

### Inception Phase

| ステップファイル | 位置 | 分類 | 現状 |
|----------------|------|------|------|
| 03-intent.md | ステップ1完了（Intent承認） | gate_approval | ✓ 参照あり |
| 04-stories-units.md | ステップ3完了（ストーリー承認） | gate_approval | ✓ 参照あり |
| 04-stories-units.md | ステップ4完了（Unit定義承認） | gate_approval | ✓ 参照あり |

### Construction Phase

| ステップファイル | 位置 | 分類 | 現状 |
|----------------|------|------|------|
| 01-setup.md | ステップ10完了（計画承認） | gate_approval | ❌ 略記（`**セミオート**: ...`） |
| 02-design.md | ステップ3完了（設計承認） | gate_approval | △ 直接参照形式（`rules-automation.md` のみ参照） |
| 03-implementation.md | ステップ4完了（コードレビュー承認） | gate_approval | ❌ 明示参照なし（AI レビュー実施のみ記載） |
| 03-implementation.md | ステップ6 項目6（統合レビュー承認） | gate_approval | △ 直接参照形式（`rules-automation.md` のみ参照） |
| 04-completion.md | ステップ1（完了条件の���認/実装承認） | gate_approval | ❌ 略記（`semi_auto なら自動承認`） |
| 03-implementation.md | ステップ6 項目3c（Self-Healingフォールバック） | user_selection | ✓ 修正対象外 |

### Operations Phase

| ステップファイル | 位置 | 分類 | 現状 |
|----------------|------|------|------|
| 02-deploy.md | ステップ1（変更確認の選択） | gate_approval | ❌ index参照あるが標準パターンなし |
| 02-deploy.md | ステップ2 開始時（デプロイ準備） | gate_approval | ❌ 明示参照なし |
| 02-deploy.md | ステップ3 開始時（CI/CD構築） | gate_approval | ❌ 明示参照なし |
| 02-deploy.md | ステップ4 開始時（監視・ロギング戦略） | gate_approval | ❌ 明示参照なし |
| 02-deploy.md | ステップ5 開始時（配布） | gate_approval | ❌ 明示参照なし |
| 02-deploy.md | ステップ6 開始時（バックログ整理と運用計画） | gate_approval | ❌ 明示参照なし |
| 02-deploy.md | ステップ7 開始時（リリース準備計画承認） | gate_approval | ❌ index参照あるが標準パターンなし |
| operations-release.md | 7.8（PR Ready化承認） | gate_approval | ❌ 明示参照なし |
| operations-release.md | 7.13（PRマージ） | user_selection | ✓ 修正対象外（明示的にユーザー選択と記述済み） |

## ユビキタス言語

- **ゲート承認**: フェーズ/ステップの進行承認。semi_autoで自動化対象
- **ユーザー選択**: ゲート承認に該当しない選択場面。常にAskUserQuestion必須
- **情報収集**: ユーザーからの自由入力が必要な場面。常にAskUserQuestion必須
- **セミオートゲート判定**: automation_mode=semi_autoでの���ォールバック評価→auto_approved/fallback判定
- **フォールバック条件**: semi_auto時にauto_approvedにならない条件（review_not_executed, error, review_issues等）

## 不明点と質問

なし（Issue詳細・既存コード分析で要件は明確化済み）
