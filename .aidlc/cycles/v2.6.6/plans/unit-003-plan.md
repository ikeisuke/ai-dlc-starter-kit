# Unit 003 実装計画: 一次情報三層検証 helper (3 source MVP + jsonl 引数 opt-in)

## 対象 Unit

- **Unit**: 003 - 一次情報三層検証 helper (3 source MVP + jsonl 引数 opt-in)
- **関連 Issue**: #652（OPEN / 本サイクル PR で Closes / opt-in helper 追加部分で Close、破壊的部分は v2.7.0+ defer 明記）
- **優先度**: Medium
- **depth_level**: standard（Phase 1 設計を実施）

## 背景・目的

v2.6.6 Intent §1.4 で確定したとおり、`steps/retrospective.md` §1.1.5「事実テーブル先抽出ステップ」は現状ユーザー / AI が手動で 3 source（decisions.md / construction review-summary / history）を Read して markdown 表に書き起こす運用となっている。手動運用は (a) 推測値の混入を構造的に防げない (b) source ごとの集計式が見るたびに揺らぐ という弱点を抱えており、#634 が指摘した「振り返り = 推測ベース KPT」問題の根本解消が未完了である。

本 Unit では「3 source 横断の事実テーブルを構造化抽出する helper」を **opt-in で skill に追加** する。既存 §1.1.5 手動 Read 経路は破壊せず後方互換として残し、helper 経由の自動抽出を新規追加する。セッションログ jsonl（#652 (c)）は file path 引数渡しの opt-in のみで処理し、自動検出・パーミッション自動付与は v2.7.0+ defer とする。

本 Unit は SC-07 を充足し、Unit 004（§1.5 起票フロー再設計）に対しては独立（依存契約なし）。

## スコープ

### 含まれるもの（責務）

- **必須対応 1**: `skills/aidlc/scripts/lib/retrospective-fact-extract.sh` を新規追加（**private 実装層 / Facade に source される**）
  - 配置確定: **公開 API は `retrospective-api.sh` のみ**（Facade 一本化）。`retrospective-fact-extract.sh` は private 実装のみを置き、Facade（`retrospective-api.sh`）から source される構造。caller 側からの直接 source は禁止
  - 公開 API は `retrospective_api_extract_facts` 1 本（Type B / raw markdown 出力）に集約
  - 内部命名規約: `retrospective-fact-extract.sh` 内の関数は **`_retrospective_fact_extract_*` プレフィックス**（先頭アンダースコア + ファイル名由来 namespace）で internal 専用であることを構造で表明。Facade からの参照以外を禁則とする
  - 公開シンボル定義（SoT）: 本 Unit 設計時に「公開シンボル一覧（1 件: `retrospective_api_extract_facts`）」を logical_design.md に明示し、それ以外は internal として扱う旨を明文化
- **必須対応 2**: 3 source の事実抽出関数実装
  - (a) `decisions.md` → DR 件数・タイトル・主因 3 分類（プロダクト固有 / AI-DLC 固有 / 両方）
  - (b) `construction/units/*-review-summary.md` → review round 数 合計 / 指摘件数 合計 / defer 件数 合計
  - (c) `history/*.md` → 時系列イベント（タイムスタンプ + 概要、最大 N 件 / 既定 5 件）
- **必須対応 3**: jsonl 引数渡し処理（opt-in）
  - file path を任意引数で受け取り、存在すれば時系列イベントに jsonl 由来イベントを追加抽出
  - 引数なしの場合は jsonl source をスキップ（既定動作）
  - 機密情報フィルタ: `(api[_-]?key|token|secret|password|bearer)` 正規表現で値マスク
- **必須対応 4**: 出力形式
  - markdown 表形式（§1.1.5 既定列構成と完全一致）
  - 列: 項目 / 値 / 出典
  - 行: DR 件数 / review round 数（合計） / 指摘件数（合計） / defer 件数 / 時系列イベント（主要なもの）
  - jsonl 引数指定時のみ、時系列イベント行に jsonl 由来エントリを追加（出典列に `<jsonl-path>` 表記）
