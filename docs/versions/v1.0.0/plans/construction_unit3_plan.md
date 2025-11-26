# Construction Phase 実行計画: Unit3 - 新しいディレクトリ構造の作成

## Unit概要
docs/aidlc/ と docs/versions/ ディレクトリを作成し、共通プロンプト・テンプレートとバージョン固有成果物を適切に配置する

## 実装範囲
- `docs/aidlc/prompts/` ディレクトリの作成と共通プロンプトの配置
- `docs/aidlc/templates/` ディレクトリの作成と共通テンプレートの配置
- `docs/aidlc/version.txt` の作成とバージョン記録
- `docs/versions/v1.0.0/` ディレクトリの作成とバージョン固有ディレクトリの配置

## 実行ステップ

### Phase 1: 設計（コードは書かない、対話形式）

#### ステップ1: ドメインモデル設計
- **目的**: ディレクトリ構造とファイル配置の責務をDDDに基づいて定義
- **成果物**: `docs/versions/v1.0.0/design-artifacts/domain-models/unit3_domain_model.md`
- **アプローチ**:
  - ディレクトリ構造全体を分析し、エンティティ・値オブジェクト・ドメインサービスを特定
  - 共通プロンプトとバージョン固有成果物の境界を明確化
  - ディレクトリ作成とファイル配置のドメイン知識を整理
- **対話**: 不明点は一問一答形式で確認

#### ステップ2: 論理設計
- **目的**: 具体的なディレクトリ構造、ファイル配置、スクリプト設計を記述
- **成果物**: `docs/versions/v1.0.0/design-artifacts/logical-designs/unit3_logical_design.md`
- **アプローチ**:
  - ディレクトリツリーの設計（docs/aidlc/ と docs/versions/ の構造）
  - ファイル配置のルール定義
  - .gitkeep ファイルの配置戦略
  - バージョン管理の方法
  - エラーハンドリング戦略
- **対話**: 不明点は一問一答形式で確認

#### ステップ3: 設計レビュー
- **目的**: ユーザーに設計内容を提示し、承認を得る
- **重要**: 承認なしで実装フェーズに進まない

### Phase 2: 実装（設計を参照してコード生成）

#### ステップ4: コード生成
- **目的**: 設計に基づいてディレクトリ作成スクリプトを実装
- **作業内容**:
  - `docs/aidlc/` ディレクトリ構造の作成
    - `docs/aidlc/prompts/` （共通プロンプト用）
    - `docs/aidlc/templates/` （共通テンプレート用）
  - `docs/versions/v1.0.0/` ディレクトリ構造の作成
    - `docs/versions/v1.0.0/prompts/` （バージョン固有プロンプト用）
    - `docs/versions/v1.0.0/templates/` （バージョン固有テンプレート用）
    - `docs/versions/v1.0.0/plans/` （実行計画用）
    - `docs/versions/v1.0.0/requirements/` （要件定義用）
    - `docs/versions/v1.0.0/story-artifacts/units/` （ユーザーストーリー用）
    - `docs/versions/v1.0.0/design-artifacts/domain-models/` （ドメインモデル用）
    - `docs/versions/v1.0.0/design-artifacts/logical-designs/` （論理設計用）
    - `docs/versions/v1.0.0/design-artifacts/architecture/` （アーキテクチャ用）
    - `docs/versions/v1.0.0/construction/units/` （構築記録用）
    - `docs/versions/v1.0.0/operations/` （運用関連用）
  - `docs/aidlc/version.txt` にバージョン情報（v1.0.0）を記録
  - 必要な場所に .gitkeep ファイルを配置
- **セキュリティ考慮**:
  - ディレクトリ権限の適切な設定
  - パスインジェクション対策

#### ステップ5: テスト生成
- **目的**: ディレクトリ構造の妥当性を検証するテスト作成
- **テスト項目**:
  - 全ディレクトリが正しく作成されているか
  - `docs/aidlc/version.txt` が正しく生成されているか
  - .gitkeep ファイルが適切に配置されているか
  - エラーケースが適切にハンドリングされるか

#### ステップ6: 統合とレビュー
- **目的**: 動作確認とレビュー
- **作業内容**:
  - ディレクトリ構造の確認（`tree` コマンドまたは `find` コマンド使用）
  - `docs/aidlc/version.txt` の内容確認
  - .gitkeep ファイルの確認
  - コードレビュー（セキュリティ、エラーハンドリング等）
- **成果物**: `docs/versions/v1.0.0/construction/units/unit3_implementation_record.md`

#### ステップ7: progress.md更新とコミット
- **目的**: 進捗状況を記録し、Gitコミットを作成
- **作業内容**:
  - progress.md の Unit3 状態を「完了」に変更
  - 完了日を記録
  - 次回実行可能なUnit候補を更新（Unit4が実行可能になる）
  - すべての変更をGitコミット

## 依存関係
- Unit1: setup-prompt.md のリファクタリング（完了済み）

## 非機能要件
- **パフォーマンス**: ディレクトリ作成は高速
- **セキュリティ**: 適切な権限設定
- **スケーラビリティ**: 新バージョン追加時にも同じ構造を使用可能
- **エラーハンドリング**: 適切なエラーメッセージとガイダンス

## 見積もり
半日

## 備考
- このUnitは新しいディレクトリ構造の物理的な作成を行う
- Unit1で実装したsetup-prompt.mdの変更を活用する
- Unit2で更新したプロンプトファイルのパス参照が機能する基盤となる
