# 論理設計: AIDLC専用レビュースキル

## 概要

`reviewing-inception` スキルのファイル構成、既存フレームワークへの統合方法、各変更対象ファイルの具体的な更新内容を定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存のreviewing-*スキルと同一パターンを踏襲する（テンプレートメソッドパターン）。

スキルの構成要素:
- YAML frontmatter: 5つの必須フィールド（name, description, argument-hint, compatibility, allowed-tools）
- Markdownボディ: 4つの必須セクション（タイトル、レビュー観点、実行コマンド、セッション継続）
- references/: セッション管理ガイド

## コンポーネント構成

### ファイル構成

```text
prompts/package/skills/reviewing-inception/
├── SKILL.md                              # スキル定義本体
└── references/
    └── session-management.md             # セッション管理ガイド（既存と同一）
```

### コンポーネント詳細

#### SKILL.md（新規作成）

- **責務**: Inception Phase成果物のレビュー観点と実行手順を定義
- **依存**: references/session-management.md（相対リンク参照）
- **公開インターフェース**: スキル呼び出し `skill="reviewing-inception"`, args="[対象] 優先ツール: [tool]"`

**YAML frontmatter**:

| フィールド | 値 |
|-----------|-----|
| name | `reviewing-inception` |
| description | `Reviews Inception Phase artifacts including Intent clarity, user story quality (INVEST), and Unit definition completeness. Use when reviewing inception artifacts, checking requirements quality, or when the user mentions inception review, requirements review, or unit definition review.` |
| argument-hint | `[レビュー対象ファイルまたはディレクトリ]` |
| compatibility | `Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.` |
| allowed-tools | `Bash(codex:*) Bash(claude:*) Bash(gemini:*)` |

**Markdownボディセクション構成**:

1. `# Reviewing Inception` + 一行説明
2. `## レビュー観点`
   - `### Intent品質`（5項目）
   - `### ユーザーストーリー品質`（5項目）
   - `### Unit定義品質`（5項目）
3. `## 実行コマンド`（Codex / Claude Code / Gemini）
4. `## セッション継続`（resume コマンド + references参照リンク）

#### references/session-management.md（新規作成）

- **責務**: セッション管理の共通ガイドを提供
- **依存**: なし
- **内容**: 既存スキル（reviewing-code等）の `references/session-management.md` と同一内容をコピー

### 既存ファイル更新

#### review-flow.md 更新内容

**更新箇所1: 「有効なレビュー種別とスキル名」テーブル（現在3行）**

追加行:

| レビュー種別 | Skills呼び出し |
|-------------|----------------|
| inception | `skill="reviewing-inception"` |

**更新箇所2: 「CallerContextマッピングテーブル」（現在4行）**

追加行（キーはinception.mdの記述に合わせて正規化）:

| 呼び出し元ステップ | デフォルトのレビュー種別 |
|---|---|
| Intent承認前 | inception |
| ユーザーストーリー承認前 | inception |
| Unit定義承認前 | inception |

**注意**: キーは `inception.md` の記述（例: 「Intent承認前に review-flow.md に従って...」）と完全一致させる。「Inception ステップN」形式ではなく「〇〇承認前」形式で統一する。

**更新箇所3: 履歴記録テンプレートの汎化**

現状（review-flow.md内の3箇所の履歴テンプレート）:
- 148-161行付近（AIレビュー完了記録）: `--phase construction` がハードコード
- 289-298行付近（指摘対応判断記録）: `--phase construction` がハードコード
- 304-315行付近（指摘対応判断サマリ記録）: `--phase construction` がハードコード
- いずれも `--unit/--unit-name/--unit-slug` がConstruction前提で含まれている
- ステップ名マッピングがConstruction固定

変更方針（3箇所すべてに適用）:
- `--phase construction` を `--phase {{PHASE}}` に変更
- `--unit/--unit-name/--unit-slug` 行にコメントを追加: `（constructionフェーズの場合のみ。inceptionフェーズではUnit引数を省略する）`
- ステップ名マッピングにInception Phaseの対応を追加:
  - Intent承認前
  - ユーザーストーリー承認前
  - Unit定義承認前

**phase別の引数仕様**:

| phase | --unit | --unit-name | --unit-slug | 備考 |
|-------|--------|-------------|-------------|------|
| inception | 省略 | 省略 | 省略 | Inception Phaseにはまだ実装Unitがない |
| construction | 必須 | 必須 | 必須 | 現行どおり |

#### ai-tools.md 更新内容

レビュースキルテーブル（11-15行）に1行追加:

| レビュー種別 | 読むファイル |
|-------------|-------------|
| Inceptionレビュー | `docs/aidlc/skills/reviewing-inception/SKILL.md` |

#### skill-usage-guide.md 更新内容

**更新箇所1: レビュースキルテーブル（48-52行）に1行追加**:

| レビュー種別 | 読むスキルファイル |
|-------------|-------------------|
| Inceptionレビュー | `docs/aidlc/skills/reviewing-inception/SKILL.md` |

**更新箇所2: ファイル配置場所の図（26-37行）にディレクトリ追加**

**更新箇所3: Claude Code セクション（69-74行）にコマンド追加**:
```text
/reviewing-inception      → Inceptionレビューを実行
```

**更新箇所4: Gemini CLI セクション（124-134行）に使い方追加**

**更新箇所5: 予約名テーブル（201-205行）に `reviewing-inception` 追加**

## 処理フロー概要

### Inception PhaseでのAIレビュー実行フロー

**ステップ**:
1. Inception Phaseプロンプトが成果物承認前にreview-flow.mdを参照
2. review-flow.mdのCallerContextマッピングから `inception` 種別を決定
3. `skill="reviewing-inception"` を呼び出し
4. スキルのレビュー観点に基づいてAIがレビューを実行
5. 反復レビュー（最大3回）後、結果を履歴に記録

**関与するコンポーネント**: inception.md → review-flow.md → reviewing-inception/SKILL.md

**inception.mdの更新方針**: inception.mdは変更しない。理由: inception.mdは既に `review-flow.md` を参照する仕組みで動作しており、review-flow.mdのCallerContextテーブルを更新すればInception Phaseのレビューフローに自動的に反映される。inception.md内の「Inception固有のレビュー観点」はAIレビュースキルへの追加ヒントとして機能し、CallerContextのキーとは独立している。

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: AIレビュー実行時間は既存スキルと同等
- **対応策**: 同一のCLIコマンドパターンを使用

### セキュリティ
- **要件**: 該当なし
- **対応策**: read-only/sandboxモードで実行

### スケーラビリティ
- **要件**: 新たなレビュー観点の追加が容易な構造
- **対応策**: レビュー観点を独立したサブセクションとして定義

### 可用性
- **要件**: codex, claude, geminiの3ツールで動作
- **対応策**: 既存スキルと同一の実行コマンドとセッション継続パターンを使用

## 技術選定
- **言語**: Markdown（スキル定義）
- **フレームワーク**: AI-DLCスキルフレームワーク（YAML frontmatter + Markdown）
- **ツール**: codex CLI, claude CLI, gemini CLI

## 実装上の注意事項
- `prompts/package/` 内を編集すること（メタ開発ルール）
- 既存スキルとの形式一貫性を厳密に維持すること
- review-flow.mdの既存テーブル行は変更しない（追加のみ）
- 履歴テンプレートの変更は後方互換性を維持すること（Construction Phaseの既存動作に影響しない）

## 不明点と質問（設計中に記録）

（現時点でなし）
