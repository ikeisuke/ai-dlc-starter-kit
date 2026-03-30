# ユーザーストーリー

## Epic: AI-DLC品質向上と企業利用対応

### ストーリー 1: Construction Phase progress.md更新タイミング修正
**優先順位**: Must-have

As a AI-DLC利用者
I want to Construction PhaseでUnitブランチ使用時にprogress.mdがPR準備完了時点で更新される
So that PRに正確な進捗状態が反映され、レビュー時に正しい状態が確認できる

**受け入れ基準**:
- [ ] Unit完了時の必須作業セクション内で、PR作成ステップの前にprogress.md更新ステップが配置される
- [ ] progress.md更新ステップでは、該当Unitのステータスを「完了」（= PR準備完了）に変更し、完了日を記録する
- [ ] progress.mdの更新がUnit PR作成前のGitコミットに含まれる（`git log` でPR作成コミットより前に確認可能）
- [ ] progress.mdでの「完了」は「PR準備完了」を意味する旨の注意書きがプロンプトに記載される（Operations Phase operations.md ステップ6.4.5と同一の解釈）
- [ ] Unitブランチを使用しない場合の既存動作に影響がない（変更はUnitブランチフロー内のみ）

**技術的考慮事項**:
- `prompts/package/prompts/construction.md` のUnit完了時の必須作業セクションを修正
- Operations Phase（operations.md ステップ6.4.5）は参照のみ。同時改修は不要

---

### ストーリー 2: フィードバック送信機能のオン/オフ設定
**優先順位**: Must-have

As a 企業内でAI-DLCを利用するチームメンバー
I want to フィードバック送信機能を設定で無効化できる
So that 社内プロジェクトの情報がパブリックリポジトリに誤って投稿されるリスクを防げる

**受け入れ基準**:
- [ ] `docs/aidlc.toml` に `[rules.feedback]` セクションが追加され、`enabled` オプション（デフォルト: `true`）で制御できる
- [ ] `enabled = false` の場合、`aidlc feedback` 実行時に「この機能は無効化されています」とテキスト表示され、`gh issue create` コマンドの実行およびURL案内の表示が行われない
- [ ] `enabled = false` の場合、代替行動（社内窓口リンク等）の表示はしない（メッセージのみ）
- [ ] `enabled = true`（デフォルト）の場合、従来どおり `aidlc feedback` でIssue作成導線が表示される（GitHub CLI経由またはURL案内）
- [ ] 設定未定義時は `true`（有効）として動作する（`read-config.sh --default "true"` を使用）
- [ ] 不正値（`true`/`false` 以外）の場合は `true`（有効）として動作する（デフォルト有効の設計方針に従い、明示的に `false` と設定した場合のみ無効化）
- [ ] 個人設定（`aidlc.toml.local`）による上書きが可能（既存の `read-config.sh` マージルール: local > base に従う）

**技術的考慮事項**:
- `prompts/package/prompts/AGENTS.md` のフィードバック送信セクションに設定読み込みと分岐ロジックを追加
- `prompts/setup/templates/aidlc.toml.template` に `[rules.feedback]` セクションを追加
- 設定読み込みは `docs/aidlc/bin/read-config.sh rules.feedback.enabled --default "true"` を使用
