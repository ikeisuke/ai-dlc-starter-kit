# 論理設計: Unit 002 Construction Unit 完了時 CI 構造チェック強化

## 概要

`bin/check-test-isolation.sh`（新規）を中核とした 3 種 CI チェック統合の論理設計。awk による関数スコープ抽出、allowlist の出口条件付き運用、squash-unit.sh への組み込み、CI workflow への統合を一括設計する。

**重要**: コードは書かず、コンポーネント構成・IF・処理フローのみを定義する。

## アーキテクチャパターン

**Pipeline + Guard pattern**

- 入力: BATS ファイル群 → 関数抽出 → 違反検出 → allowlist 照合 → 出口条件判定 → 終了コード決定
- 各段階は単方向で次段階に渡し、上流の失敗は下流で fail-closed として扱う

選定理由: シェルスクリプトでの静的解析は段階的フィルタリングが自然。複雑な状態遷移を持たないためパイプライン構造が直感的。

## コンポーネント構成

### モジュール構成

```text
bin/
├── check-test-isolation.sh           (新規 / 検査本体)
├── check-test-isolation.allowlist     (新規 / 既存違反隔離 TSV)
├── check-skill-references.sh          (既存 / 改修なし)
├── check-bash-substitution.sh         (既存 / 改修なし)
└── tests/
    └── check-test-isolation/
        ├── case_a_with_guard.bats     (新規 / ガードあり 期待: pass)
        ├── case_b_no_guard.bats        (新規 / ガードなし 期待: violation)
        └── case_c_fatal_pattern.bats   (新規 / 致命パターン 期待: severity:fatal)

skills/aidlc/scripts/
└── squash-unit.sh                      (改修 / 3 種チェック組み込み)

.github/workflows/
└── skill-reference-check.yml           (改修 / 3 種チェック step 追加 + PATHS_REGEX 拡張)

tests/                                  (既存 BATS、必要時のみ修正 + allowlist 登録)
```

### コンポーネント詳細

#### `bin/check-test-isolation.sh`

- **責務**: BATS ファイルの cwd 依存パターン静的解析、致命パターン検出、allowlist 照合、出口条件判定、violation 出力
- **依存**: `awk`、`bash`、`bin/check-test-isolation.allowlist`、`tests/`、`bin/tests/`
- **公開インターフェース**:
  - 引数: 既定で引数なし（リポジトリルート相対の `tests/` および `bin/tests/` 全 BATS）。`--allow-parse-warn` フラグでローカル開発時のみ parse 失敗を warn 化
  - 終了コード: `0` (no violations) / `1` (violation / 期限切れ / stale / parse 失敗) / `2` (スクリプトエラー / awk 不在)
  - 出力: stderr に `error\t{check_name}\t{file}:{line}\t{reason}` 形式 1 件 1 行

#### `bin/check-test-isolation.allowlist`

- **責務**: 既存違反の一時隔離リスト（TSV 形式、6 列）
- **公開インターフェース**:
  - フォーマット: `file_path<TAB>function_name<TAB>reason<TAB>added_date<TAB>tracking_issue<TAB>expiry_date`
  - ヘッダ行: `# file_path<TAB>function_name<TAB>reason<TAB>added_date<TAB>tracking_issue<TAB>expiry_date`
  - コメント行: `#` で始まる行はスキップ
  - 空行: スキップ

#### `skills/aidlc/scripts/squash-unit.sh`

- **責務（改修部分のみ）**: squash 実行前に 3 種チェックを必須実行
- **依存**: `bin/check-skill-references.sh`、`bin/check-bash-substitution.sh`、`bin/check-test-isolation.sh`
- **公開インターフェース**: 既存の squash インターフェース（`--cycle`, `--unit`, `--vcs`, `--base`, `--message-file` 等）は不変

#### `.github/workflows/skill-reference-check.yml`

