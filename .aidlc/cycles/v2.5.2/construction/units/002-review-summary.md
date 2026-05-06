# レビューサマリ: Unit 002 Construction CI 構造チェック強化

## 基本情報

- **サイクル**: v2.5.2
- **フェーズ**: Construction
- **対象**: Unit 002（Construction Unit 完了時 CI 構造チェック強化）

---

## Set 1: 2026-05-06 設計レビュー

- **レビュー種別**: ConstructionDesignReview
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘対応判断完了（全件修正済み）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `squash-unit.sh` の組み込み方式不整合 - 計画は cwd 相対 `bash bin/...`、論理設計は cwd 非依存。既存 squash-unit.sh は script dir 起点 | 修正済み（パス解決ポリシーを「常に script dir から repo root を解決した絶対パスで実行」に統一、cwd 非依存を明記） | - |
| 2 | 高 | 致命パターン優先と allowlist 橋渡し - 「allowlist 一致は warn 化」と「fatal は allowlist 対象外」が文言衝突 | 修正済み（「allowlist 一致で warn 化（ただし fatal は常に非許可・exit 1）」へ修正、判定順序を Fatal→Allowlist→残 violation の IF 契約として固定） | - |
| 3 | 高 | `AllowlistRepository` fail-open - 不正フォーマット行は warn + スキップで違反隠蔽リスク | 修正済み（fail-closed: 1 行でも不正なら即 exit 1、部分スキップ禁止） | - |
| 4 | 中 | エラー出力フォーマット揺れ - 通常 violation 4 カラム vs `awk-not-found` 例で `file:line` 欠落 | 修正済み（4 カラム TSV `error\t{check}\t{file_or_system_id}:{line_or_0}\t{reason}` に統一） | - |
| 5 | 中 | PATHS_REGEX に `tests/**/*.bats` 不在 - 実検査対象の変更が workflow をトリガーしない | 修正済み（PATHS_REGEX に `tests/.*\.bats` を追加） | - |
| 6 | 中 | `$()` 禁止の前提不正確 - 現行 check-bash-substitution.sh は `bin/*.sh` 対象外 | 修正済み（「現行ルール上は対象外」と明記、強制制約を撤廃） | - |
| 7 | 高 (Round 2) | ユースケース 2 で `bash bin/...` 相対表記が残存 | 修正済み（`bash "${REPO_ROOT}/bin/..."` に統一、前提として REPO_ROOT を script dir 起点で解決する旨を明記） | - |

### Round 4 新領域判定

本レビューは Round 3 で完了（指摘 0 件）したため発生していない。

```json
{
  "K_old": [],
  "K_new": [],
  "K_diff": [],
  "rounds_executed": 3
}
```

---

## Set 2: 2026-05-06 コードレビュー（実装後）

- **レビュー種別**: ConstructionCodeReview
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘対応判断完了（全件修正済み）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `skills/aidlc/scripts/squash-unit.sh` の 3 種チェックが `-x` 条件付きで fail-open | 修正済み（`-x` ガード削除、ファイル不在で即 exit 1、必須実行化） | - |
| 2 | 高 | allowlist stale 判定が雑（function 単位を見ていない） | 修正済み（current_violations TSV と照合し、対応 violation がもう検出されない entry を stale として exit 1） | - |
| 3 | 高 | allowlist パースが緩い（6 列厳密検証 + 妥当日付検証） | 修正済み（awk で列数 6 を強制、is_valid_date() で月/日範囲チェック） | - |
| 4 | 中 | parse 失敗の fail-closed が機能していない | 修正済み（awk 内で関数末尾未閉鎖を PARSE_ERROR として検出。なお awk の括弧カウントは文字列リテラル内も含むため info レベルとして扱い、真の awk parse 失敗のみ fail-closed） | - |
| 5 | 中 | 一時ファイルが mktemp 未使用（`/tmp/check-test-isolation-$$-...` 固定名） | 修正済み（mktemp -d で一時ディレクトリ作成、trap で確実削除） | - |
| 6 | 中 | 受け入れ基準網羅 BATS 不足 | 修正済み（`bin/tests/check-test-isolation/end_to_end_test.bats` 新規作成、E2E 8 ケース pass: ガードあり/なし/致命/4 カラム TSV/malformed/期限切れ/致命+allowlist/不正日付） | - |
| 7 | 高 (Round 2) | allowlist stale 判定のタブエスケープが文字列のまま | 修正済み（printf で実タブ生成、`grep -F -x -q --` で照合） | - |

### Round 4 新領域判定

本レビューは Round 3 で完了（指摘 0 件）したため発生していない。

```json
{
  "K_old": [],
  "K_new": [],
  "K_diff": [],
  "rounds_executed": 3
}
```

---

## Set 3: 2026-05-06 統合レビュー

- **レビュー種別**: ConstructionIntegrationReview
- **使用ツール**: codex
- **反復回数**: 1
- **結論**: 指摘 0 件 (1R clean 特例適用、全項目達成)

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| - | - | 指摘 0 件 | - | - |

### 確認内容

- 設計乖離なし
- レビュー / テスト実施: 設計レビュー Round 3 / コードレビュー Round 3 (いずれも 0 件)、3 種 CI チェック clean、BATS 197 件全 pass
- 完了条件チェックリスト全項目達成
- ストーリー 2 受け入れ基準網羅: 検査対象関数、厳密ガード判定、fatal 検出、4 カラム TSV 出力、Unit 完了ブロック、PR 時 3 チェック、最小 3 ケース BATS、既存違反なし、CI スキップ系フラグ未導入

### Round 4 新領域判定

```json
{
  "K_old": [],
  "K_new": [],
  "K_diff": [],
  "rounds_executed": 1
}
```

---
