# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
skills/aidlc/           # コアスキル（AIエージェントオーケストレーター）
  SKILL.md              # エントリポイント・ルーティング定義
  steps/                # フェーズ別・共通ワークフロー定義
    common/             # 共通ステップ（14ファイル）
    inception/          # Inception Phase（5-6ステップ）
    construction/       # Construction Phase（4ステップ）
    operations/         # Operations Phase（4ステップ）
    setup/              # Setup Phase（3ステップ）
    migrate/            # Migration Phase（3ステップ）
  scripts/              # シェルスクリプト（約50本）
    lib/                # 共通ライブラリ（bootstrap, toml-reader, validate, version）
  templates/            # Markdownテンプレート（30+）
  config/               # 設定テンプレート・デフォルト値（TOML/JSON）
  guides/               # 運用ガイド（23ファイル）
skills/reviewing-*/     # レビュースキル（code, architecture, security, inception）
.aidlc/                 # プロジェクト固有データ（設定・サイクル）
  config.toml           # プロジェクト共有設定
  rules.md              # 追加ルール
  cycles/               # サイクルデータ（requirements, story-artifacts, etc.）
```

## アーキテクチャ・パターン

- **スキルベースプラグインアーキテクチャ**: SKILL.mdがオーケストレーターとして引数ルーティング・フェーズ制御を担当
- **フェーズベースワークフロー**: Inception→Construction→Operationsの3フェーズ + Setup/Migrate独立フロー
- **共通初期化パターン**: 全フェーズで共通の4ステップ初期化（agents-rules→rules→preflight→session-continuity）
- **設定駆動型**: config.toml + defaults.tomlの多層設定でAI動作を制御

根拠: SKILL.mdの引数ルーティングセクション、steps/common/配下14ファイルの共通パターン

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash/Zsh (スクリプト), Markdown (ワークフロー定義) | scripts/*.sh, steps/**/*.md |
| 設定管理 | TOML | .aidlc/config.toml, config/defaults.toml |
| データ抽出 | dasel | scripts/lib/toml-reader.sh |
| GitHub連携 | gh CLI | scripts/check-gh-status.sh, scripts/issue-ops.sh |
| バージョン管理 | Git (cycle/*ブランチ戦略) | scripts/setup-branch.sh |

## 依存関係

- **SKILL.md → steps/**: フェーズ別ステップファイルを順に読み込み
- **steps/ → scripts/**: ステップファイルからスクリプトを呼び出し（read-config.sh, write-history.sh等）
- **steps/ → templates/**: 成果物作成時にテンプレート参照
- **scripts/ → scripts/lib/**: 共通ライブラリ関数（TOML解析、バリデーション、バージョン比較）
- **config/defaults.toml → .aidlc/config.toml**: デフォルト値フォールバックチェーン
- 循環依存: なし

## 特記事項

- **10000トークン超ファイル**: review-flow.md (20404), rules.md (10817), 01-setup.md (10196) — #460の対象
- **SKILL.md内にsetup/migrate/feedbackロジックが混在** — #457の対象
- **スクリプト共通化の余地**: バージョン検証が複数スクリプトに分散 — #452の対象
