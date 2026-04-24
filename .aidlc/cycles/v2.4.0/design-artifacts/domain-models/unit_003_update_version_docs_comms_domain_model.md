# ドメインモデル: Unit 003 update-version.sh 仕様変更のドキュメント・周知

## 概要

Unit 002 で実施した hidden breaking change の利用者周知の責務範囲を定義する。本 Unit はドキュメント更新のみのため、エンティティ等の DDD 構造は採用せず、**周知ドキュメント所有の責務分離** を中心に定義する。

**重要**: このドメインモデル設計では**コードは書かず**、責務の定義のみを行う。実装は Phase 2 で行う。

## ドメイン責務

### Unit 003: ドキュメント周知（#596 関連のみ）

- **責務**: Unit 002 が実装した `bin/update-version.sh` の hidden breaking change を、利用者がアップグレード時に把握できる状態にする
- **入力**: Unit 002 の確定挙動（`.aidlc/config.toml.starter_kit_version` 上書き廃止 + `aidlc_toml_*` 出力削除）
- **出力**: 4 ファイルの該当セクションへの追記・修正

## 周知ドキュメント所有の責務分離

`#596` 関連の周知ドキュメントは、**ファイル単位ではなくセクション単位** で所有を分離する。同じファイルでも `#597`（Milestone 関連）のセクションは Unit 007 が所有する:

| ファイル | Unit 003 所有セクション（#596 関連） | 他 Unit 所有セクション |
|---------|----------------------------------|-------------------|
| `CHANGELOG.md` | v2.4.0 セクション骨組み + `#596` 節（hidden breaking change 2 項目） | `#597` 節 → Unit 007 / `#588` 節 → Unit 001 完了処理（既に commit 済み） / `#595` 節 → Unit 004 完了処理 |
| `bin/update-version.sh` | スクリプト先頭ヘッダコメント L1-L26（**排他所有**） | （他 Unit 所有なし、本 Unit が排他） |
| `.aidlc/rules.md` | 「カスタムワークフロー > バージョンファイル更新」セクション L80-95 | Milestone 関連セクション → Unit 007 |
| `docs/configuration.md` | `starter_kit_version` 説明（L49） | サイクル運用 / Milestone 関連セクション → Unit 007 |

## 境界

- **Milestone 関連ドキュメント**: Unit 007 所有（CHANGELOG `#597` 節 / README Milestone 説明 / `rules.md` Milestone セクション / `configuration.md` サイクル運用 / `guides/issue-management.md` 等）
- **README.md**: 本 Unit 対象外（`bin/update-version.sh` 使用方法は README ではなくスクリプト先頭コメントに集約する方針）
- **`aidlc-setup` / `aidlc-migrate` 内部ドキュメント**: 既存挙動を維持するため変更しない
- **翻訳ドキュメント**: 本サイクル対象外

## ユビキタス言語

- **hidden breaking change**: 表面的な API シグネチャは変わらないが、出力フォーマットや内部挙動が変化し、依存している利用者の自動化を破壊する変更
- **正規の書き換え経路**: `starter_kit_version` を変更する正当な経路。`aidlc-setup`（初回セットアップ）/ `aidlc-migrate`（v1→v2 マイグレーション）/ 将来のアップグレード経路の 3 つに限定される
- **CHANGELOG セクション骨組み**: `## [X.Y.Z] - YYYY-MM-DD` ヘッダ + `### Added` / `### Changed` / `### Fixed` 等の見出しからなる 1 サイクル分の記述構造
- **引き継ぎタスク**: Construction Phase で発生した「Operations Phase で実施すべき手動作業」を `.aidlc/cycles/{{CYCLE}}/operations/tasks/` に記録するファイル。Operations Phase 01-setup §10 で必ず確認される

## 不明点と質問

なし（計画段階で codex AI レビュー 4 反復を経て path 整合・引き継ぎメカニズム等を確定済み）。
