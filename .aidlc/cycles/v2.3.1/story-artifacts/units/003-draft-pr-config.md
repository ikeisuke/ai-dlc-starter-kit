# Unit: ドラフトPR作成設定の固定化

## 概要

Inception Phase 完了時のドラフトPR作成判断を `config.toml` の `rules.git.draft_pr` キー（`always/never/ask`）で設定可能にし、毎回の確認を省略できるようにする。#551 と #557 を統合。

## 含まれるユーザーストーリー

- ストーリー 3: ドラフトPR作成設定の固定化

## 責務

- `config/defaults.toml` に `rules.git.draft_pr` キーを追加（デフォルト: `ask`、有効値: `always/never/ask`）
- `inception/index.md` §2.7.1 に `draft_pr` 分岐の正規化契約と `resolveDraftPrAction` を唯一の正本として一元記載
- `steps/inception/05-completion.md` のステップ5に `draft_pr` 分岐の実行手順を実装（判定ロジックは `index.md` §2.7.1 を参照）

## 境界

- `draft_pr` は PR作成方針のみを表す独立設定であり、`automation_mode` とは無関係。`ask` は常にユーザー選択（`AskUserQuestion`）として扱う
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

- 正規化契約（終了コード別処理、バリデーション、警告文言）は `index.md` §2.7.1 を唯一の正本とする
- `gh_status` との組み合わせ: `always` でも `gh_status != available` なら `skip_unavailable`
- 既存の `gh pr list` による重複PR検出は維持
- 分岐責務: 意味定義・正規化は `index.md` に一元化、`05-completion.md` は `action` に応じた実行手順のみ

## 関連Issue

- #557
- #551（統合してクローズ）

## 実装優先度

Medium

## 見積もり

小〜中（defaults.toml にキー追加 + 05-completion.md の分岐追加 + 設定取得・バリデーション経路の実装 + index.md 分岐追記）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-11
- **完了日**: 2026-04-11
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
