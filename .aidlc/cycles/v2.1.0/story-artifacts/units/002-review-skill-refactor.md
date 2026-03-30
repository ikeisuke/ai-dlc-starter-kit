# Unit: レビュースキルのタイミングベース化 + レビューフロー修正

## 概要
種別ベースのレビュースキル4つを、タイミングベースの9スキルに再構成する。併せて review-flow.md のレビュー完了条件をレビュワー承認ベースに修正する。

## 含まれるユーザーストーリー
- ストーリー 2: レビュースキルのタイミングベース化
- ストーリー 3: レビュー完了条件の修正

## 責務
- 旧レビュースキル4つの廃止（ディレクトリ削除）
- 新レビュースキル9つの作成（SKILL.md にタイミング固有の観点を記載）
- marketplace.json の更新（旧スキル削除、新スキル追加）
- review-flow.md の CallerContext マッピング更新
- review-flow.md の反復レビューフローをレビュワー承認ベースに変更
- rules.md（`.aidlc/rules.md`）のスキル呼び出し記述更新
- Construction Phase のレビュー観点変更（code に security 統合、integration は設計乖離確認に変更）

## 境界
- レビュースキルの内部実装ロジック（外部CLI呼び出し、セルフレビュー等）の基本構造は維持
- セミオートゲート判定ロジックは変更しない（review-flow.md 内のシグナル生成は維持）

## 依存関係

### 依存する Unit
- Unit 001: パス参照問題の修正（review-flow.md, rules.md のパス参照が修正済みの状態で作業するため）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 新しいタイミングの追加が容易な構造にする
- **可用性**: 該当なし

## 技術的考慮事項
- 新スキル名: reviewing-inception-intent, reviewing-inception-stories, reviewing-inception-units, reviewing-construction-plan, reviewing-construction-design, reviewing-construction-code, reviewing-construction-integration, reviewing-operations-deploy, reviewing-operations-premerge
- 旧スキル名はエイリアスなしで完全廃止（破壊的変更）
- reviewing-construction-code は旧 code + security の観点を統合
- reviewing-construction-integration は設計乖離・レビュー/テスト実施確認に観点変更
- レビュー完了条件: 「指摘ゼロ=完了」→「レビュワー承認=完了」に変更

## 関連Issue
- #486

## 実装優先度
High

## 見積もり
大規模（スキル9つの作成、review-flow.md・rules.md の構造変更）

## サブタスク・完了条件

| サブタスク | 完了条件 |
|-----------|---------|
| 旧スキル4つのディレクトリ削除 | `skills/reviewing-{code,architecture,inception,security}/` が存在しない |
| 新スキル9つの SKILL.md 作成 | 各 SKILL.md にタイミング固有のレビュー観点が記載されている |
| marketplace.json 更新 | 旧スキル名の参照がゼロ、新スキル名が全て登録済み |
| review-flow.md CallerContext 更新 | CallerContext マッピングが新スキル名で記述されている |
| review-flow.md レビュー完了条件変更 | 「指摘ゼロ=完了」→「レビュワー承認=完了」に変更されている |
| rules.md スキル呼び出し更新 | `.aidlc/rules.md` 内の旧スキル名参照がゼロ |
| Construction レビュー観点変更 | construction-code が security 統合、integration が設計乖離確認に変更 |

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-31
- **完了日**: 2026-03-31
- **担当**: @claude
- **エクスプレス適格性**: -
- **適格性理由**: -
