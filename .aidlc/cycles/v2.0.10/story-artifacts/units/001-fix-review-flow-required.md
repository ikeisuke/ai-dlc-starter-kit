# Unit: review-flow.md required時バグ修正

## 概要
review-flow.md の required モード時に CLI失敗でセルフレビューへ自動フォールバックする問題を修正する。

## 含まれるユーザーストーリー
- ストーリー 2: review-flow.mdのrequired時バグ修正 (#468)

## 責務
- review-flow.md のCLI失敗時分岐を review_mode 別に変更
- required 時: ユーザー通知 + 3択提示（リトライ/セルフレビュー/中断）
- recommend 時: 現行通り自動フォールバック

## 境界
- review-flow.md 以外のステップファイルは変更しない
- review_mode=disabled の挙動は変更しない
- reviewing-* スキル自体は変更しない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- なし（プロンプトファイルの修正のみ）

## 技術的考慮事項
- 変更対象: `skills/aidlc/steps/common/review-flow.md` のステップ5
- セミオートゲート仕様との整合性を確認する

## 関連Issue
- #468

## 実装優先度
High

## 見積もり
小規模（1ファイルのプロンプト修正）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-30
- **完了日**: 2026-03-30
- **担当**: @ai
- **エクスプレス適格性**: -
- **適格性理由**: -
