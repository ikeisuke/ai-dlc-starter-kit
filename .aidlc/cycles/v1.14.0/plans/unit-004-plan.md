# Unit 004 計画: レビューフロー更新

## 概要

`prompts/package/prompts/common/review-flow.md` を更新し、旧スキル（tool別: codex-review, claude-review, gemini-review）から新スキル（レビュー種別: reviewing-code, reviewing-architecture, reviewing-security）への呼び出しに変更する。

## 変更対象ファイル

- `prompts/package/prompts/common/review-flow.md`（メイン）
- `docs/cycles/rules.md`（AIレビューツール使用ルールの暫定更新）
- `docs/aidlc.toml`（セクション名リネーム）
- `prompts/package/prompts/common/rules.md`（設定参照キー更新）
- `prompts/package/prompts/inception.md`（テンプレート更新）
- `prompts/package/guides/config-merge.md`（設定参照キー更新）
- `prompts/package/guides/ai-agent-allowlist.md`（設定参照キー更新）
- `prompts/package/bin/read-config.sh`（コメント例更新）

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

**複数種別実行時のルール**:

- 複数種別は**直列実行**（1つずつ順番に実行）
- 各種別ごとに反復レビュー（1セット最大3回）を独立して実施
- **全種別で指摘0件**になった時点で「AIレビュー完了」とする
- 履歴記録には実行した全種別を記載（例: `【レビュー種別】code, security`）
- construction.mdの履歴判定（`AIレビュー完了` + `対象タイミング.*統合とレビュー`）は変更不要（既存のawk判定はそのまま機能する）

#### 2. スキル呼び出しの変更

旧:

| ツール名 | Skills呼び出し | MCPフォールバック |
|---|---|---|
| codex | `skill="codex"` | `mcp__codex__codex` |
| claude | `skill="claude"` | なし |
| gemini | `skill="gemini"` | なし |

新:

| レビュー種別 | Skills呼び出し |
|---|---|
| code | `skill="reviewing-code"` |
| architecture | `skill="reviewing-architecture"` |
| security | `skill="reviewing-security"` |

#### 3. `tools` 設定の役割変更

`docs/aidlc.toml` の `[rules.reviewing].tools`（旧 `[rules.mcp_review]`）を参照する。セクション名を `[rules.reviewing]` にリネームし、新スキル名（reviewing-*）との整合性を確保する。

**責務の明確化**: ツール選択（codex/claude/geminiのどれを使うか）は**新スキルの内部責務**とする。review-flow.mdは `tools` の値を読み取り、スキル呼び出し時の引数として優先ツール名を渡す。スキル内部でそのツールが利用可能かを判定し、利用不可の場合はスキル内でフォールバックする。

**review-flow.mdの責務**:

- `tools` 設定を読み取る
- レビュー種別を決定する
- スキルを呼び出す際に `tools` の優先ツール名を引数テキストに含める

**スキル呼び出し時の引数フォーマット**:

```text
skill="reviewing-code", args="[レビュー対象ファイル/ディレクトリ] 優先ツール: [codex|claude|gemini]"
```

例: `skill="reviewing-code", args="prompts/package/prompts/common/review-flow.md 優先ツール: codex"`

新スキルのSKILL.mdの `argument-hint` は「レビュー対象ファイルまたはディレクトリ」のみだが、自然言語テキストとして優先ツール情報を追記する形とする。スキル内の実行手順で対応するCLIコマンドが選択される。

**スキル側の責務**:

- 引数テキストから優先ツール情報を読み取る
- 指定されたツールが利用可能か判定
- 利用可能なツールでレビューを実行
- 利用不可の場合は他のツールにフォールバック

**フォールバック**: スキルが優先ツール指定を解釈できない場合は、スキルのSKILL.mdに記載された `allowed-tools` の順序（codex → claude → gemini）に従って利用可能なツールが自動選択される。review-flow.md側では「優先ツール: [tool]」を引数に含めるが、これは最善努力のヒントであり、スキルの動作を強制するものではない。

#### 4. MCP関連記述の全面見直し

旧スキルのMCPフォールバック（`mcp__codex__codex`）の記述を**全面削除**する。具体的に削除・修正する箇所:

- タイトル部の「MCPフォールバック」への言及（L3）
- 有効なツール名テーブルのMCPフォールバック列（L30付近）
- AIレビューツール利用可否確認のMCPフォールバックロジック（L50付近）
- ステップ2のMCPフォールバック確認（L69付近）
- ステップ5の「Skills/MCP両方利用不可」記述（L302付近）
- その他「Skills/MCP」という併記箇所すべて

**理由**: 新スキルは各種別で複数ツール（codex/claude/gemini）に対応しており、1つのツールが利用不可でも別ツールへフォールバック可能。MCPフォールバックは不要になる。

#### 5. `[rules.mcp_review]` → `[rules.reviewing]` セクション名リネーム

`docs/aidlc.toml` のセクション名を `[rules.mcp_review]` → `[rules.reviewing]` にリネームし、関連するすべての `prompts/package/` 配下ファイルの参照を更新する。過去サイクルの履歴ファイル（`docs/cycles/v1.*/`）は変更しない。

#### 6. `docs/cycles/rules.md` の暫定更新

`docs/cycles/rules.md` のAIレビューツール使用ルール（L89-112）で `skill="codex"` を固定指定している箇所を、新スキル体系に合わせて暫定的に更新する。Unit 009のドキュメント整合で最終的に整理されるが、Unit 004完了時点で実運用が破綻しないようにする。

### 変更しない部分

- 反復レビューの仕組み（1セット最大3回、指摘対応判断フロー）
- レビュー前後のコミット処理
- 人間レビューフロー
- 外部入力検証ルール
- Codexセッション管理（各新スキルにsession-management.mdが含まれている）

## 完了条件チェックリスト

- [ ] `prompts/package/prompts/common/review-flow.md` 内に `skill="codex"` が残っていない
- [ ] `prompts/package/prompts/common/review-flow.md` 内に `skill="claude"` が残っていない
- [ ] `prompts/package/prompts/common/review-flow.md` 内に `skill="gemini"` が残っていない
- [ ] `prompts/package/prompts/common/review-flow.md` 内に `mcp__codex__codex` が残っていない
- [ ] `prompts/package/prompts/common/review-flow.md` 内に「MCPフォールバック」が残っていない
- [ ] `prompts/package/prompts/common/review-flow.md` 内に「Skills/MCP」が残っていない
- [ ] review-flow.mdにレビュー種別（code/architecture/security）の選択ロジックが記載されている
- [ ] review-flow.mdに `docs/aidlc.toml` の `[rules.reviewing].tools` 参照記述が存在する
- [ ] review-flow.mdに複数種別実行時のルール（直列実行、全種別0件で完了）が記載されている
- [ ] review-flow.mdにツール選択責務の明確化（スキル内部がツール選択、review-flowは優先ツールを引数で渡す）が記載されている
- [ ] review-flow.mdの履歴記録テンプレートに `【レビュー種別】` フィールドが含まれている
- [ ] `docs/cycles/rules.md` 内に `skill="codex"` が残っていない
- [ ] `docs/cycles/rules.md` 内に `reviewing-code` または `reviewing-architecture` または `reviewing-security` の記述が存在する
- [ ] `docs/aidlc.toml` 内に `[rules.mcp_review]` が残っていない（`[rules.reviewing]` にリネーム済み）
- [ ] `prompts/package/` 配下に `rules.mcp_review` が残っていない（`rules.reviewing` に更新済み）
