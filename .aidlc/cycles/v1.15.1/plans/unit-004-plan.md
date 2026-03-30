# Unit 004 計画: migrate-backlog.sh macOS sed互換性修正

## 概要

`migrate-backlog.sh` の `generate_slug()` 関数で使用している `sed` コマンドの日本語文字範囲指定を `perl -pe` に置換し、macOS（BSD sed）で発生する `RE error: invalid character range` エラーを解消する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/bin/migrate-backlog.sh` | 60行目: `sed` → `perl -pe` に置換 |

## 実装計画

### Phase 1: 設計

このUnitは1行のコマンド置換であり、ドメインモデル・論理設計の対象外。技術的考慮事項のみ整理する。

**技術的判断**:
- `sed 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g'` → `perl -pe 's/[^a-z0-9一-龯ぁ-んァ-ヶー ]//g'`
- `perl` はmacOS / Linux両環境で標準搭載（POSIX準拠環境で広く利用可能）
- Unicode文字範囲はPerlで正しく処理される
- パイプラインの前後（`tr` コマンド）は変更不要
- スクリプト冒頭に `perl` の存在チェック（`command -v perl`）を追加し、未導入時のエラーメッセージを出力する

### Phase 2: 実装

1. `prompts/package/bin/migrate-backlog.sh` 60行目を修正
2. スクリプト冒頭に `perl` 依存チェックを追加
3. テスト: 以下のケースで `generate_slug` の入出力を検証

**テストケース**:

| 入力 | 期待出力 | 検証観点 |
|------|---------|---------|
| `Hello World` | `hello-world` | 英数字・空白 |
| `バックログ移行テスト` | `バックログ移行テスト` | 日本語（ひらがな・カタカナ・漢字） |
| `Feature: 新機能 #123` | `feature-新機能-123` | 英数字・日本語・記号混在 |
| `  複数  空白  ` | `複数-空白` | 空白連続・前後空白 |

## 完了条件チェックリスト

- [ ] `generate_slug()` 関数の `sed` を `perl -pe` に置換
- [ ] `perl` 存在チェックの追加
- [ ] macOS / Linux 両環境での動作確認（上記テストケース）
