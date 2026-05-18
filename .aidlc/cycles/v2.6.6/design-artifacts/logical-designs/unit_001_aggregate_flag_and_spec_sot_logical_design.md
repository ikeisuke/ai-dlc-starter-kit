# 論理設計: Unit 001 — T 中心アウトプット仕様 + `aggregate_issue_enabled` フラグ + cap 仕様 SoT 定義

## 概要

Unit 001 の論理コンポーネント構成と公開インターフェース・配置を確定する。本 Unit は仕様 SoT + opt-in フラグ + 同等性オラクル fixture + 判定 helper を提供し、起票実装本体は Unit 004 へ委譲する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## 事前コード読込み（v2.6.5 / #679 / Unit 002 由来 / 必須）

ドメインモデル冒頭の同名セクションが SoT。本論理設計でも監査性確保のため **(a)(b)(c) を再掲** し、論理設計起草時に踏まえた既存挙動・代替案を明示する。

### (a) Read 対象ファイル + 目的

| パス | Read 目的（論理設計レベル） |
|------|--------------------------|
| `skills/aidlc/scripts/lib/retrospective-api.sh` | 公開 API Facade パターンの踏襲 / タイプ A/B 関数の境界線 / 多重 source ガード / bootstrap の影響範囲確認 / helper 追加挿入位置の確定 |
| `skills/aidlc-retrospective/steps/retrospective.md` | §1.5 前置き挿入位置（既存 Step 1 直前）の確定 / 既存 `auto_issue_creation` inline 評価形式との比較（helper 化採用根拠） |
| `skills/aidlc/config/defaults.toml` | `[rules.retrospective]` セクションへの追加位置（`auto_issue_creation = true` 直後）/ コメント文体規約 |
| `skills/aidlc-setup/config/defaults.toml` | 二重 SoT 配布用コピーの sync 形式・正本コピーヘッダ位置 / CI 早期検出ガード（v2.6.5 Unit 004）が検証する差分形式の確認 |
| `skills/aidlc-retrospective/SKILL.md` | 冒頭 SoT 文言追加位置 / 単方向境界節（`v2.6.4 サイクル対象外項目`）との整合確認 |

### (b) 設計時に意識すべき挙動

- **既存 `auto_issue_creation` の inline 評価ロジック**: `steps/retrospective.md` §1.5 Step 2 #opt-in 基盤フラグ節は inline bash で `read-config.sh` を呼び、`rc=0/1/その他` を区別して `auto_issue` 変数に解決する形式。本 Unit でも同様の inline 化が可能だが、Unit 004 からも同等処理を必要とするため **helper 化（DRY 化）** が望ましい
- **fail-safe vs fail-open の意味差**: 既存 `auto_issue_creation` は取得失敗時 `true` = 既存動作（起票継続）の **fail-open**。本 Unit の `aggregate_issue_enabled` は取得失敗時 `false` = 既定動作（T ループ）の **fail-safe**。方向が逆である理由は「v2.6.6 以降の既定が新挙動側 = `false`」と「`true` を選択すると v2.6.5 集約 Issue 起票が走るため、未設定誤起票を避けたい」の 2 点
- **タイプ B 関数規約の制約**: stdout に 1 行純粋値のみ。warn は stderr 限定。これにより呼び出し側は `read var < <(...)` 相当の単純読み取りで処理可能
- **二重 SoT CI ガード**: `aidlc-setup/config/defaults.toml` 冒頭ヘッダに「正本: aidlc スキルの config/defaults.toml」と明示済。CI 早期検出ガード（v2.6.5 Unit 004）が両者差分を検出して fail させる。追加コメント・空白も含めて完全一致が必須
- **helper 配置位置の決定根拠**: タイプ B 関数群末尾（境界線 `# ─── 公開 API（タイプ A...）` の直前）に配置することで、Facade の論理構造を維持

### (c) 既存実装に基づく代替案検討（論理設計レベル）

