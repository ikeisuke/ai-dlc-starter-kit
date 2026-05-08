# ドメインモデル: pr-ops.sh auto-merge エラー分類

## 概要

`gh pr merge --auto` 失敗時に GitHub CLI が返す stderr 文字列を入力として、`pr-ops.sh` の呼び出し元（Operations Phase 各スクリプト）が判断可能な「分類結果ラベル」へ写像するドメイン。本 Unit 001 は「auto-merge 無効」分類に該当する文言バリアントを拡張し、`error:unknown` への落ち込みを解消する責務を負う。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装は Phase 2 で行います。

## ユビキタス言語

| 用語 | 定義 |
|------|------|
| auto-merge エラー文言 | `gh pr merge --auto` が失敗した際に stderr に返す自由形式の英語メッセージ。GitHub CLI バージョン・GraphQL レスポンス・組織設定により表記が変動する |
| 文言バリアント | 同一意味カテゴリ（例: 「auto-merge が許可されていない」）に属する複数の表記形（半角スペース型 / ハイフン型 / camelCase 型）。文字列形状は異なるが分類結果ラベルは同一 |
| 分類結果ラベル | 呼び出し元が判別する終端記号。本ドメインでは `auto-merge-not-enabled` / `permission-denied` / `unknown` の 3 値 |
| 標準出力フォーマット | `pr-ops.sh` の Operations Phase 契約上の出力形式 `pr:<N>:error:<label>`（コロン区切り 4 セグメント） |
| 後方互換要件 | 既存運用で観測された文言バリアントを将来も分類成功させ続けるという保証。`auto-merge is not allowed`（ハイフン型）/ `not enabled` / `auto_merge` の 3 種が既存パターン |
| fixture 更新トリガー（DR-001） | `gh` CLI バージョンアップで実エラー文言が変化した際にテスト fixture が失敗することで気付く運用契約。トリガー記録先は `history/construction_unit{NN}.md` |

## 値オブジェクト（Value Object）

### AutoErrorMessage

- **属性**: `text: String` — `gh pr merge --auto` 実行失敗時の stderr 全文（mixed-case、末尾改行含む可能性あり、複数行を含み得る）
- **不変性**: GitHub CLI からの出力は副作用扱いで、ドメイン内では読み取り専用として扱う
- **判定方式**: **case-insensitive な部分一致（substring / pattern match）**。`AutoMergeErrorClassifier` は文言バリアント表のいずれかが `text` に含まれる（contains）かを判定する。完全一致ではない
- **等価性（用途分離）**: 本ドメインモデルでは「2 つの `AutoErrorMessage` が同一文字列か」という同値性判定は使用しない（分類器は単一入力に対する片方向の写像のみを扱う）。将来的にキャッシュ・重複検出等で同値性判定が必要になった時点で「case-insensitive な完全一致」として別途定義する

### ClassificationLabel

- **属性**: `name: Enum { auto-merge-not-enabled, permission-denied, unknown }`
- **不変性**: 列挙値は固定。新規ラベル追加は本 Unit のスコープ外（Intent OUT_OF_SCOPE「全エラーパターン網羅再設計」）
- **等価性**: 列挙値の同一性

### ErrorOutputLine

- **属性**: `pr_number: Integer`, `label: ClassificationLabel` から構成される `pr:<N>:error:<label>` 形式の終端表現
- **不変性**: フォーマット契約（コロン区切り 4 セグメント）を破ってはならない
- **等価性**: 文字列等価

## ドメインサービス

### AutoMergeErrorClassifier

- **責務**: `AutoErrorMessage` を受け取り、`ClassificationLabel` を返す純関数。文言バリアント表（後述）に基づいて第一マッチを採用する
- **操作**:
  - `classify(message: AutoErrorMessage) -> ClassificationLabel`
- **判定順序**（**順序固定 / 短絡評価**）:
  1. `auto-merge-not-enabled` 候補語の case-insensitive マッチ → ヒットすれば即時 `auto-merge-not-enabled` を返す
  2. `permission-denied` 候補語の case-insensitive マッチ → ヒットすれば即時 `permission-denied` を返す
  3. いずれも非マッチ → `unknown`
- **判定の冪等性**: 同一入力に対して常に同一ラベルを返す（外部状態を参照しない）
- **マッチ方式**: case-insensitive な部分一致（`AutoErrorMessage.text` の任意位置に文言バリアントが含まれることを条件とする。完全一致ではない。実装は `grep -qi` / `grep -qiE` の `-q`（quiet）+ 部分一致挙動に依拠）

