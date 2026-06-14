# 論理設計: Unit 002 work-item-next.sh（依存解決による次 work item 選定）

## 概要

`work-item-next.sh`（WorkItemSelector）のコンポーネント構成・インターフェース・選定アルゴリズム・検証ハーネス構成を定義する。成果物は (1) 新規 `scripts/work-item-next.sh`、(2) サンドボックス境界テストの 2 つ。

**重要**: 本論理設計では**コードは書かず**、構成・インターフェース・アルゴリズム手順のみを定義する。実装は Phase 2（コード生成）で行う。

## 事前コード読込み

ドメインモデル（`unit_002_work_item_next_domain_model.md`）の「事前コード読込み」(a)(b)(c) を参照（重複記載しない）。要点: 選定規則は data-model §5.2 / 出力・終了コード規約は既存スクリプト / D1 はパース独自実装（validate.sh 非変更）/ D2 は resume 優先。

## アーキテクチャパターン

- **安全境界スクリプト（読み取り専用）パターン**（v3 / RFC P4）: 依存解決という決定的ロジックをスクリプトに隔離し、develop 手順（Unit 003）は本スクリプトの `key:value` 出力を消費する。スクリプトは状態を変更しない。
- **既存規約踏襲**: 出力 `key:value` / 終了コード 0/1/2 / read-only / サンドボックステストは state-*.sh・work-item-validate.sh と一致。

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc-v3/
├── scripts/
│   ├── work-item-next.sh             (新規: 依存解決による次 work item 選定 / read-only)
│   ├── work-item-validate.sh         (Unit 001 / 非変更 / パース参照元)
│   └── tests/
│       └── test-work-item-next.sh    (新規: 選定規則 + 境界 (a)-(e) のサンドボックス検証)
```

### コンポーネント詳細

#### work-item-next.sh（新規）

- **責務**: work-items ディレクトリを走査し、§5.2 規則 + D2 resume 優先で次着手 work item を決定的に 1 件選定。`next:<id>:<size>:<path>` / `next:none` を出力。read-only。
- **依存**: bash 組み込み + grep / sed / awk（jq 非依存）。
- **公開インターフェース**: 下記「スクリプトインターフェース設計」参照。

#### test-work-item-next.sh（新規）

- **責務**: 隔離サンドボックス（`mktemp -d`）に work item fixture を構築し、選定結果・終了コード・WARN・候補 status 規約・境界 (a)〜(e)・resume 優先・複数候補決定性をアサート。
- **依存**: work-item-next.sh / bash / 標準ツール。v2 `.aidlc/` を変更しない。

## スクリプトインターフェース設計

### work-item-next.sh

#### 概要

work-items ディレクトリの全 `*.md` を走査し、依存解決で次着手 work item を 1 件選定して `key:value` 形式で出力する read-only スクリプト。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `<work-items-dir>` | 必須 | work item `*.md` を格納するディレクトリ |

#### 出力（stdout）

| ケース | 出力 |
|--------|------|
| 選定あり | `next:<id>:<size>:<path>` |
| 候補なし | `next:none` |

**`<path>` の確定形式（Unit 003 入力契約）**: `<path>` は **`<work-items-dir 引数>/<filename>`** とする（引数で渡された work-items-dir 文字列をそのまま prefix し、`/` + 選定 work item のファイル名 `<id>-<slug>.md` を連結）。

- 呼び出し側（Unit 003）が **スクリプト実行時と同じ cwd** で `<path>` を開けることを保証する（引数 dir が相対パスなら出力も相対 = 同一 cwd から開ける / 絶対パスなら出力も絶対）。
- スクリプトは引数 dir を正規化・絶対化しない（producer/consumer のパス基準を「呼び出し時 cwd」に一意化し、解釈差を排除）。
- `<id>` / `<size>` にはコロン（`:`）が含まれない（frontmatter enum / id トークンの制約）ため、`next:` 出力のフィールド区切り `:` と衝突しない。`<path>` は最後のフィールドであり `/` を含み得るが区切り解析に影響しない（左から 3 つの `:` で分割し 4 番目以降を path とする）。

WARN（不在 dependency 参照 / 複数 in_progress 等）は stderr に `warning: ...` を出力する（stdout は汚さない）。

#### 終了コード（AI-DLC 終了コード規約準拠 / 既存 state-*.sh・work-item-validate.sh と一致）

- `0` = 正常（選定あり `next:...` / 候補なし `next:none` の両方）。**候補なしはエラーにしない**（develop が none を判定して release 可能等へ分岐できる / §5.1 評価順 4 は develop 側責務）。
- `1` = 入力エラー（引数不足 / ディレクトリ不在 / work item 0 件）。
- `2` = システムエラー（ディレクトリ読み取り不可 等）。

#### 選定アルゴリズム（決定的 / §5.2 + D2）

1. 引数チェック（不足 → exit 1）。ディレクトリ存在（不在 → exit 1）/ 読み取り可能（不可 → exit 2）。
2. `*.md` を収集（`nullglob`）。0 件 → exit 1（`invalid: no work items`）。
3. 各 work item の `id`（= ファイル名 prefix）/ `status` / `size` / `dependencies`（配列）を読み取り、**全 id 集合**を構築。
4. **resume 優先（D2）**: `status == in_progress` の work item を抽出。
   - 1 件以上 → 最小 id を選定。**2 件以上なら** stderr に `warning: multiple in_progress work items (anomaly)` を出力（最小 id を返す）。→ 手順 7 へ。
   - 0 件 → 手順 5 へ。
5. **新規候補抽出**: `status == pending` の各 work item について依存充足を評価:
   - 各 `dependency` について: 実在 id か確認（不在 → stderr `warning: dependency '<dep>' not found in <base>` + 当該 item を候補外 / 境界 d）。
   - 全 dependency の status が `done` → 候補（境界 a）。
   - 1 つでも非 `done`（`pending`/`in_progress`/`blocked` = 境界 b、`withdrawn` = 境界 c）→ 候補外。
6. **決定的選定（境界 e / D3）**: 候補から **id 昇順の最小 id** を 1 件選定。**「id 昇順」は数値優先**: 両 id が数字のみなら数値昇順（先頭ゼロは base-10 解釈 / `2` < `10` / `001` < `010`）、それ以外は文字列昇順のフォールバック。glob 辞書順には依存しない（data-model の id は 3 桁ゼロ埋め推奨だが必須でないため `2` と `10` の順序を数値で正す）。候補 0 件 → `next:none` 出力 / exit 0。resume 優先（手順 4）の最小 id 選定も同じ id 昇順規則を用いる。
7. 選定 work item の `id` / `size` / `<work-items-dir 引数>/<filename>` 形式の `<path>`（上記「`<path>` の確定形式」参照 / 引数が絶対パスなら出力も絶対）で `next:<id>:<size>:<path>` を出力 / exit 0。

> **候補 status 規約**: 新規着手候補は `pending` のみ（手順 5）。`in_progress` は resume 候補（手順 4）。`done`/`withdrawn`/`blocked` は新規候補から除外（手順 5 で pending 限定）。

#### 使用コマンド

```bash
work-item-next.sh ".aidlc/cycles/<cycle>/work-items"
# 例: next:002:tiny:.aidlc/cycles/<cycle>/work-items/002-foo.md
#     next:none
```

## データモデル概要

### 入力: work-items/{id}-{slug}.md

- **形式**: YAML frontmatter + Markdown 本文（data-model §4）。本 Unit は frontmatter の `status` / `size` / `dependencies` のみ参照。
- **前提**: validate 済み（§4 準拠）。不在 dependency 参照のみ防御（WARN + 候補外）。

## 処理フロー概要

スクリプトインターフェース設計「選定アルゴリズム」を正本とする（重複記載しない）。要点: in_progress 優先（resume）→ pending の依存充足評価 → id 昇順で 1 件 → `next:...` / `next:none`。

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: work item 数が数十件規模で即時応答。
- **対応策**: ディレクトリ 1 走査 + 線形評価。外部プロセス（grep/sed）呼び出しは work item 数に比例する程度で軽量。

### セキュリティ

- **要件**: 読み取り専用（状態変更しない）。
- **対応策**: ファイル書き込み・state 操作を一切行わない。出力は stdout/stderr のみ。

### スケーラビリティ / 可用性

- 該当なし（Unit NFR）。

## 技術選定

- **言語**: Bash（既存 scripts/* と一致 / `#!/usr/bin/env bash` / `set -euo pipefail`）。
- **ツール**: grep / sed / awk（jq 非依存 / work-item-validate.sh と同方針）。
- **テスト**: 自己完結ハーネス（`mktemp -d` + trap / `assert_*` / Unit 001 test 方式踏襲）。

