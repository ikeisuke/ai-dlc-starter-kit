# 論理設計: Unit 001 Inception フェーズインデックスのパイロット実装

## 概要

Unit 001 の責務（`steps/inception/index.md` の新設、SKILL.md 共通初期化フローの更新、既存 Inception ステップファイル5本の重複記述除去）を実装するための、ドキュメント構成・ファイル間インターフェース・リファクタリング方針を定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的な Markdown 本文は Phase 2（コード生成ステップ）で作成します。

## アーキテクチャパターン

**採用パターン**: **インデックス集約型プログレッシブロード（案D）**

AI-DLC Starter Kit のスキル読み込み構造に適用する軽量なドキュメント指向パターン。1フェーズ＝1インデックスファイルを常時ロードし、詳細ステップは必要時に `step_id → detail_file` 契約経由で動的参照する。

**選定理由**:
- 初回ロード量の大幅削減（Inception 22,972 tok → 15,000 tok 以下）
- 分岐ロジックの単一責任点化（保守性向上）
- `#553` 類の現在位置誤判定バグの構造的解消基盤（Unit 002 が本 Unit の骨格に実判定を流し込む）
- SKILL.md の「ステップファイル読み込みは省略不可」という不変ルールと整合する形で実装可能（インデックスを「ステップ読み込み」の新たな対象として再定義する）

## コンポーネント構成

### ファイル構成

```text
skills/aidlc/
├── SKILL.md                          # 更新: 共通初期化フローの inception 行をインデックス参照に
└── steps/
    └── inception/
        ├── index.md                  # 新規: フェーズインデックスファイル（本 Unit の主要成果物）
        ├── 01-setup.md               # 更新: 分岐・判定の重複記述を除去
        ├── 02-preparation.md         # 更新: 同上
        ├── 03-intent.md              # 更新: 同上
        ├── 04-stories-units.md       # 更新: 同上
        ├── 05-completion.md          # 更新: 同上
        └── 06-backtrack.md           # 変更なし（バックトラック専用、初回ロード対象外）
```

### 各ファイルの責務

#### `steps/inception/index.md`（新規）

- **責務**: Inception フェーズの入口ファイル。以下4セクションを集約する:
  1. 目次・概要セクション
  2. 分岐ロジックセクション
  3. 判定チェックポイント骨格セクション
  4. ステップ読み込み契約テーブル
- **依存**: なし（詳細ファイルへの参照パスのみを文字列として持つ）
- **公開インターフェース**:
  - 契約テーブル: `step_id → detail_file` の解決を可能にする Markdown テーブル
  - 判定チェックポイント骨格: Unit 002 が `TBD` フィールドを埋めるための固定スキーマ
- **ロード契約**: 初回ロードで常にロード（`SKILL.md` の「共通初期化フロー ステップ4」から参照）

#### `skills/aidlc/SKILL.md`（更新）

- **責務**: AI-DLC オーケストレーターの入口。Unit 001 での主な更新は「共通初期化フロー ステップ4: フェーズステップ読み込み」テーブルの inception 行をインデックスのみ読み込みに変更する
- **依存**: `steps/inception/index.md`
- **公開インターフェース**:
  - 「フェーズステップ読み込み」テーブル: フェーズ→読み込み対象ファイルのマッピング
- **変更範囲**:
  - 151〜166 行目付近の「共通初期化フロー」セクション
  - 具体的には `steps/inception/01-setup.md → ...` を `steps/inception/index.md` に置換
  - 「不変ルール」セクション（34 行目付近）に注釈を追加: インデックスファイルは「フェーズステップ読み込み」の対象として扱われる旨を明示

#### `steps/inception/01-setup.md` 〜 `05-completion.md`（更新）

