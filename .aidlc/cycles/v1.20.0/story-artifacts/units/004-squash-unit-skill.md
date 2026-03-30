# Unit: squash-unit スキル定義

## 概要
`squash-unit.sh` をスキル呼び出しで実行できるようにするためのSKILL.md定義を作成する。引数の自動解決・dry-runフロー・エラーハンドリングをスキルとして定義し、`commit-flow.md` にスキル呼び出しの推奨を追記する。

## 含まれるユーザーストーリー
- ストーリー 5: squash-unit スキル定義

## 責務
- `prompts/package/skills/squash-unit/SKILL.md` の作成（YAML front matter + 実行フロー）
- `docs/aidlc/skills/squash-unit/SKILL.md` への rsync 同期（upgrading-aidlc スキルで自動実行）
- `.claude/skills/squash-unit` → `../../docs/aidlc/skills/squash-unit` シンボリックリンク作成
- 引数自動解決手順の記述: `--cycle`（ブランチ名から）、`--vcs`（設定から）、`--base`（コミット履歴から）
- dry-run フローの記述: `--dry-run` で対象コミット一覧表示 → 続行確認
- メッセージファイルフロー: Write ツールで一時ファイル作成 → `--message-file` で渡す → 削除
- エラー時のフォールバック案内: `commit-flow.md` の手動フローへの誘導
- retroactive モード対応

## 境界
- `squash-unit.sh` 本体のロジック変更は含まない（スキル定義のみ）
- `commit-flow.md` への追記（スキル呼び出し推奨）は含むが、既存の直接呼び出しフローは維持
- 名前付きサイクル対応とは独立（`squash-unit.sh` は `--cycle` 引数で任意のパスを受容済み）

## 依存関係

### 依存する Unit
- なし（名前付きサイクル機能とは独立して実装可能）

### 外部依存
- `prompts/package/bin/squash-unit.sh`（既存スクリプト、変更なし）
- `prompts/package/prompts/common/commit-flow.md`（追記対象）
- 既存スキル構造（`prompts/package/skills/session-title/` 等を参考）

## 非機能要件（NFR）
- **パフォーマンス**: スキル定義のみのため影響なし
- **セキュリティ**: SKILL.md内の引数解決手順がインジェクションを防止する記述を含むこと
- **スケーラビリティ**: 将来的な `squash-unit.sh` の引数追加に対応可能な記述構造
- **可用性**: スキル呼び出し失敗時の手動フロー案内により操作が停止しない

## 技術的考慮事項
- SKILL.md の YAML front matter: `name: squash-unit`, `description`, `argument-hint` を定義
- 既存スキル（`session-title`, `reviewing-code`, `upgrading-aidlc`）のSKILL.md構造を参考にする
- 実装はサブタスクに分割: (1) SKILL.md作成・配布・リンク整備、(2) 実行フロー記述
- `commit-flow.md` 追記: スキル呼び出しを推奨として記載し、従来の直接呼び出しも維持
- 全変更は `prompts/package/` に対して行う（メタ開発ルール）

## 実装優先度
High

## 見積もり
中（SKILL.md作成と commit-flow.md 追記）

## 関連Issue
- #291 squash-unit.sh スキル化

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-10
- **完了日**: 2026-03-10
- **担当**: @claude
