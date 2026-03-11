# Unit: サンドボックス環境ガイドのツール記述整理

## 概要

sandbox-environment.md からCodex CLI、Cline、Cursor、Gemini CLIの記述を削除し、Claude CodeとKiro CLIのみの内容に整理する。

## 含まれるユーザーストーリー

- ストーリー 2: サンドボックス環境ガイドのツール記述整理

## 責務

- Codex CLI、Cline、Cursor、Gemini CLIの認証設定・sandbox設定記述の削除
- 参考リンクから削除対象ツールのリンクを削除
- 削除後の内容整合性確認

## 境界

- ai-agent-allowlist.md、skill-usage-guide.md は別Unitで対応
- ガイド以外のファイルは対象外

## 依存関係

### 依存する Unit

- なし

### 外部依存

- なし

## 非機能要件（NFR）

- 該当なし（ドキュメント修正のみ）

## 技術的考慮事項

- 編集対象は `prompts/package/guides/sandbox-environment.md`

## 実装優先度

High

## 見積もり

小規模（ドキュメント編集のみ）

## 完了条件

- Codex CLI、Cline、Cursor、Gemini CLIの記述が0件
- Claude CodeとKiro CLIの情報のみで構成されている
- 参考リンクから削除対象ツールのリンクが除去されている

## 関連Issue

なし

---

## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
