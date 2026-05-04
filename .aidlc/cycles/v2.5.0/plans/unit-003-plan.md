# Unit 003 計画: aidlc-migrate での個人好みキー移動提案

## 概要

`aidlc-migrate` 実行時に project `.aidlc/config.toml` から「個人好み」7 キー（user_stories.md ストーリー 1 / Unit 001 正規定義）を検出し、各キーごとに `~/.aidlc/config.toml`（user-global）への移動を AskUserQuestion で提案する機能を追加する。「移動」/「残す」/「全件移動 (yes-to-all)」/「全件残す (no-to-all)」の 4 択 + 対話遷移規則 + dry-run 完全性 + 「残す」選択時の非破壊性 + 冪等性の 5 観点を成立させる。

aidlc-migrate は `markdown-driven step + bash script` のハイブリッド構成（Unit 002 の aidlc-setup と同様）。本 Unit は新規 bash スクリプト（detect / move / keep / dry-run）と既存 step ファイル（`02-execute.md`）への新セクション追加で実装する。Unit 002 の安定 ID `unit002-user-global` を参照し、案内文言を二重保守しない（単一ソース原則）。

## 対象キー（user_stories.md ストーリー 1 の正規定義）

Unit 001 / Unit 002 と同一の 7 キー。本 Unit ではこの集合を script 内ハードコード + bats fixture でも同一値で扱う（将来の自動同期は v2.6.x 以降）。

| # | キー | 値型 |
|---|------|------|
| 1 | `rules.reviewing.mode` | string |
| 2 | `rules.reviewing.tools` | array |
| 3 | `rules.automation.mode` | string |
| 4 | `rules.git.squash_enabled` | boolean |
| 5 | `rules.git.ai_author` | string |
| 6 | `rules.git.ai_author_auto_detect` | boolean |
| 7 | `rules.linting.enabled` | boolean |

## 現状分析

### `aidlc-migrate` の構造

- **markdown-driven + script 併用**: `skills/aidlc-migrate/SKILL.md` がステップファイル（`steps/01-preflight.md` → `02-execute.md` → `03-verify.md`）を読み込み、各ステップから `scripts/migrate-*.sh` を呼び出す
- **既存スクリプト**: `migrate-detect.sh`（v1 検出 + manifest 生成） / `migrate-apply-config.sh` / `migrate-apply-data.sh` / `migrate-cleanup.sh` / `migrate-verify.sh`
- **TOML 読み取り**: `skills/aidlc/scripts/lib/toml-reader.sh` の `aidlc_read_toml`（dasel v2/v3 互換 + ブラケット記法変換）
- **TOML 書き込み**: `skills/aidlc-setup/scripts/migrate-config.sh` の `_safe_transform`（sed/awk → tmp → mv の安全パターン）+ 末尾 append 形式（`printf '\n%s\n' >> file`）
- **dasel `put` は v3 で廃止済み**（`02-generate-config.md` 7.4b で明記）。書き込みは sed/awk + 一時ファイル + mv で実装する

### `~/.aidlc/config.toml` の状態想定

- 既存ユーザー: 存在する場合あり（個人好みキーが既に書かれている可能性）
- 新規ユーザー: 不在の場合あり（最小ヘッダコメント付きで新規作成する）
- 同一キーが user-global に既存の場合: 上書き可否を AskUserQuestion で追加確認（NFR「同一キー既存時の確認」）

### Unit 002 との文言整合

Unit 002 で導入した「個人好みは user-global 推奨」案内テキストは `skills/aidlc-setup/steps/03-migrate.md` の `## 9b` セクション（stable_id: `unit002-user-global`）に単一ソース化されている。本 Unit では migrate 提案フロー冒頭で「Unit 002 の `## 9b` セクション（stable_id: `unit002-user-global`）と同等の案内ですが、既存プロジェクトに対して個別キーごとに移動可否を確認します」旨を 1 行で言及し、本文は再掲しない（単一ソース原則）。

## 変更対象ファイル

### Phase 1: 新規スクリプト