- **責務**: 各ステップの詳細手順。本 Unit ではインデックス側に集約される**分岐・判定の重複記述**のみを除去し、詳細手順に特化させる
- **依存**: 当該ファイルを必要時に AI エージェントが Read ツールでロードする前提。独立性を保つ
- **公開インターフェース**: Markdown の見出し構造は既存を維持し、`history` 追記や `progress.md` 更新等の成果物生成指示は保持する（静的構造回帰検証の要件）
- **変更範囲**（Unit 001 のスコープ）:
  - 分岐・判定の重複記述の除去（例: `automation_mode=semi_auto` 時のゲート判定ロジック、`Part 1 / Part 2` 遷移ロジック、エクスプレス分岐）
- **スコープ外**:
  - 共通 boilerplate（タスクステータス更新指示の繰り返し等）の削減は Unit 001 の**DoD に含めない**。インデックス集約の過程で結果的に削減される場合は許容するが、boilerplate 削減自体を目的とした編集は行わない（Intent で「自動解消扱い」としている通り、Unit 006 の計測時に達成状況を確認する）

#### `steps/inception/06-backtrack.md`（変更なし）

- **責務**: バックトラック用。初回ロード対象外（必要時のみロード）
- **変更**: なし

## インターフェース設計

### ステップ読み込み契約テーブル（`index.md` 内のテーブル）

`index.md` 内に以下のフォーマットで Markdown テーブルとして定義する:

| step_id | detail_file | entry_condition | exit_condition | load_timing |
|---------|-------------|-----------------|----------------|-------------|
| `inception.01-setup` | `steps/inception/01-setup.md` | フェーズ開始時 | セットアップ完了 | `on_demand` |
| `inception.02-preparation` | `steps/inception/02-preparation.md` | 01-setup 完了後 | 準備完了 | `on_demand` |
| `inception.03-intent` | `steps/inception/03-intent.md` | 02-preparation 完了後 | Intent 承認 | `on_demand` |
| `inception.04-stories-units` | `steps/inception/04-stories-units.md` | 03-intent 承認後 | ストーリー・Unit 定義承認 | `on_demand` |
| `inception.05-completion` | `steps/inception/05-completion.md` | 04 承認後 | フェーズ完了処理完了 | `on_demand` |

### 判定チェックポイント骨格スキーマ（`index.md` 内のテーブル）

`index.md` 内に以下のフォーマットで定義し、Unit 001 では `checkpoint_id` のみ埋め、他フィールドは `TBD` プレースホルダとする:

| checkpoint_id | input_artifacts | priority_order | undecidable_return | user_confirmation_required |
|---------------|-----------------|----------------|--------------------|----------------------------|
| `inception.setup_done` | TBD | TBD | TBD | TBD |
| `inception.preparation_done` | TBD | TBD | TBD | TBD |
| `inception.intent_done` | TBD | TBD | TBD | TBD |
| `inception.units_done` | TBD | TBD | TBD | TBD |
| `inception.completion_done` | TBD | TBD | TBD | TBD |

**Unit 002 連携**: Unit 002 が共通判定仕様（`steps/common/phase-recovery-spec.md`）を策定した後、上記テーブルの `TBD` セルを具体値に置き換える。Unit 001 の時点ではスキーマ骨格を固定し、Unit 002 の流し込みが機械的に行えるようにする。

### CurrentStepDetermination 論理インターフェース（Unit 002 接続点）

Unit 002 が実装する「成果物ベース現在ステップ判定」の論理インターフェースを、Unit 001 で**契約のみ**先行定義する。これは Intent が要求する「インデックスが現在位置判定の唯一の正本」という接続点を、Unit 001 と Unit 002 の間で機械的に繋ぐための契約である。

**論理インターフェース仕様**（Unit 001 で確立、Unit 002 が内部実装を埋める）:

