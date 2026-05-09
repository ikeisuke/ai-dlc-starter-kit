# 論理設計: aidlc-setup の starter_kit_version-only 差分 no-op スキップ

## 概要

`scripts/check-noop-upgrade.sh` の入出力契約と `02-generate-config.md` のステップ順序変更点・呼び出しフローを定義する。

## アーキテクチャパターン

**採用パターン**: 既存「アップグレードフロー（02-generate-config.md ステップ 7.x / 8.4）」に「no-op 判定ステップ」を挿入し、starter_kit_version 更新を条件分岐させる。判定ロジック自体は独立スクリプト（`check-noop-upgrade.sh`）に閉じ込めて、aidlc-setup コンテキスト内で完結させる。

**選定理由**:

- 既存スクリプト出力（migrate-config / detect-missing-keys）を一次情報として再利用できる（DRY）
- 判定ロジックを独立スクリプト化することで単体テスト容易性を確保
- `02-generate-config.md` の変更は「順序入れ替え + 条件分岐追加」のみで影響範囲が局所的

## コンポーネント構成

### レイヤー / モジュール構成

```text
Upgrade No-Op Detection（本 Unit のスコープ）
├── Detector Layer
│   └── scripts/check-noop-upgrade.sh                     [新規]
│       ├── parse_migrate_config_result(line)              [内部関数]
│       ├── decide_noop(migrated, warnings, missing_applied)
│       └── output noop=<bool> + reason=<enum>
├── Flow Layer
│   └── steps/02-generate-config.md                        [改訂]
│       ├── ステップ 7.4 migrate-config 実行 + result 行キャプチャ
│       ├── ステップ 7.4b detect-missing-keys 実行 + 対話結果集約 (detect_missing_applied=0|1)
│       ├── ステップ 7.4c 【新規】no-op 判定（check-noop-upgrade.sh）
│       └── ステップ 7.3 【条件実行】should_update_starter_kit_version=true なら starter_kit_version 更新
└── Test Layer
    └── scripts/tests/test_check_noop_upgrade.sh           [新規]
```

### コンポーネント詳細

#### scripts/check-noop-upgrade.sh

- **責務**: noop 判定の一元化。既存スクリプト出力を入力として noop=true/false を構造化形式で返す
- **依存（指摘 #4 反映 / 契約依存として明示）**:
  - **契約依存**: `migrate-config.sh` の `result:<status>:migrated=<N>,skipped=<M>,warnings=<W>` フォーマット（Contract v1）
  - **契約依存**: `detect-missing-keys.sh` 後の対話集約結果（呼び出し側が `--detect-missing-applied 0|1` の boolean に正規化済の前提）
  - **コマンド依存**: `awk` または bash の `=~` のみ（標準 GNU/BSD いずれも利用可能）
- **互換ポリシー**: `result:` フォーマットが将来変更された場合、本スクリプトの解析ロジックも同 PR 内で改訂し、`scripts/tests/test_check_noop_upgrade.sh` の契約テストを更新する。Contract v2 が必要な場合は `--migrate-config-result-version` 引数で明示する案を将来検討（本 Unit のスコープ外）
- **公開インターフェース**: 後述「スクリプトインターフェース設計」参照

#### 02-generate-config.md ステップ順序変更

| 変更前順序 | 変更後順序 | 変更点 |
|-----------|-----------|--------|
| 7.3 starter_kit_version 更新 | 7.4 migrate-config | 7.3 を 7.4 / 7.4b の後ろに移動（条件実行化） |
| 7.4 migrate-config | 7.4b detect-missing-keys | （変更なし） |
| 7.4b detect-missing-keys | 7.4c no-op 判定（新規） | 新規ステップ挿入 |
| 7.5 migrate-backlog | 7.3 starter_kit_version 更新（条件実行） | 順序入替 |
| - | 7.5 migrate-backlog | （変更なし） |

旧 7.3（starter_kit_version 更新）は「条件実行ブロック」として 7.4c の判定後に実行される。

> **注**: 既存ステップ番号体系は維持し、説明文に「順序が変わった点」を明記する形にする。新規ステップは `7.4c` として追加する。

## インターフェース設計

### スクリプトインターフェース設計

#### scripts/check-noop-upgrade.sh

##### 概要

