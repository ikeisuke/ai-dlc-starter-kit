# Unit: aidlc-migrate マージ後フォローアップ

## 概要

`/aidlc-migrate` の最終ステップに、PR マージ後の一時ブランチ削除案内（v1→v2 マイグレーション用 `aidlc-migrate/v2` ブランチ）を追加する。ユーザー対話によるオプトイン方式とし、既存の migrate フロー（verify 完了まで）を破壊しない。

> **対象ブランチ名修正（Construction Phase Unit 002 着手時）**: 当初 Unit 定義は `chore/aidlc-v<version>-upgrade` を対象として記述していたが、これは aidlc-setup スキルが生成するブランチ名であり、aidlc-migrate スキルは v1→v2 専用の `aidlc-migrate/v2` ブランチを生成する。Issue #607 本文は setup ケースのみ言及しているが、Unit 002 の本質的意図「マージ後の一時ブランチ削除案内」は migrate 側でも同様の利用者体験向上に寄与するため、対象ブランチを `aidlc-migrate/v2` に修正してスコープを維持する。詳細は decisions.md DR-016 を参照。

## 含まれるユーザーストーリー

- ストーリー1: マイグレーション用一時ブランチの自動削除案内（migrate スコープ、対象ブランチ: `aidlc-migrate/v2`）

## 責務

- `skills/aidlc-migrate/steps/03-verify.md`（§4 PR push 案内の後ろ、§5 として新規追加）に、以下のフローを追加:
  1. **マージ確認ガード**: 「v1→v2 マイグレーション PR をマージしましたか？」をユーザーに確認（はい / いいえ / 判断保留）
  2. **チェックアウト位置切替案内**（マージ済み回答時）: 現在ブランチが `aidlc-migrate/v2` の場合、削除前に HEAD を `origin/main` に detach する手順を案内（git 制約: チェックアウト中ブランチは削除不可）
  3. **一時ブランチ削除案内**（HEAD 切替後）: `aidlc-migrate/v2` ローカル + リモートブランチの削除を提案 → 同意で `git branch -d`（失敗時 `-D` 再確認）+ `git push origin --delete`（push 失敗時は warning + 継続）。3 択（ローカル+リモート / ローカルのみ / スキップ）で push 権限不在ユーザーに対応
- `skills/aidlc-migrate/SKILL.md`: 「ステップ実行」リスト構造で完結している場合は変更不要。Phase 1 設計レビューで確認
- スキップ選択時はローカル/リモートいずれも変更しない

## 境界

- `aidlc-setup` 側の処理（一時ブランチ削除 + HEAD 同期）は Unit 001 で扱う（本 Unit のスコープ外）
- 本格的な HEAD 同期処理（5 サブ条件マトリクス）は本 Unit のスコープ外。**ただし `aidlc-migrate/v2` 削除のためにはチェックアウト位置を切り替える必要があり、最低限の HEAD 切替（`git checkout --detach origin/main` 1 ケースのみ）は本 Unit に含める**（Construction Phase 着手時の発見、DR-016 参照）
- 未コミット差分ガード / 5 サブ条件マトリクス（worktree / main 系判定）は本 Unit のスコープ外（migrate のフロー特性上、03-verify.md §4 直後は通常クリーンな状態）
- `bin/post-merge-sync.sh` への変更は行わない
- 対象ブランチは `aidlc-migrate/v2` のみ（v1→v2 マイグレーション固定。Issue #607 が言及する `chore/aidlc-v<version>-upgrade` は Unit 001 で対応済み）

## 依存関係

### 依存する Unit

- **ソフト依存（推奨実装順序: Unit 001 → Unit 002）**: Unit 001 / Unit 003 とは独立して並列実装可能だが、#607 のローカル/リモート一時ブランチ削除ロジックが Unit 001 と重複するため、Unit 001 を先に実装してパターンを確定し、Unit 002 がそれを参照する順序が望ましい。並列実装する場合は Construction Phase の設計レビュー時に共通フォーマット（共通メッセージテキスト / 同一の git コマンド系列）を予め確定しておく

### 外部依存

- `git` CLI（標準依存）

## 非機能要件（NFR）

- **パフォーマンス**: 追加処理は対話 + 数回の `git` コマンド呼び出しのみ
- **セキュリティ**: リモート push 権限不足時は warning のみで停止しない
- **可用性**: 既存の migrate フロー（verify まで）は本 Unit の処理失敗時にも完了している必要がある

## 技術的考慮事項

- **対話 UI**: `AskUserQuestion` 利用が有力候補だが、Construction Phase で Unit 001 と統一する形で確定
- **Unit 001 との共通化**: #607 のローカルブランチ削除ロジックは Unit 001 と類似。Construction Phase 着手時に setup/migrate で共通フォーマット（共通メッセージテキスト / 同一の git コマンド系列）を採用するか、各スキル内で独立記述するかを設計レビューで判断
- **HEAD 同期未対応の理由**: `/aidlc-migrate` のアップグレード後に HEAD 同期を必須とするユースケースが現時点では具体化されていない（Issue #605 は setup スキル限定）。本 Unit ではスコープ外とし、必要が確認されれば将来 patch で追加検討

## 関連Issue

- #607（部分対応、migrate 側のみ。setup 側は Unit 001）

## 実装優先度

High

## 見積もり

小規模〜中規模（手順書追記のみ。Unit 001 完了後に共通フォーマットを参照すれば短縮）。Construction Phase で 1 Unit セッション内に収まる想定。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-27
- **完了日**: 2026-04-27
- **担当**: Claude Code (Opus 4.7)
- **エクスプレス適格性**: -
- **適格性理由**: -
