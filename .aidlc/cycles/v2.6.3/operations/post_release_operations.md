# リリース後の運用記録

## リリース情報

- **バージョン**: v2.6.3
- **リリース日**: 2026-05-16
- **リリース内容**: v2.6.2 サイクルの振り返り・Codex レビュー指摘・実運用フィードバック由来の 7 件のバックログ Issue を解決する patch サイクル。規約 SoT の網羅性・AI 実行の再現性・セキュリティ・保守性を底上げする。新機能追加なし。

### 含まれる Unit

| Unit | Issue | 概要 |
|------|-------|------|
| 001 | #706, #703 | AI エージェント Bash 実行の安全規約整備（printf -v result-out 関数 local 命名規約 + codex exec stdin 待ちガード） |
| 002 | #701 | operations-release.sh cmd_squash_712 への --cycle バリデーション導入（security） |
| 003 | #698 | `/aidlc v` 経路の再現性向上（CLI モードガード） |
| 004 | #694 | Operations Phase マージ前 CI 通過確認フローの SoT 化 |
| 005 | #705 | review-flow.md の MD038 違反 3 件の修正 |
| 006 | #702 | write-history.sh の symlink 解決＋repo-root 取得ロジックの共通ヘルパ化 |

## 運用状況

メタ開発プロジェクト（AI-DLC スターターキット自身）のため、エンドユーザー稼働指標・パフォーマンス指標は該当なし。

## バックログ整理結果

PR #707 の `Closes` セクションで Issue #706 / #705 / #703 / #702 / #701 / #698 / #694 を自動クローズ対象に指定済み。その他の `backlog` ラベル付き Issue は次サイクル以降の対応候補としてそのまま残置。

### 次サイクル候補（参考）

| Issue | 概要 | priority |
|-------|------|---------|
| #708 | operations-release.sh の他サブコマンド（record-release-prep-commit / pr-ready）への --cycle バリデーション拡大 | medium |
| #700 | Construction Phase ルールに「Claude Code 実運用失敗防止 12 ルール」適用検討 | medium |
| #685 | Consumer プロジェクト向け GitHub Projects セットアップ助け | medium |
| #709 | markdown lint 実行手段の統一化（npm run lint:md 等） | - |
| #699 | 区切り判断での AskUserQuestion 禁止ルールを SKILL.md に追加 | - |

完全なバックログ一覧は `gh issue list --label backlog --state open` を参照。

## 次期バージョンの計画

未定。バックログ Issue のうち priority:medium / high のものをサイクル開始時に再評価して採用候補を決定する。

## 備考

- v2.6.3 は v2.6.2 までに表面化した規約整備・再現性・保守性改善要素を集約した patch リリース。
- Unit 001 は #706（dynamic scope shadowing 規約）と #703（codex stdin 待ちガード）を「AI エージェント Bash 実行の安全規約整備」テーマで統合し、Single Source of Truth を CLAUDE.md / reviewing-common-base.md に集約した。
- Unit 004 は Operations Phase マージ前 CI 通過確認のフロー自体の SoT 化（ドキュメント整理）であり、CI 設定（`.github/workflows/`）への変更はない。
