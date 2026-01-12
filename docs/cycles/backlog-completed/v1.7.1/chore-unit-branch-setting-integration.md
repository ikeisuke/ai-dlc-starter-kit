# Unitブランチ設定のconstruction.md統合

- **発見日**: 2026-01-11
- **発見フェーズ**: Construction
- **発見サイクル**: v1.7.0
- **優先度**: 低

## 概要

`docs/aidlc.toml` に `[rules.unit_branch].enabled` 設定を追加したが、`construction.md` でこの設定を参照してブランチ作成提案をスキップするロジックがまだ未実装。

## 詳細

現在、construction.md の「ステップ6: Unitブランチ作成」では毎回ユーザーに確認している。`[rules.unit_branch].enabled = false` の場合は確認をスキップするようプロンプトを修正する必要がある。

## 対応案

1. `construction.md` のステップ6に設定確認ロジックを追加:
   ```bash
   UNIT_BRANCH_ENABLED=$(grep -A1 "^\[rules.unit_branch\]" docs/aidlc.toml 2>/dev/null | grep "enabled" | grep -o "true\|false" || echo "true")
   ```
2. `enabled = false` の場合は確認なしでスキップ
3. テンプレート（`prompts/package/templates/aidlc_toml_template.toml`）にも設定を追加