1. **`skills/aidlc-migrate/scripts/migrate-relocate-prefs.sh`** — 個人好みキー検出 + 移動 + dry-run の主要スクリプト
   - **サブコマンド形式**:
     - `detect`: project に存在する個人好み 7 キーを列挙し、各キーごとに「user-global にも同名キーが既存か（user_global_conflict）」を併記する**タブ区切り行形式**で出力。検出 0 件でも正常終了とし `summary` のみ出力する
     - `move <key> [--overwrite]`: 指定キーを project から削除 + user-global に追記。`--overwrite` 指定時は user-global に同一キー既存でも上書きする（デフォルトは警告 + skip）
     - `keep <key>`: 何もしない（ログのみ、非破壊）
     - `--dry-run`: 移動操作の差分のみ表示（書き込みなし）
   - **入力環境変数**:
     - `AIDLC_PROJECT_ROOT`（既存規約踏襲）
     - `AIDLC_USER_GLOBAL_PATH`（テスト用 user-global オーバーライド、未指定時 `${HOME}/.aidlc/config.toml`）
   - **出力フォーマット（タブ区切り単一形式に固定）**: 既存 migration 系の `migrate-config.sh` 出力（`migrate:add-section:<name>` / `skip:already-exists:<name>` 等）と同じスタンスで、grep / awk でパース可能なタブ区切り単一形式を採用する。JSON 形式は採用しない（既存系統と統一性を優先 / 依存最小化）。
     - `detect` 成功: `detected\t<key>\t<value>\t<user_global_conflict>` を 0 件以上、最終行に `summary\ttotal\t<N>`
       - `<user_global_conflict>` は `true` / `false`。markdown 側の「上書き可否」追加確認はこの値が `true` のキーに限定して提示する設計（責務一本化: detect 出力で project / user-global 両方の状態を一度に提供）
       - 値中のタブ・改行はテストで扱わない（個人好み 7 キーの値は string / boolean / `["codex"]` 程度の単純配列のみ）
     - `move` 成功: `move\t<key>\t<value>\tfrom_project\tto_user_global`
     - `keep` 成功: `keep\t<key>`
     - dry-run: `dry-run:` プレフィックス付きで上記同等行を出力（diff 比較で完全一致を観点 D1 で検証）
     - エラー: `error:<type>:<detail>` を stderr + 非 0 exit
   - **終了コード**:
     - `0`: 正常完了（検出 0 件のスキップケースも `0` を返す。`set -e` 文脈で正常スキップを異常扱いさせないため）
     - `2`: エラー（ファイル不在 / dasel 未インストール / 引数不正）
     - **`1` は使用しない**（`detect` 0 件の意味付けに使うと set -e 系と衝突するため）
   - **書き込み方式**:
     - project からの削除: `_safe_transform` 相当（sed/awk → tmp → mv）でキー行を除去
     - user-global への追記: 既存ファイル末尾 append（`printf '\n%s\n' >> file`）。同一キー既存時は警告 + skip（呼び出し側 step で「上書き可否」を別途確認する設計）
     - user-global ファイル不在時: 最小ヘッダコメント + セクション + キー値で新規作成
   - **配列値の扱い**: NFR「配列値は完全置換（マージしない）」を踏襲。`rules.reviewing.tools = ["codex"]` → user-global に同形式で書き出す

### Phase 2: ステップファイル差分

