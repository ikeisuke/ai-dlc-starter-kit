# Unit: 振り返り対話強制ガード強化（Operations §1）

## 概要

Operations Phase §1 振り返りステップで、AI エージェント（特に auto mode 動作中）が対話を経ずに振り返り Issue を起票してしまう運用ミスを構造的に防止する。`skills/aidlc/steps/operations/04-completion.md` §1 の改訂と `skills/aidlc/SKILL.md` の AskUserQuestion 使用ルール拡張を中心とした docs / steps レベルの改修。

## 含まれるユーザーストーリー

- ストーリー 1: Operations §1 振り返りでの auto mode 独断起票を防ぐ（#647）

## 責務

- `skills/aidlc/steps/operations/04-completion.md` §1 冒頭への「対話必須」明記の追加
- 同ファイル §1.0 `feedback_mode` テーブルへの「`silent` でも KPT 判断は対話必須」補足の追加
- 同ファイル §1 内の `gh issue create` / `gh api PATCH` 直前への AskUserQuestion 必須化記述の追加
- `skills/aidlc/SKILL.md` 「AskUserQuestion 使用ルール」テーブルへの「振り返り内容の決定」種別追加（auto mode 適用外であることを明示）
- 本リポ内ドライラン用 fixture（`construction/fixtures/operations-mirror-autodialog.md` 等）の作成
- 履歴記録 (`history/construction_unit01.md`) への対話必須ガード強化反映の追記

## 境界

- 振り返り Issue の本文構造改訂（KPT テンプレ自体の変更）は本 Unit のスコープ外
- `feedback_mode` の値追加（`mirror-strict` などの新値）は本 Unit のスコープ外
- jailrun 等外部リポジトリ側の追加対応は本 Unit のスコープ外（参考事例として記録のみ）
- §2 バックログ以降のセクションの改訂は本 Unit のスコープ外
- 推定値検出ガード（Unit 003 のスコープ）は重複しない

## 依存関係

### 依存する Unit

- なし（論理依存なし）
- ※ 同一ファイル `04-completion.md` §1 を改訂する Unit 003 とは **Unit 001 → Unit 003 の順** で実装することが安全（実装順依存 / コンフリクト回避）

### 外部依存

- `gh` CLI（fixture 検証時の擬似実行に必要 / 既存依存）
- なし（実装としての新規外部ライブラリ追加なし）

## 非機能要件（NFR）

- **パフォーマンス**: ドキュメント / 手順改訂のみのため、ランタイム性能影響なし
- **セキュリティ**: 機密情報の取り扱いに変更なし。既存の機密情報マスクポリシーを維持
- **スケーラビリティ**: 影響なし（手順記述のみ）
- **可用性**: 影響なし
- **後方互換**: 既存の振り返りフロー（`feedback_mode=silent` / `mirror` / `disabled`）の挙動を破壊しない

## 技術的考慮事項

- `skills/aidlc/steps/operations/04-completion.md` 651 行のうち §1 セクションの改訂のみで他セクション不変
- `skills/aidlc/SKILL.md` 251 行 / 500 行制限を守る（行追加のみで現実的な余裕あり）
- fixture は `.aidlc/cycles/v2.5.3/construction/fixtures/` 配下に置き、cycle-artifacts として cycle 完結
- 「対話必須」明記は §1 の冒頭ボックスとして強調表示（` > **重要**:` ブロック等）
- AskUserQuestion 使用ルールへの追加行は既存 3 種別表（ゲート承認 / ユーザー選択 / 情報収集）に「振り返り内容の決定」を新規行として追加（または「ユーザー選択」「情報収集」に統合する形を Construction Phase 設計で確定）

## 関連Issue

- #647（[Feedback] Operations §1 振り返り対話強制ガード強化と auto mode 動作明文化）
- 参考: jailrun #70 / PR #71（外部実証事例 / non-blocking）

## 実装優先度

High（jailrun で実害発生済 / Must-have）

## 見積もり

- 設計フェーズ: 0.5 日（domain model / logical design）
- 実装フェーズ: 1 日（docs 改訂 / fixture 作成 / レビュー）
- 合計: **1.5 日**

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
