# ドメインモデル: Unit 006 氾濫緩和（重複検出 + サイクル毎上限）

## 概要

Unit 005 が実装した mirror フロー（detect → AskUserQuestion → send / record）に対する**後付けフィルタ層**を表現するドメインモデル。同一サイクル内 retrospective における `skill_caused=true` の重複項目を 1 件に統合し、サイクル毎の `feedback_max_per_cycle` 上限超過分を抑制する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2（コード生成）で行う。

**Unit 005 ドメインモデルとの関係**: 本 Unit は Unit 005 が定義した `MirrorCandidate` / `IssueDraft` / `MirrorFlowAggregate` を**そのまま流用**し、新規エンティティ `FilterCandidateRow` / `FilterResult` / `FloodMitigationConfig` と値オブジェクト `NormalizedQuote` / `NormalizedTitle` / `JaccardScoreMilli` / `EditDistanceRatioPct` を追加する。フィルタ層は **MirrorFlowAggregate の中** で動作し、外部に新しい集約を作らない。

## エンティティ（Entity）

### FilterCandidateRow

`_classify_candidates` が拡張 6 列 TSV として出力し、フィルタ層が入力として受け取る candidate 行を表すエンティティ。Unit 005 の 4 列 candidate 行を本 Unit で 6 列へ拡張する（後方互換: 旧 4 列形式は本 Unit の実装で廃止）。実行時のみ存在し、永続化しない。

- **ID**: `(cycle, problem_index)`
- **属性**:
  - `kind`: String — 固定値 `"candidate"`（種別タグ）
  - `problem_index`: Integer — 1 始まり整数
  - `state`: MirrorStateValue — Unit 005 の値オブジェクトを参照（`-` プレースホルダ復元後）
  - `skill_caused`: Boolean — 派生値（Unit 004 から再計算）
  - `title`: NormalizedTitle — `_classify_candidates` 段で `_normalize_text` 適用済み
  - `normalized_quote`: NormalizedQuote — q1〜q3_quote のうち最初の non-empty を `_normalize_text` 適用済み
- **不変条件**:
  - `kind == "candidate"`（他の TSV 行種別とは混在しない）
  - `problem_index >= 1`
  - `skill_caused == true` の行のみがフィルタ対象（`false` 行は事前フィルタリングで除外）
  - `title.length > 0`（タイトル不明時は `（タイトル不明）` プレースホルダ / Unit 005 既定）
- **振る舞い**:
  - `to_tsv_line()`: String — TSV 出力（`candidate\t<idx>\t<state-or-dash>\t<sc>\t<title>\t<normalized_quote>`）
  - `from_tsv_line(line)`: FilterCandidateRow — TSV 行から再構築（フィルタ単体テスト用）

### FilterResult

フィルタ層の出力結果を表すエンティティ。`_filter_dedup_and_cap` が返す通過候補集合 + 抑制候補集合 + 抑制理由を保持する。一時的な実行時エンティティ。

- **ID**: `(cycle, run_started_at)`
- **属性**:
  - `passing_indices`: List<Integer> — emit candidate として通過する problem_index リスト（idx 昇順）
  - `dedup_merged`: List<DedupMergedRecord> — 重複統合された項目リスト
  - `cap_exceeded`: List<CapExceededRecord> — 上限超過項目リスト
  - `total_input`: Integer — フィルタ入力数（candidate 行数）
- **不変条件**:
  - `total_input == passing_indices.size + dedup_merged.size + cap_exceeded.size`
  - `passing_indices.size <= feedback_max_per_cycle`
  - `passing_indices` / `dedup_merged.merged_idx` / `cap_exceeded.idx` は互いに素（同一 idx が 2 か所に出ない）
  - 各リスト内で idx は昇順
- **振る舞い**:
  - `to_summary_line()`: String — `summary\tcounts\t...;dedup-merged=N;cap-exceeded=M` 用カウント計算
  - `to_dedup_tsv_lines()`: List<String> — `mirror\tdedup-merged\t<idx>\t<merged-into-idx>` 行群
  - `to_cap_tsv_lines()`: List<String> — `mirror\tcap-exceeded\t<idx>\t<count>;<max>` 行群

### DedupMergedRecord

重複統合 1 件分の記録を表す値オブジェクト。FilterResult 内で複数保持される。

- **属性**:
  - `merged_idx`: Integer — 抑制された側の problem_index
  - `representative_idx`: Integer — 代表として残る側の problem_index（最小 idx）
  - `merge_reason`: MergeReason — `quote-exact-match` / `title-jaccard` / `title-edit-distance` のいずれか
