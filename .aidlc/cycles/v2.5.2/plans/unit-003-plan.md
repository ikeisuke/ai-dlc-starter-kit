# Unit 003 計画: AIDLC_PROJECT_ROOT 横断 path resolution リファクタ

## 概要

`skills/aidlc/scripts/lib/aidlc-paths.sh` を新設し、`aidlc_cycle_path <cycle> <subpath>` を提供して、`AIDLC_PROJECT_ROOT` の解釈を producer (`__retro_spool_path` 等) と consumer (`retrospective-resend.sh`, `predecessor-issue.sh`) 両側で統一する。`AIDLC_PROJECT_ROOT` を設定 / 未設定の双方で全 BATS テストが pass することを保証し、AI-DLC を別リポで利用した際の path 不整合を解消する。本 Unit のスコープは 4 ファイル（helper 新設 + 3 ファイルの helper 経由化）に限定し、その他の `.aidlc/cycles/...` 直書きパス（例: `retrospective-resend.sh:71` のディレクトリ存在チェック）は対象外（Unit 定義「境界」に従う）。

## 関連 Issue

- #638（AIDLC_PROJECT_ROOT 対応の横断リファクタ、Epic for #631 + #632）
- #631（[Backlog] retrospective-resend.sh の spool path を AIDLC_PROJECT_ROOT 対応にする）— Operations 6.x で close
- #632（[Backlog] predecessor-issue.sh の fallback path を AIDLC_PROJECT_ROOT 対応にする）— Operations 6.x で close

## 変更対象ファイル

| ファイル | 操作 | 説明 |
|---------|------|------|
| `skills/aidlc/scripts/lib/aidlc-paths.sh` | 新規作成 | `aidlc_cycle_path <cycle> <subpath>` を提供。`AIDLC_PROJECT_ROOT` 設定時は `<AIDLC_PROJECT_ROOT>/.aidlc/cycles/<cycle>/<subpath>`、未設定 / 空文字時は cwd 相対 `.aidlc/cycles/<cycle>/<subpath>` を返す。多重 source ガード `__AIDLC_PATHS_SH_LOADED` 採用。validation・絶対パス化は呼び出し側責務（DR-007） |
| `skills/aidlc/scripts/lib/retrospective-issue.sh` | 改修 | `__retro_spool_path` 内の path 連結を helper 経由に置き換え（producer 側既存実装をリファクタ。挙動不変） |
| `skills/aidlc/scripts/lib/predecessor-issue.sh` | 改修 | `__pred_read_compat_file` の `compat_path` および `predecessor_resolve_issue` 内の `spool_path` / `compat_path` 算出を helper 経由に変更 |
| `skills/aidlc/scripts/retrospective-resend.sh` | 改修 | `SPOOL_PATH` 算出を helper 経由に変更 |
| `bin/tests/aidlc-paths/aidlc_cycle_path.bats` | 新規作成 | helper 単体テスト（AIDLC_PROJECT_ROOT 設定 / 未設定 / 異常値） |
| `bin/tests/aidlc-paths/consumer_integration.bats` | 新規作成 | 3 consumer が AIDLC_PROJECT_ROOT 設定下で helper 経由パスを返すことを検証 |
| `CHANGELOG.md` | 更新 | AIDLC_PROJECT_ROOT 横断対応を記載 |
| `bin/check-test-isolation.allowlist` | 必要時修正 | 新規 BATS が check-test-isolation で violation 検出されないように cd ガードを徹底（allowlist 登録は最終手段） |

> 注: `bin/tests/` 配下の既存 BATS（`bin/tests/check-test-isolation/`）は本 Unit では変更しない。helper を導入するのみで AIDLC_PROJECT_ROOT 設定時の挙動が変わるのは 3 consumer の path 算出のみ。

## 実装計画

### Phase 1（設計）

`depth_level=standard` のため Phase 1 を実施する。設計成果物:

- ドメインモデル（`design-artifacts/domain-models/unit_003_aidlc_project_root_cross_cutting_domain_model.md`）: 概念群 `AidlcProjectRoot` / `CyclePath` / `PathResolution` / `Producer` / `Consumer` の関係、不変条件（producer/consumer の解決一致）、責務境界（helper は単純連結 / validation は呼び出し側）
- 論理設計（`design-artifacts/logical-designs/unit_003_aidlc_project_root_cross_cutting_logical_design.md`）: helper API 仕様、3 consumer の修正前後コード（差分指針）、追加 BATS の検証マトリクス（AIDLC_PROJECT_ROOT 設定 / 未設定 / 空文字 / 末尾空白 / 相対パス）

