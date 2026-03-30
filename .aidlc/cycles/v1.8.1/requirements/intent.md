# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v1.8.1 パッチリリース

## 開発の目的

v1.8.0で追加されたスクリプト基盤の活用を完成させ、プロンプトの一貫性と保守性を向上させる。

具体的には：
- 未使用のスクリプト（env-info.sh、write-history.sh）をプロンプトに統合
- AIレビュー設定をSkills優先（MCPフォールバック）に改善し、安定性を向上
- 依存コマンド追加手順のドキュメント化
- Issueラベル付けループ処理のスクリプト化

## ターゲットユーザー

- AI-DLC Starter Kitを使用する開発者
- AI-DLCプロンプトを活用してAIエージェントと協働する開発者

## ビジネス価値

1. **保守性向上**: 複雑なbashコマンドをスクリプト呼び出しに統一し、プロンプトの可読性・保守性を向上
2. **安定性向上**: AIレビューをSkillsベースに移行し、MCP経由での応答が返らない問題を解消
3. **拡張性向上**: 依存コマンド追加手順を明文化し、将来の機能追加を容易化
4. **一貫性向上**: 履歴記録フォーマットをスクリプトで標準化

## 成功基準

- [ ] env-info.shが`prompts/package/prompts/setup.md`で使用されている
- [ ] write-history.shが`prompts/package/prompts/inception.md`、`construction.md`、`operations.md`で使用されている
- [ ] label-cycle-issues.shが`prompts/package/bin/`に作成され、`inception.md`で使用されている
- [ ] AIレビュー設定が`prompts/package/prompts/*.md`でSkills優先+MCPフォールバック方式になっている
- [ ] 依存コマンド追加手順が`prompts/package/prompts/operations.md`に記載されている
- [ ] markdownlintがパスする（`docs/aidlc/bin/run-markdownlint.sh`で検証）

## 期限とマイルストーン

- パッチリリースのため、短期間での完了を想定
- Construction Phase: 5〜6 Unit程度

## 制約事項

- パッチリリースのため、破壊的変更は避ける
- 既存の動作に影響を与えない後方互換性を維持
- prompts/package/を編集し、docs/aidlc/は直接編集しない（メタ開発ルール）
- 新規スクリプトは`prompts/package/bin/`に配置
- 対応シェル: bash（POSIX互換を意識）

## 対象Issue

- #81: env-info.shをsetup.mdで活用
- #72: 依存コマンド追加手順をoperations.mdに記載
- #70: AIレビューをSkills優先（MCPフォールバック）に改善
- #73: AIレビュー設定の改善

## 追加対応（Issue外）

- write-history.shをプロンプトに統合（heredoc置換）
- label-cycle-issues.shを新規作成（Issueラベル付けループのスクリプト化）

## 対象外（明示的に除外）

- sync-prompts.sh: 開発リポジトリ向けのため、今回は対象外（将来のサイクルで検討）
- Construction Phase中に見つかった追加のスクリプト化対象: バックログに追加しv1.8.2で対応

## 不明点と質問（Inception Phase中に記録）

[Question] v1.8.0で追加したスクリプトの活用について、具体的にどのスクリプトが未使用か？
[Answer] 調査の結果、write-history.sh、env-info.sh、sync-prompts.shが未使用。write-history.shとenv-info.shをプロンプトに統合する。sync-prompts.shは開発リポジトリ向けのため今回は対象外。

[Question] AIレビュー設定改善（#70, #73）の具体的なスコープは？
[Answer] rules.mdはリポジトリ固有のため、共通のprompts/package/prompts/*.mdでSkills優先（MCPフォールバック）方式に変更する。Skills未対応環境も考慮。

[Question] ループ処理のスクリプト化の範囲は？
[Answer] inception.mdの「各Issueにラベル付け」処理（見つかったIssue分だけ実行）をlabel-cycle-issues.shとしてスクリプト化する。

## AIレビュー履歴

### 2026-01-18 レビュー1回目（Codex）

**指摘事項**:
1. 追加対応の整合性が曖昧 → 成功基準にlabel-cycle-issues.shを追加
2. 成功基準の測定性が弱い → 対象ファイル・検証コマンドを明記
3. sync-prompts.shの扱い → 「対象外」セクションを追加し明記
4. 制約事項の漏れ → スクリプト配置先・対応シェルを追記
5. 「随時追加」の懸念 → 削除し、スコープを確定

**対応**: 全指摘を反映（「随時追加」はバックログ追加でv1.8.2対応に変更）

### 2026-01-18 レビュー2回目（Codex）

**結果**: 再指摘なし - 全ての指摘事項が解消
