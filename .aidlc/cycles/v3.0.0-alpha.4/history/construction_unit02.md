# Construction Phase 履歴: Unit 02

## 2026-06-23T12:05:21+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-frontmatter-parse-ci-guard（02-frontmatter-parse-ci-guard（禁止パースパターンの CI 機械検出 / T4））
- **ステップ**: AIレビュー完了
- **実行内容**: Phase 2 実装: bin/check-frontmatter-parse-guard.sh（frontmatter 構造解釈の禁止パターン検出 / トークンベース検出 + 論理コマンド単位スキャン〔strip_comment lexer + unit_incomplete スタックベース字句解析〕 + 限定 allow マーカー / 終了コード 0/1/2 / opt-in skip）+ bin/tests/check-frontmatter-parse-guard.sh（自己完結型 conformance 43 アサート）+ work-item-status.sh への allow マーカー 1 行 + GitHub Actions skill-reference-check.yml への step 追加 + PATHS_REGEX 更新。AI レビューを 4 段で実施（全て codex / 対象タイミング: 計画承認前・設計レビュー・コード生成後・統合とレビュー）。計画レビュー 3R（R1 3件→R3 0件）/ 設計レビュー 5R（R1 3件→R5 1件）/ コードレビュー 5R（R1 5件→R5 1件）/ 統合とレビュー 5R（R1 2件→R5 1件）、全件 resolved（unresolved 0）。Self-Healing: テストハーネス fresh_dir のサブシェル counter バグ（mktemp -d 化）/ 単一引用符パリティ誤計上（コメント中アポストロフィ / strip_comment + command-gated 継続）を修正（attempt 1-2 / recoverable）。実リポジトリ走査 違反0（7ファイル / consumer は Unit 001 移行済み）/ v3 全6スイート緑・既存 check 3本緑（回帰なし）/ shellcheck OK。semi_auto ゲートで自動承認。
- **成果物**:
  - `bin/check-frontmatter-parse-guard.sh`
  - `bin/tests/check-frontmatter-parse-guard.sh`
  - `.aidlc/cycles/v3.0.0-alpha.4/construction/units/002-review-summary.md`

---
## 2026-06-23T12:06:00+09:00

- **フェーズ**: Construction Phase
- **Unit**: 02-frontmatter-parse-ci-guard（02-frontmatter-parse-ci-guard（禁止パースパターンの CI 機械検出 / T4））
- **ステップ**: Unit完了
- **実行内容**: Unit 002（禁止パースパターンの CI 機械検出 / T4 / #733 部分対応）完了。skills/aidlc-v3/scripts/ の consumer スクリプト（lib/ と tests/ を除く）に frontmatter 構造解釈の禁止パターン（生 grep/sed/awk/permissive jq）が混入していないか機械検出する独立スクリプト bin/check-frontmatter-parse-guard.sh を新設し、GitHub Actions skill-reference-check.yml の既存単一ジョブに step として追加（別ジョブ化せず Detect skip / checkout / permissions を共有）。検出方針は候補 C（トークンベース検出 + 限定 allow マーカー）。論理コマンド単位スキャンはスタックベース字句解析 unit_incomplete で引用符状態・$() ネストを正しく処理（変数経由・複数行・関数経由の取りこぼし防止）。allow マーカー除外は awk の atomic write idiom（全行 passthrough + key 書き換えシグネチャ）のみに厳密化し、reason/issue/ref 必須・stale 検出（marker 除去で違反再現）・リポジトリ全体の許可 marker 集合固定（status.sh の 1 件のみ）で統制。opt-in シグナル（走査対象不在で exit 0 / starter kit 判定分岐を埋めない）。conformance テスト 43 アサート（合格 C1/C2/C3/B/heredoc 非検出・違反①〜⑤/変数経由/複数行/関数経由/汎用キー/permissive jq 全検出・marker 統制・システムエラー）全緑。実リポジトリ走査 違反0（consumer は Unit 001 で全移行済み）。v3 全6スイート緑・既存 check 3本緑（回帰なし）・shellcheck OK。計画/設計/コード/統合の 4 AI レビュー（codex）を全て completed（unresolved 0 / 計画3R・設計5R・コード5R・統合5R）。完了条件チェックリスト全項目達成。残課題（OUT_OF_SCOPE）なし。意思決定記録: 対象なし（候補 C 採用は AI の設計判断でユーザー選択場面なし）。markdownlint: Unit 002 成果物 0 エラー。
- **成果物**:
  - `bin/check-frontmatter-parse-guard.sh`
  - `bin/tests/check-frontmatter-parse-guard.sh`
  - `.github/workflows/skill-reference-check.yml`
  - `.aidlc/cycles/v3.0.0-alpha.4/construction/units/frontmatter_parse_ci_guard_implementation.md`

---