2. **`skills/aidlc-migrate/steps/02-execute.md`** — 新セクション `## 4. 個人好みキー移動提案` を `## 3b. Issueテンプレートの確認` の直後 / `## 4. ロールバック手順` の直前に挿入
   - **既存セクション番号の繰り下げ**: 既存「## 4. ロールバック手順」→「## 5. ロールバック手順」、「## 5. 次のステップへ」→「## 6. 次のステップへ」
   - **新セクションの安定 ID**: 直前行に `<!-- guidance:id=unit003-migrate-prefs-relocation -->` を配置（Unit 002 と同パターン）
   - **本文構成**:
     - Unit 002 `## 9b`（stable_id: `unit002-user-global`）への参照リンクで案内本文の単一ソース原則を明記
     - `migrate-relocate-prefs.sh detect` 実行 → 検出 0 件ならスキップ
     - 検出 1 件以上の場合、各キーごとに `AskUserQuestion` で 4 択を提示
       - 選択肢ヘッダ: `header: "個人好み移動"`
       - 4 択: `移動 (user-global へ)` / `そのまま残す` / `全件移動 (yes-to-all)` / `全件残す (no-to-all)`
       - 描述: 各選択肢に description を添える
     - **対話遷移規則の指示文**:
       - 最初のキー（または以降の任意キー）で `yes-to-all` 選択 → 残り全キーに `move` を無質問で適用
       - 同様に `no-to-all` → 残り全キーに `keep` を無質問で適用
       - `移動` / `残す` 単独選択 → 次キーで再度 4 択を提示
     - **`移動` 選択時の追加確認**:
       - `detect` 出力の `<user_global_conflict>` が `true` のキーについてのみ、追加 `AskUserQuestion` で「上書き / スキップ / キャンセル」3 択を提示する（responsibility 一本化: detect 出力からそのまま判定可能）
       - **3 択それぞれの script 呼び出しコマンド**:
         - `上書き` → `migrate-relocate-prefs.sh move <key> --overwrite`
         - `スキップ` → `migrate-relocate-prefs.sh keep <key>`
         - `キャンセル` → 個人好みキー移動提案フロー全体を中断（`migrate-relocate-prefs.sh` を呼び出さない）
     - **dry-run モード**:
       - 既存の aidlc-migrate dry-run コンテキスト（あれば）に従い、`--dry-run` フラグを付与
     - **冪等性指示**: 「既に移動済みのキー（project に不在 / user-global にのみ存在）は detect で再検出されない」旨を明記

### Phase 3: テスト追加

`tests/aidlc-migrate-prefs/` を新設し、bash スクリプトのユニットテスト + ステップファイル静的検証を bats で実装する。

**新規テストファイル**:

- `tests/aidlc-migrate-prefs/detect.bats` — `detect` サブコマンドの検出結果を観点別に検証
- `tests/aidlc-migrate-prefs/move.bats` — `move` サブコマンドの project 削除 + user-global 追記を検証
- `tests/aidlc-migrate-prefs/keep.bats` — `keep` サブコマンドが project / user-global を変更しないことを検証
- `tests/aidlc-migrate-prefs/dry-run.bats` — dry-run の差分が実際の `move` と完全一致することを検証
- `tests/aidlc-migrate-prefs/idempotency.bats` — 移動済みキーが detect に出てこないことを検証
- `tests/aidlc-migrate-prefs/step-integration.bats` — `02-execute.md` の `## 4` セクション静的検証（観点 A〜D + 安定 ID）
- `tests/aidlc-migrate-prefs/helpers/setup.bash` — 共通ヘルパ（fixture 作成 / user-global 一時パス / `safe_transform` 期待値生成）

**Fixture**:

- `tests/fixtures/aidlc-migrate-prefs/p-all7-keys/.aidlc/config.toml` — project に 7 キー全て存在
- `tests/fixtures/aidlc-migrate-prefs/p-mixed-3keys/.aidlc/config.toml` — project に 3 キーのみ存在（`rules.reviewing.mode` / `rules.git.squash_enabled` / `rules.linting.enabled`）
- `tests/fixtures/aidlc-migrate-prefs/p-no-keys/.aidlc/config.toml` — project に 0 キー（detect 結果空）
- `tests/fixtures/aidlc-migrate-prefs/u-empty/aidlc-config.toml` — user-global 空（最小ヘッダのみ）
- `tests/fixtures/aidlc-migrate-prefs/u-with-key/aidlc-config.toml` — user-global に既に `rules.reviewing.mode` 存在（上書き確認シナリオ用）

**観点**:

| 観点 | 検証内容 | テストファイル |
|------|---------|--------------|
| A1〜A3 | detect: 全 7 キー / 部分 3 キー / 0 キーの正しい検出（0 件でも exit 0 + summary total 0 / `<user_global_conflict>` 列を含む） | detect.bats |
| A4 | detect: `<user_global_conflict>` 列が user-global の状態を正しく反映（`true` / `false` の双方を fixture で検証） | detect.bats |
| B1〜B3 | move: project から削除 / user-global に追記 / 配列値の完全置換 | move.bats |
| B4 | move: user-global ファイル不在時の新規作成（最小ヘッダ付き） | move.bats |
| B5 | move: user-global に同一キー既存時の警告 + skip 動作（`--overwrite` 未指定） | move.bats |
| B6 | move `--overwrite`: user-global 既存キーを上書き実行（値が新値に置換される） | move.bats |
| C1 | keep: project / user-global いずれも変更しない（mtime / sha 一致確認） | keep.bats |
| C2 | keep: stdout に keep ログ出力 | keep.bats |
| D1〜D3 | dry-run: 出力が実際の move と完全一致 / project ファイル変更なし / user-global ファイル変更なし | dry-run.bats |
| E1〜E2 | 冪等性: 移動済みキーが再 detect で出てこない / 部分移動後に残ったキーのみ検出 | idempotency.bats |
| S1〜S5 | step-integration: `## 4` セクション存在 / 位置 / 4 択指示 / yes-to-all/no-to-all 遷移指示 / 安定 ID 配置 / Unit 002 参照 | step-integration.bats |

**実行コマンド**: `bats tests/aidlc-migrate-prefs/`

### Phase 4: CI 接続

`.github/workflows/migration-tests.yml` を最小拡張:

- **PATHS_REGEX 拡張**: `tests/aidlc-migrate-prefs/.+` および `tests/fixtures/aidlc-migrate-prefs/.+` を追加。スクリプト側 `skills/aidlc-migrate/scripts/migrate-.*\.sh` は既存パターンで既にカバー済み
- **実行コマンド変更**: `bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/` → `bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/ tests/aidlc-migrate-prefs/`
- **新規 workflow ファイルは作成しない**（Unit 001 / 002 と同じ最小拡張方針）

### Phase 5: ドキュメント整合

- Unit 003 定義（`.aidlc/cycles/v2.5.0/story-artifacts/units/003-migrate-prefs-relocation.md`）の実装状態を完了に更新
- 設計ドキュメント（domain model / logical design）を Unit 001 / 002 と同じディレクトリ構造で作成
- 構造記録（`.aidlc/cycles/v2.5.0/construction/units/003-...md` + `003-review-summary.md`）を完了処理時に作成

## 実装計画

### 設計方針

- **markdown × bash の責務分離**:
  - bash script（`migrate-relocate-prefs.sh`）: 検出 + TOML 読み書き（純粋な処理ロジック）
  - markdown step（`02-execute.md ## 4`）: AskUserQuestion 対話遷移 + ユーザー承認 + script 呼び出しの編成
  - script は対話を持たない（CI / dry-run / テストで決定論的に検証可能）
- **対話遷移規則は markdown 側に配置**: `yes-to-all` / `no-to-all` の遷移は LLM が実行ループ内で状態管理（local 変数 `bulk_action ∈ {none, move-all, keep-all}`）
- **配列値の完全置換**: 4 階層マージ仕様維持。`rules.reviewing.tools = ["codex"]` を user-global に書く際もマージしない
- **dry-run 完全性**: dry-run 時の出力行は実際の `move` 時と完全に同じ形式（`dry-run:` プレフィックス除去）。Phase 3 dry-run.bats で実機検証
- **既存スクリプトパターン踏襲**: `_safe_transform`（sed/awk → tmp → mv）+ aidlc_read_toml（dasel v2/v3 互換）+ タブ区切り単一出力形式（既存 migration 系 migrate-config.sh と統一）。新規依存は導入しない
- **テスト分離方針**: bash スクリプトテスト（dynamic / I/O あり / fixture 必要）と markdown 静的検証テスト（grep ベース）を別 bats ファイルに分離

### Unit 001 / 002 との境界

| 論点 | 所有 Unit | 他 Unit の扱い |
|------|----------|---------------|
| `config.toml.template` の 7 キー除去 | Unit 001（完了） | Unit 002 / 003 は変更しない |
| `defaults.toml` の 7 キー値 | Unit 001（完了、変更なし） | Unit 002 / 003 は変更しない |
| `aidlc-setup` ウィザード `## 9b` 案内 | Unit 002（完了 / 単一ソース） | Unit 003 は安定 ID `unit002-user-global` で参照のみ・本文コピー禁止 |
| `aidlc-migrate` 移動提案ロジック（**本 Unit**） | **Unit 003** | Unit 001 / 002 は触れない |
| 「個人好みは user-global 推奨」案内本文 | Unit 002（master / 単一ソース） / Unit 003（参照のみ） | Unit 001 は本文を持たない |
| 個人好み 7 キーの正規定義 | Unit 001（user_stories.md ストーリー 1） | Unit 002 / 003 は read-only 参照（script 内ハードコード） |

