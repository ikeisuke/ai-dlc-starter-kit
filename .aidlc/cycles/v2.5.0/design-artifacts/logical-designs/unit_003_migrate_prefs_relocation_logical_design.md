# 論理設計: Unit 003 aidlc-migrate での個人好みキー移動提案

## 概要

`aidlc-migrate` 実行フロー内で個人好み 7 キー検出 + 移動提案 + dry-run 対応を実装する。markdown-driven step（`02-execute.md` の新セクション `## 4`）が対話遷移を編成し、bash script（`migrate-relocate-prefs.sh`）が決定論的な検出 + 書き込みを担う**ハイブリッド構成**を採る（Unit 002 の検証 + script 委譲パターンを発展させる）。

**Unit 003 のスコープ（明示）**:

| 項目 | スコープ内／外 |
|------|---------------|
| `skills/aidlc-migrate/scripts/migrate-relocate-prefs.sh` 新規作成 | **スコープ内**（主目的） |
| `skills/aidlc-migrate/steps/02-execute.md` への `## 4` 追加 + 既存 ## 4/## 5 繰り下げ | **スコープ内** |
| `tests/aidlc-migrate-prefs/*.bats` および helpers / fixtures 新規作成 | **スコープ内** |
| `.github/workflows/migration-tests.yml` の PATHS_REGEX + 実行コマンド拡張 | **スコープ内** |
| Unit 002 安定 ID `unit002-user-global` への参照リンクの追加 | **スコープ内** |
| Unit 002 `## 9b` 案内本文の編集 | **スコープ外**（参照のみ・本文コピー禁止） |
| `defaults.toml` / `template` の編集 | **スコープ外**（Unit 001 で完了） |
| 個人好み 7 キーの正規定義変更 | **スコープ外**（Unit 001 SoT を read-only 参照） |
| `aidlc-setup` ウィザードの編集 | **スコープ外**（Unit 002 の責務） |
| 移動履歴の永続化 / 監査ログ | **スコープ外**（v2.6.x 以降の改善余地、Unit 003 では tab 区切り stdout + git 履歴で代替） |

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的な bash 実装 / bats アサーション / TOML 内容 / YAML 差分は Phase 2（コード生成）で作成する。

## アーキテクチャパターン

**Hybrid Driven Pattern**（既存 aidlc-migrate / aidlc-setup と同様）— LLM がステップファイル markdown を解釈実行し、決定論的処理（TOML 読み書き / 検出ロジック）は bash script に委譲する。本 Unit はこのパターンを Unit 002 の検証中心型から発展させ、**実 I/O を伴う書き込み処理 + 対話遷移編成**の両方をハイブリッドで成立させる。

**選定理由**:

- markdown 単体では実 I/O（TOML 編集 / dasel 呼び出し）の決定論的検証が困難
- bash 単体では LLM が編成すべき対話遷移（4 択 + yes-to-all/no-to-all + 上書き 3 択）を表現できない
- 既存 `migrate-config.sh` の `_safe_transform`（sed/awk → tmp → mv）パターンが本 Unit の編集要件（葉キー削除 + 末尾追記）に十分適合

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc-migrate/
├── steps/
│   └── 02-execute.md                                   [変更]
│       ├── ## 1〜## 3b（既存）
│       ├── ## 4. 個人好みキー移動提案                  [新規 / 安定 ID anchor 直前配置]
│       ├── ## 5. ロールバック手順                      [変更：旧 ## 4 を繰り下げ]
│       └── ## 6. 次のステップへ                        [変更：旧 ## 5 を繰り下げ]
└── scripts/
    └── migrate-relocate-prefs.sh                        [新規]

skills/aidlc/scripts/lib/
└── toml-reader.sh                                       [変更なし]  aidlc_read_toml を使用

skills/aidlc-setup/scripts/
└── migrate-config.sh                                    [変更なし]  _safe_transform パターンを参考実装

tests/aidlc-migrate-prefs/
├── helpers/
│   └── setup.bash                                       [新規]
├── detect.bats                                          [新規]
├── move.bats                                            [新規]
├── keep.bats                                            [新規]
├── dry-run.bats                                         [新規]
├── idempotency.bats                                     [新規]
├── key-set-sync.bats                                    [新規]  Unit 001 SoT との集合一致検証（観点 K1）
└── step-integration.bats                                [新規]

