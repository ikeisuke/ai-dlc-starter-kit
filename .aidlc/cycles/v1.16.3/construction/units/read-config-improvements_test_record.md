# テスト記録: read-config.sh 改善

## セッション情報

| 項目 | 内容 |
|------|------|
| **対象Unit** | Unit 001: read-config.sh 改善 |
| **テスト実施日** | 2026-02-22 |
| **実施者** | AI (Claude) |
| **環境** | macOS Darwin 25.3.0, Bash, dasel v3.2.2 |
| **ステータス** | 完了 |

---

## テスト項目チェックリスト

### defaults.toml テスト

- [x] TEST-001: defaults.toml に全キーのデフォルト値が定義されている
- [x] TEST-002: --default なしで defaults.toml の値が返る（終了コード0）
- [x] TEST-003: defaults にも project にもないキーは終了コード1
- [x] TEST-004: --default オプションが引き続き動作（後方互換）
- [x] TEST-005: プロジェクト設定が defaults を上書き

### --keys バッチモードテスト

- [x] TEST-006: --keys で複数キー一括取得
- [x] TEST-007: key:value 形式の出力
- [x] TEST-008: 存在しないキーの行は出力されない
- [x] TEST-009: 全キー不在で終了コード1
- [x] TEST-010: 1件以上取得で終了コード0

### 排他・エラーテスト

- [x] TEST-011: 既存の単一キー指定が引き続き動作
- [x] TEST-012: --keys と単一キー同時使用でエラー（終了コード2）
- [x] TEST-013: --keys 後キー0件でエラー（終了コード2）
- [x] TEST-014: 配列値が --keys で正常に1行出力

---

## テスト結果詳細

| テストID | 結果 | 実際の結果 | 備考 |
|----------|------|------------|------|
| TEST-001 | Pass | 22キー全て定義済み（rules.branch.mode は dasel v3 予約語問題あり） | BUG-001 |
| TEST-002 | Pass | `false`, exit 0 | rules.unit_branch.enabled |
| TEST-003 | Pass | 出力なし, exit 1 | 期待通り |
| TEST-004 | Pass | `fallback`, exit 0 | 期待通り |
| TEST-005 | Pass | `required`, exit 0 | defaults:recommend → project:required |
| TEST-006 | Pass | 3行の key:value 出力, exit 0 | 期待通り |
| TEST-007 | Pass | `rules.reviewing.mode:required`, exit 0 | 期待通り |
| TEST-008 | Pass | 2行出力（存在しないキーはスキップ）, exit 0 | 期待通り |
| TEST-009 | Pass | 出力なし, exit 1 | 期待通り |
| TEST-010 | Pass | `rules.reviewing.mode:required`, exit 0 | 期待通り |
| TEST-011 | Pass | `required`, exit 0 | 後方互換OK |
| TEST-012 | Pass | `Error: --keys and positional key are mutually exclusive`, exit 2 | 期待通り |
| TEST-013 | Pass | `Error: --keys requires at least one key`, exit 2 | 期待通り |
| TEST-014 | Pass | `rules.reviewing.tools:['codex']`, exit 0 | 配列値が1行で出力 |

---

## バグレポート

### BUG-001: dasel v3 予約語 'branch' による rules.branch.mode 読み取り失敗

| 項目 | 内容 |
|------|------|
| **重大度** | Medium |
| **バグ種類** | 環境バグ |
| **対応フェーズ** | Construction（実装） |
| **ステータス** | Open |
| **報告日** | 2026-02-22 |
| **バックログ** | Issue #223 |

**再現手順**:
1. `prompts/package/bin/read-config.sh rules.branch.mode` を実行

**期待される動作**:
defaults.toml の `rules.branch.mode` の値 `ask` が返る

**実際の動作**:
dasel v3 で `branch` が予約語のため、パースエラーが発生し exit 2 で終了

**備考**: TEST-001 では dasel 直接呼び出しでキー定義を確認したが、read-config.sh 経由では失敗する。Issue #223 としてバックログに登録済み。

---

## テスト中に発見・修正したバグ

### FIX-001: macOS 非互換の `head -c -1`

| 項目 | 内容 |
|------|------|
| **重大度** | High |
| **バグ種類** | 実装バグ |
| **ステータス** | Fixed |
| **発見日** | 2026-02-22 |
| **解決日** | 2026-02-22 |

**問題**: バッチモード出力で `head -c -1`（末尾1バイト除去）を使用していたが、macOS の `head` は負のバイトカウントを非サポート。
**修正**: Bash文字列操作 `${output_buffer%$'\n'}` に置換。

---

## サマリー

### 結果集計

| 結果 | 件数 |
|------|------|
| Pass | 14 |
| Fail | 0 |
| Blocked | 0 |
| Skipped | 0 |
| **合計** | 14 |

### 合格率

**100%** (14 / 14)

### 発見バグ数

- Critical: 0
- High: 1 (FIX-001: 修正済み)
- Medium: 1 (BUG-001: Issue #223)
- Low: 0
- **合計**: 2

### 所見

全14テスト項目がPassした。テスト中に macOS 非互換バグ（`head -c -1`）を発見・修正した。dasel v3 予約語問題（`rules.branch.mode`）は Issue #223 としてバックログに登録済み。
