# 既存コードベース分析

v2.1.0の分析をベースに、v2.1.1で修正対象となるファイル・領域に特化して記載。

## ディレクトリ構造・ファイル構成

### v2.1.0からの変更点
v2.1.0でレビュースキルがタイミングベースに再構成された:

```text
skills/
├── reviewing-construction-code/     # Construction: コード生成後
├── reviewing-construction-design/   # Construction: 設計レビュー
├── reviewing-construction-integration/ # Construction: 統合とレビュー
├── reviewing-construction-plan/     # Construction: 計画承認前
├── reviewing-inception-intent/      # Inception: Intent承認前
├── reviewing-inception-stories/     # Inception: ストーリー承認前
├── reviewing-inception-units/       # Inception: Unit定義承認前
├── reviewing-operations-deploy/     # Operations: デプロイ計画承認前
├── reviewing-operations-premerge/   # Operations: PRマージ前
└── write-history/                   # 履歴記録スキル（v2.1.0で追加）
```

### v2.1.1修正対象ファイル群

| Issue | 対象ファイル/領域 |
|-------|------------------|
| #493 | steps/inception/, steps/construction/, steps/operations/ (タスク管理指示の強化) |
| #494 | skills/write-history/SKILL.md, skills/aidlc-setup/ (パーミッションテンプレート) |
| #495 | steps/common/review-flow.md (review-summary作成の必須化) |
| #497 | steps/common/rules.md, steps/construction/ (スコープ縮小時のユーザー確認ルール) |
| #498 | steps/construction/04-completion.md (Unit完了時の要件カバー率照合) |
| #499 | skills/aidlc-migrate/scripts/ (starter_kit_version更新処理) |
| #490 | skills/aidlc-migrate/scripts/migrate-detect.sh (テンプレート自動削除判定) |
| #491 | skills/reviewing-*/SKILL.md (Codex呼び出しをcodexスキル経由に変更) |
| #496 | steps/inception/05-completion.md (意思決定記録ステップの強化) |
| #500 | bin/post-merge-sync.sh (リモートブランチ存在確認の追加) |

## アーキテクチャ・パターン

### レビュースキル構成（v2.1.0でタイミングベースに再構成済み）
- 各レビュースキルは独立したSKILL.mdを持ち、Codex/Claude/Geminiの外部CLI呼び出しを内包
- #491の対応により、Codex呼び出しをcodexスキル経由に統一する

### ステップファイルのフロー制御
- review-flow.mdがレビューフロー全体を制御
- 各フェーズのステップファイルがreview-flow.mdを参照してレビューを実行
- #495でreview-summary.md作成がレビュー完了時の必須ステップとして強化される

### マイグレーションスクリプト構成
- aidlc-migrate/scripts/にdetect, apply-config, verifyの3段階スクリプト
- #499でverifyまたはapply-configにstarter_kit_version更新を追加
- #490でdetect.shのハッシュ比較ロジックを修正

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| スクリプト | Bash (POSIX互換) | scripts/*.sh, bin/*.sh |
| 設定管理 | TOML (dasel) | config/defaults.toml, .aidlc/config.toml |
| プロンプト | Markdown | steps/**/*.md, SKILL.md |
| CI/CD | GitHub Actions | .github/workflows/ |
| パッケージ管理 | Claude Code Plugin | .claude-plugin/marketplace.json |

## 依存関係

### 修正対象間の依存
- #493（タスクリスト駆動）→ #495（review-summary作成）、#496（意思決定記録）: タスクリストにレビューと意思決定記録のステップを含めることで工程漏れを防止
- #497（スコープ縮小防止）→ #498（残課題提示）: スコープ縮小の検出と残課題の可視化は相互補完的
- #499（version更新）→ #490（テンプレート削除判定）: いずれもaidlc-migrateスキルの修正

### 影響が限定的なIssue（独立修正可能）
- #494: write-historyスキルのパス修正（他のスキルに影響なし）
- #491: reviewingスキルのCodex呼び出し統一（各スキル内の変更のみ）
- #500: post-merge-sync.shの修正（bin/配下の独立スクリプト）

## 特記事項

- v2.1.0でレビュースキルがタイミングベースに再構成されたため、#491の対応は9つのレビュースキル全てに適用が必要
- #490のハッシュ比較問題は利用プロジェクト（スキルがプラグインとしてインストールされた環境）でのみ発生し、メタ開発リポジトリでは再現しない
- #493の「タスクリスト駆動」は全フェーズが対象だが、v2.1.1ではステップファイルへの指示強化に限定し、新たなスクリプトやツール追加は行わない
