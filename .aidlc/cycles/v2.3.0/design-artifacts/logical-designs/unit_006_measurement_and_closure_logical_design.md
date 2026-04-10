# 論理設計: Unit 006 - 削減目標達成の計測レポートと #519 クローズ判断

## 概要

ドメインモデルで定義した計測 → 判定 → Issue 操作のフローを、bash スクリプト 1 本（`bin/measure-initial-load.sh`）と人手・手動オペレーションが組み合わさった軽量パイプラインとして論理設計する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的なコード（bash 実装、レポート本文、Issue 本文等）は Phase 2（コード生成ステップ）で作成する。

## アーキテクチャパターン

**Pipes & Filters + Manual Glue（最小オーケストレーション）**を採用する。

選定理由:

- 計測ロジックを bash スクリプトに完全集約することで「正本の単一性」と「決定論性」を物理的に保証する
- Issue 操作・レポート作成は人手判断が含まれるため、AI エージェントが対話的に実行するフローとして残す（過剰な自動化は新規バグを生む）
- 既存の `scripts/*.sh` / `bin/check-bash-substitution.sh` と整合する配置・スタイルにすることで、レビュー観点を既存パターンに揃える

## コンポーネント構成

### レイヤー / モジュール構成

```text
Unit 006 計測・クローズパイプライン
├── 計測層（純粋関数 / bash スクリプト）
│   └── bin/measure-initial-load.sh
│       ├── BASELINE_REF 検証ステージ
│       ├── ベースラインファイル展開ステージ（git show）
│       ├── tiktoken 計測ステージ（python via /tmp/anthropic-venv）
│       └── 出力フォーマッタ
├── レポート層（人手 + AI による転載と解説）
│   └── .aidlc/cycles/v2.3.0/measurement-report.md
│       └── §1〜§9（§3, §4 はスクリプト出力転載）
├── 判定層（人手判断 + ドメインロジック）
│   ├── 段階 1 評価: スクリプト出力 TOTAL ≤ 閾値
│   ├── 段階 2 評価: Unit 001-005 検証記録の引用照合（expected_assertion 充足）
│   └── boilerplate 機械検証（補助項目、#519 クローズ非阻害）
│       ├── 軸 1: ステップファイル群合計 tok 比較（v2.2.3 vs v2.3.0、tiktoken）
│       └── 軸 2: index.md 集約証跡（applicability ○ パターンの存在確認）
├── Issue 操作層（gh CLI 経由の副作用境界）
│   ├── クローズ判断コメント投稿
│   ├── 達成時操作: ラベル更新 + クローズ
│   └── 未達時操作: 構造化バックログ Issue 作成
└── ドキュメント更新層
    ├── CHANGELOG.md 追記
    ├── Unit 定義ファイル状態更新
    └── 検証記録 / 履歴記録 作成
```

### コンポーネント詳細

#### `bin/measure-initial-load.sh`

- **責務**: 計測対象ファイルリストの正本管理、`BASELINE_REF` 検証、v2.2.3 ベースライン展開、tiktoken 計測、結果のフォーマット出力
- **依存**:
  - 外部コマンド: `git`（show, rev-parse）, `mktemp`, `/tmp/anthropic-venv/bin/python3`
  - Python 依存: `tiktoken` (cl100k_base)
- **公開インターフェース**: 引数なしで実行 → stdout に Inception / Construction / Operations の v2.2.3 / v2.3.0 計測結果を出力（フォーマット詳細は「スクリプトインターフェース設計」参照）

#### 計測レポート (`measurement-report.md`)

- **責務**: スクリプト出力の人間向け転載 + 達成判定の解説 + Intent 成功基準対照表
- **依存**: `bin/measure-initial-load.sh` の出力 / Unit 001-005 の検証記録
- **公開インターフェース**: なし（成果物ファイル）

#### 判定処理（AI エージェント手動オーケストレーション）

- **責務**: スクリプト出力から段階 1 評価、検証記録引用照合（`expected_assertion` ベース）から段階 2 評価、boilerplate 2 軸機械検証（軸 1: ステップファイル群合計 tok 比較、軸 2: index.md 集約証跡）。boilerplate は補助項目で #519 クローズに影響しない
- **依存**: `bin/measure-initial-load.sh` 出力 / Unit 001-005 検証記録 / `git show` 出力 / `tiktoken` / `grep -l`
- **公開インターフェース**: なし（実装フェーズで AI エージェントが実行）