| 方針候補 | 既存実装との適合性 | 採用/却下 |
|---------|------------------|----------|
| **helper 経由（`retrospective_api_aggregate_enabled` 一本）** | DRY / Unit 004 からも再利用 / fail-safe 仕様を helper 単独で保証 / 既存タイプ B 関数群の慣例を踏襲 | **採用** |
| **inline bash で §1.5 前置きに直接記述（既存 `auto_issue_creation` と同形式）** | 一貫性はあるが Unit 004 でも同様の inline 記述が必要になり重複。fail-safe ロジックも 2 箇所に分散 | 却下（DRY 違反 / SoT 単一化原則違反） |
| **既存 `auto_issue_creation` を流用（フラグを 1 つに統合）** | 「起票 ON/OFF」と「起票形態」の **異なる軸の意味** を 1 フラグに詰めることになり概念汚染 | 却下（Intent で「別軸の opt-in」として明示済み） |
| **fixture を bats 内インライン定義（外部ファイル化しない）** | 短期的にはファイル数を減らせるが、v2.7.0+ で T ループ実装と同等性検証する際に fixture の再利用ができず再記述コスト | 却下（外部ファイル化 + SoT 単一化を選択） |
| **正規化規則を fixture JSON 内に持つ** | fixture と test の両方に規則が存在し SoT 二重化 | 却下（テストコード側 `tests/lib/retrospective_normalize.bash` 単一 SoT を選択） |

## アーキテクチャパターン

- **公開 API 層 + 内部 lib 分離パターン**（既存 `retrospective-api.sh` Facade パターンを継承）
- **fail-safe フォールバックパターン**（取得失敗時に既定値 `false` に倒し、呼び出し側を hard fail させない）
- **SoT 単一化パターン**（仕様文言 / 正規化規則 / fixture 期待値の重複を避け、各 1 箇所のみに定義）

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/
├── aidlc-retrospective/
│   ├── SKILL.md                                # 冒頭 SoT 文言追加
│   └── steps/
│       └── retrospective.md                    # 冒頭 SoT 文言 + §1.5 前置き仕様節
├── aidlc/
│   ├── config/
│   │   └── defaults.toml                       # rules.retrospective.aggregate_issue_enabled = false 追加
│   └── scripts/
│       └── lib/
│           └── retrospective-api.sh            # retrospective_api_aggregate_enabled helper 追加
└── aidlc-setup/
    └── config/
        └── defaults.toml                       # 二重 SoT sync（aidlc 側と同一エントリ）

tests/
├── fixtures/
│   └── retrospective_v265_aggregate.json       # 同等性オラクル fixture（v2.6.5 実データ）
├── lib/
│   └── retrospective_normalize.bash            # 正規化規則 SoT（normalize_volatile 実装）
└── retrospective_aggregate_enabled.bats        # 同等性テスト + helper 契約テスト（新規 or 既存ファイル拡張）
```

### コンポーネント詳細

#### 1. `skills/aidlc-retrospective/SKILL.md`（冒頭 SoT 文言追加）

- **責務**: スキル全体の目的を T 中心として明示
- **挿入位置**: 冒頭見出し `# AI-DLC 振り返り（retrospective）` の直下、既存「サイクル完了後の振り返り...」段落の **直前**
- **挿入文言（SoT 固定）**:

  ```text
  > **目的**: T を Issue 化して実行に繋げること。KPT は T を導くための手段です（v2.6.6 / #710 / Unit 001 / SC-01）。
  ```

- **依存**: なし
- **公開インターフェース**: なし（ドキュメント）

#### 2. `skills/aidlc-retrospective/steps/retrospective.md`（冒頭 SoT 文言 + §1.5 前置き仕様節）

- **責務**: 実行ステップの目的明示 + `aggregate_issue_enabled` 仕様節 SoT 化
- **挿入位置 1（冒頭 SoT 文言）**: 冒頭見出し `# /aidlc-retrospective 実行ステップ` の直下、既存「サイクルを振り返り...」段落の **直前**
- **挿入文言（冒頭）**: SKILL.md と同一文言（SC-01 で「両方冒頭」を要求）
- **挿入位置 2（§1.5 前置き仕様節）**: 既存 `## 1.5 Issue 起票フロー（v2.5.1+ / Unit 002）` 見出しの直下、`### Step 1: ...` 見出しの **直前**
- **挿入文言（§1.5 前置き / 抜粋）**:

  ```text
  ### 1.5 前置き: aggregate_issue_enabled 仕様（v2.6.6 / #710 / Unit 001 / SC-04）

  本ステップの動作は `rules.retrospective.aggregate_issue_enabled`（既定 `false`）で切り替わる:

  | 値 | 動作 | cap 判定対象 |
  |----|------|-------------|
  | `false`（既定 / v2.6.6+） | T ループ起票（Unit 004 実装） | サイクル内 T Issue 起票合計 |
  | `true`（opt-in / v2.6.5 互換） | 集約 Issue 1 件起票（既存 Step 3/4/5） | 集約 Issue 1 件 |

  値解決は `retrospective_api_aggregate_enabled` helper 経由（公開契約: stdout `true|false` / exit 0 / fail-safe `false`）。
  ```

