# ドメインモデル: Unit 003 aidlc-migrate での個人好みキー移動提案

## 概要

既存 AI-DLC プロジェクトの `.aidlc/config.toml`（project_shared 層）に残存する「個人好み」7 キーを `~/.aidlc/config.toml`（user_global 層）へ移動する**提案フロー**を表現するドメインモデル。Unit 001 / 002 で確立した 4 階層マージ仕様 + 個人好み 7 キー集合 + 安定 ID 契約を前提として、移動可否のユーザー判定 + 非破壊的選択肢 + 冪等性 + dry-run 完全性の 4 NFR を表現する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2（コード生成）で行う。

## エンティティ（Entity）

### PreferenceKeyDetection

project_shared 層に存在する個人好みキーの**検出結果**を表すエンティティ。検出された個別キーごとに 1 インスタンス。

- **ID**: `(detection_run_id, dotted_path)` の複合キー
- **属性**:
  - `detection_run_id`: String — 単一 detect 実行の識別子（実行時刻 / sha256 等で生成可能だが、本 Unit ではメモリ上の通し番号で十分）
  - `key`: ConfigKey — 検出されたキー（Unit 001 から read-only 参照する `IndividualPreferenceKey` 集合の元素）
  - `value_in_project`: TomlValue — project_shared 層に書かれた現値
  - `user_global_conflict`: Boolean — user_global 層に同名キーが既存するか
  - `user_global_value`: TomlValue? — user_global に既存の場合の値（存在しない場合は null）
- **振る舞い**:
  - `requires_overwrite_confirmation()`: Boolean — `user_global_conflict == true` を返す（step 側の追加 AskUserQuestion 提示判定）
  - `is_array_value()`: Boolean — 値型が array（`rules.reviewing.tools` の場合に true / 完全置換ルールの判定）

### RelocationCommand

ユーザーが個別キーに対して選択した**操作の意図**を表すエンティティ。実行（move/keep）またはスキップ（cancel）の意思を保持する。

- **ID**: `(detection_run_id, dotted_path, sequence)` の複合キー
- **属性**:
  - `detection_run_id`: String
  - `key`: ConfigKey
  - `action`: RelocationAction — `Move` / `Keep` / `MoveOverwrite` / `Cancel`
  - `dry_run`: Boolean — dry-run モードフラグ
  - `applied_at`: Timestamp — 実行時刻（Cancel の場合は null）
- **振る舞い**:
  - `is_destructive()`: Boolean — `action ∈ {Move, MoveOverwrite}` を返す
  - `affects_project_shared()`: Boolean — `Move` / `MoveOverwrite` の場合 true（project からキーを削除する）
  - `affects_user_global()`: Boolean — `Move` / `MoveOverwrite` の場合 true（user_global にキーを追記/上書き）

### BulkActionState

`yes-to-all` / `no-to-all` 選択時の**対話遷移状態**を表すエンティティ。step 内ループの状態管理に使用。

- **ID**: `detection_run_id`
- **属性**:
  - `detection_run_id`: String
  - `bulk_action`: BulkAction — `None` / `MoveAll` / `KeepAll`
  - `triggered_by_key`: ConfigKey? — bulk_action が None 以外になった起点キー
- **振る舞い**:
  - `should_skip_question(next_key)`: Boolean — `bulk_action != None` のとき true（残りキーは無質問で同一適用）
  - `derive_action_for(next_key)`: RelocationAction — bulk_action から RelocationAction を導出（MoveAll → Move / KeepAll → Keep）

## 値オブジェクト（Value Object）

### RelocationAction

ユーザー選択の操作を表す列挙型。

- **値**:
  - `Move` — project から削除 + user_global に追記（user_global に既存の場合は警告 + skip）
  - `MoveOverwrite` — project から削除 + user_global に追記（既存の場合は上書き）
  - `Keep` — 何もしない（非破壊）
  - `Cancel` — 個人好みキー移動提案フロー全体を中断

### BulkAction

対話遷移規則の状態を表す列挙型。

- **値**:
  - `None` — まだ bulk 選択がされていない（各キーで 4 択を提示）
  - `MoveAll` — yes-to-all 選択後（残りキーに Move を無質問で適用）
  - `KeepAll` — no-to-all 選択後（残りキーに Keep を無質問で適用）

### RelocationOutputLine

script の標準出力 / 標準エラー出力 1 行を表す不変値オブジェクト。タブ区切り単一形式。

- **属性**:
  - `prefix`: OutputPrefix — `detected` / `summary` / `move` / `keep` / `dry-run:detected` / `dry-run:move` / `dry-run:keep` / `warn` / `error`
  - `stream`: OutputStream — `stdout`（情報行）/ `stderr`（warn / error）
  - `fields`: List<String> — タブ区切り後続フィールド