## 実装上の注意事項

- **D1 パース独自実装**: work-item-validate.sh を変更せず、next.sh 内に status/size のスカラー抽出 + dependencies 配列パースを実装。validate.sh の `read_scalar`（引用符バランス）パターンを参考にするが source はしない（結合回避）。next は validate 済み入力前提のため、パースは選定に必要な最小限。
- **v2 非影響**: 変更は `skills/aidlc-v3/` 配下のみ。`skills/aidlc/`（v2）に触れない（`git diff` で確認）。
- **サンドボックス隔離**: テストは `mktemp -d` 内に work-items fixture を構築し、リポジトリ実体の `.aidlc/` を変更しない。
- **終了コード規約一貫性**: 既存 scripts と同じ 0/1/2。候補なしは exit 0（`next:none`）でエラーにしない。読み取り不可等のみ exit 2。
- **bash-tool 安全規約**: スクリプト・テストの記述で AI が Bash ツール経由実行する経路にコマンド置換（`$(...)`/backtick）を埋めない（リポジトリ規約 / #697）。スクリプト内部の `$(...)` はスクリプト自身の実行であり対象外。
- **shellcheck / bash -n / markdownlint** を全成果物で通す。

## 不明点と質問（設計中に記録）

[Question] 候補なし（`next:none`）は exit 0 か exit 1 か。
[Answer] exit 0（D5）。候補なしは正常系であり、develop が `next:none` を見て「全 work item が done/withdrawn → release 可能」（§5.1 評価順 4 / develop 側責務）等へ分岐できる。選定不能をエラー（exit 1）にすると develop が正常な終端を異常として扱ってしまう。exit 1 は入力エラー（dir 不在・0 件）に限定する。

[Question] 出力になぜ `size` を含めるか。
[Answer] develop（Unit 003）が選定後に `size: tiny` を確認して tiny フローへ分岐する必要があり、size を同梱すれば再パース不要（計画レビュー指摘 #2）。`next:<id>:<size>:<path>` の決定的フォーマットとする。
