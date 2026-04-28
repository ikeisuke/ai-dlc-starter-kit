# 論理設計: migrate-backlog.sh の UTF-8 対応（Unit 003）

## 概要

`skills/aidlc-setup/scripts/migrate-backlog.sh` の `generate_slug()` における Perl invocation を `-CSD -Mutf8` 化し、slug 生成パイプラインのエンコーディング契約を `(utf8, utf8)` に揃える論理設計。実装範囲は実質 1 行で、コンポーネント構成・インターフェース・データモデルは既存仕様を維持する。

**重要**: 本論理設計では**コードは書かず**、コンポーネント構成と契約定義のみを行う。具体的なコードは Phase 2 で生成する。

---

## 設計判断記録（A/B 確定結果）

| 判断項目 | 採用案 | 判定根拠 |
|---------|-------|---------|
| 検証手段（A=実行表 / B=bats） | **検証-A（実行表）** | **形式判定**: 計画ファイル §Phase1.3 の「検証-B 採用条件 1〜3」は形式上すべて満たす（条件1: bats インフラあり `tests/migration/*.bats` 6 件 / 条件2: CI 連動 `.github/workflows/migration-tests.yml` で `bats` 実行 / 条件3: `tests/aidlc-setup/` 等への小規模追加で 1 セッション内完結可能）。**実採用根拠**: 計画ファイル §リスクと注意点の「DEPRECATED スクリプト（v2.0.0 で削除予定）」前提と整合させて検証-A を選択する。bats を追加すると削除時に同時除去が必要となりメンテナンスコストが恒常化するため、計画ファイル既定（検証-A）を上書きしない。**判定基準の差異**: 計画ファイルの判定基準には「DEPRECATED 除外条件」が含まれていないため、形式判定のみでは検証-B となる。本判定で「DEPRECATED 除外条件」を実採用根拠として追加する。Operations Phase で計画ファイル §Phase1.3 の判定基準に「条件4: 対象が DEPRECATED でないこと」を補足するか別 Issue 化を検討する旨を意思決定記録（`inception/decisions.md`）の追補対象とする |
| `一-龯` のコードポイント範囲明示 | **Phase 2 実測で確定し design.md に追記** | ドメインモデルでは「CJK 統合漢字の主要範囲」と論理レベル記述に留め、実装時に Perl 実測（`perl -CSD -Mutf8 -e 'printf "U+%04X\n", ord("龯")'`）で確定 |
| `defaults.toml` への影響 | **影響なし（変更しない）** | 本 Unit のスコープは `migrate-backlog.sh` のみ。`defaults.toml` の `tools=["codex"]` は Unit 002 で注釈追加済（暗黙シム言及）であり追加変更不要 |
| `--dry-run` 検証ケース | **3 必須ケース中 1 ケースを `--dry-run` でも実行** | `--dry-run` モードでも `generate_slug()` は `process_item` 内で `--dry-run` 分岐前に呼ばれる（`migrate-backlog.sh` 内 `process_item` 関数）ため、抽出される slug 値はケース 1 と完全一致する。dry-run 出力全体（`[移行予定]` 行等）ではなく **slug 値のみ**を比較対象とする |
| ロケール非依存化検証 | **`LANG=C` 1 ケース実行（評価基準: Perl 段階の効果確認のみ）** | `-CSD -Mutf8` の効果は **入力依存ではなくロケール依存**（IO/regex 両層を強制 UTF-8 化）。同一入力でロケールのみ変えたケースが 1 件あれば契約成立を実証できる。**Phase 2 実測で発見された再定義**: 当初の評価基準「3 必須ケースの slug が同等」は `cut -c1-50` 段階のロケール依存（BSD/POSIX 挙動でバイト単位切り詰め）まで含むため、本 Unit のスコープ（Perl invocation の UTF-8 化）を超える。再定義後の評価基準: 「(1) Perl regex 段階で日本語が分断されないこと、(2) stderr エラーが出ないこと、(3) slug 本体（50 バイト以内範囲）が期待通り生成されること」の 3 条件のみを Case 6 で確認する。`cut -c1-50` 段階の文字化けは Issue #615 として GitHub バックログ登録（OUT_OF_SCOPE / `cut` の代替実装は別 Unit / 別サイクル）。`LANG=POSIX` は POSIX 標準で `LANG=C` と等価扱いとなる環境が多く、別ケースとして実行する必要性は低い |

