# ドメインモデル: Unit 002 Construction Unit 完了時 CI 構造チェック強化

## 概要

BATS テストの cwd 依存パターンを静的解析で検出するドメイン語彙と関係を整理する。本 Unit は Bash スクリプト + GitHub Actions workflow 改修で、構造化されたドメインを持たないが、検査器の論理を明示するために以下のエンティティで形式化する。

**重要**: コードは書かず、構造と責務の定義のみを行う。

## エンティティ（Entity）

### BatsFile

- **ID**: repo-relative path（例: `tests/foo.bats`）
- **属性**:
  - `path`: RepoPath - ファイルパス
  - `functions`: List<BatsFunction> - 含まれる関数（teardown / teardown_file / setup / setup_file / @test）
  - `parse_status`: `parsed` | `parse_failed` - 構文解析の結果
- **振る舞い**:
  - `extract_functions()`: awk による関数スコープ抽出（`{` から対応する `}` まで、深度カウンタでネスト管理）
  - `is_under_test_dirs()`: 検査対象ディレクトリ（`tests/`, `bin/tests/`）配下にあるかを判定

### BatsFunction

- **ID**: `(BatsFile.path, function_kind, function_name)` の組
- **属性**:
  - `kind`: `teardown` | `teardown_file` | `setup` | `setup_file` | `@test`
  - `name`: string - 関数名（`@test` の場合はテストケース名）
  - `start_line` / `end_line`: integer - スコープ範囲
  - `body`: string - 関数本体テキスト
  - `rm_rf_calls`: List<RmRfCall> - 検出された `rm -rf` 呼び出し
  - `cd_guards`: List<CdGuard> - 関数内の `cd` ガード
- **振る舞い**:
  - `has_rm_rf()`: `rm -rf` を含むか
  - `has_safe_cd_before(rm_rf_call)`: 当該 `rm -rf` の前に安全な `cd` ガードが先行しているか
  - `is_violation()`: `rm -rf` あり かつ ガードなし
  - `has_fatal_pattern()`: 致命パターン（`$REPO_ROOT` / `.aidlc/...` / `$(pwd)` / `$HOME/...`）を含むか

### Violation

- **ID**: `(BatsFile.path, BatsFunction.name, line)` の組
- **属性**:
  - `severity`: `fatal` | `regular`
  - `check_name`: string - 検査名（`check-test-isolation`）
  - `file`: RepoPath
  - `line`: integer
  - `reason`: string - 違反内容（`legacy-cleanup-without-cd` / `fatal-rm-rf-repo-root` 等）
  - `function_name`: string
- **振る舞い**:
  - `to_stderr_line()`: `error\t{check_name}\t{file}:{line}\t{reason}` 形式に整形
  - `is_in_allowlist(allowlist)`: 3 つ組（file_path + function_name + reason）完全一致で allowlist にあるか

### AllowlistEntry

- **ID**: `(file_path, function_name, reason)` の 3 つ組
- **属性**:
  - `file_path`: RepoPath
  - `function_name`: string
  - `reason`: string - 照合キーの一部
  - `added_date`: date (`YYYY-MM-DD`)
  - `tracking_issue`: string - 後続サイクル対応 Issue (`#NNN`)
  - `expiry_date`: date - これを過ぎると CI fail
- **振る舞い**:
  - `is_expired(today)`: 期限切れ判定
  - `is_stale(repo_state)`: 対象ファイル不在 or 関数不在 or `rm -rf` を含まなくなっている → stale
  - `matches_violation(violation)`: 3 つ組完全一致で violation を allowlist 扱いとする

## 値オブジェクト（Value Object）

### RepoPath

- **属性**: `value`: string - リポジトリ相対パス
- **不変性**: 絶対パス禁止、先頭/末尾空白除去
- **等価性**: `value` 文字列完全一致

### RmRfCall

- **属性**:
  - `line`: integer - 出現行番号
  - `target`: string - `rm -rf` のターゲット（`"."` / `"foo/"` / `"$REPO_ROOT"` 等）
  - `is_fatal_target`: boolean - 致命パターンに該当するか
- **不変性**: 1 度生成したら変更しない
- **等価性**: `(line, target)` の組

### CdGuard

- **属性**:
  - `line`: integer
  - `target`: string - `cd` のターゲット（`"$BATS_TMPDIR"` / `"$BATS_TEST_TMPDIR"` 等）
  - `is_safe`: boolean - 安全な作業ディレクトリへの `cd` か
- **不変性**: 不変
- **等価性**: `(line, target)`
- **判定基準**: `target` が以下のいずれかなら `is_safe=true`
  - `"$BATS_TMPDIR"` / `"$BATS_TEST_TMPDIR"` / `"$BATS_FILE_TMPDIR"` / `"$TMP"` / `"$(mktemp -d ...)"` 相当

### CheckExitCode

- **属性**: `value`: 0 | 1 | 2
- **不変性**: 不変
- **意味**:
  - `0`: no violations
  - `1`: violation 検出（fatal / regular / allowlist 期限切れ / stale）
  - `2`: スクリプトエラー（awk 不在等）

## 集約（Aggregate）

### CheckTestIsolationAggregate

