# Unit 002 実装計画: 共通セクション外部化

## 概要

AI-DLC手法の要約、共通開発ルールを外部ファイルに切り出し、各プロンプトから参照する形式に変更する。
これにより各プロンプトのサイズを削減し、保守性を向上させる。

## 関連Issue

- #76: 共通セクションの外部ファイル化

## 変更対象ファイル

1. **外部ファイル（新規作成）**
   - `prompts/package/prompts/common/intro.md` - AI-DLC手法の要約
   - `prompts/package/prompts/common/rules.md` - 共通開発ルール

2. **既存プロンプト（修正）**
   - `prompts/package/prompts/inception.md` - 共通部分を参照形式に変更
   - `prompts/package/prompts/construction.md` - 共通部分を参照形式に変更
   - `prompts/package/prompts/operations.md` - 共通部分を参照形式に変更

3. **成果物ドキュメント（新規作成）**
   - `docs/cycles/v1.9.0/design-artifacts/domain-models/common-section-extraction_domain_model.md`
   - `docs/cycles/v1.9.0/design-artifacts/logical-designs/common-section-extraction_logical_design.md`
   - `docs/cycles/v1.9.0/construction/units/common-section-extraction_implementation.md`

## 実装計画

### Phase 1: 設計（コードは書かない）

#### ステップ1: ドメインモデル設計

- 共通セクションの境界を明確化
  - intro.md に含める内容: AI-DLC手法の要約セクション（約20行）
  - rules.md に含める内容: 共通開発ルール（承認プロセス、質問フロー、Gitコミット、jjサポート等）
- フェーズ固有セクションの識別
  - 履歴管理のパス指定（フェーズごとに異なる）
  - 気づき記録フロー（Construction固有）
  - AIレビューフロー（別Unit: Unit 003）

#### ステップ2: 論理設計

- 参照指示の形式決定
  - Unit 001 PoC結果に基づく推奨形式を使用
  - `docs/aidlc/prompts/common/intro.md を読み込んでください`
- 削減行数の見積もり
  - 各プロンプトから約80-100行削減予定
  - 3ファイル合計で約250行以上の削減
- rsyncデプロイ設定の確認

#### ステップ3: 設計レビュー

- 設計内容のユーザー承認

### Phase 2: 実装

#### ステップ4: コード生成

1. `intro.md` の作成
   - AI-DLC手法の要約セクションを抽出
2. `rules.md` の作成
   - 共通開発ルールを抽出
   - フェーズ固有部分は残す
3. 各プロンプトの修正
   - 共通部分を削除
   - 参照指示を追加

#### ステップ5: テスト生成

- 参照読み込みの動作確認
- 各プロンプトの整合性確認

#### ステップ6: 統合とレビュー

- 行数削減の確認（250行以上）
- 実装記録の作成

---

## 完了条件チェックリスト

- [ ] `prompts/package/prompts/common/intro.md` の作成
- [ ] `prompts/package/prompts/common/rules.md` の作成
- [ ] 各フェーズプロンプトの参照形式への変更
- [ ] 250行以上の削減達成

---

## 備考

- rsyncデプロイ設定でcommon/ディレクトリが正しくコピーされることを確認
- 参照形式: Unit 001 PoC結果に基づく
- AIレビューフローは別Unit（Unit 003）で対応
- 参照漏れチェックは別Unit（Unit 004）で実施
