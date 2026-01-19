# Unit 003: label-cycle-issues.sh新規作成 - 実装計画

## 概要

複数Issueへのサイクルラベル付けを一括で行うスクリプト（label-cycle-issues.sh）を新規作成し、inception.mdに統合する。

## 変更対象ファイル

| ファイル | 変更種別 | 説明 |
|---------|---------|------|
| `prompts/package/bin/label-cycle-issues.sh` | 新規作成 | 一括ラベル付けスクリプト |
| `prompts/package/prompts/inception.md` | 修正 | スクリプト呼び出しに変更 |

**注意**: `docs/aidlc/` は `prompts/package/` の rsync コピーのため、直接編集禁止（rules.md参照）

## 実装計画

### Phase 1: 設計（コードは書かない）

1. **ドメインモデル設計**
   - スクリプトの責務と入出力を定義
   - issue-ops.shとの連携方式を定義

2. **論理設計**
   - コマンドラインインターフェース設計
   - エラーハンドリング方針

3. **設計レビュー**
   - 設計承認を取得

### Phase 2: 実装（設計承認後）

1. **label-cycle-issues.sh新規作成**
   - Unit定義ファイルからIssue番号抽出
   - issue-ops.shを呼び出してラベル付与
   - 出力形式の統一

2. **inception.md修正**
   - 個別コマンドをスクリプト呼び出しに置換

3. **テストと統合**
   - 動作確認
   - AIレビュー（required設定）

## 完了条件チェックリスト

- [ ] label-cycle-issues.shスクリプトの新規作成
- [ ] Unit定義ファイルからIssue番号を抽出する機能
- [ ] 抽出した各Issueにサイクルラベルを一括付与する機能
- [ ] inception.mdでスクリプトを呼び出すように修正
- [ ] 変更後のinception.mdがmarkdownlintをパスすることを確認

## 技術的考慮事項

- Unit定義ファイルパス: `docs/cycles/{{CYCLE}}/story-artifacts/units/*.md`
- Issue番号抽出パターン: `^- #[0-9]+`（`## 関連Issue` セクション内）
- ラベル形式: `cycle:{{CYCLE}}`
- 出力形式: `issue:{番号}:labeled:cycle:{サイクル}`
- Issue番号が見つからない場合は正常終了（エラーにしない）
- issue-ops.sh（既存スクリプト）を内部で呼び出す
