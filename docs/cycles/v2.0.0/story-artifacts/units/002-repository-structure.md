# Unit: リポジトリ構造基盤

## 概要
`skills/` ディレクトリを作成し、既存スキル（reviewing-*, squash-unit）を移動、marketplace.jsonを更新してプラグイン配布に適したリポジトリ構造を構築する。

## 含まれるユーザーストーリー
- ストーリー 2: リポジトリ構造のスキル配置移行

## 責務
- `skills/` ディレクトリ構造の作成
- 既存スキル（reviewing-code, reviewing-architecture, reviewing-inception, reviewing-security, squash-unit）の移動
- `skills/aidlc/` ディレクトリ骨格の作成
- `.claude-plugin/marketplace.json` の更新
- 旧 `.claude/skills/` シンボリックリンクの整理

## 境界
- スキルの内容変更は行わない（配置移動のみ）
- シェルスクリプトの移動はUnit 003で実施

## 依存関係

### 依存する Unit
- Unit 001: PoC - スキル機能検証（依存理由: PoCの結果により@参照フォールバックが必要か判明し、ディレクトリ構造に影響する）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 特になし
- **セキュリティ**: 特になし
- **スケーラビリティ**: 特になし
- **可用性**: 特になし

## 技術的考慮事項
- marketplace.jsonのskillsパスを `./skills/` 配下に更新
- SKILL.mdの自己完結性原則: スキルが参照するファイルは全てスキルディレクトリ内に配置

## 実装優先度
High

## 見積もり
小〜中

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
