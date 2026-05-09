# Unit: main-repo-health-check の fixture 誤検出除外（B）

## 概要

`scripts/main-repo-health-check.sh` の `check_conflict_marker()` 関数で発生する fixture/docs 引用の誤検出（v2.5.5 Operations 開始時 count=12）を pathspec 除外で解消し、real な未解決コンフリクトのみを検出する状態に戻す。

## 含まれるユーザーストーリー

- ストーリー 2: main-repo-health-check の fixture 誤検出をなくしたい（B）

## 責務

- `skills/aidlc/scripts/main-repo-health-check.sh:139` `check_conflict_marker()` の `git grep` コマンドに pathspec 除外を追加:
  - `':(exclude)tests/main-repo-health-check.bats'`
  - `':(exclude).aidlc/cycles/**/design-artifacts/**'`
- `tests/main-repo-health-check.bats` に受け入れテスト 2 種を追加:
  - 除外サンプル検証（除外パスに conflict marker があっても warning にならない）
  - 実コンフリクト検出維持（除外対象外のテンポラリパスに作成すると warning として検出される）

## 境界

- 他 check 関数（lock-file / orphan-cycle / unresolved-todo 等）の改修は対象外
- BATS fixture 側の heredoc 連結 escape 案は採用しない（テスト可読性優先）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- `git grep`（pathspec exclude サポート）
- `bats` テストランナー

## 非機能要件（NFR）

- **パフォーマンス**: health-check 実行時間に有意な差が出ないこと
- **可用性**: 既存 health-check 出力フォーマット（`health-check:conflict-marker:ok:count=N` / `health-check:conflict-marker:warning:count=N`）を維持

## 技術的考慮事項

- `git grep` の pathspec 除外は POSIX/BSD/GNU いずれの環境でも動作する
- 除外パターンは半角スペース・全角混在を含まない（zsh / bash 両対応）
- 受け入れテストは `mktemp -d` でテンポラリファイル作成し、tracked ファイル外の検出力を確認

## 関連Issue

- #670

## 実装優先度

High（Must、bug、Intent B）

## 見積もり

小。0.25 日（pathspec 1 行追加 + bats テスト 2 ケース追加）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
