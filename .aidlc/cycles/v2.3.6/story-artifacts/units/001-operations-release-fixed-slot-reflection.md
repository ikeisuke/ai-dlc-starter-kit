# Unit: operations-release.md への固定スロット反映ステップ追加

## 概要

Operations Phase のリリース手順ガイドである `skills/aidlc/steps/operations/operations-release.md` §7.6 を改訂し、`release_gate_ready` / `completion_gate_ready` / `pr_number` という固定スロットを §7.7 最終コミットに含めることを明示する。マージ前完結契約（`phase-recovery-spec.md` §5.3）を手順書単体で導出可能な状態にする。

## 含まれるユーザーストーリー

- ストーリー 1.1: 固定スロットの反映手順が `operations-release.md` から明確に導出できる（#583-A）

## 責務

- `skills/aidlc/steps/operations/operations-release.md` §7.6 への固定スロット反映ステップの追記。
- §7.2〜§7.6 で progress.md の状態遷移を記述する他節との整合性を確保するための軽微な文言調整。
- 必要に応じた §7 冒頭の概要文への参照追加（「固定スロット反映はマージ前完結契約の一部」である旨）。

## 境界

- `write-history.sh` の実装変更は扱わない（Unit 002 の責務）。
- `04-completion.md` の禁止記述追加は扱わない（Unit 002 の責務）。
- `phase-recovery-spec.md` や `operations/index.md` の仕様本文は変更しない（参照先の記述を追加する場合のみ）。
- Inception progress.md の命名統一は扱わない（Unit 003 の責務）。

## 依存関係

### 依存する Unit

- なし（独立）

### 外部依存

- なし

## 非機能要件（NFR）

- **可読性**: §7.6 を読むだけで固定スロット 3 種の反映手順が完結して把握できる。
- **整合性**: `phase-recovery-spec.md` §7（構造化シグナル）の固定スロット名と厳密に一致する。
- **互換性**: 既存 Operations Phase フロー（通常系 PR）の動作を変更しない。

## 技術的考慮事項

- 固定スロット名の表記揺れを防ぐため、スロット名は `phase-recovery-spec.md` §7 の Authoritative 表記（`release_gate_ready` / `completion_gate_ready` / `pr_number`）を参照するリンク構造にするか検討する。
- `skills/aidlc/guides/` 配下に旧 `operations-release.md` 互換リンクがあれば、参照整合性を確認する（なければ対応不要）。
- 編集は Markdown のみ。シェル・スクリプト変更は不要。

## 関連Issue

- #583（部分対応: パターン A のみ。パターン B は Unit 002）

## 実装優先度

Medium

## 見積もり

0.5 日

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
