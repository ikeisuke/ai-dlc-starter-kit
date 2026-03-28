# Construction Phase 履歴: Unit 03

## 2026-03-28T19:05:42+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-remove-v1-legacy（v1残存コード削除）
- **ステップ**: Unit完了
- **実行内容**: Unit 003 完了: v1残存コード削除

実施内容:
- aidlc-setup.sh: rsync同期処理・SYNC_DIRS/SYNC_FILES・_has_file_diff()・--no-syncオプション削除
- aidlc-setup.sh: resolve_starter_kit_root() 簡略化（ghqフォールバック削除、SCRIPT_DIRベース＋環境変数のみ）
- config.toml: [paths].setup_prompt 削除
- operations/04-completion.md: setup_prompt読み取りロジックを/aidlc setup直参照に変更
- setup/02-generate-config.md: setup_prompt生成セクション（7.2.1）削除
- aidlc-setup/SKILL.md: sync_*出力仕様・ghq:パス参照削除
- prompts/setup-prompt.md: v1互換コードブロック削除
- aidlc.toml.template: setup_promptプレースホルダー削除

AIレビュー完了（codex）:
- 対象タイミング: 統合とレビュー
- 指摘3件（全て偽陽性と判定）
  - #1（高）: パス解決の問題 → プラグインモデルのSCRIPT_DIR解決で正常動作
  - #2（中）: docs/aidlc/の残存参照 → デプロイコピーはOperations Phase同期
  - #3（中）: sync_*残存 → 02-generate-config.mdのsyncはsync-package.sh（別スクリプト）
- **成果物**:
  - `.aidlc/cycles/v2.0.4/plans/unit-003-plan.md`
  - `.aidlc/cycles/v2.0.4/design-artifacts/domain-models/remove-v1-legacy_domain_model.md`
  - `.aidlc/cycles/v2.0.4/design-artifacts/logical-designs/remove-v1-legacy_logical_design.md`

---