#### Issue 操作（`gh` CLI ラッパー、AI エージェント実行）

- **責務**: クローズ判断コメント投稿 / 達成時のラベル・クローズ操作 / 未達時のバックログ Issue 作成
- **依存**: `gh` CLI / `Issue519ClosureDecision` 値オブジェクト
- **公開インターフェース**: なし（手動実行）

#### CHANGELOG 更新

- **責務**: v2.3.0 セクションへの主要変更点と削減実績の追記
- **依存**: `CHANGELOG.md` 既存フォーマット
- **公開インターフェース**: なし

## インターフェース設計

### スクリプトインターフェース設計

#### `bin/measure-initial-load.sh`

##### 概要

v2.2.3 ベースラインと v2.3.0 現状の初回ロード tok 数を、決定論的に計測する。計測対象ファイルリストの正本でもある。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| なし | - | 引数なしで全フェーズ・全バリアントを計測 |
| `--help` | 任意 | 使い方を表示して終了 |

##### 成功時出力

```text
=== v2.2.3 BASELINE: Inception ===
<N> tok  <path>
...（全対象ファイル）
<TOTAL> tok  TOTAL

=== v2.2.3 BASELINE: Construction ===
（同様）

=== v2.2.3 BASELINE: Operations ===
（同様）

=== v2.3.0 CURRENT: Inception ===
（同様）

=== v2.3.0 CURRENT: Construction ===
（同様）

=== v2.3.0 CURRENT: Operations ===
（同様）
```

- 終了コード: `0`
- 出力先: stdout
- 改行コード: LF（バイト単位の決定論性のため）

##### エラー時出力

```text
ERROR: <理由>
```

| 終了コード | エラー条件 |
|----------|----------|
| `1` | `BASELINE_REF` と `git rev-parse v2.2.3^{commit}` 不一致 |
| `2` | `tiktoken` が import できない |
| `3` | `git show` 失敗（v2.2.3 ファイル取得不能） |
| `4` | `mktemp -d` 失敗 |

- 出力先: stderr

##### 使用コマンド

```bash
# 通常計測
bash bin/measure-initial-load.sh

# 決定論性検証（2 回連続実行してバイト単位比較）
bash bin/measure-initial-load.sh > /tmp/measure_run1.txt
bash bin/measure-initial-load.sh > /tmp/measure_run2.txt
diff /tmp/measure_run1.txt /tmp/measure_run2.txt
# 差分ゼロが期待結果

# ヘルプ
bash bin/measure-initial-load.sh --help
```

##### 計測対象ファイルリスト（スクリプト内 bash 配列の正本）

スクリプト内に以下の 4 つの bash 配列を持つ:

| 配列名 | 内容 |
|-------|------|
| `COMMON_FILES` | `SKILL.md` + `steps/common/{rules-core, preflight, session-continuity}.md` の 4 ファイル |
| `INCEPTION_BASELINE_FILES` | `inception/{01-setup, 02-preparation, 03-intent, 04-stories-units, 05-completion}.md` の 5 ファイル |
| `CONSTRUCTION_BASELINE_FILES` | `construction/{01-setup, 02-design, 03-implementation, 04-completion}.md` の 4 ファイル |
| `OPERATIONS_BASELINE_FILES` | `operations/{01-setup, 02-deploy, 03-release, 04-completion}.md` の 4 ファイル |

v2.3.0 計測時の各フェーズは `COMMON_FILES + steps/{phase}/index.md` の 5 ファイル。

`BASELINE_REF` 定数:

```text
BASELINE_REF="56c6463747b41ab74108055a933cdfe29781fb43"
```

## データモデル概要

### ファイル形式

#### `bin/measure-initial-load.sh` 出力形式

- **形式**: プレーンテキスト（LF 改行、ASCII + UTF-8）
- **主要フィールド**:
  - セクションヘッダ: `=== <variant>: <phase> ===`
  - 行: `<N> tok  <path>`（数字は右寄せ 6 桁、`tok` の前後にスペース 1 + 2、path は相対パス）
  - 末尾: `<TOTAL> tok  TOTAL`

#### `.aidlc/cycles/v2.3.0/measurement-report.md` 章構成

