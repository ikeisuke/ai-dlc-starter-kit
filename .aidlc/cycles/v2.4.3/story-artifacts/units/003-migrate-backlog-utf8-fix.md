# Unit: migrate-backlog.sh の UTF-8 対応（#610）

## 概要

`scripts/migrate-backlog.sh` の `generate_slug()` 関数で Perl invocation が UTF-8 を解釈せず、fullwidth カッコ含む日本語タイトルで `tr: Illegal byte sequence` を出して slug 後半が欠落する問題を修正する。Issue #610 本文の修正案（`perl -CSD -Mutf8` の併用）を採用し、3 ケースの動作確認結果を記録する。

## 含まれるユーザーストーリー

- ストーリー 3: migrate-backlog.sh の UTF-8 対応（#610）

## 責務

- `skills/aidlc-setup/scripts/migrate-backlog.sh` の `generate_slug()` 関数の Perl invocation を `-CSD -Mutf8` 化
- 3 ケースの動作確認: `テスト分離の改善（並列テスト対応）` / `SQLite vnode エラー（DB差し替え時の競合アクセス）` / `AgencyConfig DDD責務整理`
- `--dry-run` モードでの同等動作確認
- DEPRECATED マークは維持

## 境界

- `migrate-backlog.sh` 自体の DEPRECATED 解除や全面リライトは対象外
- 削除タイミングの見直しは対象外（必要なら別 Issue 化）
- 他のスクリプトでの UTF-8 / locale 対応は対象外

## 依存関係

### 依存する Unit

- なし

### 外部依存

- Perl 5.x 標準機能（macOS / Linux で利用可能）

## 非機能要件（NFR）

- **パフォーマンス**: 影響なし（Perl 起動オーバーヘッドのみ、変更前後で同等）
- **セキュリティ**: 影響なし
- **スケーラビリティ**: 影響なし
- **可用性**: 環境依存リスクなし（Perl 5.x 標準機能のみ）

## 技術的考慮事項

- 修正は実質 1 行（`perl -pe ...` → `perl -CSD -Mutf8 -pe ...`）
- `-CSD` で IO の UTF-8 化、`-Mutf8` で正規表現リテラルの UTF-8 解釈を併用するのが必須
- macOS / Linux 両環境で動作する Perl 5.x 標準機能のみを使用

## 関連Issue

- #610

## 実装優先度

High

## 見積もり

S（Small）: 1 行修正 + 動作確認 3 ケース。Construction Phase で 1 セッション以内

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
