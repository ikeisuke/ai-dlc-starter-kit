# Construction Phase - Unit2 実行計画

## Unit名
Unit2: 各フェーズプロンプトのパス参照更新

## 目的
inception.md、construction.md、operations.md のパス参照を新しいディレクトリ構造（`{{AIDLC_ROOT}}/templates/` と `{{VERSIONS_ROOT}}/{{VERSION}}/`）に対応させる

## 対象ファイル
- `docs/versions/v1.0.0/prompts/inception.md`
- `docs/versions/v1.0.0/prompts/construction.md`
- `docs/versions/v1.0.0/prompts/operations.md`

## 実行計画

### Phase 1: 設計（対話形式、コードは書かない）

#### ステップ1: ドメインモデル設計
- **責務**: パス参照更新のロジックを定義
- **構成要素**:
  - プロンプトファイルエンティティ（inception.md, construction.md, operations.md）
  - パス参照パターン（テンプレートパス、成果物ディレクトリパス）
  - 置換ルール（変数置換ロジック）
- **成果物**: `docs/versions/v1.0.0/design-artifacts/domain-models/unit2_domain_model.md`

#### ステップ2: 論理設計
- **責務**: パス置換の具体的な方法を定義
- **構成要素**:
  - 各プロンプトファイルで置換すべきパスのリスト
  - 置換前後のパス例
  - setup-prompt.md の変数定義との整合性確認
- **成果物**: `docs/versions/v1.0.0/design-artifacts/logical-designs/unit2_logical_design.md`

#### ステップ3: 設計レビュー
- 設計内容をユーザーに提示し、承認を得る

### Phase 2: 実装（設計を参照してコード生成）

#### ステップ4: コード生成（パス置換の実施）
- 設計ファイルを読み込み、各プロンプトファイル（inception.md, construction.md, operations.md）のパス参照を更新
- 具体的な置換対象:
  - テンプレート参照パス: `prompts/templates/` → `{{AIDLC_ROOT}}/templates/`
  - 成果物ディレクトリパス: 固定パス → `{{VERSIONS_ROOT}}/{{VERSION}}/` を使用したパス
  - セットアッププロンプトパスの記載確認

#### ステップ5: テスト生成
- パス参照が正しく置換されていることを確認するテストケースを作成
  - 各プロンプトファイルの変数参照が正しく記載されているか
  - setup-prompt.md の変数定義との整合性

#### ステップ6: 統合とレビュー
- 変更内容を確認
- 実装記録を作成: `docs/versions/v1.0.0/construction/units/unit2_implementation_record.md`

## 完了基準
- inception.md、construction.md、operations.md のパス参照がすべて新しいディレクトリ構造に対応
- setup-prompt.md の変数置換ロジックと整合性が取れている
- 実装記録に「完了」明記
- progress.md を更新してUnit2を「完了」に変更

## 想定される質問
- パス参照の置換範囲（どこまで置換するか）
- 後方互換性の考慮の必要性

## 次のUnit
Unit3: 新しいディレクトリ構造の作成 または Unit4: README.mdの更新（Unit3完了後）
