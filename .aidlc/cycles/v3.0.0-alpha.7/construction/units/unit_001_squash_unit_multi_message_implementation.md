# 実装記録: Unit 001 squash-unit.sh 複数 --message 段落結合修正（#735）

## 実装日時
2026-06-28（Construction Phase / v3.0.0-alpha.7）

## 作成ファイル

### ソースコード
- `skills/aidlc/scripts/squash-unit.sh` - 変更:
  - `parse_args` の `--message` ハンドラを後勝ち上書きから段落結合（`git commit -m` 準拠）に変更
  - `normalize_coauthor_key`（新規）: Co-Authored-By 行を dedup 比較キーに正規化する純関数（行 trim / トレーラ名 case-insensitive / コロン後空白畳み / 値部 trim、bash 3.2 互換で `tr` 使用）
  - `compose_full_message`（新規）: message + co_authors の唯一の合成点。message 側既出 + co_authors 内部重複を排除、stdout 末尾改行なし、純関数
  - `squash_git` / `build_commit_message_file`: 連結ロジックを `compose_full_message` 委譲に統一
  - `show_help`: `--message` 説明を複数指定（段落結合）対応に更新

### テスト
- `bin/tests/squash-unit/message_compose.bats` - 新規（bats / 14 ケース）:
  - 統合: 複数 --message 段落結合 / Co-Authored-By 二重出力なし（#735 再現）/ 単一 message 後方互換 / retroactive 実 CLI 経路
  - 純関数: compose_full_message の dedup（完全一致 / case 差 / コロン後空白差 / co_authors 内部重複）/ 空 / 全既出 / 末尾改行なし契約
  - build_commit_message_file 直接（retroactive 二重付与なし / 空 co_authors）

### 設計ドキュメント
- `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/domain-models/unit_001_squash_unit_multi_message_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/logical-designs/unit_001_squash_unit_multi_message_logical_design.md`

## ビルド結果
成功（bash 構文チェック `bash -n` OK / shellcheck 新規関数に警告なし、既存箇所の SC2034/SC1083 は変更外）

## テスト結果
成功

- 実行テスト数: 14（新規 message_compose.bats）+ 28（既存 internal_ci_checks 回帰）
- 成功: 42
- 失敗: 0

```text
bats bin/tests/squash-unit/ → 全パス
check-test-isolation → no violations
check-bash-substitution → no violations
```

## コードレビュー結果
- [x] セキュリティ: OK（CLI ツール・ネットワークなしで OWASP/HTTP/NW は N/A。glob 文字 dedup 誤爆なしを codex 実機検証）
- [x] コーディング規約: OK（bash 3.2 互換 / `set -euo pipefail` 整合）
- [x] エラーハンドリング: OK（既存トークン・終了コード不変）
- [x] テストカバレッジ: OK（通常・retroactive・純関数を網羅、14 ケース）
- [x] ドキュメント: OK（設計と実装一致 / help 更新）

## 技術的な決定事項
- `--message-file` 新設ではなく段落結合方針を採用（Unit 境界の決定）
- 通常・retroactive の 2 連結経路を `compose_full_message` 1 ヶ所に収束（DRY / 経路間挙動差の排除）
- dedup は正規化キー（case/空白差吸収）+ 出力原文保持。`seen` 蓄積で co_authors 内部重複も一意化
- テスト配置を Unit 責務記載の `skills/aidlc/scripts/tests/` から `bin/tests/squash-unit/`（確立済み・実行可能な bats 配置）へ補正（計画承認時に提示）

## 課題・改善点
- #740（OUT_OF_SCOPE / defer）: `find_unit_commit_range_git` の `--from/--to` 経路がルートコミット `--from` で失敗する既存不整合（`safe_log_range` 未使用）。Unit 001 スコープ外のためバックログ化

## 状態
**完了**

## 備考
- 関連: Closes #735（クローズはサイクル PR で実施）
- defer 起票: #740（backlog / type:defer-from-review）
