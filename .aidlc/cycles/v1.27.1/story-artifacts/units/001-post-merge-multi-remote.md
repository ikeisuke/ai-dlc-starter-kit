# Unit: post-merge-cleanup マルチリモート対応

## 概要
post-merge-cleanup.shのresolve_remote()を改善し、ローカルブランチ削除済み時にもマルチリモート環境で正しいリモートを特定できるようにする。

## 含まれるユーザーストーリー
- ストーリー 1: post-merge-cleanup.sh マルチリモート対応（#390 + #389）

## 責務
- resolve_remote()のブランチ不在時フォールバックロジックの改善
- refs/remotes/ またはgit ls-remoteを使用したリモートブランチ探索
- 該当ブランチが見つからない場合の警告出力

## 境界
- worktree操作ロジックの変更は含まない
- mainブランチの最新化（step_1〜step_4）のロジックは変更しない

## 依存関係

### 依存する Unit
なし

### 外部依存
- git（ls-remote, for-each-ref）

## 非機能要件（NFR）
- **パフォーマンス**: git ls-remoteはネットワークアクセスを伴うため、先にローカルrefs/remotes/を確認する
- **セキュリティ**: ls-remote探索時の資格情報保護（credential.helper=空、SSH hardening）。全リモートへの外向き接続は既知リスクとして受容（設計ドキュメントに記載）
- **スケーラビリティ**: 該当なし
- **可用性**: オフライン時はrefs/remotes/のみで判定（ls-remoteスキップ）

## 技術的考慮事項
- 正本は `prompts/package/bin/post-merge-cleanup.sh` を編集
- `docs/aidlc/bin/post-merge-cleanup.sh` はrsync同期で反映
- シングルリモート環境では従来のoriginフォールバックと同等の結果になること

## 実装優先度
High

## 見積もり
小規模（resolve_remote関数の改修 + テスト）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-22
- **完了日**: 2026-03-22
- **担当**: @ai
