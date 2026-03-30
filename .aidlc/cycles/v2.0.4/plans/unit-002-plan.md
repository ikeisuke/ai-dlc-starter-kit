# Unit 002 計画: SKILL.md パス解決 + 追加コンテキスト対応

## 概要

`/aidlc` オーケストレーターの SKILL.md を更新し、`steps/` パスがプラグインベースディレクトリから正しく解決されるようにする。また、`/aidlc <action> <追加コンテキスト>` で追加テキストをオーケストレーターに渡せるようにする。

## 非対象（Unit境界の明確化）

- **v1残存コードの削除** → Unit 003
- **ステップファイルの内容変更** → パス参照の更新のみ（最小限）
- **新機能の追加** → 行わない

## 現状分析

### SKILL.md のパス参照

現在 `steps/` パスは SKILL.md 本文内で相対パスとして記述されている（例: `steps/common/agents-rules.md`）。Claude Code はスキルの base directory からの相対パスとして解決するため、スキルが `skills/aidlc/` に配置されていれば正しく解決される。

ただし、ステップファイル内の相互参照（例: `steps/common/intro.md` を読み込んで）もベースディレクトリからの相対パスとして解決される必要がある。

### ARGUMENTS パーシング

現在の `argument-hint`: `"[inception|construction|operations|setup|express|feedback|migrate]"`

引数ルーティングは SKILL.md の「引数ルーティング」セクションで定義されているが、追加コンテキスト（action の後に続くテキスト）を受け取る仕組みがない。

## 変更対象ファイル

### 正本（直接編集）

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/SKILL.md` | argument-hint更新、ARGUMENTSパーシングセクション追加、パス解決ルール明記 |
| `skills/aidlc/CLAUDE.md` | フェーズ簡略指示テーブルに追加コンテキスト対応の記述を追加 |
| `skills/aidlc/AGENTS.md` | フェーズ簡略指示テーブルに追加コンテキスト対応の記述を追加 |

### 同期先（スクリプト経由で自動反映）

| 同期元 | 同期先 | 同期手段 |
|--------|--------|---------|
| `skills/aidlc/CLAUDE.md` | `prompts/package/prompts/CLAUDE.md` | 手動コピー |
| `skills/aidlc/AGENTS.md` | `prompts/package/prompts/AGENTS.md` | 手動コピー |
| `prompts/package/` | `docs/aidlc/` | `sync-package.sh --delete` |

### 確認対象（変更不要の見込みだが棚卸し必要）

| 対象 | 確認内容 |
|------|---------|
| `skills/aidlc/steps/` 全ファイル | 相互参照パスがベースディレクトリ相対で一貫しているか |
| `prompts/setup-prompt.md` | 引数ルーティング仕様への参照がないか |

## ARGUMENTS パーシング仕様

### 入力フォーマット

```text
ARGUMENTS = "<action> [<additional_context>]"
```

- **action**: 先頭の空白区切りトークン（1語）
- **additional_context**: action 以降の残り全テキスト（先頭空白を除去）

### パーシング例

| ARGUMENTS | action | additional_context |
|-----------|--------|--------------------|
| `construction` | `construction` | （空） |
| `construction ここまでの背景: ...` | `construction` | `ここまでの背景: ...` |
| `feedback 機能要望です` | `feedback` | `機能要望です` |
| （空 / なし） | （ブランチ名で判定） | （空） |
| `unknown_action` | エラー表示（「不明な引数です」） | — |

### エッジケース

| ケース | 挙動 |
|--------|------|
| action のみ（追加コンテキストなし） | 従来通りの動作。`additional_context` は空 |
| 複数スペース区切り | 先頭トークンのみ action、区切り空白（1つ）を除去し残りをそのまま additional_context（内部空白は保持） |
| 未知の action | エラーメッセージを表示し処理を中断。「`/aidlc [action]` の action には inception/construction/operations/setup/express/feedback/migrate のいずれかを指定してください」と案内。引数なし相当への暗黙フォールバックは行わない（誤入力の検出を優先） |
| `feedback`/`setup`/`migrate` + 追加コンテキスト | 各独立フローに additional_context を渡す（フロー側で利用するかは任意） |

### 後続ステップへの受け渡し

SKILL.md 本文の「引数ルーティング」セクション（共通初期化フローの**前**）で以下のコンテキスト変数を設定:

```text
additional_context = "<パース結果>"
```

**設定タイミング**: 引数パース直後、ルーティング判定と同時に設定する。これにより `feedback`（共通初期化をスキップ）を含む全フローで `additional_context` が利用可能になる。

ステップファイル内では `additional_context` 変数として参照可能。空の場合は無視。

## 実装計画

1. **影響範囲の棚卸し**: SKILL.md、CLAUDE.md、AGENTS.md、ステップファイルの `steps/` パス参照と引数関連記述を grep で洗い出す
2. **ARGUMENTS パーシング仕様の確定**: 上記仕様をSKILL.mdに反映（引数ルーティングセクションを拡張）
3. **SKILL.md 更新**: argument-hint 更新、パーシングロジック追加、パス解決ルール明記
4. **CLAUDE.md / AGENTS.md 更新**: 追加コンテキスト対応の記述を反映
5. **ステップファイルのパス参照確認**: 全ステップファイルの相互参照が一貫していることを確認（修正がなければスキップ）
6. **ミラー同期**: CLAUDE.md/AGENTS.md を `prompts/package/prompts/` にコピー、`sync-package.sh --delete` で `docs/aidlc/` に同期
7. **検証**: 完了条件チェックリストの全項目を確認

## 完了条件チェックリスト

- [ ] SKILL.md の `steps/` パス参照がプラグインベースディレクトリからの相対パスとして一貫している
- [ ] ステップファイル内の相互参照（`steps/common/*.md` 等）がベースディレクトリ相対で一貫している
- [ ] `/aidlc construction` （追加コンテキストなし）で従来通り動作する
- [ ] `/aidlc construction ここまでの背景` で action=construction、additional_context が正しくパースされる
- [ ] `/aidlc feedback 機能要望` で feedback フローに追加コンテキストが渡される
- [ ] 引数なし（ブランチ名判定）で従来通り動作し、additional_context は空
- [ ] `/aidlc unknown_action` で「不明な引数です」エラーメッセージを表示し処理を中断する
- [ ] CLAUDE.md / AGENTS.md のルーティング説明が SKILL.md と一致している
- [ ] `prompts/package/prompts/CLAUDE.md`、`prompts/package/prompts/AGENTS.md` が正本と同期済み
- [ ] `docs/aidlc/` が `prompts/package/` と同期済み
