# Intent（開発意図）

## プロジェクト名
ai-dlc-starter-kit v1.22.3

## 開発の目的
AI-DLCスターターキットのバグ修正、開発体験の改善、およびマルチエージェント環境対応を行う。具体的には、スクリプトのエラーハンドリング修正（exit status伝播、バリデーションスコープ制限）、AI開発プロセスの品質向上（直接実行優先原則の追加）、Kiroエージェント設定のアップデートを実施する。

## ターゲットユーザー
AI-DLCスターターキットを利用する開発者、およびスターターキット自体のメンテナー

## ビジネス価値
- スクリプト失敗時のサイレントエラーを防止し、セットアップの信頼性を向上
- リポジトリ固有のバリデーションがグローバルに適用される問題を解消し、他プロジェクトでの誤動作を防止
- AI開発プロセスにおけるフリクション（間接的アプローチ、不要なバックログ後回し）を削減
- Kiro環境でのAI-DLC利用体験を改善

## スコープ

### In Scope
- #342: `check-bash-substitution.sh` のスコープをスターターキット開発リポジトリ限定に修正
- #343: `setup_claude_permissions` 関数の失敗時exit status伝播修正
- #316: `prompts/package/prompts/common/rules.md` に直接実行優先原則を追加
- #344: `.kiro/agents/aidlc-poc.json` をIssue #344のJSON設定にアップデート

### Out of Scope
- Kiro以外のエージェント環境（Cursor、Windsurf等）の設定追加
- 新規機能の追加（バックログにあるfeature系Issue）
- スクリプトの大規模リファクタリング
- テンプレートの構造変更

## 成功基準
- `setup_claude_permissions` が `result:failed` を返す場合、関数の終了コードが非ゼロになる
- `check-bash-substitution.sh` の実行条件に `project.name = ai-dlc-starter-kit` チェックが含まれ、他リポジトリではスキップされる
- `prompts/package/prompts/common/rules.md` に「直接実行優先原則」セクションが追加され、3つの原則（直接実行優先、バックログ後回し禁止、最小複雑性）が記載されている
- `.kiro/agents/aidlc-poc.json` がIssue #344のボディに記載されたJSON（name, description, tools, allowedTools, toolsSettings, resources）と一致する

## 期限とマイルストーン
- 目標: 2026-03-16 中にPR作成

## 制約事項
- `docs/aidlc/` は直接編集禁止（`prompts/package/` を編集）
- パッチリリースのため、破壊的変更は行わない
- 既存のスクリプトインターフェースとの後方互換性を維持する

## 既存機能への影響

| 変更対象 | 影響を受ける既存機能 | 非影響範囲 | 回帰確認項目 |
|---------|-------------------|-----------|------------|
| `setup_claude_permissions` | `aidlc-setup.sh` のセットアップフロー | 他のセットアップ関数 | 正常時のexit status 0が維持されること |
| `check-bash-substitution.sh` | Operations Phase完了時のバリデーション | 他フェーズのバリデーション | スターターキットリポジトリでは従来通り実行されること |
| `rules.md` | AI-DLCプロンプト全体の行動規範 | 既存ルール（過信防止等） | 既存ルールとの矛盾がないこと |
| Kiro agent設定 | Kiro環境でのAI-DLC実行 | Claude Code環境 | Kiroで設定が正しく読み込まれること |

## 不明点と質問（Inception Phase中に記録）

[Question] #342 check-bash-substitution.shのスコープ制限方法
[Answer] Operations Phase完了時のバリデーションであり、スターターキット開発リポジトリ専用であることを明示・スコープ制限する

[Question] #344 Kiro agent設定のアップデート内容
[Answer] 既存の `.kiro/agents/aidlc-poc.json` を Issue #344 のボディにある詳細設定（allowedTools、toolsSettings等）にアップデートする

## 関連Issue
- #342: check-bash-substitution.sh フックのスコープがグローバルに適用される
- #343: setup_claude_permissions失敗時のexit status伝播
- #316: 直接実行優先原則の追加
- #344: Kiro agent setting
