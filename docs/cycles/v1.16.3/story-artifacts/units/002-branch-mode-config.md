# Unit: ブランチ作成方式の設定固定化

## 概要
サイクルブランチの作成方式（branch/worktree/ask）を設定で固定できるようにし、毎サイクルの質問を省略可能にする。

## 含まれるユーザーストーリー
- ストーリー 5: ブランチ作成方式の設定固定化 (#214)

## 責務
- inception.md ステップ7の分岐ロジック変更（`[rules.branch].mode` の値に応じた自動選択）
- worktree無効時のフォールバック処理
- 注: `rules.branch.mode` のdefaults.tomlへの追加はUnit 001で実施済みが前提

## 境界
- setup-branch.sh 自体のロジック変更は行わない
- worktree機能の新規実装は行わない

## 依存関係

### 依存する Unit
- Unit 001: read-config.sh 改善（依存理由: Unit 001で `rules.branch.mode` のデフォルト値がdefaults.tomlに定義される。ステップ7でread-config.shを使用して設定値を読み取る）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- `[rules.worktree].enabled = false` かつ `mode = "worktree"` 時のフォールバック（→ branch）
- 無効な mode 値（typo等）への警告表示と "ask" へのフォールバック
- 変更対象は prompts/package/ 配下

## 実装優先度
Medium

## 見積もり
小規模（プロンプト変更中心）

## 関連Issue
- #214

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
