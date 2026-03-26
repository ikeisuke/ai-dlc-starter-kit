# Unit 3: Construction進捗ファイル責務移動 - 実装計画

## 概要
Inception PhaseからConstruction Phaseへ、construction/progress.md作成の責務を移動する

## 現状分析

### 各フェーズの進捗ファイル作成パターン

| フェーズ | 次フェーズのprogress.md作成 |
|---------|---------------------------|
| Inception → Construction | **Inceptionが作成**（ステップ6） |
| Construction → Operations | **Operationsが自己作成** |

### 問題点
- パターンが統一されていない
- Inception Phaseが Construction Phase の責務を持っている

### 目標
- Construction PhaseもOperations Phaseと同様に「自身のprogress.mdを自己作成」するパターンに統一

---

## 実装計画

### Phase 1: 設計（ドキュメント変更のため簡略化）

このUnitはプロンプトファイル（Markdownドキュメント）の変更であり、コード実装を伴わないため、ドメインモデル設計・論理設計は省略し、直接変更計画を記述する。

### Phase 2: 実装

#### タスク1: inception.md の変更

**変更内容**:
1. ステップ6「Construction用進捗管理ファイル作成」セクションを削除
2. 完了基準から「進捗管理ファイル作成」を削除
3. 完了時の必須作業のコミット対象から「construction/progress.md」を削除
4. フローのステップ数が5ステップになることを反映

#### タスク2: construction.md の変更

**変更内容**:
1. 「最初に必ず実行すること」セクションのステップ3を変更
   - 現在: 「progress.mdを読み込む」のみ
   - 変更後: Operations Phaseと同様に「存在しない場合は作成」ロジックを追加
2. progress.md初期化ロジック:
   - `docs/cycles/{{CYCLE}}/story-artifacts/units/` をスキャンしてUnit一覧を取得
   - 各Unitファイルから名前・依存関係・優先度・見積もりを抽出
   - progress.mdを生成（全Unitの初期状態は「未着手」）
   - 次回実行可能なUnit候補を計算

#### タスク3: テスト・検証

**検証方法**:
- 変更後のinception.mdを読み、ステップ6が削除されていることを確認
- 変更後のconstruction.mdを読み、初期化ロジックが追加されていることを確認
- Operations Phaseの同様のロジックと整合性を確認

---

## 成果物

1. `docs/aidlc/prompts/inception.md` - 更新
2. `docs/aidlc/prompts/construction.md` - 更新
3. `docs/cycles/v1.2.1/construction/units/unit3_implementation.md` - 実装記録

---

## リスク・注意点

- 既存のサイクルで既にInception Phaseを完了している場合、progress.mdは既に存在するため影響なし
- 新規サイクルでは、Construction Phase開始時にprogress.mdが自動生成される動作に変わる
- メタ開発の注意: 今回の変更は「ツール側（prompts/）」の変更であり、次回セットアップ以降に反映される
