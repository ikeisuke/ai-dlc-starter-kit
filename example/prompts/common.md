# 共通知識（全フェーズ共通）

このファイルは、AI-DLC の全フェーズで読み込まれる共通知識です。

---

## プロジェクト概要

**プロジェクト名**: AI-DLC Starter Kit

**概要**: AI-DLC (AI-Driven Development Lifecycle) を使った開発をすぐに始められるスターターキット。AI を「支援ツール」ではなく、開発プロセスの「中心的な協働者」として位置づける新しいソフトウェア開発方法論を実践するためのテンプレートとガイドを提供します。

**主要な特徴**:
- AI-DLC ホワイトペーパーの日本語翻訳を提供
- 3つのフェーズ（Inception → Construction → Operations）に対応したプロンプトテンプレート
- AI が計画を提示し、人間が承認・判断する「会話の反転」の実践
- DDD・BDD・TDD を AI が自動適用する設計技法の統合

---

## 技術スタック詳細

このプロジェクトは **greenfield（新規開発）** です。

**技術スタックは Inception Phase で決定します。**

決定後、このセクションを更新してください：
- プログラミング言語
- フレームワーク
- データベース
- インフラストラクチャ
- 開発ツール
- その他

---

## ディレクトリ構成

### ドキュメント構成

```
example/
├── prompts/                          # プロンプトと履歴
│   ├── common.md                     # 全フェーズ共通知識（このファイル）
│   ├── inception.md                  # Inception Phase 用
│   ├── construction.md               # Construction Phase 用
│   ├── operations.md                 # Operations Phase 用
│   ├── additional-rules.md           # 追加ルール
│   └── history.md                    # 実行履歴
├── plans/                            # 実行計画
├── requirements/                     # 要件定義
│   ├── intent.md                     # 開発意図
│   └── prfaq.md                      # PRFAQ
├── story-artifacts/                  # ユーザーストーリー
│   ├── user_stories.md               # ユーザーストーリー一覧
│   └── units/                        # Unit 別定義
│       └── <unit_name>.md
├── design-artifacts/                 # 設計成果物
│   ├── existing-system-model.md      # 既存システムモデル（brownfield のみ）
│   ├── domain-models/                # ドメインモデル
│   │   └── <unit>_domain_model.md
│   ├── logical-designs/              # 論理設計
│   │   └── <unit>_logical_design.md
│   └── architecture/                 # アーキテクチャ設計
├── construction/                     # 構築記録
│   └── units/                        # Unit 別実装記録
│       └── <unit>_implementation.md
└── operations/                       # 運用関連
    ├── deployment_checklist.md
    ├── monitoring_strategy.md
    ├── distribution_feedback.md
    └── post_release_operations.md
```

### ソースコード構成

**Inception Phase で決定します。**

技術スタック決定後、ソースコードのディレクトリ構成をここに記載してください。

---

## 制約事項

### 技術的制約

- **開発環境**: macOS (Darwin 25.0.0)
- **Git リポジトリ**: https://github.com/ikeisuke/ai-dlc-starter-kit
- **その他の技術的制約**: Inception Phase で決定

### データライセンス制約

- AI-DLC 翻訳文書はオリジナルのホワイトペーパー（AWS, 著者: Raju SP）の翻訳
- 学習・参考目的での利用を想定
- 商用利用や再配布については AWS または著者に確認を推奨

### セキュリティ制約

- コマンドインジェクション、XSS、SQLインジェクション等の OWASP Top 10 脆弱性を防止
- 機密情報（.env、credentials.json 等）をコミットしない
- API 認証、個人情報取扱いについては Inception Phase で定義

### 開発制約

- **作業ブランチ**: feature/example
- **マージ先**: main
- **コミットメッセージ形式**:
  - 1行目: 簡潔な要約（50文字以内推奨）
  - 空行
  - 詳細説明
  - フッター（Co-Authored-By 等）

---

## 外部リソース

### 外部API情報

該当なし（Inception Phase で必要に応じて追加）

### データ統計

該当なし（Inception Phase で必要に応じて追加）

### 参考ドキュメント

- **README.md**: `/README.md` - プロジェクト概要とクイックスタートガイド
- **LICENSE**: `/LICENSE` - MIT License
- **AI-DLC 翻訳文書**: `docs/translations/` 配下
  - 特に重要: `AI-Driven_Development_Lifecycle_Summary.md` - 全体の要約
- **オリジナルホワイトペーパー**: https://prod.d13rzhkk8cj2z0.amplifyapp.com

---

## 開発ルール

### コード品質基準

- **言語統一**: すべてのドキュメント・コメントは日本語で記述
- **セキュリティ**: OWASP Top 10 脆弱性を防止
- **テスト**: 各 Unit に対してテストを作成（Construction Phase）
- **レビュー**: AI による自動レビュー + 人間による最終確認

### Git運用

- **ブランチ戦略**: feature ブランチから main へマージ
- **コミット粒度**:
  - 1つのコミットは1つの論理的な変更のみを含む
  - 機能追加、リファクタリング、バグ修正は別々のコミットに分ける
  - 関連する変更はまとめる（例: 新機能のコードとそのテスト、ドキュメント更新）
  - ビルドが成功する状態でコミットする
  - コミットメッセージで「何を」「なぜ」変更したか明確に説明
  - 悪い例: 「複数の無関係な機能を1つのコミットにまとめる」「WIP（作業中）の状態でコミット」
  - 良い例: 「ユーザー認証機能の追加」「パフォーマンス改善のためのキャッシュ導入」
- **プッシュ**: 人間の明示的な承認後のみ
- **Git Hooks**: pre-commit フックによる自動チェック（該当する場合）

