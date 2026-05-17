# Unit: Construction Phase 1 設計起草前の事前コード Read 工程組み込み

## 概要

Construction Phase 1（設計フェーズ）の設計起草前に変更対象機能の既存実装コードを事前 Read する工程をテンプレ・ステップ・レビュー観点に必須化し、「既存実装の挙動を読まずに設計起草」を主因とする Round 1 設計レビュー反復を構造的に予防する。

## 含まれるユーザーストーリー

- ストーリー 2: Construction Phase 1 で設計起草前に既存実装を Read する工程を必須化する

## 責務

- `skills/aidlc/steps/construction/02-design.md` のドメインモデル設計ステップ冒頭に「## 事前コード読込み」サブステップ + 3 観点（(a) Read 対象ファイル + 目的 / (b) 設計時に意識すべき挙動 / (c) 既存実装に基づく代替案検討）を追加（Intent §含まれるもの に基づくスコープ調整: 元責務の `templates/construction_plan_template.md` は v2.6.5 時点で非存在のため、`steps/construction/02-design.md` への直接記述に切り替え。Intent の「`steps/construction` 配下: design 起草前の事前コード Read 必須化」と整合）
- `skills/aidlc/steps/construction/` の設計起草フローステップに「事前コード Read → 設計起草」の二段階分離を明示
- `skills/reviewing-construction-design/SKILL.md` の `architecture` focus 観点に「事前コード読込みセクション存在 / 内容充足」チェックを追加
- 判定条件（見出し不在 or サブセクション空）と失敗時アクション（設計レビュー不合格 / 修正されるまで反復）を SoT 化
- 本 Unit 自身の Construction Phase で改修内容をドッグフーディング検証（U2 自身の plan に事前コード Read セクションが書かれている状態の確認）

## 境界

- `#633`（責務領域全体を広視野で検討するプロンプト指示）/ `#692`（副作用境界 / ドメイン層分離評価軸追加）は対象外（intent §含まれないもの 参照）
- 既存 `templates/construction_plan_template.md` を破壊的変更しない（セクション追加方式）
- `reviewing-construction-code` / `reviewing-construction-integration` への観点追加は対象外

## 依存関係

### 依存する Unit

- なし

### 外部依存

- なし（メタ開発内テンプレ・スキル本体のみ）

## 非機能要件（NFR）

- **パフォーマンス**: テンプレ追加のみで実行コスト変化なし。レビュー観点 1 行追加分の自然言語処理コストのみ
- **セキュリティ**: 影響なし
- **スケーラビリティ**: 対応スキル横断（reviewing-* 系）で同様パターンを将来追加可
- **可用性**: 既存設計レビュー失敗時のフォールバック動作と互換

## 技術的考慮事項

- 「## 事前コード読込み」セクションは plan テンプレ末尾近くではなく冒頭または独立セクションとして配置（設計起草前の作業を視覚的に明確化）
- `reviewing-construction-design` の判定はキーワード / 構造マッチング（Markdown 見出し検出）で軽量化
- 既存「設計レビュー時のガイド照合ルール」（.aidlc/rules.md）との重複なし（ガイド照合は別観点）

## 関連Issue

- #679（このサイクルで Closes）

## 実装優先度

High

## 見積もり

0.5〜1 日（テンプレ追加 + ステップ追記 + レビュー観点追加 + ドッグフーディング）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-17
- **完了日**: 2026-05-17
- **担当**: AI (Claude Code)
- **エクスプレス適格性**: -
- **適格性理由**: -