| 章 | 内容種別 |
|----|----|
| §1 概要 | human_narrative（目的・計測条件・`BASELINE_REF` hash・計測コマンド） |
| §2 計測対象ファイル一覧 | comparison_table（参考表示、正本はスクリプト） |
| §3 v2.2.3 ベースライン計測結果 | script_output_transcribed |
| §4 v2.3.0 計測結果 | script_output_transcribed |
| §5 差分サマリ | comparison_table（フェーズ × 差分・削減率・判定） |
| §6 boilerplate 削減状況 | comparison_table（3×4 with applicability、N/A セルあり） |
| §7 中間値突合 | comparison_table（Unit 001/003/004 中間値 vs 最終値） |
| §8 Intent 成功基準対照 | comparison_table（基準項目 × 引用元 × 達成判定） |
| §9 結論 | human_narrative（段階 1 + 段階 2 の総合判定） |

## 処理フロー概要

### ユースケース 1: 計測実行と決定論性確認

**ステップ**:

1. AI エージェントが `bin/measure-initial-load.sh` を実行（1 回目）
2. 出力を `/tmp/measure_run1.txt` 等に保持
3. 同じスクリプトを再実行（2 回目）
4. 出力を `/tmp/measure_run2.txt` 等に保持
5. `diff` でバイト単位比較し、差分ゼロを確認
6. 差分があれば即時失敗としてエラー停止

**関与するコンポーネント**: `bin/measure-initial-load.sh` のみ

### ユースケース 2: 段階 1 評価（計測達成基準）

**ステップ**:

1. ユースケース 1 で得た出力から、Inception / Construction / Operations の TOTAL 値を抽出
2. 各 phase の閾値（15,000 / 17,980 / 17,209）と単純比較
3. 3 フェーズすべてが閾値以下なら段階 1 達成

**関与するコンポーネント**: スクリプト出力（読み取り） / AI エージェント（判定）

### ユースケース 3: 段階 2 評価（Intent 成功基準項目）

**ステップ**:

1. Intent §成功基準の項目リストを取得し、各項目について `expected_assertion`（達成と見なす条件文、事前定義）を確定
2. 項目ごとに、対照表で示された引用元 Unit 検証/実装記録ファイル（実在パス）を読み込む
3. 達成根拠となり得る本文断片を `quoted_text` として抽出
4. `quoted_text` を `expected_assertion` と照合し、`evidence_status` を導出（`satisfied` / `unsatisfied` / `not_found`）
5. **`evidence_status=satisfied` の項目のみ `passed=true`**。引用が存在しても内容が `expected_assertion` を満たさない場合は `unsatisfied` として段階 2 不達となる
6. 全項目が `passed=true` の場合のみ段階 2 達成

**関与するコンポーネント**: Unit 001-005 検証/実装記録 / AI エージェント（引用照合と判定）

### ユースケース 4: boilerplate 機械検証（2 軸）

**軸 1: ステップファイル群合計 tok 比較**

1. 各フェーズについて、`steps/{phase}/0[1-5]-*.md` の全ステップファイルを v2.2.3 / v2.3.0 双方から取得
2. v2.2.3 側は `git show "$BASELINE_REF":<path>` を一時ファイルに保存
3. v2.2.3 と v2.3.0 のそれぞれについて、tiktoken (cl100k_base) で各ファイルの tok 数を計測し、フェーズ別合計を算出
4. 各フェーズで `v2.3.0 合計 ≤ v2.2.3 合計` を確認

**軸 2: index.md 集約証跡**

1. 4 パターン × 3 フェーズの applicability を `BoilerplateIndexAggregationCheck.applicable_to_phase` から取得
2. 各フェーズの index.md に対し、applicability `○` のパターンを `grep -l` で確認
3. applicability `○` のすべてが `index_md_present=true` であることを確認

**判定**: 軸 1 全フェーズ達成 ∧ 軸 2 全 ○ セル達成 → boilerplate 削減確認 PASS

> 旧方針（grep ベースの単純パターンカウント）は「ロジック記述」と「`steps/{phase}/index.md` への参照記述」を区別できないため、軸 1 を tok 数比較に変更した。

**関与するコンポーネント**: AI エージェント / git / grep / tiktoken / `StepFilesTokenComparison` / `BoilerplateIndexAggregationCheck`

### ユースケース 5: 計測レポート作成

**ステップ**:

1. ユースケース 1〜4 の結果を元に、`measurement-report.md` の各章を埋める
2. §3, §4 はスクリプト出力をフェンス付きで完全転載（改変禁止）
3. §6 は boilerplate 比較表
4. §8 は Intent 成功基準対照表（引用文付き）
5. §9 で最終結論を明示

