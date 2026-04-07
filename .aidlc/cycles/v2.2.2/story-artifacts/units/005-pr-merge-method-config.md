# Unit: PRマージ方法設定化

## 概要

config.tomlでPRマージ方法を事前設定可能にし、Operations Phase毎回のマージ方法確認を省略できるようにする。

## 含まれるユーザーストーリー

- ストーリー 5: PRマージ方法設定化（#538）

## 責務

- defaults.tomlに `rules.git.merge_method = "ask"` を追加
- operations-release.mdのPRマージ箇所を修正（設定値に応じた分岐追加）
- preflight.mdの設定値取得にmerge_methodを追加

## 境界

- Operations Phase全体の再設計
- マージ後のフロー（post-merge-sync等）の変更

## 依存関係

### 依存する Unit

なし

### 外部依存

なし

## 非機能要件（NFR）

該当なし

## 技術的考慮事項

- 有効値: "merge" | "squash" | "rebase" | "ask"
- 無効値は "ask" にフォールバック（警告表示付き）
- マージ失敗時はエラー表示→ユーザーに方法選択を求める

## 関連Issue

- #538

## 実装優先度

Medium

## 見積もり

中（3-4ファイル修正: defaults.toml, operations-release.md, preflight.md）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
