# Unit: セットアッププロンプトパス記録

## 概要
スターターキットセットアップ時に使用したプロンプトのパスを `docs/aidlc.toml` に記録し、アップグレード時に参照できるようにする。

## 含まれるユーザーストーリー
- ストーリー 4-1: セットアッププロンプトパスの記録

## 責務
- `docs/aidlc.toml` への `[setup]` セクション追加
- `[setup].prompt_path` へのパス記録処理（`prompts/setup-prompt.md`）
- Operations Phase完了時のメッセージで `[setup].prompt_path` を参照・表示

## 境界
- サイクルセットアップ（`docs/aidlc/prompts/setup.md`）への変更は対象外

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- 既存の `docs/aidlc.toml` 構造を維持しつつ `[setup]` セクションを追加
- スターターキットセットアップとサイクルセットアップの区別を明確に

## 参考ファイル
- `prompts/setup-prompt.md`（スターターキットセットアップ - パス記録処理追加対象）
- `prompts/package/prompts/operations.md`（Operations Phase - 完了メッセージ修正対象）
- `docs/aidlc.toml`（設定ファイル - セクション追加対象）
- `docs/cycles/backlog/feature-setup-prompt-path-recording.md`（バックログ）

## 実装優先度
Medium

## 見積もり
小（toml更新 + プロンプト2箇所修正）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
