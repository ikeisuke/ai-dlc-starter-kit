# Unit 001 計画: Inception フェーズインデックスのパイロット実装

## 概要

案D（インデックス集約型プログレッシブロード）の基盤を Inception Phase で先行実装する。フェーズインデックスファイル（`steps/inception/index.md`）を新設し、SKILL.md の共通初期化フローを「インデックスのみ読み込み」方式に切り替える。既存ステップファイルからインデックスに集約された分岐・判定の重複記述を除去し、詳細手順に特化させる。本 Unit は v2.3.0 サイクル全体の基盤となるため、インデックス構造仕様を他フェーズに流用可能な汎用形で確立する。

## 方針

- **構造の汎用化**: インデックスファイルの章立て（目次・分岐ロジック・現在位置判定チェックポイント）は、Unit 003（Construction）/ Unit 004（Operations）に機械的にパターン適用できるよう、Inception 固有の要素と共通要素を分離する
- **判定チェックポイントは領域確保のみ**: 現在位置判定セクションの**置き場所と骨格**だけを用意し、実判定ロジックは Unit 002（共通判定仕様）で実装する（Unit 001 の責務境界）
- **詳細手順は残す**: 既存 `01-setup.md` 〜 `05-completion.md` は削除せず、「詳細手順ファイル」として残す。インデックスから必要時に参照する形にする
- **SKILL.md の不変ルール整合**: 「ステップファイル読み込みは省略不可」に抵触しないよう、読み込み対象を「各ステップファイル列挙」から「フェーズインデックスファイル」に再定義する（インデックスも必須読み込み対象）
- **トークン予算**: Inception 初回ロード 15,000 tok 以下。現状 22,972 tok からの圧縮必要量は約 **-7,972 tok**
- **計測基準**: v2.2.3 タグ（`d88b0074`）コミットの同一コマンドによるベースライン再計測を実施

### ステップ読み込み契約【重要】

`index.md` と各詳細ステップファイル間の読み込み関係を明示的な契約として定義し、`SKILL.md` は契約を参照して読むだけの薄いルーティング責務のみを持つ。これにより暗黙結合を避け、Unit 002 以降での判定仕様差し込みが機械的に行えるようにする。

**契約スキーマ（`index.md` 内にテーブル形式で定義）**:

| フィールド | 説明 |
|-----------|------|
| `step_id` | ステップ識別子（例: `inception.01-setup`） |
| `detail_file` | 詳細ファイルのスキルベース相対パス（例: `steps/inception/01-setup.md`） |
| `entry_condition` | このステップに遷移する条件（ユーザー入力/前ステップ完了/復帰判定結果等） |
| `exit_condition` | このステップを終了する条件 |
| `load_timing` | `on_demand`（必要時ロード） / `always`（初回から常時ロード） |

**Unit 001 時点の load_timing ポリシー**:

- Unit 001 では Inception の全 `detail_file`（`01-setup.md` 〜 `05-completion.md`）を **`on_demand` 固定**とする。初回ロード対象は `index.md` のみ。
- これにより tok 計測対象は「`index.md` + 共通ファイル（SKILL.md / rules-core.md / preflight.md / session-continuity.md）」に限定され、計測契約と一致する。
- 将来的に `always` への変更が必要になった場合は、計測スクリプトを契約テーブルから自動導出する形に切り替える（Unit 003/004 以降で検討）。

**ルーティング責務**:

- `SKILL.md` 側: 共通初期化フローでは `index.md` のみを常時ロードする。詳細ファイルは「現在ステップ決定後に `index.md` の契約テーブルを参照し、対応する `detail_file` を必要時ロード」という規約で読み込む
- `index.md` 側: 契約テーブル + 分岐ロジック + 判定チェックポイントの骨格のみを含み、詳細手順は一切含めない

### 判定チェックポイント骨格スキーマ【重要】

Unit 002 の共通判定仕様が各フェーズインデックスへ機械的に差し込めるよう、Unit 001 で以下の固定スキーマだけを先行確立する（骨格のみ、実判定ロジック・具体的なファイルパスリストは Unit 002 の責務）。

**チェックポイントスキーマ（`index.md` 内にテーブル形式で定義）**:

