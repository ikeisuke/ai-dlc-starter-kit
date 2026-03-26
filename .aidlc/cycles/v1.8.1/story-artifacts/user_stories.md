# ユーザーストーリー

## Epic: スクリプト基盤の活用完成

v1.8.0で追加されたスクリプト基盤を各プロンプトに統合し、保守性と一貫性を向上させる。

---

### ストーリー 1: env-info.shをsetup.mdで活用

**優先順位**: Must-have
**関連Issue**: #81

As a AI-DLC利用者
I want to セットアップ時に環境情報を一括で確認できる
So that 依存ツールの状態を素早く把握し、問題があれば対処できる

**受け入れ基準**:

- [ ] `prompts/package/prompts/setup.md`で`env-info.sh`が呼び出されている
- [ ] 個別のツール確認bashコマンドが`env-info.sh`呼び出しに置き換わっている
- [ ] 変更後のsetup.mdがmarkdownlintをパスする

**技術的考慮事項**:

- env-info.shの出力形式（`tool:status`）に基づいて状態を判定

---

### ストーリー 2: write-history.shをプロンプトに統合

**優先順位**: Must-have

As a AI-DLC利用者
I want to 履歴記録が標準化されたスクリプトで行われる
So that フォーマットの一貫性が保たれ、保守が容易になる

**受け入れ基準**:

- [ ] `prompts/package/prompts/inception.md`のheredocがwrite-history.sh呼び出しに置換されている
- [ ] `prompts/package/prompts/construction.md`のheredocがwrite-history.sh呼び出しに置換されている
- [ ] `prompts/package/prompts/operations.md`のheredocがwrite-history.sh呼び出しに置換されている
- [ ] 履歴記録のフォーマットが従来と互換性を維持している（見出し`## {TIMESTAMP}`、項目`- **フェーズ**:`, `- **ステップ**:`, `- **実行内容**:`, `- **成果物**:`、区切り`---`）
- [ ] 変更後の各mdファイルがmarkdownlintをパスする

**技術的考慮事項**:

- write-history.shのオプション（--cycle, --phase, --step等）を適切に使用

---

### ストーリー 3: label-cycle-issues.shを新規作成

**優先順位**: Must-have

As a AI-DLC利用者
I want to 複数Issueへのラベル付けが一括で行われる
So that AIエージェントがループ処理を繰り返す必要がなくなり、許可リスト運用が容易になる

**受け入れ基準**:

- [ ] `prompts/package/bin/label-cycle-issues.sh`が作成されている
- [ ] `docs/cycles/{{CYCLE}}/story-artifacts/units/*.md`からIssue番号（`^- #[0-9]+`形式）を抽出できる
- [ ] 抽出した各Issueに`cycle:{{CYCLE}}`ラベルを一括付与できる
- [ ] Issue番号が見つからない場合は正常終了（エラーにしない）
- [ ] `prompts/package/prompts/inception.md`でスクリプトが呼び出されている
- [ ] 従来の「見つかったIssue分だけ実行」の記述がスクリプト呼び出しに置換されている
- [ ] 変更後のinception.mdがmarkdownlintをパスする

**技術的考慮事項**:

- 既存のissue-ops.shを内部で呼び出す設計
- 出力形式: `issue:{番号}:labeled:cycle:{サイクル}`

---

### ストーリー 4: AIレビュー設定の改善（Skills優先、MCPフォールバック）

**優先順位**: Must-have
**関連Issue**: #70, #73

As a AI-DLC利用者
I want to AIレビューがSkills優先で安定して動作し、Skills未対応環境ではMCPにフォールバックする
So that 様々なツール環境で一貫してAIレビューが利用できる

**受け入れ基準**:

- [ ] `prompts/package/prompts/setup.md`のAIレビュー設定がSkills優先+MCPフォールバックになっている
- [ ] `prompts/package/prompts/inception.md`のAIレビュー設定がSkills優先+MCPフォールバックになっている
- [ ] `prompts/package/prompts/construction.md`のAIレビュー設定がSkills優先+MCPフォールバックになっている
- [ ] `prompts/package/prompts/operations.md`のAIレビュー設定がSkills優先+MCPフォールバックになっている
- [ ] Skills利用可能時はSkillsを使用する旨が記載されている
- [ ] Skills未対応時はMCP（`mcp__codex__codex`等）を使用する旨が記載されている
- [ ] 変更後の各mdファイルがmarkdownlintをパスする

**技術的考慮事項**:

- Skills対応ツール: Claude Code
- Skillツールの呼び出し方法: `Skill tool: skill="codex"`
- MCPフォールバック時: `codex exec -s read-only -C <dir> "<prompt>"`

---

### ストーリー 5: 依存コマンド追加手順をドキュメント化

**優先順位**: Must-have
**関連Issue**: #72

As a AI-DLC開発者
I want to 新しい依存コマンドを追加する手順が明文化されている
So that 将来の機能追加時に一貫した方法で依存コマンドを追加できる

**受け入れ基準**:

- [ ] `prompts/package/prompts/operations.md`に依存コマンド追加手順セクションが追加されている
- [ ] env-info.shへの追加方法が記載されている
- [ ] setup.mdでの確認フローへの追加方法が記載されている
- [ ] 変更後のoperations.mdがmarkdownlintをパスする

**技術的考慮事項**:

- Operations Phaseの「運用引き継ぎ」セクションに追加が適切
