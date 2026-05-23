---
name: aidlc-retrospective
description: >
  AI-DLC サイクル振り返り（retrospective）を独立スキルとして実行する。
  feedback_mode 解決 / KPT + 主因切り分け wizard / cap 判定 / Issue 起票 / spool fallback / mirror_state ラベル化 / dialog token ガードを集約する。
  Use when the user says "/aidlc r", "/aidlc retrospective", "振り返り", "retrospective", "AIDLC振り返り".
argument-hint: "[対象サイクル / 例: v2.6.0]"
---

# AI-DLC 振り返り（retrospective）

> **目的**: T を Issue 化して実行に繋げること。KPT は T を導くための手段です（v2.6.6 / #710 / Unit 001 / SC-01）。

サイクル完了後の振り返り（Keep / Problem / Try）を整理し、必要に応じて GitHub Issue として起票する独立スキル。

> **v2.6.0 破壊的変更**: 本スキルは Operations Phase §1 から振り返り実行ロジックを移転して新設された。Operations Phase は「リリース完了 + post-merge cleanup」までで完結し、振り返りは本スキルで任意のタイミングで実行する。

## ステップ実行

1. `steps/retrospective.md` を読み込んで実行 — 対象サイクル特定 / feedback_mode 解決 / wizard / cap 判定 / 本文構築 / Issue 起票 / spool / mirror

## パス解決

- `steps/` / `scripts/` / `templates/` で始まるパスはスキルのベースディレクトリ（このSKILL.mdと同じディレクトリ）からの相対パスとして解決する
- 共有ライブラリは `skills/aidlc/scripts/lib/retrospective-api.sh`（公開 API 層）経由でのみ参照する。`skills/aidlc/scripts/lib/*.sh` の内部実装への直接 source は禁止
- 共有テンプレートは `skills/aidlc/templates/retrospective_template.md` を参照可

## 単方向境界【重要】

- 本スキルから `/aidlc` スラッシュコマンドを呼ばない
- 本スキルから `skills/aidlc/steps/operations/**` を読まない
- 内部 lib（`retrospective-issue.sh` / `feedback-mode.sh` 等）を直接 `source` しない（公開 API 層 `retrospective-api.sh` 経由のみ）

## v2.6.4 サイクル対象外項目（v2.7.0+ で対応予定）

本スキルは v2.6.4 / #710 / Unit 004 で **opt-in 基盤フラグ** (`rules.retrospective.auto_issue_creation`) と `predecessor_resolve_issue` の 5 経路後方互換確保までを実施した（デフォルト動作不変）。以下は v2.7.0+ で対応予定:

- 振り返り Issue 自動起票の完全廃止（`auto_issue_creation` デフォルト値 `false` 化）
- `Retrospective: {cycle}` タイトル運用の本格的見直し
- `retrospective_api_*` の破壊的変更
- Try/改善単位での個別 Issue 起票実装（1 Try = 1 Issue ループ）

参照: Issue #710 / v2.6.3 サイクル振り返り議論
