# Unit 004 計画: レビューフロー更新

## 概要

`prompts/package/prompts/common/review-flow.md` を更新し、旧スキル（tool別: codex-review, claude-review, gemini-review）から新スキル（レビュー種別: reviewing-code, reviewing-architecture, reviewing-security）への呼び出しに変更する。

## 変更対象ファイル

- `prompts/package/prompts/common/review-flow.md`（メイン）

## 実装計画

### 主な変更点

#### 1. レビュー種別の選択ロジック追加

現在のreview-flow.mdには「何をレビューするか」の選択がない。新設計では、呼び出し元のコンテキストに基づきレビュー種別を決定するロジックを追加する。

**レビュー種別の決定ルール**:

| 呼び出し元ステップ | デフォルトのレビュー種別 |
|---|---|
| 計画承認前 | architecture |
| Phase 1 ステップ3（設計レビュー） | architecture |
| Phase 2 ステップ4（コード生成後） | code |
| Phase 2 ステップ6（統合とレビュー） | code, security |

- 呼び出し元が明確でない場合はユーザーに選択を求める
- ユーザーが追加の種別を指定した場合は、それも実行する

#### 2. スキル呼び出しの変更

旧:

| ツール名 | Skills呼び出し |
|---|---|
| codex | `skill="codex"` |
| claude | `skill="claude"` |
| gemini | `skill="gemini"` |

新:

| レビュー種別 | Skills呼び出し |
|---|---|
| code | `skill="reviewing-code"` |
| architecture | `skill="reviewing-architecture"` |
| security | `skill="reviewing-security"` |

#### 3. `ai_tools` 設定のツール選択への反映

`docs/aidlc.toml` の `[rules.mcp_review].ai_tools` は引き続き参照する。ただし、ツール選択はスキル内部で行われるため、review-flow.mdではスキルに渡すパラメータとしてツール優先順位を伝達する記述に変更する。

- `ai_tools` リストの最初の利用可能なツールを選択
- 選択されたツール名をスキル呼び出し時に指定

#### 4. MCPフォールバックの扱い

旧スキルのMCPフォールバック（`mcp__codex__codex`）の記述を削除。新スキルはSkills経由でのみ呼び出す。MCPフォールバックが不要になった理由: 新スキルは各種別で複数ツール（codex/claude/gemini）に対応しており、1つのツールが利用不可でも別ツールへフォールバック可能。

### 変更しない部分

- 反復レビューの仕組み（1セット最大3回、指摘対応判断フロー）
- レビュー前後のコミット処理
- 人間レビューフロー
- 外部入力検証ルール
- Codexセッション管理

## 完了条件チェックリスト

- [ ] `prompts/package/prompts/common/review-flow.md` 内に `skill="codex"` が残っていない
- [ ] `prompts/package/prompts/common/review-flow.md` 内に `skill="claude"` が残っていない
- [ ] `prompts/package/prompts/common/review-flow.md` 内に `skill="gemini"` が残っていない
- [ ] review-flow.mdにレビュー種別（code/architecture/security）の選択ロジックが記載されている
- [ ] review-flow.mdに `docs/aidlc.toml` の `[rules.mcp_review].ai_tools` 参照記述が存在する
