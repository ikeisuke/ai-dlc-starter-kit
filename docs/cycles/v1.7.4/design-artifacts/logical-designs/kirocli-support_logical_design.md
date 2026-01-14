# 論理設計: KiroCLI対応

## 概要

`prompts/package/prompts/AGENTS.md` にKiroCLI対応セクションを追加する際の構成と内容を設計する。

**編集対象の明確化**: `docs/aidlc/prompts/AGENTS.md` は直接編集しない（Operations Phaseのrsyncで反映される）。

## 追加位置

`prompts/package/prompts/AGENTS.md` の末尾、「禁止事項」セクションの後に新規セクションとして追加。

## セクション構成

### セクション名

`## KiroCLI対応`（見出しレベル2）

### 内容構成

```markdown
## KiroCLI対応

このセクションでは、KiroCLIでAI-DLCを使用するための設定方法を説明します。

### 制約事項

[`@` 参照記法が機能しない旨の説明]

### 設定手順

[resources設定の方法]

### 設定例

[JSON設定例]
```

## 具体的な記載内容

### 1. 制約事項

- **KiroCLI固有の制約**: AGENTS.md内の `@ファイルパス` 記法はKiroCLIで解釈されない
- ファイル参照は `resources` 設定で明示的に指定する必要がある
- この制約はKiroCLIの仕様によるもの（Claude Codeでは `@` 記法が機能する）

### 2. 設定手順

- 設定ファイルの場所
  - ローカル: `.kiro/agents/{agent-name}.json`
  - グローバル: `~/.kiro/agents/{agent-name}.json`
- resources設定の書き方（**公式ドキュメントを参照のうえ確認**）
  - `file://` プレフィックスを使用
  - グロブパターンが使用可能
  - 仕様変更の可能性があるため、最新情報は公式ドキュメントで確認

### 3. 設定例

AI-DLC用エージェント設定の具体例を提示:

```json
{
  "name": "aidlc-agent",
  "resources": [
    "file://docs/aidlc/prompts/AGENTS.md"
  ],
  "tools": ["read", "write", "shell"]
}
```

**最小限のresources設定**:

- `docs/aidlc/prompts/AGENTS.md`: エントリーポイント（必須のみ）

**設計判断**: 他のファイル（設定ファイル、フェーズプロンプト、サイクル成果物など）はAI-DLCが必要に応じて読み込む。全ファイルをresourcesに含めるとコンテキストが増大するため、最小限の設定を推奨する。

**tools設定について**:

- `read`: ドキュメント・コードの読み取り（AI-DLC必須）
- `write`: ドキュメント・コードの生成・編集（AI-DLC必須）
- `shell`: ビルド・テスト・Git操作の実行（AI-DLC必須）

### 4. 公式ドキュメントへのリンク

<https://kiro.dev/docs/cli/custom-agents/configuration-reference/#resources-field>

**注意**: KiroCLIの仕様は更新される可能性があるため、設定時は必ず公式ドキュメントを参照すること。

## 実装時の注意事項

- 編集対象: `prompts/package/prompts/AGENTS.md`
- `docs/aidlc/prompts/AGENTS.md` は直接編集しない（rsyncで反映される）
- Markdownlintに準拠した記法を使用
