# リリース後の運用記録

## リリース情報

- **バージョン**: v2.6.2
- **リリース日**: 2026-05-12
- **リリース内容**: v2.6 系の運用基盤を機能完成版に固定する patch リリース。v2.6.0 の3領域 defer 完成（振り返りフロー独立化 / marketplace.json への version SoT 一本化 / GitHub Projects 移行）、振り返り分離・Operations フロー周辺の致命的バグ修正、v2.6.1 Issue #688 の根本原因クラス（AI エージェント Bash プロンプト経由の zsh OOM）の一般化予防 を一括解消。

### 含まれる Unit

| Unit | Issue | 概要 |
|------|-------|------|
| 001 | #678 | pr-ready --body-file 空ファイル検証で PR 本文 null 上書き事故防止 |
| 002 | #680 | aidlc-migrate manifest 由来パスのトラバーサル検証 |
| 003 | #677 | Operations §7.12.5 squash-712 / write-history operations-round 整合性 |
| 004 | #682 | gh-project-cli ensure-fields の field options 差分同期実装 |
| 005 | #683 | Unit 006 副作用 bats テスト整備（gh API モック + 4 スクリプト） |
| 006 | #697 | AI エージェント Bash プロンプト経由の zsh OOM クラス予防（規約改訂） |

## 運用状況

メタ開発プロジェクト（AI-DLC スターターキット自身）のため、エンドユーザー稼働指標・パフォーマンス指標は該当なし。

## バックログ整理結果

PR #696 の `Closes` セクションで Issue #677 / #678 / #680 / #682 / #683 / #697 を自動クローズ対象に指定済み。その他の `backlog` ラベル付き Issue は次サイクル以降の対応候補としてそのまま残置。

### 次サイクル候補（参考）

| Issue | 概要 | priority |
|-------|------|---------|
| #705 | review-flow.md の既存 MD038 違反 3 件整理 | low |
| #703 | codex exec の stdin 待ちハング: </dev/null 必須運用の明文化 | medium |
| #701 | security: operations-release.sh cmd_squash_712 への --cycle バリデーション | medium |
| #700 | Construction Phase ルールに「Claude Code 実運用失敗防止 12 ルール」適用検討 | medium |
| #685 | Consumer プロジェクト向け GitHub Projects セットアップ助け | medium |

完全なバックログ一覧は `gh issue list --label backlog --state open` を参照。

## 次期バージョンの計画

未定。バックログ Issue のうち priority:medium / high のものをサイクル開始時に再評価して採用候補を決定する。
