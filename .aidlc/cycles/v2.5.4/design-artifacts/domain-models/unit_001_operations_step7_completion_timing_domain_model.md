# ドメインモデル: Operations §7 ステップ7「完了」更新タイミング

## 概要

Operations Phase の **ステップ7「完了」状態** に関するドキュメント・ドメイン語彙を整理する。本 Unit は docs / template 改訂のため、ここでの「ドメイン」は「Operations Phase 進捗管理に登場する状態ラベル / 遷移点 / ドキュメント責務レイヤ」のドキュメンタリ・ドメインを指す。本書では構造と責務のみを定義し、実際の文言改訂内容は論理設計に委ねる。

---

## エンティティ

### Operations Step

Operations Phase を構成する 7 ステップ（§1〜§7）。本 Unit では §7（リリース準備）のみを対象とする。

- **ID**: ステップ番号（1〜7）
- **属性**:
  - `current_state`: 状態ラベル（`未着手` / `進行中` / `完了` / `スキップ` / `PR準備完了`）
  - `completion_date`: 完了日（`完了` 状態への遷移時に記録）
- **振る舞い**:
  - `start()`: `未着手` → `進行中`
  - `complete(at: SubStep)`: `進行中` → `完了`（本 Unit はこの遷移点を `§7.7` に明示固定する）
  - `skip(reason)`: `未着手` → `スキップ`

### Operations Step 7 SubStep

§7（リリース準備）の 13 サブステップ（§7.1〜§7.13）。

- **ID**: サブステップ番号（7.1, 7.2, ..., 7.7.1, 7.12.5, ..., 7.13）
- **属性**:
  - `name`: サブステップ名（例: `バージョン確認` / `progress.md更新` / `Git コミット` / `PR マージ`）
  - `phase`: `pre-merge` / `post-merge`（境界は §7.13 マージ）
- **振る舞い**:
  - `update_progress(state)`: `progress.md` のステップ7 状態を更新（§7.6 が主実行点）
  - `commit()`: `pre-merge` の確定点（§7.7 が **「完了」更新の main 反映点**）
  - `merge_pr()`: `post-merge` への遷移点（§7.13）

---

## 値オブジェクト

### StatusLabel

`progress.md` 内のステップ状態に使用するラベル。5 値固定。

- **属性**: `value`: enum (`未着手` / `進行中` / `完了` / `スキップ` / `PR準備完了`)
- **不変性**: 5 値は本 Unit のスコープ外で固定（境界に明記）。本 Unit ではラベルの追加・削除を行わない
- **等価性**:
  - `完了` と `PR準備完了` は **§7.6 で書き込む状態の同義表現**（`03-release.md` line 30 「ステップ7が「完了」（= PR準備完了）」が SoT）
  - 本 Unit ではこの同義関係を計画ファイルおよび改訂後 docs 内で明示する

### CompletionTimingPoint

ステップ7「完了」状態が **main に反映される確定タイミング**。本 Unit の中心ドメイン概念。

- **属性**:
  - `subStep`: §7.7 Git コミット（固定値）
  - `meaning`: 「`progress.md` の `ステップ7=完了` および `completion_gate_ready=true` が §7.7 のコミットによって main に取り込まれる」
- **不変性**: 本 Unit 完了後、`§7.7` が唯一の確定タイミングとして全 docs で一貫して参照される
- **等価性**:
  - `§7.7 Git コミット時` ≡ `マージ前完結契約の成立点`（`operations-release.md` §7.7 セクションで明示）
  - 過去解釈との関係: 「§7.13 マージ後にステップ7全体完了」という解釈は **本 Unit で構造的に廃止** する（`02-deploy.md` line 199 の曖昧記述を書き換え）

---

## 集約

### Step7 Completion Timing Aggregate

ステップ7「完了」更新タイミングに関わる文書群の整合性を 1 つの集約として扱う。

- **集約ルート（SoT 単一化 / Round 1 設計レビュー指摘 #7 対応）**: `operations-release.md` §7.7 セクション（タイミング契約 SoT）
- **含まれる要素**:
  - `operations-release.md` §7.2〜§7.6 統合節 line 28 周辺（§7.6 書き込み点の参照ハブ）
  - `02-deploy.md` §7（入口手順 / line 183 / 186 / 199）
  - `03-release.md` 完了時の確認 line 28-31（完了判定）
  - `04-completion.md` §4 マージ前完結ルール line 476-491（整合性ガード）
  - `templates/operations_progress_template.md` line 13 直後（テンプレート推移経路コメント）
