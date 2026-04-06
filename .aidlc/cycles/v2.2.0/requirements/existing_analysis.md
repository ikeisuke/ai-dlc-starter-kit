# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
skills/
├── aidlc/                          # メインスキル（9,703B SKILL.md）
│   ├── config/                     # defaults.toml(924B), config.toml.example
│   ├── guides/                     # ガイド文書
│   ├── scripts/                    # シェルスクリプト群
│   ├── steps/
│   │   ├── common/                 # 共通ステップ（15ファイル）
│   │   ├── inception/              # Inception Phase（6ファイル）
│   │   ├── construction/           # Construction Phase（4ファイル）
│   │   └── operations/             # Operations Phase（5ファイル）
│   └── templates/                  # テンプレート群
├── aidlc-setup/                    # セットアップスキル
├── reviewing-construction-code/    # 8,000B
├── reviewing-construction-design/  # 6,083B
├── reviewing-construction-integration/ # 5,717B
├── reviewing-construction-plan/    # 5,423B
├── reviewing-inception-intent/     # 5,153B
├── reviewing-inception-stories/    # 5,209B
├── reviewing-inception-units/      # 6,112B
├── reviewing-operations-deploy/    # 5,464B
└── reviewing-operations-premerge/  # 5,730B
```

## 初回ロード量（ベースライン）

### Inception Phase（最大ケース）: **109,623B (~107KB)**

| ファイル | バイト | カテゴリ |
|---------|--------|---------|
| inception/01-setup.md | 14,314 | フェーズ |
| inception/05-completion.md | 12,606 | フェーズ |
| common/review-flow.md | 12,375 | 共通 |
| common/rules.md | 10,891 | 共通 |
| SKILL.md | 9,703 | エントリ |
| common/preflight.md | 9,071 | 共通 |
| inception/04-stories-units.md | 8,014 | フェーズ |
| common/review-flow-reference.md | 7,438 | 共通 |
| inception/03-intent.md | 6,704 | フェーズ |
| common/compaction.md | 6,528 | 共通 |
| inception/02-preparation.md | 5,738 | フェーズ |
| common/task-management.md | 3,885 | 共通 |
| common/commit-flow.md | 3,626 | 共通 |
| common/agents-rules.md | 3,409 | 共通 |
| common/session-continuity.md | 2,274 | 共通 |
| common/phase-responsibilities.md | 196 | 共通 |
| common/progress-management.md | 178 | 共通 |

### Reviewingスキル合計: **52,891B (~52KB)**

9スキル合計。各スキルの共通ボイラープレート（実行コマンド・セッション継続・外部ツール関係・セルフレビューモード）は推定60-70%。

## 圧縮対象の特定

### S16: 先読み指示パターン（32箇所）

| ファイル | 該当行数 |
|---------|---------|
| inception/01-setup.md | 8箇所 |
| construction/01-setup.md | 9箇所 |
| operations/01-setup.md | 9箇所 |
| inception/05-completion.md | 1箇所 |
| construction/04-completion.md | 1箇所 |
| operations/02-deploy.md | 1箇所 |

SKILL.mdのステップ4で全ステップファイルの一括読み込みが指示されているため、ステップファイル内の「今すぐ読み込んで」指示は冗長。

### S7/S13: Reviewingスキル共通セクション

各SKILL.mdの以下セクションが共通:
- 実行コマンド（Codex/Claude/Gemini）: ~300B
- セッション継続: ~300B
- 外部ツールとの関係: ~600B
- セルフレビューモード（手順・指示テンプレート・制約）: ~1,500B
- 合計共通部分: ~2,700B × 9スキル = ~24,300B

固有部分は「レビュー観点」セクションのみ（各300-2,000B程度）。

### S5+: 01-setup.md バージョンチェックテーブル

inception/01-setup.md のステップ6（三角モデル）がバージョン比較の5モード×条件分岐を含む。ステップ6a〜6d（約100-150行、推定5-7KB）。

### #530: rules.linting設定キー不整合

| ファイル | キー名 |
|---------|--------|
| aidlc/config/defaults.toml | `enabled = false` |
| aidlc-setup/templates/config.toml.template | `markdown_lint = false` |
| aidlc/config/config.toml.example | `[rules.linting]`セクション（コメントで旧キー言及） |

### #531: defaults.toml先頭コメント

| ファイル | 現状コメント |
|---------|-------------|
| aidlc/config/defaults.toml | 「プロジェクトの docs/aidlc.toml で上書き可能です」 |
| aidlc-setup/config/defaults.toml | 同上 + 「正本: aidlc スキルの config/defaults.toml」 |

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (スクリプト), Markdown (プロンプト) | scripts/*.sh, steps/**/*.md |
| フレームワーク | Claude Code Skills (AI-DLC) | SKILL.md |
| 主要ツール | dasel v3, gh CLI, git | env-info.sh |

## 依存関係

- **SKILL.md** → steps/common/*.md, steps/{phase}/*.md（一括読み込み）
- **steps/common/review-flow.md** → reviewing-*/SKILL.md（スキル呼び出し）
- **steps/common/preflight.md** → scripts/env-info.sh, scripts/read-config.sh
- **各ステップファイル** → templates/*.md（テンプレート参照）
- **reviewing-*/SKILL.md** → references/session-management.md（各スキル個別コピー）

循環依存: なし

## 特記事項

- Inception Phase初回ロードが107KBで、Issueの「推定80KB超」より大きい（SKILL.mdのステップ4で全ステップ一括読み込みのため）
- review-flow-reference.md（7,438B）は「必要時参照」のはずだが、review-flow.mdから参照指示があり初回ロード対象に含まれる可能性あり
- common/ai-tools.md（4,729B）やcommon/intro.md（1,348B）はInception Phaseでは明示的にロード指示がないがconstruction/operations の01-setup.mdで先読み指示あり
