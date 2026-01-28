# ドメインモデル設計: サンドボックス環境ガイド

## 概要

AIエージェントのサンドボックス環境に関するガイドのドメインモデルを定義する。

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

## 集約

### SandboxGuide集約

- ルート: SandboxGuide
- 境界内エンティティ: Section
- 境界内値オブジェクト: ToolConfiguration, SecurityNote

## ガイド構成

```
sandbox-environment.md
├── 1. 概要
│   ├── サンドボックスとは
│   ├── 目的（意図しないファイル変更・コマンド実行の防止）
│   └── 利点
├── 2. Claude Code
│   ├── Docker環境での実行
│   ├── --dangerously-skip-permissions フラグの説明
│   └── 注意事項
├── 3. Codex CLI
│   ├── sandbox設定オプション
│   │   ├── read-only
│   │   ├── workspace-write
│   │   └── danger-full-access
│   └── 設定例
├── 4. KiroCLI
│   ├── サンドボックス設定（対応状況を記載）
│   └── 代替手段（Docker利用など）
├── 5. Docker/コンテナ環境
│   ├── 汎用的なコンテナ実行例
│   ├── Dockerfile例
│   └── docker-compose例（オプション）
└── 6. セキュリティ注意事項
    ├── サンドボックス無効化時のリスク
    ├── 推奨設定
    └── ベストプラクティス
```

## Q&A

（設計中に発生した質問と回答を記録）

- なし