### 文言バリアント表（Unit 001 適用範囲）

#### `auto-merge-not-enabled` カテゴリ

| バリアント | 由来 | 既存 / 新規 | 備考 |
|-----------|------|------------|------|
| `auto-merge is not allowed` | gh CLI 既存出力（ハイフン型） | 既存 | 後方互換維持必須 |
| `auto merge is not allowed` | gh CLI 実出力（半角スペース型、#665 観測） | **新規（Unit 001 で追加）** | `auto[- ]merge is not allowed` で吸収 |
| `enablePullRequestAutoMerge` | GraphQL ミューテーション名（API 経路） | **新規（Unit 001 で追加）** | camelCase（case-insensitive で吸収） |
| `not enabled` | gh CLI 既存出力（簡略表現） | 既存 | 後方互換維持必須 |
| `auto_merge` | gh CLI 既存出力（snake_case 残骸） | 既存 | 後方互換維持必須 |

#### `permission-denied` カテゴリ

| バリアント | 由来 | 既存 / 新規 | 備考 |
|-----------|------|------------|------|
| `permission` | gh CLI 既存出力 | 既存 | Unit 001 範囲外（変更なし） |
| `forbidden` | gh CLI 既存出力 | 既存 | Unit 001 範囲外（変更なし） |
| `403` | HTTP ステータスコード | 既存 | Unit 001 範囲外（変更なし） |

#### 境界（OUT_OF_SCOPE）

`merge conflict` / `branch protection` / `not approved` 等の他エラーパターンは Unit 001 のスコープ外（Intent §「除外するもの」: 「`pr-ops.sh` 全エラーパターンの網羅再設計」OUT_OF_SCOPE）。これらの判定文言は本 Unit では変更しない。

## 集約（Aggregate）

本ドメインは状態を持たない純関数の集合（`AutoMergeErrorClassifier`）であり、伝統的な集約（永続化対象）は存在しない。`AutoErrorMessage` → `ClassificationLabel` の写像のみを扱う。

## リポジトリインターフェース

なし（永続化対象なし）。fixture（テストデータ）はテストファイル内に直接定義。

## ファクトリ

なし（値オブジェクトの生成は呼び出し元の文字列をそのまま `AutoErrorMessage` として扱うため、特別なファクトリは不要）。

## 不変条件

1. **後方互換性**: 既存パターン 3 種（`auto-merge is not allowed` / `not enabled` / `auto_merge`）は新規分類器でも `auto-merge-not-enabled` を返さなければならない
2. **誤分類禁止**: `permission` / `forbidden` / `403` を含む文言は `permission-denied` を返さなければならない（`auto-merge-not-enabled` への吸収禁止）
3. **判定順序の固定**: `auto-merge-not-enabled` カテゴリの判定が `permission-denied` カテゴリより先に実行される（既存実装の順序を維持。順序逆転は本 Unit のスコープ外）
4. **大文字小文字非依存**: 全パターンは case-insensitive で判定される（既存 `grep -qi` の挙動を維持）

## 関連する意思決定（DR）

- **DR-001（fixture 更新トリガーの記録先）**: `gh` CLI バージョン更新で実エラー文言が変わった場合、bats（または `.sh`）テスト fixture が失敗することで気付ける運用とし、トリガー記録先は `history/construction_unit01.md`（Unit 005 と保守方針統一）

## 不明点と質問（設計中に記録）

[Question] 案 A（インライン拡張）vs 案 B（ヘルパ関数化）の最終決定はドメインモデルでなく論理設計で扱うべきか
[Answer] **論理設計で扱う**。本ドメインモデルは「分類ドメインの語彙と責務」の定義に専念し、実装手段（インライン or 関数化）は論理設計の「コンポーネント詳細」セクションで決定する。

[Question] `enablePullRequestAutoMerge` は GraphQL ミューテーション名であり「エラー文言」というより「エラーコンテキストの一部」だが、ドメイン語彙として fixture に含めて良いか
[Answer] **含める**。`gh` CLI が GraphQL レスポンスをそのまま stderr に出力する経路があり（#665 で実観測）、`enablePullRequestAutoMerge` 文字列は実エラー出力の一部として扱う。case-insensitive で `enablepullrequestautomerge` をマッチさせる。
