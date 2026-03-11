# Unit: AIエージェント許可リストの刷新

## 概要

ai-agent-allowlist.md からCodex CLI、Cline、Cursor、jj関連の記述を削除し、Claude CodeとKiro CLIのみの設定ガイドに刷新する。

## 含まれるユーザーストーリー

- ストーリー 1: AIエージェント許可リストの刷新

## 責務

- Codex CLI、Cline、Cursorのセクションおよび関連記述の削除
- jj関連コマンドの許可リスト・設定例からの削除
- 適用範囲、推奨アプローチ、コマンドカテゴリ、参考リンクの整理
- 削除後の内容整合性確認

## 境界

- sandbox-environment.md、skill-usage-guide.md は別Unitで対応
- ガイド以外のファイル（プロンプト、テンプレート等）は対象外

## 依存関係

### 依存する Unit

- なし

### 外部依存

- なし

## 非機能要件（NFR）

- 該当なし（ドキュメント修正のみ）

## 技術的考慮事項

- 編集対象は `prompts/package/guides/ai-agent-allowlist.md`
- セクション番号は削除後に再番号付けが必要

## 実装優先度

High

## 見積もり

小規模（ドキュメント編集のみ）

## 完了条件

- Codex CLI、Cline、Cursorのセクション・記述が0件
- jj関連コマンドの記述が0件
- Claude CodeとKiro CLIの情報のみで構成されている
- セクション番号が連番で整合している

## 関連Issue

なし

---

## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
