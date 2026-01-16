# Unit: 共通ラベル一括初期化スクリプト

## 概要
バックログ管理用の共通ラベル（backlog, type:*, priority:*）を一括で作成するスクリプトを作成する。

## 含まれるユーザーストーリー
- ストーリー 1-2: 共通ラベル一括初期化

## 関連Issue
- #34

## 責務
- 12個の共通ラベルを一括作成
- 既存ラベルのスキップ
- プロンプト内のラベル作成をスクリプト呼び出しに置換

## 境界
- サイクルラベル（cycle:vX.X.X）は別Unitで対応

## 依存関係

### 依存する Unit
- Unit 001（環境情報でgh確認）

### 外部依存
- gh（GitHub CLI）

## 非機能要件（NFR）
- **パフォーマンス**: 12ラベル作成で30秒以内
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: gh認証済み環境で動作

## 技術的考慮事項

### 作成するラベル
| ラベル名 | 色 | 説明 |
|---------|------|------|
| backlog | 0052CC | バックログアイテム |
| type:feature | A2EEEF | 新機能 |
| type:bugfix | D73A4A | バグ修正 |
| type:chore | FEF2C0 | 雑務 |
| type:refactor | C5DEF5 | リファクタリング |
| type:docs | 0075CA | ドキュメント |
| type:perf | F9D0C4 | パフォーマンス |
| type:security | D93F0B | セキュリティ |
| priority:high | B60205 | 優先度: 高 |
| priority:medium | FBCA04 | 優先度: 中 |
| priority:low | 0E8A16 | 優先度: 低 |

### 変更対象ファイル
- `prompts/package/bin/init-labels.sh`（新規）
- `prompts/package/prompts/setup.md`（呼び出し追加）
- `prompts/package/guides/backlog-management.md`（呼び出し追加）

## 実装優先度
High

## 見積もり
30分

---
## 実装状態

- **状態**: 進行中
- **開始日**: 2026-01-17
- **完了日**: -
- **担当**: AI
