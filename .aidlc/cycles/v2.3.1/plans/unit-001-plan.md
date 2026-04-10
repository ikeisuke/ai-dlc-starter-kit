# Unit 001 実装計画: PRマージのユーザー判断化

## 対象Unit

- Unit 001: PRマージのユーザー判断化
- 関連Issue: #558

## 目的

Operations Phase ステップ 7.13（PRマージ）で `automation_mode=semi_auto` 時もマージ実行前にユーザー確認を必須とする。マージは破壊的・不可逆操作であり、`AskUserQuestion使用ルール` の「ユーザー選択」に分類されるべき。

## 変更対象ファイル

| ファイル | 変更種別 | 概要 |
|---------|---------|------|
| `skills/aidlc/steps/operations/operations-release.md` | 主変更 | ステップ 7.13 にマージ実行前の `AskUserQuestion` ゲートを追加（詳細手順層） |
| `skills/aidlc/steps/operations/02-deploy.md` | 参照更新 | ステップ 7.13 のサブステップ一覧（集約層）にユーザー確認必須の旨を追記 |
| `skills/aidlc/steps/operations/index.md` | 分岐明記 | 分岐ロジックセクションにPRマージを「ユーザー選択」分類として明記 |

## 変更方針

### 1. `operations-release.md` ステップ 7.13

- マージ実行（`scripts/operations-release.sh merge-pr` 呼び出し）の直前に `AskUserQuestion` を追加
- ユーザーが判断するのは「マージ実行の可否」のみ
- マージ方法は `merge_method` 設定から自動決定（選択肢に含めない）
- 確認メッセージにはPR番号・マージ方法を情報として提示（CI状態は設計レビューで除外: gh_availabilityはフロー前段で検証済みのため確認メッセージには不要）
- `automation_mode` に関わらず常にユーザー確認を実施（「ユーザー選択」分類のため `semi_auto` でも自動化対象外）

### 2. `02-deploy.md`

- ステップ 7.13 の参照箇所で、ユーザー確認が必須である旨を明記

### 3. `index.md`

- §2.6「automation_mode 分岐（ゲート判定）」の「ゲート発生箇所」一覧にPRマージ（ステップ 7.13）を追加
- PRマージは「ユーザー選択」分類のため `semi_auto` でも `auto_approved` にならない例外であることを明記
- 必要に応じて「ゲート承認」と「ユーザー選択」の分類を区別する注記を追加

## 完了条件チェックリスト

- [ ] `operations-release.md` ステップ 7.13 にマージ実行前の `AskUserQuestion` ゲートが追加されている
- [ ] ユーザーが選ぶのはマージ実行の可否のみであり、マージ方法は `merge_method` 設定から自動決定される
- [ ] 確認メッセージにPR番号・マージ方法が情報として含まれる
- [ ] `automation_mode=semi_auto` 時もマージ前にユーザー確認が行われる（「ユーザー選択」分類）
- [ ] `automation_mode=manual` 時の既存動作が退行しない
- [ ] `02-deploy.md` のステップ 7.13 参照がユーザー確認必須に合わせて更新されている
- [ ] `index.md` §2.6 のゲート発生箇所一覧にPRマージ（ステップ 7.13）が追加され、「ユーザー選択」分類として明記されている
- [ ] `pr-ops.sh merge` / `operations-release.sh merge-pr` スクリプト自体は変更していない
