# テスト記録: シェルスクリプトバグ修正・バリデーション強化

## セッション情報

| 項目 | 内容 |
|------|------|
| **対象Unit** | Unit 001: シェルスクリプトバグ修正・バリデーション強化 |
| **テスト実施日** | 2026-02-19 |
| **実施者** | AI (Claude) |
| **環境** | macOS Darwin 25.2.0, Bash |
| **ステータス** | 完了 |

---

## テスト項目チェックリスト

### check-open-issues.sh テスト

- [x] TEST-001: `--limit` 値未指定時に `error:missing-limit-value` を出力
- [x] TEST-002: `--limit 0` で `error:invalid-limit-value` を出力
- [x] TEST-003: `--limit abc` で `error:invalid-limit-value` を出力
- [x] TEST-004: `--limit -5` で `error:invalid-limit-value` を出力
- [x] TEST-005: `--limit 5` で正常にIssue一覧を取得
- [x] TEST-006: 未知のオプション `--unknown` で `error:unknown-option:--unknown` を出力

### suggest-version.sh テスト

- [x] TEST-007: 正常実行で5行の `key:value` 出力
- [x] TEST-008: `calculate_next_version` patch で正しいバージョン計算
- [x] TEST-009: `calculate_next_version` minor で正しいバージョン計算
- [x] TEST-010: `calculate_next_version` major で正しいバージョン計算
- [x] TEST-011: `calculate_next_version` 不正type で stderr にエラー出力、return 1
- [x] TEST-012: `calculate_next_version` 空バージョンで v1.0.0 を返す

---

## テスト結果詳細

| テストID | 結果 | 実際の結果 | 備考 |
|----------|------|------------|------|
| TEST-001 | Pass | `error:missing-limit-value`, exit 1 | 期待通り |
| TEST-002 | Pass | `error:invalid-limit-value`, exit 1 | 期待通り |
| TEST-003 | Pass | `error:invalid-limit-value`, exit 1 | 期待通り |
| TEST-004 | Pass | `error:invalid-limit-value`, exit 1 | 期待通り |
| TEST-005 | Pass | Issue一覧表示、exit 0 | 期待通り |
| TEST-006 | Pass | `error:unknown-option:--unknown`, exit 1 | 期待通り |
| TEST-007 | Pass | 5行の key:value 出力、exit 0 | 期待通り |
| TEST-008 | Pass | v1.2.3 → v1.2.4 | 期待通り |
| TEST-009 | Pass | v1.2.3 → v1.3.0 | 期待通り |
| TEST-010 | Pass | v1.2.3 → v2.0.0 | 期待通り |
| TEST-011 | Pass | stderr: `error: unknown version type: invalid_type`, return 1 | 期待通り |
| TEST-012 | Pass | v1.0.0 | 期待通り |

---

## サマリー

### 結果集計

| 結果 | 件数 |
|------|------|
| Pass | 12 |
| Fail | 0 |
| Blocked | 0 |
| Skipped | 0 |
| **合計** | 12 |

### 合格率

**100%** (12 / 12)

### 発見バグ数

- Critical: 0
- High: 0
- Medium: 0
- Low: 0
- **合計**: 0

### 所見

全テスト項目がPassした。入力バリデーション（値未指定、不正値）とエラー処理改善（stdout/stderr分離）、default caseの追加が設計通りに動作している。
