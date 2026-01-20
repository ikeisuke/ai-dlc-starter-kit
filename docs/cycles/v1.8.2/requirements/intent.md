# Intent（開発意図）

## プロジェクト名

AIスキル統合・AIレビュー設定強化・jjサポート強化

## 開発の目的

AI-DLCスターターキットの開発体験を向上させるため、以下の3つの改善を行う：

1. **AIスキル統合**: スキルファイル（codex/claude/gemini）をプロジェクト単位で自動的に利用可能にする
2. **AIレビュー設定強化**: MCPツールを設定で指定可能にし、環境ごとの柔軟性を向上
3. **jjサポート強化**: jjワークフローの正式サポートを強化し、gitとの違いによるミスを削減

## ターゲットユーザー

- AI-DLCスターターキットを利用する開発者
- Claude Code / KiroCLI でAIレビュー機能を使いたいユーザー
- 複数プロジェクトで統一されたスキルセットを使いたいチーム

## ビジネス価値

- **再利用性向上**: スキルをGitで管理し、プロジェクトをcloneするだけで即座に利用可能
- **環境構築の簡素化**: 個別のスキルインストール作業が不要
- **一貫性の確保**: プロジェクト内で統一されたスキルセットを使用可能
- **マルチツール対応**: Claude Code / KiroCLI 両方で同じスキルを利用可能

## 成功基準

### AIスキル統合（#86）
- [ ] スキルファイル（codex/claude/gemini）が `prompts/package/skills/` に配置されている
- [ ] セットアップ時に `docs/aidlc/skills/` にrsyncでコピーされる
- [ ] `.claude/skills/` から `docs/aidlc/skills/` へのシンボリックリンクが設定されている
- [ ] プロジェクトをcloneした後、Claude Codeでスキルが認識される
- [ ] KiroCLI での利用方法がドキュメント化されている

### AIレビュー設定強化（#82）
- [ ] `aidlc.toml` の `[rules.mcp_review]` セクションに `mcp_tools` 設定を追加
- [ ] 優先順位付きリスト形式（`mcp_tools = ["tool1", "tool2"]`）で指定可能
- [ ] 上から順に利用可能なツールを検索し、最初に見つかったものを使用
- [ ] すべて利用不可の場合はSkillsにフォールバック（既存動作を維持）

### jjサポート強化（#83）
- [ ] `docs/aidlc/guides/jj-support.md` のコマンド対照表を充実
- [ ] jj特有のワークフロー（describe+new、bookmark等）を明文化
- [ ] よくあるミスと対処法のセクションを追加

## 期限とマイルストーン

サイクル v1.8.2 内で完了

## 制約事項

### 技術的制約
- Claude Codeのスキル機能（`.claude/skills/`）を利用
- 既存のパッケージ管理方式（`prompts/package/` → `docs/aidlc/`）との整合性を維持
- シンボリックリンクはGitで追跡可能な形式で管理

### スコープ制約
- 対象スキル: codex, claude, gemini の3つ
- 新規スキルの追加機能は今回のスコープ外

## 不明点と質問（Inception Phase中に記録）

[Question] スキルファイルの配置場所は？
[Answer] `prompts/package/skills/` に配置し、rsyncで `docs/aidlc/skills/` にコピー

[Question] Claude Codeへのインストール方法は？
[Answer] シンボリックリンク方式（`.claude/skills/` → `docs/aidlc/skills/`）

[Question] KiroCLI対応は含めるか？
[Answer] 含める（利用方法を文書化）

[Question] Issue #82, #83も今回のスコープに含めるか？
[Answer] 含める（#82: AIレビュー設定強化、#83: jjサポート強化）

[Question] AIレビュー設定強化（#82）のMCPツール指定形式は？
[Answer] 優先順位付きリスト形式（`mcp_tools = ["tool1", "tool2"]`）、上から順に試行

[Question] jjサポート強化（#83）の対象範囲は？
[Answer] ガイド強化のみ（jj-support.mdの充実、コマンド例追加）、プロンプト修正は含まない

## 関連Issue

- #86: [Enhancement] AIスキル（codex/claude/gemini）の統合と各環境対応
- #82: [Enhancement] AIレビュー用MCPツールを設定で指定可能にする
- #83: [Enhancement] jjワークフローの正式サポート強化
