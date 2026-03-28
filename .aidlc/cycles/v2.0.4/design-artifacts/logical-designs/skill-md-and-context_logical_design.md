# 論理設計: SKILL.md パス解決 + 追加コンテキスト対応

## 概要

SKILL.mdにARGUMENTSパーシングセクションを追加し、追加コンテキストの受け渡しを実現する。

**重要**: このドキュメントでは実装コードは書きません。

## スコープ

### In Scope（Unit 002）

- SKILL.md のARGUMENTSパーシング追加・引数ルーティング拡張
- パス解決ルールの明示化
- CLAUDE.md / AGENTS.md の更新
- ミラー同期

### Out of Scope

- v1残存コードの削除 → Unit 003
- ステップファイルの内容変更

## コンポーネント構成

### 1. ARGUMENTSパーシング（SKILL.md 追加セクション）

**配置場所**: SKILL.md の「引数ルーティング」セクションの直前

**セクション内容**:

```markdown
## ARGUMENTSパーシング

ARGUMENTS文字列を以下のルールでパースする:

1. ARGUMENTSが空または未指定の場合:
   - action = （ブランチ名で判定: `cycle/*` なら `construction`、それ以外は `inception`）
   - additional_context = （空）

2. ARGUMENTSが指定されている場合:
   - 先頭の空白区切りトークンを action として取得
   - action が有効値（inception/construction/operations/setup/express/feedback/migrate）でない場合:
     エラーメッセージを表示して処理を中断
   - action 以降の残りテキストから先頭の区切り空白（1つ）のみ除去し、残りをそのまま additional_context として設定（内部の空白は保持）

パース完了後、additional_context をコンテキスト変数として保持する。
```

### 2. 引数ルーティング拡張（SKILL.md 既存セクション修正）

**変更内容**:

- 既存の引数ルーティングテーブルはそのまま維持
- テーブルの後に以下を追加:

```markdown
**追加コンテキスト**: ARGUMENTSのパーシング結果として `additional_context` が設定されている場合、
フェーズ実行中にコンテキスト変数として参照可能。空の場合は従来と同じ動作。
```

- 「引数なしの場合」の説明はそのまま維持

### 3. argument-hint 更新（SKILL.md frontmatter）

**変更**:

```yaml
# 変更前
argument-hint: "[inception|construction|operations|setup|express|feedback|migrate]"

# 変更後
argument-hint: "<action> [追加コンテキスト]"
```

### 4. パス解決ルール明示化（SKILL.md 追加セクション）

**配置場所**: 「制約事項」セクションに追記

**追加内容**:

```markdown
- **ステップファイルのパス解決**: `steps/` で始まるパスはスキルのベースディレクトリ（SKILL.mdと同じディレクトリ）からの相対パスとして解決する。ステップファイル内の相互参照（例: `steps/common/rules.md` を読み込んで）も同じルールに従う
```

### 5. CLAUDE.md 更新

**変更内容**: フェーズ簡略指示テーブルの後に追加コンテキストの説明を追加

```markdown
**追加コンテキスト**: `/aidlc <action> <テキスト>` の形式で、actionの後に任意のテキストを追加できます。
追加テキストはフェーズ実行中にコンテキスト変数 `additional_context` として参照されます。

例: `/aidlc construction 前回のセッションで設計レビューまで完了`
```

### 6. AGENTS.md 更新

CLAUDE.md と同じ追加コンテキスト説明を追加（フェーズ簡略指示テーブルの後）。

### 7. 正本更新コンポーネント（SourceDocumentUpdater）

**責務**: 正本ファイル（`skills/aidlc/` 配下）の直接編集のみを担う。

| 正本ファイル | 変更内容 |
|-------------|---------|
| `skills/aidlc/SKILL.md` | frontmatter + パーシング + ルーティング + パス解決 |
| `skills/aidlc/CLAUDE.md` | 追加コンテキスト説明追加 |
| `skills/aidlc/AGENTS.md` | 追加コンテキスト説明追加 |

### 8. ミラー同期コンポーネント（MirrorSync）

**責務**: 正本更新完了後に、配布パッケージと配布物を正本と一致させる。

**同期フロー**:

```text
Step A: 正本 → 配布パッケージ（手動コピー）
  skills/aidlc/CLAUDE.md → prompts/package/prompts/CLAUDE.md
  skills/aidlc/AGENTS.md → prompts/package/prompts/AGENTS.md

Step B: 配布パッケージ → 配布物（スクリプト）
  prompts/package/ → docs/aidlc/  (sync-package.sh --delete)
```

**検証**: Step A後にdiff確認、Step B後に構造一致確認

## 実行順序

```text
1. 影響範囲の棚卸し（grep）
2. SKILL.md 更新（frontmatter + パーシング + ルーティング + パス解決）
3. CLAUDE.md / AGENTS.md 更新
4. ステップファイルのパス参照確認
5. ミラー同期（CLAUDE.md/AGENTS.md → prompts/package/ → docs/aidlc/）
6. 検証（完了条件チェックリスト全項目）
```

## 検証計画

計画の完了条件チェックリストと1:1で対応させる。

| # | 完了条件 | 検証方法 |
|---|---------|---------|
| 1 | SKILL.md の `steps/` パス参照が一貫 | `grep -rn 'steps/' skills/aidlc/SKILL.md` で全パスがベースディレクトリ相対であること |
| 2 | ステップファイルの相互参照が一貫 | `grep -rn 'steps/' skills/aidlc/steps/` で相互参照パスがベースディレクトリ相対であること |
| 3 | `/aidlc construction` で従来通り動作 | SKILL.md の引数ルーティングテーブルに `construction` が存在し、パーシングセクションで action のみの場合 additional_context が空と記述されていること |
| 4 | `/aidlc construction ここまでの背景` でパース成功 | パーシング例テーブルに該当例が含まれ、additional_context が正しく分離されること |
| 5 | `/aidlc feedback 機能要望` で追加コンテキスト渡し | パーシング例テーブルに feedback + 追加コンテキストの例が含まれ、フィードバック送信セクションで additional_context が参照可能であること |
| 6 | 引数なしで従来通り動作 | パーシングセクションに「引数なし時はブランチ名で判定」の記述があること |
| 7 | `/aidlc unknown_action` でエラー表示 | パーシングセクションに未知 action のエラーハンドリングが記述され、エラーメッセージが明記されていること |
| 8 | CLAUDE.md/AGENTS.md のルーティング説明が一致 | 追加コンテキスト説明がSKILL.mdの仕様と整合していること |
| 9 | prompts/package/prompts/ が正本と同期済み | `diff skills/aidlc/CLAUDE.md prompts/package/prompts/CLAUDE.md` と `diff skills/aidlc/AGENTS.md prompts/package/prompts/AGENTS.md` で差分なし |
| 10 | docs/aidlc/ が prompts/package/ と同期済み | `diff -rq prompts/package/prompts/CLAUDE.md docs/aidlc/prompts/CLAUDE.md` と AGENTS.md 同様で差分なし |
