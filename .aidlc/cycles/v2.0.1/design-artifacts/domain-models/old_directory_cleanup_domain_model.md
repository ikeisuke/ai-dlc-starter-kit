# ドメインモデル: 旧ディレクトリ移行・削除

## 概要

v1からv2へのスキル化に伴い、`docs/aidlc/` 配下の旧ディレクトリが `skills/aidlc/` に移行済みだが、参照パスが未更新のファイル群を一括修正する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

### PathMapping（パス置換マッピング）

- **属性**:
  - old_path: String - 旧パスパターン（置換元）
  - new_path: String - 新パスパターン（置換先）
  - scope: String - 適用対象ディレクトリ
- **振る舞い**:
  - apply(file): 指定ファイル内の old_path を new_path に置換

### TargetFile（置換対象ファイル）

- **属性**:
  - path: String - ファイルパス
  - category: Enum[prompts_package, skills, docs_guides, kiro_agents, bin] - カテゴリ
  - match_count: Integer - 旧パスの出現回数

## 値オブジェクト（Value Object）

### PathMappingRule

置換ルールを定義。各ルールは `replacement_type` を持つ:

| # | old_path | new_path | replacement_type | 備考 |
|---|---------|---------|-----------------|------|
| 1 | `docs/aidlc/templates/` | `skills/aidlc/templates/` | path_replace | テンプレート参照 |
| 2 | `docs/aidlc/config/` | `skills/aidlc/config/` | path_replace | 設定ファイル参照 |
| 3 | `docs/aidlc/bin/` | `skills/aidlc/scripts/` | path_replace | スクリプト参照 |
| 4 | `docs/aidlc/skills/` | `skills/` | path_replace | スキルディレクトリ参照 |
| 5a | `docs/aidlc/prompts/common/` | `skills/aidlc/steps/common/` | path_replace | ステップファイル |
| 5b | `docs/aidlc/prompts/lite/` | `skills/aidlc/steps/lite/` | path_replace | Liteステップ |
| 5c | `docs/aidlc/prompts/CLAUDE.md` | `skills/aidlc/CLAUDE.md` | path_replace | ルートファイル |
| 5d | `docs/aidlc/prompts/AGENTS.md` | `skills/aidlc/AGENTS.md` | path_replace | ルートファイル |
| 5e | `docs/aidlc/prompts/inception.md` | `/aidlc inception` | command_redirect | スキルコマンド |
| 5f | `docs/aidlc/prompts/construction.md` | `/aidlc construction` | command_redirect | スキルコマンド |
| 5g | `docs/aidlc/prompts/operations.md` | `/aidlc operations` | command_redirect | スキルコマンド |
| 5h | `docs/aidlc/prompts/setup.md` | `/aidlc setup` | command_redirect | スキルコマンド |
| 5i | `docs/aidlc/prompts/operations-release.md` | `skills/aidlc/steps/operations/` | manual_override | 個別確認要 |

**replacement_type**:
- `path_replace`: 単純な文字列置換
- `command_redirect`: パス参照をスキルコマンド呼び出しに変換
- `manual_override`: 文脈依存のため個別判断が必要

### ExclusionScope（除外スコープ）

以下は置換対象から除外:
- `.aidlc/cycles/` 配下の履歴データ（過去のサイクル記録は変更しない）
- `docs/versions/` 配下のバージョンアーカイブ
- `CHANGELOG.md`（変更履歴として正確に残す）

## 集約（Aggregate）

### MigrationBatch

- **集約ルート**: PathMapping
- **含まれる要素**: PathMappingRule（5件）、TargetFile（53件）
- **境界**: 活性ファイル（上記ExclusionScope外）のみ
- **不変条件**: 置換後のパスが実在するディレクトリ/ファイルを指すこと

## コンテキスト境界

| コンポーネント | 役割 |
|-------------|------|
| `skills/aidlc/` | Canonical Source（正本） |
| `.claude/skills/` | Adapter（シンボリックリンク） |
| `.kiro/agents/` | Adapter（エージェント定義） |
| `docs/aidlc/guides/` | Documentation Consumer |
| `prompts/package/` | Legacy Source（v2.0.2廃止予定） |

## ユビキタス言語

- **活性ファイル**: 現在のコードベースで実際に使用されるファイル（履歴・アーカイブを除く）
- **旧パス**: v1時代の `docs/aidlc/` 配下のパス
- **v2パス**: スキル化後の `skills/aidlc/` 配下のパス
- **正本**: コンポーネントの一次ソース（`skills/aidlc/`）

## 不明点と質問（設計中に記録）

（なし - 要件はバックログIssueで明確）
