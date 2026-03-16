# 論理設計: セットアップ時のデフォルト許可パターン追加

## 概要

`setup-ai-tools.sh` に新ステップを追加し、`.claude/settings.json` へデフォルト許可パターンを自動設定する処理を設計する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコード（SQL、JSON、実装コード等）はImplementation Phase（コード生成ステップ）で作成します。

## アーキテクチャパターン

手続き型シェルスクリプト。既存の `setup-ai-tools.sh` に新関数 `setup_claude_permissions()` を追加する。既存の `setup_claude_skills()` / `setup_kiro_skills()` / `setup_kiro_agent()` と同列の関数として配置。

## コンポーネント構成

### モジュール構成

```text
setup-ai-tools.sh
├── setup_claude_skills()       [既存]
├── setup_kiro_skills()         [既存]
├── setup_kiro_agent()          [既存]
├── setup_claude_permissions()  [新規: オーケストレーション]
│   ├── _detect_json_state()    [新規: JSON状態判定]
│   ├── _merge_permissions()    [新規: パターンマージ]
│   ├── _generate_template()    [新規: テンプレートJSON生成]
│   └── _write_atomic()         [新規: 原子的書き込み]
└── メイン処理                   [変更: ステップ番号更新]
```

### コンポーネント詳細

#### setup_claude_permissions()

- **責務**: オーケストレーション - 小関数を組み合わせて許可パターン設定フロー全体を制御する
- **依存**: jq（オプション）、python3（オプション）、mktemp、mv
- **公開インターフェース**: 引数なし、stdout にステータス出力。最終行に `result:STATUS` 形式（例: `result:created`）で機械判定可能な結果種別を出力

#### _detect_json_state()

- **責務**: `.claude/settings.json` の存在・妥当性を判定する
- **引数**: file_path
- **戻り値（stdout）**: `absent` / `valid` / `invalid` / `unknown`（jq・python3不在時。`unknown`はオーケストレーション側でdegraded経路へ遷移）
- **依存**: jq（優先）、python3（フォールバック）

#### _merge_permissions()

- **責務**: 既存パターンとデフォルトパターンをマージし、重複排除した結果を返す
- **引数**: existing_json_path, patterns_array
- **戻り値（stdout）**: マージ済みJSON文字列
- **依存**: jq（優先）、python3（フォールバック）

#### _generate_template()

- **責務**: デフォルトパターンを含むテンプレートJSONを生成する
- **引数**: patterns_array
- **戻り値（stdout）**: JSON文字列
- **依存**: なし（ヒアドキュメントで生成）

#### _write_atomic()

- **責務**: テンポラリファイル経由で原子的にファイルを書き込む
- **引数**: target_path, content
- **戻り値**: 終了コード（0: 成功, 1: 失敗）
- **依存**: mktemp、mv

#### メイン処理の変更

- **変更内容**: ステップ番号を `[1/3]` `[2/3]` `[3/3]` → `[1/4]` `[2/4]` `[3/4]` `[4/4]` に変更
- **新規追加**: `[4/4] Setting up Claude Code permissions...` として `setup_claude_permissions` を呼び出す

## スクリプトインターフェース設計

### setup_claude_permissions() 関数

#### 概要

`.claude/settings.json` にAI-DLC用デフォルト許可パターンを設定する。

#### 引数

なし（関数内で定数として許可パターンを定義）

#### 処理フロー

```text
1. デフォルトパターン配列を定義
2. _detect_json_state() で状態判定
   ├── absent → _generate_template() → _write_atomic() → result=created
   ├── invalid → backup → _generate_template() → _write_atomic() → result=created
   ├── valid → ステップ3へ
   └── unknown → 警告出力 → result=degraded
3. マージツール利用可否チェック（jq → python3 → なし）
   ├── jq or python3 利用可 → ステップ4へ
   └── 両方不在 → 警告出力 → result=degraded
4. _merge_permissions() でマージ
   ├── 新規パターンあり → _write_atomic() → result=updated
   └── 新規パターンなし → result=skipped
5. 結果出力（result種別に応じたメッセージ）
```

#### JSON状態判定ロジック（_detect_json_state）

| 条件 | 判定結果 |
|------|---------|
| ファイルが存在しない | `absent` |
| ファイルが存在し、`jq . file >/dev/null 2>&1` が成功 | `valid` |
| ファイルが存在し、jq不在の場合 `python3 -c "import json; json.load(open('file'))"` で判定 | `valid` / `invalid` |
| ファイルが存在し、jq・python3ともに不在の場合 | `unknown`（バリデーション不可 → degraded経路へ遷移） |
| ファイルが存在し、上記チェックが失敗 | `invalid` |

#### テンプレートJSON生成（_generate_template）

不在時・不正JSON時に生成するテンプレート。ヒアドキュメントで直接出力（ツール依存なし）。