`migrate-config.sh` の `result:` 行と `detect-missing-keys.sh` 後の対話結果から no-op 判定を行う。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--migrate-config-result <line>` | 必須 | `migrate-config.sh` stdout の `result:...` 行（例: `result:completed:migrated=0,skipped=18,warnings=0`） |
| `--detect-missing-applied <0\|1>` | 必須 | detect-missing-keys.sh + 対話結果で実際に追加されたかを示すフラグ。`0` = 追加なし / `1` = 追加あり |

##### 出力契約（成功・失敗いずれも 3 行固定 / 指摘 #2 反映）

成功時・失敗時のいずれも **`noop=` / `reason=` / `error=` の 3 行を必ず stdout に出力する**。空欄は空文字列で表現。

##### 成功時出力（noop=true）

```text
noop=true
reason=no-changes
error=
```

##### 成功時出力（noop=false）

```text
noop=false
reason=migrate-config-changed
error=
```

または:

```text
noop=false
reason=missing-keys-applied
error=
```

両方が同時に true なら `migrate-config-changed` を優先（`migrate-config-changed` が記載されれば missing-keys は冗長情報のため省略）。

##### エラー時出力（指摘 #2 反映 / 契約一本化）

エラー時も成功時と同じ 3 行構造で返し、契約を一本化する。失敗時は `noop=` と `reason=` を空とし `error=` に詳細を入れる:

```text
noop=
reason=
error=invalid-input:<detail>
```

引数欠落時:

```text
noop=
reason=
error=missing-arg:--migrate-config-result
```

- 終了コード: `0`=判定成功（`noop=` と `reason=` は非空 / `error=` は空）
- 終了コード: `2`=判定失敗（`noop=` と `reason=` は空 / `error=` は非空）。呼び出し側はフォールバック扱い

呼び出し側は exit code を一次判定に使い、`noop=` の値を補助的に確認する。

##### 入力解析ロジック

```text
parse_migrate_config_result(line):
  - 形式: "result:<status>:migrated=<N>,skipped=<M>,warnings=<W>"
  - awk または bash の =~ で <N> と <W> を抽出
  - 数値以外 / 形式不一致 → exit 2 (invalid-input)
  - migrated, warnings を返す

decide_noop(migrated, warnings, missing_applied):
  - noop = (migrated == 0) && (warnings == 0) && (missing_applied == 0)
  - reason 決定:
    - noop=true → "no-changes"
    - migrated > 0 or warnings > 0 → "migrate-config-changed"
    - missing_applied == 1 → "missing-keys-applied"
```

### 02-generate-config.md ステップ 7.4c の手順（新規 / 指摘 #3 反映: テンポラリファイル経由の機械可読受け渡し）

```text
### 7.4c no-op 判定【アップグレードモードのみ】

ステップ 7.4 と 7.4b の結果を集約し、starter_kit_version 更新の要否を判定します。

**入出力契約**: ステップ 7.4 / 7.4b は以下のテンポラリファイルに結果を書き出すこと（AI agent 内部変数ではなく、明示的な機械可読媒体を使用）:

- `${TMPDIR:-/tmp}/aidlc-setup-migrate-config-result.txt`: ステップ 7.4 の `migrate-config.sh` stdout 全体を tee で書き出す（`result:` 行を含む）
- `${TMPDIR:-/tmp}/aidlc-setup-detect-missing-applied.txt`: ステップ 7.4b の対話結果として `0` または `1` の 1 文字を書き出す（追加実行されたら `1`、それ以外は `0`）

ステップ 7.4 の修正:
（既存）`scripts/migrate-config.sh` を実行
（追加）出力を一時ファイルに保存: `scripts/migrate-config.sh | tee "${TMPDIR:-/tmp}/aidlc-setup-migrate-config-result.txt"`

ステップ 7.4b の修正:
（既存）対話で「追加する/しない」を判定
（追加）対話結果に基づき AI agent が `printf '0' > "${TMPDIR:-/tmp}/aidlc-setup-detect-missing-applied.txt"` または `printf '1' > ...` を実行する

**7.4c 実行**:

```bash
RESULT_LINE=$(grep -E '^result:' "${TMPDIR:-/tmp}/aidlc-setup-migrate-config-result.txt" | head -1)
DETECT_APPLIED=$(cat "${TMPDIR:-/tmp}/aidlc-setup-detect-missing-applied.txt")
scripts/check-noop-upgrade.sh \
    --migrate-config-result "$RESULT_LINE" \
    --detect-missing-applied "$DETECT_APPLIED"
```

