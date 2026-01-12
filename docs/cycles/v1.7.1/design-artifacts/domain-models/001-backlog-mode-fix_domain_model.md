# ドメインモデル: バックログモード読み込み修正

## 概要

aidlc.tomlの`[backlog].mode`設定を各フェーズプロンプトで正しく読み込み、モードに応じた処理分岐を行うためのロジック設計。

**重要**: このUnit はプロンプト修正のため、従来のDDDモデル（エンティティ等）ではなく、設定読み込みロジックの責務定義を行う。

## 概念モデル

### バックログモード設定

- **設定ファイル**: `docs/aidlc.toml`
- **セクション**: `[backlog]`
- **キー**: `mode`
- **値**: `"git"` | `"issue"`
- **デフォルト値**: `"git"`

### モードによる分岐ポイント

```text
[backlog]
mode = "git" or "issue"

mode=git の場合:
  - バックログは docs/cycles/backlog/*.md に保存
  - ファイル操作でCRUD

mode=issue の場合:
  - バックログは GitHub Issue に保存
  - gh コマンドでCRUD
  - ラベル（backlog, type:xxx, priority:xxx, cycle:xxx）を使用
```

## 責務の定義

### 1. 設定読み込み責務

**責務**: aidlc.tomlからbacklog.mode設定を読み込み、変数に格納する

**パターン**: 既存のmcp_review設定読み込みに倣う

```bash
BACKLOG_MODE=$(awk '/^\[backlog\]/{found=1} found && /^mode\s*=/{gsub(/.*=\s*"|".*/, ""); print; exit}' docs/aidlc.toml 2>/dev/null || echo "git")
[ -z "$BACKLOG_MODE" ] && BACKLOG_MODE="git"
```

### 2. モード分岐責務

**責務**: 読み込んだモードに応じて処理を分岐する

**分岐パターン**:

```bash
if [ "$BACKLOG_MODE" = "issue" ]; then
    # Issue駆動の処理
else
    # Git駆動の処理（デフォルト）
fi
```

### 3. フォールバック責務

**責務**: mode=issue でも GitHub CLI 未認証時は git にフォールバック

**条件**: `gh auth status` が失敗した場合

## 各フェーズでの適用箇所

### setup.md

- **現状**: mode設定を参照していない
- **追加箇所**: 「最初に必ず実行すること」セクション内
- **目的**: 後続処理でモードを参照できるよう変数を設定
- **補足**: Unit 002（ラベル作成）の前提として必要

### construction.md

- **現状**: mode設定を参照していない
- **追加箇所**: 「気づき記録フロー」セクション
- **目的**: バックログ作成時にmode=issueならIssue作成を案内

### inception.md

- **確認必要**: バックログ参照箇所があるか確認
- **目的**: あれば同様にmode分岐を追加

### operations.md

- **確認必要**: バックログ参照箇所があるか確認
- **目的**: あれば同様にmode分岐を追加

## ユビキタス言語

- **バックログモード**: バックログの保存先を決定する設定（git / issue）
- **Git駆動**: ローカルファイル（`docs/cycles/backlog/*.md`）でバックログを管理する方式
- **Issue駆動**: GitHub Issueでバックログを管理する方式
- **フォールバック**: Issue駆動が使用できない場合にGit駆動に切り替える動作

## 不明点と質問

設計上の不明点はなし。既存パターン（mcp_review設定）に倣った実装が可能。
