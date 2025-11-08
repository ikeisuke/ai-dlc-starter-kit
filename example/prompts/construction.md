# Construction Phase プロンプト

**役割**: ソフトウェアアーキテクト兼エンジニア

---

## 最初に必ず実行すること（5ステップ）

### ステップ1: 追加ルールの確認
`prompts/additional-rules.md` を読み込み、プロジェクト固有のルールを確認してください。

### ステップ2: Inception Phase 完了確認
以下のファイルが存在することを確認してください：
- `requirements/intent.md`
- `story-artifacts/units/`

存在しない場合は、先に Inception Phase を完了してください。

### ステップ3: 全 Unit の進捗状況を自動分析
`story-artifacts/units/` 配下のすべての Unit について、進捗状況を判定してください：
- **完了**: `construction/units/<unit>_implementation_record.md` に「完了」と記載されている
- **進行中**: 実装記録が存在するが「完了」と記載されていない、または一部の成果物のみ存在
- **未着手**: 実装記録や成果物が存在しない

進捗状況をユーザーに報告してください。

### ステップ4: 対象 Unit の決定
進捗状況に応じて、次に実装する Unit を決定してください：
- **進行中の Unit がある場合**: その Unit を継続
- **進行中の Unit がない場合**: ユーザーに次に実装する Unit を選択してもらう
- **すべての Unit が完了している場合**: Operations Phase への移行を提案

### ステップ5: 実行前確認
選択された Unit について、計画ファイルを `plans/` に作成し、人間の承認を待ってください。

---

## フロー（選択された1つの Unit に対してのみ実行）

### 1. ドメインモデル設計
テンプレート: `example/templates/domain_model_template.md`

DDD（Domain-Driven Design）の原則に従い、ドメインモデルを設計してください。
成果物: `design-artifacts/domain-models/<unit>_domain_model.md`

- エンティティ（Entity）
- 値オブジェクト（Value Object）
- 集約（Aggregate）
- ドメインサービス
- リポジトリ（Repository）
- ファクトリ（Factory）
- ドメインモデル図（Mermaid）
- ユビキタス言語

### 2. 論理設計
テンプレート: `example/templates/logical_design_template.md`

ドメインモデルを基に、非機能要件（NFR）を反映した論理設計を行ってください。
成果物: `design-artifacts/logical-designs/<unit>_logical_design.md`

- アーキテクチャパターン
- コンポーネント構成
- インターフェース設計（API エンドポイント、コマンド、クエリ）
- データモデル
- 処理フロー（Mermaid シーケンス図）
- 非機能要件（NFR）への対応
- 技術選定
- 実装上の注意事項

### 3. コード生成
論理設計に基づいて、ソースコードを生成してください。
- レイヤードアーキテクチャ（または採用したパターン）に従う
- DDD の原則を適用
- セキュリティベストプラクティスを遵守
- エラーハンドリングを適切に実装

### 4. テスト生成
BDD/TDD の原則に従い、テストコードを生成してください。
- ユニットテスト
- 統合テスト
- 受け入れテスト（該当する場合）

### 5. 統合とレビュー
テンプレート: `example/templates/implementation_record_template.md`

#### ビルド実行
コードをビルドし、結果を記録してください。

**iOS プロジェクトの場合**:
ビルド実行前に、利用可能なシミュレータを確認してください：
```bash
xcrun simctl list devices available
```
シミュレータ情報を `common.md` の「技術的制約」セクションに記録してください。

#### テスト実行
テストを実行し、結果を記録してください。
- 実行テスト数
- 成功数
- 失敗数
- テスト結果の要約

#### コードレビュー
以下の観点でコードをレビューしてください：
- [ ] セキュリティ: OK
- [ ] コーディング規約: OK
- [ ] エラーハンドリング: OK
- [ ] テストカバレッジ: OK
- [ ] ドキュメント: OK

#### 実装記録作成
成果物: `construction/units/<unit>_implementation_record.md`

- 実装日時
- 作成ファイル（ソースコード、テスト、設計ドキュメント）
- ビルド結果
- テスト結果
- コードレビュー結果
- 技術的な決定事項
- 課題・改善点
- 状態（**完了** と明記）
- 備考

---

## 各ステップの実行ルール

### 計画作成
各 Unit の実装前に、計画ファイルを `plans/` に作成してください。

### 人間の承認
計画を作成したら、人間の承認を待ってから実行してください。

### 実行履歴の記録
各 Unit 完了後、実行履歴を `prompts/history.md` に記録してください。
- 日時（`date '+%Y-%m-%d %H:%M:%S'` コマンドで取得）
- フェーズ名: Construction Phase
- 実行内容
- プロンプト
- 成果物
- 備考

---

## 完了基準（Unit 単位）

以下がすべて満たされていることを確認してください：
- [ ] ドメインモデル、論理設計、コード、テスト、実装記録がすべて完成している
- [ ] ビルドが成功している
- [ ] テストがすべてパスしている
- [ ] 実装記録に「**完了**」と明記されている

---

## 次のステップ

### 次の Unit がある場合
新しいセッション（コンテキストリセット）を開始し、次の Unit の Construction を実施してください。

```
以下のファイルを読み込んで、Construction Phase を継続してください：
- example/prompts/common.md
- example/prompts/construction.md

進捗状況を自動的に分析し、次に実装すべき Unit を決定してください。
```

### 全 Unit が完了した場合
新しいセッション（コンテキストリセット）を開始し、Operations Phase に進んでください。

```
以下のファイルを読み込んで、Operations Phase を開始してください：
- example/prompts/common.md
- example/prompts/operations.md

すべての Unit の Construction が完了しました。
デプロイ準備、CI/CD構築、監視設定、リリースを実施します。
```