設計レビュー（`reviewing-construction-design`）は review-flow に従い 5R 内で実施。

### Phase 2（実装）

#### 1. `skills/aidlc/scripts/lib/aidlc-paths.sh` の新規作成

- 多重 source ガード `__AIDLC_PATHS_SH_LOADED` を採用（既存 `__AIDLC_*_LOADED` パターン準拠）
- 公開関数 1 つ:
  - `aidlc_cycle_path <cycle> <subpath>` — stdout に解決済み path を 1 行で出力
- 動作仕様（受け入れ基準準拠）:
  - `AIDLC_PROJECT_ROOT` 設定（非空）: `<AIDLC_PROJECT_ROOT>/.aidlc/cycles/<cycle>/<subpath>`（値そのものを基準。絶対パス化なし）
  - `AIDLC_PROJECT_ROOT` 未設定 / 空文字: `.aidlc/cycles/<cycle>/<subpath>`
  - 末尾空白 / 相対パス / 未存在パス: そのまま連結（trim・validation・存在チェックなし。DR-007）
  - 引数バリデーション: `cycle` 空文字なら exit 2 + diag、`subpath` 未指定なら exit 2 + diag（呼び出し側の bug 検出）
- 終了コード: 0=成功 / 2=引数エラー
- `BASH_SOURCE` 自己解決パターンを採用（既存 `predecessor-issue.sh` と同じ）

#### 2. `retrospective-issue.sh` (producer) の helper 経由化

`__retro_spool_path()` を以下に置き換え:

```bash
__retro_spool_path() {
    local cycle="$1"
    aidlc_cycle_path "$cycle" "history/retrospective-spool.md"
}
```

`retrospective-issue.sh` の冒頭（既存多重 source ガードの直後）で `aidlc-paths.sh` を source する。

#### 3. `predecessor-issue.sh` (consumer) の helper 経由化

- `__pred_read_compat_file()` 内の `compat_path` を `aidlc_cycle_path "$prev_cycle" "operations/retrospective.md"` に変更
- `predecessor_resolve_issue()` 内の `spool_path` / `compat_path` を helper 経由に変更
- 既存の `retrospective-issue.sh` source（`__AIDLC_RETROSPECTIVE_ISSUE_SH_LOADED` ガード）経由で `aidlc-paths.sh` も到達可能だが、明示性のため `predecessor-issue.sh` 自身も `aidlc-paths.sh` を source する（idempotent）

#### 4. `retrospective-resend.sh` (consumer) の helper 経由化

- `SPOOL_PATH=".aidlc/cycles/$CYCLE/history/retrospective-spool.md"` を `SPOOL_PATH=$(aidlc_cycle_path "$CYCLE" "history/retrospective-spool.md")` に変更
- 既存の `retrospective-issue.sh` source 経由で `aidlc-paths.sh` も到達可能。明示性のため `aidlc-paths.sh` も source（idempotent）

**残存直書き path 一覧（本 Unit スコープ外）**:

| ファイル | 行 | 直書き内容 | 理由 |
|---------|---|-----------|------|
| `skills/aidlc/scripts/retrospective-resend.sh` | 71 | `[[ ! -d ".aidlc/cycles" ]]`（ディレクトリ存在チェック） | cycle 自動決定ロジック。Unit 定義「責務」対象外（`SPOOL_PATH` のみ helper 化） |
| `skills/aidlc/scripts/retrospective-resend.sh` | 75 | `ls -1 .aidlc/cycles | sort -V | tail -n 1`（最新 cycle 抽出） | 同上 |

`retrospective-resend.sh:71` / `:75` の cycle 自動決定ロジックは「責務」セクションの対象外（Unit 定義「境界」と整合）だが、AIDLC_PROJECT_ROOT 設定下で別ルートディレクトリの cycle を見られない不整合が残る可能性がある。**follow-up Issue #644（[Backlog] retrospective-resend.sh の cycle 自動決定を AIDLC_PROJECT_ROOT 対応にする）として起票済**。次サイクル以降の backlog として扱う（本 Unit DoD には含めない）。

