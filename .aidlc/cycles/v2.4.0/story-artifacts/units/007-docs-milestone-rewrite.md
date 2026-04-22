# Unit: 公開ドキュメントのサイクル運用記述を Milestone 参照に書き換え

## 概要

#597 Unit C 相当。Unit 005 / 006 で更新した Inception/Operations の Milestone 手順に整合する形で、公開ドキュメント（`docs/configuration.md` / `README.md` / `skills/aidlc/guides/` / `skills/aidlc/rules.md`）のサイクル運用記述を Milestone ベースに書き換える。旧サイクル（v2.3.6 以前）の併記は残さず、過去サイクルの追跡は CHANGELOG / `.aidlc/cycles/v*/` ディレクトリ / 残置された `cycle:v*` ラベル（deprecated）で行うことを CHANGELOG に明記する。

## 含まれるユーザーストーリー

- ストーリー 3: ドキュメント更新によるユーザー周知（Unit C 由来）

## 責務（ファイル所有を Unit 003 と明確に分離）

本 Unit は **#597 Milestone 運用関連の公開ドキュメント書き換えのみ**を扱う。`#596` 関連の周知（`bin/update-version.sh` 関連の `rules.md` / `configuration.md` 段落、CHANGELOG の `#596` 節）は Unit 003 の責務。

- `docs/configuration.md` の **サイクル運用セクション**（`cycle:v*` 言及・`label-cycle-issues.sh` 言及）を Milestone 参照に書き換え。`starter_kit_version` 関連段落（Unit 003 所有）は触らない
- `README.md` の **サイクル運用記述箇所**を Milestone 運用前提に更新（Milestone 進捗バッジは v2.4.0 では追加しない、追加検討は v2.5.0 以降のバックログ）。`bin/update-version.sh` 関連の README 記述は本 Unit 対象外（Unit 003 が `bin/update-version.sh` のスクリプト先頭コメントに集約する方針）
- `skills/aidlc/guides/issue-management.md` のサイクルラベル付与記述を Milestone 紐付け手順に書き換え
- `skills/aidlc/guides/backlog-management.md` を更新: 「Backlog（Milestone 未割当）」の運用説明追加、サイクル開始時の Milestone 紐付けフロー記述
- `skills/aidlc/guides/backlog-registration.md` を更新: 新規 Issue 登録時に Milestone 未割当を初期状態とする旨を明記
- `skills/aidlc/guides/glossary.md` に「Milestone」エントリ追加（GitHub Milestone を AI-DLC のサイクル管理単位として用いる定義）、「サイクルラベル」エントリは「v2.4.0 で deprecated、Milestone に置換」の注記付きで残置
- `skills/aidlc/rules.md` の **運用ルール記述のサイクル運用前提を Milestone に書き換え**（Milestone 関連セクションのみ）。「カスタムワークフロー > バージョンファイル更新」セクション（Unit 003 所有）は触らない
- CHANGELOG（v2.4.0 リリースノート）の **`#597` 節** に以下を排他所有として記述（`#596` 節は Unit 003 所有）:
  - 旧サイクル（v2.3.6 以前）の併記を残さない方針、過去サイクル追跡は CHANGELOG / `.aidlc/cycles/v*/` ディレクトリ / `cycle:v*` ラベル（deprecated 物理残置）で行う旨
  - **`cycle-label.sh` / `label-cycle-issues.sh` の deprecation 記載**（Unit 005 から本 Unit へ委譲された項目。Unit 005 完了時に依頼内容として確定する）
  - Inception/Operations フローの Milestone 運用本採用の概要

## 境界

- Inception Phase の Markdown ステップ更新は Unit 005 で扱う
- Operations Phase の Markdown ステップ更新は Unit 006 で扱う
- `bin/update-version.sh` 関連のドキュメント更新は本 Unit 対象外（Unit 003 所有）
- 翻訳ドキュメント（`docs/translations/`）への波及は本サイクル対象外
- スクリプト本体の挙動変更は本 Unit 対象外（Unit 005 で deprecation 注記、Unit 006 でフロー組込み）
- Construction Phase 設計時に CHANGELOG の節構造を確定し、`#596` 節（Unit 003 所有）と `#597` 節（本 Unit 所有）を物理的に分離して独立編集できる状態を作る

## 依存関係

### 依存する Unit

- Unit 005: Inception Phase へ Milestone 作成ステップを追加（依存理由: ドキュメント側で参照する Milestone 作成手順の確定形が Unit 005 で得られる）
- Unit 006: Operations Phase へ Milestone close + 紐付け確認を組込み（依存理由: ドキュメント側で参照する Milestone close 手順の確定形が Unit 006 で得られる）

### 外部依存

- なし（社内ドキュメントのみ）

## 非機能要件（NFR）

- **パフォーマンス**: 該当なし（ドキュメント変更）
- **セキュリティ**: 機密情報の混入がないこと
- **スケーラビリティ**: 該当なし
- **可用性**: 公開ドキュメントの記述が Unit 005 / 006 の手順と整合していること（実装と乖離しない）

## 技術的考慮事項

- 設計レビュー時のガイド照合ルール（`skills/aidlc/rules.md`「設計レビュー時のガイド照合ルール」）を適用し、過剰な互換記述（旧運用の説明残置）が混入しないよう確認する
- `glossary.md` の「サイクルラベル」エントリ残置は、過去ドキュメントとの参照リンク切れを避ける目的。「v2.4.0 で deprecated」の注記を必ず付ける
- README のバッジ追加可否は本 Unit では「追加しない」に固定済み（ストーリー 3 受け入れ基準）

## 関連Issue

- #597（部分対応：Unit C 担当部分。Unit A は Unit 006、Unit B は Unit 005、Unit D-F は本サイクル対象外）

## 実装優先度

Medium（Unit 005 / 006 完了後の周知、リリース前必須）

## 見積もり

2〜3 時間（5〜7 ファイル編集 + CHANGELOG 整合確認）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
