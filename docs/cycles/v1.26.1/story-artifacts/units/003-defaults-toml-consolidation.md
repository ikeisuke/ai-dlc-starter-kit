# Unit: defaults.tomlデフォルト値集約

## 概要
プリフライトチェックで使用される設定キーのうち、defaults.tomlに未登録の5キーを追加し、デフォルト値の定義箇所を一元化する。

## 含まれるユーザーストーリー
- ストーリー 4: defaults.tomlへのデフォルト値集約

## 関連Issue
- #376

## 責務
- defaults.tomlに以下の5キーとデフォルト値を追加:
  - rules.depth_level.level = "standard"
  - rules.automation.mode = "manual"
  - rules.construction.max_retry = 3
  - rules.preflight.enabled = true
  - rules.preflight.checks = ["gh", "review-tools", "config-validation"]
- 追加後の動作確認（read-config.shで正しく取得できること）

## 境界
- read-config.sh自体の変更は含まない
- --defaultオプションの廃止は含まない（Unit 4で実施）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- dasel（TOML解析）

## 非機能要件（NFR）
- 該当なし

## 技術的考慮事項
- 編集対象は `prompts/package/config/defaults.toml`
- 既存の設定構造（セクション分割、コメント形式）に合わせる
- config-schema.tomlとの整合性も確認

## 実装優先度
High

## 見積もり
極小（5キーの追加のみ）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-21
- **完了日**: 2026-03-21
- **担当**: -
