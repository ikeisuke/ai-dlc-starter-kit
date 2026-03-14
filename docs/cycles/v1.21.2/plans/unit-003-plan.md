# Unit 003 計画: ローカルCIチェック組み込み

## 概要

Operations Phaseのステップ6.4（Markdownlint実行）の後に、Bash Substitution Checkのローカル実行手順を追加する。

## 変更対象

- `prompts/package/prompts/operations-release.md`: ステップ6.4の後（6.4.5の前）にBash Substitution Check手順を追加

## 変更内容

1. ステップ6.4の後、6.4.5の前に新しいセクション「## 6.4.2 Bash Substitution Check実行【CI対応】」を追加
2. `bin/check-bash-substitution.sh` の実行手順を記載
3. 違反検出時のエラー報告と修正フロー（Markdownlintと同様のパターン）

## 完了条件

- [ ] operations-release.md にBash Substitution Check手順が追加されている
- [ ] 既存のステップ番号に影響がない
- [ ] 違反検出時の対応手順が明記されている