| フィールド | 説明 |
|-----------|------|
| `checkpoint_id` | チェックポイント識別子（例: `inception.intent_done`） |
| `input_artifacts` | 判定時に参照する成果物ファイルパスのリスト（Unit 002 で具体値を埋める） |
| `priority_order` | 同点時の優先順位（共通仕様の `operations > construction > inception` を参照） |
| `undecidable_return` | 判定不能時の戻り値（例: `undecidable:missing_file`、`undecidable:format_error`） |
| `user_confirmation_required` | ユーザー確認が必須か（boolean。異常系は常に `true`） |

Unit 001 の成果物には、このスキーマと**Inception の各ステップに対応する空のチェックポイント行（`checkpoint_id` のみ記入、他フィールドは `TBD` プレースホルダ）**を含める。Unit 002 は `TBD` を埋める作業のみを行う。

### トークン予算配分（暫定見積もり）

| ファイル | 現状 tok | 目標 tok | 備考 |
|---------|---------|---------|------|
| SKILL.md | 4,685 | 4,700 | 共通初期化フロー更新で微増許容 |
| rules-core.md | 1,885 | 1,885 | 変更なし |
| preflight.md | 1,965 | 1,965 | 変更なし |
| session-continuity.md | 181 | 181 | 変更なし |
| steps/inception/01-setup.md | 3,353 | 読み込まず | 詳細ファイル化 |
| steps/inception/02-preparation.md | 2,053 | 読み込まず | 詳細ファイル化 |
| steps/inception/03-intent.md | 2,536 | 読み込まず | 詳細ファイル化 |
| steps/inception/04-stories-units.md | 3,076 | 読み込まず | 詳細ファイル化 |
| steps/inception/05-completion.md | 3,238 | 読み込まず | 詳細ファイル化 |
| **（新規）** steps/inception/index.md | - | **≤ 6,269** | 5 ステップの目次・概要・分岐・判定骨格 |
| **合計（初回ロード）** | 22,972 | **≤ 15,000** | |

## 対象ファイル

| # | ファイル | 操作 | 主な変更内容 |
|---|---------|------|-------------|
| 1 | `skills/aidlc/steps/inception/index.md` | **新規** | フェーズインデックスファイル。目次・分岐ロジック・現在位置判定チェックポイント（骨格のみ）を集約。詳細ファイル参照リンクを含む |
| 2 | `skills/aidlc/SKILL.md` | 更新 | 共通初期化フロー「ステップ4: フェーズステップ読み込み」の inception 行を `index.md` のみに変更。引数ルーティングテーブルの説明は維持 |
| 3 | `skills/aidlc/steps/inception/01-setup.md` | 更新 | インデックスに集約する分岐（Part1/Part2遷移、エクスプレス判定、automation_mode分岐等）の重複記述を除去し、詳細手順に特化 |
| 4 | `skills/aidlc/steps/inception/02-preparation.md` | 更新 | インデックスに集約する分岐・判定の重複記述を除去 |
| 5 | `skills/aidlc/steps/inception/03-intent.md` | 更新 | インデックスに集約する分岐・判定の重複記述を除去 |
| 6 | `skills/aidlc/steps/inception/04-stories-units.md` | 更新 | インデックスに集約する分岐・判定の重複記述を除去 |
| 7 | `skills/aidlc/steps/inception/05-completion.md` | 更新 | インデックスに集約する分岐・判定の重複記述を除去 |

## 設計成果物（Phase 1）

- `.aidlc/cycles/v2.3.0/design-artifacts/domain-models/unit_001_inception_index_domain_model.md`
- `.aidlc/cycles/v2.3.0/design-artifacts/logical-designs/unit_001_inception_index_logical_design.md`

## 実装記録（Phase 2）

- `.aidlc/cycles/v2.3.0/construction/units/unit_001_inception_index_implementation.md`

## 検証手順

### tok 計測

#### ベースライン計測（v2.2.3）

v2.2.3 タグの成果物は現行ワークツリーには存在しないため、`git show` で一時ディレクトリへ展開してから同一 Python スニペットで計測する:

```bash
# 1. v2.2.3 タグの対象ファイルを一時ディレクトリへ展開
BASE_REF="d88b0074"  # v2.2.3 タグコミット
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/skills/aidlc/steps/common" "$TMPDIR/skills/aidlc/steps/inception"
git show ${BASE_REF}:skills/aidlc/SKILL.md > "$TMPDIR/skills/aidlc/SKILL.md"
git show ${BASE_REF}:skills/aidlc/steps/common/rules-core.md > "$TMPDIR/skills/aidlc/steps/common/rules-core.md"
git show ${BASE_REF}:skills/aidlc/steps/common/preflight.md > "$TMPDIR/skills/aidlc/steps/common/preflight.md"
git show ${BASE_REF}:skills/aidlc/steps/common/session-continuity.md > "$TMPDIR/skills/aidlc/steps/common/session-continuity.md"
for f in 01-setup 02-preparation 03-intent 04-stories-units 05-completion; do
    git show ${BASE_REF}:skills/aidlc/steps/inception/${f}.md > "$TMPDIR/skills/aidlc/steps/inception/${f}.md"
done

# 2. ベースライン計測（v2.2.3 の読み込み対象は 9 ファイル）
cd "$TMPDIR" && /tmp/anthropic-venv/bin/python3 -c "
import tiktoken
enc = tiktoken.get_encoding('cl100k_base')
files = [
    'skills/aidlc/SKILL.md',
    'skills/aidlc/steps/common/rules-core.md',
    'skills/aidlc/steps/common/preflight.md',
    'skills/aidlc/steps/common/session-continuity.md',
    'skills/aidlc/steps/inception/01-setup.md',
    'skills/aidlc/steps/inception/02-preparation.md',
    'skills/aidlc/steps/inception/03-intent.md',
    'skills/aidlc/steps/inception/04-stories-units.md',
    'skills/aidlc/steps/inception/05-completion.md',
]
total=0
for p in files:
    with open(p) as f: t=f.read()
    n=len(enc.encode(t))
    total+=n
    print(f'{n:>6} tok  {p}')
print(f'{total:>6} tok  TOTAL baseline (v2.2.3)')
"
rm -rf "$TMPDIR"
```

#### 実装後計測（v2.3.0 Unit 001 実装後）

v2.3.0 では `load_timing=on_demand` ポリシーにより、初回ロード対象は 5 ファイル（共通4 + index.md）のみ:

```bash
/tmp/anthropic-venv/bin/python3 -c "
import tiktoken
enc = tiktoken.get_encoding('cl100k_base')
files = [
    'skills/aidlc/SKILL.md',
    'skills/aidlc/steps/common/rules-core.md',
    'skills/aidlc/steps/common/preflight.md',
    'skills/aidlc/steps/common/session-continuity.md',
    'skills/aidlc/steps/inception/index.md',
]
total=0
for p in files:
    with open(p) as f: t=f.read()
    n=len(enc.encode(t))
    total+=n
    print(f'{n:>6} tok  {p}')
print(f'{total:>6} tok  TOTAL Inception initial load (v2.3.0)')
"
```

結果が **15,000 tok 以下** であることを確認。ベースライン値（v2.2.3）と併記してレポートする。

### 回帰検証（検証サンプル A - 静的構造検証）

**Unit 001 での検証方針**: 対話フロー全体の再実行は行わず、**静的構造検証**に限定する。これにより実行コストを抑えつつ、新アーキテクチャ導入時の構造破綻を検出する。実地実行を伴う完全な回帰は Unit 006（計測・クローズ判断）で実施する。

**比較元の固定方法**:

v2.2.3 ベースライン側の成果物は `git show d88b0074:<path>` で一時ディレクトリへ展開し、現行ワークツリー上の実装結果と **ファイル内容のテキスト比較**を行う。比較対象は以下の固定5グループ:

```bash
BASE_REF="d88b0074"
BASE_DIR=$(mktemp -d)/v2.2.3
CURR_DIR=$(pwd)

# グループ1: テンプレート（変更不可）
mkdir -p "$BASE_DIR/skills/aidlc/templates"
for f in intent_template user_stories_template unit_definition_template prfaq_template decision_record_template inception_progress_template; do
    git show ${BASE_REF}:skills/aidlc/templates/${f}.md > "$BASE_DIR/skills/aidlc/templates/${f}.md"
done

# グループ2: Inception ステップファイル（リファクタ対象）
mkdir -p "$BASE_DIR/skills/aidlc/steps/inception"
for f in 01-setup 02-preparation 03-intent 04-stories-units 05-completion; do
    git show ${BASE_REF}:skills/aidlc/steps/inception/${f}.md > "$BASE_DIR/skills/aidlc/steps/inception/${f}.md"
done

# グループ3: 共通ファイル
mkdir -p "$BASE_DIR/skills/aidlc/steps/common"
for f in progress-management rules-core preflight session-continuity; do
    git show ${BASE_REF}:skills/aidlc/steps/common/${f}.md > "$BASE_DIR/skills/aidlc/steps/common/${f}.md"
done
```

