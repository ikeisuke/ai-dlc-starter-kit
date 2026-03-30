# Unit 002 計画: ローカルバックログ廃止

## 概要

バックログ管理モード設定（`[rules.backlog].mode`）を廃止し、GitHub Issue一本化する。
バックログは常にGitHub Issueに記録する。設定項目`backlog_mode`自体を廃止する。
旧設定が残っている既存ユーザーには警告を出すが、動作は常にIssue方式で固定。

## 設計判断

- **設定項目自体を廃止**: issueしか選択肢がないため`backlog_mode`設定は不要（ユーザー指示）
- **旧設定の扱い**: config.tomlに旧設定が残っていても無視（警告のみ）。削除は強制しない
- **resolve-backlog-mode.sh簡素化**: 常に`issue`を返す。旧設定検出時はstderr警告
- **migrate-detect.sh更新**: バックログディレクトリは常に削除候補として報告（mode非依存）
- **メタ開発ルール**: `prompts/package/`を更新 → `sync-package.sh`で`docs/aidlc/`に同期（直接編集禁止）

## 変更対象ファイル

### スクリプト

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/config/defaults.toml` | `[rules.backlog]`セクション削除 |
| `skills/aidlc/scripts/resolve-backlog-mode.sh` | 常に`issue`を返すように簡素化。旧設定検出時はstderr警告 |
| `skills/aidlc/scripts/init-cycle-dir.sh` | バックログディレクトリ作成処理を無条件スキップ（条件分岐削除） |
| `skills/aidlc/scripts/migrate-detect.sh` | バックログディレクトリ検出をmode非依存に変更（常に削除候補） |
| `skills/aidlc/scripts/migrate-config.sh` | backlogセクションのマイグレーション処理を廃止警告に変更 |

### 設定テンプレート・例

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/config/config.toml.example` | `[rules.backlog]`セクション削除 |
| `.aidlc/config.toml` | `[rules.backlog]`セクションにdeprecatedコメント追加 |

### プロンプト・ステップファイル（主要変更）

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/steps/common/agents-rules.md` | バックログ管理テーブル削除→「GitHub Issueに記録」の一文に |
| `skills/aidlc/steps/common/preflight.md` | `check-backlog-mode.sh`実行・`backlog_mode`コンテキスト変数を削除 |
| `skills/aidlc/steps/construction/01-setup.md` | backlog_mode条件分岐全削除、Issue直接記述に統一 |
| `skills/aidlc/steps/construction/03-implementation.md` | バックログ登録のmode分岐削除、Issue方式に統一 |
| `skills/aidlc/steps/common/rules.md` | バックログモード関連の記述削除 |
| `skills/aidlc/steps/common/review-flow.md` | バックログ関連の記述更新 |

### プロンプト・ステップファイル（軽微な変更）

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/steps/inception/01-setup.md` | バックログ関連の記述更新 |
| `skills/aidlc/steps/inception/02-preparation.md` | バックログ関連の記述更新 |
| `skills/aidlc/steps/inception/05-completion.md` | バックログ関連の記述更新 |
| `skills/aidlc/steps/operations/01-setup.md` | バックログ関連の記述更新 |
| `skills/aidlc/steps/operations/02-deploy.md` | バックログ関連の記述更新 |
| `skills/aidlc/steps/operations/04-completion.md` | バックログ関連の記述更新 |
| `skills/aidlc/steps/setup/03-migrate.md` | バックログ関連の記述更新 |

### ガイド・ドキュメント

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/guides/backlog-management.md` | モード分岐削除、Issue方式に統一 |
| `prompts/package/guides/backlog-registration.md` | モード分岐削除、Issue方式に統一 |
| `skills/aidlc/steps/setup/02-generate-config.md` | backlog_mode設定ヒアリング削除 |
| `prompts/setup-prompt.md` | backlog_mode設定ヒアリング削除 |

### 同期

| 対象 | 方法 |
|------|------|
| `docs/aidlc/` 配下 | `sync-package.sh`で自動反映（直接編集禁止） |

### 変更不要ファイル

| ファイル | 理由 |
|---------|------|
| `skills/aidlc/scripts/check-backlog-mode.sh` | resolve-backlog-mode.shに依存するため自動追従 |

## 実装計画

### Phase 1: 設計

1. ドメインモデル設計
2. 論理設計
3. 設計レビュー

### Phase 2: 実装

1. スクリプト変更（defaults.toml、resolve-backlog-mode.sh、init-cycle-dir.sh、migrate-detect.sh、migrate-config.sh）
2. 設定テンプレート更新（config.toml.example、.aidlc/config.toml）
3. プロンプト・ステップファイル変更
4. ガイド・ドキュメント変更
5. sync-package.sh実行
6. AIレビュー＋Markdownlint

## 完了条件チェックリスト

- [ ] defaults.tomlから`[rules.backlog]`セクション削除
- [ ] resolve-backlog-mode.shが常に`issue`を返す
- [ ] 旧設定検出時にstderr警告が出る
- [ ] プロンプトファイルからbacklog_mode条件分岐全削除
- [ ] agents-rules.mdのバックログ管理をIssue固定に簡素化
- [ ] init-cycle-dir.shのバックログディレクトリ作成を無条件スキップ
- [ ] migrate-detect.shのバックログディレクトリ検出をmode非依存に更新
- [ ] ガイド（backlog-management.md、backlog-registration.md）更新
- [ ] 検証: `resolve_backlog_mode`が常に`issue`を返すこと
- [ ] 検証: `init-cycle-dir.sh --dry-run`でbacklogディレクトリが`created`にならないこと
- [ ] 検証: rg残留確認（backlog_mode条件分岐、git-only等の案内文が残っていないこと）