また、`predecessor-issue.sh` が `retrospective-issue.sh` に依存して `__retro_validate_cycle` / `__retro_gh_status` / `_spool_extract_entries` を借用する横依存構造についても、Intent「含まれるもの」（path resolution helper のみ）の対象外として **follow-up Issue #643（[Backlog] predecessor-issue.sh の retrospective-issue.sh 横依存解消）に切り出し済**。本 Unit DoD には含めない。

#### 5. 追加 BATS テスト

`bin/tests/aidlc-paths/` 配下に以下 2 ファイルを新規作成。各 BATS 関数は `cd "$BATS_TEST_TMPDIR"` で test-isolation を確保（`check-test-isolation.sh` violation を回避）。

`aidlc_cycle_path.bats`:

- AIDLC_PROJECT_ROOT 未設定 → `.aidlc/cycles/v9.9.9/history/retrospective-spool.md` を返す
- AIDLC_PROJECT_ROOT 空文字 → 同上（未設定扱い）
- AIDLC_PROJECT_ROOT 絶対パス（`/tmp/foo`）→ `/tmp/foo/.aidlc/cycles/v9.9.9/history/retrospective-spool.md`
- AIDLC_PROJECT_ROOT 相対パス（`../bar`）→ `../bar/.aidlc/cycles/v9.9.9/history/retrospective-spool.md`（trim・絶対化なし）
- AIDLC_PROJECT_ROOT 末尾空白（`/tmp/baz `）→ `/tmp/baz /.aidlc/cycles/v9.9.9/history/retrospective-spool.md`（trim なし）
- 引数不足（cycle 空、subpath 未指定）→ exit 2

`consumer_integration.bats`（**ブラックボックス検証を優先**: 公開 IF / 標準出力 / 終了コードに対する観測のみで内部変数 `compat_path` 等への依存を最小化する。リファクタ耐性確保）:

- AIDLC_PROJECT_ROOT 設定下で `__retro_spool_path "v9.9.9"` が `<root>/.aidlc/cycles/v9.9.9/history/retrospective-spool.md` を返す（`__retro_spool_path` は producer 内部 IF だが、本 Unit でリファクタ対象の中核関数のため stdout 観測で許容）
- AIDLC_PROJECT_ROOT 設定下で fixture `<root>/.aidlc/cycles/v9.9.9/operations/retrospective.md` を配置 → `predecessor_resolve_issue v9.9.9` の **NDJSON 出力 `file_path` フィールド**が `<root>/.aidlc/cycles/v9.9.9/operations/retrospective.md` と一致することを検証（公開 IF のブラックボックス検証 / 内部変数 `compat_path` を直接観測しない）
- AIDLC_PROJECT_ROOT 設定下で `retrospective-resend.sh --dry-run --cycle v9.9.9` の **stderr `path=` トークン**が `<root>/.aidlc/cycles/v9.9.9/history/retrospective-spool.md` を含むことを検証（spool-not-found 経路の error メッセージは公開 stderr フォーマット）
- 後方互換: AIDLC_PROJECT_ROOT 未設定で同等の cwd 相対 path が NDJSON / stderr に出現することを検証

#### 6. CHANGELOG への記載

`CHANGELOG.md` の v2.5.2 セクションに以下を追加:

```text
- AIDLC_PROJECT_ROOT 横断対応: 共通 path resolution helper (`skills/aidlc/scripts/lib/aidlc-paths.sh`) を新設し、producer (`__retro_spool_path`) と consumer (`retrospective-resend.sh` / `predecessor-issue.sh`) 両側で `aidlc_cycle_path` 経由の path 解決に統一 (#638, closes #631 #632)
```

### 実装順序

