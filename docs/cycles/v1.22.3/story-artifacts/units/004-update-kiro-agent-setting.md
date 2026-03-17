# Unit: Kiro agent設定のアップデート

## 概要
`.kiro/agents/aidlc-poc.json` をツール権限・リソース参照を含む詳細な設定にアップデートする。

## 含まれるユーザーストーリー
- ストーリー 4: Kiro agent設定のアップデート

## 責務
- `.kiro/agents/aidlc-poc.json` を所定のJSON設定にアップデート
- name、description、tools、allowedTools、toolsSettings、resourcesの全フィールドを設定

## 境界
- `prompts/package/kiro/agents/aidlc.json` の更新は行わない（Operations Phase時にaidlc-setupで同期）
- Kiro以外のエージェント環境の設定は対象外

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 影響なし
- **セキュリティ**: allowedCommandsでコマンド実行範囲を制限
- **スケーラビリティ**: 影響なし
- **可用性**: 影響なし

## 技術的考慮事項
- 正本は `.kiro/agents/aidlc-poc.json`
- `autoAllowReadonly: true` により読み取り専用コマンドは自動許可

## 実装優先度
Medium

## 見積もり
小規模（JSONファイルの更新）

## 関連Issue
- #344

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-17
- **完了日**: 2026-03-17
- **担当**: @ai