- **不変条件**:
  - `merged_idx > representative_idx`（代表は常に最小 idx）
  - `merge_reason` は上記 3 値のうちの 1 つ
- **振る舞い**:
  - `to_tsv_line()`: String — `mirror\tdedup-merged\t<merged_idx>\t<representative_idx>` 出力（注: TSV では merge_reason は出さない / 機械可読性より行数最小化を優先）

### CapExceededRecord

上限超過 1 件分の記録を表す値オブジェクト。

- **属性**:
  - `idx`: Integer — 抑制された problem_index
  - `current_count`: Integer — 抑制が発生した時点での通過済み件数
  - `max_per_cycle`: Integer — 設定値（`feedback_max_per_cycle`）
- **不変条件**:
  - `current_count >= max_per_cycle`
  - `idx` は通過候補にもダンピング統合にも含まれない
- **振る舞い**:
  - `to_tsv_line()`: String — `mirror\tcap-exceeded\t<idx>\t<current_count>;<max_per_cycle>`

### FloodMitigationConfig

フィルタ層の設定値を保持する設定エンティティ。`retrospective-schema.yml` の `flood_mitigation` セクション + 4 階層マージ後の `defaults.toml` `[rules.retrospective] feedback_max_per_cycle` から構築される。

- **属性**:
  - `feedback_max_per_cycle`: Integer — 4 階層マージ結果（不正値時は schema default 3）
  - `dedup_jaccard_threshold_milli`: Integer — schema 値（不正値時は default 700）
  - `dedup_edit_distance_ratio_pct`: Integer — schema 値（不正値時は default 30）
  - `nfkc_unavailable_policy`: NfkcUnavailablePolicy — `Fatal`（v2.5.0 固定）
  - `cap_strategy`: CapStrategy — `SkipAndRecord`（v2.5.0 固定）
- **不変条件**:
  - `feedback_max_per_cycle >= 0`（0 を許容: 全 candidate cap-exceeded として扱う / DI4 検証）
  - `0 <= dedup_jaccard_threshold_milli <= 1000`
  - `0 <= dedup_edit_distance_ratio_pct <= 100`
  - 不正値検出時は warn ログ + default フォールバック（recoverable）
- **振る舞い**:
  - `load_from_schema_and_config()`: FloodMitigationConfig — schema + defaults.toml + project-local をマージしてビルド
  - `validate_and_fallback()`: FloodMitigationConfig — 不正値を default に置換してログ出力

## 値オブジェクト（Value Object）

### NormalizedQuote

引用箇所文字列の正規化済み形式を表す値オブジェクト。`_normalize_text` で trim + collapse + NFKC 適用済み。

- **属性**:
  - `value`: String — 正規化後文字列
- **不変条件**:
  - 前後空白なし（trim 済み）
  - 連続空白なし（collapse 済み / 半角スペース 1 個に統一）
  - NFKC 正規形（全角英数 → 半角、合成文字統一済み）
- **振る舞い**:
  - `from_raw(raw_quote)`: NormalizedQuote — 生引用箇所から正規化（Python 3 経由 NFKC）
  - `equals(other)`: Boolean — String 完全一致比較

### NormalizedTitle

タイトル文字列の正規化済み形式を表す値オブジェクト。NormalizedQuote と同じ正規化ルールを適用するが、ドメイン上の区別（引用箇所 vs タイトル）のため別型。

- **属性 / 不変条件**: NormalizedQuote と同じ
- **振る舞い**:
  - `from_raw(raw_title)`: NormalizedTitle
  - `bigrams()`: Set<String> — Jaccard 計算用文字 bigram 集合（タイトル特有の振る舞い）

### JaccardScoreMilli

Jaccard 係数を整数化した値オブジェクト。マルチバイト文字対応のため Python 3 経由で文字単位 bigram を計算する。

- **属性**:
  - `value`: Integer — 0..1000 の整数（= Jaccard係数 × 1000、切り捨て丸め）
- **不変条件**:
  - `0 <= value <= 1000`
- **振る舞い**:
  - `from_bigram_sets(a, b)`: JaccardScoreMilli — 計算式 `intersection_size * 1000 / union_size`（Python 3 経由）
  - `meets_threshold(threshold_milli)`: Boolean — `value >= threshold_milli`（境界 700 を含む）
- **純粋性レベル**: ビジネス副作用なし（Python 3 サブプロセス呼び出しあり / ファイル更新なし）

### EditDistanceRatioPct

編集距離を短い側長で正規化した整数比率を表す値オブジェクト。マルチバイト文字対応のため Python 3 経由で Levenshtein 距離を計算する。