- **境界**: 上記ファイル群の「ステップ7「完了」更新タイミング」記述に閉じる。`scripts/` / `bats` / 既存サイクル成果物（v2.5.3 以前の `progress.md`）への波及は禁止
- **不変条件**:
  1. 全 5 ファイルで「§7.7 Git コミット時に確定」が一意に参照される
  2. 「完了」と「PR準備完了」の同義関係が明示される
  3. マージ後（§7.13 後）の `progress.md` 編集は禁止（`04-completion.md` 整合性ガード経由）
  4. 状態ラベル一覧（5 値）の追加・削除を行わない（境界保護）
  5. `scripts/write-history.sh` の exit 3 ガード（`completion_gate_ready=true` AND PR `MERGED`）と論理整合する（`§7.7` で `completion_gate_ready=true` が main 反映される invariant の維持・強化）

---

## ドメインサービス

### Step7 Timing Consistency Verifier

本 Unit 改訂後、5 ファイル間の「§7.7 Git コミット時に確定」整合性を verify する **ドキュメンタリ検証サービス**。実装は grep ベースで論理設計に委ねる。

- **責務**: 不変条件 1〜5 を機械的に検証可能な形で表現する
- **操作**:
  - `verify_timing_uniqueness()`: 5 ファイルで「§7.7 Git コミット時」表現が一致するか grep で確認
  - `verify_label_synonymy()`: 「完了」と「PR準備完了」の同義性記述が計画 + 改訂後 docs に存在するか確認
  - `verify_post_merge_prohibition()`: `04-completion.md` line 484 「**理由**」段落延長に「二重更新禁止」記述が存在するか確認
  - `verify_label_count_invariant()`: `templates/operations_progress_template.md` 状態ラベル定義行数が不変であることを `grep -c "^|"` で確認
  - `verify_scope_protection()`: `git diff --name-only` で `scripts/` / `bin/tests/` / `tests/` / 過去サイクル `progress.md` への波及がないことを確認

---

## ユビキタス言語

このドメインで使用する共通用語:

- **§7（ステップ7 / リリース準備）**: Operations Phase の最終ステップ。サブステップ §7.1〜§7.13 を含む
- **§7.6（progress.md 更新）**: ステップ7 の状態を `完了`（= `PR準備完了`）に書き込む実行点
- **§7.7（Git コミット）**: §7.6 の更新を含む全変更を main 反映するコミット時点。**ステップ7「完了」更新の確定タイミング**
- **§7.13（PR マージ）**: PR を main にマージする時点。**この時点以降の `progress.md` 編集は禁止**
- **マージ前完結契約**: PR マージ前に全成果物が main に反映される運用契約（DR-001 / Unit 002 / #583）
- **`completion_gate_ready`**: `progress.md` の固定スロット（`true` / `false`）。§7.6 で `true` に書き込まれ、§7.7 のコミットで main 反映される
- **マージ前完結契約の成立点**: §7.7 の Git コミットによって `completion_gate_ready=true` および `ステップ7=完了` が main に取り込まれる時点
- **`write-history.sh` exit 3 ガード**: マージ後の `write-history --phase operations` 呼び出しを `completion_gate_ready=true` AND PR `MERGED` の AND 条件で拒否するガード（`04-completion.md` line 486-491）
- **「完了」と「PR準備完了」の同義関係**: §7.6 で `progress.md` に書き込む状態の 2 種表現。`03-release.md` line 30 が SoT

---

## 文書責務レイヤモデル

| レイヤ | ファイル | 責務 |
|--------|---------|------|
| 規範（手順 SoT） | `operations-release.md` §7.2〜§7.6 統合節 / §7.7 | 主タイミング表現（§7.6 書き込み・§7.7 main 反映）の確定 |
| 入口手順 | `02-deploy.md` §7 | サブステップ列挙とステップ7開始/完了時の状態遷移宣言 |
| 完了判定 | `03-release.md` 完了時の確認 line 28-31 | Operations Phase 完了基準としての §7.7 main 反映済み状態の確認 |
| 整合性ガード | `04-completion.md` §4 マージ前完結ルール line 476-491 | マージ後編集禁止の理由付け強化（二重更新禁止） |
| テンプレート | `templates/operations_progress_template.md` line 13 | v2.5.4 以降の新規サイクル向け推移経路コメント |
| 履歴 | `.aidlc/cycles/v2.5.4/history/construction_unit01.md` | 実装進捗の記録（変更ファイル / レビュー round / 検証結果） |

各レイヤは `operations-release.md` を SoT として参照し、自身のレイヤ責務に閉じた表現を持つ（重複記述の抑制）。

---

## 不明点と質問（設計中に記録）

`[Question]` / `[Answer]` 形式で記録する。本ドメインモデル作成時点で発生した未解決質問はなし（Round 1 計画レビューで「PR準備完了」ラベルとの関係 / `03-release.md` 編集対象漏れ / `04-completion.md` 配置位置等の高優先度疑問は計画ファイル本体で解消済み）。

論理設計フェーズで発生した質問は本セクションに追記する。
