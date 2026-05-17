# ドメインモデル: Unit 003 Operations §7.13 直前マージ前完結契約最終確認

## ステップ 0: 事前コード読込み

> 適用条件: depth_level != minimal の場合のみ必須。minimal は設計ステップ自体スキップ可のため N/A（U2 で規定した SoT に従う）。
>
> 本 Unit 自身の通常経路ドッグフーディングは本サイクル Operations Phase §7.13 通過時に retrofit で `.aidlc/cycles/v2.6.5/history/operations.md` に記録する（検証ケース (a) 通常）。

### (a) Read 対象ファイル + 目的

| ファイル | 目的 |
|---------|------|
| `skills/aidlc/steps/operations/operations-release.md` | §7.13 内既存の「マージ方法確定」「設定保存」「未コミット差分検出ガード」「マージ実行確認」の順序を確認 |
| `skills/aidlc/steps/operations/02-deploy.md` | §7.13 サブステップ一覧 (line 197) の表記スタイルを確認、目次責務として確認の存在のみ追記する位置を特定 |
| `skills/aidlc/SKILL.md`（AskUserQuestion 使用ルール / ユーザー選択種別） | 「区切り判断での AskUserQuestion 禁止」例外として位置付け、`automation_mode` 非依存の正当化根拠を確認 |

### (b) 設計時に意識すべき挙動

- 既存「マージ実行確認」(line 443-451) は `gh pr merge` 実行直前の最終ゲート。本新規ゲートはそれより前段で「記録完了 / 凍結対象確認」を担う（責務直交）
- `02-deploy.md` 側は目次のみ、SoT は `operations-release.md` のみという二重 SoT 化禁止
- `back_to_record` 選択時は段階依存維持のため §7.6 → §7.7 → §7.8 → ... → §7.12.6 → 新規最終確認 → マージ実行確認 → §7.13 の経路を再通過

### (c) 既存実装に基づく代替案検討

- **採用**: 「マージ実行確認」直前に独立 AskUserQuestion セクション追加 + 役割分担（記録完了 vs マージ最終承認）を明文化
- **却下**: 既存「マージ実行確認」のメッセージに「記録完了確認」を統合 → 質問が複雑化し選択肢分岐が増える / 役割混在

## 概要

PR マージ実行前に「マージ前完結契約（progress.md ステップ7「完了」確定 / 修正コミット記録漏れなし）」を最終確認するユーザー選択ゲート。`automation_mode` 非依存・例外なし常時実行。

## エンティティ

### PreMergeFinalConfirmation

- **ID**: `(cycle, pr_number)`
- **属性**: `cycle`, `pr_number`, `frozen_files`, `user_choice`
- **振る舞い**: `present()` で AskUserQuestion 起動、`apply_choice()` で `proceed_to_merge` / `back_to_record` の遷移

## 値オブジェクト

### ChoiceId

- enum: `proceed_to_merge` / `back_to_record`

### FrozenFile

- **属性**: `path` (string) - マージ前完結契約成立後に凍結対象となるファイルパス
- 主要値: `.aidlc/cycles/<cycle>/operations/progress.md`、サイクル成果物全般

## 集約

### PreMergeFinalGate

- **集約ルート**: `PreMergeFinalConfirmation`
- **境界**: 1 つの PR マージに対する 1 回の最終確認サイクル
- **不変条件**:
  - `automation_mode` に関わらず 1 回必ず提示（`full_auto` 含む全モード）
  - `back_to_record` 選択時は §7.6/§7.7 → §7.8〜§7.12.6 を再通過してから本ゲートに再到達（論理設計・計画書と同一記述粒度で統一）
  - 提示順序: 既存「マージ方法確定 → 設定保存 → 差分ガード → 【本ゲート】→ マージ実行確認 → gh pr merge」

## ドメインサービス

### PreMergeFinalConfirmationPresenter

- **責務**: AskUserQuestion 提示用メッセージ組み立て（凍結対象ファイル一覧 + post-merge `write-history.sh exit 3` ガード説明 + 選択肢）

## ユビキタス言語

- **マージ前完結契約 (Pre-Merge Completion Contract)**: progress.md ステップ7「完了」+ `release_gate_ready=true` + `completion_gate_ready=true` が §7.7 Git コミットで PR ブランチに確定する設計原則。マージ後の編集は禁止
- **凍結対象ファイル (Frozen File)**: マージ前完結契約成立後、§7.13 マージ完了まで編集禁止のファイル群
- **post-merge ガード**: `write-history.sh` の `--operations-stage post-merge` 検出時 exit 3 で停止する既存メカニズム。本 Unit の pre-merge ゲートと対称
