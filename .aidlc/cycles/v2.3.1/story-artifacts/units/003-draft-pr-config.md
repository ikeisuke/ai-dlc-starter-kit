# Unit: ドラフトPR作成設定の固定化

## 概要

Inception Phase 完了時のドラフトPR作成判断を `config.toml` の `rules.git.draft_pr` キー（`always/never/ask`）で設定可能にし、毎回の確認を省略できるようにする。#551 と #557 を統合。

## 含まれるユーザーストーリー

- ストーリー 3: ドラフトPR作成設定の固定化

## 責務

- `config/defaults.toml` に `rules.git.draft_pr` キーを追加（デフォルト: `ask`、有効値: `always/never/ask`）
- `steps/inception/05-completion.md` のステップ5にdraft_pr設定分岐を実装
- `draft_pr` の取得・有効値検証・不正値警告・`ask` フォールバックのバリデーションロジックを `05-completion.md` 内に実装（`read-config.sh` で値取得、不正値時は `⚠ draft_pr の値が不正です（"{value}"）。デフォルト値 "ask" を使用します。` と警告）
- `inception/index.md` の分岐ロジックに draft_pr 分岐を追記

## 境界

- `automation_mode` との優先関係: `draft_pr` が `automation_mode` より優先
- PR作成後の操作（本文更新、Ready化等）は変更しない
- Operations Phase のPR Ready化フローは変更しない

## 依存関係

### 依存する Unit

- なし

### 外部依存

- なし

## 非機能要件（NFR）

- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項

- `read-config.sh` での値取得・バリデーション（有効値: `always/never/ask`、無効値時は `ask` にフォールバック）
- `gh_status` との組み合わせ: `always` でも `gh_status != available` ならスキップ
- 既存の `gh pr list` による重複PR検出は維持

## 関連Issue

- #557
- #551（統合してクローズ）

## 実装優先度

Medium

## 見積もり

小〜中（defaults.toml にキー追加 + 05-completion.md の分岐追加 + 設定取得・バリデーション経路の実装 + index.md 分岐追記）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
