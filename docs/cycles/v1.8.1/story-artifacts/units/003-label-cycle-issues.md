# Unit: label-cycle-issues.sh新規作成

## 概要

複数Issueへのサイクルラベル付けを一括で行うスクリプトを新規作成し、inception.mdに統合する。

## 含まれるユーザーストーリー

- ストーリー 3: label-cycle-issues.shを新規作成

## 責務

- label-cycle-issues.shスクリプトの新規作成
- Unit定義ファイルからIssue番号を抽出する機能
- 抽出した各Issueにサイクルラベルを一括付与する機能
- inception.mdでスクリプトを呼び出すように修正
- 変更後のinception.mdがmarkdownlintをパスすることを確認

## 境界

- issue-ops.sh自体の修正は行わない（内部で呼び出す）
- ラベルの作成は行わない（cycle-label.shで対応済み）

## 依存関係

### 依存するUnit

- なし

### 外部依存

- issue-ops.sh（既存スクリプト、内部で呼び出し）
- GitHub CLI（gh）

## 非機能要件（NFR）

- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項

- Unit定義ファイルパス: `docs/cycles/{{CYCLE}}/story-artifacts/units/*.md`
- Issue番号抽出パターン: `^- #[0-9]+`
- ラベル形式: `cycle:{{CYCLE}}`
- 出力形式: `issue:{番号}:labeled:cycle:{サイクル}`
- Issue番号が見つからない場合は正常終了（エラーにしない）

## 実装優先度

High

## 見積もり

中規模（新規スクリプト作成 + inception.md修正）

---

## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
