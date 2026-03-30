# Unit 006: Dependabot PR確認オプション - 計画

## 概要

Inception PhaseでのDependabot PR確認機能をオプション化し、必要なプロジェクトでのみ有効にできるようにする。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/aidlc.toml` | `[inception.dependabot]` セクション追加 |
| `prompts/package/prompts/inception.md` | 設定チェックロジック追加 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 設定構造とオプション動作の定義
2. **論理設計**: inception.mdへの条件分岐追加方法の設計

### Phase 2: 実装

1. **aidlc.toml更新**: `[inception.dependabot]` セクション追加
   - `enabled = false` (デフォルト)
2. **inception.md更新**: 「13. Dependabot PR確認」セクションに設定チェックを追加
   - `[inception.dependabot].enabled = true` の場合のみ実行
   - 未設定または `false` の場合はスキップ

## 完了条件チェックリスト

- [ ] aidlc.tomlに`[inception.dependabot].enabled`設定を追加
- [ ] 設定に基づくDependabot PR確認の有効/無効切り替え
- [ ] 既存のcheck-dependabot-prs.shスクリプトとの連携

## 技術的考慮事項

- デフォルトは `false`（既存の挙動を維持 → 確認しない）
- 既存の `check-dependabot-prs.sh` スクリプトをそのまま活用
- 他の設定（`gh:available` 等）との組み合わせを考慮

## 見積もり

小規模（設定追加 + 条件分岐追加）
