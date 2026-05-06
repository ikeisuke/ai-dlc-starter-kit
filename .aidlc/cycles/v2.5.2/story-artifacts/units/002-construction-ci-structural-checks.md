# Unit: Construction Unit 完了時 CI 構造チェック強化

## 概要

`bin/check-test-isolation.sh` を新規作成して BATS テストの cwd 依存パターンを静的解析で検出し、`scripts/squash-unit.sh` 経由で Unit 完了時に check-skill-references / check-bash-substitution / check-test-isolation の 3 種を必須実行する。violation 検出時は Unit 完了が exit 1 でブロックされる。CI ワークフロー（`.github/workflows/skill-reference-check.yml`）にも 3 種チェックを統合し、PR 単位で同チェックが実行される。

## 含まれるユーザーストーリー

- ストーリー 2: Construction Unit 完了時 CI 構造チェック強化

## 責務

- `bin/check-test-isolation.sh` の新規作成
  - 検査対象関数: BATS の `teardown` / `teardown_file` / `setup` / `setup_file` / `@test`
  - ガード判定の厳密ルール: 同一関数内で `rm -rf` の前に `cd "$BATS_TMPDIR"` / `cd "$BATS_TEST_TMPDIR"` / `cd "$BATS_FILE_TMPDIR"` / `cd "$TMP"` / `cd "$(mktemp -d ...)"` のいずれかが先行していること
  - 致命パターン: `rm -rf "$REPO_ROOT"` / `rm -rf .aidlc/...` / `rm -rf "$(pwd)"` / `rm -rf $HOME/...` を `severity:fatal` として検出
  - violation 出力: exit 1 + stderr に `error\t<check_name>\t<file>:<line>\t<reason>` 形式で 1 件 1 行
  - **既存違反の allowlist 機構（出口条件付き）**: `bin/check-test-isolation.allowlist` を新規作成し、本 Unit 開始時点で既存違反として記録されているファイル/関数を一時隔離する。
    - **allowlist エントリ必須メタ情報**: 各エントリは TSV 形式で `file_path<TAB>function_name<TAB>reason<TAB>added_date<TAB>tracking_issue<TAB>expiry_date` の 6 列を必須とする。`reason` は照合キーの一部として扱い、過剰マッチを防止
    - **照合ルール**: 違反検出時は `file_path + function_name + reason` の 3 つ組で完全一致したエントリのみ allowlist 扱いとして warn 継続。一部一致は allowlist として扱わず、新規違反として exit 1
    - **CI ガード**: `bin/check-test-isolation.sh` 実行時に allowlist の以下 2 ケースを fail（exit 1）:
      - **期限切れ**: `expiry_date` が現在日を過ぎている entry（タイムリーに更新されていない陳腐 entry を放置しない）
      - **stale エントリ**: 対象ファイル/関数が既に存在しない、または `rm -rf` を含まなくなっている（実体のない陳腐 entry を放置しない）
    - **新規違反の扱い**: allowlist 外の新規違反は exit 1 でブロック（既存通り）
- `scripts/squash-unit.sh` への 3 種チェック組み込み（必須実行、violation 検出時は Unit 完了をブロック）
- `.github/workflows/skill-reference-check.yml` への check-bash-substitution / check-test-isolation 統合
- `bin/tests/check-test-isolation/` 配下に最小 3 ケースの BATS テスト（ガードあり / ガードなし / 致命パターン）
- 本 Unit 完了直前までに **allowlist の作成**（既存違反の一時隔離）。**allowlist 内違反の段階解消は別 Issue として切り出し**、後続サイクルで対応する

## 境界

- BATS 以外のテストフレームワーク対応は本 Unit のスコープ外
- 関数スコープを完全に解析する高度な静的解析（変数追跡、関数間呼び出し追跡）は不要。1 関数内のテキストレベル解析で十分
- CI ワークフローのリネームや構造変更は行わない（既存 `skill-reference-check.yml` への統合のみ）
- **allowlist 内の既存違反の段階解消は本 Unit のスコープ外**（後続サイクルの別 Unit として分離。allowlist 作成までが本 Unit のクリティカルパス）
- 暫定回避フラグ（CI スキップ等）は追加しない（allowlist は既存違反の一時隔離であり、CI のスキップとは異なる）

## 依存関係

### 依存する Unit

- 001-review-flow-5r-and-defer-automation（**soft dependency / レビュー運用前提**: 成果物依存ではなく運用ルール依存。本 Unit の review が 5R 化された review-flow に従うために必要。**実装着手は Unit 001 完了を待たずに開始可能**。レビュー実施時点で Unit 001 が完了している必要がある）

### 外部依存

- `awk`（BATS 関数のスコープ判定）
- `bash` 4+
- GitHub Actions runner 環境（`.github/workflows/skill-reference-check.yml` の実行環境として）

## 非機能要件（NFR）

- **パフォーマンス**: `check-test-isolation.sh` の実行時間は既存 BATS テスト数（数十件規模）で 1 秒以内を目安とする
- **セキュリティ**: 検査スクリプト自体が `rm -rf` 等の破壊的コマンドを実行しないこと（読み取り専用解析）
- **スケーラビリティ**: BATS テスト数の増加に対して O(N) で線形にスケール
- **可用性**: CI 環境で `awk` が利用できることを前提（GitHub Actions の Ubuntu runner に標準搭載）

## 技術的考慮事項

- 関数スコープ判定は `awk` で `function foo() {` から対応する `}` までを 1 関数として識別する実装を想定（多階層 `{}` のネストはマッチング深度カウンタで管理）
- 本 Unit の Unit 完了時点から自身の violation 検出が有効化されるため、Unit 完了直前に既存 BATS の cwd 依存検証を必ず完了させる
- 既存 PR への影響: 違反がない状態を本 Unit 内で確保することで CI 失敗増を抑制する
- check-test-isolation.sh 自体が `bin/check-bash-substitution.sh` の対象になる可能性があるため、`$()` を使わない実装が必要（`.aidlc/rules.md` のコーディング規約に従う）

## 関連Issue

- #636（Construction Unit 完了時の CI 構造チェック強化（skill-references / bash-substitution / test-isolation））

## 実装優先度

High（本 Unit 完了は後続 Unit C/D の Unit 完了時 CI 構造チェック発動のトリガー）

## 見積もり

中〜大（新規スクリプト + 既存 squash-unit.sh への組み込み + CI ワークフロー統合 + 既存 BATS の事前検証・修正）。1 〜 2 日。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
