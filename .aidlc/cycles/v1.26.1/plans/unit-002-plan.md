# Unit 002 計画: Operations Phaseカスタムワークフロー追加

## 概要
Operations Phaseのリリース品質保証を強化するため、operations-release.mdの7.12（PRマージ前レビュー）にローカルレビュー手順を追加し、rules.mdのカスタムワークフローにパーミッション管理ステップを追加する。

## 変更対象ファイル
1. `prompts/package/prompts/operations-release.md` - 7.12にローカルレビュー手順（サブステップ0として追加）
2. `docs/cycles/rules.md` - カスタムワークフローにパーミッション管理ステップ追加

## 実装計画

### Step 1: operations-release.md 7.12へのローカルレビュー手順追加
- 既存のサブステップ1の前に「サブステップ0: ローカルレビュー」を挿入
- codex CLIによるローカルレビュー: `codex review --base main`
- reviewingスキルによるレビュー: `skill="reviewing-code"` 等
- 外部PRレビューが利用不可時のフォールバックとしての位置づけ明記
- 正常系: 指摘あり→修正→再レビュー、指摘0件→「指摘なし」表示→マージへ
- 異常系: コマンド失敗→エラー表示→手動レビューへ誘導

### Step 2: rules.mdへのパーミッション管理カスタムワークフロー追加
- カスタムワークフローセクション（Bash Substitution Check後）に「パーミッション管理」を追加
- 実行タイミング: 7.7（Gitコミット）完了後、aidlc-setup同期の前
- ステップ1: `/tools:suggest-permissions` でセッション分析
- ステップ2: `/tools:suggest-permissions --review all` で既存設定監査
- 正常系: 提案あり→設定反映→コミット、提案なし→「変更なし」表示
- 異常系: コマンド失敗→警告表示→手動確認案内→続行
- --review all: HIGH/CRITICAL指摘→対応フロー、指摘なし→「監査合格」表示

## 完了条件チェックリスト
- [ ] operations-release.mdの7.12にローカルレビュー手順が追加されている
- [ ] `codex review --base main` によるローカルCodexレビューの手順が記載されている
- [ ] reviewingスキルによるローカルレビューの手順が記載されている
- [ ] レビュー指摘への対応フロー（修正→再レビュー）が記載されている
- [ ] 外部PRレビュー利用不可時のフォールバックとして明確に位置づけられている
- [ ] コマンド失敗時のエラーハンドリングが記載されている
- [ ] 指摘0件の場合の動作が記載されている
- [ ] rules.mdにパーミッション管理カスタムワークフローが追加されている
- [ ] suggest-permissionsとreview allの2ステップが記載されている
- [ ] 正常系・異常系のフローが記載されている
- [ ] 設定変更時のコミット手順が記載されている