- **不変条件**:
  - `prefix` ごとに必須フィールド数が決まる（detected: 4, summary: 2, move: 4, keep: 1, warn: 2, error: 2）
  - 値中にタブ・改行を含まない（個人好み 7 キーの値は string / boolean / 単純配列のみ。実装時は制御文字 0x00-0x1F + 0x7F の混入を `_value_has_unsafe_chars` で reject）

### OutputPrefix

タブ区切り出力のプレフィックスを表す列挙型。プレフィックス命名規約（実装契約）:

- **`detected`** / **`summary`** / **`move`** / **`keep`**: 情報行（stdout / exit 0）
- **`dry-run:` 系**（`dry-run:detected` / `dry-run:move` / `dry-run:keep`）: dry-run 実行時の情報行（stdout / exit 0 / 書き込みなし）
- **`warn:`**: 処理継続可能な競合通知（stderr / exit 0 / 例: `warn:user-global-key-exists`）
- **`error:`**: 致命エラー（stderr / exit 2 / 例: `error:invalid-value`, `error:project-config-not-found`）

`warn` と `error` は終了コードと意味論で明確に区別される（ログ集約・自動判定で安全に分類可能）。

### OutputStream

出力ストリームを表す列挙型。

- **値**: `Stdout`（情報行）/ `Stderr`（warn / error）

### IndividualPreferenceKey / LayerKind / ConfigKey

Unit 001 で定義済みの値オブジェクトを参照する。本 Unit では新規定義しない。

- `IndividualPreferenceKey` — 個人好み 7 キー集合（Unit 001 ストーリー 1 正規定義）
- `LayerKind` ∈ `{Defaults, UserGlobal, ProjectShared, ProjectLocal}` — 4 階層
- `ConfigKey` — TOML dotted path で同定される設定キー

## ドメインサービス（Domain Service）

### PreferenceDetectionService

project_shared と user_global を読み取り、個人好み 7 キーの検出 + conflict 判定を行うドメインサービス。markdown / bash 実装の責務分離を概念的に表現する（具象クラスは作らない）。

- **責務**:
  - project_shared 層から個人好み 7 キーのうち存在するものを列挙する
  - 各検出キーについて user_global 層に同名キーが既存するか（user_global_conflict）を判定する
  - 検出 0 件でも正常終了し、`summary total 0` 行で観測可能にする

### RelocationExecutorService

RelocationCommand を受け取り、project_shared からの削除 + user_global への追記（または上書き）を実行するドメインサービス。dry-run の場合は実 I/O を行わず出力のみ。

- **責務**:
  - `Move` / `MoveOverwrite` の実行: project ファイルから sed/awk で対象行を削除 → user_global に追記（または上書き）
  - `Keep` の実行: 何もせず（非破壊）、ログ出力のみ
  - dry-run: I/O を伴わず、実 move 出力と完全一致する diff 出力を生成（`dry-run:` プレフィックス付き）
  - `MoveOverwrite` 実行時の上書きロジック: user_global の既存キー行を sed/awk で削除した後に新値を追記（既存追記方式 + 削除前処理の組み合わせ）
  - 配列値の完全置換（4 階層マージ仕様維持 / `rules.reviewing.tools = ["codex"]` を user_global に同形式で書き出す）

### IdempotencyResolver

冪等性 NFR を保証する概念サービス。「移動済みキーは再 detect されない」「部分移動後は残ったキーのみ検出される」を保証する。

- **責務**:
  - PreferenceDetectionService が project_shared を **常に最新の状態で読み取る** ことを保証（キャッシュなし / セッション横断状態なし）
  - 移動済みキー（project から削除済み）は次回 detect で 0 件結果に貢献する
  - **本 Unit の実装方式**: PreferenceDetectionService の純粋関数性（入力 = project ファイルの現状、出力 = 検出結果）により暗黙的に冪等性を満たす（追加機構なし）

## 集約（Aggregate）

### PreferenceRelocationAggregate

単一 detect 実行をルートに、その結果として生成される PreferenceKeyDetection / RelocationCommand / BulkActionState を凝集する集約。一度の `aidlc-migrate` 実行内での状態整合性の境界。

- **集約ルート**: `detection_run_id` をキーとする論理的な実行コンテキスト（具象 entity ではなく実行スコープ）
- **メンバー**:
  - PreferenceKeyDetection（0〜7 件）
  - RelocationCommand（PreferenceKeyDetection と 1:1）
  - BulkActionState（実行スコープ全体に 1 件）
- **不変条件**:
  - PreferenceKeyDetection は ConfigKey が `IndividualPreferenceKey` 集合の元素である
  - RelocationCommand の `dotted_path` は対応する PreferenceKeyDetection と一致
  - BulkActionState の `bulk_action != None` の場合、後続 RelocationCommand は無質問で `derive_action_for` の結果に従う
  - `RelocationAction.Cancel` 発生時、後続 PreferenceKeyDetection に対する RelocationCommand は生成されない（フロー全体中断）
