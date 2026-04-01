# ドメインモデル: 運用安定化

## 概要

write-historyスキルのパス修正、reviewingスキルのCodex呼び出し統一、post-merge-sync.shのエラーハンドリング改善の3つの独立した修正の影響範囲と変更パターンを整理する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## エンティティ（Entity）

### write-historyスキル
- **ID**: `skills/write-history/SKILL.md`
- **属性**:
  - scriptPath: string - スクリプト実行パス（現状: `scripts/write-history.sh`）
  - description: string - スキルの説明
- **振る舞い**:
  - executeScript: SKILL.md内のスクリプトパスに従い`write-history.sh`を実行する
- **問題**: スクリプトパス `scripts/write-history.sh` はaidlcスキルのベースディレクトリからの相対パス。write-historyスキルのベースディレクトリ（`skills/write-history/`）には`scripts/`が存在しない。スキル実行時のパス解決はSKILL.mdのベースディレクトリが起点となるため、パスが解決できない

### settings-template（パーミッション設定テンプレート）
- **ID**: `skills/aidlc/config/settings-template.json`
- **属性**:
  - allowList: string[] - 自動許可されるツール操作のリスト
  - askList: string[] - 確認を要求する操作のリスト
- **振る舞い**:
  - providePermissions: aidlc-setupスキルがこのテンプレートを読み込み、プロジェクトの`.claude/settings.json`に適用する
- **所有関係**: `aidlc`スキルが所有。`aidlc-setup`スキルは利用する側

### reviewingスキル（9種共通構造）
- **ID**: `skills/reviewing-{type}/SKILL.md`（9ファイル）
- **属性**:
  - reviewType: string - レビュー種別（code, architecture, security, inception等）
  - codexCommand: string - Codex実行コマンド（現状: `codex exec -s read-only -C . "<指示>"`)
  - claudeCommand: string - Claude実行コマンド
  - geminiCommand: string - Gemini実行コマンド
  - resumeCommand: string - セッション継続コマンド
  - allowedTools: string - フロントマターのallowed-tools
- **振る舞い**:
  - executeReview: 指定されたCLIツールでレビューを実行する
  - resumeSession: 前回セッションを継続する

### post-merge-sync.sh
- **ID**: `bin/post-merge-sync.sh`
- **属性**:
  - dryRun: boolean - ドライランモード
  - yes: boolean - 自動承認モード
  - parentRepo: string - 親リポジトリパス
- **振る舞い**:
  - deleteRemoteBranch: リモートブランチを削除する
  - checkRemoteBranchExists: リモートブランチの存在を確認する（**新規追加**）

## 値オブジェクト（Value Object）

### BranchDeletionResult
- **属性**:
  - status: enum(`deleted`, `skipped`, `warn`) - 削除結果
  - reason: string - 理由（`remote`, `already-deleted`, `remote-delete-failed`）
  - branch: string - ブランチ名
- **不変性**: 結果は一度確定したら変わらない
- **等価性**: status + reason + branch の組み合わせ

### SkillPermission
- **属性**:
  - type: enum(`allow`, `ask`) - 許可種別
  - pattern: string - パーミッションパターン（例: `Skill(write-history)`）
- **不変性**: 設定テンプレート内のエントリは固定
- **等価性**: pattern の文字列一致

## 集約（Aggregate）

### reviewingスキル群
- **集約ルート**: 共通契約（計画ファイルの「#491共通契約」セクション）
- **含まれる要素**: 9つのreviewingスキルSKILL.md
- **境界**: Codex実行コマンドセクションの変更のみ。レビュー観点・出力フォーマット・セルフレビューモードは各スキル固有
- **不変条件**: 全9スキルが同一のCodex呼び出しパターンを使用すること

### パーミッション設定
- **集約ルート**: settings-template.json
- **含まれる要素**: allowList、askList
- **境界**: aidlcスキルが所有する設定テンプレートの範囲
- **不変条件**: aidlc-setupスキルが利用するテンプレートとの整合性

## ドメインサービス

### リモートブランチ削除サービス（post-merge-sync.sh内）
- **責務**: マージ済みリモートブランチの安全な削除
- **操作**:
  - checkAndDeleteRemoteBranch: `git ls-remote --exit-code`で存在確認→存在すれば`git push origin --delete`→結果を`BranchDeletionResult`として返す

## ユビキタス言語

- **スキルベースディレクトリ**: SKILL.mdが配置されているディレクトリ。パス解決の起点
- **設定テンプレート**: `settings-template.json`。aidlc-setupスキルがプロジェクトに適用するパーミッション設定の雛形
- **codexスキル経由**: `codex exec`コマンドをcodexスキルプラグインのインターフェースを通じて実行すること
- **自動削除済みブランチ**: GitHubの「Automatically delete head branches」設定によりPRマージ時に自動削除されたリモートブランチ

## 不明点と質問（設計中に記録）

なし（3つのIssueの対象ファイルが完全に独立しており、要件が明確）
