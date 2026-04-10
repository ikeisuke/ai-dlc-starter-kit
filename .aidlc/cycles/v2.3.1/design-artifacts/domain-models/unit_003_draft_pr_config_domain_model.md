# モジュール設計: ドラフトPR作成設定の固定化

## 概要

Inception Phase完了時のドラフトPR作成判断を `config.toml` の `rules.git.draft_pr` 設定で制御するモジュール設計。

## モジュール構成

### Configuration Layer（`defaults.toml` / `config.toml`）

`draft_pr` のデフォルト値と上書き値を提供する。

- **責務**: `draft_pr` 設定値の永続化
- **出力**: `read-config.sh` 経由で値を提供
- **有効値**: `always` / `never` / `ask`（デフォルト: `ask`）

### Branch Logic Layer（`inception/index.md`）

`draft_pr` の正規化（`draft_pr_raw` → `draft_pr_effective`）と分岐判定ロジックを一元管理する。

- **責務**:
  - `read-config.sh` の終了コード処理・不正値処理・デフォルト適用を正規化契約として定義
  - `resolveDraftPrAction` 論理インターフェースの提供
- **不変条件**: 正規化ロジックと意味定義はこのレイヤーにのみ存在する

### Execution Layer（`inception/05-completion.md`）

`resolveDraftPrAction` の結果（`action` + `decision_source`）に従い実行手順を提供する。

- **責務**: `action` に応じた実行（PR作成 / ユーザー確認 / スキップ）+ `decision_source` に応じた警告表示
- **依存**: `index.md`（`resolveDraftPrAction` 契約）
- **不変条件**: 正規化・分岐判定の責務を持たない。`action` を受け取るだけ

## 論理インターフェース

### resolveDraftPrAction

```text
Input:
  gh_status: available | other
  draft_pr_raw: read-config.sh の出力値（終了コード付き）
  existing_pr: boolean

Output:
  action: skip_unavailable | skip_existing_pr | skip_never | ask_user | create_draft_pr
  decision_source: explicit | defaulted_missing | defaulted_invalid | fallback_error
```

**正規化（Branch Logic層で実行）**:

| read-config.sh 終了コード | draft_pr_raw | draft_pr_effective | decision_source |
|--------------------------|-------------|-------------------|-----------------|
| 0 | `always` / `never` / `ask` | そのまま | `explicit` |
| 0 | その他 | `ask` | `defaulted_invalid` |
| 1 | - | `ask` | `defaulted_missing` |
| 2 | - | `ask` | `fallback_error` |

**分岐判定（Branch Logic層で実行）**:

| gh_status | existing_pr | draft_pr_effective | action |
|-----------|------------|-------------------|--------|
| != available | - | - | `skip_unavailable` |
| available | true | - | `skip_existing_pr` |
| available | false | `never` | `skip_never` |
| available | false | `ask` | `ask_user` |
| available | false | `always` | `create_draft_pr` |

## 依存方向

```text
config.toml / defaults.toml (Configuration Layer)
  ← read-config.sh で取得
inception/index.md (Branch Logic Layer) [正規化 + 分岐判定]
  ← resolveDraftPrAction 契約を消費
inception/05-completion.md (Execution Layer) [action実行のみ]
```

## 不変条件

1. `draft_pr` は `automation_mode` とは独立した設定
2. `ask` は常にユーザー選択（`AskUserQuestion`）
3. `always` でも `gh_status != available` なら `skip_unavailable`
4. 正規化・意味定義は `index.md` にのみ記載
5. Execution層は `action` + `decision_source` を受け取るだけ

## ユビキタス言語

- **draft_pr**: Inception Phase完了時のドラフトPR作成方針設定値
- **draft_pr_effective**: 正規化後の実効値（`always` / `never` / `ask`）
- **decision_source**: 設定値の由来（`explicit`=明示設定、`defaulted_missing`=キー不在、`defaulted_invalid`=不正値、`fallback_error`=読取障害）
- **action**: 分岐判定結果（`skip_unavailable` / `skip_existing_pr` / `skip_never` / `ask_user` / `create_draft_pr`）
