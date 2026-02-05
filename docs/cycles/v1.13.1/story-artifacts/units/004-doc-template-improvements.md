# Unit: ドキュメント・テンプレート強化

## 概要
CLAUDE.mdのAskUserQuestion機能ガイドを強化し、論理設計テンプレートにスクリプトインターフェース設計セクションを追加する。

## 含まれるユーザーストーリー
- ストーリー5: AskUserQuestion機能の使用ガイド強化
- ストーリー6: 論理設計テンプレートのスクリプトインターフェース設計ガイド追加

## 責務
- CLAUDE.mdに「必ず使用すべき場面」リストを追加
- logical_design_template.mdに「スクリプトインターフェース設計」セクションを追加

## 境界
- 他のプロンプトファイルへの変更は含まない
- 実際のスクリプト実装への影響なし

## ソースファイル管理
- **修正対象**: `prompts/package/prompts/CLAUDE.md`、`prompts/package/templates/logical_design_template.md`（ソース）
- **同期先**: `docs/aidlc/prompts/CLAUDE.md`、`docs/aidlc/templates/logical_design_template.md` はrsync同期で自動更新（Operations Phaseで実施）
- このリポジトリはメタ開発のため、`prompts/package/`がソースオブトゥルース

## 凝集性についての注記
CLAUDE.mdとlogical_design_template.mdは異なるドメインのドキュメントだが、どちらも「ドキュメント・テンプレートの強化」というカテゴリで小規模な変更のため、同一Unitとして扱う。分割のオーバーヘッドの方が大きい。

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
- CLAUDE.mdはClaude Code固有の設定ファイル
- logical_design_template.mdはConstruction Phase Phase 1で使用されるテンプレート
- rsync同期のためprompts/package/配下を修正対象とする

## 実装優先度
Medium（Should-have）

## 見積もり
小規模（ドキュメント2ファイルの修正）

## 関連Issue
- #168
- #165

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
