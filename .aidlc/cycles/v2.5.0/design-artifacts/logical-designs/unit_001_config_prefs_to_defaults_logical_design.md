# 論理設計: Unit 001 個人好みキーの defaults.toml 集約

## 概要

`config.toml.template` から個人好み 7 キーを除去し、`defaults.toml`（既に値あり）を 4 階層マージの最低優先層として機能させる。新規プロダクションコードは追加せず、既存の 4 階層マージ機構（`read-config.sh` / `bootstrap.sh`）を変更しない。新規テスト 2 ファイルと CI 接続のみが追加成果物。

**Unit 001 のスコープ（明示）**:

| 項目 | スコープ内／外 |
|------|---------------|
| `skills/aidlc-setup/templates/config.toml.template` の編集 | **スコープ内**（主目的） |
| `skills/aidlc/config/config.toml.example` の編集 | **スコープ内**（理由: template との整合維持。所有 Unit を Unit 001 に確定済み — 計画 §「Unit 002 / 003 との境界」表参照） |
| `tests/config-defaults/*.bats` 新規作成 | **スコープ内** |
| `tests/fixtures/config-defaults/` 新規作成 | **スコープ内** |
| `.github/workflows/migration-tests.yml` 拡張 | **スコープ内** |
| `skills/aidlc/config/defaults.toml`（正本）の編集 | **スコープ外**（既に 7 キー収録済み、編集なし） |
| `skills/aidlc-setup/config/defaults.toml`（同期コピー）の編集 | **スコープ外**（同期確認のみ。`bin/check-defaults-sync.sh` で監視） |
| `skills/aidlc/scripts/read-config.sh` / `lib/bootstrap.sh` | **スコープ外**（既存マージロジック維持） |
| `aidlc-setup` ウィザード UI 文言追加 | **スコープ外**（Unit 002 の責務） |
| `aidlc-migrate` 移動提案ロジック | **スコープ外**（Unit 003 の責務） |

「template 差分中心」という表現は主目的を指し、附随的な整合維持変更（example / fixture / bats / CI）も Unit 001 のスコープ内である。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的なコード（bash スクリプト本体、bats アサーション、TOML 内容、YAML 差分）は Phase 2（コード生成）で作成する。

## アーキテクチャパターン

**既存パターンの維持** — Layered Configuration（4 階層設定）パターン。defaults → user-global → project_shared → project_local の優先度で `dasel` ベースの読取マージを行う。本 Unit はパターン自体を変更せず、各層の責務分離を明確化する成果物差分（template 削除）と検証層（bats テスト + CI ジョブ拡張）を追加する。

**選定理由**: 既存実装が `dasel` v3 + bash スクリプトで安定稼働しており、変更コストとリスクが最小。Unit 001 のスコープは「責務分離の明示化」であり、新パターン導入は不要。

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc-setup/templates/
└── config.toml.template          [変更]  個人好み 7 キーを除去

skills/aidlc/config/
├── defaults.toml                 [不変]  既に 7 キー全て収録済み（正本）
└── config.toml.example           [変更]  template と整合（実値・コメント例とも削除）

skills/aidlc-setup/config/
└── defaults.toml                 [不変]  正本の同期コピー（bin/check-defaults-sync.sh で監視）

skills/aidlc/scripts/
├── read-config.sh                [不変]  4 階層マージの読取エントリポイント
└── lib/bootstrap.sh              [不変]  AIDLC_PROJECT_ROOT 等の解決

tests/
├── fixtures/
│   └── config-defaults/          [新規]  Unit 001 用 fixture ディレクトリ
│       ├── b1-no-keys/           [新規]  観点 B1 用: 7 キー無い project config
│       │   └── .aidlc/config.toml
│       └── b2-with-keys/         [新規]  観点 B2 用: 7 キー有り project config
│           └── .aidlc/config.toml
└── config-defaults/              [新規]  Unit 001 用 bats テストディレクトリ
    ├── template-removed-keys.bats   [新規]  観点 A
    └── defaults-resolution.bats     [新規]  観点 B1 + B2

.github/workflows/
└── migration-tests.yml           [変更]  PATHS_REGEX と実行コマンド拡張