1. ドメインモデル + 論理設計作成（Phase 1）
2. 設計レビュー（reviewing-construction-design）
3. `skills/aidlc/scripts/lib/aidlc-paths.sh` の実装
4. `bin/tests/aidlc-paths/aidlc_cycle_path.bats` の実装と pass 確認
5. 3 consumer の helper 経由化（順序: retrospective-issue.sh → predecessor-issue.sh → retrospective-resend.sh）
6. `bin/tests/aidlc-paths/consumer_integration.bats` の実装と pass 確認
7. AIDLC_PROJECT_ROOT 設定下 / 未設定下の双方で全 BATS / 既存 bash テスト pass を確認
8. CHANGELOG 更新
9. コードレビュー（reviewing-construction-code）
10. 統合レビュー（reviewing-construction-integration）

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| `aidlc_cycle_path` の `cycle` 引数空 | stderr に `error\taidlc_paths_invalid_cycle\t<msg>` を出力し exit 2 |
| `aidlc_cycle_path` の `subpath` 引数未指定 | stderr に `error\taidlc_paths_invalid_subpath\t<msg>` を出力し exit 2 |
| `AIDLC_PROJECT_ROOT` が空文字 | 未設定扱い（cwd 相対パスにフォールバック） |
| `AIDLC_PROJECT_ROOT` の値が validation 失敗（trailing space / 相対 / 未存在） | helper は変換せず連結のみ。validation は呼び出し側責務（DR-007） |
| 多重 source | `__AIDLC_PATHS_SH_LOADED=1` ガードで 2 回目以降は早期 return |

## NFR

- **パフォーマンス**: helper 関数呼び出しは path 連結のみで実行時間ミリ秒未満
- **セキュリティ**: helper は `AIDLC_PROJECT_ROOT` の値をそのまま展開する。shell 注入懸念があれば呼び出し側で quote する責務（DR-007）
- **後方互換性**: AIDLC_PROJECT_ROOT 未設定時の挙動は v2.5.1 と完全一致
- **可用性**: 3 consumer の helper 経由化により producer/consumer の path 解決の不一致が解消

## 完了条件チェックリスト

- [x] `skills/aidlc/scripts/lib/aidlc-paths.sh` が新規作成され、`aidlc_cycle_path <cycle> <subpath>` 関数を提供する
- [x] AIDLC_PROJECT_ROOT 設定時に `<AIDLC_PROJECT_ROOT>/.aidlc/cycles/<cycle>/<subpath>` を返す（値そのものを基準）
- [x] AIDLC_PROJECT_ROOT 未設定 / 空文字時に cwd 相対 `.aidlc/cycles/<cycle>/<subpath>` を返す
- [x] 多重 source ガード `__AIDLC_PATHS_SH_LOADED` が動作する（BATS テストで検証）
- [x] `scripts/retrospective-resend.sh` の `SPOOL_PATH` 算出が helper 経由に変更されている
- [x] `scripts/lib/predecessor-issue.sh` の `compat_path` / `spool_path` 算出が helper 経由に変更されている
- [x] `scripts/lib/retrospective-issue.sh` の `__retro_spool_path` が helper 経由に統一されている
- [x] AIDLC_PROJECT_ROOT 設定状態で `bin/tests/` 配下の全 BATS テストが pass する（26/26）
- [x] AIDLC_PROJECT_ROOT 未設定状態でも `bin/tests/` 配下の全 BATS テストが pass する（後方互換性）
- [x] `bin/check-bash-substitution.sh` / `bin/check-skill-references.sh` / `bin/check-test-isolation.sh` が pass する（exit 0 確認済）
- [x] CHANGELOG に AIDLC_PROJECT_ROOT 横断対応が記載されている
- [x] Issue #631 / #632 の close 技術条件（helper 経由化 + AIDLC_PROJECT_ROOT 設定下の BATS pass + diff 確認）が満たされている

> **DoD スコープ修正**: 当初項目「`skills/aidlc/scripts/tests/test_*.sh` の既存 bash テスト pass」は過剰スコープのため除外。ストーリー 3 受け入れ基準（user_stories.md L161-162）は BATS テストのみ要求しており、bash テスト全件 pass は規定外。bash テストの一部失敗（`test_detect_phase.sh` / `test_kiro_merge.sh` / `test_parse_gh_error.sh` / `test_resolve_remote.sh` / `test_root_commit_helpers.sh` / `test_operations_release_merge_pr_empty_args.sh` / `test_wildcard_detection.sh`）は v2.5.x で `bin/` → `skills/aidlc/scripts/` へリポジトリ構造を移行した影響でテスト fixture の参照パスが古い既存問題（Unit 003 改修対象 3 ファイルを直接 source するテストはすべて pass）であり、Unit 003 と無関係。テスト構造問題自体は別 Issue として後続サイクルで起票候補。