---

## アーキテクチャパターン

**Pipes and Filters**（既存）: `tr` → `perl` → `tr` → `sed` → `cut` の単方向パイプライン構成。本 Unit はパイプライン構成自体は維持し、中間段階の 1 つ（`perl` フィルタ）のエンコーディング契約のみを修正する。**設計判断**: パターン変更や段階追加を行わず、既存パターンに最小手を入れる方針（Issue #610 修正案の最小実装方針と整合）。

## コンポーネント構成

### モジュール構成

```text
skills/aidlc-setup/scripts/migrate-backlog.sh
├── generate_slug()                    # 修正対象（1 行のみ変更）
│   ├── tr [:upper:] [:lower:]         # 段階1: 小文字化
│   ├── perl -CSD -Mutf8 -pe ...       # 段階2: regex フィルタ ← 修正
│   ├── tr ' ' '-'                     # 段階3: 空白→ハイフン
│   ├── sed 's/--*/-/g'                # 段階4: ハイフン重複圧縮
│   ├── sed 's/^-//;s/-$//'            # 段階5: 先頭末尾ハイフン除去
│   └── cut -c1-50                     # 段階6: 50 文字切り詰め
├── get_prefix_from_section()          # 変更なし
├── parse_old_backlog()                # 変更なし
├── (その他の関数)                       # 変更なし
└── (DEPRECATED マーク)                 # 維持
```

### コンポーネント詳細

#### `generate_slug()`

- **責務**: バックログタイトルから URL/ファイル名安全な slug を生成する
- **依存**: `tr`（POSIX）、`perl 5.x`（macOS / Linux 標準）、`sed`、`cut`
- **公開インターフェース**: 単一引数 `title: string`、stdout に slug を出力
- **修正点**: `perl -pe '...'` → `perl -CSD -Mutf8 -pe '...'`（IO/regex 両層を UTF-8 強制）
- **エンコーディング契約**: 修正後 `(utf8, utf8)` で確立（ドメインモデル §値オブジェクト `EncodingContract` 参照）

## インターフェース設計

### スクリプトインターフェース（既存維持）

#### `migrate-backlog.sh`

##### 概要

旧形式バックログ（`.aidlc/cycles/backlog.md`）を新形式（`.aidlc/cycles/backlog/<file>.md`）に移行する DEPRECATED スクリプト。v2.0.0 で削除予定だが本 Unit では削除タイミング変更しない。

##### 引数（変更なし）

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--dry-run` | 任意 | 実際の変更を行わず、移行予定の内容を表示 |
| `--no-delete` | 任意 | 移行後も元ファイルを削除しない |

##### 成功時出力（変更なし）

```text
status:migrated|dry_run|no_file
migrated_count:N
skipped_completed:N
skipped_duplicate:N
deleted:true|false
```

- 終了コード: `0`
- 出力先: stdout

##### エラー時出力（変更なし）

```text
status:error
message:<エラー内容>
```

- 終了コード: `1`（一般エラー）/ `2`（パスエラー）
- 出力先: stderr

##### 使用コマンド（変更なし）

```bash
# 通常実行
./skills/aidlc-setup/scripts/migrate-backlog.sh

# dry-run
./skills/aidlc-setup/scripts/migrate-backlog.sh --dry-run

# 元ファイル削除なし
./skills/aidlc-setup/scripts/migrate-backlog.sh --no-delete
```

### 内部関数インターフェース

#### `generate_slug(title: string) -> string`

- **パラメータ**: `title`: バックログタイトル（UTF-8 多言語混在を許容）
- **戻り値**: 正規化済み slug（小文字英数字 + 主要日本語 + ハイフン、最大 50 文字）
- **副作用**: なし（純粋関数）
- **修正後の契約**: 入力タイトルが UTF-8 整合性を保つ場合、出力 slug も UTF-8 整合性を保つ。fullwidth カッコ等の許容範囲外文字は除去され、後続のマルチバイト境界分断は発生しない

## データモデル概要

本 Unit の対象範囲には永続データモデルなし。入出力はすべて bash 変数 / stdout / stderr 上の文字列。

## 処理フロー概要

### slug 生成の処理フロー（修正後）

**ステップ**:

1. `generate_slug()` が `title: string` を受け取る
2. `tr '[:upper:]' '[:lower:]'`: ASCII 小文字化（UTF-8 範囲外文字は変化なし）
3. `perl -CSD -Mutf8 -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g'`:
   - `-CSD` で STDIN/STDOUT を UTF-8 として扱う
   - `-Mutf8` で regex リテラル内の日本語範囲を Unicode コードポイント範囲として解釈
   - 許容範囲外文字（fullwidth カッコ等）を UTF-8 シーケンスごと削除
