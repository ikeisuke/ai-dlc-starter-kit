# Unit 7: プロンプト参照ガイド - 実行計画

## 概要
既存のフェーズプロンプトを活用する方法を明確にし、独自プロンプト作成を防ぐ仕組みを確立する。

**特徴**: このUnitは主にドキュメント作成がメインであり、コード実装は含まない。

---

## 対象ストーリー
- ストーリー 6.1: プロンプト参照ガイドの作成
- ストーリー 6.2: 独自プロンプト防止の仕組み

---

## Phase 1: 設計【簡略化】

このUnitはドキュメント作成がメインのため、ドメインモデル設計と論理設計を1つの設計ドキュメントに統合する。

### ステップ1-2: 統合設計
**目的**: プロンプト参照ガイドの構成と注意書きの仕様を定義

**成果物**: `docs/cycles/v1.0.1/design-artifacts/unit7_prompt_guide_design.md`

**内容**:
- プロンプト参照ガイドの構成
- 注意書きの文面
- 更新対象ファイル一覧

### ステップ3: 設計レビュー
ユーザーに設計内容を提示し、承認を得る

---

## Phase 2: 実装【ドキュメント作成】

### ステップ4: プロンプト参照ガイド作成
**成果物**: `docs/aidlc/prompt-reference-guide.md`

**内容**:
1. 概要（AI-DLCのフェーズ構成）
2. 各フェーズプロンプトの使い方
3. フェーズ間の移行方法（コマンド例）
4. よくある間違いと対策
5. プロンプトのカスタマイズ方法
6. 実行例（コピー＆ペースト可能）

### ステップ5: フェーズプロンプト更新
**対象ファイル**:
- `docs/aidlc/prompts/inception.md`
- `docs/aidlc/prompts/construction.md`
- `docs/aidlc/prompts/operations.md`

**追加内容**: 冒頭に注意書きを追加

### ステップ6: 統合とレビュー
- 成果物の整合性確認
- `docs/cycles/v1.0.1/construction/units/unit7_implementation.md` に実装記録を作成

---

## 成果物一覧

| フェーズ | 成果物 | パス |
|---------|--------|------|
| 設計 | 統合設計 | `docs/cycles/v1.0.1/design-artifacts/unit7_prompt_guide_design.md` |
| 実装 | プロンプト参照ガイド | `docs/aidlc/prompt-reference-guide.md` |
| 実装 | フェーズプロンプト更新 | `docs/aidlc/prompts/*.md` |
| 実装 | 実装記録 | `docs/cycles/v1.0.1/construction/units/unit7_implementation.md` |

---

## 完了基準

- [ ] 統合設計完了
- [ ] 設計レビュー承認
- [ ] プロンプト参照ガイド作成
- [ ] フェーズプロンプトに注意書き追加
- [ ] 実装記録作成
- [ ] progress.md更新
- [ ] 履歴記録
- [ ] Gitコミット

---

## 作成日時
2025-11-28
