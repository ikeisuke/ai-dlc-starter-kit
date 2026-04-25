# Unit: Construction Squash ステップの誤省略抑止

## 概要

Construction Phase 完了処理のステップ 7「Squash（コミット統合）」が「【オプション】」と表記されているため AI エージェントが省略可能と誤解釈し、`squash_enabled=true` 環境でも Squash がスキップされる事故（#594）を、ラベル除去と `commit-flow.md` 冒頭の前提チェック追加で解消する。

## 含まれるユーザーストーリー

- ストーリー 3: Construction Squash ステップが誤省略されない

## 責務

- `skills/aidlc/steps/common/commit-flow.md` の「Squash統合フロー」冒頭に前提チェックセクションを追加し、`rules.git.squash_enabled` を確認したうえで `false` または未設定時は `squash:skipped:disabled` を返してフロー終了、`true` のときのみ次のステップへ進むロジックを明示する
- `skills/aidlc/steps/construction/04-completion.md` ステップ 7 の見出しから「【オプション】」ラベルを除去し、「`squash_enabled=true` の場合は必須」と明記する
- 既存の `squash:success` / `squash:skipped` / `squash:error` シグナル分岐は維持する

## 境界

- `skills/squash-unit/SKILL.md` 側に分岐ロジックを追加しない（呼び出し側責任を維持）
- **主対象は Construction Phase の Unit 完了処理**だが、共有ファイル `commit-flow.md` の前提チェック追加に伴う Inception Phase 側への同等効果（フェーズ完了時の Squash 前提チェック）は意図した副次影響として許容する。Inception 固有手順（`inception/05-completion.md` 等）への追加変更は行わない
- ケーススタディ（visitory の Unit 003 / 004 事例）を `guides/` に追加することはしない

## 依存関係

### 依存する Unit

- なし

### 外部依存

- 既存の `scripts/read-config.sh`（`rules.git.squash_enabled` の取得）
- `/squash-unit` スキル（無条件 squash 実行）

## 非機能要件（NFR）

- **パフォーマンス**: 手順書改訂のみで実行時間への影響なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: `squash_enabled=false` 環境への影響がゼロ（現状のスキップ動作と等価）であること

## 技術的考慮事項

- `commit-flow.md` の「Squash統合フロー」冒頭で `rules.git.squash_enabled` の取得方法（`scripts/read-config.sh rules.git.squash_enabled`）と exit code の扱いを具体化する
- `squash:skipped:disabled` の戻り値が既存の `squash:skipped` フローと整合するよう、`04-completion.md` の後続分岐（ステップ 7a / ステップ 8）への影響を事前レビューする
- `04-completion.md` ステップ 7 の見出しを更新したときに、目次や相互参照で「【オプション】」を引用している箇所がないか `grep` で確認する

## 関連Issue

- #594

## 実装優先度

Medium

## 見積もり

手順書改訂のみで 0.5 日規模

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
