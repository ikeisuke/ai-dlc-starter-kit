# 実装記録: Unit 004 aidlc-setup の starter_kit_version-only 差分 no-op スキップ

## 実装日時

2026-05-09T22:25 〜 2026-05-09T23:30 (JST)

## 作成ファイル

### ソースコード

- `skills/aidlc-setup/scripts/check-noop-upgrade.sh` - no-op 判定スクリプト（Domain 層 NoOpPolicy.decide() 純関数 + Application/Infrastructure 層引数解析・パース。3 行構造化出力 `noop=` / `reason=` / `error=` を返し、exit 0=判定成功 / exit 2=判定失敗）

### テスト

- `skills/aidlc-setup/scripts/tests/test_check_noop_upgrade.sh` - 36 アサーション（4 シナリオ + 引数欠落・形式不一致・不正値・改行/タブ混入サニタイズ）

### ドキュメント改訂

- `skills/aidlc-setup/steps/02-generate-config.md` - ステップ順序を `7.4 → 7.4b → 7.4c (新規 no-op 判定) → 7.3 (条件実行) → 7.5` に変更。`mktemp -d "${TMPDIR:-/tmp}/aidlc-setup.XXXXXXXX"` セッションディレクトリ + `umask 077` でテンポラリファイル受け渡しをセキュア化。`rm -rf` cleanup に三重ガード（非空・ディレクトリ・プレフィックス検証）を追加

### 設計ドキュメント（Phase 1 で作成済 / Phase 2 で更新なし）

- `.aidlc/cycles/v2.6.0/design-artifacts/domain-models/unit_004_aidlc_setup_no_op_skip_domain_model.md`
- `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_004_aidlc_setup_no_op_skip_logical_design.md`

## ビルド結果

成功（bash スクリプトのため明示的なビルドプロセスはなし。shellcheck は警告ゼロ。markdownlint-cli2 は警告ゼロ）

```text
shellcheck skills/aidlc-setup/scripts/check-noop-upgrade.sh
shellcheck skills/aidlc-setup/scripts/tests/test_check_noop_upgrade.sh
→ shellcheck OK

npx markdownlint-cli2 skills/aidlc-setup/steps/02-generate-config.md
→ Linting: 1 file(s) / Summary: 0 error(s)
```

## テスト結果

成功

- 実行テスト数: 36（assert）
- 成功: 36
- 失敗: 0

```text
=== check-noop-upgrade.sh ユニットテスト ===
--- ケース 1: noop=true (no-changes) ---  ... 4 PASS
--- ケース 2: noop=false (migrate-config-changed) ---  ... 6 PASS
--- ケース 3: noop=false (missing-keys-applied) ---  ... 2 PASS
--- ケース 4: 引数不足 / 不正入力 (exit 2 + 3 行構造) ---  ... 24 PASS

=== 結果: PASS=36, FAIL=0 ===
```

## コードレビュー結果

- [x] セキュリティ: OK（Round 2 で出力サニタイズ + rm -rf ガード追加 / Round 3 last_round_clean）
- [x] コーディング規約: OK（`set -euo pipefail` / クォーティング / 行全体アンカー付き正規表現）
- [x] エラーハンドリング: OK（引数欠落・形式不一致・不正値はすべて exit 2 + 3 行 error= 出力）
- [x] テストカバレッジ: OK（4 シナリオ + 異常系 + サニタイズ確認の 36 アサーション）
- [x] ドキュメント: OK（02-generate-config.md にステップ順序・テンポラリディレクトリ契約・cleanup ガード手順を明記）

### AI レビュー履歴（reviewing-construction-code / codex）

| Round | 指摘件数 | 重要度内訳 | 対応 |
|-------|---------|-----------|------|
| Round 1 | 4 件 | 高1 / 中1 / 低2 | 全件修正（temp dir セキュア化 / `--help` 廃止 / 正規表現アンカー / テスト追加） |
| Round 2 | 2 件 | 低2（security） | 全件修正（出力サニタイズ / `rm -rf` 三重ガード） |
| Round 3 | 0 件 | - | `last_round_clean` で完了 |

`automation_mode=semi_auto` + `review_mode=required` + `unresolved_count=0` → `auto_approved`。

### 統合 AI レビュー（codex review --base main）

実施。指摘 0 件で完了。Codex 結論: "I did not find any introduced defects that are clearly actionable and likely to be fixed by the author."

## 技術的な決定事項

1. **テンポラリ媒体の選定**: 設計時点では固定パス (`${TMPDIR:-/tmp}/aidlc-setup-*.txt`) としていたが、コードレビュー Round 1 の高重要度指摘（symlink/race リスク）を受け、`mktemp -d` ベースのセッションディレクトリに変更。AI agent はセッションディレクトリパスを 7.4 / 7.4b / 7.4c の各 Bash 呼び出しでリテラル展開済みの絶対パス文字列として受け渡す
2. **3 行出力契約の防御層**: `--help` 廃止に加え、`sanitize_for_output()` で LF/CR/TAB を `?` に置換 + 200 文字切り詰めを `emit_decision` 経由で全フィールド適用。外部入力越しの 3 行契約破壊を防止
3. **正規表現の厳密化**: `result:` 行の検証を `^result:[A-Za-z0-9-]+:migrated=([0-9]+),skipped=([0-9]+),warnings=([0-9]+)$` の行全体アンカー付き完全一致に変更（前方一致・末尾ゴミ文字・予期せぬ status 値を拒否）
4. **`rm -rf` の三重ガード**: cleanup 時の誤削除を防ぐため `[[ -n ]] && [[ -d ]] && [[ "${TMPDIR:-/tmp}/aidlc-setup."* ]]` の三条件を全て満たした場合のみ削除を実行

## 設計ドキュメントとの差分

設計ドキュメント（domain-model / logical-design）は Phase 1 完了時点での仕様（固定テンポラリパス + `--help` あり）を記録している。Phase 2 のコードレビューによりセキュリティ強化のため以下が更新された:

- 固定パス → `mktemp -d` セッションディレクトリ
- `--help` 廃止
- 正規表現アンカー強化
- 出力サニタイズ追加
- cleanup 三重ガード

これらは契約レベルでの後退を伴わない（noop= / reason= / error= の 3 行構造化出力契約 + exit 0|2 は不変）。設計の本質的責務分離（NoOpPolicy 純関数 / Application/Infrastructure 層分離 / Contract v1 への依存明示）は維持。

## 課題・改善点

- 将来 `migrate-config.sh` の `result:` 行フォーマットが変更される場合、本スクリプトの `_re` パターンと `test_check_noop_upgrade.sh` の契約テストを同 PR 内で同時改訂する。Contract v2 が必要な場合は将来 `--migrate-config-result-version` 引数で明示する案を検討（本 Unit のスコープ外、必要時に Issue 起票）

## 状態

**完了**

## 備考

- 関連 Issue: #618
- 設計の domain-model / logical-design は Phase 1 で確定済（Round 3 last_round_clean）
- レビューサマリ: `.aidlc/cycles/v2.6.0/construction/units/004-review-summary.md`
