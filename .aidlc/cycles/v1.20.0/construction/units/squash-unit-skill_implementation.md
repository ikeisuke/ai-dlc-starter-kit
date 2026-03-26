# 実装記録: squash-unit スキル定義

## 変更ファイル

### 新規作成
- `prompts/package/skills/squash-unit/SKILL.md`: スキル定義
- `docs/aidlc/skills/squash-unit/SKILL.md`: rsync同期先コピー
- `.claude/skills/squash-unit`: シンボリックリンク（→ `../../docs/aidlc/skills/squash-unit`）

### 変更
- `prompts/package/prompts/common/commit-flow.md`: Squash統合フローセクションにスキル呼び出し推奨を追記

## 実装内容

### SKILL.md

- YAML front matter: `name`, `description`, `argument-hint` を定義
- 引数自動解決手順: `--cycle`（ブランチ名）、`--unit`（Unit番号、Inception時省略）、`--vcs`（`rules.jj.enabled`）、`--base`（コミット履歴）、`--message-file`（Writeツール）
- 実行フロー: dry-run → 確認 → メッセージファイル作成 → squash実行 → 削除・確認
- Unit完了/Inception Phase完了の2パターンを全ステップに記載
- retroactiveモード: `--retroactive --from --to` の使い方
- エラーハンドリング: 出力パターン別対応表
- セキュリティ: `$()` 不使用、`--message-file` 経由のメッセージ渡し

### commit-flow.md

- Squash統合フローセクションの先頭にblockquoteで `/squash-unit` スキル呼び出し推奨を追記
- 既存の直接呼び出しフローは完全維持（フォールバック用）

## 技術的決定

1. **VCS判定**: `rules.jj.enabled` を使用（`rules.vcs.type` は存在しない。既存フローとの整合性を維持）
2. **エラーコード**: `squash-unit.sh` 実装の `dirty-working-tree` に合わせた（ハイフン区切り）
3. **unit省略**: Inception Phase完了squashでは `--unit` を省略（`squash-unit.sh` の仕様に準拠）
