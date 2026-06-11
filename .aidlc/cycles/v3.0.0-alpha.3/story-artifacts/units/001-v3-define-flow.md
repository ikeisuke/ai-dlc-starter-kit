# Unit: v3 define フロー実行実装

## 概要

`skills/aidlc-v3/steps/define.md` を「読める手順」から実行可能なフローへ進める。cycle ディレクトリ作成・`intent.md` / `work-items/*.md` / `journal.md` 生成・`state.json` 初期化・branch / commit を実際に行えるようにする。

## 含まれるユーザーストーリー

- ストーリー 1: define を実行して新しい v3 cycle を作成する

## 責務

- v3 形式（フラット構造: `intent.md` / `work-items/` / `journal.md`）の cycle ディレクトリ作成ロジック（**`state.json` は cycle ディレクトリ配下ではなく cycle レベルの `.aidlc/state.json`** / `docs/v3/data-model.md` §2）
- define Step 1〜4（環境チェック / Intent 定義 + 承認ゲート / Work Item 分割 + 承認ゲート / 初期化）の実行手順具体化
- Step 4 での `state.json` 初期化（`state-write.sh` 経由 atomic 書き込み、`define_completed: true`）
- `journal.md` への define 完了追記、cycle ブランチ作成 + 初回 commit
- `templates/intent.md` / `templates/work-item.md` / `templates/journal.md` を用いた成果物生成

## 境界

- develop / release / reflect フローの実装（後続フェーズ）
- `early_pr: true` 時の Draft PR 作成詳細（PR 整備は release フェーズ責務 / 本 Unit は通常パスの「PR 作らない」を実装）
- `status` 実行実装（Phase 6）

## 依存関係

### 依存する Unit

- なし（alpha.2 で実装済みの `state-write.sh` / `state-validate.sh` / テンプレートを利用する）

### 外部依存

- git / `state-write.sh`（alpha.2 成果物）

## 非機能要件（NFR）

- **パフォーマンス**: 1 cycle 作成は数秒以内
- **セキュリティ**: `state.json` 書き込みは `state-write.sh` 経由（atomic / 直接編集禁止）
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項

cycle ディレクトリ作成は安全境界が不要な単純処理（`mkdir -p` 等）であり AI inline で実行可能だが、`state.json` 書き込みは atomic 性が必要なため `state-write.sh` を経由する（RFC P4）。検証は v2 ドッグフーディング用 `.aidlc/` を破壊しないサンドボックス／テストハーネスで行う。

## 関連Issue

- なし

## 実装優先度

High

## 見積もり

0.5〜1 サイクル相当（define フロー手順具体化 + cycle dir ロジック + 検証）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
