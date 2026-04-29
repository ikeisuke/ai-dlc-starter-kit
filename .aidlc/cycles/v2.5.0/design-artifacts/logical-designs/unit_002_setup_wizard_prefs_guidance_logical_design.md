# 論理設計: Unit 002 aidlc-setup ウィザードの個人好み推奨案内

## 概要

`aidlc-setup` のステップファイル（`skills/aidlc-setup/steps/03-migrate.md`）に「個人好みは `~/.aidlc/config.toml`（user-global）推奨」の案内セクション `## 9b` を追加し、新規セットアップ時に LLM が解釈実行する案内出力の振る舞いを定義する。本 Unit はプロダクションコードを追加せず（aidlc-setup は markdown-driven）、ステップファイル差分とそれを検証する bats 静的検証テスト + CI 接続のみを成果物とする。

**Unit 002 のスコープ（明示）**:

| 項目 | スコープ内／外 |
|------|---------------|
| `skills/aidlc-setup/steps/03-migrate.md` への `## 9b` セクション追加 | **スコープ内**（主目的） |
| `tests/aidlc-setup/setup-prefs-guidance.bats` 新規作成 | **スコープ内** |
| `tests/aidlc-setup/helpers/setup.bash` 新規作成 | **スコープ内** |
| `.github/workflows/migration-tests.yml` 拡張（PATHS_REGEX + 実行コマンド） | **スコープ内** |
| Unit 002 定義（`story-artifacts/units/002-...md`）の実装状態更新 | **スコープ内** |
| `skills/aidlc-setup/steps/01-detect.md` / `02-generate-config.md` の編集 | **スコープ外**（単一ソース原則：`03-migrate.md` のみに案内を持つ。重複が無いことを観点 D3 で検証） |
| `--non-interactive` フラグの実装（CLI フラグ受理） | **スコープ外**（aidlc-setup は markdown-driven skill のため CLI 実体が無い。フォワード互換参考記述のみ） |
| `skills/aidlc/config/defaults.toml` / `template` の編集 | **スコープ外**（Unit 001 で完了） |
| `aidlc-migrate` 移動提案ロジック | **スコープ外**（Unit 003 の責務） |
| Unit 003 で本案内を再表示する場合の参照方法 | Unit 003 のスコープ。本 Unit は「実装ソース（`03-migrate.md` 内の **stable_id** `unit002-user-global`）を単一ソース」とする境界宣言のみ。stable_id は markdown に HTML コメントアンカー（`<!-- guidance:id=unit002-user-global -->`）として埋め込まれ、見出し文言の変更にも耐える |

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的な markdown 本文・bats アサーション・YAML 差分は Phase 2（コード生成）で作成する。

## アーキテクチャパターン

**Markdown-Driven Instruction Pattern**（既存 aidlc-setup スキルが採用）— LLM がステップファイル markdown を順次読み込み、記述された指示文に従って対話・出力・コマンド実行を行う。本 Unit は新セクション `## 9b` を追加することで、初回セットアップ完了直前に表示する案内テキストを LLM の振る舞いとして指示する。

**選定理由**: aidlc-setup は既に markdown-driven であり、CLI スクリプト化や別エンジン導入はコスト過大。本 Unit の目的（案内テキスト 1 個の追加）に対して既存パターンが最適解。検証は bats 静的解析で「指示文の存在」を保証する形態とし、LLM の動的実行テストは別 Unit / 別サイクルへ委譲する。

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc-setup/steps/
├── 01-detect.md                     [変更なし]  案内重複が無いことを観点 D3 で検証
├── 02-generate-config.md            [変更なし]  同上
└── 03-migrate.md                    [変更]      ## 9b セクションを ## 9 と ## 10 の間に追加

tests/aidlc-setup/
├── helpers/
│   └── setup.bash                   [新規]      bats 共通ヘルパ（assert_section_between / extract_section_body / 等）
└── setup-prefs-guidance.bats        [新規]      観点 A / B / C / D の静的検証

.github/workflows/
└── migration-tests.yml              [変更]      PATHS_REGEX 拡張 + 実行コマンドへ tests/aidlc-setup/ 追加

.aidlc/cycles/v2.5.0/
├── plans/
│   └── unit-002-plan.md             [既存]      本 Unit の計画
├── design-artifacts/
│   ├── domain-models/
│   │   └── unit_002_..._domain_model.md       [新規 / 本ファイルと並行作成]
│   └── logical-designs/
│       └── unit_002_..._logical_design.md     [新規 / 本ファイル]
├── construction/units/
│   ├── 002-implementation.md        [新規 / Phase 2 末で作成]
│   └── 002-review-summary.md        [新規 / Phase 2 で逐次追記]
└── story-artifacts/units/
    └── 002-setup-wizard-prefs-guidance.md     [変更]  実装状態を「完了」に更新