- **責務（改修部分のみ）**: PR 単位で 3 種チェックを実行
- **公開インターフェース**:
  - `PATHS_REGEX` 拡張: 既存（`skills/.+|bin/check-skill-references\.sh|.github/workflows/skill-reference-check\.yml`）に以下を追加
    - `bin/check-bash-substitution\.sh`
    - `bin/check-test-isolation\.sh`
    - `bin/check-test-isolation\.allowlist`
    - `bin/tests/check-test-isolation/.*\.bats`
  - 既存の `Run check-skill-references` step の後に以下の step を追加:
    - `Run check-bash-substitution`
    - `Run check-test-isolation`

## インターフェース設計

### スクリプトインターフェース設計

#### `bin/check-test-isolation.sh`

##### 概要

BATS テストの cwd 依存パターン（`rm -rf` の前に安全な `cd` ガードがない関数）を静的解析で検出する。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| なし | - | リポジトリルートから引数なしで実行 |
| `--allow-parse-warn` | 任意 | parse 失敗を warn 化（既定は fail-closed exit 1）。ローカル開発用 |
| `-h`, `--help` | 任意 | usage 表示 |

##### 成功時出力

```text
check-test-isolation: no violations, {N} files checked
```

- 終了コード: `0`
- 出力先: stdout

##### violation 検出時出力

```text
error	check-test-isolation	{file}:{line}	{reason}
error	check-test-isolation	{file}:{line}	severity:fatal {reason}
check-test-isolation: {N} violations, {M} files checked
```

- 終了コード: `1`
- 出力先: stderr（violation lines）+ stdout（最終サマリ）

##### allowlist 期限切れ / stale 出力

```text
error	check-test-isolation	allowlist:{line}	expired	expiry_date={YYYY-MM-DD}
error	check-test-isolation	allowlist:{line}	stale	{file_path}:{function_name}
```

- 終了コード: `1`
- 出力先: stderr

##### スクリプトエラー出力

```text
error	check-test-isolation	system:0	awk-not-found
error	check-test-isolation	system:0	allowlist-malformed-line:{N}
```

- 終了コード: `2`（システムエラー） / `1`（allowlist-malformed-line は fail-closed として exit 1）
- 出力フォーマットは通常 violation と同一の 4 カラム（`error\t{check_name}\t{file_or_system_id}:{line_or_0}\t{reason}`）に統一。機械処理の後方互換性を保証する

##### 使用コマンド

```bash
# 既定実行
bash bin/check-test-isolation.sh

# ローカル開発時の parse 失敗 warn 化
bash bin/check-test-isolation.sh --allow-parse-warn

# ヘルプ
bash bin/check-test-isolation.sh --help
```

#### `skills/aidlc/scripts/squash-unit.sh`（改修部分のみ）

##### パス解決ポリシー（cwd 非依存）

既存 `squash-unit.sh` は **スクリプト自身の位置基準** で動作する設計（cwd 非依存）。3 種チェック呼び出しもこの方針に揃え、cwd に依存しない実装とする。

```bash
# スクリプト自身の位置から repo root を解決（既存 squash-unit.sh 内で計算済みの REPO_ROOT を流用）
# 例: SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" → REPO_ROOT="$SCRIPT_DIR/../../../../"
# 実装は既存 squash-unit.sh の REPO_ROOT 算出ロジックに合わせる

# 3 種 CI 構造チェック（必須実行、violation 検出時 exit 1）
bash "${REPO_ROOT}/bin/check-skill-references.sh" || {
  echo "squash:error:check-skill-references-failed" >&2
  exit 1
}
bash "${REPO_ROOT}/bin/check-bash-substitution.sh" || {
  echo "squash:error:check-bash-substitution-failed" >&2
  exit 1
}
bash "${REPO_ROOT}/bin/check-test-isolation.sh" || {
  echo "squash:error:check-test-isolation-failed" >&2
  exit 1
}
```

実装注意:

- **cwd 非依存**: `cd` の有無や呼び出し元の cwd に関わらず動作する。スクリプト自身の位置から repo root を解決した絶対パスで実行
- 既存 `squash-unit.sh` の `REPO_ROOT` 算出ロジック（`SCRIPT_DIR` から相対）を流用し、cwd 相対の `bin/...` は使用しない
- スクリプト終了コード非 0 → squash 全体を exit 1 で中止
- 致命パターンも `severity:fatal` 込みで exit 1 を返すため、squash 中止条件として等価に扱える

#### `.github/workflows/skill-reference-check.yml`（改修部分のみ）

##### PATHS_REGEX 拡張

```yaml
env:
  PATHS_REGEX: '^(skills/.+|bin/check-skill-references\.sh|bin/check-bash-substitution\.sh|bin/check-test-isolation\.sh|bin/check-test-isolation\.allowlist|bin/tests/check-test-isolation/.*\.bats|tests/.*\.bats|\.github/workflows/skill-reference-check\.yml)$'
```

**注**: `tests/.*\.bats` を追加し、`check-test-isolation.sh` の実検査対象（`tests/**/*.bats`）の変更が必ず workflow をトリガーするよう一致させる。検査スクリプト変更と検査対象変更の両方が CI で検証される依存構造を保証する。

##### Step 追加

```yaml
- name: Run check-bash-substitution
  run: bash bin/check-bash-substitution.sh

- name: Run check-test-isolation
  run: bash bin/check-test-isolation.sh
```

## データモデル概要

### ファイル形式

#### `bin/check-test-isolation.allowlist`（TSV）

```text
# file_path	function_name	reason	added_date	tracking_issue	expiry_date
tests/foo.bats	teardown	legacy-cleanup-without-cd	2026-05-06	#XXX	2026-08-06
```

各列の制約:

- `file_path`: repo-relative（先頭 `/` 不可、絶対パス不可、空白不可）
- `function_name`: BATS 関数名（`teardown` / `setup` / `setup_file` / `teardown_file` / `@test "..."` の name 部）
- `reason`: 照合キーの一部となる識別子（例: `legacy-cleanup-without-cd`、`historical-fixture-cleanup`）
- `added_date`: `YYYY-MM-DD`
- `tracking_issue`: `#NNN` または GitHub Issue URL
- `expiry_date`: `YYYY-MM-DD`、現在日と比較

## 処理フロー概要

### ユースケース 1: ローカルから check-test-isolation.sh 実行

1. リポジトリルートから引数なし実行
2. `awk` 存在確認 → 不在なら exit 2
3. `tests/` および `bin/tests/` 配下の `*.bats` を列挙
4. 各ファイルについて `BatsParser.parse()` → BatsFunction[] 抽出
5. parse 失敗時: `--allow-parse-warn` 指定なら warn + スキップ、なしなら exit 1
6. 各 BatsFunction について `FatalPatternDetector.detect()` → 致命 violation を抽出（**最優先 / 必ずこの順序**）
7. 各 BatsFunction について `CdGuardEvaluator.evaluate()` → 通常 violation を抽出
8. 全 violation について `AllowlistMatcher.match()` → allowlist 一致で warn 化（**ただし fatal は常に非許可**: AllowlistMatcher は事前に severity を確認し、`severity=fatal` の violation はマッチがあっても warn 化しない）。判定順序は固定: `Fatal優先 → Allowlist 照合 → 残 violation` の IF 契約として保証する
9. allowlist 全 entry について `AllowlistIntegrityChecker.check()` → 期限切れ / stale を IntegrityViolation として抽出
10. 残 violation 数 > 0 または IntegrityViolation > 0 → exit 1
11. 残 violation 0 → exit 0

### ユースケース 2: squash-unit.sh から 3 種チェック実行

**前提**: `squash-unit.sh` は script dir 起点で `REPO_ROOT` を解決済み（`SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` → `REPO_ROOT="$SCRIPT_DIR/../../../../"`）。すべてのチェック呼び出しは `${REPO_ROOT}/bin/...` の絶対パスで実行する（cwd 非依存）。