- **集約境界外との関係**:
  - Unit 002 の SetupGuidanceAggregate（root: `03-migrate.md` の `unit002-user-global`）への**参照のみ**で「user-global 推奨」案内を再表示（本文コピー禁止 / 単一ソース原則）
  - Unit 001 の正規 7 キー集合（IndividualPreferenceKey）は read-only 参照
  - dry-run 結果と実行結果は完全一致（dry-run 完全性 NFR）

## リポジトリインターフェース

本 Unit の I/O はファイルシステム（TOML ファイル）が対象。永続化リポジトリは TOML ファイルそのもので代替する。**実装非対象**として概念のみ記載する。

### ProjectConfigRepository（概念）

- `find_individual_prefs() -> List<PreferenceKeyDetection.partial>`: project_shared 層から個人好み 7 キーのうち存在するものを返す
- `delete_key(key: ConfigKey) -> Result`: 指定キー行を削除（sed/awk + tmp + mv）

### UserGlobalConfigRepository（概念）

- `has_key(key: ConfigKey) -> Boolean`: 同名キー存在判定
- `read_key(key: ConfigKey) -> TomlValue?`: 既存値読み取り
- `append_key(key: ConfigKey, value: TomlValue) -> Result`: 末尾追記（ファイル不在時は最小ヘッダ付きで新規作成）
- `overwrite_key(key: ConfigKey, value: TomlValue) -> Result`: 既存行削除 + 末尾追記

## 参考概念（実装非対象）

### IndividualPreferenceKeyCatalog（Unit 001 から継続）

Unit 001 で定義した正規 7 キー集合の単一ソース概念。本 Unit では PreferenceDetectionService の検出対象キー集合として参照のみ。

### RelocationAuditLog

将来サイクルで「移動履歴の永続化 + 監査」が必要になった場合の概念。本 Unit では tab 区切り stdout 出力 + 既存 git 履歴で代替する（永続化なし）。

## ドメインモデル図（テキスト）

```text
PreferenceRelocationAggregate (root: detection_run_id)
├─ BulkActionState (bulk_action ∈ {None, MoveAll, KeepAll}, triggered_by_key ∈ ConfigKey?)
├─ PreferenceKeyDetection[] (0〜7 件)
│  └─ key: ConfigKey ← IndividualPreferenceKey (Unit 001 から read-only)
│     value_in_project: TomlValue
│     user_global_conflict: Boolean
│     user_global_value: TomlValue?
└─ RelocationCommand[] (PreferenceKeyDetection と 1:1)
   ├─ action: RelocationAction ∈ {Move, MoveOverwrite, Keep, Cancel}
   ├─ dry_run: Boolean
   └─ applied_at: Timestamp?

外部参照:
- IndividualPreferenceKey (Unit 001 から read-only)
- LayerKind (Unit 001 から read-only)
- SetupGuidanceAggregate.GuidanceMessage (Unit 002 stable_id = "unit002-user-global" から参照のみ)

外部公開契約:
- detection_run_id ごとの集約整合性は単一 aidlc-migrate 実行内で完結
- BulkActionState による無質問遷移は markdown step 側で状態管理（script 側は持たない）
- script は決定論的（CI で再現可能 / 対話を持たない / dry-run 完全性）
```

## 設計判断

| 論点 | 判断 | 根拠 |
|------|------|------|
| BulkActionState の管理場所 | markdown step（02-execute.md ## 4）側で状態管理 | script は決定論的 / dry-run 完全性を保つため対話状態を持たせない。step 側は LLM が実行ループ内で `bulk_action` 変数を保持する |
| MoveOverwrite を独立 RelocationAction とした理由 | 「上書き」と「警告 + skip」の意図を集約レベルで明確に区別するため | step 側 3 択（上書き / スキップ / キャンセル）と script `--overwrite` フラグの対応関係が直接 traceable になる |
| user_global_conflict を PreferenceKeyDetection の属性にした理由 | detect 出力で project / user_global 両方の状態を一度に提供することで、追加 conflict 判定 API（check-conflict 等）を不要にする | 責務一本化 + step 側ロジック単純化（追加 round-trip 不要） |
| IdempotencyResolver を「純粋関数性で暗黙的に保証」とした理由 | 追加状態（履歴ファイル等）を持たないことで実装単純化と冪等性を両立 | プロジェクト config の現状を入力とする純粋関数なら自然に冪等。明示的な mark / unmark 機構は不要 |
| Cancel の扱い | フロー全体中断（後続キーの RelocationCommand 生成なし） | ユーザー意思（中断したい）を集約境界で明確化。部分実行による不整合を防ぐ |
| Unit 002 への参照方法 | 安定 ID `unit002-user-global` で参照、本文コピー禁止 | Unit 002 の境界宣言と一致（単一ソース原則）。文言変更耐性を維持 |
