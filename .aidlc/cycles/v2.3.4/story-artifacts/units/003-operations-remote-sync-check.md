# Unit: Operations Phase リモート同期チェック追加

## 概要

Operations Phase開始時にリモート同期チェックを追加し、古いコードベースで作業を進めるリスクを低減する。併せて取り込み漏れの原因調査を実施し、設計ドキュメントに記録する。

## 含まれるユーザーストーリー

- ストーリー 3: Operations Phaseのリモート同期チェック追加

## 責務

- Operations Phase開始時（`steps/operations/01-setup.md`）にリモート同期チェックステップを追加
- behind件数が1以上の場合、AskUserQuestionで「取り込む / スキップして続行」を表示
- `git fetch` 失敗時・upstream未設定時のスキップ処理と警告表示
- 取り込み漏れの原因調査と `.aidlc/cycles/v2.3.4/construction/units/` 配下の設計ドキュメントへの記録（原因、再現条件、対策方針）
- `setup-branch.sh` の `check_main_freshness()` と同等のアプローチで inline git操作（`git fetch` + `git rev-list HEAD..@{u}`）によりチェック。既存 `verify-git` の未pushコミット検出（ローカル→リモート方向）とは補完関係にある

## 境界

- `operations-release.sh` スクリプト本体の変更は含まない（既存機能の再利用のみ）
- Operations Phase以外のフェーズへのリモート同期チェック追加は含まない

## 依存関係

### 依存する Unit

- Unit 002: 推奨・提案応答確保ルール追加（依存理由: チェック結果表示後の応答確保ルールをUnit 002で定義するため）

### 外部依存

なし

## 非機能要件（NFR）

- **パフォーマンス**: チェックは軽量であること（`git fetch` + 差分確認程度）
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: オフライン環境でスキップ可能であること

## 技術的考慮事項

- 既存の `operations-release.sh verify-git` の `remote-sync` チェックロジックを再利用可能か検討
- Operations Phase開始時のチェックはブロッカーではなく推奨レベル（warn severity）
- Inception Phase ステップ9-3 の `setup-branch.sh` の `main_status` パターンとの一貫性

## 関連Issue

- #571

## 実装優先度

High

## 見積もり

中（調査 + ステップファイル修正 + 設計ドキュメント記録）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-14
- **完了日**: 2026-04-14
- **担当**: AI
- **エクスプレス適格性**: -
- **適格性理由**: -
