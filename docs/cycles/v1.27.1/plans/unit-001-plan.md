# Unit 001 計画: post-merge-cleanup マルチリモート対応

## 概要

post-merge-cleanup.sh の resolve_remote() を改善し、ローカルブランチ削除済み時にもマルチリモート環境で正しいリモートを特定できるようにする。

## 関連Issue

- #390: ローカルブランチ削除済み時のリモート判定がoriginフォールバック
- #389: ブランチ不在時のマルチリモート対応

## 変更対象ファイル

- `prompts/package/bin/post-merge-cleanup.sh` — resolve_remote() 関数の改修（正本）
- `docs/aidlc/bin/post-merge-cleanup.sh` — rsync同期で反映

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: resolve_remote() のフォールバックロジック設計
2. **論理設計**: refs/remotes/ → git ls-remote の2段階探索アルゴリズム設計
3. **設計レビュー**

### Phase 2: 実装

4. **コード生成**: resolve_remote() のフォールバック改善
   - ブランチ名が空または git config で解決できない場合の新ロジック:
     1. `git for-each-ref refs/remotes/*/branch_name` でローカルキャッシュからリモート探索
     2. 見つからない場合、`git ls-remote` で各リモートを確認（オフライン時スキップ）
     3. 該当ブランチが見つからない場合、警告出力してoriginフォールバック
   - シングルリモート環境では従来と同等の結果を保証
5. **テスト生成**: BDD/TDDに従ったテスト作成
6. **統合とレビュー**: ビルド・テスト実行、AIレビュー

## 完了条件チェックリスト

- [x] resolve_remote()のブランチ不在時フォールバックロジックの改善
- [x] refs/remotes/ またはgit ls-remoteを使用したリモートブランチ探索
- [x] 該当ブランチが見つからない場合の警告出力
