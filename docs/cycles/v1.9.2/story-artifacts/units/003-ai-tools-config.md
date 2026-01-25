# Unit: ai_tools設定による複数AIサービス対応

## 概要

aidlc.tomlでAIレビューに使用するサービスの優先順位を設定できるようにする。

## 含まれるユーザーストーリー

- ストーリー3: 複数AIサービスのレビュー対応

## 責務

- review-flow.mdにai_tools設定セクションを追加
- 利用可否判定ロジックの明文化
- 後方互換性の維持

## 対象ファイル

- `prompts/package/prompts/common/review-flow.md`（編集対象）
- `docs/aidlc/prompts/common/review-flow.md`（Operations Phaseでrsync同期）

## 境界

- 実際のレビュー実行ロジックの変更は最小限
- 新規AIツールの追加は対象外

## 依存関係

### 依存する Unit

なし（依存する他のUnitがない）

### 外部依存

なし

## 非機能要件（NFR）

- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 新規ツール追加に対応可能な設計
- **可用性**: 該当なし

## 技術的考慮事項

- 対応ツール名リスト: codex, claude, gemini
- エラーハンドリング: 空配列、未対応ツール名、不正な型

**ai_tools設定スキーマ**:

```toml
# aidlc.toml内
[mcp_review]
mode = "required"  # 既存設定
ai_tools = ["codex", "claude", "gemini"]  # 新規追加
```

| フィールド | 型 | デフォルト | 説明 |
|-----------|-----|----------|------|
| ai_tools | array of string | `["codex"]` | AIレビューに使用するツールの優先順位リスト |

## 実装優先度

High

## 見積もり

中規模な変更

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
