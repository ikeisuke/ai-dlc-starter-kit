# ユーザーストーリー

## Epic: AI-DLC品質向上と企業利用対応

### ストーリー 1: Construction Phase progress.md更新タイミング修正
**優先順位**: Must-have

As a AI-DLC利用者
I want to Construction PhaseでUnitブランチ使用時にprogress.mdがPR準備完了時点で更新される
So that PRに正確な進捗状態が反映され、レビュー時に正しい状態が確認できる

**受け入れ基準**:
- [ ] Unitブランチ上でUnit完了時の必須作業を実行する際、progress.mdが「完了」（= PR準備完了）に更新される
- [ ] progress.mdの更新がUnit PR作成前のコミットに含まれる
- [ ] Operations Phaseの6.4.5パターンと一貫した「PR準備完了 = 完了」の解釈が適用される
- [ ] Unitブランチを使用しない場合の既存動作に影響がない

**技術的考慮事項**:
- `prompts/package/prompts/construction.md` のUnit完了時の必須作業セクションを修正
- Operations Phase（operations.md ステップ6.4.5）の実装パターンを踏襲

---

### ストーリー 2: フィードバック送信機能のオン/オフ設定
**優先順位**: Must-have

As a 企業内でAI-DLCを利用するチームメンバー
I want to フィードバック送信機能を設定で無効化できる
So that 社内プロジェクトの情報がパブリックリポジトリに誤って投稿されるリスクを防げる

**受け入れ基準**:
- [ ] `docs/aidlc.toml` に `[rules.feedback]` セクションが追加され、`enabled` オプション（デフォルト: `true`）で制御できる
- [ ] `enabled = false` の場合、`aidlc feedback` 実行時に「この機能は無効化されています」と表示され、Issue作成導線（CLIコマンド実行・URL案内）がブロックされる
- [ ] `enabled = true`（デフォルト）の場合、従来どおり `aidlc feedback` でIssue作成導線が表示される
- [ ] 設定読み込みは `read-config.sh` を使用し、個人設定（`aidlc.toml.local`）による上書きが可能である

**技術的考慮事項**:
- `prompts/package/prompts/AGENTS.md` のフィードバック送信セクションに設定読み込みと分岐ロジックを追加
- `prompts/package/aidlc.toml` に `[rules.feedback]` セクションを追加
