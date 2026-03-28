# Unit: ローカルバックログ廃止

## 概要
バックログ管理モード設定（`[rules.backlog].mode`）を廃止し、GitHub Issue一本化する。設定項目自体を廃止し、バックログは常にGitHub Issueに記録する。旧設定が残っている場合は警告を出力する。

## 含まれるユーザーストーリー
- ストーリー 2: ローカルバックログの廃止 (#423)

## 関連Issue
- #423

## 責務
- defaults.tomlから`[rules.backlog]`セクション削除
- resolve-backlog-mode.shを常に`issue`を返すように簡素化（旧設定検出時はstderr警告）
- プロンプト・ステップファイルからbacklog_mode条件分岐を全削除（Issue方式に統一）
- agents-rules.mdのバックログ管理をIssue固定に簡素化
- init-cycle-dir.shのバックログディレクトリ作成を無条件スキップ
- migrate-detect.shのバックログディレクトリ検出をmode非依存に更新
- migrate-config.shの`[rules.backlog]`追加処理を廃止
- env-info.shのbacklog.mode出力を削除
- ガイド・テンプレート・設定例の更新（backlog-management.md、backlog-registration.md、config.toml.example、aidlc.toml.template等）
- prompts/package/配下の正本ファイル更新（sync-package.shでdocs/aidlc/に同期）

## 境界
- 既存の`.aidlc/cycles/backlog/`ディレクトリの自動削除は含まない
- 移行処理での読み取りは許可（既存資産検出のため）

## 依存関係

### 依存するUnit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし

## 技術的考慮事項
- 旧設定利用者へのbreaking changeを避けるフォールバック方式
- 影響範囲が広い（複数プロンプト・スクリプト）

## 実装優先度
High

## 見積もり
中規模（設定変更＋複数プロンプト・スクリプト更新）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-28
- **完了日**: 2026-03-28
- **担当**: @claude
- **エクスプレス適格性**: -
- **適格性理由**: -
