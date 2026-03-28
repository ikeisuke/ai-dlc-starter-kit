# AI-DLC（AI-Driven Development Lifecycle）

このプロジェクトはAI-DLCを使用しています。

## 非AIDLCプロジェクトガード

`.aidlc/config.toml` が存在しない場合、AI-DLCのフェーズ実行は行わない。
ユーザーにセットアップを案内する:

```text
AI-DLC環境が未セットアップです。
「start setup」または `/aidlc setup` でセットアップを開始してください。
```

## 開発サイクルの開始

### 初期セットアップ / アップグレード

`/aidlc setup` を実行してください。

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

1. 初回は `/aidlc setup` でセットアップ
2. `/aidlc inception` でサイクル作成からUnit定義まで完了
3. `/aidlc construction` で設計と実装
4. `/aidlc operations` でデプロイと運用

## ドキュメント

- 設定: `.aidlc/config.toml`
- 追加ルール: `.aidlc/cycles/rules.md`

---

## フェーズ簡略指示

以下の簡略指示でフェーズを開始できます：

| 指示 | 対応処理 |
|------|----------|
| 「インセプション進めて」「start inception」 | `/aidlc inception` |
| 「コンストラクション進めて」「start construction」 | `/aidlc construction` |
| 「オペレーション進めて」「start operations」 | `/aidlc operations` |
| 「セットアップ」「start setup」 | `/aidlc setup`（Setup Phase） |
| 「start express」 | `/aidlc express`（エクスプレスモード、フェーズ連続実行を有効化） |
| 「AIDLCフィードバック」「aidlc feedback」 | `/aidlc feedback`（フィードバック送信） |
| 「start migrate」「aidlc migrate」 | `/aidlc migrate`（v1→v2移行） |

**Lite版を使用する場合**:
| 指示 | 対応処理 |
|------|----------|
| 「start lite inception」 | `/aidlc lite inception` |
| 「start lite construction」 | `/aidlc lite construction` |
| 「start lite operations」 | `/aidlc lite operations` |

**後方互換性**: 従来の詳細な指示（`docs/aidlc/prompts/xxx.md を読み込んで`）は `/aidlc` コマンドにリダイレクトされます。

### サイクル判定

- ブランチ名 `cycle/vX.X.X` からサイクルを自動判定
- mainブランチの場合:
  - 初期セットアップ: `/aidlc setup`
  - 新規サイクル開始: `/aidlc inception`
- コンテキストなしで「続けて」: ユーザーに確認

---

@`steps/common/agents-rules.md` を参照してください。

---

@`steps/common/feedback.md` を参照してください。

---

@`steps/common/ai-tools.md` を参照してください。
