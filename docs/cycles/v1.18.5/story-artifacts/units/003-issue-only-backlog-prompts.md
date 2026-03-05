# Unit: issue-onlyモード時のプロンプト修正

## 概要

`backlog.mode=issue-only`時にローカルバックログファイルの探索・操作をスキップするようプロンプトを修正する。

## 含まれるユーザーストーリー

- ストーリー 3: issue-onlyモード時のローカルバックログ操作排除 (#272)（プロンプト修正部分）

## 関連Issue

- #272

## 責務

正本パス（`prompts/package/prompts/`配下）を編集する:

- `prompts/package/prompts/inception.md`のバックログ関連3箇所にモードチェックを追加
- `prompts/package/prompts/construction.md`のバックログ確認1箇所にモードチェックを追加
- `prompts/package/prompts/operations.md`のバックログ整理2箇所（+付随操作）にモードチェックを追加

**注**: `docs/aidlc/`への反映はOperations PhaseのrsyncまたはUnit 001修正後のupgrade-aidlc.shで実施

## 境界

- 既存ローカルバックログファイルの削除は含まない（Unit 004で対応）
- `review-flow.md`のバックログ自動登録ロジックは既にモードチェック済みのため変更不要
- `init-cycle-dir.sh`は既にissue-only時スキップ済みのため変更不要

## 依存関係

### 依存するUnit

- なし

### 外部依存

- なし

## 非機能要件（NFR）

- **パフォーマンス**: N/A（プロンプト変更のみ）
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項

- プロンプトファイルの変更のため、テストは手動検証が中心
- `$()` コマンド置換禁止ルールに準拠すること
- `backlog.mode`の値が未設定・不正値の場合は`git`として扱う既存ルールを維持

## 実装優先度

High

## 見積もり

小（プロンプトファイル3ファイルの修正）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
