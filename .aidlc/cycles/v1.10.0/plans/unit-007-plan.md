# Unit 007 計画: inception.mdサイズ最適化

## 概要

`prompts/package/prompts/inception.md` を最適化し、AIのコンテキスト消費を削減する。

## 現状

- 現在行数: 812行
- 目標行数: 730行以下（10%以上削減）
- 削減目標: 82行以上

## 変更対象ファイル

### 新規作成

1. `prompts/package/guides/ios-version-update.md` - iOSバージョン更新ガイド（外部化）
2. `prompts/package/bin/check-dependabot-prs.sh` - Dependabot PR一覧取得スクリプト
3. `prompts/package/bin/check-open-issues.sh` - オープンIssue一覧取得スクリプト

### 変更

1. `prompts/package/prompts/inception.md` - 外部ファイル参照に置き換え

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 外部化対象セクションの特定と依存関係の整理
2. **論理設計**: 外部ファイルの構成と参照方式の設計
3. **設計レビュー**: ユーザー承認

### Phase 2: 実装

1. **iOSバージョン更新ガイドの外部化**
   - 649-703行（約55行）を`guides/ios-version-update.md`に移動
   - inception.mdに簡潔な参照を残す（5行程度）
   - 削減見込み: 約50行

2. **ヘルパースクリプト作成**
   - `check-dependabot-prs.sh`: Dependabot PR一覧取得
   - `check-open-issues.sh`: オープンIssue一覧取得
   - 既存コマンドをスクリプト化し、エラーハンドリングを追加
   - inception.mdのコマンドを1行のスクリプト呼び出しに置換
   - 削減見込み: 約10行

3. **冗長な説明の簡略化**
   - セットアップコンテキスト確認（240-371行）の詳細説明を外部ガイド参照に変更
   - 重複した説明の統合
   - 削減見込み: 約30行

4. **テスト・検証**
   - 最適化後のinception.mdの行数確認
   - 外部化したセクションが正しく参照されることを確認

## 完了条件チェックリスト

- [ ] 付録・参照資料の外部ファイル化
- [ ] 複雑なbashコマンドのヘルパースクリプト化
- [ ] 冗長な説明の簡略化
- [ ] 最適化後の行数が730行以下（10%以上削減）
- [ ] 全機能が正常動作すること

## リスク・考慮事項

- 外部ファイルが多くなりすぎると、逆に管理コストが増加する
- 参照先が変更された場合の同期維持
