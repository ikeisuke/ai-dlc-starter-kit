# ドメインモデル: session-title表示順変更

## エンティティ

### SessionTitle

セッション識別用のタイトル文字列を生成・表示するエンティティ。

**属性**:

| 属性 | 型 | 必須 | 説明 |
|------|-----|------|------|
| project_name | 文字列 | 必須 | プロジェクト名 |
| cycle | 文字列 | オプション（空許容） | サイクルバージョン（空の場合は表示スキップ） |
| phase | 文字列 | 必須 | フェーズ名（Inception/Construction/Operations） |
| unit | 文字列 | オプション | ユニット識別子（Construction Phase時のみ） |

**振る舞い**:

- `build_title()`: 属性から表示タイトル文字列を組み立てる
  - 基本形: `{project_name} / {cycle} / {phase}`
  - unit指定時: `{project_name} / {cycle} / {phase} / {unit}`
  - cycle が空の場合: `{project_name} / {phase}`
  - cycle が空 かつ unit指定時: `{project_name} / {phase} / {unit}`

## 値オブジェクト

### DisplayOrder

表示順序を定義する値オブジェクト。

**変更前**: `project_name / phase / cycle`
**変更後**: `project_name / cycle / phase [ / unit ]`

## 引数マッピング

### 変更前

```text
$1 = project_name
$2 = phase
$3 = cycle
```

### 変更後

```text
$1 = project_name
$2 = cycle
$3 = phase
$4 = unit (オプション)
```

## 呼び出し元との契約

| フェーズ | project_name | cycle | phase | unit |
|---------|-------------|-------|-------|------|
| Inception | toml から取得 | ブランチから抽出（不明時は空） | Inception | なし |
| Construction（初回） | toml から取得 | CYCLE変数 | Construction | なし（Unit未決定） |
| Construction（Unit確定後） | toml から取得 | CYCLE変数 | Construction | Unit名 |
| Operations | toml から取得 | CYCLE変数 | Operations | なし |

## 呼び出しタイミング

- **Inception**: ステップ1.5で1回呼び出し
- **Construction**: ステップ2.6で初回呼び出し（unitなし）、ステップ4でUnit確定後に再度呼び出し（unit付き）
- **Operations**: ステップ2.6で1回呼び出し

## docs/aidlc との関係

`docs/aidlc/` 配下のファイルは `prompts/package/` からrsyncで同期されるコピーであり、直接編集しない。`prompts/package/` のみを変更対象とする。
