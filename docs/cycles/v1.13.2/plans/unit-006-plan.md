# Unit 006 計画: setup-context.md機能の廃止

## 概要

SetupとInceptionの統合により不要になったsetup-context.md機能を廃止する。

## 変更対象ファイル

1. **削除**: `prompts/package/templates/setup_context_template.md`
2. **編集**: `prompts/package/prompts/inception.md`
   - 「完了時の必須作業【重要】」セクション内の「1. セットアップコンテキスト生成【自動】」を削除
   - 後続の見出し番号を繰り上げ（2→1, 3→2, ...）

## 実装計画

### Phase 1: 設計（スキップ）

このUnitはプロンプトとテンプレートの削除のみであり、ドメインモデル・論理設計は不要。

### Phase 2: 実装

1. `prompts/package/templates/setup_context_template.md` を削除
2. `prompts/package/prompts/inception.md` を編集
   - 行699-726（「1. セットアップコンテキスト生成【自動】」セクション）を削除
   - 見出し番号を繰り上げ:
     - `### 2. サイクルラベル作成` → `### 1. サイクルラベル作成`
     - `### 3. iOSバージョン更新` → `### 2. iOSバージョン更新`
     - `### 4. 履歴記録` → `### 3. 履歴記録`
     - `### 5. ドラフトPR作成` → `### 4. ドラフトPR作成`
     - `### 6. Gitコミット` → `### 5. Gitコミット`

## 完了条件チェックリスト

- [ ] `prompts/package/prompts/inception.md` から `setup-context.md` 作成・読み込みに関する記述が削除されている
- [ ] `prompts/package/templates/setup_context_template.md` が削除されている
