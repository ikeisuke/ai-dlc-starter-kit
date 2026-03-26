# Unit 002 計画: write-history.sh安全性ドキュメント改善

## 概要

write-history.shの`--content`引数に関するコマンドインジェクションリスク（Issue #254）への対応。スクリプト自体はセキュアであることを確認済みのため、ドキュメント（プロンプト）側の安全パターン統一と注意書き追加を行う。

## 調査結果サマリ

- **write-history.sh自体**: `echo`/`printf`で出力、`eval`不使用。セキュア
- **プロンプト内の呼び出しパターン**:
  - review-flow.md: 8箇所 → 全て`<<'CONTENT_EOF'`クォート済み（対応不要）
  - rules.md: 2箇所 → 直接文字列パターン（`--content "..."` マルチライン）。ヒアドキュメントパターンに統一
  - operations.md, construction.md, inception.md: フォーマット例テンプレート（変更不要）

## 変更対象ファイル

| ファイル | 操作 | 内容 |
|---------|------|------|
| `prompts/package/prompts/common/rules.md` | 編集 | 2箇所の`--content`をヒアドキュメントパターンに変更 + 安全パターンの注意書き追加 |

## 実装計画

### Phase 1: 設計（スキップ）

変更が小規模（rules.mdの2箇所 + 注意書き1箇所）のため、設計フェーズをスキップし直接実装に進む。

### Phase 2: 実装

1. `rules.md` L160: `--content "【セミオート自動承認】..."` → `--content "$(cat <<'CONTENT_EOF' ... CONTENT_EOF )"` 形式に変更
2. `rules.md` L178: `--content "【セミオートフォールバック】..."` → 同上
3. `rules.md`の履歴記録フォーマットセクション付近に、`--content`引数の安全パターンに関する注意書きを追加:
   - **原則**: `--content`の値はクォート付きヒアドキュメム（`<<'TOKEN'`）のみ許可
   - **許可例**: `--content "$(cat <<'CONTENT_EOF' ... CONTENT_EOF )"`
   - **禁止例**: クォートなしヒアドキュメント（`<<TOKEN`）、変数展開やコマンド置換を含む直接文字列（`--content "$(cmd)"`, `--content "$VAR"`）
   - **終端トークン衝突時**: 本文に`CONTENT_EOF`が含まれる場合は代替トークン（例: `HISTORY_EOF`）を使用

## 完了条件チェックリスト

- [ ] rules.mdの2箇所がヒアドキュメントクォート形式に統一
- [ ] 終端トークンインジェクション防止の注意書きが追加済み
- [ ] 全プロンプトの`--content`パターンがクォート形式であることをgrep確認
- [ ] Markdownlintエラーなし
