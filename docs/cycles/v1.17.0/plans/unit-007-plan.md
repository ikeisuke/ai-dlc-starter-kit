# Unit 007 計画: squash-unit.sh 事後squash対応

## 概要

squash-unit.sh に `--retroactive` オプションを追加し、GIT_SEQUENCE_EDITOR + GIT_EDITOR 方式で過去のUnit（HEAD以外）に対する非対話的rebaseによる事後squashを実現する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/bin/squash-unit.sh` | `--retroactive` オプション追加、rebase方式の実装 |
| `prompts/package/prompts/common/commit-flow.md` | Squash統合フローに事後squash手順を追記 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 事後squashのコミット範囲特定ロジック、rebase todo構築、エラーハンドリングの構造を設計
2. **論理設計**: シェルスクリプト内の関数構成、GIT_SEQUENCE_EDITOR/GIT_EDITOR の構築方法、rebase todo編集スクリプトの構成、squash前後の検証方法を設計

### Phase 2: 実装

1. **squash-unit.sh 修正**:
   - `--retroactive` オプションのパース追加
   - `--retroactive` + `--vcs=jj` 排他チェック（`squash:error:unsupported-vcs` で拒否）
   - 対象Unitのコミット範囲特定関数（コミットメッセージのUnit番号パターンマッチ）
   - `--unit` の厳格バリデーション（`^[0-9]{3}$` 形式チェック。`--retroactive` 時は必須）
   - 範囲特定の優先順位: `--base` 明示指定 > `--unit` による自動判定
   - rebase todo編集用bashスクリプトの構築（GIT_SEQUENCE_EDITOR経由、一時ファイル置換方式でsed -i依存を回避）
   - GIT_EDITOR（コミットメッセージ差し替え用）の構築
   - 異常系処理: unit-not-found, dirty-working-tree, conflict
   - `--dry-run` との組み合わせ対応
   - squash前後の `git diff <base>..HEAD` 一致検証

2. **commit-flow.md 更新**:
   - Squash統合フローに事後squash手順セクション追加
   - `--retroactive` の使用条件（gitのみ、jj非対応）を明記
   - `--retroactive` の使い方を記載

3. **テスト**:
   - テストレコード作成（Markdownベース）
   - 正常系: 単一Unit squash、複数中間コミットのsquash
   - 正常系: --dry-run との組み合わせ
   - 異常系: unit-not-found、dirty-working-tree、conflict、unsupported-vcs
   - 互換性: macOS/Linuxでのrebase todo編集

## 技術的考慮事項

- `--retroactive` は明示指定時のみ有効。デフォルトは既存の `git reset --soft` 方式を維持
- **VCS制約**: `--retroactive` は `--vcs=git` のみ対応。`--vcs=jj` 指定時は `squash:error:unsupported-vcs` で即座にエラー終了
- **範囲特定の責務分離**: 通常squash時は呼び出し側（AI）が `--base` を判定する既存設計を維持。`--retroactive` 時はスクリプト内部で `--unit` 番号からコミット範囲を自動特定（事後squashでは中間コミット範囲の判定が複雑なため）。`--base` 明示指定時はそちらを優先
- **rebase todo編集方式**: `sed -i` のOS差異問題を回避するため、bashスクリプト（一時ファイル読み込み→加工→上書き）をGIT_SEQUENCE_EDITORに渡す方式を採用。rebase todoの対象Unitの最初のコミットを reword、残りを fixup、後続Unitは pick のまま
- GIT_EDITOR でコミットメッセージをfeat: メッセージに差し替え
- squash前後で `git diff <base>..HEAD` のツリーが一致することを検証（安全性保証）
- rebase conflict 時は `git rebase --abort` でリカバリし、`squash:error:conflict` を返す
- jj環境での事後squash対応はスコープ外
- **エラーコード一覧**: `squash:error:unit-not-found`, `squash:error:dirty-working-tree`（既存実装と統一）, `squash:error:conflict`, `squash:error:unsupported-vcs`

## 完了条件チェックリスト

- [x] squash-unit.sh に `--retroactive` オプションを追加
- [x] GIT_SEQUENCE_EDITOR + GIT_EDITOR を使った非対話的rebase方式の実装
- [x] 対象Unitのコミット範囲特定（コミットメッセージのUnit番号から）
- [x] 異常系処理（unit-not-found, dirty-working-tree, conflict, unsupported-vcs, rebase-failed）
- [x] `--dry-run` との組み合わせ対応
- [x] commit-flow.md のSquash統合フローに事後squash手順を追記
