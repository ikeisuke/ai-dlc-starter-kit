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

| 指示 | 対応フェーズ |
|------|-------------|
| 「インセプション進めて」「start inception」 | Inception Phase |
| 「コンストラクション進めて」「start construction」 | Construction Phase |
| 「オペレーション進めて」「start operations」 | Operations Phase |
| 「セットアップ」「start setup」 | Setup（新規サイクル開始） |

**Lite版を使用する場合**:
| 指示 | 対応フェーズ |
|------|-------------|
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

### 禁止事項

- 既存履歴の削除・上書き（historyは追記のみ）
- 承認なしでの次ステップ開始
- 独自判断での重要な決定（必ず質問する）
