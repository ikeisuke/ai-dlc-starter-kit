# Unit 002 計画: Unit実装状態「取り下げ」追加

## 概要

Unit定義の実装状態に「取り下げ」（withdrawn）を正式な有効値として追加し、Construction PhaseとOperations Phaseで完了扱いとして正しく認識されるようにする。メタ開発のため`prompts/package/`配下を編集する。

## 変更対象ファイル

1. `prompts/package/templates/unit_definition_template.md` — 有効値リストに「取り下げ」追加
2. `prompts/package/prompts/construction.md` — 状態定義、依存関係判定、進捗判定を更新
3. `prompts/package/prompts/operations.md` — 進捗検証、進捗表示を更新
4. `prompts/package/prompts/operations-release.md` — 状態遷移ドキュメントを更新

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 「取り下げ」ステータスの位置づけと各フェーズでの扱いを定義
2. **論理設計**: 各ファイルの具体的な変更箇所と変更内容を定義

### Phase 2: 実装

3. **コード生成**: 上記4ファイルを更新
4. **テスト**: 変更内容の整合性確認（プロンプト変更のためコードテストなし）
5. **統合とレビュー**: AIレビュー実施

## 完了条件チェックリスト

- [ ] Unit定義テンプレートの有効値リストに「取り下げ」が追加されている
- [ ] Construction Phaseの状態定義に「取り下げ」が含まれている
- [ ] Construction Phaseの依存関係判定で「取り下げ」が完了扱いとなっている
- [ ] Construction Phaseの進捗判定で「取り下げ」が完了扱いとなっている
- [ ] Operations Phaseの進捗検証で「取り下げ」が完了扱いとなっている
- [ ] Operations Phaseの進捗表示で「取り下げ」が「完了」と区別して表示されている
