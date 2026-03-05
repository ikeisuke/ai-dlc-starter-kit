# Unit 003 計画: issue-onlyモード時のプロンプト修正

## 概要

`backlog.mode=issue-only`時にローカルバックログファイルの探索・操作をスキップするようプロンプトを修正する。

## 変更対象ファイル

1. `prompts/package/prompts/inception.md`（正本）
2. `prompts/package/prompts/construction.md`（正本）

**注**: `operations.md` は既にモード分岐が適切にゲートされており（Step 5.1: L406-419 git/git-only, L421-467 issue/issue-only, L469-471 排他/非排他ルール、Section 3: L577-584）、修正不要。

## 実装計画

### 1. inception.md の修正（3箇所）

#### 1-1. ステップ13-2 対応済みバックログとの照合（L573-598）

**問題**: `docs/cycles/backlog-completed/` と `docs/cycles/backlog-completed.md` のローカルファイル探索がモードチェックなしで常時実行される。

**修正**: セクション冒頭にモードガードを追加:
- `issue-only`: このサブステップを完全スキップ（ローカルバックログファイルが存在しないため照合不要）
- `git-only` / `git` / `issue`: 現行動作を維持

#### 1-2. ステップ9 サイクルディレクトリ作成の注意書き（L475）

**問題**: 「気づきは共通バックログ（`docs/cycles/backlog/`）に直接記録します。」がモード非依存で記載されており、`issue-only`時に誤解を招く。

**修正**: 「気づきは共通バックログに直接記録します（保存先は `backlog_mode` に従う）。」に変更。

#### 1-3. ステップ13 バックログ確認の冒頭（L541-543）

**問題**: `backlog_mode` の参照指示はあるが、`issue-only`時の全体的なスキップ指示がない。ステップ13-2がモードガードなしのため。

**修正**: ステップ13の冒頭に「`issue-only` の場合、ローカルファイル操作（`docs/cycles/backlog/`, `docs/cycles/backlog-completed/`）はスキップする」旨の注記を追加。

### 2. construction.md の修正（1箇所）

#### 2-1. ステップ3.5 バックログ確認（L244-251）

**問題**: `docs/cycles/backlog/` の `ls` コマンドがモードチェックなしで常時実行される。

**修正**: 既存の4モード体系（inception.md L557-559, operations.md L469-471）に準拠したモードチェックを追加:
- `git`: ローカルファイル（`ls docs/cycles/backlog/`）＋Issue（`gh:available`時）の両方を確認
- `git-only`: ローカルファイルのみ確認
- `issue`: Issue（`gh:available`時）＋ローカルファイルの両方を確認
- `issue-only`: Issueのみ確認（ローカルファイル探索を完全スキップ）

## 完了条件チェックリスト

- [ ] `inception.md` ステップ13-2に`issue-only`時スキップガードが追加されている
- [ ] `inception.md` ステップ9の注意書きがモード依存表記に変更されている
- [ ] `inception.md` ステップ13冒頭に`issue-only`時のローカルファイルスキップ注記がある
- [ ] `construction.md` ステップ3.5に4モード体系に準拠したモードチェックが追加されている