**関与するコンポーネント**: AI エージェント / 全ユースケース結果

### ユースケース 6: #519 クローズ判断と Issue 操作

**ステップ**:

1. `Issue519ClosureDecision.is_closeable()` を評価（段階 1 ∧ 段階 2）
2. 達成時:
   - クローズ判断コメント本文を一時ファイルに書き出し、`gh issue comment 519 --body-file` で投稿
   - `gh issue edit 519 --add-label "status:done" --remove-label "status:in-progress"`
   - `gh issue close 519 --reason completed`
   - 一時ファイルを削除
3. 未達時:
   - `derive_unmet_categories()` で `UnmetCategory[]` を導出
   - 各カテゴリについて `gh issue create --title "[Backlog] {category}: {要約}" --body-file <一時> --label "backlog,type:*,priority:*"` で Issue 作成
   - 本文には `#519` 参照と検証記録への参照を含める
   - #519 にクローズ判断コメントを投稿（クローズはしない）

**関与するコンポーネント**: AI エージェント / `gh` CLI / `Issue519ClosureDecision`

### ユースケース 7: CHANGELOG 更新

**ステップ**:

1. `CHANGELOG.md` の現状を読み込み、既存セクション構造を把握
2. v2.3.0 セクションが未存在なら新設、存在なら追記
3. 案D / #553 解決 / Tier 2 施策 / 削減実績の 4 要素を含める
4. 削減実績はスクリプト出力から実測値を引用

**関与するコンポーネント**: AI エージェント / `CHANGELOG.md`

## 非機能要件（NFR）への対応

### 正確性（Unit 定義 NFR より）

- **要件**: 計測値は同一コマンド・同一環境で再現可能
- **対応策**: `bin/measure-initial-load.sh` の `BASELINE_REF` 固定 + `tiktoken` 固定 + 配列正本化 + 2 回連続実行のバイト一致検証

### 可視性（Unit 定義 NFR より）

- **要件**: 達成状況が定量的に把握できる形式でレポート化
- **対応策**: `measurement-report.md` の §5 差分表 + §6 boilerplate 比較表 + §8 Intent 対照表で全項目を表形式化

### ガバナンス（Unit 定義 NFR より）

- **要件**: クローズ判断は計測データに基づき、主観を排除する
- **対応策**: 段階 1 は閾値比較のみ、段階 2 は事前定義された `expected_assertion` と引用文の照合（`evidence_status=satisfied` のみ達成と見なす）で判定。`Issue519ClosureDecision.is_closeable()` 純粋関数化。引用が存在するだけでは達成と見なさない

## 技術選定

- **言語**: bash（計測スクリプト）/ Python 3（tiktoken 経由のトークン計測）
- **フレームワーク**: なし
- **ライブラリ**: `tiktoken` (cl100k_base)
- **CLI ツール**: `git`, `gh`, `grep`, `mktemp`, `diff`
- **データベース**: なし（純粋なファイルシステム + git ベース）

## 実装上の注意事項

### スクリプト品質

- bash 配列の参照は `${ARRAY[@]}` 形式を使い、quoting を厳密にする
- 一時ディレクトリは `mktemp -d` で取得し、`trap` で自動削除する
- `set -euo pipefail` を冒頭で設定し、pipe 失敗を見逃さない
- `$()` コマンド置換は `bin/check-bash-substitution.sh` の検査対象外（`.sh` 内は許容、CLAUDE.md の `$()` 禁止ルールはコマンド入力時のみ）

### 機密情報

- 計測対象は公開済みの Markdown ファイルのみ。機密情報は含まれない
- `gh` CLI の認証情報は環境変数経由で渡す（スクリプト内にハードコードしない）

### 保守性

- 計測対象ファイルリストの変更が発生した場合、スクリプト内 bash 配列のみを変更する。本計画書および `measurement-report.md` の参考表示は手動で同期する
- `BASELINE_REF` の更新が将来発生した場合は、計画書のリスク節と本論理設計の両方を更新する

### 再現性

- スクリプト内で `LANG=C LC_ALL=C` をエクスポートしてロケールに依存しない動作を保証する
- `tiktoken.encoding_for_model()` ではなく `tiktoken.get_encoding('cl100k_base')` を直接使う（モデル名変更の影響を受けない）

## 不明点と質問（設計中に記録）

設計中の不明点なし。
