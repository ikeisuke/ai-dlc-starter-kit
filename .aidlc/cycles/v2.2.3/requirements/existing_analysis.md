# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
skills/aidlc/
├── SKILL.md (13KB) — オーケストレーター定義
├── version.txt
├── config/ — デフォルト設定
├── guides/ — ガイドドキュメント
├── scripts/ — 実行スクリプト（lib/, tests/）
├── steps/ — フェーズ別実行ステップ
│   ├── common/ (16ファイル) — 共通ステップ
│   ├── inception/ (6ファイル) — Inception Phase
│   ├── construction/ (4ファイル) — Construction Phase
│   └── operations/ (5ファイル) — Operations Phase
└── templates/ — ドキュメントテンプレート
```

## アーキテクチャ・パターン

- **オーケストレーターパターン**: SKILL.mdがエントリポイントとなり、フェーズ別ステップファイルに処理を委譲
- **プロンプトチェーン**: ステップファイルがAIエージェントへの指示として順次読み込まれる
- **設定駆動**: `.aidlc/config.toml` + `defaults.toml` のマージ構成で動作を制御
- 根拠: SKILL.md の引数ルーティング、preflight.md の設定値取得フロー

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash（スクリプト）、Markdown（プロンプト） | scripts/*.sh, steps/**/*.md |
| 設定形式 | TOML | .aidlc/config.toml, config/defaults.toml |
| 外部ツール | gh CLI, dasel, codex CLI | scripts/env-info.sh, preflight.md |

## 依存関係

### 今回の変更対象ファイルの依存マップ

| 変更対象 | 参照元（影響を受けるファイル） |
|---------|---------------------------|
| session-continuity.md | SKILL.md, inception/01-setup.md, construction/01-setup.md, operations/01-setup.md, context-reset.md, compaction.md |
| preflight.md | SKILL.md（共通初期化フローから参照） |
| SKILL.md | 全フェーズのエントリポイント |
| operations-release.md | operations/02-deploy.md から参照 |
| review-flow.md | 各フェーズのレビューステップから参照 |
| rules-automation.md | semi_auto判定時に参照 |

### session-state.md 参照箇所（廃止影響範囲）

- `steps/common/session-continuity.md` — 生成・復元ロジック本体
- `steps/inception/01-setup.md` — 中断時の保存指示
- `steps/construction/01-setup.md` — 同上
- `steps/operations/01-setup.md` — 同上
- `steps/common/context-reset.md` — 中断時の保存指示
- `steps/common/compaction.md` — コンパクション復帰時の参照
- `guides/troubleshooting.md` — トラブルシューティング

## 特記事項

- preflight.md（9.1KB）は共通ステップの中で最大。出力フォーマットの冗長な説明が圧縮余地
- session-continuity.md（2.4KB）のうちsession-state.md関連が大半。廃止でファイル自体を大幅簡略化可能
- Operations Phaseのマージフロー（7.13）にはauto-merge対応がない。gh pr merge --auto の追加が必要
