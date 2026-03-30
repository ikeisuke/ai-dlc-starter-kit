# 論理設計: session-title表示順変更

## 変更概要

引数順序の変更と、オプショナルなunit引数の追加。

## ファイル別変更詳細

### 1. aidlc-session-title.sh

**引数解析部分**:

```text
変更前:
  PROJECT_NAME="${1:-}"
  PHASE="${2:-}"
  CYCLE="${3:-}"

変更後:
  PROJECT_NAME="${1:-}"
  CYCLE="${2:-}"
  PHASE="${3:-}"
  UNIT="${4:-}"
```

**必須チェック**:

```text
変更前: PROJECT_NAME, PHASE, CYCLE すべて必須（3つ揃わないと exit 0）
変更後: PROJECT_NAME, PHASE 必須（2つ揃わないと exit 0）。CYCLE は空許容（空の場合は表示スキップ）。UNIT はオプション（空の場合は表示スキップ）。
```

**タイトル組み立てロジック**:

```text
TITLE の組み立て:
1. TITLE = "$PROJECT_NAME"
2. CYCLE が非空の場合: TITLE = "$TITLE / $CYCLE"
3. TITLE = "$TITLE / $PHASE"
4. UNIT が非空の場合: TITLE = "$TITLE / $UNIT"
```

**Usage コメント更新**:

```text
変更前: Usage: aidlc-session-title.sh <project_name> <phase> <cycle>
変更後: Usage: aidlc-session-title.sh <project_name> <cycle> <phase> [unit]
```

### 2. SKILL.md

**argument-hint**:

```text
変更前: <project_name> <phase> <cycle>
変更後: <project_name> <cycle> <phase> [unit]
```

**実行方法セクション**:

引数説明の順序変更:
- `project_name`: 変更なし
- `cycle`: 2番目に移動。サイクルバージョン。空の場合は表示スキップ
- `phase`: 3番目に移動
- `unit`: 新規追加。Construction Phase時にUnit名を指定（オプション）

**スクリプト呼び出し例**:

```bash
bash ...aidlc-session-title.sh "$PROJECT_NAME" "$CYCLE" "$PHASE" "$UNIT"
```

### 3. inception.md

**変更箇所**: ステップ1.5のsession-title呼び出し引数説明

```text
変更前:
引数: `project.name`=ステップ1の出力、`phase`=`Inception`、`cycle`=`current_branch` から抽出（不明時は `unknown`）

変更後:
引数: `project.name`=ステップ1の出力、`cycle`=`current_branch` から抽出（不明時は空文字列）、`phase`=`Inception`
```

注: `unknown` → 空文字列に変更（空の場合は表示スキップされるため、unknownを表示する必要がない）

### 6. construction.md（ステップ4後の再呼び出し追加）

**追加箇所**: ステップ4（対象Unit決定）の直後

```text
追加:
Unit確定後、session-titleスキルを再度実行してunit情報を反映する。
引数: `project.name`=`docs/aidlc.toml` の `[project].name`、`cycle`=`{{CYCLE}}`、`phase`=`Construction`、`unit`=Unit名
```

### 4. construction.md

**変更箇所**: ステップ2.6のsession-title呼び出し引数説明

```text
変更前:
引数: `project.name`=`docs/aidlc.toml` の `[project].name`、`phase`=`Construction`、`cycle`=`{{CYCLE}}`（不明時は `unknown`）

変更後:
引数: `project.name`=`docs/aidlc.toml` の `[project].name`、`cycle`=`{{CYCLE}}`（不明時は空文字列）、`phase`=`Construction`、`unit`=Unit名（オプション、Unit作業中の場合のみ）
```

### 5. operations.md

**変更箇所**: ステップ2.6のsession-title呼び出し引数説明

```text
変更前:
引数: `project.name`=`docs/aidlc.toml` の `[project].name`、`phase`=`Operations`、`cycle`=`{{CYCLE}}`（不明時は `unknown`）

変更後:
引数: `project.name`=`docs/aidlc.toml` の `[project].name`、`cycle`=`{{CYCLE}}`（不明時は空文字列）、`phase`=`Operations`
```

## 後方互換性

引数順序が変更されるため、既存の呼び出し箇所すべてを同時に更新する必要がある。スキルの引数はフェーズプロンプトで記述されており、AIが解釈して実行するため、プロンプトの更新のみで対応可能。

## docs/aidlc との関係

`docs/aidlc/` 配下のファイル（`docs/aidlc/prompts/`、`docs/aidlc/skills/`、`docs/aidlc/bin/`）は `prompts/package/` からrsyncで同期されるコピーである。変更は `prompts/package/` のみに対して行い、`docs/aidlc/` への反映はセットアップスクリプト実行時に自動で行われる。
