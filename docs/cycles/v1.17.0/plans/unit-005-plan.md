# Unit 005 計画: PR本文へのレビュー情報記載

## 概要

Unit PR・サイクルPRの本文テンプレートを更新し、要件・受け入れ基準・レビューサマリを記載する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/construction.md` | Unit PR作成テンプレート更新（ドラフトPR・Ready化・新規PR） |
| `prompts/package/prompts/operations.md` | サイクルPR作成テンプレート更新（ドラフトPR Ready化・新規PR） |

**注**: メタ開発ルールに従い、`docs/aidlc/` ではなく `prompts/package/` を編集する。

**確認のみ（変更不要）**:
- `prompts/package/prompts/inception.md`: 既にClosesセクションが存在することを確認済み。レビューサマリセクションは追加しない（Inception時点ではサマリ対象が不完全なため）。

## 実装計画

### Phase 1: 設計

#### 1. ドメインモデル設計

PRテンプレートの構造変更を定義:

- **construction.md のUnit PR**:

  | テンプレート箇所 | 追加セクション |
  |-----------------|--------------|
  | Unitブランチ作成（初期セットアップ内）のドラフトPR | 要件、受け入れ基準 |
  | Unit完了時のPR Ready化（ステップ5-2） | 要件、受け入れ基準、レビューサマリ |
  | Unit完了時の新規PR作成（ステップ5-3） | 要件、受け入れ基準、レビューサマリ |

  - ドラフトPRにはレビューサマリを含めない（作成時点ではレビュー未実施のため）
  - Ready化/新規PRのレビューサマリ: AIが `docs/cycles/{{CYCLE}}/construction/units/{NNN}-review-summary.md` を読み込んで直接PR本文に記載
  - サマリファイルが存在しない場合: レビューサマリセクションを省略する指示を記載

- **operations.md のサイクルPR**:

  | テンプレート箇所 | 追加セクション |
  |-----------------|--------------|
  | ドラフトPR Ready化（ステップ6.6） | Intent概要、受け入れ基準、全体修正概要、レビューサマリ |
  | 新規PR作成（ステップ6.6内 PRなし時） | Intent概要、受け入れ基準、全体修正概要、レビューサマリ |

  - レビューサマリの参照契約:
    - Construction Phase サマリ: `docs/cycles/{{CYCLE}}/construction/units/` 配下の `*-review-summary.md` を列挙し、各ファイルへのリンクを記載
    - Inception Phase サマリ: `docs/cycles/{{CYCLE}}/inception/` 配下の `*-review-summary.md` を列挙し、各ファイルへのリンクを記載
    - いずれも存在しない場合: レビューサマリセクション全体を省略

#### 2. 論理設計

各テンプレートの具体的なセクション構成とプレースホルダを設計。

### Phase 2: 実装

#### 3. construction.md 更新

- Unitブランチ作成内のドラフトPRテンプレート（bodyセクション）更新
- Unit完了時のPR Ready化テンプレート（ステップ5-2）更新
- Unit完了時の新規PR作成テンプレート（ステップ5-3）更新
- レビューサマリの存在チェックロジック記載

#### 4. operations.md 更新

- ステップ6.6（ドラフトPR Ready化）のbodyテンプレート更新
- 新規PR作成テンプレート更新
- レビューサマリリンクの集約・列挙ロジック記載

## 完了条件チェックリスト

- [x] construction.md のドラフトPRテンプレートに要件・受け入れ基準が追加されている
- [x] construction.md のReady化/新規PRテンプレートに要件・受け入れ基準・レビューサマリが追加されている
- [x] operations.md のサイクルPR作成テンプレートにIntent概要・受け入れ基準・全体修正概要・レビューサマリリンクが追加されている
- [x] レビューサマリファイルが存在しない場合のサマリセクション省略ロジックが記載されている（construction.md・operations.md両方）
- [x] inception.md のドラフトPRテンプレートにClosesセクションがあることを確認済み（変更なし）
