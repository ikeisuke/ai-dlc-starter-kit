# ドメインモデル: 進捗管理再設計

## 概要

progress.mdの役割を再設計し、複数人開発でもコンフリクトが起きにくい進捗管理の仕組みを実現する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 現状分析

### 現在のprogress.md構成

| フェーズ | パス | 用途 | 作業形態 |
|----------|------|------|----------|
| Inception | `inception/progress.md` | ステップ1〜5の進捗 | 1人（AI） |
| Construction | `construction/progress.md` | Unit単位の進捗 | 複数人（Unit単位で分担） |
| Operations | `operations/progress.md` | ステップ1〜5の進捗 | 1人（AI） |

### 課題

- **Construction Phase**: 複数人が別々のUnitを担当する際、同じprogress.mdを更新するとコンフリクトの可能性がある
- **Inception/Operations**: 1人作業のためコンフリクトリスクは低い

## 設計方針

### 決定事項

1. **Construction Phase**: progress.mdを廃止し、**Unit定義ファイルに状態を直接追記**する方式に変更
2. **Inception Phase**: 現状維持（1人作業のためコンフリクトリスクなし）
3. **Operations Phase**: 現状維持（1人作業のためコンフリクトリスクなし）

### Construction Phase の新しい進捗管理

#### Unit定義ファイルへの状態セクション追加

`docs/cycles/{{CYCLE}}/story-artifacts/units/unit{番号}_{name}.md` に以下のセクションを追加:

```markdown
---
## 実装状態

- **状態**: 未着手 | 進行中 | 完了
- **開始日**: YYYY-MM-DD または -
- **完了日**: YYYY-MM-DD または -
- **担当**: @username または -
```

#### 状態の取得方法

Construction Phase開始時:
1. `story-artifacts/units/` ディレクトリ内の全Unit定義ファイルを列挙
2. 各ファイルの「実装状態」セクションを読み取り
3. 状態に基づいて実行可能Unitを判定

#### 状態遷移

```
未着手 → 進行中 → 完了
```

- **未着手→進行中**: Unit作業開始時に担当者が更新
- **進行中→完了**: Unit完了時に担当者が更新

## 概念モデル

### エンティティ

#### Unit（実装単位）

- **識別子**: Unit番号 + Unit名
- **属性**:
  - 概要: ユーザーストーリーの要約
  - 依存関係: 他Unitへの依存
  - 優先度: High / Medium / Low
  - 見積もり: 作業量の目安
  - **実装状態**: 未着手 / 進行中 / 完了（新規追加）
  - **開始日**: 作業開始日（新規追加）
  - **完了日**: 作業完了日（新規追加）
  - **担当**: 担当者（新規追加）
- **格納場所**: `story-artifacts/units/unit{番号}_{name}.md`

### サービス（AIの処理）

#### 進捗検出サービス

- **責務**: Unit定義ファイルから進捗状況を収集し、実行可能Unitを判定
- **操作**:
  - `listUnits()`: 全Unit定義ファイルを列挙
  - `getUnitStatus(unitFile)`: Unitの実装状態を取得
  - `getExecutableUnits()`: 依存関係を考慮し、実行可能なUnitを返す

## 影響範囲

### 変更が必要なファイル

1. **`docs/aidlc/prompts/construction.md`**
   - progress.md参照部分を削除
   - Unit定義ファイルからの状態読み取りに変更
   - Unit完了時の更新先をUnit定義ファイルに変更

2. **`docs/aidlc/templates/unit_template.md`**
   - 「実装状態」セクションを追加

3. **`docs/aidlc/prompts/inception.md`**
   - Unit定義作成時に「実装状態」セクション（初期値: 未着手）を含める指示を追加

### 変更不要なファイル

- `inception/progress.md` の仕組み（現状維持）
- `operations/progress.md` の仕組み（現状維持）

## 不明点と質問（設計中に記録）

[Question] 複数人での同時開発を想定していますか？
[Answer] 複数人開発を想定するのはConstruction Phaseのみ（Inception/OperationsはAIが1人で実行）

[Question] Construction Phaseで複数人が作業する場合、各人が別々のUnitを担当する形式ですか？
[Answer] 同じUnitを複数人で作業することはない（Unit単位で担当分け）

[Question] コンフリクト対策として、Unit単位でファイル分割 vs progress.md維持のどちらが好ましいですか？
[Answer] Unit単位でファイル分割（A案）を採用。ただしUnit定義ファイルに直接書く方式で。

[Question] 責務の分離（定義と状態を分ける）を重視しますか？情報の集約（1ファイルにまとめる）を重視しますか？
[Answer] Unit定義ファイルに状態を直接追記する方式（A1）を採用
