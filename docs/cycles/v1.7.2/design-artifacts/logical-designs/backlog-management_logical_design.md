# 論理設計: バックログ管理改善

## 概要

バックログ管理のmodeオプションに"git-only"/"issue-only"を追加し、AGENTS.mdにバックログ管理方針を明文化する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## 変更対象ファイルと変更内容

### 1. prompts/package/prompts/AGENTS.md

**追加位置**: 「AI-DLC共通ルール」セクション内、「禁止事項」の前

**追加内容**:

```markdown
### バックログ管理

バックログの保存先は `docs/aidlc.toml` の `[backlog].mode` で設定する。

| mode | 保存先 | 説明 |
|------|--------|------|
| git | `docs/cycles/backlog/*.md` | ローカルファイルがデフォルト（他の保存先も許容） |
| issue | GitHub Issues | GitHub Issueがデフォルト（他の保存先も許容） |
| git-only | `docs/cycles/backlog/*.md` | ローカルファイルのみ（Issue作成禁止） |
| issue-only | GitHub Issues | GitHub Issueのみ（ローカルファイル作成禁止） |

**排他モード（*-only）の場合**: 指定された保存先のみを使用し、他の保存先への記録は行わない。
```

### 2. prompts/setup-prompt.md

**変更箇所**: aidlc.tomlテンプレート内の `[backlog]` セクション

**変更前**:
```toml
[backlog]
# バックログ管理モード設定
# mode: "git" | "issue"
# - git: ローカルファイルに保存（従来方式、デフォルト）
# - issue: GitHub Issueに保存
mode = "git"
```

**変更後**:
```toml
[backlog]
# バックログ管理モード設定
# mode: "git" | "issue" | "git-only" | "issue-only"
# - git: ローカルファイルがデフォルト、状況に応じてIssueも許容（デフォルト）
# - issue: GitHub Issueがデフォルト、状況に応じてローカルも許容
# - git-only: ローカルファイルのみ（Issueへの記録を禁止）
# - issue-only: GitHub Issueのみ（ローカルファイルへの記録を禁止）
mode = "git"
```

### 3. prompts/package/prompts/inception.md

**変更箇所1**: バックログ確認セクション（約459-481行目付近）

**変更内容**: 排他モードの判定と分岐を追加

```markdown
**設定確認**:
```bash
if command -v dasel >/dev/null 2>&1; then
    BACKLOG_MODE=$(dasel -f docs/aidlc.toml -r toml '.backlog.mode' 2>/dev/null || echo "git")
else
    BACKLOG_MODE=""  # AIが設定ファイルを直接読み取る
fi
[ -z "$BACKLOG_MODE" ] && BACKLOG_MODE="git"
```

**排他モード判定**: modeが "git-only" または "issue-only" の場合は排他モード

#### 3-1. 共通バックログ

**mode=git または mode=git-only の場合**:
```bash
ls docs/cycles/backlog/ 2>/dev/null
```

**mode=issue または mode=issue-only の場合**:
```bash
gh issue list --label backlog --state open
```

**mode=git または mode=issue の場合のみ**: ローカルファイルとIssue両方を確認し、片方にしかない項目がないか確認

**mode=git-only または mode=issue-only の場合**: 指定された保存先のみを確認（他の保存先は確認しない）
```

### 4. prompts/package/prompts/construction.md

**変更箇所**: 気づき記録フローセクション（約127-167行目付近）

**変更内容**: 排他モードの判定と分岐を追加

```markdown
**設定確認**:
```bash
if command -v dasel >/dev/null 2>&1; then
    BACKLOG_MODE=$(dasel -f docs/aidlc.toml -r toml '.backlog.mode' 2>/dev/null || echo "git")
else
    BACKLOG_MODE=""  # AIが設定ファイルを直接読み取る
fi
[ -z "$BACKLOG_MODE" ] && BACKLOG_MODE="git"
```

**dasel未インストールの場合**: AIは `docs/aidlc.toml` を読み込み、`[backlog]` セクションの `mode` 値を取得。

**排他モード判定**: modeが "git-only" または "issue-only" の場合は排他モード

**mode=git または mode=git-only の場合**: `docs/cycles/backlog/{種類}-{スラッグ}.md` にファイルを作成

**mode=issue または mode=issue-only の場合**: GitHub Issueを作成（ガイド参照: `docs/aidlc/guides/issue-driven-backlog.md`）

**排他モードの場合の注意**: 指定された保存先以外への記録は禁止
```

### 5. prompts/package/prompts/operations.md

**変更箇所**: バックログ記録フローセクション（約822-855行目付近）

**変更内容**: construction.mdと同様の排他モード判定と分岐を追加

## 処理フロー

### バックログ記録フロー

```
1. docs/aidlc.tomlからBACKLOG_MODEを取得
2. 排他モード判定（*-only かどうか）
3. 保存先決定:
   - git / git-only → ローカルファイル
   - issue / issue-only → GitHub Issue
4. 記録実行
5. （非排他モードのみ）必要に応じて他の保存先にも記録可能
```

### バックログ確認フロー

```
1. docs/aidlc.tomlからBACKLOG_MODEを取得
2. 排他モード判定（*-only かどうか）
3. 確認対象決定:
   - 排他モード → 指定された保存先のみ
   - 非排他モード → 両方の保存先を確認
4. バックログ項目を表示
5. ユーザーに対応を確認
```

## 非機能要件（NFR）への対応

### パフォーマンス
- 該当なし（プロンプト変更のみ）

### セキュリティ
- 該当なし

### スケーラビリティ
- 該当なし

### 可用性
- 該当なし

## 技術選定

- **言語**: Markdown
- **ツール**: なし（プロンプト変更のみ）

## 実装上の注意事項

1. `docs/aidlc/` は直接編集禁止。必ず `prompts/package/` を編集する
2. 変更はOperations PhaseのrsyncでAI-DLC環境に反映される
3. 後方互換性を維持（デフォルト値は "git" のまま）

## 不明点と質問（設計中に記録）

（現時点で不明点なし）
