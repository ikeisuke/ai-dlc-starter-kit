# Construction履歴: Unit 003 - issue-onlyモード時のプロンプト修正

## 計画

- codexレビュー（1回目）: 3件（高1, 低2）
  - #1（高）: construction.md 4モード体系不整合 → 修正
  - #2（低）: operations.md Step 5.1過剰修正 → 削除（既にゲート済み）
  - #3（低）: operations.md Section 3過剰修正 → 削除（同上）
- codexレビュー（2回目）: 0件 → auto_approved

## 設計

- スキップ（プロンプトファイルのみの変更、コードエンティティなし）

## 実装

### 変更ファイル

1. `prompts/package/prompts/inception.md`（正本）- 3箇所修正
   - ステップ13-2: `issue-only`時のスキップガード追加
   - ステップ9注意書き: ローカルパス固定表記→`backlog_mode`依存表記に変更
   - ステップ13冒頭: 排他モード時のローカルファイルスキップ注記追加
   - ステップ13-1: `gh:available`ガードとフォールバック記述を追加

2. `prompts/package/prompts/construction.md`（正本）- 1箇所修正
   - ステップ3.5: 4モード体系（git/git-only/issue/issue-only）に準拠したモードチェック追加
   - `gh:available`未利用時のフォールバック（issue→ローカル、issue-only→スキップ）を追加

3. `prompts/package/prompts/operations.md` - **修正不要**（既にモード分岐が適切にゲート済み）

### AIレビュー

- codexコードレビュー（1回目）: 2件（中2）
  - #1（中）: construction.md gh未利用時の挙動未定義 → 修正
  - #2（中）: inception.md ステップ13-1のgh:availableガード不足 → 修正
- codexコードレビュー（2回目）: 0件 → auto_approved
