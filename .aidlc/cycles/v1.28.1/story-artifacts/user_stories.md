# ユーザーストーリー

## Epic: AI-DLCワークフロー改善

### ストーリー 1: Codex PRレビューのIssue Comment承認検出（#408）
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to Codexボットが独立したIssue Commentで投稿した承認結果も自動検出される
So that PRマージ前のレビュー確認で承認漏れが発生しない

**受け入れ基準**:
- [ ] Codexボットが `@codex review` コメントに👍リアクションした場合、従来通り「承認済み」と判定される
- [ ] Codexボット（`chatgpt-codex-connector[bot]`）が投稿したIssue Commentの本文に承認キーワード（`Didn't find any major issues` 等）が含まれる場合、「承認済み」と判定される
- [ ] Codexボットが投稿したIssue Commentに却下・要修正を示すキーワードが含まれる場合は、承認とは判定されない
- [ ] Codexボット以外のユーザーが同様のコメントを投稿した場合は、承認とは判定されない（`user.login` でフィルタ）
- [ ] リアクション判定（c-3）とIssue Comment判定の両方が存在する場合、いずれかで承認と判定される
- [ ] Issue Comment判定のAPI失敗時は、警告メッセージを表示し、a/b/c判定の結果のみで続行する（c-2リアクション取得失敗と同じ補助判定扱い）

**技術的考慮事項**:
- `rules.md` のc判定ロジックにc-4（Issue Comment判定）を追加
- Codexボットアカウント定数 `chatgpt-codex-connector[bot]` を再利用
- 承認メッセージの正規表現パターンを定義する必要がある

---

### ストーリー 2: Unit実装状態「取り下げ」の追加（#406）
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to Unitの実装状態に「取り下げ」を設定できる
So that スコープ縮小や優先度変更でUnitを取り下げた際に、進捗管理が正確に機能する

**受け入れ基準**:
- [ ] Unit定義テンプレートの実装状態の有効値に「取り下げ」が含まれる
- [ ] Construction Phaseのステップ9（進捗判定）で、「取り下げ」状態のUnitが完了扱いとなる
- [ ] Construction PhaseのUnit選択ロジックで、「取り下げ」状態のUnitが実行対象から除外される
- [ ] Construction Phaseの依存関係判定で、「取り下げ」状態のUnitは依存を解決済みとして扱われる
- [ ] Operations Phaseの全Unit完了確認で、「取り下げ」状態のUnitが完了扱いとなり、全体の完了判定を妨げない
- [ ] Operations Phaseの進捗表示で、「取り下げ」と「完了」が区別して表示される
- [ ] 「未着手」のUnitは従来通りUnit選択で実行対象候補となる
- [ ] 「進行中」のUnitは従来通り優先的に継続対象となる
- [ ] 「完了」のUnitは従来通り依存解決済み・進捗完了扱いとなる

**技術的考慮事項**:
- `prompts/package/prompts/construction.md` の状態定義、Unit選択、依存関係判定を更新
- `prompts/package/prompts/operations.md` の進捗検証、セミオートゲートを更新
- `prompts/package/templates/unit_definition_template.md` の有効値リストを更新
