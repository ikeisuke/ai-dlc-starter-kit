# 実装記録: backlog.md移行処理

## 実装日時
2025-12-25

## 作成ファイル

### ソースコード
- `prompts/package/prompts/setup.md` - ステップ6「旧形式バックログ移行」を追加

### テスト
- 本ファイル内「テストシナリオ」セクション参照（手動テスト）

### 設計ドキュメント
- `docs/cycles/v1.5.2/design-artifacts/domain-models/backlog-migration_domain_model.md`
- `docs/cycles/v1.5.2/design-artifacts/logical-designs/backlog-migration_logical_design.md`

## テストシナリオ（BDD形式）

### シナリオ1: 旧形式ファイルが存在しない場合

```gherkin
Feature: 旧形式バックログ移行
  As a ユーザー
  I want to 旧形式backlog.mdが存在しない場合はスキップされる
  So that 不要な処理を実行しない

Scenario: 旧形式ファイルが存在しない
  Given docs/cycles/backlog.md が存在しない
  When setup.md のステップ6を実行する
  Then 移行確認は表示されない
  And 「完了時の作業」に進む
```

**テスト手順**:
1. `docs/cycles/backlog.md` が存在しないことを確認
2. setup.md を読み込んでサイクルを開始
3. ステップ6で「OLD_BACKLOG_NOT_EXISTS」が出力されることを確認
4. 移行確認なしで完了時の作業に進むことを確認

### シナリオ2: 旧形式ファイルが存在し、移行を実行する場合

```gherkin
Scenario: 旧形式ファイルが存在し移行を承認
  Given docs/cycles/backlog.md が存在する
  And 延期タスクが2件、次サイクル検討タスクが3件ある
  When setup.md のステップ6を実行する
  And 移行確認で「Y」を選択
  Then バックアップファイル docs/cycles/backlog.md.bak が作成される
  And docs/cycles/backlog/ に5件のファイルが作成される
  And 移行結果サマリが表示される
```

**テスト手順**:
1. 現在の `docs/cycles/backlog.md` を使用
2. setup.md を読み込んでサイクルを開始
3. ステップ6で移行確認が表示されることを確認
4. 「Y」を選択
5. バックアップファイルが作成されることを確認
6. backlog/ ディレクトリに適切なファイルが作成されることを確認

### シナリオ3: 移行を拒否する場合

```gherkin
Scenario: 移行を拒否
  Given docs/cycles/backlog.md が存在する
  When setup.md のステップ6を実行する
  And 移行確認で「n」を選択
  Then 移行処理はスキップされる
  And docs/cycles/backlog.md は変更されない
  And 「完了時の作業」に進む
```

**テスト手順**:
1. 移行確認で「n」を選択
2. backlog.md が変更されていないことを確認
3. 完了時の作業に進むことを確認

### シナリオ4: 完了済み項目のスキップ

```gherkin
Scenario: 完了済み項目をスキップ
  Given docs/cycles/backlog.md に取消線付き項目がある
  When 移行処理を実行する
  Then 取消線付き項目は移行されない
  And スキップ件数が結果サマリに表示される
```

**テスト手順**:
1. 現在の `docs/cycles/backlog.md` 内の `~~取消線~~` 項目を確認
2. 移行実行後、これらの項目がファイル化されていないことを確認
3. サマリに「スキップ（完了済み）: X件」が表示されることを確認

### シナリオ5: 重複ファイルのスキップ

```gherkin
Scenario: 既存ファイルとの重複を検出
  Given docs/cycles/backlog/ に同名ファイルが既に存在する
  When 移行処理を実行する
  Then 重複するファイルは上書きされない
  And スキップ件数が結果サマリに表示される
```

**テスト手順**:
1. `docs/cycles/backlog/` に既存ファイルがあることを確認
2. 移行実行後、既存ファイルが変更されていないことを確認
3. サマリに「スキップ（重複）: X件」が表示されることを確認

## ビルド結果
N/A（プロンプトファイルのためビルド不要）

## テスト結果
未実行（統合とレビューで実行予定）

## コードレビュー結果
- [x] セキュリティ: OK（上書き防止、バックアップ機能あり）
- [x] コーディング規約: OK（既存setup.mdの形式に準拠）
- [x] エラーハンドリング: OK（スキップ条件を明確化）
- [x] テストカバレッジ: OK（主要シナリオをカバー）
- [x] ドキュメント: OK（処理手順を詳細に記載）

## 技術的な決定事項
1. **AIによる解析**: Bashスクリプトではなく、AIがMarkdownを読み込んで解析・変換する方式を採用
   - 理由: 複雑なMarkdown構造の解析はAIの方が柔軟に対応可能
2. **バックアップ方式**: タイムスタンプ付き `.bak.[YYYYMMDD_HHMMSS]` を採用
   - 理由: 再実行時に前回のバックアップを上書きしない（MCPレビュー指摘対応）
3. **プレフィックス追加**: `deferred-` を新規追加
   - 理由: 「延期タスク」を既存プレフィックス（feature-, chore-等）と区別
4. **セキュリティガード**: ファイル内容をデータとしてのみ扱う明示的な指示を追加
   - 理由: プロンプトインジェクション防止（MCPレビュー指摘対応）
5. **スキップ条件の限定**: 「完了」判定をタイトル行のみに限定
   - 理由: 本文中の言及で誤スキップを防止（MCPレビュー指摘対応）

## 課題・改善点
1. **日本語スラッグ**: 現在は日本語を除去するが、将来的にはローマ字変換も検討
2. **大量項目**: 100件以上の項目がある場合のパフォーマンス検証が必要
3. **同名タイトル重複**: バックログ `chore-backlog-migration-duplicate-handling.md` に記録済み

## 状態
**完了**

## 備考
- 実装場所: `prompts/package/prompts/setup.md`（rules.mdに従い、docs/aidlc/は直接編集しない）
- Operations Phase の rsync で `docs/aidlc/` に反映される
