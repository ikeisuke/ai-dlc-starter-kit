# Unit: setup-prompt.md関連の変更

## 概要
setup-prompt.mdを改善し、旧形式バックログ移行をInception Phaseから移動し、アップグレード完了メッセージを更新する。

## 含まれるユーザーストーリー
- ストーリー4: 旧形式バックログ移行のアップグレード処理への移動
- ストーリー7: アップグレード完了メッセージの更新

## 責務
- inception.mdから旧形式バックログ移行ステップを削除
- setup-prompt.mdのアップグレードセクションに移行処理を追加
- setup-prompt.mdの完了メッセージを「start inception」に更新

## 境界
- アップグレードスキル化は別Unit（Unit 005）で対応
- operations.md/construction.mdへの変更は別Unit（Unit 002）で対応
- Lite版プロンプト（`prompts/package/prompts/lite/`）は対象外（別サイクルで対応）

## ソースファイル管理
- **修正対象**: `prompts/package/prompts/inception.md`、`prompts/setup-prompt.md`（ソース）
- **同期先**: `docs/aidlc/prompts/inception.md` はrsync同期で自動更新（Operations Phaseで実施）
- 注: `prompts/setup-prompt.md` は同期対象外（ルート直下のセットアップ専用ファイル）
- このリポジトリはメタ開発のため、`prompts/package/`がソースオブトゥルース

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
- inception.mdとsetup-prompt.mdの両方を変更
- 旧形式バックログ移行は「旧形式ファイルが存在する場合のみ」の条件を明記
- rsync同期のためprompts/package/prompts/配下を修正対象とする

## 実装優先度
Medium（Should-have + Could-have）

## 見積もり
小規模（ドキュメント2ファイルの修正）

## 関連Issue
- #163
- #160

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-05
- **完了日**: 2026-02-05
- **担当**: Claude
