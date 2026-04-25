# Construction Phase 履歴: Unit 05

## 2026-04-26T01:09:01+09:00

- **フェーズ**: Construction Phase
- **Unit**: 05-milestone-step-md-clarification（Milestone step.md 構造改善（4 ファイル明確化））
- **ステップ**: Unit完了
- **実行内容**: Unit 005「Milestone step.md 構造改善（4 ファイル明確化）」を完了。

## 改訂内容

empirical-prompt-tuning 由来の構造審査指摘 5 件を最小修正で解消（4 ファイル × 5 指摘）:

### F1: skills/aidlc/steps/inception/02-preparation.md L51 追記

「1を選択時の追加処理」: 選択した Issue 番号を改行区切りで `SELECTED_ISSUES` 変数として保持する旨を 1 行追記。

### F2: 02-preparation.md L65 第 2 項目に AND ガード統合

`MILESTONE_ENABLED == true` の項目に「**ただし** `SELECTED_ISSUES` が空の場合は early-link 呼び出し自体をスキップする（呼び出し側 AND ガード）」を統合。設計レビュー指摘により独立箇条書きから階層関係を明示する形に変更。

### F2b: 02-preparation.md L94 既存出力に下位互換注記併記

`early-link:no-issues-provided` 出力に「**下位互換用の出力**であり、呼び出し側 AND ガードにより実運用上は発生しない」注記を併記（Unit 定義 L46 整合）。

### F3: 05-completion.md L98-102 に MILESTONE_NUMBER 抽出例追加

```bash
# MILESTONE_NUMBER の抽出例（ensure-create stdout から awk で抽出）
scripts/milestone-ops.sh ensure-create {{CYCLE}} | awk -F= '{print $NF}'
# 例: 出力 "milestone:v2.4.1:created:number=42" → "42" のみが標準出力される
```

設計レビュー指摘により `grep -oE 'number=[0-9]+' | awk -F= '{print $2}'` の二重 pipe を `awk -F= '{print $NF}'` の 1 段 pipe に簡素化。

### F4: 01-setup.md L165 / L174 / L191 H4 見出しに注記併記

`#### 11-1` / `#### 11-2` / `#### 11-3` の各 H4 見出しに「（setup-step11 内部処理）」注記を併記。番号 11-1 / 11-2 / 11-3 は維持（04-completion.md L247「setup 側 11-1」表記との整合保全）。

### F5: 04-completion.md §5.5 本体無改訂

構造審査で all OK 判定済み（Unit 定義 L21）。L247「setup 側 11-1」表記が改訂後の 01-setup.md と矛盾しないことを目視確認のみ実施。

## Unit 003 引継ぎ事項の解消

Unit 003 レビューサマリで「Unit 005 で対処可能」と明示されていた `05-completion.md` 旧 L124（現 L130）の MD038 lint error（`次の `## ` まで` のコードスパン内 trailing space）を、最小修正（`次の `##` 見出しまで` への変更）で解消。意味は維持。

## 改訂方針の背景

- **Issue**: #602（v2.4.0 で追加した Milestone 関連 step.md 4 ファイルに対する empirical-prompt-tuning 構造審査の指摘 5 件解消）
- **解決方針**: 既存 Milestone 運用仕様（opt-in ガード既定値、5 ケース判定、create/close フロー）には触れず、注記併記・1 行追記・コードブロック追加で AI エージェントの誤解釈を抑止。04-completion.md §5.5 は構造審査 all OK 判定済みのため本体無改訂

## レビュー結果（セルフレビュー継続 - Codex usage limit 到達）

- 計画レビュー（2 ラウンド）: 高×2 / 中×2 / 低×3 → 修正反映 → approved（低×3 残留は軽微）
- 設計レビュー（1 ラウンド）: 中×2 / 低×3、中×2 は実装で吸収（F2 階層改善 / F3 簡素化）
- コードレビュー（1 ラウンド）: 高×0 / 中×0 / 低×4、すべて許容範囲で approved
- 統合レビュー（1 ラウンド）: 結果反映後にレビューサマリへ追記

レビューサマリ: `.aidlc/cycles/v2.4.1/design-artifacts/unit_005_review_summary.md`

## Phase 2b 検証結果

- 文言要件チェックリスト 12 項目すべて PASS（F1-F5 検出 / 件数確認 / 番号維持 / 04-completion.md 無改訂 / 4 ファイル以外無変更 / `$(...)` 不使用 / 整合確認 / Markdownlint 4 ファイル直接 + サイクル全体）
- 既存ロジック保全: 02-preparation.md §16 早期判定フロー、05-completion.md §1-1 / §1-2 / §1-3 の 5 ケース判定、01-setup.md §11 の集約処理、04-completion.md §5.5 close フロー すべて無変更
- 境界保全: `git diff --name-only skills/` で 3 ファイルのみ変更（04-completion.md 本体無改訂、`milestone-ops.sh` / `setup-step11.sh` 等のスクリプト無変更）
- `$(...)` 不使用: 3 ファイルすべて PASS（CLAUDE.md 準拠、F3 抽出例は pipe + `awk -F='{print $NF}'`）
- Markdownlint: 4 ファイル直接 lint で 0 error（既存 MD038 解消含む）、サイクル全体 lint で 0 error

## DR-006 整合

シェルスクリプト無変更、ドキュメント 13 行追加 / 6 行削除（注記併記・記述追加・MD038 修正）のみ。Milestone 運用仕様（opt-in ガード既定値、5 ケース判定、create/close フロー）は無変更で「パッチスコープ実装本体不変方針」と完全整合。

## 次サイクル運用観測点

4 ファイル × 5 指摘の改訂が AI エージェントの解釈精度向上にどれだけ寄与するかは次サイクル以降の実運用で検証する。再発が観測された場合は対応方針（さらなる注記追加、構造変更）を v2.5.0 以降で検討する。
- **成果物**:
  - `skills/aidlc/steps/inception/02-preparation.md`
  - `skills/aidlc/steps/inception/05-completion.md`
  - `skills/aidlc/steps/operations/01-setup.md`
  - `.aidlc/cycles/v2.4.1/plans/unit-005-plan.md`
  - `.aidlc/cycles/v2.4.1/design-artifacts/domain-models/unit_005_milestone_step_md_clarification_design.md`
  - `.aidlc/cycles/v2.4.1/design-artifacts/unit_005_review_summary.md`
  - `.aidlc/cycles/v2.4.1/story-artifacts/units/005-milestone-step-md-clarification.md`

---
