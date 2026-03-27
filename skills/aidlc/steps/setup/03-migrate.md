## 9. Git コミット

セットアップで作成・更新したすべてのファイルをコミット:

```bash
git add .aidlc/config.toml .aidlc/cycles/ skills/ docs/aidlc/ AGENTS.md CLAUDE.md .github/
# AIDLC-PATH: physical-path-required (reason: git-add)
# .claude/skills ディレクトリが作成されている場合のみ追加
[ -d ".claude/skills" ] && git add .claude/
# .agents/skills ディレクトリが作成されている場合のみ追加
[ -d ".agents/skills" ] && git add .agents/
# .kiro/agents/aidlc.json が作成されている場合のみ追加
[ -f ".kiro/agents/aidlc.json" ] && git add .kiro/
```

**コミットメッセージ**（モードに応じて選択）:
- **初回**: `git commit -m "feat: AI-DLC初回セットアップ完了"`
- **アップグレード**: `git commit -m "chore: AI-DLCをバージョンX.X.Xにアップグレード"`
- **移行**: `git commit -m "chore: AI-DLC新ファイル構成に移行"`

---

## 10. 完了メッセージと次のステップ

### 初回セットアップの場合

```text
AI-DLC環境のセットアップが完了しました！

作成されたファイル:

プロジェクト設定:
- .aidlc/config.toml - プロジェクト設定

AI-DLCスキル（skills/aidlc/）:
- steps/ - フェーズステップファイル
- templates/ - ドキュメントテンプレート
- scripts/ - ユーティリティスクリプト
- config/ - デフォルト設定

プロジェクト固有ファイル（.aidlc/cycles/）:
- rules.md - プロジェクト固有ルール

AIツール設定ファイル（プロジェクトルート）:
- AGENTS.md - 全AIツール共通（AI-DLC設定を参照）
- CLAUDE.md - Claude Code専用（AI-DLC設定を参照）
- .claude/skills/ - スキルディレクトリ（各スキルへのシンボリックリンク + 独自スキル用）
- .agents/skills/ - Agentスキルディレクトリ（各スキルへのシンボリックリンク）
- .kiro/agents/aidlc.json - KiroCLIエージェント設定（シンボリックリンク）

GitHub Issueテンプレート（.github/ISSUE_TEMPLATE/）:
- backlog.yml - バックログ用テンプレート
- bug.yml - バグ報告用テンプレート
- feature.yml - 機能要望用テンプレート
- feedback.yml - フィードバック用テンプレート

### AIエージェント許可リストの設定（オプション）

AI-DLCではファイル操作やGitコマンドを多用します。
毎回の確認を減らすため、許可リストまたはsandbox環境の設定を推奨します。

詳細は {{aidlc_dir}}/guides/ai-agent-allowlist.md を参照してください。

### ユーザー共通設定（オプション）

複数のAI-DLCプロジェクトで共通設定を使用したい場合:
1. ディレクトリ作成: mkdir -p ~/.aidlc
2. 設定ファイル作成: touch ~/.aidlc/config.toml
3. 共通設定を記述

詳細は {{aidlc_dir}}/guides/config-merge.md を参照してください。
```

### アップグレードの場合

```text
AI-DLCのアップグレードが完了しました！

更新されたファイル:
- skills/aidlc/ - AI-DLCスキル（フェーズステップファイル）
- skills/aidlc/templates/ - ドキュメントテンプレート

※ .aidlc/config.toml は保持されています（変更なし）

---
**セットアップは完了です。このセッションはここで終了してください。**

新しいセッションで `/aidlc inception` と指示し、サイクルを開始してください。
```

**重要**: アップグレード完了後は、自動で Inception Phase を開始しないでください。ユーザーが新しいセッションで明示的に開始するまで待機してください。

### 移行の場合

```text
AI-DLCの新ファイル構成への移行が完了しました！

移行されたファイル:
| 移行元 | 移行先 |
|--------|--------|
| docs/aidlc/project.toml | .aidlc/config.toml |
| docs/aidlc/prompts/additional-rules.md | .aidlc/cycles/rules.md |
| docs/aidlc/version.txt | （削除: config.toml に統合） |

これにより、skills/aidlc/ ディレクトリはスターターキットと完全同期可能になりました。
```

<!-- AIDLC-PATH: physical-path-required (reason: v1-migration) -->

---

## 次のステップ: サイクル開始

**注意**: このセクションは初回セットアップ・移行の場合のみ表示してください。
- **ケースB（バージョン同じ）**: このセクションは表示せず、自動で `/aidlc inception` を実行する
- **ケースC（アップグレード完了後）**: 上記「アップグレードの場合」のメッセージを表示し、セッションを終了する

### 初回セットアップ・移行の場合

セットアップが完了しました。新しいセッションで `/aidlc inception` と指示し、サイクルを開始してください。

---

## AI-DLC 概要

AI-DLC（AI-Driven Development Lifecycle）は、AIを開発の中心に据えた新しい開発手法です。

**主要原則**:
- **会話の反転**: AIが作業計画を提示し、人間が承認・判断する
- **設計技法の統合**: DDD・BDD・TDDをAIが自動適用
- **短サイクル反復**: 各フェーズを短いサイクルで反復

**3つのフェーズ**:
1. **Inception**: 要件定義、ユーザーストーリー作成、Unit分解
2. **Construction**: 設計、実装、テスト
3. **Operations**: デプロイ、監視、運用
