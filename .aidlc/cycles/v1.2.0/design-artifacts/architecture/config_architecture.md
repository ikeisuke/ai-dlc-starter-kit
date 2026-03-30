# 設定アーキテクチャ設計

## 概要

AI-DLC スターターキットにおける設定管理のアーキテクチャを定義する。

## 設計原則

1. **単一設定ファイル**: プロジェクト設定は `project.toml` に集約
2. **変数置換の廃止**: `{{CYCLE}}` 等のテンプレート変数を廃止し、AIが設定ファイルを読む形式に変更
3. **静的テンプレート**: `docs/aidlc/` 配下のプロンプト・テンプレートは変更しない前提（バージョンアップ対応の簡素化）
4. **コンテキスト節約**: プロンプト内でのパス記述を最小化

---

## 設定ファイル構造

### プロジェクト設定

**ファイル**: `docs/aidlc/project.toml`

**役割**: プロジェクト固有の全設定を集約

**スキーマ**:

```toml
# AI-DLC プロジェクト設定

[project]
name = "プロジェクト名"
description = "プロジェクト概要"

[project.tech_stack]
languages = ["TypeScript", "Python"]
frameworks = []
tools = ["Claude Code"]

[paths]
setup_prompt = "prompts/setup-prompt.md"
aidlc_dir = "docs/aidlc"
cycles_dir = "docs/cycles"

[cycle_variables]
# 実行時に変動する変数の定義
# 実際の値はユーザーから指示される
CYCLE = "サイクルバージョン（例: v1.2.0）"
CYCLE_DIR = "docs/cycles/{CYCLE}"

[rules]
# 開発ルール

[rules.coding]
# コーディング規約
naming_convention = "lowerCamelCase"
# 追加ルールは自由記述

[rules.security]
# セキュリティ要件
validate_user_input = true
use_env_for_secrets = true

[rules.performance]
# パフォーマンス要件（必要に応じて記載）

[rules.custom]
# その他カスタムルール
```

### サイクル固有変数

**配置**: ディレクトリ名から導出（専用ファイルなし）

| 変数 | 導出方法 | 例 |
|------|---------|-----|
| CYCLE | ユーザー指示 or ディレクトリ名 | v1.2.0 |
| CYCLE_DIR | `docs/cycles/{CYCLE}` | docs/cycles/v1.2.0 |

---

## ファイル変更ポリシー

### docs/aidlc/ 配下

| ファイル/ディレクトリ | 変更 | 備考 |
|---------------------|------|------|
| `project.toml` | 可 | プロジェクト固有設定（唯一の動的ファイル） |
| `prompts/` | 不可 | スターターキット提供のフェーズプロンプト |
| `templates/` | 不可 | スターターキット提供のドキュメントテンプレート |
| その他 | 不可 | スターターキット提供ファイル |

### 廃止対象

| ファイル | 理由 |
|---------|------|
| `prompts/additional-rules.md` | 内容を `project.toml` に統合 |

---

## タイミング別フロー

### セットアップ時（初回のみ）

```
1. prompts/setup-prompt.md を実行
2. ユーザーとの対話でプロジェクト情報を収集
3. docs/aidlc/project.toml を生成
4. docs/aidlc/ 配下に静的ファイルを配置
```

### フェーズ実行時

```
1. ユーザーがフェーズプロンプトを指示
   例: 「docs/aidlc/prompts/construction.md を読んで v1.2.0 の Construction を継続」
2. AIが project.toml を読み込み
3. AIがサイクルディレクトリを特定
4. フェーズ処理を実行
```

### フロー図

```
[セットアップ]
    │
    ▼
┌─────────────────┐
│ project.toml   │ ← 生成（初回のみ）
│ 生成            │
└─────────────────┘
    │
    ▼
[フェーズ実行時]
    │
    ▼
┌─────────────────┐
│ project.toml   │ ← 読み込み
│ 読み込み        │
└─────────────────┘
    │
    ▼
┌─────────────────┐
│ サイクル特定    │ ← ユーザー指示 or ディレクトリ名
│ (v1.2.0 等)    │
└─────────────────┘
    │
    ▼
┌─────────────────┐
│ フェーズ処理    │
│ 実行           │
└─────────────────┘
```

---

## プロンプト記述方式の変更

### Before（変数置換方式）

```markdown
## 進捗管理ファイル読み込み
`docs/cycles/{{CYCLE}}/construction/progress.md` を読み込む
```

### After（AI読み取り方式）

```markdown
## 最初に実行すること
1. `docs/aidlc/project.toml` を読み込む
2. ユーザーから指示されたサイクルを確認
3. サイクルディレクトリを特定

## 進捗管理ファイル読み込み
サイクルディレクトリ内の `construction/progress.md` を読み込む
```

**利点**:
- 変数置換処理が不要
- プロンプト内のパス記述が減少（コンテキスト節約）
- 置換漏れのリスク解消

---

## 移行方針

### 後続 Unit での対応

| Unit | 対応内容 |
|------|---------|
| Unit 3: セットアップ分離 | `project.toml` 生成処理を実装 |
| Unit 4: フェーズプロンプト改修 | 変数置換方式 → AI読み取り方式への変更 |
| Unit 5: プロンプト分割・短縮化 | プロンプト内パス記述の簡素化 |

### additional-rules.md 廃止手順

1. 現在の内容を `project.toml` の `[rules]` セクションに移行
2. `additional-rules.md` を削除（または参照のみのファイルに変更）
3. フェーズプロンプトから `additional-rules.md` への参照を削除

---

## 設計判断の記録

| 項目 | 決定 | 理由 |
|------|------|------|
| 設定ファイル形式 | TOML | セクション明確、コメント可、エラーになりにくい |
| 配置場所 | docs/aidlc/project.toml | docs構造に統一、configディレクトリ不要 |
| サイクル固有設定 | ファイルなし | ディレクトリ名から導出可能 |
| 変数置換 | 廃止 | AI読み取り方式に変更 |
| additional-rules.md | 廃止 | project.toml に統合 |
