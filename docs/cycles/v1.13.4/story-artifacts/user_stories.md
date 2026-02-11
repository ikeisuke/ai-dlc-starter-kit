# ユーザーストーリー

## Epic: AIレビュースキルの改善・安定化

### ストーリー 1: Codex skillsのシンボリックリンク配置（#177）
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to セットアップ実行後にCodex CLIの `~/.codex/skills/` にAI-DLCスキルが自動配置される
So that Codex CLIからAI-DLCのレビュースキルを利用できる

**受け入れ基準**:
- [ ] セットアップスクリプト実行後、`~/.codex/skills/` ディレクトリが作成される
- [ ] `~/.codex/skills/codex-review` が `docs/aidlc/skills/codex-review` へのシンボリックリンクとして存在する
- [ ] `ls -la ~/.codex/skills/` でリンク先が正しいことを確認できる
- [ ] 既存の `.claude/skills/` へのシンボリックリンク配置は維持される
- [ ] 2回目以降のセットアップ実行時、既存リンクが正しければスキップされる

**技術的考慮事項**:
- `prompts/package/bin/setup-ai-tools.sh` を編集（メタ開発ルール）
- Codex CLIがインストールされていない環境でもエラーにならないこと

---

### ストーリー 2: Codex skills compatibilityフィールド追加（#178）
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to Codex skillsのSKILL.mdにサンドボックス要件が記載されている
So that Codex CLI利用時に必要なサンドボックス設定が明確にわかる

**受け入れ基準**:
- [ ] `codex-review/SKILL.md` のメタデータにcompatibilityフィールドが追加される
- [ ] compatibilityフィールドにネットワークアクセス要件が明記される
- [ ] フィールドの文字数が500文字以内（Codex仕様の上限）
- [ ] Agent Skills Specificationに準拠した形式で記載される

**技術的考慮事項**:
- `prompts/package/skills/codex-review/SKILL.md` を編集（メタ開発ルール）
- compatibilityフィールドはドキュメント用途のみ（ランタイムでの強制なし）

---

### ストーリー 3: claude-reviewスキルの不安定動作調査・修正（#179）
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to claude-reviewスキルが安定してレビュー結果を返す
So that AIレビューフローが中断せず信頼性高く運用できる

**受け入れ基準**:
- [ ] レスポンス未返却の原因が特定され、調査結果が文書化される
- [ ] 指摘が二転三転する原因が特定され、調査結果が文書化される
- [ ] 再現手順が確立される
- [ ] 実施可能な対策が実装される、またはワークアラウンドがSKILL.mdに明文化される
- [ ] 修正後、3回連続でレビュー実行が正常完了することを手動確認できる

**技術的考慮事項**:
- `prompts/package/skills/claude-review/SKILL.md` を編集（メタ開発ルール）
- 外部要因（モデル側の問題）の場合はワークアラウンド明文化を成果物とする
- `claude -p` コマンドの出力形式やタイムアウト設定を調査