**出力解釈**:

| 出力 | 意味 | アクション |
|------|------|----------|
| exit 0 + `noop=true` + `reason=no-changes` | 適用変更なし | 7.3（starter_kit_version 更新）を **スキップ** + メッセージ表示 |
| exit 0 + `noop=false` + `reason=*` | 適用変更あり | 7.3 を **通常実行** |
| exit 2 + `error=*` | 判定不能 | 警告表示 + 7.3 を **通常実行**（フォールバック） |

**スキップ時の表示**:

`.aidlc/config.toml の starter_kit_version 更新をスキップしました（差分なし）`
- `migrate-config: 適用変更なし`
- `detect-missing-keys: 追加なし`
- 注意: `.claude/settings.json (8.4)` は別責務として通常通り適用されます

**一時ファイルのクリーンアップ**: ステップ 7.4c 完了後、または 7.5 開始前に `rm -f "${TMPDIR:-/tmp}/aidlc-setup-migrate-config-result.txt" "${TMPDIR:-/tmp}/aidlc-setup-detect-missing-applied.txt"` を実行する（一時ファイルの残置防止）。

### 7.3 starter_kit_version 更新（条件実行）

7.4c の判定結果に基づき条件実行。`should_update_starter_kit_version=true` の場合のみ実行する。
それ以外は本ステップをスキップして 7.5 へ進む。
```

## データモデル概要

### 入力データ: migrate-config.sh の result 行

形式: `result:completed:migrated=<N>,skipped=<M>,warnings=<W>` または `result:completed-with-warnings:migrated=<N>,skipped=<M>,warnings=<W>`

### 入力データ: detect_missing_applied（指摘 #3 反映 / 受け渡し媒体の固定）

`02-generate-config.md` のステップ 7.4b 終了時点で、AI agent が `${TMPDIR:-/tmp}/aidlc-setup-detect-missing-applied.txt` に `0` または `1` の 1 文字を書き込む。値: `0` (追加なし) / `1` (追加あり)。

ステップ 7.4c では `cat` でこのファイルを読み込み `--detect-missing-applied` 引数に渡す。

## 処理フロー概要

### ユースケース1: no-op アップグレード（v2.4.2 → v2.4.3 で starter_kit_version 値のみ変化）

1. ユーザーが `aidlc-setup` を実行（アップグレードモード）
2. ステップ 7.4 `migrate-config.sh | tee "${TMPDIR:-/tmp}/aidlc-setup-migrate-config-result.txt"` 実行 → ファイルに `result:completed:migrated=0,skipped=18,warnings=0` 含む出力が保存
3. ステップ 7.4b `detect-missing-keys.sh` 実行 → `summary\ttotal\t0` → ユーザーに追加確認なし → AI agent が `printf '0' > "${TMPDIR:-/tmp}/aidlc-setup-detect-missing-applied.txt"`
4. ステップ 7.4c `check-noop-upgrade.sh --migrate-config-result "$RESULT_LINE" --detect-missing-applied "$DETECT_APPLIED"` → exit 0 + `noop=true / reason=no-changes / error=`
5. ステップ 7.3 をスキップ（starter_kit_version 更新なし）+ 通知メッセージ表示
6. 一時ファイルクリーンアップ
7. ステップ 7.5 / 8.4 は通常通り実行

**関与するコンポーネント**: 02-generate-config.md, migrate-config.sh, detect-missing-keys.sh, check-noop-upgrade.sh, テンポラリファイル

### ユースケース2: 通常のアップグレード（migrate-config が新セクション追加）

1. ステップ 7.4 → ファイルに `result:completed:migrated=2,skipped=10,warnings=0` を含む出力
2. ステップ 7.4b → 欠落キー 3 件 → ユーザー追加 → `printf '1' > ...`
3. ステップ 7.4c → exit 0 + `noop=false / reason=migrate-config-changed / error=`
4. ステップ 7.3 を通常実行（starter_kit_version 更新）
5. 後続ステップ通常通り

### ユースケース3: フォールバック（出力解析失敗）

1. ステップ 7.4 で何らかの理由で `result:` 行が異常 → grep で取得できず空文字列
2. ステップ 7.4c → exit 2 + `noop= / reason= / error=invalid-input:...`
3. 警告表示「⚠ no-op 判定に失敗しました。通常通り starter_kit_version を更新します。」
4. ステップ 7.3 を通常実行（既存挙動と同じ）

## 非機能要件（NFR）への対応

### 正確性

- **要件**: 偽陰性（書き込みすべきところをスキップ）を起こさない
- **対応策**:
  - 判定の AND 条件を厳格に (`migrated == 0` AND `warnings == 0` AND `missing_applied == 0`)
  - 解析失敗時は安全側（通常更新）にフォールバック
  - ユニットテストで 4 シナリオ（noop / migrate-config-changed / missing-keys-applied / invalid-input）を検証

### 可観測性

- **要件**: スキップ時に明確なメッセージで利用者に通知
- **対応策**: 「7.3 をスキップしました（差分なし）」+ 集約サマリ + 「.claude/settings.json は別責務」の注記を表示

### 互換性

- **要件**: 既存のアップグレードフロー（他フィールド差分あり）は変化しない
- **対応策**: ステップ順序変更は「7.3 を 7.4/7.4b の後に移動」のみ。冪等な値更新のため副作用なし。フォールバック挙動も「starter_kit_version を必ず更新する」既存挙動を維持

## 技術選定

- **言語**: Bash（既存 setup スクリプトと整合）
- **依存ツール**:
  - `awk` または bash の `=~`（result 行解析）
- **テストフレームワーク**: 既存の bash assert スタイル（`scripts/tests/`）

## 実装上の注意事項

- **shellcheck**: 新規スクリプトは shellcheck 通過必須
- **AI agent への指示**: `02-generate-config.md` のステップ 7.4 完了時にスクリプト出力を `${TMPDIR:-/tmp}/aidlc-setup-migrate-config-result.txt` に tee 経由で書き出すこと。7.4b 完了時に対話結果を `${TMPDIR:-/tmp}/aidlc-setup-detect-missing-applied.txt` に `0` または `1` として書き出すこと（指摘 #1 / #3 反映 / 受け渡し媒体はテンポラリファイル固定）。7.4c では `grep -E '^result:' <result-file> | head -1` で行を抽出し、`cat <applied-file>` で値を取得し、`check-noop-upgrade.sh` に渡す
- **冗長性回避**: 既存スクリプトの出力フォーマット（`result:` 行 / `summary` 行）に追加変更は加えない。本 Unit はそれらを「読む」だけ
- **設定ファイル不在時**: `02-generate-config.md` のフロー上、ステップ 7.4 / 7.4b は config.toml が存在する前提で動作する。本 Unit ではその前提を変更しない

## 不明点と質問

[Question] 受け渡し媒体としてテンポラリファイル / 環境変数 / プロセス置換 のどれを採用するか（指摘 #3 反映）。
[Answer] **テンポラリファイル**を採用。理由: (1) AI agent のセッション切替・コンパクションでも状態が消失しない、(2) 02-generate-config.md は人間にも読まれるドキュメントなのでファイル経路の明示が再現性を高める、(3) 既存の `migrate-config.sh` 出力（複数行・比較的大きい）を環境変数に詰め込むと quoting が複雑化する。`${TMPDIR:-/tmp}/aidlc-setup-migrate-config-result.txt` と `${TMPDIR:-/tmp}/aidlc-setup-detect-missing-applied.txt` の 2 ファイルを使用。

[Question] テンポラリファイルのクリーンアップを忘れた場合のリスクは？
[Answer] 残置しても害はない（次回 setup 実行時に上書きされる、最大 2 ファイル）。Phase 2 では `02-generate-config.md` のステップ 7.4c 末尾に明示的な `rm -f` 手順を追加する。

[Question] 契約フォーマット変更時の対応（指摘 #4 反映）。
[Answer] `migrate-config.sh` の `result:` 行フォーマットが将来変更される場合、`check-noop-upgrade.sh` の解析ロジックと `test_check_noop_upgrade.sh` の契約テストを同 PR 内で同時改訂する。フォーマット変更時はテストが先に失敗するため検出可能。Contract v2 が必要な場合は将来 `--migrate-config-result-version` 引数で明示する案を検討（本 Unit のスコープ外、必要時に Issue 起票）。
