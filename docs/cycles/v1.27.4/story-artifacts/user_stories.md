# ユーザーストーリー

## Epic: AI-DLCワークフローの信頼性・安全性向上

### ストーリー 1: migrate-config警告検出のstdout解析移行（#402）
**優先順位**: Must-have

As a AI-DLC利用者
I want to aidlc-setupがmigrate-configの警告をstdout解析で正しく検出すること
So that 終了コード規約変更後もアップグレード時の警告情報を見逃さない

**受け入れ基準**:
- [ ] aidlc-setup.shがmigrate-config.shのstdout出力に`warn:`プレフィックスの行が含まれる場合、`warn:migrate-warnings`を出力する
- [ ] migrate-config.shが警告なしで正常完了（stdout出力に`warn:`なし、exit 0）した場合、警告メッセージを出力しない
- [ ] migrate-config.shが致命的エラーで失敗（exit 1以上）した場合、`error:migrate-failed`を出力する
- [ ] 終了コード2による警告判定ロジックが削除されている

**技術的考慮事項**:
- 編集対象: `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` のStep 5（L370-403）
- migrate-config.shのstdout出力フォーマットを確認し、警告行の検出パターンを決定する

---

### ストーリー 2: バックログ登録時のスコープガード追加（#401）
**優先順位**: Must-have

As a AI-DLC利用者
I want to バックログ登録時にスコープ内の項目が誤ってバックログに外出しされることを防止すること
So that サイクルのスコープ内作業が確実に当該サイクル内で対応される

**受け入れ基準**:

**主対象: 改善提案のバックログ登録ルール（rules.md）**:
- [ ] バックログ登録前に `intent.md` の「含まれるもの」セクションに列挙されたIssue番号・作業項目と照合する手順が追加されている
- [ ] 照合の結果、登録しようとしている項目が「含まれるもの」に該当する場合、バックログに登録せず現サイクル内での対応を指示する記述がある
- [ ] 照合の結果、「含まれるもの」に該当しない場合は従来通りバックログに登録される動作が維持される

**派生対応: Construction Phase 気づき記録フロー**:
- [ ] Construction Phase の気づき記録フロー（`construction.md`）にも、登録前に `intent.md` のスコープを確認する同一の手順が追加されている

**技術的考慮事項**:
- 主対象の編集先: `prompts/package/prompts/common/rules.md` の「改善提案のバックログ登録ルール」セクション（L585〜）
- 派生対応の編集先: `prompts/package/prompts/construction.md` の気づき記録フロー
- プロンプトベースの制約（AIエージェントがルールに従って判定する方式）
- スコープ判定の参照元: `docs/cycles/{{CYCLE}}/requirements/intent.md` の「含まれるもの」セクション

---

### ストーリー 3: semi_autoゲートにレビュー実施済み前提条件を追加（#400）
**優先順位**: Must-have

As a AI-DLC利用者（semi_autoモード使用時）
I want to AIレビュー未実施のまま自動承認されることを防止すること
So that 品質チェックを経ずに次フェーズに遷移するリスクが排除される

**受け入れ基準**:
- [ ] フォールバック条件テーブルに`review_not_executed`条件が優先度0（最優先）で追加されている
- [ ] 該当承認ポイントでAIレビューが未実施の場合、自動承認がブロックされユーザー確認へ遷移する
- [ ] AIレビューが実施済み（指摘0件で合格）の場合、従来通り自動承認が動作する
- [ ] AIレビューに指摘が残っている場合は既存の`review_issues`条件で処理される（新条件との重複なし）
- [ ] `automation_mode=manual`の場合はこの条件に影響されない（従来通りユーザー承認）

**技術的考慮事項**:
- 編集対象: `prompts/package/prompts/common/rules.md` のフォールバック条件テーブル（L429〜）および構造化シグナルスキーマ（L438〜）
- 優先度0は既存の優先度1（error）より高い最優先として追加