```text
operation: determine_current_step
input:
  - phase_index: PhaseIndex              # 対象フェーズのインデックス（本 Unit で確立）
  - input_artifacts_state: ArtifactsState # 現サイクル配下のファイル存在状態・progress.md 完了マーク等を集約した状態オブジェクト
output:
  - 判定成功時: step_id（文字列、例: "inception.04-stories-units"）
  - 判定不能時: "undecidable:<reason_code>"
    - reason_code の4系統（Unit 002 で実装する異常系）:
      - missing_file     : 必須成果物ファイル欠損
      - conflict         : 複数フェーズ成果物の競合
      - format_error     : progress.md 等のパース失敗
      - legacy_structure : v2.2.x 以前の旧構造検出
user_confirmation_connection:
  - 判定不能時はユーザー確認フローへ接続しうる契約として定義する
  - 実際にユーザー確認が必須かは Unit 002 が reason_code ごとに決定する（RecoveryCheckpoint.user_confirmation_required フィールドに実値を流し込む）
  - Unit 001 の時点では「接続可能な契約点」があることのみを保証し、固定真偽値は定義しない
```

**Unit 001 と Unit 002 の責務境界（明示）**:

| 要素 | Unit 001 の責務 | Unit 002 の責務 |
|------|-----------------|-----------------|
| `PhaseIndex` ドキュメント構造 | 確立する | 触らない |
| `StepLoadingContract` 契約テーブル | 確立・全5ステップ分を埋める | 触らない |
| `RecoveryCheckpoint` スキーマ | 確立・全5チェックポイント分の `checkpoint_id` のみ埋める | 触らない |
| `RecoveryCheckpoint` の `input_artifacts`/`priority_order`/`undecidable_return`/`user_confirmation_required` フィールド | `TBD` プレースホルダで残す | 実値に置き換える |
| `CurrentStepDetermination` 論理インターフェース | 入出力契約を文書化する | 内部判定ロジックを `phase-recovery-spec.md` に実装する |
| `compaction.md` の現在位置判定テーブル | `index.md` の冒頭に「Unit 002 で削除予定の非正本。新規参照禁止、Unit 001 期間中も旧テーブル参照は非推奨」と宣言する（削除自体は Unit 002） | 削除する |

**Source of Truth 宣言（Unit 001 で行う）**: `index.md` の冒頭メタコメントに次を明記する — 「Unit 001 時点から、フェーズの現在位置判定に関する正本は本インデックスファイルである。`compaction.md` に残存する判定テーブルは Unit 002 で削除予定の遺物であり、新規参照は禁止する」。これにより Unit 001 期間中の判定仕様参照元を単一化する。

### SKILL.md「フェーズステップ読み込み」テーブルの変更

既存:

```markdown
| フェーズ | 読み込み対象 |
|---------|-------------|
| inception | `steps/inception/01-setup.md` → `02-preparation.md` → `03-intent.md` → `04-stories-units.md` → `05-completion.md`（`06-backtrack.md` は必要時） |
| construction | ... |
| operations | ... |
```

変更後（inception 行のみ更新）:

```markdown
| フェーズ | 読み込み対象 |
|---------|-------------|
| inception | `steps/inception/index.md`（詳細ステップは契約テーブル経由で必要時ロード） |
| construction | ... (変更なし、Unit 003 で更新) |
| operations | ... (変更なし、Unit 004 で更新) |
```

## スクリプトインターフェース設計

本 Unit では新規スクリプトは追加しない。既存の `scripts/read-config.sh` 等への変更もなし。

## データモデル概要

### ファイル形式

- **形式**: Markdown
- **主要ファイル**: `steps/inception/index.md`
  - 章構成: `## 目次`、`## 分岐ロジック`、`## 判定チェックポイント骨格`、`## ステップ読み込み契約`
  - テーブル形式: 上記インターフェース設計セクションに記載

**補足**: インデックスファイル内部には、他フェーズ（Unit 003/004）で流用可能なように「汎用構造仕様コメント」を含める。具体的には `<!-- phase-index-schema: v1 -->` のような Markdown コメントで世代を識別する。

## 処理フロー概要

### フロー1: AI エージェントの Inception Phase 初回ロード

