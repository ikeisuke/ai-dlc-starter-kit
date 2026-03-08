# Unit: jjサポート非推奨化 - スクリプト

## 概要
シェルスクリプトのjj関連処理に非推奨警告（`warn:jj-deprecated`）を追加する。コードは残存させ機能は維持する。

## 含まれるユーザーストーリー
- ストーリー 5: jjサポート関連処理の非推奨化（スクリプト部分）

## 責務
- `prompts/package/bin/squash-unit.sh` で `--vcs jj` 指定時に非推奨警告を出力
- `prompts/package/bin/aidlc-git-info.sh` でjj環境検出時に非推奨警告を出力
- `prompts/package/bin/aidlc-cycle-info.sh` でjj優先ブランチ取得時に非推奨警告を出力
- `prompts/package/bin/migrate-config.sh` の `[rules.jj]` セクション追加時に非推奨コメントを付加
- 全スクリプトのjj処理ロジックは変更なし（機能維持）

## 境界
- プロンプトファイルへの非推奨注記追加はUnit 006の責務
- 編集対象は `prompts/package/bin/` 配下（`docs/aidlc/bin/` は `prompts/package/` からのrsync同期先であり直接編集しない）
- jjコードの削除は行わない（機能維持）

## 依存関係

### 依存する Unit
- Unit 006: deprecate-jj-prompts（依存理由: プロンプト側の非推奨注記が完了している必要がある）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- 非推奨警告の出力フォーマット: `warn:jj-deprecated`（既存のwarnプレフィックスパターンに準拠）
- jj処理ロジック自体は変更なし（警告出力の追加のみ）
- git処理への影響がないことをスクリプトの動作確認で検証

## 実装優先度
High

## 見積もり
小規模（各スクリプトに警告出力を追加するのみ）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-07
- **完了日**: 2026-03-07
- **担当**: AI
