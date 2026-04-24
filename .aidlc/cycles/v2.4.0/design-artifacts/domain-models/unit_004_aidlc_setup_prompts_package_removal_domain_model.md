# ドメインモデル: Unit 004 aidlc-setup の prompts/package/ 遺物純削除

## 概要

aidlc-setup スキルのエントリポイント `skills/aidlc-setup/steps/01-detect.md` から、v2.0.5 で削除済みディレクトリ `prompts/package/` への言及（L89-L91）を純削除する。本 Unit はマークダウン記述削除のみのため、エンティティ等の DDD 構造は採用せず、**削除責務と判定フローへの非影響保証** を中心に定義する。

**重要**: このドメインモデル設計では**コードは書かず**、責務の定義のみを行う。実装は Phase 2 で行う。

## ドメイン責務

### Unit 004: 旧ガイダンス文言の純削除

- **責務**: aidlc-setup スキル 01-detect.md L89-L91 から `prompts/package/` ディレクトリ言及を含む 3 行を削除し、CHANGELOG `### Removed` 節に削除事実を記録する
- **入力**:
  - 現行 01-detect.md（L89-L91 に削除対象を含む）
  - v2.0.5 CHANGELOG L482（`prompts/package/` ディレクトリ削除記録、参照のみ）
- **出力**:
  - 削除後 01-detect.md（L89-L91 削除 + 空行整理）
  - v2.4.0 CHANGELOG `### Removed` 節 1 項目追加

## 削除対象と所有関係

| ファイル | Unit 004 所有範囲 | 他 Unit との関係 |
|---------|----------------|---------------|
| `skills/aidlc-setup/steps/01-detect.md` | L89-L91 削除 + 空行整理（**排他所有**） | 他 Unit 所有なし |
| `CHANGELOG.md` | v2.4.0 セクション `### Removed` 見出し新規作成 + `#595` 節 1 項目 | **既存骨組み（commit 2ca41bf7 時点）**: `## [2.4.0] - 2026-04-XX` + `### Changed`（Unit 003 が追加した `#596` 節 2 項目）のみ。`### Added` の `#597` 節（Unit 007 所有予定）/ `### Fixed` の `#588` 節（Unit 001 完了処理所有予定）/ Unit 005/006/007 完了処理が追加し得る他見出しは **未追加**（将来追加予定） |

## 判定フローへの非影響保証

L89-L91 は「もし現在のディレクトリが `ai-dlc-starter-kit` リポジトリ内の場合」の説明文であり、AI への判定指示ではない。早期判定（L93 以降）は独立フローで以下の述語を使用する:

| 早期判定 | 述語 | 削除影響 |
|---------|------|---------|
| #1 セットアップ済み | `.aidlc/config.toml` 存在 | なし |
| #2 v1 移行 | `docs/aidlc.toml` または `docs/aidlc/project.toml` 存在 | なし |
| #3 初回セットアップ | 上記 3 ファイルすべて不在 | なし |

ただし、ケース (d)「`ai-dlc-starter-kit` クローン直後 + `.aidlc/config.toml` なし」では、L89-L91 が果たしていた事前ガイダンス（メタ開発判定 vs 通常利用は対象プロジェクトへ移動）が消える。判定ロジックは無変化だが、新規ユーザーが ai-dlc-starter-kit クローン直下で誤って setup を進める余地は増える（plan のリスク評価で Low-Medium と記録）。

## 境界

- **代替判定条件追加**: 本 Unit 対象外（純削除のみ）。v2.5.0 以降のバックログ Issue で別扱い（DR-007）
- **aidlc-setup の他セクション変更**: 本 Unit 対象外（バージョン比較・cycle.mode 等の変更は本サイクルでは扱わない）
- **DR-003（純削除固定）/ DR-007（代替判定条件追加は本サイクル対象外）**: Inception 完了処理で `inception/decisions.md` に集約記録済み、本 Unit からは追加実施なし
- **README.md / 翻訳ドキュメント**: 本 Unit 対象外

## ユビキタス言語

- **prompts/package/**: v1 時代のソース配布構造（`docs/aidlc/` のコピー元）。v2.0.5 で削除（PR #449 / CHANGELOG L482）
- **メタ開発モード**: ai-dlc-starter-kit リポジトリ自体の開発を行う運用。v1 では `prompts/package/` 存在で識別、v2 では `.aidlc/config.toml` で識別
- **早期判定**: 01-detect.md L93 以降の自動分岐ロジック。`.aidlc/config.toml` / `docs/aidlc.toml` / `docs/aidlc/project.toml` の存在で 3 分岐
- **事前ガイダンス**: L89-L91 が果たしていた説明文（早期判定の前にユーザーへ提示される情報、判定ロジックそのものではない）

## 不明点と質問

なし（plan 段階で codex AI レビュー 5 反復を経て検証スコープ・影響評価を確定済み）。
