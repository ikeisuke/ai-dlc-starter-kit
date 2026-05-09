# Unit: Inception Issue 選択フローで複数選択を前提化（D）

## 概要

`steps/inception/02-preparation.md` §16「GitHub Issue 確認」の文言を改善し、AI エージェントが複数 Issue を 1 サイクルに含める提案を自然に行うようにする。現状の「選択した Issue を…」テキストは AI に単一選択を誘導するバイアスを生んでおり、Issue を多数取り込みたいケースで毎回手動誘導が必要になっている。

## 含まれるユーザーストーリー

- ストーリー 4: Inception の Issue 選択で複数選択を前提としたい（D）

## 責務

- **前提**: Inception Phase 完了条件として本 Unit 対応 Issue が事前に起票・採番済みであること（Issue 起票そのものは Inception 05-completion ステップで実施し、本 Unit の責務には含めない）
- 上記で採番済みの Issue 番号を参照しつつ、`steps/inception/02-preparation.md` §16「GitHub Issue確認」内に以下を**両方**追加:
  - 「複数選択可」を明示する文言（例: 「対応する Issue を**複数選択可で**選択させ」）
  - AskUserQuestion 呼び出し例または推奨パターン（`multiSelect: true` の利用例を含む 1 ブロック以上）
- `関連Issue` セクションに採番済み Issue 番号を反映（Construction 開始時の Unit 編集権限の範囲内）

## 境界

- 他の AskUserQuestion 呼び出し全般（Inception 03-intent / Operations / Construction 等）への文言改善は対象外（Intent 明示除外）
- AskUserQuestion API 自体の設計見直しは対象外
- `scripts/check-open-issues.sh` の出力フォーマット変更は不要（表示テキストのみ調整）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- 新規 GitHub Issue が **Inception Phase 05-completion ステップで起票・採番済み**（本 Unit 開始時点で番号が確定していること）

## 非機能要件（NFR）

- **可用性**: 既存の Inception 02-preparation §16 動作を維持（破壊的変更なし、文言追加のみ）
- **保守性**: 修正は §16 周辺の局所修正にとどめ、修正範囲を最小化

## 技術的考慮事項

- 単純な Markdown 文言修正、影響範囲は §16 のみ
- AI エージェントの解釈バイアスを完全に排除することは不可能（LLM 特性）。文言の明示化と推奨例の掲載でバイアスを軽減することが目的
- 観測可能性: 補助基準として後続サイクルの振り返り材料で実効性を観測（本サイクル DoD 外）

## 関連Issue

- #674

## 実装優先度

High（Must、Intent D）

## 見積もり

小。0.1 日（Markdown 文言修正のみ。Issue 起票は Inception 05-completion 側で別途実施）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
