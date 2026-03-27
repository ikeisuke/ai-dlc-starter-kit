# Unit 001 計画: サイクルデータ移行

## 概要

`docs/cycles/` → `.aidlc/cycles/` へのサイクルデータ移行。データ自体は既に `.aidlc/cycles/` に存在し、`docs/cycles/` ディレクトリは削除済み。残りは設定ファイル・ドキュメント内のパス参照更新。

## 現状分析

- `docs/cycles/` ディレクトリ: **存在しない**（既に移動済み）
- `.aidlc/cycles/`: v1.0.1〜v2.0.1 の全サイクルデータが存在
- `suggest-version.sh`: 既に `AIDLC_CYCLES` 変数（`.aidlc/cycles`）を使用
- `bootstrap.sh`: `AIDLC_CYCLES` を `.aidlc/cycles` にハードコード済み

## 変更対象ファイル

| ファイル | 行 | 変更内容 |
|---------|-----|---------|
| `.aidlc/config.toml` | 19 | `cycles_dir = "docs/cycles"` → `cycles_dir = ".aidlc/cycles"` |
| `skills/reviewing-inception/SKILL.md` | 52 | `docs/cycles/{{CYCLE}}/inception/decisions.md` → `.aidlc/cycles/...` |
| `skills/aidlc/config/config.toml.example` | 123-124 | コメント内の `docs/cycles/` → `.aidlc/cycles/` |
| `skills/aidlc/templates/index.md` | 116 | `docs/cycles/{{CYCLE}}/operations/tasks/` → `.aidlc/cycles/...` |
| `skills/aidlc/scripts/write-history.sh` | 91 | コメント例の `docs/cycles/` → `.aidlc/cycles/` |

## 実装計画

1. 上記5ファイルの `docs/cycles` パス参照を `.aidlc/cycles` に更新
2. grep で残留参照がないことを確認（`.aidlc/cycles/` 内の履歴データは除外）

## 完了条件チェックリスト

- [ ] `.aidlc/config.toml` の `cycles_dir` が `.aidlc/cycles` に更新されている
- [ ] `suggest-version.sh` 等のスクリプトが `.aidlc/cycles` を参照している（確認のみ、既に対応済み）
- [ ] `docs/cycles/` ディレクトリが存在しない（確認のみ、既に削除済み）
- [ ] スキル・テンプレート内の `docs/cycles` 参照が `.aidlc/cycles` に更新されている
- [ ] 移行フロー文書（`03-migrate.md`）が v2 パスを使用している（確認のみ、既に対応済み）
