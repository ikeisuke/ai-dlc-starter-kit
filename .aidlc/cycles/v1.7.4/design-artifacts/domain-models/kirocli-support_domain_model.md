# ドメインモデル設計: KiroCLI対応

## 概要

KiroCLIでAI-DLCを使用するための設定案内を `prompts/package/prompts/AGENTS.md` に追加する。

**注**: `docs/aidlc/prompts/AGENTS.md` は直接編集しない（Operations Phaseのrsyncで反映される）。

## ドメイン概念

### 1. KiroCLI設定案内

`prompts/package/prompts/AGENTS.md` に追加する「KiroCLI対応」セクションの構造。

**構成要素**:

- **概要説明**: KiroCLIでの使用方法の概要
- **制約事項**: `@` 参照記法がKiroCLIで機能しない旨の説明（KiroCLI固有の制約）
- **設定手順**: resources設定の方法（公式ドキュメント参照を明記）
- **設定例**: 具体的なJSON設定例

### 2. 情報構造

```text
KiroCLI対応セクション
├── 概要
│   └── KiroCLIでAI-DLCを使用する方法
├── 制約事項
│   └── @参照記法の非対応について
├── 設定手順
│   ├── 設定ファイルの場所
│   │   ├── ローカル: .kiro/agents/{name}.json
│   │   └── グローバル: ~/.kiro/agents/{name}.json
│   └── resources設定の書き方
└── 設定例
    └── AI-DLC用エージェント設定のJSON例
```

## ビジネスルール

1. **自己完結性**: ユーザーがこのセクションだけで設定できるよう、必要な情報を網羅する
2. **最新情報への誘導**: KiroCLIの仕様変更に備え、公式ドキュメントへのリンクを含める
3. **最小限の設定**: AI-DLCに必要な最小限の設定のみを案内する

## 技術的補足

### tools設定について

AI-DLCでは以下のツールが必要:

- `read`: ドキュメント・コードの読み取り（必須）
- `write`: ドキュメント・コードの生成・編集（必須）
- `shell`: ビルド・テスト・Git操作の実行（必須）

これらはAI-DLCのConstruction/Operations Phaseで必要となる最小権限。

### resources設定について

- 設定形式はKiroCLI公式ドキュメントに準拠
- 仕様変更の可能性があるため、必ず公式ドキュメントを参照するよう案内に明記
- 参照: <https://kiro.dev/docs/cli/custom-agents/configuration-reference/#resources-field>

## 質問と回答

なし（Unit定義で技術的考慮事項が明確化済み）
