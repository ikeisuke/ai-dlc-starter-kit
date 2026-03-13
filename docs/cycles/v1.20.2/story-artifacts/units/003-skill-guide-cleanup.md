# Unit: スキル利用ガイドのツール記述整理

## 概要

skill-usage-guide.md からCodex CLI、Gemini CLIの記述を削除し、Claude CodeとKiro CLIのみの内容に整理する。

## 含まれるユーザーストーリー

- ストーリー 3: スキル利用ガイドのツール記述整理

## 責務

- Codex CLIの使用方法記述の削除
- Gemini CLIの使用方法記述の削除
- 削除後の内容整合性確認

## 境界

- ai-agent-allowlist.md、sandbox-environment.md は別Unitで対応
- ガイド以外のファイルは対象外

## 依存関係

### 依存する Unit

- なし

### 外部依存

- なし

## 非機能要件（NFR）

- 該当なし（ドキュメント修正のみ）

## 技術的考慮事項

- 編集対象は `prompts/package/guides/skill-usage-guide.md`

## 実装優先度

High

## 見積もり

小規模（ドキュメント編集のみ）

## 完了条件

- Codex CLI、Gemini CLIの使用方法記述が0件
- Claude CodeとKiro CLIの情報のみで構成されている
- 削除後の内容が整合している

## 関連Issue

なし

---

## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-12
- **完了日**: 2026-03-12
- **担当**: -