- **必須対応 5**: source 不在時のフォールバック動作
  - source ファイル不在 → warn 出力（stderr）+ 当該 source 行を「-（source 不在）」で出力 + 他 source 処理継続
  - cycle ディレクトリ不在 → fatal（exit 2）
- **必須対応 6**: スキル間依存ルール遵守 + 役割分離（モジュール凝集）
  - 公開 API は `retrospective_api_extract_facts` のみ（caller 側は internal lib を直接 source 禁止）
  - **役割を 3 層に分離**して責務過密を防止:
    - **(L1) extractors**: source ごとに構造化データ（`FactRow` 集合）を生成する internal 関数群（`_retrospective_fact_extract_decisions` / `_retrospective_fact_extract_review_summary` / `_retrospective_fact_extract_history` / `_retrospective_fact_extract_jsonl_optional`）。入力: cycle / 出力: 構造化 FactRow 配列（pipe-separated 中間形式）
    - **(L2) renderer**: 構造化 FactRow 集合を §1.1.5 既定列構成と diff 0 の markdown 表に整形する internal 関数（`_retrospective_fact_extract_render_markdown`）。表示互換ロジックを単独 unit に閉じ、extractors からは切り離す
    - **(L3) orchestrator**: 公開 API `retrospective_api_extract_facts`。extractors を順次呼び出し、結果を renderer に渡して標準出力に流すのみ（集計ロジック・表示整形ロジックは持たない）
  - 将来の source 追加（jsonl 以外）時は L1 に追加するだけで L2/L3 を改変不要、表示形式変更時は L2 のみを改変、という分離を担保
  - aidlc-retrospective skill 側からは `retrospective-api.sh` 経由で呼び出す経路を準備（呼び出し側組み込みは本 Unit 範囲外、SoT 化のみ）
- **必須対応 7**: bats テスト追加
  - 単体: 各 source ごとに正常系 / 空ファイル系 / ファイル不在系
  - 統合: 手動 §1.1.5 経路（既存）と helper 経路で同一 cycle データに対し markdown 表が diff 0
  - jsonl: 引数あり（fixture jsonl）/ 引数なし両ケース
  - 機密情報フィルタ: API キー含む jsonl 入力 → 値がマスクされて出力
  - パフォーマンス: 1 cycle 分の 3 source 抽出が 5 秒以内（NFR）
- **設計ドキュメント**: ドメインモデル + 論理設計を `.aidlc/cycles/v2.6.6/design-artifacts/` 配下に作成
- AI レビュー（設計 / コード / 統合）を codex で実施（`review_mode=required`）

### 含まれないもの（境界）

- **§1.1.5 のデフォルト経路を helper 化する変更** → v2.7.0+ defer（後方互換維持のため本サイクルでは opt-in 追加のみ）
- **既存 §1.1.5 手動 Read 経路の置き換え / 削除** → 後方互換のため明示的に除外
- **セッションログ jsonl の自動検出**（ホームディレクトリ走査 / 典型パス探索）→ v2.7.0+ defer
- **jsonl のパーミッション自動付与** → v2.7.0+ defer
- **§1.5 Issue 起票フロー（Try ループ化 + cap 再定義）** → Unit 004
- **`aggregate_issue_enabled` 仕様 SoT 定義** → Unit 001（完了済）
- **§1.2.5 セルフレビュー + 判別ガイド** → Unit 002（完了済）

## 実装方針

### Phase 1: 設計

- **ドメインモデル**:
  - `FactRow`: 事実テーブル 1 行（項目 / 値 / 出典）
  - `FactTable`: FactRow の集合（出力単位）
  - `SourceKind`: { decisions, review_summary, history, jsonl }
  - `ExtractionContext`: cycle / source 集合 / jsonl path （opt-in）
  - `ExtractionResult`: FactTable + warn 集合（不在 source 等）
  - `Extractor`（抽象的役割）: 1 source を `FactRow` 配列に変換する責務単位
  - `Renderer`（抽象的役割）: `FactRow` 配列を §1.1.5 互換 markdown 表に整形する責務単位
  - `Orchestrator`（抽象的役割）: extractors を順次起動し、結果を renderer に流す責務単位（公開 API はこの層）
