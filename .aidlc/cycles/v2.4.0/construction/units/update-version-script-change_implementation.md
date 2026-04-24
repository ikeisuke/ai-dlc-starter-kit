# 実装記録: Unit 002 update-version.sh 挙動変更

## 実装日時

2026-04-23

## 作成ファイル

### ソースコード

- `bin/update-version.sh`（修正） - `.aidlc/config.toml` 書き込み完全廃止、`aidlc_toml_*` 出力削除、`_tmp_toml` / `_bak_toml` 関連処理削除（L138, L142, L145, L147, L151, L161, L163, L178, L181, L185, L192, L197 の 12 箇所）
- `bin/update-version.sh` L108-L120 - `read_starter_kit_version` 残置、コメントで「妥当性検証専用、変数値は出力に使用しない」を明示

### テスト

- `bin/tests/test_update_version_no_toml_write.sh`（新規） - regression テスト 7 ケース 31 アサーション
  - Case 1: dry-run 出力に aidlc_toml_* 行が含まれない
  - Case 2: 成功出力に aidlc_toml: 行が含まれず .aidlc/config.toml が無変更
  - Case 3: .aidlc/config.toml 不在時の error:config-toml-not-found 維持
  - Case 4: メタ開発シナリオ（version.txt=2.4.0, starter_kit_version=2.3.6）で starter_kit_version が保持される
  - Case 5a: error:invalid-config-toml-format（starter_kit_version キー欠落）
  - Case 5b: error:config-toml-read-failed（unreadable, chmod 000、root 環境 skip ロジック付き）
  - Case 5c: error:invalid-config-toml-format（starter_kit_version キー重複）
  - Case 6a: ロールバック整合性（2 段階目 mv 失敗で version.txt 復元）
  - Case 6b: ロールバック整合性（3 段階目 mv 失敗で version.txt + skills/aidlc/version.txt 両方復元）

### 設計ドキュメント

- `.aidlc/cycles/v2.4.0/design-artifacts/domain-models/unit_002_update_version_script_change_domain_model.md`
- `.aidlc/cycles/v2.4.0/design-artifacts/logical-designs/unit_002_update_version_script_change_logical_design.md`

## ビルド結果

成功（bash スクリプトのため明示的なビルドステップなし、構文チェックは bash 実行時に確認、`bash -n` でも syntax pass 確認済み）

## テスト結果

成功

| テストファイル | bash 5.3 | bash 3.2.57 | アサーション数 |
|---------------|----------|-------------|--------------|
| test_update_version_no_toml_write.sh（新規） | PASS | PASS | 31 |
| test_read_starter_kit_version.sh（既存、関連） | PASS | - | 12 |
| test_pr_ops_get_related_issues_empty.sh（Unit 001、関連） | PASS | - | 8 |
| test_operations_release_pr_ready_no_related_issues.sh（Unit 001、関連） | PASS | - | 7 |

**合計**: 新規 31 アサーション PASS、既存 27 アサーション PASS（regression なし）

```text
=== bin/update-version.sh starter_kit_version 上書き廃止テスト ===
[Case 1] dry-run 出力に aidlc_toml_* 行が含まれない → PASS x4
[Case 2] 成功出力に aidlc_toml: 行が含まれず .aidlc/config.toml 無変更 → PASS x5
[Case 3] .aidlc/config.toml 不在時のエラー維持 → PASS x2
[Case 4] メタ開発シナリオ → PASS x3
[Case 5a] invalid-config-toml-format (キー欠落) → PASS x2
[Case 5b] config-toml-read-failed (unreadable) → PASS x2
[Case 5c] invalid-config-toml-format (キー重複) → PASS x2
[Case 6a] ロールバック整合性（2段階目 mv 失敗） → PASS x5
[Case 6b] ロールバック整合性（3段階目 mv 失敗） → PASS x6
PASS: 31 / FAIL: 0
```

## コードレビュー結果

- [x] セキュリティ: OK（ファイルパーミッション・所有権の変更なし、入力エスケープ変更なし）
- [x] コーディング規約: OK（既存スタイル踏襲、アトミック更新パターン維持、bash 3.2 互換）
- [x] エラーハンドリング: OK（既存契約 `config-toml-not-found` / `config-toml-read-failed` / `invalid-config-toml-format` を維持、`config-toml-write-failed` のみ削除）
- [x] テストカバレッジ: OK（出力フォーマット 2 ケース、エラー維持 4 ケース、メタ開発 1 ケース、ロールバック 2 ケース）
- [x] ドキュメント: OK（設計ドキュメントとコード差分が完全一致、計画ファイルとも整合）

AI レビュー: codex 2 反復
- 反復 1: P2×1 指摘（Case 5b が重複キー再検証で rc=2 経路未検証）→ Case 5b を unreadable 検証に差し替え、Case 5c に重複キー分離
- 反復 2: 指摘 0 件、auto_approved 適格

## 技術的な決定事項

1. **`.aidlc/config.toml` 妥当性検証専用残置**: `read_starter_kit_version` 呼び出しを削除せず、コードコメントで「妥当性検証専用、変数値は出力に使用しない」を明示。これにより既存の壊れた config.toml 検出契約（rc=1 / rc=2）を維持
2. **Unit 003 との境界遵守**: `bin/update-version.sh` の先頭ヘッダコメント（L1-L26）は本 Unit で変更せず、Unit 003 へ委譲
3. **ロールバック整合性テスト**: 偽 `mv` スタブパターン（PATH 先頭差し替え）で 2 段階目 / 3 段階目失敗を分離検証。3 段階目失敗（6b）が複数ファイル復元の本質検証
4. **読み取り権限テスト**: `chmod 000` 検証は root 環境では機能しないため `id -u` チェックで skip ロジック追加（既存 `test_read_starter_kit_version.sh:130` 周辺と同パターン）
5. **bash 互換性**: GNU bash 5.3 + macOS `/bin/bash` 3.2.57 両方で全 31 アサーション PASS、bash 4+ 専用構文不使用

## 課題・改善点

なし（Unit スコープは完了。Unit 003 で hidden breaking change 周知、CHANGELOG / docs / rules.md / 先頭ヘッダコメント の追従が実施される）。

## 状態

**完了**

## 備考

- Issue #596 の解消方法: Unit 002（実装側）+ Unit 003（ドキュメント側）両完了後にサイクル PR (#599) マージ時に `Closes #596` で auto-close
- 影響範囲: `bin/update-version.sh` のみ（共通ライブラリ `version.sh`、他のスクリプトは無変更）
- リスクレベル: Medium（hidden breaking change だが repo 内呼び出し元は手順書のみ、外部 / private automation への影響は CHANGELOG 周知で対応）
- メタ開発シナリオ手動確認: `bash bin/update-version.sh --version v9.9.9 --dry-run` を本リポジトリで実行し、`aidlc_toml_*` 行が含まれないことを確認済み（実出力で確認）