**検証項目（静的解析のみ）**:

1. **テンプレート完全一致**: `diff -r "$BASE_DIR/skills/aidlc/templates/" "$CURR_DIR/skills/aidlc/templates/"` が空（テンプレートファイルは本 Unit で一切変更しない）
2. **生成予定ファイルパス一覧の照合**: v2.2.3 の各 Inception ステップファイルから `Write|作成|生成` 等のキーワードで成果物パスを grep 抽出したリストと、本 Unit 実装後の対応する詳細ステップファイルから同一パターンで抽出したリストが一致
3. **progress.md 更新指示形式の照合**: `grep -n "progress.md" "$BASE_DIR/skills/aidlc/steps/inception/*.md"` と現行版の出力行集合が一致（ファイル名・指示内容の変化を検出）
4. **`/write-history` 呼び出しステップ名集合の照合**: `grep -n "write-history\|ステップ名" "$BASE_DIR/skills/aidlc/steps/inception/*.md"` で抽出したステップ名集合と現行版の集合が一致
5. **decisions.md 書き込み手順の照合**: `05-completion.md` の「意思決定記録」セクションについて `diff "$BASE_DIR/.../05-completion.md" "$CURR_DIR/.../05-completion.md"` を実行し、変更が「重複記述削除」のみで意思決定記録フォーマット自体は変わっていないことを目視確認

**可変項目の除外**: タイムスタンプ・セッション ID・コミットハッシュ等は比較対象から除外（上記は全てファイル内容ベースの比較なので該当なし）。

### 契約ルーティング検証【新アーキテクチャ固有】

案Dの価値は初回ロード削減だけでなく「インデックスのみロード → 契約経由で対応詳細ファイルに到達する」という経路にあるため、Unit 001 時点でこの契約インターフェースが機能することを検証する。

**検証範囲（Unit 001 スコープ）**:

- **対象**: 「`step_id` が与えられた時、契約テーブルから対応する `detail_file` を一意に取り出せる」ことの確認（`manual step_id → detail_file` ルーティング）
- **対象外**: 「Inception 途中状態の成果物から `state → step_id` を自動判定する」ロジック（Unit 002 の責務）

**手順**:

1. `index.md` の契約テーブルに Inception 全5ステップ分の行が埋まっていることを確認
2. 代表的な `step_id`（例: `inception.01-setup`、`inception.04-stories-units`）を手動で与え、契約テーブルから対応 `detail_file` パスが一意に解決できることを確認
3. `index.md` のみをロードした状態から、解決された `detail_file` を実際に Read ツールで読めることを確認
4. #553 相当の後半 `step_id`（例: `inception.04-stories-units` / `inception.05-completion`）でも同様にルーティング可能であることを確認

**明確な境界**: `state → step_id` の自動判定は Unit 002 で実装する。Unit 001 では契約インターフェース（`step_id → detail_file`）の機能のみを保証する。

### 重複記述除去の確認

- 分岐・判定に関するキーワード（例: `automation_mode`、`express_enabled`、`Part 1/Part 2`、`自動選択`、`フォールバック`）を既存ステップファイルに対して grep し、インデックス側と重複していないことを確認

## 完了条件チェックリスト

- [ ] `steps/inception/index.md` が新規作成され、以下3点を含む構造が確立している:
  - (1) 全ステップ（01-05）の目次・概要
  - (2) ステップ間分岐ロジック（Part1/Part2 遷移、エクスプレス判定、automation_mode 分岐等）
  - (3) 現在位置判定チェックポイント（骨格のみ、実判定ロジックは Unit 002）