4. `tr ' ' '-'`: 半角スペースをハイフンに変換（修正前は `Illegal byte sequence` を出していた段階）
5. `sed 's/--*/-/g'`: 連続ハイフンを 1 つに圧縮
6. `sed 's/^-//;s/-$//'`: 先頭・末尾ハイフン除去
7. `cut -c1-50`: 最大 50 文字に切り詰め

**関与するコンポーネント**: `generate_slug()` 内の各段階のみ（外部コンポーネントとの依存なし）

### 修正前後の挙動差分

| 入力 | 修正前出力 | 修正後出力 | 差分の発生原因 |
|------|----------|----------|--------------|
| `テスト分離の改善（並列テスト対応）` | `テスト分離の改善`（stderr に `tr: Illegal byte sequence`） | `テスト分離の改善並列テスト対応` | 修正前は `（` U+FF08 の UTF-8 3 バイトのうち一部のみ削除され不正シーケンス残留 |
| `SQLite vnode エラー（DB差し替え時の競合アクセス）` | `sqlite-vnode-エラー`（同上） | `sqlite-vnode-エラーdb差し替え時の競合アクセス` | 同上 |
| `AgencyConfig DDD責務整理` | `agencyconfig-ddd`（stderr エラーなしだが切れる） | `agencyconfig-ddd責務整理` | regex がバイト単位評価で日本語末尾を範囲外として削除 |
| `Cloudflare Worker GTFS ダウンロード最適化`（参考） | `cloudflare-worker-gtfs`（同上） | `cloudflare-worker-gtfs-ダウンロード最適化` | 同上（参考行、完了条件外） |

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 影響なし（Unit 定義 NFR）
- **対応策**: Perl 起動オーバーヘッドのみで、`-CSD -Mutf8` の指定は内部処理パスを変えない。実測上の差は無視可能

### セキュリティ

- **要件**: 影響なし（Unit 定義 NFR）
- **対応策**: 入力文字列のサニタイズ範囲（許容文字セット）は変更なし。修正は文字エンコーディング解釈のみ

### スケーラビリティ

- **要件**: 影響なし（Unit 定義 NFR）
- **対応策**: バックログ移行は 1 回限りのバッチ処理で並列性も発生しない

### 可用性

- **要件**: 環境依存リスクなし（Unit 定義 NFR）
- **対応策**: Perl 5.x 標準機能のみ使用、`-CSD -Mutf8` は macOS / Linux 共通動作。`LANG=C` 等のロケール下でも IO/regex 両層が UTF-8 強制されるため、ロケール非依存で動作する

## 技術選定

- **言語**: Bash 5.x（既存）+ Perl 5.x（macOS / Linux 標準、変更なし）
- **フレームワーク**: なし
- **ライブラリ**: Perl の `utf8` プラグマ（標準）、`-C` switch（標準）
- **データベース**: なし

## 実装上の注意事項

- **`-CSD` と `-Mutf8` の併用必須**: いずれかのみでは不整合契約となり、本 Unit の修正目的を達成しない（ドメインモデル §値オブジェクト `EncodingContract` の整合性ルール参照）
- **CJK 統合漢字範囲の確定**: Phase 2 で `perl -CSD -Mutf8 -e 'printf "U+%04X\n", ord("龯")'` で実測し、design.md（本ファイル）または history に追記
- **DEPRECATED マーク維持**: ヘッダコメント・関連注記は変更しない（Unit 定義「境界」）
- **regex リテラル不変**: `[^a-z0-9一-龯ぁ-んァ-ヶー ]` の文字列内容は変更しない。修正前の許容範囲を保持する
- **既存パイプラインの順序維持**: 段階 1〜6 の順序は変更しない（Issue 本文の検証手順と整合）