**ステップ**:
1. ユーザーが `/aidlc inception` を実行
2. AI エージェントが SKILL.md を読み込み、「共通初期化フロー」を順に実行
3. 共通ステップ（`rules-core.md` / `preflight.md`）をロード
4. セッション継続判定（`session-continuity.md`）
5. **フェーズステップ読み込み**: 「フェーズステップ読み込み」テーブルの inception 行に従い `steps/inception/index.md` のみをロード
6. `step_id` の決定:
   - **Unit 001 時点の既定ルート（必須契約）**:
     - `step_id` が明示指定されている場合（追加コンテキスト等で指定された場合）: 契約テーブルから解決
     - `step_id` 未指定の場合: `inception.01-setup`（フェーズの最初のステップ）を既定開始点として契約テーブルから解決
     - これにより Unit 002 の自動判定が未実装でも、Unit 001 単体で `/aidlc inception` の開始経路が必ず閉じる
   - **Unit 002 完了後の拡張**: `CurrentStepDetermination.determine(phase_index, artifacts_state)` により成果物群と progress.md からインデックスの判定チェックポイントに従い自動判定（本 Unit ではインターフェース契約のみ）
7. 該当 `step_id` の `detail_file` を Read ツールで読み込み、そのステップを実行

**関与するコンポーネント**: SKILL.md、rules-core.md、preflight.md、session-continuity.md、index.md、detail file

### フロー2: 契約ルーティング検証（Unit 001 の DoD 対応）

**ステップ**:
1. **全5 `step_id` の解決確認**: Inception の全ステップ（`inception.01-setup` / `inception.02-preparation` / `inception.03-intent` / `inception.04-stories-units` / `inception.05-completion`）について、`index.md` の契約テーブルから該当行を grep で取り出す
2. 各行の `detail_file` 列の値をスキルベースディレクトリからの相対パスとして解決
3. 実際に Read ツールで該当5ファイルが読めることを確認
4. **`StepLoadingContract` 列構造固定確認**: 契約テーブルの列数・列名が固定スキーマ（`step_id` / `detail_file` / `entry_condition` / `exit_condition` / `load_timing`）と一致することを確認
5. **`RecoveryCheckpoint` 骨格固定確認**: 判定チェックポイント骨格テーブルが以下を満たすことを確認:
   - 列数・列名が固定スキーマ（`checkpoint_id` / `input_artifacts` / `priority_order` / `undecidable_return` / `user_confirmation_required`）と一致
   - 全5チェックポイント行（`inception.setup_done` / `inception.preparation_done` / `inception.intent_done` / `inception.units_done` / `inception.completion_done`）が存在
   - 各行の `checkpoint_id` 以外のセルがすべて `TBD` であること（Unit 002 流し込み待ちの状態）
6. **既定ルート確認**: `step_id` 未指定時の既定開始点 `inception.01-setup` が契約テーブルに存在することを確認

**関与するコンポーネント**: index.md、detail file（5本）

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: Inception 初回ロード 15,000 tok 以下（Unit 定義 NFR）
- **対応策**:
  1. 全 `detail_file` の `load_timing` を `on_demand` に固定し、初回ロード対象を `index.md` と共通4ファイルに絞る
  2. `index.md` のサイズ予算は 6,269 tok 以下（共通4ファイル 8,716 tok + index.md ≤ 15,000 tok）
  3. 既存ステップファイルの重複記述除去は二次的な効果（詳細ファイルの合計サイズも削減されるが、初回ロード対象外のため直接の効果はない）
- **測定方法**: 計画ファイル記載の `tiktoken (cl100k_base)` 計測スクリプト

### セキュリティ

- **要件**: 該当なし（ドキュメント変更のみ、認証・認可・入力検証は発生しない）
- **対応策**: 秘密情報を含むファイルは変更対象に含まれないため対応不要

### スケーラビリティ

- **要件**: 他フェーズに展開可能な汎用構造を採用する（Unit 定義 NFR）
- **対応策**:
  1. `index.md` の章構成・テーブルスキーマをフェーズ非依存にする
  2. フェーズ固有要素（ステップ名、分岐条件）と共通要素（契約スキーマ、判定チェックポイントスキーマ）を分離する
  3. インデックスファイル冒頭に `<!-- phase-index-schema: v1 -->` コメントで世代管理

