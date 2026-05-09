# Unit 002 計画: main-repo-health-check の fixture 誤検出除外

## 概要

`skills/aidlc/scripts/main-repo-health-check.sh:139` の `check_conflict_marker()` で `git grep` 対象から fixture/docs を pathspec 除外し、v2.5.5 Operations 開始時に発生していた count=12 の fixture 誤検出を解消する。実コンフリクト検出力は維持する。

## 関連 Issue

- #670（main-repo-health-check: tests/docs 内のコンフリクトマーカー fixture を除外する）

## スコープ境界

| 範囲 | 含む / 含まない |
|------|----------------|
| `check_conflict_marker()` の `git grep` pathspec 除外追加 | 含む |
| 受け入れテスト 2 種（除外サンプル検証 / 実コンフリクト検出維持） | 含む |
| `tests/main-repo-health-check.bats` の CI 実行エントリ追加（`.github/workflows/migration-tests.yml`） | 含む（DoD「既存全シナリオが PASS」を CI で検証可能にするため、Round 1 codex 指摘 #1 対応） |
| 他 check 関数（lock-file / orphan-cycle / unresolved-todo 等）の改修 | 含まない（Unit 境界） |
| BATS fixture の heredoc 連結 escape 案 | 含まない（Unit 境界、可読性優先） |

## 責務分離原則