- **論理設計**:
  - 公開シンボル一覧（SoT）: `retrospective_api_extract_facts` 1 本のみ。internal 関数は `_retrospective_fact_extract_*` プレフィックスで公開非対象を表明
  - 公開 API シグネチャ: `retrospective_api_extract_facts <cycle> [<jsonl_path>]`（標準出力に markdown 表 / 標準エラーに warn）
  - **3 層内部関数分割**:
    - L1 extractors: `_retrospective_fact_extract_decisions` / `_retrospective_fact_extract_review_summary` / `_retrospective_fact_extract_history` / `_retrospective_fact_extract_jsonl_optional`
    - L2 renderer: `_retrospective_fact_extract_render_markdown`
    - L3 orchestrator: `retrospective_api_extract_facts`（Facade 公開関数 / extractors を順次起動 → renderer 呼び出し）
  - 各 extractor の出力契約（中間形式）: `kind|item|value|source_path` の pipe-separated 1 行 / 1 FactRow（バイナリ互換性のための SoT）
  - 集計ロジック（L1 内部）: DR 件数（`grep -c '^## DR-'`）/ review round 数（review-summary の round 見出し集計）/ 指摘件数（指摘箇条書きカウント）/ defer 件数（defer ラベル付き行）
  - 時系列イベント抽出（L1 内部）: history/*.md の見出し（H2 以上）+ 直後 1 行を「YYYY-MM-DD HH:MM | 概要」化、最大 5 件
  - jsonl 抽出（L1 内部）: line-by-line で `type=event` 系の構造化エントリを抽出、機密フィルタ後にタイムスタンプ + summary に正規化
  - 表示互換契約（L2 内部）: §1.1.5 手動経路と diff 0 を保証。手動運用で観測される列順序・行順序・空白を固定し、Renderer 層のみが表現形式を知る
  - retrospective-api.sh 統合方式: Facade から `retrospective-fact-extract.sh` を source（多重 source ガード適用）。公開 API としては `retrospective_api_extract_facts` のみを登録、internal symbol は呼出側 namespace を汚染しない
  - bats fixture: 本サイクル `.aidlc/cycles/v2.6.5/` を実データ fixture として流用（Unit 定義技術考慮事項に明記）

### Phase 2: 実装

> 補足: review_round_total 集計仕様は「`**反復回数**: N` 行の N を数値合計」を一次方針、Set/Round 見出し数を補助カウントとする。Phase 2 で実装確定。

1. `skills/aidlc/scripts/lib/retrospective-fact-extract.sh` 新規追加（internal 関数のみ: L1 extractors + L2 renderer / `_retrospective_fact_extract_*` プレフィックス遵守）
2. `skills/aidlc/scripts/lib/retrospective-api.sh` から source + 公開関数 `retrospective_api_extract_facts`（L3 orchestrator）追加
3. bats テスト追加（単体 / 統合 / jsonl / 機密フィルタ / パフォーマンス）
4. shellcheck pass 確認

### Phase 3: テスト

- bats 全テスト pass
- 既存 retrospective テスト群（`tests/retrospective_*.bats`）regression なし
- パフォーマンス確認: `time` 計測で 5 秒以内

## 完了条件チェックリスト

- [ ] `skills/aidlc/scripts/lib/retrospective-fact-extract.sh` が新規追加され（private 実装層）、`retrospective-api.sh` から source されている
- [ ] 3 source（decisions / review-summary / history）の抽出関数が実装されている
- [ ] jsonl file path 引数渡しの opt-in 処理が実装されている
- [ ] 出力 markdown 表が §1.1.5 既定列構成と完全一致する
- [ ] 機密情報フィルタが jsonl 入力に適用される
- [ ] source 不在時の warn + スキップ動作が実装されている
- [ ] 公開 API は `retrospective_api_extract_facts` 1 本のみ（内部 lib 直接 source 禁止が守られる）
- [ ] L1 extractors / L2 renderer / L3 orchestrator の 3 層分離が実装に反映されている（責務単一・相互汚染なし）
- [ ] `retrospective-fact-extract.sh` 内の internal 関数が `_retrospective_fact_extract_*` プレフィックス規約に従っている
- [ ] bats 単体テスト（各 source × 正常系 / 空 / 不在）が追加され全て pass
- [ ] bats 統合テスト（手動 §1.1.5 経路と helper 経路の diff 0）が追加され pass
- [ ] bats jsonl テスト（引数あり / なし）が追加され pass
- [ ] bats 機密フィルタテストが追加され pass
- [ ] 既存 §1.1.5 手動 Read 経路を破壊していない（regression なし）
- [ ] 設計ドキュメント（ドメインモデル + 論理設計）が `.aidlc/cycles/v2.6.6/design-artifacts/` 配下に作成されている
- [ ] AI レビュー（設計 / コード / 統合）を codex で実施し全 clean
- [ ] shellcheck pass
- [ ] markdownlint pass（`markdown_lint=true`）

## SC マッピング（Intent との対応）

- **SC-07**: 一次情報三層検証 helper が opt-in で追加され、(a)/(b)/(c) の 3 source + (d) jsonl の file path 引数渡しを処理可能。既存 §1.1.5 手動 Read 経路は破壊されず後方互換 fixture テストで動作維持

## 依存関係

- **依存する Unit**: なし
- **依存される Unit**: なし（Unit 004 は本 Unit 完了を前提としない）
- **外部依存**: jsonl の典型パス（`~/.claude/projects/<repo>/*.jsonl`）は任意引数のみ扱う

## 想定リスク・留意点

- **§1.1.5 手動経路との diff 0 保証**: 列順序・行順序・空白の固定が崩れると後方互換が破壊される。bats 統合テストで強制
- **bash dynamic scope shadowing**: result-out 関数を実装する場合、CLAUDE.md 規約「printf -v 系 result-out 関数の local 命名規約」（`_local_<関数省略名>_<名>` プレフィックス）を遵守
- **Bash ツール経由のコマンド置換禁止**: CLAUDE.md「AI エージェント Bash ツール経由の安全パターン」遵守。テスト fixture 作成 / helper 内部実装ともに `$(...)` / backtick を Bash ツール引数文字列に直書きしない
- **shellcheck**: SC2030/SC2031 系は subshell 限定なので別系統で検出。命名規約が主防御線
- **機密情報フィルタの false positive**: 正規表現マスクは安全側に倒す（誤マスクが情報損失を起こしても、漏洩よりはマシ）

## レビュー観点

設計レビュー:

- ドメインモデルが Unit 003 のスコープ（3 source MVP + jsonl 引数 opt-in）に過不足なく対応しているか
- 後方互換（§1.1.5 手動経路との diff 0）の論理保証が設計に組み込まれているか
- スキル間依存ルール（公開 API 1 本化）が守られているか
- 役割 3 層分離（extractors / renderer / orchestrator）が設計に反映されているか
- 公開シンボルが `retrospective_api_extract_facts` 1 本のみで、internal は `_retrospective_fact_extract_*` プレフィックスに統一されているか
- jsonl 機密フィルタの設計が漏洩リスクと false positive のバランスを取れているか

コードレビュー:

- shellcheck pass
- result-out 関数の命名規約遵守
- Bash ツール経由のコマンド置換禁止遵守
- 公開 API 以外を caller が呼べないことを構造で保証（多重 source ガード等）

統合レビュー:

- bats テスト全 pass
- 手動 §1.1.5 経路との diff 0
- パフォーマンス NFR（5 秒以内）達成
- markdownlint pass

## 次のアクション

承認後、Phase 1（設計）に着手:

1. ドメインモデル設計 → `.aidlc/cycles/v2.6.6/design-artifacts/domain-models/unit_003_fact_extract_helper_domain_model.md`
2. 論理設計 → `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_003_fact_extract_helper_logical_design.md`
3. 設計 AI レビュー（codex）
4. 設計承認
