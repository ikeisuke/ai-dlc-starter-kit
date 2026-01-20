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
- [ ] `aidlc.toml` でMCPツール名を設定可能
- [ ] 優先順位付きでツールを指定できる
- [ ] 設定されたツールが利用不可の場合のフォールバック動作が実装されている

### jjサポート強化（#83）
- [ ] jjワークフロー専用ガイドが強化されている
- [ ] プロンプト内でjj/git両対応のコマンド例が併記されている
- [ ] jj特有のワークフロー（bookmark等）が明文化されている

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

## 関連Issue

- #86: [Enhancement] AIスキル（codex/claude/gemini）の統合と各環境対応
- #82: [Enhancement] AIレビュー用MCPツールを設定で指定可能にする
- #83: [Enhancement] jjワークフローの正式サポート強化
