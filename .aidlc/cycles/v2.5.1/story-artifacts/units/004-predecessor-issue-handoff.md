# Unit: predecessor handoff の Issue 検索化

## 概要

新サイクル Inception 開始時、前サイクル振り返りをファイル参照ではなく Issue 検索（前サイクル closed Milestone + `retrospective` ラベル の AND 検索）で取得する。0 件 / 1 件 / 複数件 / `gh` 不可 / `milestone_enabled=false` の各分岐を厳密な判定順で実装し、`predecessor_retrospective.md` 関連の手動配置案内を撤去する。v2.5.0 互換の旧 `operations/retrospective.md` 読み取りは fallback で維持。

## 含まれるユーザーストーリー

- ストーリー 4: predecessor handoff の Issue 検索化

## 責務

本 Unit は **読み取り側のみ** 責任を持ち、ラベル / Milestone 命名規約の正本は Intent §「判断 6.1」を参照する（Unit 002 ではなく共有契約から読む）。

- `01-setup.md §4a` の改修（手動配置参照を削除し、Issue 検索ロジックに置き換え）
- `gh issue list --milestone <PREV_CYCLE> --label retrospective --state all` 検索の実装（ラベル名・Milestone 名は Intent §「判断 6.1」より取得）
- 0 / 1 / 複数件分岐の判定（自動採用 / spool fallback / 対話確認）
- `milestone_enabled=false` の場合は label のみ検索 + `closedAt` 降順最新採用 + 確認
- `gh_status != available` 時の spool fallback（`cycles/{{PREV_CYCLE}}/history/retrospective-spool.md`）
- `templates/predecessor_retrospective.md` の廃止（または存在時は警告）
- 既存 `cycles/{{PREV_CYCLE}}/operations/retrospective.md` 読み取り経路維持（v2.5.0 互換 / 追加 fallback として動作）
- コンテキスト変数 `predecessor_retrospective_issue_url` の設定
- 関連 BATS テスト（`tests/predecessor-issue-handoff.bats`）

## 境界

- 振り返り Issue 起票本体は Unit 002 が担う（本 Unit は前サイクル Issue を取得するのみ）
- ラベル / Milestone 命名規約の **正本は Intent §「判断 6.1」**（Unit 002 と共有）。本 Unit は読み取り側として正本を参照する

## 依存関係

### 依存する Unit

- Unit 002: retrospective Issue 一本化 + spool + mirror_state ラベル化（依存理由: Unit 002 が起票実装主体のため、Unit 004 が検索する Issue / spool ファイル がデータ生成側として Unit 002 によって生み出されるデータ生成順依存。命名規約の正本は Intent §「判断 6.1」に一本化済み）

### 外部依存

- `gh` CLI（Issue / Milestone 検索）
- 既存 `01-setup.md §4a`（手動配置案内の削除対象）

## 非機能要件（NFR）

- **検索精度**: 前サイクル retrospective Issue を一意に特定できる（誤り参照防止）
- **可用性**: `gh` 不可 / 0 件時も処理が継続できる（spool fallback / warn 表示）
- **互換性**: v2.5.0 ユーザーの旧 `retrospective.md` ファイル参照経路を読み取りに限り維持

## 技術的考慮事項

- 判定順は厳密に守る（ストーリー 4 の受け入れ基準参照）
- `--state all` で closed Milestone 内の Issue が取得できる
- `predecessor_retrospective.md` テンプレ廃止後、grep で 0 件を確認

## 関連Issue

- なし（独自スコープ / 派生バックログとして次サイクルから持ち越し検討対象）

## 実装優先度

Medium

## 見積もり

小〜中規模。検索ロジック + 分岐判定 + 01-setup.md §4a 改修 + テンプレ廃止 + BATS テスト。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-05
- **完了日**: 2026-05-05
- **担当**: Construction Phase Unit 004
- **エクスプレス適格性**: -
- **適格性理由**: -