### ステップ

1. `skills/aidlc-migrate/scripts/migrate-relocate-prefs.sh` を新規作成（detect / move / keep / dry-run）
2. `tests/aidlc-migrate-prefs/helpers/setup.bash` を新規作成（fixture コピー / 一時ディレクトリ / sha 比較等）
3. `tests/fixtures/aidlc-migrate-prefs/` 配下の 5 種類 fixture を新規作成
4. bash スクリプトのユニットテスト（detect / move / keep / dry-run / idempotency）を bats で 5 ファイル新規作成
5. `skills/aidlc-migrate/steps/02-execute.md` に `## 4. 個人好みキー移動提案` セクションを追加（既存 ## 4 / ## 5 を ## 5 / ## 6 に繰り下げ）+ 安定 ID コメントアンカー配置
6. ステップファイル静的検証 bats を新規作成（`tests/aidlc-migrate-prefs/step-integration.bats`）
7. `.github/workflows/migration-tests.yml` の `PATHS_REGEX` と実行コマンドを拡張
8. ローカルでテスト実行（`bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/ tests/aidlc-migrate-prefs/`）— 既存テストへの回帰なしを確認
9. markdownlint 実行
10. AI レビュー（計画 / 設計 / コード / 統合）
11. コミット + squash

## 完了条件チェックリスト

- [x] `skills/aidlc-migrate/scripts/migrate-relocate-prefs.sh` が detect / move / keep の 3 サブコマンド + `--dry-run` グローバルオプション + `--overwrite` move 専用オプションを実装している
- [x] script の入出力フォーマット（タブ区切り単一形式: `detected\t<key>\t<value>\t<user_global_conflict>` / `summary\ttotal\t<N>` / `move\t...` / `keep\t...` / `error:<type>:<detail>`）が固定化されパース可能（JSON 形式は採用しない / 既存 migration 系統と統一）
- [x] script の終了コードが `0=正常 / 2=エラー` の 2 値で `1` を使用しない（detect 0 件は `0` + `summary total 0` で表現、set -e 文脈でのスキップ誤判定を回避）
- [x] `detect` 出力が project 側検出結果に加えて `<user_global_conflict>` を併記し、step 側「上書き可否」追加確認の判定根拠を一本化している（責務分離テスト）
- [x] script が project からの削除に `_safe_transform` 相当（sed/awk → tmp → mv）を使用（dasel `put` 廃止対応）
- [x] script が user-global に追記する際、ファイル不在時は最小ヘッダ付きで新規作成する
- [x] script が user-global に同一キー既存時は警告 + skip し、上書き可否は呼び出し側で確認する設計
- [x] script が `--dry-run` フラグで書き込みを行わないことを bats で実機検証（D1〜D3 ケース PASS）
- [x] script が冪等性（移動済みキー再検出ゼロ）を bats で実機検証（E1 / E2 ケース PASS）
- [x] `skills/aidlc-migrate/steps/02-execute.md` に `## 4. 個人好みキー移動提案` セクションが追加されている
- [x] 既存 `## 4. ロールバック手順` / `## 5. 次のステップへ` が `## 5` / `## 6` に繰り下げられている（参照リンクの破壊なし）
- [x] `## 4` セクションの直前行に安定 ID コメントアンカー `<!-- guidance:id=unit003-migrate-prefs-relocation -->` が配置されている（S5 ケース PASS）
- [x] `## 4` セクション本文に Unit 002 安定 ID `unit002-user-global` への参照（単一ソース）が含まれる
- [x] `## 4` セクション本文に 4 択（`移動` / `残す` / `全件移動 (yes-to-all)` / `全件残す (no-to-all)`）の選択肢指示が含まれる
- [x] `## 4` セクション本文に対話遷移規則（`yes-to-all` / `no-to-all` 後は無質問で同一適用）の指示が含まれる
- [x] **観点 A テスト**: detect.bats が 0 件 / 部分 3 件 / 全 7 件 + `<user_global_conflict>` 列の true/false 検証の 4 ケース PASS
- [x] **観点 B テスト**: move.bats が削除 / 追記 / 配列完全置換 / 新規作成 / 既存キー警告 + skip / `--overwrite` での上書き実行の 6 ケース PASS
- [x] **観点 C テスト**: keep.bats が非破壊性 / ログ出力の 2 ケース PASS
- [x] **観点 D テスト**: dry-run.bats が出力一致 / project 変更なし / user-global 変更なしの 3 ケース PASS
- [x] **観点 E テスト**: idempotency.bats が再検出ゼロ / 部分移動後の残存検出の 2 ケース PASS
- [x] **観点 S テスト**: step-integration.bats が ## 4 セクション存在 + 位置 + 4 択 + 遷移規則 + 安定 ID + Unit 002 参照の 6 ケース PASS
- [x] CI 接続: `.github/workflows/migration-tests.yml` の `PATHS_REGEX` と実行コマンドが拡張され、PR 上で `bats tests/aidlc-migrate-prefs/` が走る
- [x] 既存の `tests/migration/` / `tests/config-defaults/` / `tests/aidlc-setup/` のテストが回帰せずパスする（87 件 → 110+ 件想定）
- [x] `.md` 差分の markdownlint パス
- [x] Unit 003 定義（`story-artifacts/units/003-migrate-prefs-relocation.md`）の実装状態が「完了」に更新されている

