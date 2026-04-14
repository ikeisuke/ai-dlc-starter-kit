# ドメインモデル: defaults.toml 存在チェック修正

## 概要

プリフライトチェックにおける `config/defaults.toml` の存在確認記述を、SKILL.mdのパス解決ルール（上位契約）に準拠させるための概念モデル定義。本Unitはドキュメント修正のみであり、コード上のエンティティは存在しない。

## ルール構造

### 上位契約: PathRule（SKILL.mdパス解決ルール）

- **定義**: `config/` で始まるパスはスキルベースディレクトリからの相対パスとして解決する（#563 で確立済み）
- **責務**: パス解決の基準を一元的に定義
- **本Unitとの関係**: 参照のみ、修正しない

### 下位契約: CheckCondition（preflight.md §5 存在確認条件）

- **定義**: `config/defaults.toml` の存在確認をPathRuleに従って実行する条件記述
- **責務**: PathRuleを参照し、スキルベース相対パスとして解決した結果に対して存在確認を行う旨を記述
- **修正対象**: 現状はPathRuleへの参照が欠落しており、AIエージェントがプロジェクトルート相対で実行してしまう

### 表示契約: DisplayMessage（preflight.md §6 結果テンプレート）

- **定義**: CheckConditionの結果に基づいて存在/不在を表示するテンプレート
- **責務**: CheckConditionの結果にのみ依存し、表示文言を提供
- **修正対象**: パスがスキルベース相対であることを明示する表現に変更

## 契約間の依存関係

```text
PathRule（SKILL.md）
  ↑ 参照（修正しない）
CheckCondition（preflight.md §5）← 修正箇所1
  ↓ 結果に依存
DisplayMessage（preflight.md §6）← 修正箇所2
```

- PathRule → CheckCondition: 一方向参照（CheckConditionがPathRuleを参照）
- CheckCondition → DisplayMessage: CheckConditionの結果にDisplayMessageが従属
- 循環依存なし

## 不変条件

- `config/` プレフィックスで始まるパスは常にスキルベース相対として解決される（PathRuleの保証）
- DisplayMessageはCheckConditionの結果にのみ依存し、パス解決ロジックを持たない

## ユビキタス言語

- **スキルベースディレクトリ**: SKILL.mdと同じディレクトリ。パス解決の基点
- **スキルベース相対パス**: `steps/`, `scripts/`, `config/` 等で始まるパスで、スキルベースディレクトリからの相対として解決されるもの
- **偽陰性**: 実際には存在するのに「不在」と報告される誤検出