- **依存**: `retrospective_api_aggregate_enabled`（helper）
- **公開インターフェース**: なし（ドキュメント / SoT）

#### 3. `skills/aidlc/scripts/lib/retrospective-api.sh`（helper 追加）

- **責務**: `aggregate_issue_enabled` フラグ値を解決して `true|false` を返す（fail-safe 保証）
- **追加関数**: `retrospective_api_aggregate_enabled`（タイプ B / 純粋値 1 行）
- **依存**: `scripts/read-config.sh`
- **公開インターフェース**: 後述「スクリプトインターフェース設計」セクション
- **配置位置（ファイル内）**: タイプ B 関数群末尾（既存 `retrospective_api_prefill` の直後）。タイプ A 関数群との境界線（`# ─── 公開 API（タイプ A / 副作用あり）───`）の **直前**

#### 4. `skills/aidlc/config/defaults.toml` / `skills/aidlc-setup/config/defaults.toml`（二重 SoT 追加）

- **責務**: フラグの既定値 `false` を 4 階層マージの最下層に定義
- **追加位置**: `[rules.retrospective]` セクション末尾（既存 `auto_issue_creation = true` の **直後**）
- **追加エントリ**:

  ```toml
  # 振り返り出力モードの集約 Issue opt-in フラグ（v2.6.6 / #710 / Unit 001）
  # - false（デフォルト / v2.6.6 新既定）: 集約 Issue 起票を行わず、T Issue ループ起票（Unit 004 実装）を実行
  # - true（v2.6.5 互換 opt-in）        : 既存 §1.5 Step 3/4/5 を実行して集約 retrospective Issue を 1 件起票
  # auto_issue_creation（起票 ON/OFF 軸）とは独立の opt-in 軸（起票形態軸 / 集約 vs T ループ）。
  # 値解決失敗時は scripts/lib/retrospective-api.sh の retrospective_api_aggregate_enabled が
  # 既定 false にフォールバックする（fail-safe）。
  # cap 判定（feedback_max_per_cycle）の対象は本フラグで連動切り替え:
  #   - true: 集約 Issue 1 件の上限 / - false: サイクル内 T Issue 起票合計の上限
  # 詳細仕様は skills/aidlc-retrospective/steps/retrospective.md §1.5 前置き仕様節を SoT として参照。
  aggregate_issue_enabled = false
  ```

- **二重 SoT sync**: 両ファイル完全同一文言で追加。v2.6.5 Unit 004 由来の CI 早期検出ガード（sync 検証）が pass することを実装フェーズで確認

#### 5. `tests/fixtures/retrospective_v265_aggregate.json`（同等性オラクル fixture）

- **責務**: v2.6.5 集約 Issue 起票結果のスナップショット（期待値のみ）
- **形式**: JSON
- **フィールド**: 後述「データモデル概要」セクション
- **生成元**: v2.6.5 実データ（取得手順は後述「処理フロー概要 / fixture 生成」）
- **依存**: なし（純粋データ）

#### 6. `tests/lib/retrospective_normalize.bash`（正規化規則 SoT）

- **責務**: `normalize_volatile()` 関数の単一 SoT 実装
- **公開インターフェース**: 後述「スクリプトインターフェース設計」セクション
- **依存**: 標準 unix tools（`sed` / `sha256sum`）

#### 7. `tests/retrospective_aggregate_enabled.bats`（同等性テスト + helper 契約テスト）

- **責務**: 以下 4 系統のテスト
  - (a) **SC-04 同等性テスト**: `aggregate_issue_enabled = true` 時の実起票結果（テスト環境で再現生成）を fixture と比較し差分 0 を確認
  - (b) **helper 契約テスト（正常系）**: `read-config.sh` exit 0 + `true|false` 値で stdout 一致 / exit 0 / stderr 出力なし
  - (c) **helper 契約テスト（fail-safe / warn 有無を区別）**:
    - `read-config.sh` exit 1（キー不在）: stdout=`false` + exit 0 + **stderr warn なし**
    - `read-config.sh` exit 0 + 不正値（`true|false` 以外）: stdout=`false` + exit 0 + **stderr warn あり**
    - `read-config.sh` exit 2 以上（読み取り層エラー）: stdout=`false` + exit 0 + **stderr warn あり**
  - (d) **既存シグネチャ不変テスト**: `grep` で `retrospective_api_*` 公開関数定義の差分が helper 追加分のみであることを確認
