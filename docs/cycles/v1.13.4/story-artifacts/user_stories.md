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
So that Codex CLI利用時に必要なサンドボックス設定が事前にわかり、設定ミスによるレビュー失敗を回避できる

**受け入れ基準**:
- [ ] `codex-review/SKILL.md` のメタデータにcompatibilityフィールドが追加される
- [ ] compatibilityフィールドにネットワークアクセス要件が明記される
- [ ] フィールドの文字数が500文字以内（Codex仕様の上限）
- [ ] [Agent Skills Specification v1.0](https://agentskills.io/specification) のcompatibilityフィールド定義に準拠した形式で記載される

**技術的考慮事項**:
- `prompts/package/skills/codex-review/SKILL.md` を編集（メタ開発ルール）
- compatibilityフィールドはドキュメント用途のみ（ランタイムでの強制なし）

---

### ストーリー 3: claude-reviewスキル不安定動作の調査（#179-調査）
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to claude-reviewスキルの不安定動作の原因が特定・文書化されている
So that 不安定動作への対処方針が明確になる

**受け入れ基準**:
- [ ] レスポンス未返却の原因が特定され、調査結果が `docs/cycles/v1.13.4/design-artifacts/` に文書化される
- [ ] 指摘が二転三転する原因が特定され、同ファイルに文書化される
- [ ] 各症状の再現手順（実行コマンド、期待する動作、実際の動作）が同ファイルに含まれる
- [ ] 原因が「スキル設定の問題」「CLIの問題」「モデル側の問題」のいずれかに分類される

**技術的考慮事項**:
- `claude -p` コマンドの出力形式やタイムアウト設定を調査
- `--output-format stream-json` オプションの効果を検証

---

### ストーリー 4: claude-reviewスキルの対策実装（#179-対策）
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to claude-reviewスキルが安定してレビュー結果を返す
So that AIレビューフローが中断せず信頼性高く運用できる

**受け入れ基準**:
- [ ] ストーリー3の調査結果に基づく対策がSKILL.mdに反映される
- [ ] 対策実装後、`claude -p --output-format stream-json "テストレビュー"` を3回連続実行し、すべてexit code 0で完了し、stdoutにレビュー本文が1件以上含まれる
- [ ] 外部要因（モデル側の問題）の場合は、ワークアラウンドがSKILL.mdに明文化される

**技術的考慮事項**:
- `prompts/package/skills/claude-review/SKILL.md` を編集（メタ開発ルール）
- ストーリー3の調査結果に依存
