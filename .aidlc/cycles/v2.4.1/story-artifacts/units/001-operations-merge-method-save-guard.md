# Unit: Operations 7.13 merge_method 設定保存ガード追加

## 概要

Operations Phase §7.13 で `merge_method=ask` 選択後に `write-config.sh` が `.aidlc/config.toml` を書き換えた際、その変更がマージ前の PR に反映されず未コミットで残る bug（#601）を、マージ実行前のガード手順（案B）で解消する。

## 含まれるユーザーストーリー

- ストーリー 1: merge_method 設定保存が PR に追従する

## 責務

- `skills/aidlc/steps/operations/operations-release.md` §7.13 に、`write-config.sh` 実行後の未コミット差分検出ガードを追加する
- 3 分岐（コミット+push / follow-up PR / 破棄）の具体手順をステップ手順書に明示する
- 各分岐の終了条件（マージ実行に進む前提条件）を手順書内に記述する
- 「案B を採用した」旨をコメントまたは説明文で明示する

## 境界

- Inception Phase 側で `merge_method` を事前確定する案 A（大規模リファクタリング）は扱わない（v2.5.0 以降で別途検討）
- `operations-release.sh` などの実行スクリプト本体の変更は行わない（手順書の明確化のみ）
- `AskUserQuestion` の既存呼び出し仕様・`automation_mode` との関係は変更しない
- `04-completion.md` L42 の「post-merge 改変禁止ルール」は既存のまま維持し拡張しない

## 依存関係

### 依存する Unit

- なし

### 外部依存

- 既存の `skills/aidlc/scripts/write-config.sh`
- 既存の `AskUserQuestion` 仕様（SKILL.md「ユーザー選択」種別）

## 非機能要件（NFR）

- **パフォーマンス**: 手順書改訂のみで実行時間への影響なし
- **セキュリティ**: `.aidlc/config.toml` の内容はコミットする値に限定し、機密情報を含まない前提を維持
- **スケーラビリティ**: 該当なし
- **可用性**: `gh_status != available` の分岐は既存仕様（手動案内）を維持

## 技術的考慮事項

- §7.13 直後には「マージ実行確認」ステップがあるため、ガードは `write-config.sh` の出力ブロックとマージ実行確認の間に挿入する
- ガード内で提示する 3 択は `AskUserQuestion` の「ユーザー選択」種別を用いる（`automation_mode` に関わらず対話必須）
- 「follow-up PR」分岐では jailrun v0.3.1 の実運用手順（`git stash` → 新ブランチ → PR 作成）をリファレンスとして記述
- `history/operations.md` への follow-up PR 番号記録は `/write-history` スキル経由で行う
- **検証責務**: 実装後に 3 分岐（コミット+push / follow-up PR / 破棄）の終了条件が既存の 7.13 以降フロー（マージ実行確認・マージ実行）上で矛盾なく成立することを walkthrough で確認する。加えて、jailrun v0.3.1 の再発ケース（`merge_method=ask` + 保存選択 + マージ直前に設定差分残存）を手順レベルで追試し、差分が残らないことを確認する

## 関連Issue

- #601

## 実装優先度

High

## 見積もり

手順書改訂 0.5〜1 日 + 3 分岐 walkthrough / 再発ケース追試 0.25〜0.5 日 の合計 0.75〜1.5 日規模

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
