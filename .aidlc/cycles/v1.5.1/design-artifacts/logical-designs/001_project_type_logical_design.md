# 論理設計: プロジェクトタイプ設定機能

## 概要

プロジェクトタイプの設定・保存・参照の仕組みを設計する。

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/setup.md` | タイプ選択ステップを追加 |
| `prompts/package/aidlc.toml` | テンプレートに `project.type` を追加 |
| `prompts/package/prompts/operations.md` | タイプ参照ロジックを追加 |

## 1. setup.md への変更

### 追加位置

「サイクル存在確認」ステップの後、「ディレクトリ作成」の前に新ステップを追加。

### 追加内容

```markdown
### X. プロジェクトタイプ確認

docs/aidlc.toml の [project] セクションを確認:

\`\`\`bash
grep "^type" docs/aidlc.toml 2>/dev/null || echo "NOT_SET"
\`\`\`

**未設定の場合（NOT_SET）**:

プロジェクトタイプを選択してください:

1. web - Webアプリケーション
2. backend - バックエンドAPI/サーバー
3. cli - コマンドラインツール
4. desktop - デスクトップアプリ
5. ios - iOSアプリ
6. android - Androidアプリ
7. general - 汎用/未分類（デフォルト）

選択後、aidlc.toml に追記:

\`\`\`bash
# [project] セクションに type を追加
sed -i '' '/^\[project\]/a\
type = "{選択した値}"
' docs/aidlc.toml
\`\`\`

**設定済みの場合**:
現在の設定を表示して確認。
```

## 2. aidlc.toml テンプレートへの変更

### 変更箇所

`prompts/package/aidlc.toml` が存在しない場合、`prompts/setup-init.md` でaidlc.tomlを生成する箇所を確認する必要あり。

### 追加フィールド

```toml
[project]
name = "..."
description = "..."
type = "general"  # 追加: web, backend, cli, desktop, ios, android, general
```

## 3. operations.md への変更

### 変更箇所

「ステップ4: 配布」セクションの条件分岐ロジックを明確化。

### 現在の記述

```markdown
### ステップ4: 配布（PROJECT_TYPE=web/backend/general の場合はスキップ）
```

### 変更後の記述

```markdown
### ステップ4: 配布

**スキップ判定**:

\`\`\`bash
PROJECT_TYPE=$(grep "^type" docs/aidlc.toml 2>/dev/null | cut -d'"' -f2)
if [ -z "$PROJECT_TYPE" ]; then PROJECT_TYPE="general"; fi
echo "PROJECT_TYPE: $PROJECT_TYPE"
\`\`\`

- **スキップ対象** (`web`, `backend`, `general`, 未設定): ステップ4を「スキップ」としてprogress.mdに記録し、ステップ5へ進む
- **実行対象** (`cli`, `desktop`, `ios`, `android`): 配布計画を作成
```

## 4. 後方互換性

| ケース | 動作 |
|--------|------|
| `project.type` が未設定 | `general` として扱う |
| `project.type` が不正な値 | `general` として扱う（警告表示） |
| 既存の aidlc.toml | そのまま動作（type未設定→general） |

## シーケンス図

```
[ユーザー] --> [setup.md]
                  |
                  v
            タイプ選択を促す
                  |
                  v
            [aidlc.toml] に保存
                  |
                  :
                  : (Construction Phase)
                  :
                  v
            [operations.md]
                  |
                  v
            aidlc.toml から type を読み取り
                  |
                  v
            配布ステップの実行/スキップを判定
```

## 不明点と質問

なし（仕様は計画フェーズで確定済み）