## NFR チェック

- **非破壊性**: keep.bats（観点 C1）で project / user-global の sha256 一致を確認することで、「残す」選択時の非変更を実機検証
- **冪等性**: idempotency.bats（観点 E1 / E2）で「移動済みキーが再 detect されない」「部分移動後に残ったキーのみ検出される」を実機検証
- **dry-run 完全性**: dry-run.bats（観点 D1）で dry-run 出力と実 move 出力（`dry-run:` プレフィックス除去後）の完全一致を diff で検証

## 想定リスクと対策

| リスク | 対策 |
|--------|------|
| dasel v3 の `put` 廃止により書き込みロジックが脆弱化（sed/awk ベースで TOML 構造を壊す可能性） | `migrate-config.sh` で実績ある `_safe_transform`（sed/awk → tmp → mv）パターンを採用。move.bats / dry-run.bats で fixture 比較により構造保全を実機検証。複雑な編集（ネストテーブル変更等）は本 Unit のスコープ外（葉キーの削除 + 末尾追記のみ） |
| user-global の既存キー上書き判断が markdown 側に押し込まれて UX 複雑化 | script 側で「既存キー検出時は警告 + skip」する保守的デフォルトを採用し、上書き可否は markdown 側の追加 AskUserQuestion で明示的に取得。これにより script 単体は決定論的（CI で検証可能） |
| 対話遷移規則（yes-to-all / no-to-all）の状態管理を LLM が誤る | `## 4` セクション本文に「`bulk_action ∈ {none, move-all, keep-all}` の状態を最初のキーから順に管理する」旨の擬似コード相当の手順を明記。step-integration.bats（観点 S）で関連文字列の含有を静的検証 |
| 配列値（`rules.reviewing.tools`）の完全置換ロジックが他セクション値を壊す | move.bats（観点 B3）で `["codex"]` → user-global に同形式で書き出される fixture を用意して検証 |
| Unit 002 の `## 9b` 案内本文が変更された場合に Unit 003 の参照が陳腐化 | Unit 002 で確立した安定 ID `unit002-user-global` で参照することで文言変更耐性を担保。本文コピー禁止を境界表に明記済み |
| 既存ステップ番号繰り下げ（## 4→## 5、## 5→## 6）でドキュメント内相互参照が壊れる | step-integration.bats で繰り下げ後の番号を含む既存セクション存在を回帰検証ケースで担保。`02-execute.md` 内に「## 4」「## 5」を直接参照する文字列が他にないことを grep で実装時確認 |

## 関連 Issue

- #592（部分対応: 実装スコープ 4 を担当）

## 見積もり

0.7 セッション（dry-run 込み + テストケース充実 + 既存ステップ番号繰り下げ込み）