- **集約ルート**: CheckRun
- **含まれる要素**: 検査対象 BatsFile[] / 検出された Violation[] / 適用された AllowlistEntry[] / 最終 CheckExitCode
- **境界**: 1 回の `check-test-isolation.sh` 実行に対応する一貫した検査結果
- **不変条件**:
  - 致命パターン（`severity=fatal`）の violation は allowlist 対象外（必ず exit 1）
  - allowlist の期限切れ / stale は `--strict` でなくても exit 1（fail-closed）
  - parse 失敗は既定で exit 1（fail-closed）、`--allow-parse-warn` 時のみ warn
  - exit code は最大 1 件の致命または regular で 1、検出 0 件で 0、スクリプトエラーで 2

### Squash3CheckAggregate

- **集約ルート**: SquashRun
- **含まれる要素**: check-skill-references / check-bash-substitution / check-test-isolation の 3 種実行結果
- **境界**: 1 回の `squash-unit.sh` 実行に対応する 3 種チェック実行
- **不変条件**:
  - 3 種いずれかが exit 1 を返した場合、squash は中止（Unit 完了をブロック）
  - 3 種すべて pass の場合のみ squash 続行

## ドメインサービス

### BatsParser

- **責務**: BatsFile を読み込み、関数スコープを抽出してから BatsFunction[] を構築する
- **操作**:
  - `parse(file: BatsFile) -> Result<List<BatsFunction>, ParseError>` - awk で関数スコープ抽出
  - 失敗時は ParseError を返し、上位（CheckRun）が fail-closed の判定を行う

### CdGuardEvaluator

- **責務**: BatsFunction 内の `rm -rf` の前に安全な `cd` が先行しているかを判定する
- **操作**:
  - `evaluate(func: BatsFunction) -> List<Violation>` - 各 `rm -rf` について `is_in_safe_cd_scope` を判定し violation を返す

### FatalPatternDetector

- **責務**: BatsFunction 内に致命パターンの `rm -rf` があるかを検出する
- **操作**:
  - `detect(func: BatsFunction) -> List<Violation>` - 致命パターンを `severity=fatal` で抽出（CdGuardEvaluator より優先）

### AllowlistMatcher

- **責務**: Violation が AllowlistEntry にマッチするかを判定する
- **操作**:
  - `match(violation: Violation, entries: List<AllowlistEntry>) -> Option<AllowlistEntry>` - 3 つ組完全一致のみマッチ
  - **致命パターン例外**: `violation.severity == fatal` の場合、マッチがあっても allowlist 対象外として violation を残す

### AllowlistIntegrityChecker

- **責務**: AllowlistEntry の出口条件（期限切れ / stale）を判定する
- **操作**:
  - `check(entries: List<AllowlistEntry>, repo_state: RepoState) -> List<IntegrityViolation>` - 期限切れ / stale を IntegrityViolation として返す（exit 1 trigger）

## リポジトリインターフェース

### BatsRepository

- **対象集約**: BatsFile（ファイルシステム）
- **操作**:
  - `find_under(dirs: List<RepoPath>) -> List<BatsFile>` - `tests/`, `bin/tests/` 配下の `*.bats` を列挙

### AllowlistRepository

- **対象集約**: AllowlistEntry
- **操作**:
  - `load(path: RepoPath) -> List<AllowlistEntry>` - TSV 解析（コメント行 `#` でスキップ、空行スキップ、6 列タブ区切り）
  - **fail-closed 原則**: 不正フォーマット行（タブ区切り 6 列を満たさない / `added_date` / `expiry_date` の日付パース不能 等）は **即 exit 1** とする。1 行でも不正なら全体を fail させ「部分スキップによる違反隠蔽」を防止する。ファイル全体が parse 不能（読み込み失敗）の場合は exit 2

## ファクトリ

### CheckRunFactory

- **生成対象**: CheckRun (CheckTestIsolationAggregate のルート)
- **生成ロジック概要**: 引数（オプション）と実行時 today 日付、リポジトリ状態を入力に CheckRun を生成

## ユビキタス言語

- **cwd 依存パターン**: BATS 関数内で `rm -rf` の前に作業ディレクトリを安全な場所（`$BATS_TMPDIR` 等）に切り替えていない記述。誤って repo root を消す可能性がある
- **致命パターン (fatal)**: `rm -rf "$REPO_ROOT"` 等の絶対パス／cwd 依存で repo / `.aidlc/` / `$HOME` を消す可能性のある記述。allowlist 不可
- **allowlist**: 既存違反の一時隔離リスト（出口条件付き / tracking_issue / expiry_date 必須）
- **3 種チェック**: check-skill-references / check-bash-substitution / check-test-isolation の必須 CI チェック群
- **fail-closed**: 解釈不能な状態（parse 失敗 / allowlist 期限切れ / stale）で違反扱いとする方針

## 不明点と質問

[Question] BATS 関数の `function foo() {` 形式と `foo() {` 形式（function キーワードなし）の両方に対応するか？
[Answer] BATS では `@test "..."` ブロック以外に `function foo() { ... }` か `foo() { ... }` の双方が許容される。awk のマッチ正規表現で両方をカバーする（`^[[:space:]]*(function[[:space:]]+)?[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\([[:space:]]*\)[[:space:]]*{`）。

[Question] `cd "$(mktemp -d ...)"` のように `$()` を含む cd ガードを許容するか（自身が bash-substitution 違反に該当する可能性）？
[Answer] check-bash-substitution.sh は `bin/` 配下のスクリプトを検査対象とし、BATS テスト（`tests/` / `bin/tests/`）は対象外（typically）。仮に検査対象だったとしても本 Unit のスコープ外。BATS 内の `cd "$(mktemp -d)"` は安全な cd ガードとして許容する。
