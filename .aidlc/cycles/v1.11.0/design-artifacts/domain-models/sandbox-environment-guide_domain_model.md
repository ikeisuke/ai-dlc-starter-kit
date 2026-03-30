# ドメインモデル設計: サンドボックス環境ガイド

## 概要

AIエージェントのサンドボックス環境に関するガイドのドメインモデルを定義する。

## 検証情報

| 項目 | 値 | 参照先 |
|------|-----|--------|
| 検証日 | 2026-01-28 | - |
| Claude Code | 1.0.x | [公式ドキュメント](https://docs.anthropic.com/claude-code) |
| Codex CLI | 0.89.x | [GitHub](https://github.com/openai/codex) |
| KiroCLI | 0.x | [公式ドキュメント](https://kiro.dev/docs/cli) |

**注意**: 各ツールの仕様は頻繁に更新されます。実装時は公式ドキュメントで最新情報を確認してください。

## エンティティ

### SandboxGuide（サンドボックスガイド）

ガイド全体を表すルートエンティティ。

**属性**:

- title: ガイドのタイトル
- sections: セクションのリスト

### Section（セクション）

ガイドの各セクションを表すエンティティ。

**属性**:

- heading: セクション見出し
- content: セクション内容
- subsections: サブセクションのリスト（オプション）

## 値オブジェクト

### ToolConfiguration（ツール設定）

各AIエージェントのサンドボックス設定を表す。

**属性**:

- toolName: ツール名（Claude Code / Codex CLI / KiroCLI）
- sandboxOptions: サンドボックス設定オプション
- commands: 設定コマンド例
- notes: 注意事項

### SecurityNote（セキュリティ注意事項）

セキュリティに関する注意事項を表す。

**属性**:

- riskLevel: リスクレベル（高/中/低）
- description: 説明
- recommendation: 推奨設定

### UseCaseRecommendation（ユースケース別推奨設定）

ユースケースに応じた推奨サンドボックス設定を表す。

**属性**:

- useCase: ユースケース名（コードレビュー / 通常開発 / 特殊要件）
- permissionLevel: 推奨権限レベル
- toolSettings: ツール別設定マッピング

### PermissionLevel（権限レベル）

サンドボックスの権限レベルを表す列挙型。

**値**:

- READ_ONLY: 読み取り専用
- WORKSPACE_WRITE: ワークスペース書き込み許可
- FULL_ACCESS: フルアクセス（非推奨）

## 集約

### SandboxGuide集約

- ルート: SandboxGuide
- 境界内エンティティ: Section
- 境界内値オブジェクト: ToolConfiguration, SecurityNote, UseCaseRecommendation, PermissionLevel

## 対象環境

### サポートOS/プラットフォーム

| OS | サポート状況 | 備考 |
|----|-------------|------|
| macOS | ○ | 主要な開発環境 |
| Linux | ○ | Docker実行環境として推奨 |
| Windows | △ | WSL2経由を推奨 |

### 実行環境

- ローカル開発環境
- Dockerコンテナ
- CI/CD環境（GitHub Actions等）

## ガイド構成

```text
sandbox-environment.md
├── 1. 概要
│   ├── サンドボックスとは
│   ├── 目的（意図しないファイル変更・コマンド実行の防止）
│   └── 利点
├── 2. ユースケース別推奨設定【新規】
│   ├── コードレビュー・調査 → 読み取り専用
│   ├── 通常の開発作業 → ワークスペース書き込み
│   └── 特殊な要件 → フルアクセス（要注意）
├── 3. Claude Code
│   ├── Docker環境での実行（APIキー渡し方含む）
│   ├── --dangerously-skip-permissions フラグの説明
│   ├── ユーザー権限設定
│   └── 注意事項
├── 4. Codex CLI
│   ├── sandbox設定オプション
│   │   ├── read-only
│   │   ├── workspace-write
│   │   └── danger-full-access
│   ├── 設定ファイルの場所と優先順位
│   └── 設定例
├── 5. KiroCLI
│   ├── サンドボックス設定（対応状況を記載）
│   └── 代替手段（Docker利用など）
├── 6. Docker/コンテナ環境
│   ├── 汎用的なコンテナ実行例
│   ├── Dockerfile例（ユーザー権限、ネットワーク制限含む）
│   └── docker-compose例（オプション）
└── 7. セキュリティ注意事項【拡充】
    ├── サンドボックス無効化時のリスク
    ├── ネットワーク外部通信の制御
    ├── シークレット保護（APIキー、環境変数）
    ├── プロンプトインジェクション対策
    ├── 依存関係のサプライチェーンリスク
    ├── 推奨設定
    └── ベストプラクティス
```

## Q&A

（設計中に発生した質問と回答を記録）

- なし
