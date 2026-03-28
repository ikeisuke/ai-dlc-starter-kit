# AI-DLC（AI-Driven Development Lifecycle）

このプロジェクトはAI-DLCを使用しています。

## 開発サイクルの開始

### 初期セットアップ / アップグレード

`prompts/setup-prompt.md` を読み込んでください。

スターターキットの初期セットアップ、バージョンアップ、または移行時に使用します。

### 新規サイクル開始

`/aidlc inception` を実行してください。

Setup PhaseとInception Phaseが統合され、1回の実行で
サイクル開始からUnit定義まで完了できます。

### 既存サイクルの継続

以下のコマンドを実行してください：

- Inception Phase: `/aidlc inception`
- Construction Phase: `/aidlc construction`
- Operations Phase: `/aidlc operations`

## 推奨ワークフロー

1. 初回は `prompts/setup-prompt.md` でセットアップ
2. `/aidlc inception` でサイクル作成からUnit定義まで完了
3. Construction Phaseで設計と実装
4. Operations Phaseでデプロイと運用

## ドキュメント

- 設定: `.aidlc/config.toml`
- 追加ルール: `.aidlc/cycles/rules.md`

---

## フェーズ簡略指示

以下の簡略指示でフェーズを開始できます：

| 指示 | 対応処理 |
|------|----------|
| 「インセプション進めて」「start inception」 | Inception Phase（新規サイクル開始、推奨） |
| 「コンストラクション進めて」「start construction」 | Construction Phase |
| 「オペレーション進めて」「start operations」 | Operations Phase |
| 「セットアップ」「start setup」 | Inception Phase（リダイレクト） |
| 「start express」 | Inception Phase（エクスプレスモード、フェーズ連続実行を有効化） |
| 「AIDLCフィードバック」「aidlc feedback」 | フィードバック送信 |

**後方互換性**: 従来の詳細な指示（`docs/aidlc/prompts/xxx.md を読み込んで`）は `/aidlc` コマンドにリダイレクトされます。

### サイクル判定

- ブランチ名 `cycle/vX.X.X` からサイクルを自動判定
- mainブランチの場合:
  - 初期セットアップ: `prompts/setup-prompt.md`
  - 新規サイクル開始: `/aidlc inception`
- コンテキストなしで「続けて」: ユーザーに確認

---

@`skills/aidlc/steps/common/agents-rules.md` を参照してください。

---

@`skills/aidlc/steps/common/feedback.md` を参照してください。

---

@`skills/aidlc/steps/common/ai-tools.md` を参照してください。