構造:
```text
{
  "permissions": {
    "allow": [
      ... パターン ...
    ]
  }
}
```

#### パターンマージ処理（_merge_permissions）

既存の `.claude/settings.json` にパターンを追加する場合:

**安定マージ方針**: 既存の `permissions.allow` 配列の順序を保持し、未登録パターンのみ末尾に追加する。これにより差分が最小化され、順序に意味を持たせる将来要件にも対応可能。

**jq利用時**:
1. 既存の `permissions.allow` 配列を取得（存在しない場合は空配列）
2. デフォルトパターンのうち既存に含まれないものを末尾に追加
3. 元のJSONの `permissions.allow` を更新後の配列で置換
4. 既存の他のキー（`permissions.deny` 等）は保持

**python3利用時（jq不在のフォールバック）**:
1. python3でJSONを読み込み
2. `permissions.allow` の既存順序を保持し、未登録パターンを末尾に追加
3. 元のJSONの他のキーを保持したまま出力

#### 結果種別と出力メッセージ

| 結果種別 | 出力メッセージ |
|---------|-------------|
| `created` | `Created: .claude/settings.json (default permissions)` |
| `updated` | `Updated: .claude/settings.json (N new permissions added)` |
| `skipped` | `Skipped: .claude/settings.json (all permissions already present)` |
| `degraded` | `Warning: jq/python3 not found, cannot update existing .claude/settings.json` |
| `failed` | `Warning: Failed to write .claude/settings.json, skipping` |

- 終了コード: `0`（常に成功。セットアップ全体を中断しない）
- 出力先: stdout（既存関数の出力と統一）
- 最終行に `result:STATUS` 形式で機械判定可能な結果種別を出力（例: `result:created`）
- メイン処理は結果種別を `Done:` メッセージに含めて出力可能

#### その他の警告出力

```text
Backup: .claude/settings.json → .claude/settings.json.bak (invalid JSON)
```

## データモデル概要

### ファイル形式

- **形式**: JSON
- **パス**: `.claude/settings.json`
- **主要フィールド**:
  - permissions: Object - 許可設定
  - permissions.allow: String[] - 許可パターン配列

### デフォルトパターン一覧

具体的なパターンは計画ファイル（unit-003-plan.md）のセクション3を正本として参照。

| # | パターン種別 | 件数 |
|---|------------|------|
| 1 | `Bash(docs/aidlc/bin/*.sh:*)` 形式（引数可変） | 16件 |
| 2 | `Bash(docs/aidlc/bin/*.sh)` 形式（引数なし） | 2件 |
| 3 | `Bash(mktemp /tmp/aidlc-*.XXXXXX)` 形式 | 5件 |
| 4 | `Skill(*)` 形式 | 6件 |
| | **合計** | **29件** |

## 処理フロー概要

### メインフロー: setup_claude_permissions()

**ステップ**:
1. デフォルトパターン配列を定義
2. `_detect_json_state()` で状態判定
3. 状態に応じた分岐処理（新規作成 / マージ / バックアップ＋新規作成）
4. `_write_atomic()` で原子的書き込み
5. 結果種別に応じたステータス出力

**関与するコンポーネント**: setup_claude_permissions() + 4つの小関数

## 非機能要件（NFR）への対応

### セキュリティ

- **要件**: 許可対象を最小限に限定
- **対応策**: AI-DLCスクリプトのみを対象とするパターンに限定。プロジェクト固有のスクリプトは含めない。`:*` は引数が可変なスクリプトにのみ付与

### 可用性

- **要件**: セットアップ全体を中断しない
- **対応策**: 全エラーケースで `return`（`exit` しない）。ツール不在時はdegraded結果。書き込み失敗時はfailed結果＋テンポラリファイル削除

## 技術選定

- **言語**: Bash（既存スクリプトと同一）
- **ツール依存**: jq（オプション、優先）、python3（オプション、jq不在時のフォールバック）
- **原子的書き込み**: `mktemp` + `mv`（同一ディレクトリ内）

## 実装上の注意事項

- テンポラリファイルのクリーンアップ漏れを防ぐため、`trap` ではなく書き込み後の即時削除パターンを使用（既存関数との一貫性）
- `permissions.allow` が存在しない既存JSONの場合は、jq/python3で `permissions` オブジェクトと `allow` 配列を生成してからマージ
- `mv` によるリネームはアトミックだが、異なるファイルシステム間では非アトミック。テンポラリファイルは同一ディレクトリ（`.claude/`）に作成する
- ヒアドキュメントでのJSON生成時、末尾カンマや不要な空白に注意
- 小関数名は `_` プレフィックスでプライベート慣例を明示
- バックアップ戦略は `.bak` 固定（1回実行前提の運用制約）。世代バックアップが必要になった場合は将来拡張として対応

## 不明点と質問（設計中に記録）

（なし - 計画フェーズおよびレビューで解決済み）
