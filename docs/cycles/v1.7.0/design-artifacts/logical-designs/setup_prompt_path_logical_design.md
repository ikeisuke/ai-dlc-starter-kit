# 論理設計: セットアッププロンプトパス記録

## 概要

セットアッププロンプトのパスを環境非依存の形式で記録し、Operations Phase完了時に参照・表示する機能の論理設計。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

プロンプトベースの指示変更（コードではなくMarkdownプロンプトの修正）

## コンポーネント構成

### 変更対象ファイル

```text
prompts/
└── setup-prompt.md          # パス記録処理を追加
    └── package/
        └── prompts/
            └── operations.md # パス参照・表示処理を追加
```

## 処理フロー概要

### フロー1: パス記録（setup-prompt.md）

**タイミング**: ステップ7「aidlc.toml の生成」

**ステップ**:
1. パス特定方法を決定（下記参照）
2. パス形式を判定（同一リポジトリ内 → 外部ghq → 絶対パスの優先順）
3. 適切な形式に変換
4. `docs/aidlc.toml` の `[paths].setup_prompt` に記録

**パス特定方法**（優先順位順）:
1. **デフォルト値**: 同一リポジトリ内の場合は `prompts/setup-prompt.md` を使用
2. **ユーザー入力**: 外部リポジトリの場合、AIがユーザーに確認
   - 「このセットアッププロンプトのパスを教えてください」
3. **環境変数**: 将来的にClaude Code等で環境変数から取得可能になった場合に対応

**再実行時の挙動**:
- 初回セットアップ: パスを記録
- アップグレードモード: 既存の `[paths].setup_prompt` を**保持**（上書きしない）
  - 理由: アップグレード時は既に正しいパスが記録されているため
- 移行モード: 新規記録（既存設定がないため）

**パス形式判定ロジック**（優先順位順）:
```text
1. IF プロンプトファイルがプロジェクトルート配下
     THEN 相対パス形式で記録
          例: "prompts/setup-prompt.md"
2. ELSE IF ghq管理下のリポジトリ（ghq root が取得可能）
     THEN ghq形式で記録
          例: "ghq:github.com/owner/repo/prompts/setup-prompt.md"
3. ELSE
     絶対パスをそのまま記録（フォールバック、非推奨）
```

**プロンプトへの追加指示**:
```markdown
### 7.2.1 setup_prompt パスの設定

`[paths].setup_prompt` には、このセットアッププロンプトファイルのパスを設定します。

**パス形式の判定**:
1. このファイル（setup-prompt.md）がプロジェクトルート配下にある場合:
   - 相対パスを使用（例: `prompts/setup-prompt.md`）

2. このファイルが外部リポジトリにある場合:
   - ghq形式を使用: `ghq:{host}/{owner}/{repo}/{path}`
   - 例: `ghq:github.com/ikeisuke/ai-dlc-starter-kit/prompts/setup-prompt.md`

3. 上記以外の場合:
   - 絶対パスをそのまま使用

**判定補助**:
- プロジェクトルートは `docs/aidlc.toml` が作成されるディレクトリ
- 外部リポジトリの場合、`ghq root` コマンドでルートパスを取得可能
```

### フロー2: パス参照・表示（operations.md）

**タイミング**: Operations Phase 完了メッセージ

**ステップ**:
1. `docs/aidlc.toml` から `[paths].setup_prompt` を読み取り
2. 完了メッセージに埋め込み

**現在の完了メッセージ（840行目付近）**:
```markdown
**AI-DLCスターターキットをアップグレードする場合**: `[setup-promptのパス]` を読み込んでください。
```

**変更後**:
```markdown
**AI-DLCスターターキットをアップグレードする場合**:

以下のコマンドで `docs/aidlc.toml` から `setup_prompt` パスを確認し、そのファイルを読み込んでください:
\`\`\`bash
grep "setup_prompt" docs/aidlc.toml
\`\`\`

※ ghq形式の場合は `$(ghq root)/{path}` で展開できます。
```

## インターフェース設計

### 設定ファイル形式

#### `docs/aidlc.toml` - [paths] セクション

```toml
[paths]
# セットアッププロンプトのパス
# 形式:
#   - 相対パス: "prompts/setup-prompt.md"（プロジェクト内の場合）
#   - ghq形式: "ghq:{host}/{owner}/{repo}/{path}"（外部リポジトリの場合）
setup_prompt = "prompts/setup-prompt.md"
aidlc_dir = "docs/aidlc"
cycles_dir = "docs/cycles"
```

## 非機能要件（NFR）への対応

### パフォーマンス
- N/A（プロンプト修正のみ）

### セキュリティ
- N/A

### スケーラビリティ
- N/A

### 可用性
- ghqがインストールされていない環境でも動作
- ghq形式パスの場合、展開方法をメッセージで案内

## 技術選定
- 言語: Markdown（プロンプト）
- ツール: bash（grep、sed等）
- 依存: ghq（オプション）

## 実装上の注意事項

1. **後方互換性**: 既存の `[paths].setup_prompt` 設定を維持
2. **デフォルト値**: 同一リポジトリ内の場合は `prompts/setup-prompt.md`
3. **ghq非依存**: ghqがなくても動作するよう、展開方法を案内に含める

## 不明点と質問（設計中に記録）

（なし - 計画段階で確認済み）
