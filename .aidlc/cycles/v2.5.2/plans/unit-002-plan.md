# Unit 002 計画: Construction Unit 完了時 CI 構造チェック強化

## 概要

`bin/check-test-isolation.sh` を新規作成して BATS テストの cwd 依存パターン（破壊的 `rm -rf` の前に安全な作業ディレクトリへの `cd` がない関数）を静的解析で検出する。`scripts/squash-unit.sh` 経由で Unit 完了時に check-skill-references / check-bash-substitution / check-test-isolation の 3 種を必須実行し、violation 検出時は Unit 完了を exit 1 でブロックする。CI ワークフロー（`.github/workflows/skill-reference-check.yml`）にも 3 種チェックを統合する。

## 関連 Issue

- #636 Construction Unit 完了時の CI 構造チェック強化（skill-references / bash-substitution / test-isolation）

## 変更対象ファイル

| ファイル | 操作 | 説明 |
|---------|------|------|
| `bin/check-test-isolation.sh` | 新規作成 | BATS 関数（teardown / teardown_file / setup / setup_file / @test）内で `rm -rf` の前に安全な `cd` ガードがあるかを静的解析。致命パターン (`rm -rf "$REPO_ROOT"` 等) は `severity:fatal` で検出。violation 出力 1 件 1 行 (`error\t<check_name>\t<file>:<line>\t<reason>`)。allowlist 機構あり |
| `bin/check-test-isolation.allowlist` | 新規作成 | 本 Unit 開始時点の既存違反を一時隔離する TSV (`file<TAB>function<TAB>reason<TAB>added_date<TAB>tracking_issue<TAB>expiry_date`) |
| `bin/tests/check-test-isolation/` 配下 | 新規作成 | BATS 3 ケース最小（ガードあり / ガードなし / 致命パターン） |
| `skills/aidlc/scripts/squash-unit.sh` | 改修 | Unit 完了時に 3 種チェックを必須実行。violation あれば exit 1 で squash 中止 |
| `.github/workflows/skill-reference-check.yml` | 改修 | check-bash-substitution / check-test-isolation を追加（リネーム・構造変更なし、既存 step の追加のみ）。`PATHS_REGEX` を `bin/check-bash-substitution\.sh` / `bin/check-test-isolation\.sh` / `bin/check-test-isolation\.allowlist` / `bin/tests/check-test-isolation/.*\.bats` / `tests/.*\.bats` も含むよう拡張（検査スクリプト変更と検査対象 BATS 変更の両方が CI で必ず検証される依存構造に） |
| `bin/tests/` 既存 BATS | 必要時のみ修正 | check-test-isolation 検出時、致命パターンは即修正、軽微パターンは allowlist 登録（後続サイクル対応） |

## 実装計画

### Phase 1（設計）

設計成果物:

- ドメインモデル（`design-artifacts/domain-models/unit_002_construction-ci-structural-checks_domain_model.md`）: BatsFunction / RmRfPattern / CdGuard / Allowlist / IntegrityCheck / Violation のドメイン語彙と関係
- 論理設計（`design-artifacts/logical-designs/unit_002_construction-ci-structural-checks_logical_design.md`）: check-test-isolation.sh の awk アルゴリズム、allowlist フォーマット、squash-unit.sh への組み込み箇所、CI 統合構成

`depth_level=standard` のため Phase 1 は実施。設計レビュー（reviewing-construction-design）を 5R 内で実施。

### Phase 2（実装）

#### 1. `bin/check-test-isolation.sh` の新規作成

シェルスクリプト構造:

- 引数: 引数なしで実行（リポジトリルートから `tests/` および `bin/tests/` 配下の `*.bats` を全検査）
- 検査対象関数: `function teardown()` / `function teardown_file()` / `function setup()` / `function setup_file()` / `@test "..."` ブロック
- 関数スコープ抽出: awk で `{` から対応する `}` までをマッチング深度カウンタで識別
- ガード判定: 同一関数内で `rm -rf` の前に以下のいずれかが先行していること
  - `cd "$BATS_TMPDIR"`
  - `cd "$BATS_TEST_TMPDIR"`
  - `cd "$BATS_FILE_TMPDIR"`
  - `cd "$TMP"`
  - `cd "$(mktemp -d ...)"` または `cd "$(...mktemp -d...)"` 相当