tests/fixtures/aidlc-migrate-prefs/
├── p-all7-keys/.aidlc/config.toml                       [新規]
├── p-mixed-3keys/.aidlc/config.toml                     [新規]
├── p-no-keys/.aidlc/config.toml                         [新規]
├── u-empty/aidlc-config.toml                            [新規]
└── u-with-key/aidlc-config.toml                         [新規]

.github/workflows/
└── migration-tests.yml                                  [変更]  PATHS_REGEX + 実行コマンド拡張
```

### コンポーネント間の依存関係

```text
[02-execute.md ## 4]
        ↓ 呼び出し
[migrate-relocate-prefs.sh]
        ↓ ライブラリ参照
[skills/aidlc/scripts/lib/toml-reader.sh] (aidlc_read_toml)
        ↓ パターン参照（コード非依存）
[skills/aidlc-setup/scripts/migrate-config.sh] (_safe_transform)

[migrate-relocate-prefs.sh] ←─── [tests/aidlc-migrate-prefs/*.bats]
        ↓                                  ↑
[tests/fixtures/aidlc-migrate-prefs/]      [helpers/setup.bash]

[02-execute.md ## 4] ←─── [step-integration.bats] (静的検証)

[02-execute.md ## 4] (stable_id = unit003-migrate-prefs-relocation)
        ←─── 将来 Unit が安定 ID で参照可能
        ─→ [03-migrate.md ## 9b] (Unit 002 stable_id = unit002-user-global) へ参照のみ（本文コピー禁止）
```

**依存方向の不変条件**:

- bash script は LLM 対話を持たない（純粋 I/O + 決定論性）
- markdown step は script を呼び出すが、script は markdown を呼び出さない（単方向依存）
- bats テストは script + helpers + fixtures に依存（helpers は script を間接呼び出し）
- 循環依存なし

## インターフェース定義

### コンポーネント A: `migrate-relocate-prefs.sh`（決定論的 script）

**サブコマンドとオプションの責務分離（一本化）**:

- **サブコマンドは `detect|move|keep` の 3 種類のみ**
- **`--dry-run` は全サブコマンド共通の「グローバルオプション」**（サブコマンドではない）
- **`--overwrite` は `move` 専用オプション**

**サブコマンド一覧**:

| サブコマンド | 必須位置引数 | 専用オプション | 目的 |
|------------|------------|--------------|------|
| `detect` | （なし） | （なし） | project_shared から個人好み 7 キーを検出 + user_global_conflict 併記 |
| `move` | `<key>`（対象キーの dotted path） | `--overwrite` | project から削除 + user_global に追記 |
| `keep` | `<key>`（対象キーの dotted path） | （なし） | 何もせず（非破壊） |

**グローバルオプション**:

| オプション | 適用サブコマンド | 用途 |
|----------|---------------|------|
| `--dry-run` | `detect` / `move` / `keep` 全て | 書き込みを行わず差分のみ表示（detect は元々読み取りのみだが、出力プレフィックスを `dry-run:` に切り替えて呼び出し側が dry-run ラン全体を一律識別できるようにする） |

**入力環境変数**:

| 名前 | 必須 | デフォルト | 用途 |
|------|------|----------|------|
| `AIDLC_PROJECT_ROOT` | No | `git rev-parse --show-toplevel` | project ルート（既存規約踏襲） |
| `AIDLC_USER_GLOBAL_PATH` | No | `${HOME}/.aidlc/config.toml` | user-global ファイルパス（テスト用オーバーライド） |

**出力フォーマット（タブ区切り単一形式 / `printf '%s\t%s\t...\n'`）**:

| プレフィックス | フィールド構成 | 出力タイミング |
|--------------|--------------|--------------|
| `detected` | `detected\t<key>\t<value>\t<user_global_conflict>` | detect サブコマンドで各検出キー 1 行 |
| `summary` | `summary\ttotal\t<N>` | detect サブコマンドの末尾（必ず 1 行） |
| `move` | `move\t<key>\t<value>\tfrom_project\tto_user_global` | move 成功時 |
| `keep` | `keep\t<key>` | keep 成功時 |
| `dry-run:detected` | 上記 detected と同形式 | dry-run + detect 時（detect 自体は読み取りのみなので dry-run でも detected を出力） |
| `dry-run:move` | 上記 move と同形式（プレフィックスのみ違い） | dry-run + move 時 |
| `dry-run:keep` | 上記 keep と同形式 | dry-run + keep 時 |
| `warn:<type>:<detail>` | stderr に出力 | 処理継続可能な競合通知（exit 0 で継続）。type 例: `user-global-key-exists`（`--overwrite` 未指定で既存キー検出時の skip 警告） |
| `error:<type>:<detail>` | stderr に出力 | 致命エラー（exit 2）。type 例: `key-not-found` / `missing-key-arg` / `dasel-not-found` / `invalid-args` / `project-config-not-found` / `unknown-subcommand` / `invalid-key` |

**プレフィックス命名規約**:

- **`error:`** は **常に exit 2** と対応する致命エラー専用（`set -e` 文脈での即時失敗）
- **`warn:`** は **常に exit 0** で処理継続可能な競合・警告通知専用
- **`dry-run:`** は dry-run 出力のプレフィックス（後続の通常プレフィックスと組み合わせて使用）
- ログ集約・将来の自動判定で `error:` 行 = 致命エラー、`warn:` 行 = 通知 / 確認が必要、と一律分類できる

**終了コード**:

| コード | 意味 |
|--------|------|
| `0` | 正常完了（detect 0 件のスキップケース含む） |
| `2` | エラー（必須引数不足 / dasel 未インストール / project ファイル不在 / 不明サブコマンド） |

**`1` は使用しない**（`detect` 0 件の意味付けに使うと `set -e` 系と衝突するため、Unit 003 計画 R1 指摘 3 の解消方針）。

**書き込み方式**（既存 migrate-config.sh パターン踏襲）:

- **project からの削除（`move` / `move --overwrite`）**:
  - `_safe_transform` 相当のシェル関数で sed/awk → tmp → mv を実行
  - 削除対象は「葉キー = 行」のみ（セクション全体の削除は本 Unit のスコープ外）
  - 削除後にセクションが空になっても`[section]`ヘッダは残す（既存挙動踏襲）
- **user-global への追記（`move`, `move --overwrite`）**:
  - 既存ファイル末尾 append（`printf '\n%s\n' >> file`）
  - 同一キー既存（`--overwrite` 未指定）: stderr に `warn:user-global-key-exists:<key>` を出力 + `0` 終了でスキップ警告（致命エラーではない / `warn:` プレフィックス命名規約に従う）
  - 同一キー既存（`--overwrite` 指定）: 既存キー行を sed/awk で削除した後に新値を追記
  - ファイル不在時: 最小ヘッダコメント + 必要なセクション + キー値で新規作成

**配列値の扱い**: `rules.reviewing.tools = ["codex"]` 等は dasel が出力する形式（`['codex']` のシングルクォート形式）を一度通常 TOML 形式（`["codex"]`）に正規化してから user_global に書き出す。テストでは fixture の元値と書き出し後の値の意味的等価性を検証する。

**冪等性の保証**:

- detect は project_shared の現状を毎回フルスキャンする純粋関数
- 移動済みキーは project から削除済みのため次回 detect で 0 件結果に貢献
- 追加状態（履歴ファイル等）は持たない（IdempotencyResolver のドメイン判断）

### コンポーネント B: `02-execute.md ## 4` セクション（編成 step）

**配置**: `## 3b. Issueテンプレートの確認` の直後 / 既存 `## 4. ロールバック手順` の直前

**繰り下げ**: 既存 `## 4. ロールバック手順` → `## 5. ロールバック手順`、`## 5. 次のステップへ` → `## 6. 次のステップへ`

**安定 ID**: セクション直前に HTML コメントアンカー `<!-- guidance:id=unit003-migrate-prefs-relocation -->` を配置（Unit 002 と同パターン / 文言変更耐性）

**論理構造**:

| 順序 | 要素 | 内容 |
|------|------|------|
| 1 | Title | `## 4. 個人好みキー移動提案` |
| 2 | Unit002Reference | Unit 002 安定 ID `unit002-user-global`（`skills/aidlc-setup/steps/03-migrate.md` の `## 9b`）への参照リンク + 「本案内の本文は単一ソース化のためコピーしません」旨 |
| 3 | DetectInvocation | `migrate-relocate-prefs.sh detect` 実行 + 出力解釈手順（タブ区切り行をパースして key / value / user_global_conflict を取得） |
| 4 | DetectZeroSkip | 検出 0 件（`summary total 0`）の場合、本セクションをスキップして次のステップ（## 5）へ進む旨 |
| 5 | InteractionLoop | 検出キーごとに以下を反復: |
|    | + BulkActionStateInit | 初期 `bulk_action = none` を維持 |
|    | + MainQuestion | bulk_action == none の場合、`AskUserQuestion` で 4 択（`移動` / `そのまま残す` / `全件移動 (yes-to-all)` / `全件残す (no-to-all)`、`header: "個人好み移動"`）を提示 |
|    | + BulkActionTransition | yes-to-all 選択 → bulk_action = move-all、no-to-all 選択 → bulk_action = keep-all、以降のキーは無質問で derive_action_for を適用 |
|    | + ConflictConfirmation | `move` または `move-all` 適用キーかつ user_global_conflict == true の場合、追加 `AskUserQuestion` で 3 択（`上書き` / `スキップ` / `キャンセル`、`header: "上書き確認"`）を提示 |
|    | + ScriptInvocation | 各 RelocationAction に対応する script コマンドを呼び出し（`Move` → `migrate-relocate-prefs.sh move <key>`, `MoveOverwrite` → `move <key> --overwrite`, `Keep` → `keep <key>`, `Cancel` → script 呼び出しなしでフロー全体中断。dry-run 時は全コマンドに `--dry-run` を付与） |
| 6 | DryRunNote | dry-run コンテキスト（既存 aidlc-migrate に dry-run があれば連動 / なければ markdown フラグで判定）の連携指示 |
| 7 | IdempotencyNote | 「移動済みキーは次回実行時に detect で再検出されない」旨の冪等性指示 |

**実行条件**: aidlc-migrate のデータ移行ステップ（## 1〜## 3b）が成功した直後。エラー時は `git checkout .` でロールバック可能であることを既存パターンに従って明記する。

### コンポーネント C: `helpers/setup.bash`（共通ヘルパ）

**責務**: bats テストから呼び出される一時環境構築 + 比較ヘルパ群の提供

**定数 / 環境変数**（`readonly` / `setup` で初期化）:

| 名前 | 型 | 用途 |
|------|---|------|
| `SCRIPT_PATH` | string（path） | `<repo_root>/skills/aidlc-migrate/scripts/migrate-relocate-prefs.sh` の絶対パス |
| `FIXTURES_DIR` | string（path） | `<repo_root>/tests/fixtures/aidlc-migrate-prefs` の絶対パス |
| `STEP_FILE_PATH` | string（path） | `<repo_root>/skills/aidlc-migrate/steps/02-execute.md` の絶対パス |

**関数 API**:

| 関数名 | 引数 | 戻り値 | 失敗時 exit code | 用途 |
|--------|------|-------|------------------|------|
| `setup_env` | `project_fixture`: string, `user_global_fixture`: string | `TEST_TMPDIR`, `AIDLC_PROJECT_ROOT`, `AIDLC_USER_GLOBAL_PATH` を export | 1（fixture 不在） | 一時ディレクトリにフィクスチャをコピーし環境変数設定 |
| `teardown_env` | （なし） | （なし） | （常に 0） | `TEST_TMPDIR` を削除 |
| `run_detect` | （なし） | `${output}` に script stdout、`${status}` に exit code | （bats 規約） | `migrate-relocate-prefs.sh detect` をラップ |
| `run_move` | `key`, `[--overwrite]`, `[--dry-run]` | 同上 | （bats 規約） | `migrate-relocate-prefs.sh move <key> [opts]` をラップ |
| `run_keep` | `key`, `[--dry-run]` | 同上 | （bats 規約） | `migrate-relocate-prefs.sh keep <key> [opts]` をラップ |
| `assert_file_unchanged` | `path` | （なし） | 1（変更検出） | sha256 で `setup_env` 時点との一致確認 |
| `assert_file_changed` | `path` | （なし） | 1（変更なし） | 同上の逆 |
| `assert_key_absent_in_project` | `key` | （なし） | 1（含有検出） | project file から該当キー行が削除されたか |
| `assert_key_present_in_user_global` | `key`, `expected_value` | （なし） | 1（不在 or 値不一致） | user-global に追記されたか |
| `extract_step_section_body` | `anchor` | stdout | 1 | `02-execute.md` から指定セクション本文を抽出（Unit 002 helper と同等） |
| `assert_section_count_in_step_file` | `pattern`, `expected` | （なし） | 1 | パターン出現数検証 |

### コンポーネント D: `tests/aidlc-migrate-prefs/*.bats`（観点別検証）

**観点 A（detect.bats / 4 ケース）**: 0 件 / 部分 3 件 / 全 7 件 + `<user_global_conflict>` 列の true/false 検証

**観点 B（move.bats / 6 ケース）**: 削除 / 追記 / 配列完全置換 / 新規作成 / 既存キー警告 + skip / `--overwrite` 上書き

**観点 C（keep.bats / 2 ケース）**: 非破壊性（sha256 一致） / ログ出力

**観点 D（dry-run.bats / 3 ケース）**: 出力一致（実 move と dry-run move の `dry-run:` プレフィックス除去後 diff 0） / project ファイル変更なし / user-global ファイル変更なし

**観点 E（idempotency.bats / 2 ケース）**: 移動後 detect 0 件 / 部分移動後の残存 detect

**観点 K（key-set-sync.bats / 1 ケース）**:

- K1: `migrate-relocate-prefs.sh` 内ハードコード 7 キー集合 = Unit 001 SoT 集合（`tests/config-defaults/helpers/setup.bash` の `b1_expected_for` で定義された 7 キー）の対称差が 0

**観点 S（step-integration.bats / 6 ケース）**:

- S1: `## 4. 個人好みキー移動提案` セクションが 1 回のみ存在
- S2: 位置検証（`## 3b.` < `## 4.` < `## 5.` の行番号順序）
- S3: 4 択（`移動` / `残す` / `全件移動` / `全件残す`）の文字列含有
- S4: 対話遷移規則（`yes-to-all` / `no-to-all` / `bulk_action`）の文字列含有
- S5: 安定 ID `<!-- guidance:id=unit003-migrate-prefs-relocation -->` が `## 4` 直前行に 1 回のみ
- S6: Unit 002 安定 ID `unit002-user-global` への参照（文字列含有 + 単一ソース原則の言及）

**実行コマンド**: `bats tests/aidlc-migrate-prefs/`

### コンポーネント E: `migration-tests.yml`（CI 接続）

**変更内容**:

- **PATHS_REGEX 拡張**: 既存パターンに以下を追加
  - `tests/aidlc-migrate-prefs/.+`
  - `tests/fixtures/aidlc-migrate-prefs/.+`
  - `skills/aidlc-migrate/steps/.+`（既存パターンには未含有）
  - `skills/aidlc-migrate/scripts/migrate-relocate-prefs\.sh`（既存 `migrate-.*\.sh` パターンで自動カバー / 念のため明示）
- **実行コマンド変更**: `bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/` → `bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/ tests/aidlc-migrate-prefs/`

**境界条件**:

- 既存テスト群の実行は維持
- ジョブ表示名「Migration Script Tests」は本 Unit でもリネームしない（Unit 001 / 002 から継続する課題 / 履歴連続性優先）

## エラーハンドリング

### script レベル

| エラー条件 | 出力 | exit code |
|----------|------|-----------|
| 必須引数不足（`move` / `keep` の `<key>` 未指定） | stderr: `error:missing-key-arg:<subcommand>` | 2 |
| 不明サブコマンド | stderr: `error:unknown-subcommand:<arg>` | 2 |
| project file 不在 | stderr: `error:project-config-not-found:<path>` | 2 |
| dasel 未インストール | stderr: `error:dasel-not-found` | 2 |
| user-global に対象キー既存（`--overwrite` 未指定） | stderr: `warn:user-global-key-exists:<key>` | 0（警告 + skip / 致命でない / `warn:` プレフィックス） |
| 不正キー（個人好み 7 キー集合外） | stderr: `error:invalid-key:<key>` | 2 |

### markdown step レベル

- 既存 aidlc-migrate のロールバック手順（`## 5. ロールバック手順` / 旧 ## 4）に従う
- script からの致命エラー（exit 2）検出時、`git checkout .` でロールバック可能であることを再案内
- script からの警告（`warn:user-global-key-exists` / exit 0）時は、conflict 確認の追加 AskUserQuestion を経由しているはずなので step 側でハンドル不要

## NFR チェック

| NFR | 検証手段 |
|-----|---------|
| 非破壊性（「残す」選択時に project / user-global を変更しない） | keep.bats（観点 C1）で sha256 一致を確認 |
| 冪等性（移動済みキーが再 detect されない） | idempotency.bats（観点 E1 / E2）で実機検証 |
| dry-run 完全性（dry-run と実 move の出力完全一致） | dry-run.bats（観点 D1）で diff 検証 |
| 安定 ID 契約 | step-integration.bats（観点 S5）で `## 4` 直前行 + 出現数 1 を検証 |
| 単一ソース原則（Unit 002 案内本文を二重定義しない） | step-integration.bats（観点 S6）で Unit 002 安定 ID 参照 + 重複なしを検証 |
| Unit 001 キー集合との同期（`migrate-relocate-prefs.sh` 内ハードコードされた 7 キーが Unit 001 SoT と一致） | キー集合一致テスト（観点 K1）で実機検証 |

## Unit 001 正規 7 キー集合への固定参照点（read-only 参照契約）

本 Unit のスクリプトはパフォーマンス上の理由で 7 キーをスクリプト内にハードコードする（detect 実行時に `defaults.toml` を毎回読み取らない）。Unit 001 SoT との同期が崩れるリスクを以下で回避する:

**固定参照点**:

- **SoT（Source of Truth）**: `.aidlc/cycles/v2.5.0/story-artifacts/user_stories.md` のストーリー 1（受け入れ基準内の 7 キー列挙）
- **派生先 1**: `skills/aidlc/config/defaults.toml`（Unit 001 で値を集約）
- **派生先 2（本 Unit）**: `skills/aidlc-migrate/scripts/migrate-relocate-prefs.sh` 内の定数配列（例: `INDIVIDUAL_PREFERENCE_KEYS=(rules.reviewing.mode rules.reviewing.tools ...)`）
- **派生先 3（既存）**: `tests/config-defaults/helpers/setup.bash`（Unit 001 で定義済み / B1 期待値）

**変更検知テスト（観点 K1）**: `tests/aidlc-migrate-prefs/key-set-sync.bats` を新設し、以下の 2 経路の集合一致を実機検証する:

- `migrate-relocate-prefs.sh` 内ハードコード集合 vs Unit 001 `defaults.toml` の個人好み 7 キー集合（`tests/config-defaults/helpers/setup.bash` から再利用可能な期待値関数を参照）
- 集合の対称差が空（追加・削除・改名いずれも検出）

**観点 K1 の追加**:

- **K1**: `migrate-relocate-prefs.sh` 内ハードコード 7 キー = Unit 001 正規 7 キー集合（対称差 0）

これにより Unit 001 SoT 変更時に CI で乖離を検出可能となり、人手依存の追従を排除する。

## Unit 001 / 002 / 003 のキー集合参照ハブ（参考）

| 参照場所 | 形式 | 同期手段 |
|---------|------|---------|
| Unit 001 user_stories.md ストーリー 1 | 文書（SoT） | 手動編集 |
| Unit 001 `skills/aidlc/config/defaults.toml` | TOML 値 | check-defaults-sync.sh |
| Unit 001 `tests/config-defaults/helpers/setup.bash`（`b1_expected_for`） | bash 関数 | bats（手動同期） |
| Unit 002 `## 9b` 案内本文の代表 3 キー | markdown | step-integration.bats（部分集合検証） |
| Unit 003 `migrate-relocate-prefs.sh` 内ハードコード | bash 配列 | **観点 K1** で対称差 0 を CI 検証（本 Unit で新設） |

## 実装計画への接続

論理設計レベルでは以下が決定済み:

- `migrate-relocate-prefs.sh` のサブコマンド / 引数 / 出力フォーマット / 終了コード仕様
- `02-execute.md ## 4` の論理構造（7 要素）と script 呼び出しコマンド対応
- bats ヘルパ関数のインターフェース（引数 / 戻り値 / 失敗時 exit code）
- 5 種類 fixture と各観点テスト（A 4 + B 6 + C 2 + D 3 + E 2 + S 6 = 23 ケース想定）の対応
- CI 接続の最小拡張内容（PATHS_REGEX + 実行コマンド延長）

Phase 2（コード生成）では:

- `migrate-relocate-prefs.sh` の bash 実装（`_safe_transform` + `aidlc_read_toml` + 検出ロジック）
- `02-execute.md ## 4` の具体的 markdown 表現
- `helpers/setup.bash` の bash 関数実装
- `*.bats` の bats アサーション実装（A〜S の 23 ケース）
- 5 種類 fixture の TOML 内容
- `migration-tests.yml` の YAML 差分

を順次作成する。
