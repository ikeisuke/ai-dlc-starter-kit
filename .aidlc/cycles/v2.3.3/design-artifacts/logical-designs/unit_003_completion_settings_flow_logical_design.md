# 論理設計: 05-completion.md設定保存フロー分離

## 概要
`steps/inception/05-completion.md` のステップ5d内に同居する「設定保存フロー」を独立ステップ5d-1として分離する構造変更の詳細設計。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン
パイプラインパターン（ステップの直列実行）。ステップ5d → 5d-1 → 5eの順序で、2段階のデータ（`DraftPrAction` + `UserConfirmation`）を介して受け渡す。Markdownの見出し構造でステップ境界を表現し、AIエージェントが各ステップを順番に実行する。

## コンポーネント構成

### 変更対象ファイル

```text
skills/aidlc/steps/inception/05-completion.md
└── ### 5. ドラフトPR作成【推奨】
    ├── ステップ5a. gh_status判定（変更なし）
    ├── ステップ5b. draft_pr取得・正規化（変更なし）
    ├── ステップ5c. 既存PR確認（変更なし）
    ├── ステップ5d. actionに応じた実行（★責務縮小）
    ├── ステップ5d-1. 設定保存フロー（★新規追加）
    └── ステップ5e. PR作成実行（★前提条件追記）
```

### コンポーネント詳細

#### ステップ5d（変更後）
- **責務**: 上流で確定済みの `DraftPrAction` に応じた分岐実行と、`ask_user` 時のユーザー選択取得
- **依存**: ステップ5b（`draft_pr_effective`）、ステップ5c（既存PR確認結果）
- **入力**: `DraftPrAction`（ステップ5a-5cの判定結果から `resolveDraftPrAction` 契約で確定済み: `skip_unavailable` | `skip_existing_pr` | `skip_never` | `ask_user` | `create_draft_pr`）
- **出力**:
  - `action`: DraftPrAction（そのまま透過）
  - `user_confirmation`: UserConfirmation | null（`ask_user` 時のみ生成、`true` = はい / `false` = いいえ）
- **変更内容**: 「設定保存フロー」サブセクションを削除。`ask_user`の選択肢表示と結果取得までを責務とする

#### ステップ5d-1（新規）
- **責務**: ユーザーの選択結果の設定永続化確認・実行
- **入力**: `action`（DraftPrAction）+ `user_confirmation`（UserConfirmation）
- **実行条件**: `action` が `ask_user` の場合のみ（`skip_*` / `create_draft_pr` ではスキップ）
- **内容**: ステップ5dから移動した設定保存フロー全文（ロジック変更なし）
  - 「この選択を設定に保存しますか？」の確認
  - 保存先スコープ選択（`local` / `project`）
  - `write-config.sh` による保存実行（保存値: `confirmed=true` → `always`、`confirmed=false` → `never`）

#### ステップ5e（変更後）
- **責務**: ドラフトPR作成実行（変更なし）
- **入力**: `action`（DraftPrAction）+ `user_confirmation`（UserConfirmation | null）
- **前提条件**: `action` が `ask_user` の場合はステップ5d-1完了後、`create_draft_pr` の場合はステップ5d完了後に実行
- **実行条件**: `action` が `create_draft_pr`、または `action` が `ask_user` かつ `user_confirmation.confirmed=true` の場合のみ
- **変更内容**: 冒頭に前提条件・実行条件の記述を追加

### ステップ間インターフェース

```text
5d (action分岐) → action + user_confirmation を出力
  ├─ skip_never          → 5d-1スキップ → 5eスキップ → 完了
  ├─ ask_user + yes      → 5d-1実行(設定保存) → 5e実行(PR作成)
  ├─ ask_user + no       → 5d-1実行(設定保存) → 5eスキップ → 完了
  └─ create_draft_pr     → 5d-1スキップ → 5e実行(PR作成)
```

## 処理フロー概要

### Markdownの具体的変更箇所

**ステップ5d（縮小）**:
1. 現在の `**ステップ5d. action に応じた実行**` セクション内の `ask_user` ブランチから「設定保存フロー」サブセクション（`選択後、「この選択を設定に保存しますか？」と確認:` 以降のブロック）を削除

**ステップ5d-1（新規追加）**:
1. ステップ5dとステップ5eの間に新しい見出しを追加
2. 実行条件を冒頭に明記: `action` が `ask_user` の場合のみ
3. ステップ5dから削除した設定保存フローの内容をそのまま配置

**ステップ5e（前提条件追記）**:
1. 冒頭に遷移条件を追記: `action` + `user_confirmation` による実行判定

### 変更の差分イメージ

```text
【Before: ステップ5d】
- skip_never: スキップ表示
- ask_user: 選択肢表示 → 設定保存フロー ← ここが同居
- create_draft_pr: PR作成に進む

【After: ステップ5d】
- skip_never: スキップ表示
- ask_user: 選択肢表示 + user_confirmation取得のみ
- create_draft_pr: PR作成に進む

【After: ステップ5d-1（新規）】
- 実行条件: action=ask_user のみ
- 設定保存フロー全文（5dから移動）

【After: ステップ5e（前提追記）】
- 前提条件: action + user_confirmationによる遷移条件
- PR作成実行（既存内容は変更なし）
```

## 非機能要件（NFR）への対応

### 可読性
- ステップの見出しレベルで責務境界が明確化される
- AIエージェントがステップを順番に実行する際、設定保存フローを読み飛ばす構造的リスクが排除される

## 実装上の注意事項
- Markdown見出し構造のみの変更であり、テキスト内容（設定保存フローの記述）自体は変更しない
- ステップ番号体系（5d-1）は既存の番号付けルールとの整合性を確認すること
- `index.md` §2.7.1 の `resolveDraftPrAction` ロジックは変更不要（出力が同じaction値であるため）
- 設定保存の実装詳細（`write-config.sh`、`config.toml` / `config.local.toml`）は5d-1ステップ内の記述として維持する（ドメインモデルではなく実装層の関心事）