- **属性**:
  - `value`: Integer — 0..100 の整数（= edit_distance / min_len × 100、切り捨て丸め）
- **不変条件**:
  - `0 <= value <= 100`
- **振る舞い**:
  - `from_strings(a, b)`: EditDistanceRatioPct — Levenshtein 距離計算 + 整数比率化（Python 3 経由）
  - `meets_threshold(threshold_pct)`: Boolean — `value <= threshold_pct`（境界 30 を含む）
- **純粋性レベル**: ビジネス副作用なし（Python 3 サブプロセス呼び出しあり / ファイル更新なし）

### MergeReason

DedupMergedRecord の統合理由を表す列挙型。

- **値**:
  - `QuoteExactMatch` — 引用箇所の正規化済み文字列が完全一致（Pass A）
  - `TitleJaccard` — タイトルの Jaccard 整数比較で閾値超過（Pass B）
  - `TitleEditDistance` — タイトルの編集距離整数比較で閾値以内（Pass B）
- **不変条件**: 上記 3 値のいずれか
- **振る舞い**:
  - `to_payload()`: String — `quote-exact-match` / `title-jaccard` / `title-edit-distance`

### NfkcUnavailablePolicy

NFKC 不可時の方針を表す列挙型。v2.5.0 では `Fatal` のみ採用。

- **値**:
  - `Fatal` — exit 2 + `error\tnfkc-unavailable\tpython3-required` で停止（DR-006 の fatal 系統に従う）
- **不変条件**: v2.5.0 固定値（将来拡張で `WarnAndDegrade` 等を追加する可能性あり）

### CapStrategy

上限超過時の戦略を表す列挙型。v2.5.0 では `SkipAndRecord` のみ採用。

- **値**:
  - `SkipAndRecord` — 超過分を AskUserQuestion 抑制 + cap-exceeded 行記録
- **不変条件**: v2.5.0 固定値

## ドメインサービス（Domain Service）

### FilterDedupAndCapService

フィルタ層全体のオーケストレーション責務を持つドメインサービス。**ビジネス副作用なし（ファイル I/O 禁止 / グローバル変数禁止 / 入出力のみ）**。実装上は内部の `_dedup_pass_b` 経由で python3 サブプロセス（`_jaccard_bigram_milli` / `_edit_distance_ratio_pct`）を呼び出すため、純粋性レベルは「ビジネス副作用なし」となる。

- **責務**:
  - 入力 `List<FilterCandidateRow>` + `FloodMitigationConfig` の各値（feedback_max_per_cycle / dedup_jaccard_threshold_milli / dedup_edit_distance_ratio_pct）を **明示的な引数として受け取る**
  - Pass A（QuoteExactMatch）→ Pass B（TitleJaccard / TitleEditDistance）→ CapFilter の順で実行
  - `FilterResult` を構築して返す
- **依存**: `JaccardScoreMilli` / `EditDistanceRatioPct` / `MergeReason` / `FilterResult`（型 + python3 サブプロセス）
- **純粋性レベル**: **ビジネス副作用なし**（ファイル / 永続ストア更新なし。実装依存として python3 サブプロセス呼び出しあり）

### NormalizationService

文字列正規化サービス。Python 3 必須前提で NFKC 適用。

- **責務**:
  - `_normalize_text(s)` の実装本体
  - Python 3 利用可否事前チェック → 不可なら `NfkcUnavailablePolicy` に従って fatal 終了
- **依存**: 外部 `python3` コマンド
- **純粋性レベル**: **ビジネス副作用なし**（ファイル / 永続ストアを更新しない）。ただし**実装依存として外部プロセス（python3）呼び出しはある**ため `FilterDedupAndCapService` の「完全純粋」とは区別する
- **エラー処理**: Python 3 不在時 → exit 2 + `error\tnfkc-unavailable\tpython3-required`

### DedupPassAService

引用箇所完全一致による重複検出サービス。

- **責務**:
  - 入力 `List<FilterCandidateRow>` から `normalized_quote` をキーにグループ化
  - 各グループで最小 idx を代表とし、それ以外を `DedupMergedRecord(merged_idx, representative_idx, QuoteExactMatch)` として記録
- **依存**: `MergeReason.QuoteExactMatch`
- **副作用**: なし

### DedupPassBService

タイトル類似度（Jaccard / 編集距離）による重複検出サービス。Pass A の結果（残った代表のみ）を入力とする。

