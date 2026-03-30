# 実装記録: Unit 7 プロンプト参照ガイド

## 概要
既存のフェーズプロンプトを活用する方法を明確にし、独自プロンプト作成を防ぐ仕組みを確立。

## 実施日
2025-11-28

## ステータス
完了

---

## 実施内容

### Phase 1: 設計

#### 統合設計
- **成果物**: `docs/cycles/v1.0.1/design-artifacts/unit7_prompt_guide_design.md`
- **内容**:
  - プロンプト参照ガイドの構成設計
  - 注意書きの仕様定義
  - 更新対象ファイル一覧

### Phase 2: 実装

#### セットアップテンプレート更新（メタ開発）

1. **prompts/setup/common.md**
   - ディレクトリ構成に `prompt-reference-guide.md` を追加
   - `prompt-reference-guide.md` 生成テンプレートを追加
   - セットアップ完了メッセージに追加

2. **prompts/setup/inception.md**
   - テンプレート内に注意書きを追加

3. **prompts/setup/construction.md**
   - テンプレート内に注意書きを追加

4. **prompts/setup/operations.md**
   - テンプレート内に注意書きを追加

---

## 成果物一覧

| 種類 | ファイルパス | 操作 |
|------|-------------|------|
| 計画 | `docs/cycles/v1.0.1/plans/unit7_prompt_reference_guide_plan.md` | 新規作成 |
| 設計 | `docs/cycles/v1.0.1/design-artifacts/unit7_prompt_guide_design.md` | 新規作成 |
| テンプレート | `prompts/setup/common.md` | 更新 |
| テンプレート | `prompts/setup/inception.md` | 更新 |
| テンプレート | `prompts/setup/construction.md` | 更新 |
| テンプレート | `prompts/setup/operations.md` | 更新 |

---

## 計画からの変更点

- **変更**: `docs/aidlc/prompt-reference-guide.md` を直接作成 → セットアップテンプレートに追加
- **理由**: メタ開発のため、現在使用中のプロンプトではなくセットアップテンプレートを更新すべき

---

## 備考

- 次回セットアップ時に生成されるプロンプトに注意書きが反映される
- 自動検証ツールは Could-have のため未実装
