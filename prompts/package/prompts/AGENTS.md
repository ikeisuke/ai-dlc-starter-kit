# AI-DLC（AI-Driven Development Lifecycle）

このプロジェクトはAI-DLCを使用しています。

## 開発サイクルの開始

### 初期セットアップ / アップグレード

`prompts/setup-prompt.md` を読み込んでください。

スターターキットの初期セットアップ、バージョンアップ、または移行時に使用します。

### 新規サイクル開始

`docs/aidlc/prompts/setup.md` を読み込んでください。

既存プロジェクトで新しいサイクルを開始する場合に使用します。

### 既存サイクルの継続

以下のプロンプトを読み込んでください：

- Inception Phase: `docs/aidlc/prompts/inception.md`
- Construction Phase: `docs/aidlc/prompts/construction.md`
- Operations Phase: `docs/aidlc/prompts/operations.md`

## 推奨ワークフロー

1. 初回は `prompts/setup-prompt.md` でセットアップ
2. `docs/aidlc/prompts/setup.md` でサイクルを作成
3. Inception Phaseで要件定義とUnit分解
4. Construction Phaseで設計と実装
5. Operations Phaseでデプロイと運用

## ドキュメント

- 設定: `docs/aidlc.toml`
- 追加ルール: `docs/cycles/rules.md`

---

## フェーズ簡略指示

以下の簡略指示でフェーズを開始できます：

| 指示 | 対応処理 |
|------|----------|
| 「インセプション進めて」「start inception」 | Inception Phase |
| 「コンストラクション進めて」「start construction」 | Construction Phase |
| 「オペレーション進めて」「start operations」 | Operations Phase |
| 「セットアップ」「start setup」 | Setup（新規サイクル開始） |
| 「AIDLCアップデート」「update aidlc」「start upgrade」 | アップグレード（環境更新） |

**Lite版を使用する場合**:
| 指示 | 対応処理 |
|------|----------|
| 「start lite inception」 | Inception Phase (Lite) |
| 「start lite construction」 | Construction Phase (Lite) |
| 「start lite operations」 | Operations Phase (Lite) |

**後方互換性**: 従来の詳細な指示（`docs/aidlc/prompts/xxx.md を読み込んで`）も引き続き有効です。

### サイクル判定

- ブランチ名 `cycle/vX.X.X` からサイクルを自動判定
- mainブランチの場合:
  - 初期セットアップ: `prompts/setup-prompt.md`
  - 新規サイクル開始: `docs/aidlc/prompts/setup.md`
- コンテキストなしで「続けて」: ユーザーに確認

---

## AI-DLC共通ルール

### 実行前の検証

- **MCPレビュー推奨**: Codex MCP利用可能時は重要な変更前にレビュー
- **指示の妥当性検証**: 実行前に指示が明確か、リスクはないか確認

### フェーズ固有のルール

- **Inception Phase**: Intent作成は対話形式、Unit定義では依存関係を明確化
- **Construction Phase**: 設計と実装を分離（Phase 1で設計、Phase 2で実装）
- **Operations Phase**: デプロイ前にチェックリスト確認、ロールバック手順必須

### 質問と深掘り

ユーザーとの対話で質問する際は、以下のルールに従う：

**質問の目的**:

- 曖昧な要件を明確化する
- 前提条件や制約を確認する
- 複数の解釈がある場合に意図を特定する

**深掘りのテクニック**:

- 「具体的には？」で詳細を引き出す
- 「例えば？」で具体例を求める
- 「なぜ？」で背景・理由を確認する
- ユースケースやシナリオを聞いて理解を深める

**注意事項**:

- 質問の概要を先に提示し、その後は一問一答形式で進める（各フェーズのハイブリッド方式に従う）
- 回答を得てから次の質問に進む
- 独自の解釈で進めず、必ず確認する

### バックログ管理

バックログの保存先は `docs/aidlc.toml` の `[backlog].mode` で設定する。

| mode | 保存先 | 説明 |
|------|--------|------|
| git | `docs/cycles/backlog/*.md` | ローカルファイルがデフォルト（他の保存先も許容） |
| issue | GitHub Issues | GitHub Issueがデフォルト（他の保存先も許容） |
| git-only | `docs/cycles/backlog/*.md` | ローカルファイルのみ（Issue作成禁止） |
| issue-only | GitHub Issues | GitHub Issueのみ（ローカルファイル作成禁止） |

**排他モード（`*-only`）の場合**: 指定された保存先のみを使用し、他の保存先への記録は行わない。

### 禁止事項

- 既存履歴の削除・上書き（historyは追記のみ）
- 承認なしでの次ステップ開始
- 独自判断での重要な決定（必ず質問する）

---

## KiroCLI対応

このセクションでは、KiroCLIでAI-DLCを使用するための設定方法を説明します。

### 制約事項

- **KiroCLI固有の制約**: AGENTS.md内の `@ファイルパス` 記法はKiroCLIで解釈されません
- この制約はKiroCLIの仕様によるものです（Claude Codeでは `@` 記法が機能します）
- KiroCLIでは `resources` に指定したファイルのみがエージェントに読み込まれます

### 設定手順

1. 設定ファイルを作成します:
   - ローカル（プロジェクト固有）: `.kiro/agents/{agent-name}.json`
   - グローバル（ユーザー全体）: `~/.kiro/agents/{agent-name}.json`

2. `resources` フィールドでAI-DLCに必要なファイルを指定します

**注意**: KiroCLIの仕様は更新される可能性があります。最新情報は[公式ドキュメント](https://kiro.dev/docs/cli/custom-agents/configuration-reference/#resources-field)を参照してください。

### 設定例

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

| パス | 用途 |
|------|------|
| `docs/aidlc/prompts/AGENTS.md` | エントリーポイント（必須） |

**注意**: パスはプロジェクトルートからの相対パスで指定します。

**resourcesの拡張**: 必要に応じて以下のパスを追加できます:

```json
"resources": [
  "file://docs/aidlc/prompts/AGENTS.md",
  "file://docs/aidlc.toml",
  "file://docs/aidlc/prompts/construction.md"
]
```

全ファイルをresourcesに含めるとコンテキストが増大するため、作業に必要なファイルのみを指定してください。

**tools設定**:

| ツール | 用途 |
|--------|------|
| `read` | ドキュメント・コードの読み取り |
| `write` | ドキュメント・コードの生成・編集 |
| `shell` | ビルド・テスト・Git操作の実行 |
