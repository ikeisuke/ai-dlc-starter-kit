# 論理設計: Codex skillsの設定ドキュメント作成

## 概要

`prompts/package/guides/skill-usage-guide.md` に Codex CLI 向けスキル設定セクションを追記する。既存の「Codex CLI / Gemini CLI」セクションを分離・拡充し、`~/.codex/skills` へのシンボリックリンク設定手順を文書化する。

**重要**: この論理設計では**コードは書かず**、ドキュメントの構成定義のみを行います。

## ドキュメント構成変更

### 変更前の構成（該当部分）

```text
## 各AIツールでの使い方
├── ### Claude Code              (既存・変更なし)
├── ### Codex CLI / Gemini CLI   (既存・変更対象)
└── ### KiroCLI                  (既存・変更なし)
```

### 変更後の構成（該当部分）

```text
## 各AIツールでの使い方
├── ### Claude Code              (変更なし)
├── ### Codex CLI                (新規: 分離・拡充)
│   ├── #### スキル設定（初回のみ）
│   ├── #### 設定確認
│   ├── #### 他のAIツールを呼び出す場合
│   └── #### セットアップフローとの関係
├── ### Gemini CLI               (新規: 分離)
└── ### KiroCLI                  (変更なし)
```

**注**: 前段セクション（「スキルファイルの配置場所」等）は `docs/aidlc/skills/` を対象としたプロジェクト内配置の説明であり、変更不要。`~/.codex/skills` はCodex CLI固有の読み込みパスであるため、Codex CLIセクション内で関係を説明する。

## リンク対象スキル

Codex CLIのスキルとしてリンクする対象は**レビュー系3スキルのみ**:

- `codex-review`
- `claude-review`
- `gemini-review`

**リンク対象外**: `aidlc-upgrade`, `gh`, `jj` はAI-DLCワークフロースキルであり、Codex CLIから直接使用する想定ではないため対象外。

## セクション詳細

### Codex CLI セクション

#### サブセクション1: スキル設定（初回のみ）

- **目的**: Codex CLIがスキルファイルを認識するための手動セットアップ手順
- **内容**:
  - `~/.codex/skills` ディレクトリの作成
  - レビュー系3スキル（codex-review, claude-review, gemini-review）へのシンボリックリンク作成
  - リンク先はプロジェクトの `docs/aidlc/skills/` 配下への絶対パスで指定
- **コマンド例**: `mkdir -p ~/.codex/skills` + `ln -s` コマンド

#### サブセクション2: 設定確認

- **目的**: シンボリックリンクが正しく作成されたことの確認
- **内容**:
  - `ls -la ~/.codex/skills/` でシンボリックリンクの存在と参照先を確認
  - 期待される出力例を提示

#### サブセクション3: 他のAIツールを呼び出す場合

- **目的**: 既存のスキルファイル参照方法の説明（既存内容を維持）
- **内容**: 現在の「Codex CLI / Gemini CLI」セクションのCodex部分を移動

#### サブセクション4: セットアップフローとの関係

- **目的**: AI-DLC セットアップとの関連を説明
- **内容**:
  - AI-DLCセットアップ（`prompts/setup-prompt.md`）は `.claude/skills/` のシンボリックリンクを自動作成するが、`~/.codex/skills` は対象外
  - Codex CLIユーザーは手動で `~/.codex/skills` を設定する必要がある
  - プロジェクトごとに1回設定すれば、以降のアップグレードでは `docs/aidlc/skills/` が更新されるためシンボリックリンクの再作成は不要
  - 前段セクション「スキルファイルの配置場所」との関係: プロジェクト内の `docs/aidlc/skills/` がスキルの実体、`~/.codex/skills` はCodex CLIがそれを参照するためのリンク

### Gemini CLI セクション

- 既存の「Codex CLI / Gemini CLI」セクションからGemini部分を分離
- 内容は既存と同等（スキルファイルの参照方法のみ）

## 配置ルール

- 新セクションは「Claude Code」セクションの直後、「KiroCLI」セクションの前に配置
- Codex CLI → Gemini CLI → KiroCLI の順序（AIツールのアルファベット順に近い配置）

## 非機能要件（NFR）への対応

- N/A（ドキュメント変更のみ）

## 不明点と質問（設計中に記録）

なし