### プロンプト履歴管理

- すべてのフェーズ実行時に `example/prompts/history.md` へリアルタイムで記録
- 記録項目:
  - 日時（`date '+%Y-%m-%d %H:%M:%S'` コマンドで取得）
  - フェーズ名
  - 実行内容
  - 使用したプロンプト
  - 生成された成果物
  - 備考

### 追加ルールの参照

プロジェクト固有の追加ルールは `example/prompts/additional-rules.md` を参照してください。
各フェーズ開始時に必ず確認すること。

---

## フェーズの責務分離

### Inception Phase（起動フェーズ）

**役割**: プロダクトマネージャー兼ビジネスアナリスト

**やること**:
- Intent（開発意図）の明確化
- 既存コード分析（brownfield の場合）
- ユーザーストーリー作成
- Unit 定義
- PRFAQ 作成
- 技術スタックの決定（greenfield の場合）

**やらないこと**:
- 詳細な設計（Construction で実施）
- コード実装（Construction で実施）
- デプロイや運用設定（Operations で実施）

**成果物形式**:
- `requirements/intent.md`
- `design-artifacts/existing-system-model.md`（brownfield のみ）
- `story-artifacts/user_stories.md`
- `story-artifacts/units/*.md`
- `requirements/prfaq.md`

### Construction Phase（構築フェーズ）

**役割**: ソフトウェアアーキテクト兼エンジニア

**やること**:
- ドメインモデル設計（DDD 原則）
- 論理設計（NFR 反映）
- コード生成
- テスト生成
- 統合とレビュー
- Unit 単位での反復実施

**やらないこと**:
- 要件定義（Inception で実施済み）
- デプロイや運用設定（Operations で実施）

**成果物形式**:
- `design-artifacts/domain-models/<unit>_domain_model.md`
- `design-artifacts/logical-designs/<unit>_logical_design.md`
- ソースコードファイル
- テストファイル
- `construction/units/<unit>_implementation.md`

### Operations Phase（運用フェーズ）

**役割**: DevOps エンジニア兼 SRE

**やること**:
- デプロイ準備
- CI/CD 構築
- 監視・ロギング戦略
- 配布（該当する場合）
- リリース後の運用
- フィードバック収集と次期バージョンの計画

**やらないこと**:
- 要件定義（Inception で実施済み）
- コード実装（Construction で実施済み）

**成果物形式**:
- `operations/deployment_checklist.md`
- CI/CD 設定ファイル
- `operations/monitoring_strategy.md`
- `operations/distribution_feedback.md`
- `operations/post_release_operations.md`

---

## 進捗管理と冪等性

### 進捗状態チェックリスト

各フェーズは以下のチェックリストで進捗を管理します：

#### Inception Phase
- [ ] Intent 明確化完了
- [ ] 既存コード分析完了（brownfield のみ）
- [ ] ユーザーストーリー作成完了
- [ ] Unit 定義完了
- [ ] PRFAQ 作成完了

#### Construction Phase
各 Unit ごとに以下をチェック：
- [ ] ドメインモデル設計完了
- [ ] 論理設計完了
- [ ] コード実装完了
- [ ] テスト実装完了
- [ ] 統合とレビュー完了

#### Operations Phase
- [ ] デプロイ準備完了
- [ ] CI/CD 構築完了
- [ ] 監視・ロギング戦略完了
- [ ] 配布完了（該当する場合）
- [ ] リリース後の運用開始

### 冪等性保証の手順

各フェーズの開始時に以下の手順を実行し、冪等性を保証します：

1. **既存成果物確認**: 該当フェーズの成果物ファイルが存在するか確認
2. **差分特定**: 既存ファイルがある場合、内容を読み込んで未完了部分を特定
3. **計画作成**: 実行すべき残りのタスクを `plans/` に計画ファイルとして作成
4. **承認**: 人間の承認を得る
5. **実行**: 計画に従って実行（既存部分はスキップ）
6. **完了確認**: 成果物が完成したことを確認

この手順により、途中で中断した場合でも、同じプロンプトで再開すれば続きから実行できます。

---

## バージョン情報

- **対象リリース**: v1
- **ベースブランチ**: main
- **作業ブランチ**: feature/example
- **作成日**: 2025-11-06
- **最終更新日**: 2025-11-06

---

## AI-DLC 原則の反映

このプロジェクトでは、AI-DLC の 10 の主要原則を以下のように実践します：

1. **再構築（Reimagine not Retrofit）**: 既存の開発手法の改良ではなく、AI 時代に合わせた根本的な再設計
2. **会話の反転（Reverse the Conversation）**: AI が計画を提示し、人間が承認・判断
3. **設計技法の統合（Integrate Design Techniques）**: DDD・BDD・TDD を AI が自動適用
4. **AI の現実的な能力に合わせる**: AI の強みと限界を理解した設計
5. **複雑なシステム開発を対象とする**: 大規模・複雑なシステムに適用
6. **人間との共創を維持する**: AI が提案、人間が検証・承認
7. **学習容易性**: 既存の知識を活用し、段階的に学習可能
8. **役割の集約**: 専門特化された役割を最小限に
9. **ステージを最小化してフローを最大化**: 短サイクルで高速イテレーション
10. **固定プロセスを廃止**: AI が状況に応じて最適なプロセスを提案

---

## 注意事項

- このファイルは全フェーズで読み込まれる共通知識です
- 各フェーズ開始時に、このファイルと該当フェーズの `.md` ファイルを読み込んでください
- プロジェクトの進行に応じて、適宜このファイルを更新してください
- 特に「技術スタック詳細」と「ソースコード構成」は Inception Phase 完了後に更新が必要です
