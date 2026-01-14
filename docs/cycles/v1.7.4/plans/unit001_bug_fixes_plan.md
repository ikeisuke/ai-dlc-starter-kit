# Unit 001: バグ修正 - 計画

## 概要

AI-DLCプロンプト内のバグを修正し、安定した動作を提供する。

## 対象Issue

- #66: issue-onlyモードの正常動作
- #63: 未追跡ファイルのコミット対応

## 問題分析

### バグ1: issue-onlyモードが正しく処理されない (#66)

**問題箇所**:

1. `prompts/package/prompts/setup.md:170`

   ```bash
   if [ "$BACKLOG_MODE" = "issue" ]; then
   ```

   → `issue-only` の場合もGitHub CLI確認が必要だが、カバーされていない

2. `prompts/package/prompts/inception.md:661`

   ```bash
   if [ "$BACKLOG_MODE" != "issue" ]; then
   ```

   → `issue-only` の場合もサイクルラベル作成が必要だが、スキップされてしまう

3. **周辺テキストの不整合**: 条件式だけでなく、見出しや説明文も `mode=issue` のみの記述となっており、`issue-only` への言及がない

**修正方針**:

- `issue` だけでなく `issue-only` も含めた条件に変更
- パターン: 明示的な列挙（`[ "$BACKLOG_MODE" = "issue" ] || [ "$BACKLOG_MODE" = "issue-only" ]`）を使用
  - **理由**: `issue*` のようなワイルドカードマッチは将来の別モードを誤って拾うリスクがあるため、明示列挙が安全
- 周辺テキスト（見出し、説明）も `issue または issue-only` の形式に更新

### バグ2: 未追跡ファイルのみの場合にコミットされない (#63)

**問題箇所**:

- 複数ファイルで使用されている以下のパターン:

  ```bash
  git diff --quiet && git diff --cached --quiet || git add -A && git commit -m "..."
  ```

  → `git diff` は追跡済みファイルの変更のみ検出。未追跡ファイル（新規作成ファイル）は検出されない

**影響ファイル**:

- `prompts/package/prompts/construction.md` (4箇所)
- `prompts/package/prompts/inception.md` (4箇所)
- `prompts/package/prompts/operations.md` (4箇所)

**修正方針**:

- `git status --porcelain` を使用して、追跡済み変更と未追跡ファイルの両方を検出
- パターン:

  ```bash
  [ -n "$(git status --porcelain)" ] && git add -A && git commit -m "..."
  ```

### 影響範囲の補足

**`docs/aidlc/prompts/` について**:

- `docs/aidlc/` は `prompts/package/` の rsync コピーである（`docs/cycles/rules.md` 参照）
- `prompts/package/prompts/` を修正すれば、Operations Phase の rsync で `docs/aidlc/prompts/` に自動反映される
- したがって、本計画では `prompts/package/prompts/` のみを修正対象とする

## 実装計画

### Phase 1: 設計

このUnitは単純なバグ修正のため、簡易設計を行う:

- ドメインモデル: プロンプト内の条件分岐ロジックの修正（ドキュメント変更のみ）
- 論理設計: bash条件式の修正パターン定義

### Phase 2: 実装

1. **setup.md の修正** (バグ1)
   - 行168-186付近: `mode=issueの場合` の見出しと説明を `mode=issue または issue-only の場合` に更新
   - 条件式を明示列挙に変更

2. **inception.md の修正** (バグ1)
   - 行661付近: 条件式を明示列挙に変更
   - 関連する見出しや説明も更新

3. **construction.md の修正** (バグ2)
   - 4箇所の `git diff --quiet` パターンを `git status --porcelain` に変更

4. **inception.md の追加修正** (バグ2)
   - 4箇所の `git diff --quiet` パターンを `git status --porcelain` に変更

5. **operations.md の修正** (バグ2)
   - 4箇所の `git diff --quiet` パターンを `git status --porcelain` に変更

### 検証

- markdownlintによる文法チェック
- 修正パターンの一貫性確認
- **条件分岐の動作確認**: `issue-only` 設定時にGitHub CLI確認とラベル作成が実行されることを確認
- **未追跡ファイルの検出確認**: 未追跡ファイルのみ存在する状態で `git status --porcelain` が出力を返すことを確認

## 成果物

- `prompts/package/prompts/setup.md` (修正)
- `prompts/package/prompts/inception.md` (修正)
- `prompts/package/prompts/construction.md` (修正)
- `prompts/package/prompts/operations.md` (修正)
- `docs/cycles/v1.7.4/construction/units/unit001_bug_fixes_implementation.md` (実装記録)

## リスク評価

| リスク | 影響度 | 対策 |
|--------|--------|------|
| 条件式の修正ミスで別モードが誤マッチ | 中 | 明示列挙を使用し、ワイルドカードを避ける |
| `git status --porcelain` で意図しないファイルをコミット | 中 | `.gitignore` の適切な設定を前提とする。プロンプトで「変更がある場合のみ」の意図を明確化 |
| 周辺テキストの更新漏れ | 低 | 修正時にgrep検索で関連箇所を網羅的に確認 |