- 致命パターン判定: 以下を `severity:fatal` として最優先検出
  - `rm -rf "$REPO_ROOT"` / `rm -rf "${REPO_ROOT}"`
  - `rm -rf .aidlc/...`（リポジトリ内 .aidlc 配下を消す）
  - `rm -rf "$(pwd)"` / `rm -rf "$PWD"`
  - `rm -rf $HOME/...`
- allowlist 照合: `bin/check-test-isolation.allowlist` を読み込み、`file_path + function_name + reason` の 3 つ組完全一致のみ allowlist 扱い
- allowlist の CI ガード:
  - 期限切れ (`expiry_date` < 現在日) → exit 1 + reason 表示
  - stale (対象ファイル不在 or 関数不在 or `rm -rf` を含まなくなっている) → exit 1 + reason 表示
- violation 出力フォーマット: stderr に `error\t{check_name}\t{file}:{line}\t{reason}` 形式で 1 件 1 行
- 終了コード: 0 (no violations) / 1 (violation 検出 / allowlist の期限切れ・stale)
- セキュリティ: 検査スクリプト自体は `rm -rf` 等の破壊的コマンドを実行しない（読み取り専用解析）
- bash-substitution の扱い: 現行 `check-bash-substitution.sh` は `skills/aidlc/steps/*.md` のみ検査対象で `bin/*.sh` は対象外。よって本実装では `$()` の使用を強制制約にせず、可読性優先で書く（将来 `bin/*.sh` 用チェック導入時は別 Unit で対応）

#### 2. `bin/check-test-isolation.allowlist` の新規作成

TSV フォーマット（タブ区切り、ヘッダ行付き）:

```text
# file_path	function_name	reason	added_date	tracking_issue	expiry_date
```

各列の意味:

- `file_path`: repo-relative path（例: `tests/foo.bats`）
- `function_name`: 違反を含む関数名（例: `teardown`、`@test "..."` の場合は test 名そのまま）
- `reason`: 照合キーの一部として扱う再現可能な説明（例: `legacy-cleanup-without-cd`）
- `added_date`: 登録日 (`YYYY-MM-DD`)
- `tracking_issue`: 後続サイクルで解消する Issue 番号 (`#NNN`)
- `expiry_date`: 期限 (`YYYY-MM-DD`)、これを過ぎると CI が exit 1

本 Unit では check-test-isolation.sh を既存 BATS 全件に対して実行 → 違反を抽出 → allowlist へ事前登録（致命パターンは allowlist 不可、即修正）。

#### 3. `bin/tests/check-test-isolation/` BATS 3 ケース

- ケース A: `cd "$BATS_TMPDIR"` ガードあり + `rm -rf .` → no violations
- ケース B: ガードなし + `rm -rf foo/` → violation 検出
- ケース C: 致命パターン `rm -rf "$REPO_ROOT"` → severity:fatal violation

#### 4. `skills/aidlc/scripts/squash-unit.sh` への組み込み

squash 実行前のフェーズに以下を追加:

```bash
# Unit 完了 CI 構造チェック（3種必須実行）
"${SCRIPT_ROOT}/../../../../bin/check-skill-references.sh" || exit 1
"${SCRIPT_ROOT}/../../../../bin/check-bash-substitution.sh" || exit 1
"${SCRIPT_ROOT}/../../../../bin/check-test-isolation.sh" || exit 1
```

実装時は AIDLC_PROJECT_ROOT 環境変数の利用を考慮（Unit 003 で本格対応予定）し、本 Unit ではリポジトリルート相対パスで安全にスクリプトを呼び出す。

#### 5. `.github/workflows/skill-reference-check.yml` への統合

既存 `bin/check-skill-references.sh` の step に並列して以下を追加（リネーム・構造変更なし）:

```yaml
- name: Run check-bash-substitution
  run: bash bin/check-bash-substitution.sh
- name: Run check-test-isolation
  run: bash bin/check-test-isolation.sh
```

#### 6. 既存 BATS の事前検証

check-test-isolation.sh を `tests/` および `bin/tests/` 全 BATS に対して実行 → 違反検出 → 以下の優先順位で対応:

1. **致命パターン（severity:fatal）**: 即修正。allowlist 不可
2. **修正可能な軽微違反**: 本 Unit 内で **可能な限り修正**（`cd "$BATS_TMPDIR"` 等のガード追加）
3. **修正不能 or 修正リスクが高い違反**: allowlist 登録（出口条件付き / tracking_issue 必須 / expiry_date 設定）

ストーリー 2 受け入れ基準「既存の tests/**/*.bats で違反がない」と Unit 定義「allowlist は既存違反の一時隔離」の橋渡し:

- ストーリー文の「違反がない」とは「本 Unit で修正可能な違反は修正済み」+「修正困難な違反は allowlist で出口条件付きに隔離（後続サイクルで段階解消）」と解釈する
- allowlist は「暫定回避フラグ（CI スキップ等）」とは異なる: 全 violation は CI で個別判定され、allowlist 内のみ warn 継続、allowlist 外は exit 1。期限切れ / stale は exit 1 で fail
- 致命パターン (severity:fatal) は allowlist 不可（履歴破壊防止のクリティカルな防御）
- 受け入れ基準「暫定回避フラグを追加していない」は維持（CI スキップフラグや無条件 warn は導入しない）

### 実装順序

1. ドメインモデル + 論理設計作成（Phase 1）
2. 設計レビュー
3. `bin/check-test-isolation.sh` の実装
4. `bin/tests/check-test-isolation/` BATS 3 ケースの実装と pass 確認
5. 既存 BATS への一括検査と allowlist 登録
6. `bin/check-test-isolation.allowlist` の作成
7. `skills/aidlc/scripts/squash-unit.sh` への 3 種チェック組み込み
8. `.github/workflows/skill-reference-check.yml` の統合
9. AI レビュー（reviewing-construction-code）→ 統合レビュー（reviewing-construction-integration）

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| 致命パターン検出 | `severity:fatal` として exit 1。allowlist 登録不可 |
| 軽微違反 + allowlist 既存 | 3 つ組完全一致なら warn 継続 |
| allowlist 期限切れ | exit 1 + reason 表示 |
| allowlist stale (対象不在) | exit 1 + reason 表示 |
| awk 不在 | エラー表示 + exit 2 |
| BATS ファイル parse 失敗 | **fail-closed**: 既定で exit 1（CI / squash-unit.sh 経由では絶対 exit 1）。`--allow-parse-warn` フラグ指定時のみ warn + スキップ（ローカル開発用の限定オプション） |

## NFR

- パフォーマンス: 数十件規模の BATS で 1 秒以内
- セキュリティ: 検査スクリプト自体は破壊的コマンドを実行しない（読み取り専用）
- スケーラビリティ: BATS テスト数に対して O(N) 線形
- 可用性: CI 環境で awk が利用できることを前提（GitHub Actions Ubuntu runner 標準搭載）

## 完了条件チェックリスト

- [x] `bin/check-test-isolation.sh` が新規作成され、BATS 関数（teardown / teardown_file / setup / setup_file / @test）内の `rm -rf` 前 cd ガードを判定する
- [x] 致命パターン（`rm -rf "$REPO_ROOT"` / `.aidlc/...` / `"$(pwd)"` / `$HOME/...`）が `severity:fatal` で検出される
- [x] allowlist 機構が動作する（3 つ組完全一致での隔離、stale / 期限切れの fail）
- [x] `bin/check-test-isolation.allowlist` が作成され、本 Unit 開始時点の既存違反が登録されている
- [x] `bin/tests/check-test-isolation/` 配下に最小 3 ケース BATS（ガードあり / ガードなし / 致命）が pass する
- [x] `skills/aidlc/scripts/squash-unit.sh` が 3 種チェック（skill-references / bash-substitution / test-isolation）を必須実行し、violation 検出時 exit 1 で Unit 完了をブロックする
- [x] `.github/workflows/skill-reference-check.yml` に check-bash-substitution / check-test-isolation が統合されている
- [x] check-test-isolation.sh の実装が cwd 非依存（script dir から repo root 解決）
- [x] 全 BATS テスト（既存 188 + 新規 3）がパス
- [x] 全 3 種 CI チェックが pass