- [ ] インデックスファイルの構造仕様（セクション構成・見出しレベル・必須項目）がドキュメント内にコメントまたは別章で明文化され、他フェーズに流用可能な形になっている
- [ ] **【ステップ読み込み契約】** `index.md` に契約テーブル（`step_id` / `detail_file` / `entry_condition` / `exit_condition` / `load_timing`）が存在し、Inception の全5ステップ分の行が埋まっている
- [ ] **【判定チェックポイント骨格】** `index.md` にチェックポイントスキーマ（`checkpoint_id` / `input_artifacts` / `priority_order` / `undecidable_return` / `user_confirmation_required`）が存在し、Inception の各ステップに対応する空行が `TBD` プレースホルダで定義されている
- [ ] `SKILL.md` の「共通初期化フロー ステップ4: フェーズステップ読み込み」の inception 行が `steps/inception/index.md` のみの読み込みに更新されている
- [ ] `SKILL.md` は契約テーブルを参照する薄いルーティング責務のみを持ち、詳細ステップの読み込み条件ロジックを直接持たない
- [ ] 既存の `steps/inception/01-setup.md` 〜 `05-completion.md` から、インデックスに集約された分岐・判定の重複記述が除去されている（grep で確認）
- [ ] 既存の Inception ステップファイル（詳細手順）は削除されず残っている（必要時に参照される形）
- [ ] **【計測】** Inception 初回ロードの実測値が **15,000 tok 以下** である
- [ ] **【ベースライン再計測】** v2.2.3 タグ（`d88b0074`）を同一コマンドで再計測した結果が記録されている
- [ ] **【静的構造回帰検証】** 以下5項目の静的解析で v2.2.3 との一致を確認（対話フロー再実行は不要。実地回帰は Unit 006 で実施）:
  - 生成予定ファイルパス一覧（各ステップファイル内の生成指示を照合）
  - テンプレートファイル（`templates/*.md`）が本 Unit で変更されていないこと（grep）
  - progress.md 更新指示の形式（grep）
  - `history/inception.md` の `/write-history` 呼び出し箇所で使うステップ名集合（grep）
  - `decisions.md` の ID 連番と対象要件ラベル形式（`05-completion.md` と `decision_record_template.md` の diff）
- [ ] **【load_timing ポリシー遵守】** Inception の全 `detail_file`（`01-setup.md` 〜 `05-completion.md`）が契約テーブル上で `load_timing=on_demand` に固定されている（tok 計測対象と一致）
- [ ] **【契約ルーティング検証】** 代表 `step_id`（`inception.01-setup` / `inception.04-stories-units` / `inception.05-completion` 等）を手動で与えると、契約テーブルから対応 `detail_file` が一意に解決でき、実際に Read ツールで読める
- [ ] SKILL.md の不変ルール「ステップファイル読み込みは省略不可」に抵触していない（インデックスファイルが「フェーズステップ読み込み」の対象として再定義されている）
- [ ] SKILL.md 本文が 500 行以内を維持している

## 依存関係

### 前提 Unit
- なし（本サイクルの基盤 Unit）

### 本 Unit を依存元とする Unit
- Unit 002: 共通判定仕様を `index.md` の「判定チェックポイント骨格」に流し込む
- Unit 003: Construction インデックスに構造パターンを流用
- Unit 004: Operations インデックスに構造パターンを流用

## 関連 Issue

- #519: コンテキスト圧縮メイン Issue（Tier 2/3 完遂）

## リスクと留意事項

- **トークン予算の厳しさ**: 15,000 tok 目標は新規 `index.md` を最大 6,269 tok に収める必要があり、5 ステップの詳細手順を大胆に圧縮する必要がある。設計段階で「何を必ず残し、何を詳細ファイルに残すか」を明確化する
- **不変ルール抵触リスク**: インデックスのみ読み込みが「ステップファイル読み込み省略」と解釈されないよう、SKILL.md 側の定義変更を明示的に行う
- **Unit 002 との境界**: 現在位置判定セクションは「領域確保と骨格のみ」とし、実判定ロジックには踏み込まない（Unit 002 の責務）
- **回帰検証のスコープ限定**: Unit 001 では静的構造検証（grep・diff・テンプレート照合）のみを必須とし、対話フロー再実行は不要。実地回帰検証は Unit 006（計測・クローズ判断）で全 Unit 実装後に一括実施する