```

### コンポーネント間の依存関係

```text
[03-migrate.md ## 9b]
        ↑ 静的検証
[setup-prefs-guidance.bats]
        ↑ 共通ヘルパ
[helpers/setup.bash]
        ↑ CI 実行
[migration-tests.yml]

[03-migrate.md ## 9b] (実装ソース、Unit 003 から参照される単一ソース)
        ←─── Unit 003 (将来 / 参照のみ・本文コピー禁止)
```

**依存方向の不変条件**:

- `setup-prefs-guidance.bats` → `helpers/setup.bash` の単方向（テストファイルがヘルパに依存）
- `migration-tests.yml` → `tests/aidlc-setup/` の検出依存（PATHS_REGEX）
- 循環依存なし
- aidlc-setup ステップファイル相互は依存しない（`01` → `02` → `03` の実行順序は SKILL.md が規定するもので、内容上の参照依存は無い）

## インターフェース定義

### コンポーネント A: `## 9b` セクション（案内テキスト指示）

**配置**: `skills/aidlc-setup/steps/03-migrate.md` の `## 9. Git コミット` 直後、`## 10. 完了メッセージと次のステップ` 直前

**安定 ID**: セクション直前に HTML コメントアンカー `<!-- guidance:id=unit002-user-global -->` を配置する。Unit 003 など外部からの参照キーは見出し文言ではなく本 ID を使用する（文言変更耐性）

**論理構造**（GuidanceMessage の ElementKind と各要素が満たすべき**意味要件**を、観点 A〜D の静的検証で使う具体トークンに展開した対応表）:

| 順序 | ElementKind | 意味要件（ドメインモデル由来） | 静的検証トークン（テスト設計層） |
|------|------------|--------------------------------|-----------------------------|
| 1 | Title | 見出しが GuidanceMessage の役割を表現する | `## 9b. 個人好み user-global 推奨案内`（A1） |
| 2 | LayerHierarchyOverview | 4 階層マージ仕様の概念を伝達する | `defaults` / `user-global` / `project` / `project.local` の 4 階層名（明文化推奨） |
| 3 | KeyExamples | Unit 001 正規 7 キーから代表 3 キーを言及する | `rules.reviewing.mode` / `rules.automation.mode` / `rules.linting.enabled`（B1〜B3） |
| 4 | UserGlobalCodeSnippet | `~/.aidlc/config.toml` への記述例を提示する | `~/.aidlc/config.toml`（A3）+ TOML コード例 |
| 5 | TeamImpactNote | project 共有がチーム全体に反映される旨を注意喚起する | 「project 共有」/ 「チーム」のいずれかを含む（明文化推奨） |
| 6 | ModeApplicabilityNote | 初回セットアップ経路かつ automation_mode 全モードで表示される旨を明示する | `初回セットアップ`（D2 / C3 共通）+ `automation_mode` + `manual` / `semi_auto` / `full_auto`（C3） |
| 7 | StderrRoutingNote | 非対話モード時の stderr ルーティング指示を含む / フォワード互換として `--non-interactive` に言及する | `--non-interactive`（C1）+ `stderr` または `>&2`（C2） |
| 8 | IdempotencyNote | 1 回のみ表示する旨の冪等性指示を含む | 「1 回」を含む（明文化推奨） |

**実行条件指示文**:

- 「**初回セットアップの場合のみ**実行する。アップグレード／移行モードでは表示しない」
- 「**初回セットアップ経路では `automation_mode` が `manual` / `semi_auto` / `full_auto` のいずれでも本セクションをスキップせず、案内を 1 回表示する**」
- 「AI エージェントが echo / printf 等で案内を出力する場合は `>&2`（stderr）にリダイレクトする。将来 `--non-interactive` フラグが導入された場合も同様」

**出力先**:

- 対話モード（既定）: ユーザー向けコンソール出力（LLM の標準応答）
- 非対話モード（automation_mode = `semi_auto` / `full_auto`、フォワード互換: `--non-interactive`）: stderr リダイレクト

**冪等性**:

- 本セクションは `03-migrate.md` 内で 1 回のみ定義される
- `01-detect.md` / `02-generate-config.md` には同等の案内を持たない（観点 D3）

### コンポーネント B: `helpers/setup.bash`（共通ヘルパ）

**責務**: bats テストから呼び出される静的解析ヘルパ群の提供。**定数/環境変数**と**関数 API** で契約形式を分離する。

**定数 / 環境変数**（`readonly` 前提、bats `setup_file` で初期化）:

| 名前 | 型 | 値 | 用途 |
|------|---|----|------|
| `STEP_FILE_PATH` | string（path） | `<repo_root>/skills/aidlc-setup/steps/03-migrate.md` の絶対パス | 検査対象ステップファイル |
| `OTHER_STEP_FILES` | array of string（paths） | `[<repo_root>/skills/aidlc-setup/steps/01-detect.md, <repo_root>/skills/aidlc-setup/steps/02-generate-config.md]` | 重複検査対象（観点 D3） |

**関数 API**:

| 関数名 | 引数 | 戻り値 | 失敗時 exit code | 用途 |
|--------|------|-------|------------------|------|
| `assert_section_exists` | `section_anchor`: string（例: `"## 9b."`） | （なし） | 1（不在）/ 2（STEP_FILE 不存在） | 指定見出しの存在確認 |
| `assert_section_count` | `pattern`: string, `expected`: int | （なし） | 1（不一致）/ 2（STEP_FILE 不存在） | パターン出現数検証（観点 D1） |
| `assert_section_between` | `after_id`, `target_id`, `before_id`: string（例: `"9"`, `"9b"`, `"10"`） | （なし） | 1（順序違反）/ 2（いずれかが不在） | 行番号順序 `line_after < line_target < line_before` を検証（観点 A2） |
| `extract_section_body` | `section_anchor`: string | stdout: 本文文字列 | 1（セクション不在） | awk で `##` プレフィックス区切りに従い本文を抽出 |
| `assert_body_contains_token` | `section_anchor`, `token`: string | （なし） | 1（未含有）/ 2（セクション不在） | 本文の `grep -F` 含有確認 |
| `assert_body_contains_any` | `section_anchor`, `token1`, `token2`, ... | （なし） | 1（全未含有）/ 2（セクション不在） | いずれか 1 トークンが含まれるか（観点 C2 の 2 段判定方式に対応） |
| `assert_other_files_no_token` | `token`: string | （なし） | 1（重複検出）/ 2（OTHER_STEP_FILES 内のいずれかが不在） | OTHER_STEP_FILES に token が含まれないか（観点 D3） |

**実装方針**:

- `awk` ベースで `##` プレフィックス付き見出しを区切り判定し、抽出範囲を限定
- `grep -F` を基本とし、エスケープを伴う正規表現は使わない（観点 C2 の OR 判定は `assert_body_contains_any` で 2 段実行）
- 一時ディレクトリ・fixture は不要（静的検証のみ）

### コンポーネント C: `setup-prefs-guidance.bats`（観点別検証）

**責務**: 4 観点（A / B / C / D）に従い、`## 9b` セクションの構造・本文・指示・冪等性を静的検証する

**テストケース構成**（最小 13 ケース、unit-002-plan.md 完了条件と整合）:

| 観点 | ケース数 | 検証内容 |
|------|---------|---------|
| A1〜A3 | 3 | セクション存在 / 位置制約（after `## 9.` / before `## 10.`）/ `~/.aidlc/config.toml` 含有 |
| B1〜B3 | 3 | 代表 3 キー（`rules.reviewing.mode` / `rules.automation.mode` / `rules.linting.enabled`）含有 |
| C1〜C3 | 3 | `--non-interactive` 含有 / `stderr` または `>&2` 含有 / `automation_mode` 全モード（`manual` / `semi_auto` / `full_auto`）含有 |
| D1〜D3 | 3 | `## 9b` 見出しの出現数 = 1 / 「初回セットアップ」スコープ限定指示 / `01-detect.md` / `02-generate-config.md` への重複なし |
| 回帰 | 1 | `## 9.` / `## 10.` セクションの存在を保証（既存セクション破壊検出） |

**実行コマンド**: `bats tests/aidlc-setup/`

### コンポーネント D: `migration-tests.yml`（CI 接続）

**変更内容**:

- **PATHS_REGEX 拡張**: 既存パターンに `tests/aidlc-setup/.+` および `skills/aidlc-setup/steps/.+` を追加
- **実行コマンド**: `bats tests/migration/ tests/config-defaults/` → `bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/`
- **新規ジョブは作らない**（Unit 001 と同じ最小拡張方針）

**境界条件**:

- 既存の `tests/migration/` および `tests/config-defaults/` の実行は維持
- ジョブ表示名「Migration Script Tests」は本 Unit でもリネームしない（履歴連続性優先 / Unit 001 から残された継続課題）

## 検証戦略（4 観点詳細）

### 観点 A: セクション存在 + 構造

| # | 検査内容 | 検証方法 |
|---|---------|---------|
| A1 | `## 9b. 個人好み user-global 推奨案内` ヘッダが `03-migrate.md` に **1 回のみ** 存在 | `grep -c '^## 9b\.' STEP_FILE_PATH` が `1` |
| A2 | `## 9. Git コミット` < `## 9b. ...` < `## 10. 完了メッセージ` の行番号順序 | `assert_section_between "9" "9b" "10"` ヘルパ。`grep -n` で各行番号を抽出し比較 |
| A3 | `## 9b` 本文に `~/.aidlc/config.toml` を含む | `extract_section_body "## 9b"` の結果に `grep -F '~/.aidlc/config.toml'` |

### 観点 B: 代表 3 キーの例示

| # | 検査内容 | 検証方法 |
|---|---------|---------|
| B1 | `## 9b` 本文に `rules.reviewing.mode` を含む | `assert_body_contains_token "## 9b" "rules.reviewing.mode"` |
| B2 | `## 9b` 本文に `rules.automation.mode` を含む | 同様 |
| B3 | `## 9b` 本文に `rules.linting.enabled` を含む | 同様 |

### 観点 C: 非対話モード対応指示（AC「`--non-interactive` でもログ記録」の実動作保証）

| # | 検査内容 | 検証方法 |
|---|---------|---------|
| C1 | `## 9b` 本文に `--non-interactive` を含む | `assert_body_contains_token "## 9b" "--non-interactive"` |
| C2 | `## 9b` 本文に `stderr` または `>&2` を含む | `assert_body_contains_any "## 9b" ">&2" "stderr"` の 2 段判定方式 |
| C3 | `## 9b` 本文に **「初回セットアップ」スコープ条件** + `automation_mode` 全モード（`manual` / `semi_auto` / `full_auto`）を含む | `初回セットアップ` + `automation_mode` + 3 モード文字列の計 5 トークンを順次 `assert_body_contains_token`（C3 と D2 を整合的に保つため `初回セットアップ` を共通必須トークンに含める） |

### 観点 D: 冪等性とスコープ限定

| # | 検査内容 | 検証方法 |
|---|---------|---------|
| D1 | `## 9b` 見出しの出現数が STEP_FILE 内で 1 | `assert_section_count '^## 9b\.' 1` |
| D2 | `## 9b` 本文に **`初回セットアップ`** の文字列を固定で含む（C3 と整合） | `assert_body_contains_token "## 9b" "初回セットアップ"` |
| D3 | `01-detect.md` / `02-generate-config.md` には `~/.aidlc/config.toml` 推奨案内のキー文字列が含まれない（重複なし） | `assert_other_files_no_token "rules.reviewing.mode"`（または `~/.aidlc/config.toml` 等） |

## エラーハンドリング

本 Unit は markdown 静的検証のため、ランタイムエラーは発生しない。bats テスト失敗時の挙動は標準的な bats 出力（TAP 形式）に従う:

- 失敗時: `not ok N` が出力され、exit code 非 0 で CI が失敗
- ヘルパ関数内のエラー: `>&2` で診断メッセージを出力し非 0 終了

## NFR チェック

| NFR | 検証手段 |
|-----|---------|
| 冪等性（同一セッション 1 回表示） | 観点 D1（出現数 = 1） + IdempotencyNote 要素の存在（意味要件「1 回のみ表示する旨」を観点 A〜D の具体トークン検証で確認） |
| テスト互換（既存テスト回帰なし） | `bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/` で 70+ 件 → 80+ 件想定。既存件数の維持を確認 |
| 設計意図の伝達（チーム汚染回避の理由提示） | LayerHierarchyOverview + TeamImpactNote 要素が本文に存在することを観点 A〜D の組み合わせで実質保証 |

## 実装計画への接続

論理設計レベルでは以下が決定済み:

- markdown 内 ElementKind の `semantic_requirements` を観点 A〜D の検証対象トークンに展開した対応表（コンポーネント A の論理構造表）
- bats ヘルパ関数のインターフェース（引数・戻り値・用途）
- CI 接続の最小拡張内容（PATHS_REGEX 追加 + 実行コマンド延長）

Phase 2（コード生成）では:

- `## 9b` セクション本文の具体的 markdown 表現（タイトル / 説明文 / コード例 / 注記）
- `helpers/setup.bash` の bash 関数実装
- `setup-prefs-guidance.bats` の bats アサーション実装
- `migration-tests.yml` の YAML 差分

を順次作成する。
