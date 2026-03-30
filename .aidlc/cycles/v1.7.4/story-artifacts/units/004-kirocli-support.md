# Unit: KiroCLI対応

## 概要
KiroCLIでAI-DLCを使用するための設定案内をAGENTS.mdに追加する。

## 含まれるユーザーストーリー
- ストーリー6: KiroCLI対応 (#57)

## 関連Issue
- #57

## 責務
- KiroCLI向けの設定案内の追加
- `@` 参照記法が機能しない旨の説明
- Kiroエージェントへの `resources` 設定確認手順の記載

## 境界
- KiroCLI固有の設定ファイル（.kiro/agents.toml等）の直接編集は含まない
- KiroCLIの詳細な使い方は含まない

## 依存関係

### 依存する Unit
- Unit 005: プロンプト最適化（依存理由: 両方がAGENTS.mdを編集するため、先にUnit 005で質問深掘りルールを追加してから本Unitを実行する）

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- 編集先: `prompts/package/prompts/AGENTS.md`（Operations Phaseでrsyncにより `docs/aidlc/` に反映）
- 参照: <https://kiro.dev/docs/cli/custom-agents/configuration-reference/#resources-field>
- ユーザー向け案内内容: Kiroエージェントにresources設定で `docs/aidlc/prompts/AGENTS.md` を読み込ませる

## 実装優先度
Medium

## 見積もり
小規模（ドキュメント追加のみ）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-01-14
- **完了日**: 2026-01-14
- **担当**: AI