bin/
└── check-defaults-sync.sh        [不変]  正本／コピー sync 監視（既存）
```

### コンポーネント詳細

#### `config.toml.template`（変更対象）

- **責務**: `aidlc-setup` 実行時に project 共有層 `.aidlc/config.toml` を初期生成する雛形
- **依存**: `aidlc-setup` ウィザードのプレースホルダ展開ロジック
- **公開インターフェース**: ファイル内容（TOML テキスト）。プレースホルダ `[現在日時]` / `[version.txt の内容]` / `[プロジェクト名]` / `[言語リスト]` 等
- **本 Unit の変更**: `[rules.git]` / `[rules.reviewing]` / `[rules.linting]` / `[rules.automation]` セクションから個人好み 7 キーを除去。`[rules.linting]` / `[rules.automation]` は対象キー全削除のためセクション全体を除去。`[rules.git]` / `[rules.reviewing]` はプロジェクト強制キーが残るためセクションヘッダ保持

#### `defaults.toml`（正本 / 不変）

- **責務**: 4 階層マージの最低優先層。AI-DLC スターターキット同梱の既定値を提供
- **依存**: `read-config.sh` / `bootstrap.sh`
- **公開インターフェース**: ファイル内容（TOML）。`read-config.sh` 経由で読まれる
- **本 Unit の取り扱い**: 編集なし（既に 7 キー全て収録済み）

#### `config.toml.example`（変更対象）

- **責務**: project 共有層の「リファレンス例」。ドキュメント補助として使われる
- **依存**: `aidlc-setup` ウィザードからは参照されない（template とは独立）
- **公開インターフェース**: ファイル内容（TOML）
- **本 Unit の変更**: template と同じ単純除去ルールを適用。実値もコメント例も残さない。「user-global 推奨」案内文言は Unit 002（`aidlc-setup` ウィザード）に単一ソース化することで example の二重保守を排除

#### `tests/fixtures/config-defaults/`（新規）

- **責務**: 観点 B1 / B2 で `read-config.sh` の入力となる project 共有層 fixture ファイルを保持
- **依存**: なし
- **公開インターフェース**: ディレクトリ構造とファイル内容
- **構造**:
  - `b1-no-keys/.aidlc/config.toml` — 7 キーを含まない最小プロジェクト設定（必須項目 `[project] name` / `type` のみ）
  - `b2-with-keys/.aidlc/config.toml` — 7 キーを含むプロジェクト設定。値は defaults.toml と区別可能な「異なる値」を設定（例: `mode = "required"` / `tools = ["claude"]` 等）

#### `tests/config-defaults/template-removed-keys.bats`（新規）

- **責務**: 観点 A — `config.toml.template` に対象 7 キーが存在しないことを検証
- **依存**: `dasel` v3+
- **公開インターフェース**: bats テスト関数（`@test "..."` ブロック群）
- **検証方式**: `dasel -r toml -f <template_path> '<dotted_path>'` の終了コードが非 0（キー不在）であることをアサート。7 キーそれぞれを独立したテストケースとして記述

#### `tests/config-defaults/defaults-resolution.bats`（新規）

- **責務**: 観点 B1 + B2 — 4 階層マージの優先度規則（後方互換 NFR）と既定値同等性 NFR を検証
- **依存**: `dasel` v3+ / `read-config.sh` / `bash`
- **公開インターフェース**: bats テスト関数
- **検証方式**:
  - **B1 ケース群**: `b1-no-keys` fixture を `AIDLC_PROJECT_ROOT` に切り替え、`read-config.sh --keys <7キー>` の各出力が **テスト定数として固定した期待値**（user_stories.md ストーリー 1 由来の正規値）と一致することをアサート
  - **B2 ケース群**: `b2-with-keys` fixture を `AIDLC_PROJECT_ROOT` に切り替え、`read-config.sh --keys <7キー>` の各出力が project 値（fixture の値）と一致することをアサート

**B1 のテスト定数表**（既定値同等性 NFR の Source of Truth）:

| dotted_path | 期待値（template 旧値 = defaults 現値 = テスト固定値） |
|-------------|------------------------------------------------|
| `rules.reviewing.mode` | `recommend` |
| `rules.reviewing.tools` | `["codex"]` |
| `rules.automation.mode` | `manual` |
| `rules.git.squash_enabled` | `false` |
| `rules.git.ai_author` | `""`（空文字列） |
| `rules.git.ai_author_auto_detect` | `true` |
| `rules.linting.enabled` | `false` |

この表は bats テスト内で**ハードコードされた期待値定数**として扱う。`defaults.toml` 側の値が将来意図せず変更されると、テストが期待値と一致せず失敗するため、既定値同等性 NFR の崩壊を直接検知できる。`defaults.toml` を意図的に変更する際は、本表とテストコードを同時に更新するレビューポイントを設ける（変更の二重承認）。

#### `.github/workflows/migration-tests.yml`（変更対象）

- **責務**: PR 上で bats テストを CI 実行する
- **依存**: GitHub Actions / bats-core@1.11.1 / `gh api`
- **公開インターフェース**: `on: pull_request` トリガーと `jobs.migration-tests`
- **本 Unit の変更**:
  - `PATHS_REGEX` を拡張: 既存 `tests/migration/.+` に加え `tests/config-defaults/.+` / `tests/fixtures/config-defaults/.+` / `skills/aidlc-setup/templates/config\.toml\.template` / `skills/aidlc/config/defaults\.toml` / `skills/aidlc-setup/config/defaults\.toml` を追加
  - 実行コマンドを `bats tests/migration/` → `bats tests/migration/ tests/config-defaults/` に変更
  - ジョブ表示名は既存維持（「Migration Script Tests」）。意味的な乖離はあるが本 Unit のスコープ外（リネームは別 PR で扱う方が CI 履歴の連続性として安全）

## インターフェース設計

### スクリプトインターフェース設計

本 Unit では新規スクリプトを追加しない。既存スクリプト（`read-config.sh` / `check-defaults-sync.sh`）の I/F も変更しない。テストから利用するインターフェースのみここに記載する。

#### `read-config.sh --keys <key1> [key2] ...`（既存 / 不変 / テストから利用）

- **概要**: 複数キーを一括で 4 階層マージ後の値として解決する
- **本 Unit のテストでの利用**: 観点 B1 / B2 で fixture を `AIDLC_PROJECT_ROOT` に切り替えて呼び出し、出力を期待値と比較
- **入力環境変数**: `AIDLC_PROJECT_ROOT`（`bootstrap.sh` で解決される。テストでは fixture ディレクトリに切り替える）
- **出力**: 1 行 1 キーの `key:value` 形式（stdout）
- **終了コード**: 0=値あり / 1=キー不在 / 2=エラー

#### `dasel -r toml -f <path> <dotted_path>`（既存 / 不変 / テストから利用）

- **本 Unit のテストでの利用**: 観点 A で template ファイルを読み、対象キーの dotted_path で `select` し、終了コード非 0（キー不在）をアサート

#### `bin/check-defaults-sync.sh`（既存 / 不変 / 実装ステップで利用）

- **概要**: `skills/aidlc/config/defaults.toml`（正本）と `skills/aidlc-setup/config/defaults.toml`（コピー）の TOML 設定値部分が一致することを検証
- **本 Unit の利用**: 実装ステップ 3 で実行し、回帰がないことを確認
- **終了コード**: 0=一致 / 1=不一致 / 2=ファイル不在

### bats テスト関数命名規則

既存 `tests/migration/*.bats` の慣行に倣う。`@test "<カテゴリ>: <検証内容>"` 形式。

例:
- `@test "template: rules.reviewing.mode が config.toml.template に存在しない"`
- `@test "B1: rules.reviewing.mode が project に無い時 defaults 値（recommend）が返る"`
- `@test "B2: rules.reviewing.mode が project にある時 project 値（required）が返る"`

## データモデル概要

### ファイル形式

- **形式**: TOML（既存）
- **主要セクション**:
  - `[project]`: name / type / description / tech_stack（プロジェクト強制 — 残存）
  - `[rules.git]`: commit_on_* / branch_mode / unit_branch_enabled（プロジェクト強制 — 残存） + squash_enabled / ai_author / ai_author_auto_detect（個人好み — **本 Unit で template から削除**）
  - `[rules.reviewing]`: exclude_patterns / codex_bot_account（残存可能）+ mode / tools（個人好み — **本 Unit で template から削除**）
  - `[rules.linting]`: enabled（個人好み — **本 Unit でセクションごと template から削除**）
  - `[rules.automation]`: mode（個人好み — **本 Unit でセクションごと template から削除**）

### fixture ファイル構造

- **`b1-no-keys/.aidlc/config.toml`**:
  - 必須セクションのみ: `[project]` name / type、`[rules.coding]` naming_convention 等
  - 7 キーを意図的に含まない
- **`b2-with-keys/.aidlc/config.toml`**:
  - `b1-no-keys` の内容に加え、7 キー全てを **defaults と異なる値** で記述
  - 期待値: `read-config.sh` がこれら project 値を defaults より優先して返すこと

## 処理フロー概要

### ユースケース 1: `aidlc-setup` 実行時の project 共有 config 生成（本 Unit 完了後の挙動）

**ステップ**:
1. ユーザーが `aidlc-setup` を起動
2. ウィザードがプレースホルダを収集（プロジェクト名等）
3. `TemplateGenerationService` が `config.toml.template` を読み込む
4. プレースホルダを展開して project 共有層 `.aidlc/config.toml` を生成
5. **本 Unit 完了後**: 生成された `.aidlc/config.toml` には 7 キーが含まれない（template 側で除去済み）
6. ユーザーが `read-config.sh --keys rules.reviewing.mode` 等を実行 → defaults.toml の値（`recommend`）が返る

**関与するコンポーネント**: `aidlc-setup` ウィザード / `config.toml.template` / `read-config.sh` / `defaults.toml`

### ユースケース 2: 既存プロジェクト（v2.4.x 以前で setup 済み）での後方互換動作

**ステップ**:
1. 既存プロジェクトの `.aidlc/config.toml` には 7 キーが残存している
2. `read-config.sh --keys rules.reviewing.mode` が呼ばれる
3. `bootstrap.sh` が 4 階層をロード
4. `ConfigMergeService` が project_shared 層の値を defaults より優先して返す
5. **後方互換**: 既存挙動が維持される（破壊的変更なし）。Unit 003（`aidlc-migrate`）で「user-global 推奨に移動するか」を後日提案する

**関与するコンポーネント**: `read-config.sh` / `bootstrap.sh` / 4 階層 fixture（テストでは fixture を使用）

### ユースケース 3: 観点 A テストの実行フロー

**ステップ**:
1. CI（`migration-tests.yml`）または開発者ローカルで `bats tests/config-defaults/template-removed-keys.bats` が起動
2. 各 `@test` ケース内で `dasel -r toml -f skills/aidlc-setup/templates/config.toml.template '<dotted_path>'` を実行
3. 終了コード非 0（キー不在）であることを `[ "$status" -ne 0 ]` でアサート
4. 7 キー全てで成功なら bats テスト全体がパス

**関与するコンポーネント**: bats / dasel / `config.toml.template`

### ユースケース 4: 観点 B1 / B2 テストの実行フロー

**ステップ**:
1. `setup()` ヘルパで一時ディレクトリ作成 + fixture を `cp -r tests/fixtures/config-defaults/<case>/ $TMPDIR/`
2. `AIDLC_PROJECT_ROOT=$TMPDIR/<case>` を export
3. `read-config.sh --keys <7キー>` を実行
4. 出力（key:value 形式）をパースして**ハードコードされたテスト定数（B1 期待値表参照）**と一致することをアサート（B1）/ fixture 値と一致することをアサート（B2）
5. `teardown()` で一時ディレクトリを削除

**関与するコンポーネント**: bats / read-config.sh / bootstrap.sh / fixture

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: bats 実行時間が大きく増えないこと（既存 `tests/migration/` は数秒オーダーで完了）
- **対応策**: 観点 A は `dasel` 単体呼び出しのみ、観点 B は `read-config.sh` 単体呼び出しのみ。サブプロセス起動 1 ケースあたり 1〜2 回のため新規追加のオーバーヘッドは数百 ms 程度

### セキュリティ

- **要件**: fixture に機密情報を含めない
- **対応策**: 7 キーは選好設定であり機密情報ではない。`ai_author` 値もテスト用ダミー（`"test@example.com"` 等）を使う。`.env` / `*.key` 等のレビュー除外パターンには該当しない

### スケーラビリティ

- **要件**: なし（local CI 実行のみ）

### 可用性

- **要件**: `bin/check-defaults-sync.sh` 失敗時に CI が確実にブロックされること
- **対応策**: 既存 `pr-check.yml` の `defaults-sync-check` ジョブが既に機能。本 Unit の変更で新規不整合は発生しない見込みだが、ローカルステップ 3 で明示的に再実行することで早期検知

### 後方互換（本 Unit 固有 NFR）

- **要件**: 既存プロジェクトの project_shared 層に 7 キーが残っていても 4 階層マージで読み取れる
- **対応策**: 観点 B2 テストで直接検証（fixture `b2-with-keys` で project 値が defaults を上書きすることをアサート）

### 既定値同等性（本 Unit 固有 NFR）

- **要件**: defaults.toml の 7 キー値が template 旧値と完全一致
- **対応策**: 計画ファイルの「対象キー（user_stories.md ストーリー 1 の正規定義）」表で確認済み（全 7 キー一致）。観点 B1 テストで defaults 値の動作を確認

### 冪等性（本 Unit 固有 NFR）

- **要件**: `aidlc-setup` 再実行で 7 キーが復活しない
- **対応策**: template 側で除去済みのため、再実行しても展開結果に含まれない（観点 A テストで間接的に保証）

## 技術選定

- **テストフレームワーク**: bats-core 1.11.1（既存 `migration-tests.yml` で利用、CI 経由でインストール済み）
- **TOML パーサー**: dasel v3（既存依存、`read-config.sh` / `bootstrap.sh` で利用中）
- **シェル**: bash（POSIX 互換は不要、`#!/usr/bin/env bash` を既存慣行に従う）
- **CI**: GitHub Actions（既存 `migration-tests.yml` の拡張のみ）

## 実装上の注意事項

- **コマンド置換禁止ルール**: `.aidlc/rules.md` および CLAUDE.md の規定により Bash コードブロック内の `$(...)` / バッククォート禁止。bats テスト内でも遵守する。値取得は環境変数化＋ファイル経由のリダイレクトを使う（既存 `tests/migration/*.bats` の慣行に倣う）
- **fixture の絶対パス回避**: bats テストは `BATS_TEST_DIRNAME` を使って相対参照する（既存慣行）
- **AIDLC_PROJECT_ROOT 切替**: `bootstrap.sh` の解決ロジックを尊重し、`export` で切替後に `read-config.sh` を呼ぶ。テスト後は `unset` で漏出を防ぐ
- **既存 `tests/migration/` のヘルパ流用**: `tests/migration/helpers/setup.bash`（あれば）を参照し、共通化できるパターンは流用。完全独立で書く必要はない
- **`migration-tests.yml` 変更時の skip ロジック確認**: `gh api` 呼び出し依存のため、ローカルで regex 単体だけ確認してから push する（CI で skip 誤動作が発生してもブロッカーにならないよう、別 commit で隔離）

## 不明点と質問

[Question] `tests/migration/` 配下に共通 `helpers/` ディレクトリは存在するか
[Answer] 存在する（`tests/migration/migrate-detect.bats:3` で `load helpers/setup` が呼ばれている）。本 Unit の bats でも同様のヘルパを参照するか、`tests/config-defaults/helpers/setup.bash` を独自に作る。実装時に既存ヘルパの内容を確認の上、流用できる箇所は流用する

[Question] `AIDLC_PROJECT_ROOT` 切替は `bootstrap.sh` で確実に効くか
[Answer] 既存実装で対応済み。`bootstrap.sh` は `AIDLC_PROJECT_ROOT` が設定されていればそれを使用し、未設定時は `git rev-parse --show-toplevel` 等で自動解決する。テストでは export して使う

[Question] `migration-tests.yml` のジョブ表示名は本 Unit でリネームすべきか
[Answer] リネームしない（既存維持）。CI 履歴の連続性を優先。`name: Migration Tests` のままでも `Bash Tests` 系の bats を走らせる運用は技術的に問題ない。意味的な乖離は許容範囲内であり、リネーム自体は別 PR / 別サイクルで扱う方が安全