| レイヤ | 役割 | ファイル |
|--------|------|---------|
| 実装 SoT | `git grep` への pathspec 除外追加（`tests/main-repo-health-check.bats` および `.aidlc/cycles/**/design-artifacts/**`） | `skills/aidlc/scripts/main-repo-health-check.sh:139` |
| テスト SoT | bats 受け入れテスト 2 種追加 | `tests/main-repo-health-check.bats` |
| 履歴 | 実装進捗・レビュー round・検証結果記録 | `.aidlc/cycles/v2.5.6/history/construction_unit02.md` |

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/scripts/main-repo-health-check.sh` | 改修（実装 SoT） | line 145 の `git grep` 呼び出しに `-- ':(exclude)tests/main-repo-health-check.bats' ':(exclude).aidlc/cycles/**/design-artifacts/**'` を追加 |
| `tests/main-repo-health-check.bats` | テスト追加（テスト SoT） | (a) 除外サンプル検証: 除外パスに conflict marker を持つファイルがあっても warning にならない / (b) 実コンフリクト検出維持: 除外対象外のテンポラリパスに conflict marker を作成すると warning として検出される |
| `.github/workflows/migration-tests.yml` | 改修（CI wiring） | (1) `bats` 実行行に `tests/main-repo-health-check.bats` を追加 / (2) `PATHS_REGEX`（line 25）の glob 列挙に `tests/main-repo-health-check\.bats` を追加（PR 差分トリガに含めるため）/ (3) ジョブ列に `skills/aidlc/scripts/main-repo-health-check\.sh` を追加（実装スクリプト変更時にも CI が回るよう PATHS_REGEX を拡張） |
| `.aidlc/cycles/v2.5.6/history/construction_unit02.md` | 新規作成 | Unit 002 の進捗履歴・レビュー round・検証結果 |

> 編集箇所の正確な diff（pathspec 文字列順、テストケース構造）は **論理設計** で確定する。

## 実装計画

### Phase 1（設計）

`depth_level=standard` のため Phase 1 はスキップしない。設計成果物として以下を作成する:

- ドメインモデル（`design-artifacts/domain-models/unit_002_health_check_fixture_exclusion_domain_model.md`）: `conflict-marker 検出の対象境界` のドメイン語彙整理（real conflict / fixture / docs / temporary path / pathspec exclude）
- 論理設計（`design-artifacts/logical-designs/unit_002_health_check_fixture_exclusion_logical_design.md`）: `git grep` 改訂前後コマンド、pathspec exclude の評価順、bats テスト 2 ケースの入出力定義（mktemp ベースの fixture 戦略を含む）

設計レビュー（`reviewing-construction-design`）を 5R 内で実施する。

### Phase 2（実装）

実装順序:

1. `main-repo-health-check.sh:145` の `git grep` 改訂（pathspec 除外追加）
2. `tests/main-repo-health-check.bats` に受け入れテスト 2 種を追加
3. `.github/workflows/migration-tests.yml` に CI wiring 追加（`bats` 実行行 + `PATHS_REGEX` への当該テスト・スクリプト登録）
4. bats 実行（既存全シナリオへの regression がないことを併せて確認）
5. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）
6. 履歴記録（変更ファイル / レビュー round / 検証結果）

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| pathspec 構文の OS 差（BSD/GNU `git`） | `:(exclude)` magic は git 2.13+ で POSIX 互換。Unit 定義「技術的考慮事項」で BSD/GNU 両対応を確認済み |
| 除外パターンが将来的に拡張ディレクトリに対応できない | `.aidlc/cycles/**/design-artifacts/**` でサイクル番号を `**` で吸収。新規 docs 配置場所で検出が必要な場合は別 Unit で対応 |
| 既存全シナリオ（現時点 5 件）（warning ケース等）が pathspec 追加で再現できなくなる | bats 既存ケースは `mktemp -d` 経由のテンポラリパスで warning 期待を立てている前提。除外対象外の path で fixture を作成すれば従前同様 warning が返るため regression は出ない（設計フェーズで bats 既存ケースの patten を再確認する） |
| 受け入れテスト (b) 実コンフリクト検出維持の path 選択 | tracked 配下では除外パターンに該当しない path を選ぶ（例: `bin/__tmp_conflict_fixture.txt` 等の untracked + tracked テンポラリ）。`mktemp -d` で worktree 外を使うか、対象 worktree 内の除外対象外 path に置くかは設計時に決定 |

## NFR

- **パフォーマンス**: pathspec 1 引数追加。health-check 実行時間に有意な差は生じない
- **可用性**: 既存出力フォーマット（`health-check:conflict-marker:ok:count=N` / `:warning:count=N`）を維持
- **互換性**: pathspec `:(exclude)` 記法は `git grep` の標準サポート、追加依存なし

## 完了条件チェックリスト

### 機能整合

- [ ] `main-repo-health-check.sh:145` の `git grep` に `-- ':(exclude)tests/main-repo-health-check.bats' ':(exclude).aidlc/cycles/**/design-artifacts/**'` が追加されている
- [ ] クリーンな main worktree で health check を実行したとき `health-check:conflict-marker:ok:count=0` が返る（受け入れ基準 1）
- [ ] 既存出力フォーマット（`ok:count=N` / `warning:count=N`）が維持されている

### テスト

- [ ] `tests/main-repo-health-check.bats` に以下 2 種が追加され PASS する:
  - (a) 除外サンプル検証: 除外パス（`tests/main-repo-health-check.bats` 自身および `.aidlc/cycles/**/design-artifacts/**` 配下）に conflict marker が含まれても `ok:count=0` で warning にならない
  - (b) 実コンフリクト検出維持: 除外対象外のテンポラリパス（`mktemp -d` または除外対象外の tracked 経路）に conflict marker を含むファイルを作成すると `warning:count=N` として検出される
- [ ] 既存 BATS 5 シナリオが引き続き PASS（受け入れ基準 2、regression なし）

### CI 実行エントリへの接続（Round 1 codex 指摘 #1 対応）

事実確認: Round 1 検証で `.github/workflows/migration-tests.yml:66` の `bats ...` 実行行に `tests/main-repo-health-check.bats` が含まれていないこと、および `PATHS_REGEX` にも未登録であることを確認した（手動 / ローカル実行のみで CI からは未実行）。本 Unit で CI wiring を追加する。

- [ ] `.github/workflows/migration-tests.yml:66` の `bats` 実行コマンドに `tests/main-repo-health-check.bats` が追加されている
- [ ] `migration-tests.yml:25` の `PATHS_REGEX` に以下 2 つのパターンが追加されている:
  - `tests/main-repo-health-check\.bats`
  - `skills/aidlc/scripts/main-repo-health-check\.sh`
- [ ] PR 差分が上記いずれかの path のみを含む状態で `migration-tests` workflow がトリガされ、新規テスト 2 種を含む全シナリオが PASS することを Phase 2 の検証で確認する（CI 実行ログをレビュー時に参照）

### 履歴

- [ ] `.aidlc/cycles/v2.5.6/history/construction_unit02.md` が新規作成され、変更ファイル一覧 / レビュー round / 検証結果が含まれる

### 品質ゲート

- [ ] AI レビュー（`reviewing-construction-design` / `reviewing-construction-code` / `reviewing-construction-integration`）が完了条件（`is_completed()` 単一仕様: 1R clean 特例または直近 round clean）を満たす
- [ ] Codex レビュー（`codex review --base main`）でも追加指摘なし、または defer 化済み
- [ ] markdownlint（`markdown_lint=true`）が変更対象 markdown ファイル（plan / domain model / logical design / history）で pass する

## 見積もり

- 設計フェーズ: 0.1 日（domain model / logical design / pathspec 評価順整理）
- 実装フェーズ: 0.2 日（pathspec 1 引数 + bats テスト 2 ケース + CI wiring 1 行 + PATHS_REGEX 2 パターン + 既存テスト regression 確認 + レビュー）
- 合計: **0.3 日**（Unit 定義の見積もり 0.25 日に対し CI wiring 追加で +0.05 日、許容範囲内）
