# Unit: UnitブランチPR自動作成

## 概要
Construction PhaseでUnitブランチを作成する際に、ドラフトPRを自動作成する機能を追加する。

## 含まれるユーザーストーリー
- ストーリー3: UnitブランチでのドラフトPR自動作成

## 責務
- Unitブランチ作成時のドラフトPR作成フローを追加
- PRタイトル・ボディの自動生成
- GitHub CLI利用不可時のフォールバック案内

## 境界
- 既存のUnit完了時のPRマージフローは変更しない
- Unit以外のブランチ（サイクルブランチ等）のPR作成は対象外

## 依存関係

### 依存する Unit
- なし（独立して実装可能）

### 外部依存
- GitHub CLI（gh）

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- GitHub CLI の `gh pr create --draft` コマンドを使用
- PRタイトル: `[Draft][Unit {NNN}] {Unit名}`
- PRボディ: Unit定義から概要を抽出
- 修正対象: prompts/package/prompts/construction.md

## 実装優先度
High

## 見積もり
1時間

---
## 実装状態

- **状態**: 進行中
- **開始日**: 2026-01-08
- **完了日**: -
- **担当**: AI
