# Construction Phase 進捗管理

## Unit 一覧

| Unit | 状態 | 担当ストーリー | 依存 | 完了日 |
|------|------|--------------|------|--------|
| 001 pr-ops-empty-list-fix | 完了 | ストーリー 7（#588） | なし | 2026-04-23 |
| 002 update-version-script-change | 完了 | ストーリー 6a（#596 実装側） | なし | 2026-04-23 |
| 003 update-version-docs-comms | 完了 | ストーリー 6b（#596 周知側） | Unit 002 | 2026-04-23 |
| 004 aidlc-setup-prompts-package-removal | 完了 | ストーリー 5（#595） | なし | 2026-04-23 |
| 005 inception-milestone-step | 完了 | ストーリー 1, 4（#597 Unit B） | なし | 2026-04-23 |
| 006 operations-milestone-close | 完了 | ストーリー 2（#597 Unit A） | なし | 2026-04-23 |
| 007 docs-milestone-rewrite | 完了 | ストーリー 3（#597 Unit C） | Unit 005, 006 | 2026-04-23 |

## 実装順序（推奨）

依存関係上、以下の順で着手するのが妥当（並列化可能な Unit は同時進行）:

1. **第 1 グループ（独立、並列可）**: Unit 001 / Unit 002 / Unit 004 / Unit 005 / Unit 006
2. **第 2 グループ（依存後）**: Unit 003（Unit 002 完了後） / Unit 007（Unit 005, 006 完了後）

## 現在の Unit

なし（全 Unit 完了、Operations Phase へ遷移可能）

## 完了済み Unit

- Unit 001 pr-ops-empty-list-fix（2026-04-23、Issue #588 解消、PR マージ時 auto-close 想定、bash 3.2 / 5.x 両対応確認済み）
- Unit 002 update-version-script-change（2026-04-23、Issue #596 実装側完了、starter_kit_version 上書き廃止 + メタ開発シナリオ動作確認済み）
- Unit 003 update-version-docs-comms（2026-04-23、Issue #596 ドキュメント周知完了、CHANGELOG #596 節 / bin/update-version.sh ヘッダ / .aidlc/rules.md / docs/configuration.md 更新、Operations 引き継ぎタスク作成済み、サイクル PR マージで #596 auto-close 準備完了）
- Unit 004 aidlc-setup-prompts-package-removal（2026-04-23、Issue #595 解消、`skills/aidlc-setup/steps/01-detect.md` L89-L91 純削除 + 空行整理、CHANGELOG `### Removed` #595 節追加（挙動変化・注意文・将来バックログ扱い明記）、fixture 4 ケース動作確認 OK、サイクル PR マージで #595 auto-close 準備完了）
- Unit 005 inception-milestone-step（2026-04-23、Issue #597 Unit B 部分対応、Inception Phase 02-preparation/05-completion/index.md の Milestone 化 + 5 ケース判定 + PATCH フォールバック + 関連 Issue awk 抽出 + cycle-label.sh / label-cycle-issues.sh DEPRECATED 注記、Markdown 整合性検証 全 OK / bash -n syntax check 全 OK、Unit 007 への CHANGELOG `#597` 節 deprecation 記載依頼明記）
- Unit 006 operations-milestone-close（2026-04-23、Issue #597 Unit A 部分対応、Operations Phase 01-setup ステップ11「Milestone 紐付け確認・fallback 判定」追加 / 04-completion ステップ5.5「Milestone close」追加 / index.md §2.8 補助契約追記、5 ケース判定 + 冪等補完原則 + マージ前完結契約準拠 + LINK_FAILED 集約判定 exit 1 契約 + gh_status != available 時 exit 1 契約、codex implementation review 5 反復で auto_approved 適格達成、Unit 007 への CHANGELOG `#597` 節 Operations 側追記依頼明記）
- Unit 007 docs-milestone-rewrite（2026-04-23、Issue #597 Unit C 完了、公開ドキュメント書き換え（issue-management / backlog-management / backlog-registration / glossary）+ CHANGELOG `[2.4.0]` 節を Keep a Changelog 順序（Added → Changed → Deprecated → Removed）に再構成、`#597` 関連 6 項目追加、手動復旧 3 パターン分岐（A-1 duplicate/closed / A-2 LINK_FAILED Issue+PR / B gh 不可 curl+PAT+UI 3a/3b）、過剰修正回避（docs/configuration.md / README.md / .aidlc/rules.md は no-op）、Markdown 整合性検証 全 OK、サイクル PR マージで #597 auto-close 準備完了 → Unit 005 / 006 / 007 の 3 Unit すべて完了）

## 次回実行時の指示

全 7 Unit 完了。`/aidlc operations` で Operations Phase を開始してください。