- **依存**: 上記 fixture / 正規化 helper / 既存 bats 環境

## インターフェース設計

### スクリプトインターフェース設計

#### `retrospective_api_aggregate_enabled`（関数 / helper）

##### 概要

`rules.retrospective.aggregate_issue_enabled` フラグ値を `true|false` の純粋値として返す。fail-safe で常に `exit 0`。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| なし | - | 引数を受け取らない（環境から `read-config.sh` 経由で解決） |

##### 成功時出力

```text
true
```

または

```text
false
```

- 終了コード: `0`（常に）
- 出力先: stdout（末尾改行あり / 1 行）

##### エラー時出力（= fail-safe フォールバック / ドメインモデル・計画書と完全一致）

| `read-config.sh` の状態 | stdout | exit | stderr warn |
|------------------------|--------|------|-------------|
| exit 1（キー不在 / 既定動作） | `false` | 0 | **なし** |
| exit 0 + 不正値（`true|false` 以外） | `false` | 0 | あり（1 行） |
| exit 2 以上（読み取り層エラー） | `false` | 0 | あり（1 行） |

warn 1 行の書式例（不正値 / 読み取り層エラー時）:

```text
[warn] retrospective_api_aggregate_enabled: read-config.sh が rc=<N> または不正値 "<value>" を返したため既定 false にフォールバックします
```

##### 使用コマンド

```bash
# 直接呼び出し（テスト）
source skills/aidlc/scripts/lib/retrospective-api.sh
retrospective_api_aggregate_enabled
# → "true" or "false"

# steps/retrospective.md §1.5 前置きでの参照（疑似コード / 実装は Unit 004）
retrospective_api_aggregate_enabled > /tmp/aidlc-agg-enabled.txt
read aggregate_enabled < /tmp/aidlc-agg-enabled.txt
if [[ "$aggregate_enabled" == "true" ]]; then
    # 既存 §1.5 Step 3/4/5 を実行（aggregate モード）
else
    # T ループ起票（Unit 004 実装 / t_loop モード）
fi
```

##### 内部処理（疑似フロー / 実装は Phase 2 / ドメインモデル・計画書と完全一致）

1. `scripts/read-config.sh rules.retrospective.aggregate_issue_enabled` を呼ぶ（exit code 捕捉）
2. exit 0 + 値が `true` または `false` → そのまま stdout 出力 + exit 0
3. exit 0 + 値が `true|false` 以外（不正値） → stderr warn + stdout=`false` + exit 0
4. exit 1（キー不在 / 既定動作扱い） → stdout=`false` + exit 0 / **warn なし**
5. exit 2 以上（読み取り層エラー） → stderr warn + stdout=`false` + exit 0

#### `normalize_volatile`（関数 / 正規化 helper）

##### 概要

入力テキストから揺らぎ項目（タイムスタンプ / セッション ID / 環境固有絶対パス / 生成時差分要因）を除外し、正規化済みテキストを stdout に出力する。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `<入力テキスト>` | stdin | 正規化対象（複数行可） |

##### 成功時出力

```text
<正規化済みテキスト>
```

- 終了コード: `0`
- 出力先: stdout

##### 使用コマンド

```bash
load tests/lib/retrospective_normalize.bash
echo "$body" | normalize_volatile
# または: normalize_volatile <<< "$body"
```

##### 正規化対象 allowlist（実装で適用する置換規則）

| 種別 | 正規表現パターン例 | 置換後 |
|------|------------------|--------|
| ISO 8601 タイムスタンプ | `[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\+[0-9]{2}:[0-9]{2})?` | `<TIMESTAMP>` |
| JST 形式タイムスタンプ | `[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}( JST)?` | `<TIMESTAMP>` |
| セッション ID（UUID v7 等） | `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}` | `<SESSION_ID>` |
| ホーム配下絶対パス | `/Users/[^/]+/`, `/home/[^/]+/` | `~/` |
| `generated_at: ...` 行 | `generated_at: .*` | `generated_at: <TIMESTAMP>` |

##### 正規化しないキー（比較必須）

Issue タイトル / 本文 `## / ###` 見出し行 / ラベル名 / cap の `current_count` / `over` 数値 / 各見出し配下の本文非変動部分。

## データモデル概要

### ファイル形式: `tests/fixtures/retrospective_v265_aggregate.json`

