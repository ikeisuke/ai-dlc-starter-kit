# ドメインモデル: Construction Phase確認の自動化

## 概要

Construction PhaseのUnit完了時確認を、ユーザーへの質問形式からAI自身による自動確認に変更する。

## エンティティ

### 履歴ファイル（HistoryFile）

Unit作業の履歴を記録するMarkdownファイル。

- **パス**: `docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md`
  - `{NN}`: 2桁ゼロパディング（例: `01`, `04`, `12`）
- **属性**:
  - cycle: サイクル番号（例: v1.12.1）
  - unitNumber: Unit番号（2桁ゼロパディングされた文字列、例: "04"）
  - content: ファイル内容

### Operations引き継ぎタスク（OperationsTask）

Operations Phaseで実行が必要な手動作業を記録するファイル。

- **パス**: `docs/cycles/{{CYCLE}}/operations/tasks/{NNN}-{task-slug}.md`
- **属性**:
  - taskNumber: タスク番号（3桁ゼロパディング）
  - taskSlug: タスク識別子
  - content: タスク内容

## 値オブジェクト

### AIレビュー実施状態（AIReviewStatus）

- **値**:
  - `IMPLEMENTED`: 実施済み（履歴に記録あり）
  - `NOT_IMPLEMENTED`: 未実施（履歴に記録なし）
  - `FILE_NOT_FOUND`: 履歴ファイルが存在しない

### 引き継ぎタスク存在状態（OperationsTaskStatus）

- **値**:
  - `EXISTS`: タスクあり（1件以上の.mdファイルが存在）
  - `NOT_EXISTS`: タスクなし（.mdファイルが0件、またはディレクトリ自体が存在しない）

**注意**: ディレクトリ未作成と空ディレクトリは同一扱い（`NOT_EXISTS`）とする。

## ドメインサービス

### AIレビュー実施確認サービス（AIReviewCheckService）

**責務**: 履歴ファイルを読み取り、AIレビューが実施されたかを判定する

**入力**:
- cycle: サイクル番号
- unitNumber: Unit番号

**処理フロー**:
1. 履歴ファイルのパスを構築: `docs/cycles/{cycle}/history/construction_unit{unitNumber}.md`
   - `unitNumber`は2桁ゼロパディング済み文字列（例: "04"）
2. ファイルの存在を確認
   - 存在しない → `FILE_NOT_FOUND` を返す
3. ファイル内容を読み取り
4. 以下のパターンを検索（部分一致）:
   - 「AIレビュー」
   - 「レビュー反映」
5. パターンが見つかった → `IMPLEMENTED` を返す
6. パターンが見つからない → `NOT_IMPLEMENTED` を返す

**検出パターンの根拠**:
- 既存の履歴ファイル（v1.5.2〜v1.12.1）を調査した結果、AIレビューを実施したUnitでは「AIレビュー」または「レビュー反映」という記述が含まれている
- write-history.shで記録する際のstep名やcontentに自然に含まれるキーワード
- 現状の履歴記録はUTF-8で統一されており、表記揺れ（大文字小文字等）は発生しない
- 誤検知リスク: 低（これらのキーワードはAIレビュー関連の文脈でのみ使用される）

**誤検知・例外の扱い**:
- 「AIレビュー未実施」のような否定表現が含まれる場合も `IMPLEMENTED` と判定される可能性があるが、実運用上このような記述は発生しない（スキップ時は別形式で記録される）
- 万一誤検知が発生しても、ユーザーは次のステップで「今からAIレビューを実施する」を選択可能なため、影響は軽微

**出力**: AIReviewStatus

### 引き継ぎタスク確認サービス（OperationsTaskCheckService）

**責務**: operations/tasks/ディレクトリを確認し、引き継ぎタスクの有無を判定する

**入力**:
- cycle: サイクル番号

**処理フロー**:
1. タスクディレクトリのパスを構築: `docs/cycles/{cycle}/operations/tasks/`
2. ディレクトリ内の`.md`ファイルを列挙
   - ディレクトリが存在しない場合: 空リストとして扱う
3. ファイル数が1以上 → `EXISTS` を返す（ファイル名リストも付与）
4. ファイル数が0 → `NOT_EXISTS` を返す

**判定基準**:
- `ls docs/cycles/{cycle}/operations/tasks/*.md 2>/dev/null` の出力が空でなければ `EXISTS`
- 出力が空（ディレクトリ未作成、空ディレクトリ、.mdファイルなし）であれば `NOT_EXISTS`

**出力**: OperationsTaskStatus（+ ファイル名リスト）

## 確認結果の出力形式

### AIレビュー実施確認の出力

**実施済みの場合**:
```text
【AIレビュー実施確認】
履歴ファイルを確認しました: docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md

結果: AIレビュー実施済み
```

**未実施の場合**:
```text
【AIレビュー実施確認】
履歴ファイルを確認しました: docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md

結果: AIレビュー未実施

警告: AIレビューの記録が見つかりません。
どのように対応しますか？
1. 今からAIレビューを実施する（推奨）
2. スキップする（理由を記録）
```

**履歴ファイルが存在しない場合**:
```text
【AIレビュー実施確認】
警告: 履歴ファイルが見つかりません
パス: docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md

AIレビューの実施状態を確認できません。
どのように対応しますか？
1. 今からAIレビューを実施する（推奨）
2. スキップする（理由を記録）
```

### 引き継ぎタスク確認の出力

**タスクありの場合**:
```text
【Operations引き継ぎタスク確認】
タスクディレクトリを確認しました: docs/cycles/{{CYCLE}}/operations/tasks/

結果: 引き継ぎタスクあり（N件）
- 001-task-slug.md
- 002-another-task.md

Operations Phase開始時に確認・実行されます。
```

**タスクなしの場合**:
```text
【Operations引き継ぎタスク確認】
タスクディレクトリを確認しました: docs/cycles/{{CYCLE}}/operations/tasks/

結果: 引き継ぎタスクなし
```

## スキップ理由の記録

AIレビュー未実施時に「スキップする」を選択した場合、履歴ファイルに以下の形式で記録する（既存の仕様を維持）。

**記録先**: `docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md`（write-history.sh使用）

**記録形式**:
```markdown
### AIレビュースキップ
- **対象タイミング**: [タイミング]
- **スキップ理由**: [ユーザーが入力した理由]
- **日時**: YYYY-MM-DD HH:MM:SS
```

**対象タイミングの許容値**:
- `設計レビュー（Phase 1 ステップ3）`
- `統合とレビュー（Phase 2 ステップ6）`

**注意**: 上記の固定値を使用し、自由入力は行わない。

## 質問との違い

| 項目 | 変更前（質問形式） | 変更後（自動確認） |
|------|-------------------|-------------------|
| AIレビュー実施確認 | 「実施しましたか？」と質問 | 履歴ファイルを読んで自動判定 |
| 引き継ぎタスク確認 | 「ありましたか？」と質問 | ディレクトリを確認して自動判定 |
| ユーザー操作 | 質問に回答が必要 | 確認結果を見るだけ（問題時のみ対応選択） |