### 可用性

- **要件**: 既存 Inception フローの動作を破壊しない（Unit 定義 NFR）
- **対応策**:
  1. 既存 `01-setup.md` 〜 `05-completion.md` は削除せず、重複除去のみ行う
  2. 各ステップファイルの必須セクション見出し（H2/H3）は維持する
  3. 成果物生成指示（テンプレート参照、Write ツール呼び出し、`progress.md` 更新等）は一切変更しない
  4. 静的構造回帰検証（計画ファイル記載の5項目）で変更範囲を限定する

## 技術選定

- **言語**: Markdown（AI-DLC スキルの標準記述言語）
- **フレームワーク**: なし（Claude Code の Read/Write ツールと AI エージェントの解釈能力に依存）
- **ライブラリ**: `tiktoken (cl100k_base)`（tok 計測用）
- **データベース**: なし

## 実装上の注意事項

### SKILL.md の不変ルール整合

- SKILL.md の「不変ルール」セクション（34 行目付近）に次の旨を追記: 「フェーズインデックスファイル（`index.md`）が存在する場合、『ステップファイル読み込み』の対象として扱う。インデックスから `step_id` 経由で詳細ファイルに辿る流れもステップファイル読み込みの一形態である」
- これにより「インデックスのみロード」が「ステップファイル読み込み省略」と誤解されるリスクを構造的に排除する

### 重複記述除去の範囲管理

- 既存 5 ステップファイルから除去するのは**分岐・判定の繰り返し記述のみ**とする
- 手順そのもの（テンプレート参照、Write ツール呼び出し、`progress.md` / `history` 更新等）は一切変更しない
- 除去候補のキーワード: `automation_mode=semi_auto`、`express_enabled`、`Part 1 / Part 2`、`auto_approved`、`フォールバック条件`、`セミオートゲート判定`
- 各ファイルからの除去前後で、grep でキーワード出現回数を記録し、除去量を定量化する
- **boilerplate 削減の扱い**: Intent で「案D化の過程で自動解消扱い」とされているため、Unit 001 では boilerplate 削減自体を目的とした編集は行わない。結果的に減る場合は許容するが、DoD の検証項目には含めない

### トークン予算の厳守

- 計画ファイル記載の予算配分に従う: `index.md` ≤ 6,269 tok（共通4ファイル 8,716 tok + 誤差バッファ 15 tok = 計 8,731 tok 上限を控えめに見積もり）
- **契約不変領域（削減対象外）**: 以下の要素は Unit 002 以降が機械的に流し込むための契約であり、予算都合でも列構造・行構造を変更してはならない:
  - `StepLoadingContract` 契約テーブル（列: `step_id` / `detail_file` / `entry_condition` / `exit_condition` / `load_timing`）
  - `RecoveryCheckpoint` 骨格スキーマ（列: `checkpoint_id` / `input_artifacts` / `priority_order` / `undecidable_return` / `user_confirmation_required`）
  - Inception の全5ステップに対応する契約行・チェックポイント行
- 実装中に予算超過が判明した場合は、**非契約部分のみ**を以下の順で削減する:
  1. `index.md` の説明文・導入文の簡略化
  2. 分岐ロジックセクションの箇条書き化・冗長表現の削除
  3. 汎用構造仕様コメントの外部ファイル分離（index.md 本体から参照形式へ）
- これでも予算超過する場合は、Unit 001 の計画見直しをユーザーに提案（この場合は承認プロセスに戻る）

### 保守性・拡張性

- 他フェーズ Unit（003/004）が本 Unit のパターンを機械的に流用できるよう、インデックスファイルの「汎用構造仕様」を別章として明記する
- 判定チェックポイント骨格スキーマは Unit 002 が編集する前提で、`TBD` セルを一貫したパターンで配置する

## 不明点と質問（設計中に記録）

（対話を通じて不明点を明確化するセクション。現時点では不明点なし。計画レビュー5回反復により必要な仕様は計画ファイルに固定済み）