- **形式**: JSON
- **主要フィールド**:

  | フィールド | 型 | 説明 |
  |-----------|----|----- |
  | `meta.source` | string | 生成元の説明（例: `"v2.6.5 milestone retrospective Issue #NNN"` または `".aidlc/cycles/v2.6.5/<artifact-path>"`） |
  | `meta.captured_at` | string | fixture スナップショット取得日（ISO 8601） |
  | `meta.fixture_version` | string | fixture フォーマットバージョン（例: `"1.0.0"`） |
  | `expected_title` | string | 集約 Issue タイトル（完全一致対象） |
  | `expected_heading_set` | array<string> | 本文 `##` / `###` 見出し行の順序込み列 |
  | `expected_normalized_body_hash` | string | `normalize_volatile()` 適用後本文の sha256 ハッシュ（hex） |
  | `expected_labels` | array<string> | ラベル集合（test 側で順不同集合一致を取る） |
  | `expected_cap.current_count` | integer | v2.6.5 起票時の `current_count` |
  | `expected_cap.over` | boolean | `over` フラグの期待値 |

- **正規化規則は格納しない**（規則本体は `tests/lib/retrospective_normalize.bash` 単一 SoT）

## 処理フロー概要

### フロー 1: helper 値解決の処理フロー

1. 呼び出し側（steps/retrospective.md §1.5 前置き / Unit 004 実装）が `retrospective_api_aggregate_enabled` を呼ぶ
2. helper が `scripts/read-config.sh rules.retrospective.aggregate_issue_enabled` を実行（exit code を捕捉）
3. 取得結果を判別:
   - `exit 0` + 値 `true|false` → stdout に出力 + exit 0
   - `exit 0` + 不正値 → stderr warn + stdout `false` + exit 0
   - `exit 1` → stdout `false` + exit 0
   - `exit 2 以上` → stderr warn + stdout `false` + exit 0
4. 呼び出し側が stdout を読み取り、`true|false` 2 値分岐で処理

**関与するコンポーネント**: `retrospective_api_aggregate_enabled` / `scripts/read-config.sh`

### フロー 2: 同等性テスト実行の処理フロー

1. test setup: `tests/fixtures/retrospective_v265_aggregate.json` をロード
2. テスト環境で `aggregate_issue_enabled = true` を設定
3. retrospective 本文生成パス（既存 §1.5 Step 3）を実行して `actual_body` を取得
4. `tests/lib/retrospective_normalize.bash` の `normalize_volatile()` で actual_body を正規化
5. 正規化済み actual_body の sha256 を fixture の `expected_normalized_body_hash` と比較
6. タイトル / 見出し列 / ラベル集合 / cap の 4 系統も比較
7. 全項目差分 0 で pass

**関与するコンポーネント**: bats / `normalize_volatile` / fixture / retrospective 本文生成パス

### フロー 3: fixture 生成（二段階基準 / Unit 001 統合レビューで確定）

**Unit 001 段階基準（本 Unit 完了条件 = schema-only）**:

1. fixture スキーマ（meta / expected_title / expected_heading_set / expected_normalized_body_hash / expected_labels / expected_cap）を `fixture_status="schema-only"` で配置
2. 実値（タイトル / hash / cap）は placeholder のまま
3. 構造検証 bats（FIX1-3）と正規化 helper 動作検証（NRM1-5）で Unit 001 段階の SC-04 を充足

**Unit 004 finalize 基準（最終達成）**:

1. Unit 004 が aggregate path フル実起票テスト（テスト環境で `aggregate_issue_enabled=true` 設定 → §1.5 Step 3 を呼ぶ）を実行
2. 生成された集約 Issue 本文を `normalize_volatile()` で正規化し sha256 を算出 → fixture 実値（`fixture_status="finalized"`）へ反映
3. 差分 0 同等性 bats を新規追加（Unit 004 統合フェーズの責務）

**v2.6.5 実データ不在の事実（Unit 001 統合レビューで確認）**: `gh issue list --milestone v2.6.5 --label retrospective` の結果は #714 / #712 / #722 / #723 / #724（個別 backlog / T Issue / 集約 Issue タイトル `Retrospective: v2.6.5` 規約に合致するものなし）。v2.6.5 で集約 Issue 起票機能は実起票されていない。よって fixture 生成元は「v2.6.6 リリース時点 aggregate path コード生成 output」を SoT とする（Intent SC-04 の二段階解釈）。

