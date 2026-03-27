# 論理設計: サイクルデータ移行

## 概要

設定ファイル・ドキュメント内の `docs/cycles` パス参照を `.aidlc/cycles` に更新する。

## アーキテクチャパターン

単純なテキスト置換。アーキテクチャパターンは不要。

## コンポーネント構成

変更対象は5ファイル。新規コンポーネントの作成なし。

## 変更対象と置換ルール

| # | ファイル | 置換前 | 置換後 | 種別 |
|---|---------|--------|--------|------|
| 1 | `.aidlc/config.toml` | `cycles_dir = "docs/cycles"` | `cycles_dir = ".aidlc/cycles"` | 設定値 |
| 2 | `skills/reviewing-inception/SKILL.md` | `docs/cycles/{{CYCLE}}/inception/decisions.md` | `.aidlc/cycles/{{CYCLE}}/inception/decisions.md` | ドキュメント参照 |
| 3 | `skills/aidlc/config/config.toml.example` | `docs/cycles/vX.X.X/` / `docs/cycles/[name]/vX.X.X/` | `.aidlc/cycles/...` | コメント |
| 4 | `skills/aidlc/templates/index.md` | `docs/cycles/{{CYCLE}}/operations/tasks/` | `.aidlc/cycles/{{CYCLE}}/operations/tasks/` | テンプレート参照 |
| 5 | `skills/aidlc/scripts/write-history.sh` | `docs/cycles/v1.8.0/history/` | `.aidlc/cycles/v1.8.0/history/` | コメント例 |

## 処理フロー

1. 5ファイルの該当箇所を `docs/cycles` → `.aidlc/cycles` に置換
2. `grep -r "docs/cycles"` でスキル・スクリプト内の残留参照を確認（`.aidlc/cycles/` 内の履歴は除外）
3. 確認完了

## 非機能要件（NFR）への対応

全て N/A（テキスト置換のみ）

## 実装上の注意事項

- `.aidlc/cycles/` 内の履歴データ（過去のサイクル記録）に含まれる `docs/cycles` 参照は更新対象外（歴史的記録として保持）
- `CHANGELOG.md` 内の過去バージョン記録も更新対象外
