# AI-Driven Development Lifecycle (AI-DLC)

AWS が提唱する AI ネイティブなソフトウェア開発方法論のホワイトペーパーとその翻訳です。

## 元データ

オリジナルのホワイトペーパー: <https://prod.d13rzhkk8cj2z0.amplifyapp.com>

## AI-DLC とは

AI-Driven Development Lifecycle (AI-DLC) は、AI を「支援ツール」としてではなく、開発プロセスの「中心的な協働者」として位置づける新しいソフトウェア開発方法論です。従来の SDLC や Agile を AI 時代に合わせて根本的に再設計したものです。

### 主な特徴

- **AI 主導**: AI が開発の司令塔となり、人間が監督・検証者として関与
- **会話の反転**: AI が作業計画を提示し、人間が承認・判断する
- **3つのフェーズ**: Inception（起動）→ Construction（構築）→ Operations（運用）
- **設計技法の統合**: DDD・BDD・TDD などを AI が自動適用

## ドキュメント構成

### 翻訳ドキュメント

各章を個別のファイルに分割して翻訳しています：

1. **`AI-DLC_I_CONTEXT_Translation.md`** - 背景
   ソフトウェア工学の進化と AI ネイティブ開発の必要性

2. **`AI-DLC_II_KEY_PRINCIPLES_Translation.md`** - 主要原則
   AI-DLC を支える 10 の原則（再構築、会話の反転、設計技法の統合など）

3. **`AI-DLC_III_CORE_FRAMEWORK_Translation.md`** - コアフレームワーク
   3つのフェーズ（Inception、Construction、Operations）の詳細

4. **`AI-DLC_IV_IN_ACTION_Translation.md`** - 実践例（新規開発）
   Green-Field プロジェクトでの AI-DLC 適用方法

5. **`AI-DLC_V_IN_ACTION_BrownField_Translation.md`** - 実践例（既存システム）
   Brown-Field プロジェクトでの AI-DLC 適用方法

6. **`AI-DLC_VI_Adopting_Translation.md`** - 導入方法
   AI-DLC を組織に導入するための戦略

7. **`AI-DLC_AppendixA_ja.md`** - 付録 A
   実践のためのプロンプトテンプレート集

### 要約版

- **`AI-Driven_Development_Lifecycle_Summary.md`** - 全体の要約
  全章を簡潔にまとめたもの（最初に読むことを推奨）

## 推奨する読み方

### クイックスタート（10分）

1. `AI-Driven_Development_Lifecycle_Summary.md` で全体像を把握

### 基礎理解（30分）

1. `AI-DLC_I_CONTEXT_Translation.md` - なぜ AI-DLC が必要か
2. `AI-DLC_II_KEY_PRINCIPLES_Translation.md` - AI-DLC の考え方
3. `AI-DLC_III_CORE_FRAMEWORK_Translation.md` - 基本的な仕組み

### 実践準備（1時間）

1. `AI-DLC_IV_IN_ACTION_Translation.md` - 新規開発での適用
2. `AI-DLC_V_IN_ACTION_BrownField_Translation.md` - 既存システムでの適用
3. `AI-DLC_AppendixA_ja.md` - 具体的なプロンプト例

### 組織導入（2時間）

上記すべて + `AI-DLC_VI_Adopting_Translation.md`

## 主要概念

### 10の原則

1. 再構築（Reimagine not Retrofit）
2. 会話の方向を反転（Reverse the Conversation）
3. 設計技法の統合（Integrate Design Techniques）
4. AI の現実的な能力に合わせる
5. 複雑なシステム開発を対象とする
6. 人間との共創を維持する
7. 学習容易性
8. 役割の集約
9. ステージを最小化してフローを最大化
10. 固定プロセスを廃止

### 3つのフェーズ

1. **Inception（起動）**
   ビジネス上の意図（Intent）を AI が分解し、開発単位（Unit）を生成

2. **Construction（構築）**
   AI がドメイン設計（DDD）→論理設計→コード→テストを自動化

3. **Operations（運用）**
   AI がデプロイ、監視、SLA 違反予測、修正提案を実施

## このリポジトリでの活用

このホワイトペーパーで提唱されている AI-DLC の原則とプロンプトテンプレートを参考に、Claude Agents を活用した開発フローの実例を showcase として実装しています。

## ライセンスと利用について

オリジナルのホワイトペーパーは AWS (Amazon Web Services) により公開されています。
著者: Raju SP, Amazon Web Services

**重要**: このドキュメントには明示的なライセンス情報が記載されていません。
- オリジナル文書: <https://prod.d13rzhkk8cj2z0.amplifyapp.com>
- このリポジトリの翻訳文書は、学習・参考目的での利用を想定しています
- 商用利用や再配布については、AWS または著者に直接確認することを推奨します

翻訳版の著作権については、オリジナルの著作権者に帰属します。