**関与するコンポーネント（Unit 001 段階）**: `normalize_volatile` / fixture JSON ファイル
**関与するコンポーネント（Unit 004 段階）**: 上記 + aggregate path 起票関数（`retrospective_body_compose` 等）

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 起票 helper 追加による既存処理オーバーヘッド 5% 以内
- **対応策**: helper 追加は §1.5 前置き / Unit 004 経路でのみ呼ばれる新パス。既存処理（§1.5 Step 3/4/5）には helper 呼び出しを差し込まない（aggregate モード時は既存パスをそのまま実行）。よって既存処理への影響は **構造的に 0%**。helper 1 回呼び出し当たりのコストは `read-config.sh` 1 回 + 数行の bash 評価で 100ms 以内見込み

### セキュリティ

- **要件**: 新規 fixture に GitHub トークン / 個人情報を含めない
- **対応策**: `normalize_volatile()` でホーム配下絶対パス / セッション ID を正規化済みにする。fixture コミット前に `grep -nE '/Users/|/home/[^/]+/|ghp_|gho_|github_pat_'` で確認

### 後方互換性

- **要件**: `aggregate_issue_enabled` 未設定の v2.6.5 以前 consumer がアップグレード時にエラーなし
- **対応策**: 4 階層マージで `defaults.toml` の `false` が解決される。helper も fail-safe で常に `exit 0`。consumer 側の `config.toml` に新キーが無くても hard fail しない

## 技術選定

- **言語**: bash（既存 `retrospective-api.sh` と同一）
- **テストフレームワーク**: bats（既存テスト群と同一）
- **データ形式**: TOML（config）/ JSON（fixture）
- **ハッシュ**: `sha256sum`（macOS / Linux 両対応の標準 unix tool）

## 実装上の注意事項

- **multi source ガード**: `retrospective-api.sh` の既存ガード（`RETROSPECTIVE_API_SOURCED`）を尊重し、helper 追加位置を境界線 `# ─── 公開 API（タイプ A...）` の前に固定
- **タイプ B 関数規約**: stdout に「raw text 1 行 / 純粋値」のみ。stderr / 他出力を混在させない（warn は stderr 限定）
- **fail-safe SoT 一貫性**: helper / fixture 取得失敗時の挙動を「Unit 001 計画書 §必須対応 4」「ドメインモデル §概念 3」「本論理設計のスクリプトインターフェース節」の 3 箇所で完全一致させる（契約二重化禁止）
- **二重 SoT 同期**: `aidlc/config/defaults.toml` と `aidlc-setup/config/defaults.toml` は **完全同一文言**（コメント含む）で sync する。CI 早期検出ガード（v2.6.5 Unit 004）が差分を検出して fail させる

## 実装制約（本リポジトリ規約）

- **Bash ツール経由のコマンド置換禁止**: helper 実装 / bats テスト / ドキュメント内 bash サンプルのいずれでも、AI 起動 Bash ツールの引数文字列に `$(...)` / backtick を含めない（SoT: `CLAUDE.md` §「AI エージェント Bash ツール経由の安全パターン」）
- **result-out 関数の local 命名規約**: `retrospective-api.sh` 系列で `printf -v "$result_var"` 形式の result-out 関数を新設する場合、内部 local は `_local_<関数省略名>_<名>` 形式の namespace 付き命名を必ず適用する（dynamic scope shadowing による caller 変数空残しバグの予防 / v2.6.3 / #706 / SoT: `CLAUDE.md` §「printf -v 系 result-out 関数の local 命名規約」）。**本 Unit の `retrospective_api_aggregate_enabled` は stdout 出力型のため本規約の直接適用対象外だが、helper 拡張時 / 内部 helper 関数追加時に違反しないことを Phase 2 実装でレビューする**
- **codex 非対話実行時の stdin 待ちガード**: bats / CI / レビュー自動化スクリプトから codex を呼ぶ箇所では、`</dev/null` 付与または `codex exec - < <file>` 形式を必須とする（SoT: `CLAUDE.md` §「codex exec の stdin 待ちガード」）

## 不明点と質問

- [Question] `tests/lib/` に既存 bats helper があり命名規約が存在するか？
- [Answer] 実装フェーズ着手時に `ls tests/lib/ 2>/dev/null && ls tests/*.bats | head -3` で確認。既存命名がある場合はそれに整合
- [Question] `aidlc-setup/config/defaults.toml` の sync 検証は GitHub Actions のどのワークフローで実行されているか？
- [Answer] 実装フェーズ着手時に `.github/workflows/` を grep して特定（v2.6.5 Unit 004 で追加された経路名を確認）。本 Unit はそのワークフローが本サイクル変更でも pass することを完了条件にする
