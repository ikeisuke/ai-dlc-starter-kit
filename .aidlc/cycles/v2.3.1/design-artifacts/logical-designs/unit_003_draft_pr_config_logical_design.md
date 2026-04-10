# 論理設計: ドラフトPR作成設定の固定化

## 概要

`defaults.toml`、`index.md`、`05-completion.md` の3ファイルに対する変更により、`draft_pr` 設定によるドラフトPR作成の固定化を実現する。

## アーキテクチャパターン

**Strategy Pattern（設定駆動）+ Normalize-then-Dispatch**: `draft_pr` の生値を正規化してから分岐判定し、結果のactionをExecutionに渡す。正規化と判定はBranch Logic層に、実行はExecution層に分離する。

## コンポーネント構成

### 変更対象ファイルと責務

```text
config/defaults.toml          [Configuration - デフォルト値]
  └── [rules.git] draft_pr = "ask"

steps/inception/index.md       [Branch Logic - 正規化+分岐判定]
  └── §2.8 draft_pr 分岐
      ├── 正規化契約（read-config終了コード→draft_pr_effective+decision_source）
      └── resolveDraftPrAction（gh_status,draft_pr_effective,existing_pr→action）

steps/inception/05-completion.md [Execution - action実行+診断表示]
  └── ステップ5: action に応じた実行 + decision_source による警告表示
```

## インターフェース設計

### resolveDraftPrAction（`index.md` §2.8 で定義）

```text
Input:
  gh_status: available | other
  draft_pr_effective: always | never | ask（正規化済み）
  existing_pr: boolean

Output:
  action: skip_unavailable | skip_existing_pr | skip_never | ask_user | create_draft_pr
```

| gh_status | existing_pr | draft_pr_effective | action |
|-----------|------------|-------------------|--------|
| != available | - | - | `skip_unavailable` |
| available | true | - | `skip_existing_pr` |
| available | false | `never` | `skip_never` |
| available | false | `ask` | `ask_user` |
| available | false | `always` | `create_draft_pr` |

### 正規化契約（`index.md` §2.8 で定義）

| read-config.sh 終了コード | draft_pr_raw | draft_pr_effective | decision_source | 警告メッセージ |
|--------------------------|-------------|-------------------|-----------------|--------------|
| 0 | `always`/`never`/`ask` | そのまま | `explicit` | なし |
| 0 | その他 | `ask` | `defaulted_invalid` | `⚠ draft_pr の値が不正です（"{value}"）。デフォルト値 "ask" を使用します。` |
| 1 | - | `ask` | `defaulted_missing` | `⚠ draft_pr が未設定です。デフォルト値 "ask" を使用します。` |
| 2 | - | `ask` | `fallback_error` | `⚠ draft_pr の読み取りに失敗しました。デフォルト値 "ask" を使用します。` |

### ステップ5 処理フロー（`05-completion.md` で実装）

```text
gh_status 判定
├─ [!= available] → skip_unavailable（read-config.sh は実行しない）
└─ [available]
    → read-config.sh rules.git.draft_pr を実行
    → 正規化（index.md §2.8 の正規化契約に従う）
    → decision_source が explicit 以外なら警告表示
    → resolveDraftPrAction（index.md §2.8）を評価
    → action に応じた実行:
        ├─ skip_existing_pr → 既存PR表示
        ├─ skip_never → スキップ（設定によりスキップメッセージ）
        ├─ ask_user → ユーザー確認（AskUserQuestion）→ 作成/スキップ
        └─ create_draft_pr → 自動作成
```

## 実装上の注意事項

- `defaults.toml` の `[rules.git]` セクションに `draft_pr = "ask"` を追加
- `index.md` に §2.8 として `draft_pr` 分岐セクションを新設（正規化契約 + resolveDraftPrAction テーブル）
- `05-completion.md` のステップ5を書き換え: 正規化→判定→実行の流れで `index.md §2.8` を参照
- PR作成のコマンド・テンプレート参照・成功時メッセージは既存のまま維持
