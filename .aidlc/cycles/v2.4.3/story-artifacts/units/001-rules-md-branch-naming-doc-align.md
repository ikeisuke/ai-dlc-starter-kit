# Unit: rules.md ブランチ運用文言の実装整合（#612）

## 概要

`.aidlc/rules.md` に残存する旧表記 `upgrade/vX.X.X` を、実装で稼働している `chore/aidlc-v<version>-upgrade` 命名に整合させる。あわせて `aidlc-setup` / `aidlc-migrate` SKILL.md・関連ステップに「ダウンストリーム向け運用 vs スターターキット自身は `cycle/vX.X.X`」の役割対比を明記し、用途の混同を構造的に解消する。命名のリネーム作業は行わない（実装は v2.4.2 で既に新命名で稼働済み）。

## 含まれるユーザーストーリー

- ストーリー 1: アップグレードブランチ運用の意図明示（#612）

## 責務

- `.aidlc/rules.md` のブランチ運用フロー文言（L274 周辺）を `chore/aidlc-v<version>-upgrade` 命名に整合
- ダウンストリーム向け / スターターキット自身向けの役割対比を文言で追加
- `aidlc-setup` / `aidlc-migrate` SKILL.md および関連ステップ（必要箇所）の文言補強
- `aidlc-migrate` 配下のブランチ命名関連文言を grep で全洗い出しし、対比節追加要否を判断・記録
- 最終的に setup / migrate 双方の運用文言整合（grep 差分が解消されていること）を検証し、結果を design.md または history に記録

## 境界

- 実装側のブランチ命名変更（リネーム）は対象外（既に新命名で稼働中）
- 過去サイクルで作成された `upgrade/v*` ブランチ（既存）の処理は対象外
- スターターキット自身向けの `aidlc-setup` 抑止ロジック（Intent 案 A）は対象外
- `bin/post-merge-sync.sh` の対応プレフィックス追加は最小限とし、未対応プレフィックスがある場合のみ最小修正

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `gh`（変更影響なし）
- `git`（変更影響なし）

## 非機能要件（NFR）

- **パフォーマンス**: ドキュメント変更のため影響なし
- **セキュリティ**: 影響なし
- **スケーラビリティ**: 影響なし
- **可用性**: 影響なし

## 技術的考慮事項

- 主な変更はMarkdown文言のみ。実装ロジック変更を伴わない
- grep ベースで対象箇所を網羅特定する。基本パターン: `grep -rn "upgrade/v" .aidlc/rules.md skills/aidlc-setup/ skills/aidlc-migrate/`、`aidlc-migrate` 配下の追加確認用パターン: `grep -rn "upgrade/v\|chore/aidlc-v" skills/aidlc-migrate/`（ストーリー1受け入れ基準と整合）
- 役割対比の表現は v2.4.0 の Milestone 運用本採用 / v2.4.2 の post-merge フォローアップと整合させる
- 文言の構造（節立て・対比表）は Construction Phase の design.md で確定する

## 関連Issue

- #612

## 実装優先度

High

## 見積もり

S（Small）: 文言整合のみ。Construction Phase で 1 セッション程度

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-28
- **完了日**: 2026-04-28
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
