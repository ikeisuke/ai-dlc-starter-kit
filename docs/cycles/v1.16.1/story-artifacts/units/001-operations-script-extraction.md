# Unit: operations.md定型処理スクリプト化

## 概要
operations.mdの定型処理（リモート同期確認、コミット漏れ確認）をシェルスクリプトに切り出し、プロンプトファイルを1000行以内に削減する。

## 含まれるユーザーストーリー
- ストーリー 1: operations.mdの定型処理スクリプト化
- ストーリー 3: 回帰確認

## 責務
- `validate-remote-sync.sh` の実装（リモート同期確認ロジック）
- `validate-uncommitted.sh` の実装（コミット漏れ確認ロジック）
- operations.mdの該当セクションをスクリプト呼び出しに置き換え
- 回帰確認（ユーザーストーリー3の受け入れ基準に定義された全ケースを実行）

## 境界
- inception.md、construction.mdの修正は行わない（設計のみUnit 002で実施）
- 新規スキルの作成は行わない
- 既存スクリプト（pr-ops.sh等）の改修は行わない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- git（リモート同期確認で使用）
- 既存スクリプトの出力形式規約（key:value形式）

## 非機能要件（NFR）
- **パフォーマンス**: スクリプトのローカル処理部分（git log, git status等）が5秒以内に完了すること（git fetchのネットワーク通信時間は計測対象外）
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- `prompts/package/bin/` にスクリプトを配置（rsyncで `docs/aidlc/bin/` に反映）
- 既存スクリプトと同じ出力形式（`status:ok` / `status:warning` / `status:error`）
- POSIX sh互換を目指すが、既存スクリプトがbash前提ならbashで統一
- operations.mdの修正も `prompts/package/prompts/` を編集

## 関連Issue
- #201: [Backlog] operations.mdの行数削減（1033行→1000行以内）

## 実装優先度
High

## 見積もり
小規模（スクリプト2本 + プロンプト修正）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
