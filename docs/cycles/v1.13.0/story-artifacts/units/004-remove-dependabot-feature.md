# Unit: Dependabot機能削除

## 概要
Dependabot PR確認機能を削除し、メンテナンスコストを削減してコードベースをシンプルに保つ。

## 含まれるユーザーストーリー
- ストーリー9: Dependabot PR確認機能の削除

## 責務
- inception.mdからDependabot PR確認ステップを削除
- check-dependabot-prs.shスクリプトを削除
- aidlc.tomlテンプレートから[inception.dependabot]セクションを削除
- 関連ドキュメントの更新
- 【追加】アップグレード時に既存の`[inception.dependabot].enabled = true`設定をcycles/rules.mdに移行する機能を追加

## 境界
- 既存プロジェクトのaidlc.tomlからの設定削除は対象外（後方互換性維持）

## 依存関係

### 依存するUnit
なし

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- `prompts/package/prompts/inception.md`からステップ13（Dependabot PR確認）を削除
- `prompts/package/bin/check-dependabot-prs.sh`を削除
- `prompts/setup/templates/aidlc.toml.template`から[inception.dependabot]セクションを削除
- 既存プロジェクトで設定が残っていても無視されるようにする（後方互換性）

## 実装優先度
Medium

## 見積もり
小（削除のみ）

## 関連Issue
Closes #96

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-05
- **完了日**: 2026-02-05
- **担当**: @claude