## 実装範囲（差分）

```diff
 generate_slug() {
     local title="$1"
     echo "$title" | \
         tr '[:upper:]' '[:lower:]' | \
-        perl -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g' | \
+        perl -CSD -Mutf8 -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g' | \
         tr ' ' '-' | \
         sed 's/--*/-/g' | \
         sed 's/^-//;s/-$//' | \
         cut -c1-50
 }
```

行番号: 計画作成時点で L75（Phase 2 実装時に再確認し、history に最終行番号を記録）

## 検証手段（検証-A 採用）

design.md（本ファイル）または history に以下のテーブルを Phase 2 実装時に追記:

| # | 入力タイトル | 修正前 slug | 期待 slug | 実測 slug | 環境 | 備考 |
|---|------------|------------|----------|----------|------|------|
| 1 | `テスト分離の改善（並列テスト対応）` | `テスト分離の改善` | `テスト分離の改善並列テスト対応` | （実行記録） | `LANG=ja_JP.UTF-8` | 必須ケース、fullwidth カッコ |
| 2 | `SQLite vnode エラー（DB差し替え時の競合アクセス）` | `sqlite-vnode-エラー` | `sqlite-vnode-エラーdb差し替え時の競合アクセス` | （実行記録） | `LANG=ja_JP.UTF-8` | 必須ケース、全角＋半角混在 |
| 3 | `AgencyConfig DDD責務整理` | `agencyconfig-ddd` | `agencyconfig-ddd責務整理` | （実行記録） | `LANG=ja_JP.UTF-8` | 必須ケース、半角主体＋日本語末尾 |
| 4 | `Cloudflare Worker GTFS ダウンロード最適化` | `cloudflare-worker-gtfs` | `cloudflare-worker-gtfs-ダウンロード最適化` | （実行記録） | `LANG=ja_JP.UTF-8` | 参考、完了条件外 |
| 5 | `テスト分離の改善（並列テスト対応）` | （ケース1と同じ） | `テスト分離の改善並列テスト対応` | （実行記録） | `LANG=ja_JP.UTF-8` + `--dry-run` | dry-run 同等動作確認。`generate_slug()` は `--dry-run` 分岐前に呼ばれるため slug 値はケース 1 と完全一致するはず。**比較対象は slug 値のみ**（`[移行予定]` 等の dry-run 固有出力は対象外） |
| 6 | `テスト分離の改善（並列テスト対応）` | （ケース1と同じ） | `テスト分離の改善並列テスト対応`（Perl 段階の効果確認のみ） | （実行記録） | `LANG=C` | ロケール非依存化検証（再定義後）。評価基準は **Perl 段階のみ**: (1) regex で日本語分断なし、(2) stderr エラーなし、(3) 50 バイト以内範囲の slug 本体が期待通り。50 バイト超入力時の `cut -c1-50` 文字化けは Issue #615 にバックログ登録（OUT_OF_SCOPE） |

実行方法: `migrate-backlog.sh:generate_slug()` 相当のパイプラインを bash で再現し、各ケースの入力に対して修正後コマンドを実行。出力結果と stderr エラーの有無を記録。

## 不明点と質問

[Question] 検証-A の実行表は design.md（本ファイル）に記録するか、history に記録するか
[Answer] 一次記録は history（`history/construction_unit03.md`）に Phase 2 実装エントリとして追記。本 design.md にはテンプレート（上記表）のみ残し、実測値を Phase 2 で history に書く。設計と実測を分離することで設計レビュー時の前提と Phase 2 実測の差異を追跡可能にする

[Question] CJK 統合漢字範囲の Phase 2 実測は必須か
[Answer] 必須ではないが推奨。`一-龯` の範囲不変が前提のため、修正後に範囲が変化していないことを 1 コマンドで確認できる。仮に環境差で範囲が変動する場合は Issue 化（本 Unit のスコープ外）

[Question] 1 行修正で domain_model + logical_design の 2 ファイルを作成するのは過剰ではないか
[Answer] 過剰の懸念はあるが、Construction Phase の `depth_level=standard` 規約に従う。AI-DLC の構造的整合性（他 Unit との一貫性）と将来の DEPRECATED 解除サイクル時の参照価値（エンコーディング契約モデルは類似スクリプトに再利用可能）を優先する
