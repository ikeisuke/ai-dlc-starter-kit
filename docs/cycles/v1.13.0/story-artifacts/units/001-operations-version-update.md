# Unit: Operations Phase version.txt更新

## 概要
Operations Phaseのリリース準備ステップにversion.txt更新手順を明示化し、バージョン更新漏れを防止する。

## 含まれるユーザーストーリー
- ストーリー7: Operations Phaseにversion.txt更新ステップ追加

## 責務
- Operations Phaseのステップ6（リリース準備）にversion.txt更新手順を追加
- AI-DLCスターターキット自体のリリース時のみ適用される条件分岐

## 境界
- version.txt以外のバージョン管理（package.json等）は対象外
- 一般プロジェクトのバージョン管理は既存の「バージョン確認」ステップで対応

## 依存関係

### 依存するUnit
なし

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A（プロンプト修正のみ）
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- `prompts/package/prompts/operations.md`のステップ6に追記
- `project.name = "ai-dlc-starter-kit"`の判定を追加
- version.txtとdocs/aidlc.tomlの両方を更新する手順

## 実装優先度
High

## 見積もり
小（プロンプト修正のみ）

## 関連Issue
Closes #158

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
