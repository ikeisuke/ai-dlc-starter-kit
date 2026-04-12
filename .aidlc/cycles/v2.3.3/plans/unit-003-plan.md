# Unit 003 計画: 05-completion.md設定保存フロー分離

## 概要
`steps/inception/05-completion.md` のステップ5dに同居している「action分岐」と「設定保存フロー」を構造的に分離し、設定保存フローの読み飛ばしを防止する。

## 背景
Issue #566: `draft_pr=ask` でユーザーが選択後、ステップ5e（PR作成実行）に意識が移り、同じステップ5d内の設定保存フローが完全にスキップされた。

## 修正対象
- `skills/aidlc/steps/inception/05-completion.md`（ステップ5d周辺）

## 修正内容

### 1. ステップ5dの責務を「action分岐 + ユーザー選択」のみに限定
- `skip_never` / `ask_user` / `create_draft_pr` の分岐ロジックはそのまま維持
- `ask_user` セクション内の「設定保存フロー」を削除（次ステップに移動）
- **出力**: 2段階のデータを定義
  - `action`: DraftPrAction（`resolveDraftPrAction` 契約の出力をそのまま透過）
  - `user_confirmation`: UserConfirmation | null（`ask_user` 時のみ、ユーザーの「はい/いいえ」選択結果）

### 2. 新ステップ「5d-1. 設定保存フロー」を5dと5eの間に追加
- ステップ5dの直後、ステップ5eの直前に配置
- **入力**: `action` + `user_confirmation`
- **実行条件**: `action` が `ask_user` の場合のみ実行（`skip_*` / `create_draft_pr` ではスキップ）
- 内容: 現在ステップ5d内にある設定保存フロー全体をそのまま移動
  - 「この選択を設定に保存しますか？」の確認
  - 保存先スコープ選択（local / project）
  - 保存実行（`confirmed=true` → `always`、`confirmed=false` → `never`）

### 3. ステップ5eの前提条件を明確化
- **入力**: `action` + `user_confirmation`
- **前提条件**: `action=ask_user` の場合はステップ5d-1完了後、`action=create_draft_pr` の場合はステップ5d完了後に実行
- **実行条件**: `action=create_draft_pr`、または `action=ask_user` かつ `confirmed=true` の場合のみ

### ステップ間遷移フロー

```text
5d (action分岐) → action + user_confirmation を出力
  ├─ skip_never          → 5d-1スキップ → 5eスキップ → 完了
  ├─ ask_user + yes      → 5d-1実行(設定保存) → 5e実行(PR作成)
  ├─ ask_user + no       → 5d-1実行(設定保存) → 5eスキップ → 完了
  └─ create_draft_pr     → 5d-1スキップ → 5e実行(PR作成)
```

## 設計方針
- **ロジック変更なし**: 設定保存フローの内容自体は変更せず、構造（配置）のみ変更
- **Issue #566 対策案A採用**: 独立ステップ分離により、構造的に見落としを防止
- **既存契約準拠**: `resolveDraftPrAction` の出力とユーザー応答を別の値として分離し、既存インターフェース契約との整合性を維持

## 完了条件チェックリスト
- [ ] 設定保存フローがステップ5d内から独立ステップ（5d-1）に移動されている
- [ ] ステップ5dの出力が2段階（action + user_confirmation）で定義されている
- [ ] ステップ5d-1の入力・実行条件（`action=ask_user` の場合のみ）が明記されている
- [ ] ステップ5eの前提条件が条件付きで定義されている（5d-1実行時は完了後、スキップ時はスキップ確定後）
- [ ] 分離後のステップ5d → 5d-1 → 5eの遷移フローが明文化されている
- [ ] 設定保存フローのロジック自体が変更されていない（構造分離のみ）