1. squash 実行前のステップで `bash "${REPO_ROOT}/bin/check-skill-references.sh"` を実行
2. exit 0 なら次へ、非 0 なら `squash:error:check-skill-references-failed` で exit 1
3. 同様に `bash "${REPO_ROOT}/bin/check-bash-substitution.sh"`
4. 同様に `bash "${REPO_ROOT}/bin/check-test-isolation.sh"`
5. 3 種すべて pass で squash 続行

### ユースケース 3: GitHub Actions workflow

1. PR push で `skill-reference-check.yml` がトリガー
2. paths-filter で `PATHS_REGEX` に該当する変更がある場合のみ実行
3. 既存 `Run check-skill-references` step → 新規 `Run check-bash-substitution` → 新規 `Run check-test-isolation`
4. 3 step すべて pass でジョブ pass

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 数十件規模の BATS で 1 秒以内
- **対応策**: awk による線形パース、I/O は逐次読み込み、外部プロセスは最小限（awk 本体のみ）

### セキュリティ

- **要件**: 検査スクリプト自体が `rm -rf` 等の破壊的コマンドを実行しない
- **対応策**: 読み取り専用解析（`grep` / `awk` のみ）、書き込み操作は一切行わない

### スケーラビリティ

- **要件**: BATS テスト数に対して O(N) 線形
- **対応策**: ファイル単位で独立処理、並列化は不要（数十件規模）

### 可用性

- **要件**: CI 環境で `awk` が利用できることを前提
- **対応策**: GitHub Actions Ubuntu runner には `awk` (gawk) が標準搭載。事前確認 step を追加し不在なら exit 2

## 技術選定

- **言語**: Bash 4+ + awk（GNU awk / BSD awk 互換性を確保）
- **データ形式**: TSV（allowlist）、stderr 行ベース（violation 出力）
- **CI**: GitHub Actions（既存 workflow に統合）

## 実装上の注意事項

- **`$()` の扱い（現行ルール上は対象外）**: 現行の `bin/check-bash-substitution.sh` は `skills/aidlc/steps/*.md` 内の Bash コードブロックのみを検査対象とし、`bin/*.sh` は検査対象に含まれない。よって `check-test-isolation.sh` 実装で `$()` を使用しても現行 CI は通過する。本 Unit のスコープでは `$()` の使用可否を強制せず、可読性優先で書く（バッククォートは入れ子困難なため）。**将来 `bin/*.sh` 用の bash-substitution チェックが導入されれば本ファイルも対象となるが、その導入自体は別 Unit / 別 Issue に切り出す**
- **awk 互換性**: BSD awk と GNU awk の両方で動作するよう、拡張機能（`gensub` / `length(array)` 等）を避ける
- **致命パターンの優先**: FatalPatternDetector を CdGuardEvaluator より先に実行し、致命は allowlist 対象外として確実に exit 1（IF 契約で固定）
- **fail-closed 原則**: parse 失敗・期限切れ・stale・allowlist 不正フォーマット行はすべて exit 1（明示フラグでのみ緩和、部分スキップは禁止）
- **cwd 非依存**: スクリプト本体および呼び出し側 (`squash-unit.sh`) はすべて script dir から repo root を解決した絶対パスで動作。cwd 依存の相対パスは使用しない

## 不明点と質問

[Question] バッククォート `` ` `` を使う際にネストが必要な場合はどうするか？
[Answer] 関数化して return / echo で値を返す。例: `local mktemp_result; mktemp_result=` `` `_my_mktemp` ``、`_my_mktemp() { mktemp -d -t check-test-isolation.XXXXXX; }`。

[Question] CI workflow で `Run check-test-isolation` ステップが allowlist の expiry_date エラーで fail した場合の運用は？
[Answer] expiry_date が来ている entry は tracking_issue で参照される後続サイクルで段階解消する。CI fail を契機に tracking_issue を確認し、解消 PR を作成するか、解消できない場合は expiry_date を延長する判断を行う（延長は実質的な技術的負債残存となるため極力避ける）。
