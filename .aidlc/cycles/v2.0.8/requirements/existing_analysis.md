# 既存コードベース分析

## ディレクトリ構造・ファイル構成

### 対象アクション別ファイル構成

```
skills/aidlc/
├── SKILL.md                    # オーケストレーター（全アクションのルーティング）
├── CLAUDE.md                   # Claude Code固有設定
├── scripts/                    # 共通スクリプト群（25+ファイル）
├── steps/
│   ├── common/                 # 共通ステップ（15ファイル）
│   ├── inception/              # Inception Phase（6ファイル: 01-06）
│   ├── construction/           # Construction Phase（4ファイル: 01-04）
│   └── operations/             # Operations Phase（5ファイル: 01-04 + operations-release.md）
├── templates/                  # テンプレート
├── guides/                     # ガイド
├── config/                     # デフォルト設定
└── references/                 # 参照資料

skills/aidlc-setup/
├── SKILL.md                    # セットアップスキル
├── scripts/                    # セットアップ固有スクリプト
├── steps/                      # セットアップステップ
└── templates/                  # セットアップテンプレート
```

## アーキテクチャ・パターン

- **スキルベースプラグインアーキテクチャ**: SKILL.md がエントリポイント、steps/ がフェーズ定義
- **オーケストレーターパターン**: SKILL.md がアクションをルーティングし、各フェーズステップに委譲
- **設定駆動**: config.toml + defaults.toml によるマージ設定

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| シェルスクリプト | Bash | scripts/*.sh |
| 設定パーサー | dasel | scripts/read-config.sh |
| プロンプト定義 | Markdown | steps/**/*.md |
| CI | GitHub Actions | .github/ |

## 依存関係

- scripts/ は steps/ から参照される（パス解決はスキルベースディレクトリ相対）
- aidlc-setup は aidlc とは独立したスキル（委譲パターン）
- 共通ステップ（common/）は全フェーズから参照

## 特記事項

- メタ開発リポジトリのため、prompts/package/ が rsync 元（docs/aidlc/ は直接編集禁止）
- 総点検の主対象: steps/ 配下の .md + scripts/ 配下の .sh
