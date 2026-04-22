# Unit: update-version.sh 仕様変更のドキュメント・周知

## 概要

Unit 002 で実施した `bin/update-version.sh` の hidden breaking change（`.aidlc/config.toml.starter_kit_version` 上書き廃止 + `aidlc_toml_*` 出力削除）について、CHANGELOG の `#596` 節 / `bin/update-version.sh` のスクリプト先頭コメント / `skills/aidlc/rules.md`「カスタムワークフロー > バージョンファイル更新」セクション / `docs/configuration.md`（`starter_kit_version` 段落、既存時のみ）を追従更新する。利用者がアップグレード時に挙動変化を把握できる状態にする。**README は本 Unit 対象外**（Milestone 関連の README 更新は Unit 007）。

## 含まれるユーザーストーリー

- ストーリー 6b: update-version.sh 仕様変更のドキュメント・周知（#596 周知側）

## 責務（ファイル所有を Unit 007 と明確に分離）

本 Unit は **#596 関連の周知のみ**を扱う。Milestone 運用に関するドキュメント書き換えは Unit 007 の責務。CHANGELOG / `skills/aidlc/rules.md` / `docs/configuration.md` といった共有ドキュメントについては、**セクション単位で所有を分離**する:

- **CHANGELOG（v2.4.0 リリースノート）の `#596` 節のみ**を本 Unit が担当: hidden breaking change として 2 項目を明記
  - 「`bin/update-version.sh` の更新対象から `.aidlc/config.toml.starter_kit_version` を除外」
  - 「`bin/update-version.sh` の出力フォーマットから `aidlc_toml_current` / `aidlc_toml_new` / `aidlc_toml:${VERSION}` 行を削除」
- `bin/update-version.sh` のスクリプト先頭コメント「更新対象」リストを新仕様に追従（`.aidlc/config.toml` の行を削除）。**本ファイルの編集は本 Unit が排他所有**
- `skills/aidlc/rules.md` の「カスタムワークフロー > バージョンファイル更新」セクション（既存）に `starter_kit_version` の正規の書き換え経路（`aidlc-setup` / `aidlc-migrate` / 将来のアップグレード経路に限定）を追記。**rules.md でも本セクションのみが本 Unit 所有**、Milestone 関連セクションは Unit 007 所有
- `docs/configuration.md` に `starter_kit_version` 記述があれば新設計に追従（既存記述がない場合は追加要否を設計時に判断）。**configuration.md でも `starter_kit_version` 関連の段落のみが本 Unit 所有**、サイクル運用 / Milestone 関連セクションは Unit 007 所有
- README は本 Unit の対象外（`bin/update-version.sh` の使用方法説明は README ではなくスクリプト先頭コメントに集約する。Milestone 関連の README 更新は Unit 007）

## 境界

- スクリプト本体の挙動変更は Unit 002 で完了済みである前提（重複実装しない）
- Milestone 運用に関するドキュメント（CHANGELOG の `#597` 節 / README の Milestone 説明 / `rules.md` の Milestone セクション / `configuration.md` のサイクル運用セクション / `guides/issue-management.md` 等）は本 Unit 対象外（Unit 007 所有）
- `aidlc-setup` / `aidlc-migrate` の書き込み経路の実装変更はスコープ外（既存挙動の文書化のみ）
- 翻訳ドキュメント（`docs/translations/`）への波及は本サイクル対象外
- Construction Phase 設計時に CHANGELOG の節構造を確定し、`#596` 節と `#597` 節を物理的に分離して各 Unit が独立して編集できる状態を作る（編集競合の予防）

## 依存関係

### 依存する Unit

- Unit 002: update-version.sh の挙動変更（依存理由: CHANGELOG に記載する内容と script コメントの「更新対象」リストが、Unit 002 の実装結果と整合している必要がある。Unit 002 の確定挙動を基に文書化するため）

### 外部依存

- なし（社内ドキュメントのみ）

## 非機能要件（NFR）

- **パフォーマンス**: 該当なし（ドキュメント変更）
- **セキュリティ**: 機密情報の混入がないこと（`starter_kit_version` の値自体は公開情報）
- **スケーラビリティ**: 該当なし
- **可用性**: CHANGELOG の記述が公開リリース時点で確実に含まれていること（Operations Phase での CHANGELOG 更新フロー（7.2）と整合）

## 技術的考慮事項

- CHANGELOG のフォーマットは既存サイクル（v2.3.5 / v2.3.6）の記載スタイルを踏襲
- 「hidden breaking change」のセクションが既存 CHANGELOG にあるか確認し、なければ「Breaking Changes」または「Notable Changes」相当の見出しを使う
- `skills/aidlc/rules.md` の「バージョンファイル更新」セクションは既存メタ開発ルール記述あり（`bin/update-version.sh --version {{CYCLE}}` の呼び出し例）。新設計記述を追記する形

## 関連Issue

- #596（部分対応：本 Unit はドキュメント・周知のみ。スクリプト挙動変更は Unit 002）

## 実装優先度

Medium（Unit 002 完了後の周知。リリース前必須）

## 見積もり

0.5〜1 時間（CHANGELOG `#596` 節 1 段落 + `bin/update-version.sh` スクリプト先頭コメント + `rules.md`「バージョンファイル更新」セクション追記 + `configuration.md` 既存記述追従、README は対象外）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
