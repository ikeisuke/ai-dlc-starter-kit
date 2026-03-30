# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.15.1 - スキル管理の標準化とツール互換性改善

## 開発の目的
AI-DLCスターターキットのスキル管理をKiroの標準形式に対応させ、AIDLC固有のレビュースキルを追加し、既存ツールの互換性問題を修正する。これにより、複数のAIツール間での一貫したスキル呼び出しと、Inception Phase成果物の品質向上を実現する。

## ターゲットユーザー
AI-DLCスターターキットを使用する開発者（Claude Code、Kiro等の複数AIツール利用者）

## スコープ

### 対象（In Scope）

| Issue | タイトル | 対象コンポーネント | 依存Issue | 並行可否 |
|-------|---------|------------------|----------|---------|
| #192 | Kiro .kiro/skills/ 標準呼び出し対応への移行 | .kiro/skills/, スキル定義ファイル | なし | 可 |
| #191 | AIDLC専用レビュースキル: ユーザーストーリー・インテントレビュー | docs/aidlc/skills/, レビューフロープロンプト | なし | 可 |
| #189 | upgrading-aidlc: setup-prompt.md のローカル探索ステップを省略する | docs/aidlc/skills/upgrading-aidlc/ | なし | 可 |
| #190 | migrate-backlog.sh: macOS sed互換性エラー（日本語文字範囲） | docs/aidlc/bin/migrate-backlog.sh | なし | 可 |

### 対象外（Out of Scope）

- #164: セミオートモードの実装
- #31: GitHub Projects連携

## ビジネス価値
- Kiroの標準スキル呼び出し方式に対応することで、Kiroユーザーの利便性が向上する
- AIDLC専用レビュースキルにより、インテントやユーザーストーリーの品質チェックが自動化される
- upgrading-aidlcスキルの簡略化で、アップグレード体験が改善される
- macOS sed互換性修正で、gitモード利用時のバックログ移行が正常に動作する

## 成功基準
- #192: Kiroの `.kiro/skills/` に既存スキル定義を配置し、Kiro CLIから `skill://` 参照で呼び出しが成功すること。Claude Code側の既存スキル呼び出し（`skill="reviewing-code"` 等）も引き続き動作すること
- #191: AIDLC専用レビュースキル（`reviewing-inception` 等）が作成され、`docs/aidlc/prompts/common/review-flow.md` のレビュー種別マッピングに追加されていること。Intent承認前・ユーザーストーリー承認前のタイミングでスキルが呼び出されること
- #189: upgrading-aidlcスキルの実行時にsetup-prompt.mdのローカル探索ステップが実行されず、スターターキットリポジトリから直接取得されること
- #190: `docs/aidlc/bin/migrate-backlog.sh --dry-run` がmacOS（BSD sed）環境でエラーなく完了し、日本語タイトルを含むバックログのスラッグ生成が正常に行われること

## 期限とマイルストーン
パッチリリース（v1.15.1）として、単一サイクルで完了

## 制約事項
- `docs/aidlc/` は直接編集禁止（`prompts/package/` を編集し、Operations Phaseでrsync反映）
- Claude CodeとKiroの両方で動作するスキル形式を維持すること
- 既存スキルの後方互換性を保つこと

## コンポーネント依存関係

- `skill-loader`（Kiro）→ `.kiro/skills/` ディレクトリ配置
- `skill-loader`（Claude Code）→ `.claude/skills/` ディレクトリ配置（既存、変更なし）
- `reviewing-inception` スキル → Inception Phase成果物（intent.md, user_stories.md）
- `upgrading-aidlc` スキル → スターターキットリポジトリの `setup-prompt.md`
- `migrate-backlog.sh` → BSD sed / GNU sed（OS依存）

## 不明点と質問（Inception Phase中に記録）

[Question] サイクルのテーマ・方向性
[Answer] 「スキル管理の標準化とツール互換性改善」で合意

[Question] #192と#191の依存関係
[Answer] 依存関係なし。それぞれ独立して対応可能

[Question] スコープの除外事項
[Answer] #164（セミオートモード）、#31（GitHub Projects連携）は対象外。その他の除外事項なし