- **責務**:
  - Pass A の代表集合に対し、idx 昇順で 2 重ループでタイトル類似度を比較
  - Jaccard 整数比較 `>= 700` または編集距離整数比較 `<= 30` のいずれかを満たすペアを統合候補とする
  - 後者の idx を `DedupMergedRecord(merged_idx, representative_idx, TitleJaccard | TitleEditDistance)` として記録
- **依存**: `JaccardScoreMilli` / `EditDistanceRatioPct` / `MergeReason`
- **副作用**: なし
- **判定優先**: 同一ペアが両条件を満たす場合は Jaccard 優先（merge_reason = TitleJaccard）

### CapFilterService

上限ガードサービス。Pass A + Pass B 後の通過候補集合に対し、idx 昇順で max 件まで通過 / 残りを抑制。

- **責務**:
  - 入力 `List<Integer>`（dedup 通過 idx）+ `feedback_max_per_cycle`
  - idx 昇順で max 件目までを通過、それ以降を `CapExceededRecord(idx, current_count, max)` として記録
- **依存**: `CapExceededRecord` / `CapStrategy`
- **副作用**: なし

## 集約（Aggregate）

### MirrorFlowAggregate（Unit 005 から継承 / 拡張）

Unit 005 が定義した MirrorFlowAggregate は本 Unit でも継続採用する。本 Unit ではフィルタ層を `_detect()` 内の classify → emit candidate の中間に挿入するため、集約境界は変わらない。

- **集約ルート**: `MirrorFlowAggregate`（Unit 005）
- **新規参加メンバー**:
  - `FilterCandidateRow`（拡張 6 列 candidate 行）
  - `FilterResult`（フィルタ結果集計）
  - `FloodMitigationConfig`（設定値）
- **不変条件追加**:
  - `_detect()` の candidate emit は `FilterResult.passing_indices` のみ
  - `dedup_merged` / `cap_exceeded` 行は AskUserQuestion 対象外（Step 5 文書側責務 / summary に件数表示のみ）

## ドメインイベント（Domain Event）

本 Unit は Unit 005 のフロー内に閉じる責務であり、新規ドメインイベントは追加しない。Unit 005 の `MirrorCandidateDetected` / `MirrorIssueSent` / `MirrorRecordWritten` をそのまま流用。

ただし以下の **副作用なきマーカー**（実装上は TSV 行出力）を本 Unit で追加する:

- `DedupMerged`: 重複統合発生時に dedup_merged TSV 行で記録
- `CapExceeded`: 上限超過発生時に cap_exceeded TSV 行で記録

これらは履歴イベントとして扱い、retrospective.md には書き込まない（実行時情報のみ）。

## 不変条件（横断）

1. **単一ソース原則**: しきい値は `retrospective-schema.yml` の `flood_mitigation` セクションが唯一のソース。`retrospective-mirror.sh` 内のハードコードは禁止
2. **後方互換**: `feedback_max_per_cycle` 未設定時は schema default 3 にフォールバック（fatal にしない）
3. **純粋関数性**: `FilterDedupAndCapService` は副作用なし（ファイル I/O / グローバル変数読み書き禁止）。`NormalizationService` のみ Python 3 サブプロセスを許容
4. **整数演算性**: しきい値比較は全て整数比較。浮動小数点演算は使用しない（bash 互換性）
5. **Unit 005 終了コード契約の維持**: detect / send / record の exit 0 / 2 / recoverable failure 5 種は本 Unit で変更しない（DR-006 整合）

## Unit 005 ドメインモデルからの差分まとめ

| 項目 | Unit 005 | Unit 006 |
|------|---------|---------|
| candidate TSV 列数 | 4 列 (kind/idx/state/sc) | 6 列 (+title/+normalized_quote) |
| フィルタ層 | なし（全 candidate 通過） | 追加（FilterDedupAndCapService） |
| 設定キー | feedback_mode / upstream_repo | + feedback_max_per_cycle / dedup_jaccard_threshold_milli / dedup_edit_distance_ratio_pct |
| TSV 行種別 | mirror\tcandidate / skip / send-failed / sent / recorded | + mirror\tdedup-merged / cap-exceeded |
| summary 行 | total / skill_caused_true / already-processed | + dedup-merged / cap-exceeded |
| Python 3 依存 | なし | あり（NFKC 必須） |

## Unit 007 への引き継ぎ点

- `FloodMitigationConfig` は将来「過去サイクル横断 dedup」「優先度フィルタ」を追加する際の拡張ポイント
- `FilterResult` は機械可読 TSV のため、Unit 007 が後段でさらに加工する設計が可能
- `MergeReason` 列挙は値拡張可能（`AiSemanticSimilarity` 等を v2.6.x で追加候補）
