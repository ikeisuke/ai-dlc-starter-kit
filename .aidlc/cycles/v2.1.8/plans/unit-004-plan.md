# Unit 004 計画: dasel v3対応

## 概要

`aidlc-setup` のプロンプトファイル内のdaselコマンド例がv2形式のみで記述されており、dasel v3環境で失敗する問題を修正する。

## 対象ファイル

| ファイル | 箇所 | 現状の問題 |
|---------|------|-----------|
| `skills/aidlc-setup/steps/01-detect.md` | 行101: バージョン比較 | `dasel -f .aidlc/config.toml 'starter_kit_version'` がv3で失敗 |
| `skills/aidlc-setup/steps/02-generate-config.md` | 行417: キー追記 | `dasel put -f .aidlc/config.toml -t <type> '<key>' -v '<value>'` がv2のみ |

## 修正方針

- スクリプト（`read-config.sh`, `bootstrap.sh`, `detect-missing-keys.sh`）は既にv2/v3対応済みのため変更しない
- プロンプトファイル内にv2/v3両形式を直接併記し、AIが試行で判定する方式に更新する
- v3では `put` サブコマンドが廃止されているため、書き込みはAI直接編集をフォールバックとして明記する

## 完了条件チェックリスト

- [ ] `01-detect.md` のdaselコマンド例がv2/v3両対応になっている
- [ ] `02-generate-config.md` のdaselコマンド例がv2/v3両対応になっている
- [ ] 既存スクリプト（read-config.sh等）に変更がないこと
- [ ] プロンプト内の説明が正確であること

## 関連Issue

- #528
