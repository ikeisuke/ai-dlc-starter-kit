# Journal: v3.0.0-rc.1

<!--
追記型の軽量記録。日付見出し（## YYYY-MM-DD）配下に作業証跡を箇条書きで追記する。
全 step の詳細記録は義務化しない（要点のみ）。次サイクルの define で参照可能にする。
-->

## 2026-07-11

- define completed: intent and 3 work items created (001-v2-maintenance-branch / tiny / low, 002-v3-mainline-replacement / risky / high / deps:001, 003-readme-docs-renewal / normal / low / deps:002)
- スコープ: Epic #736 7-e（フル本流化）を RC として実施。`skills/aidlc-v3 → skills/aidlc` 置換 + v2 保全（v2-maintenance branch）+ README 刷新 + marketplace `3.0.0-rc.1` 化。GA（v3.0.0）は RC 検証後の後続サイクル。best-effort migration / v2 EOL 宣言はスコープ外（beta.3 での defer を維持）
- 付随: beta.3 で解消済みの #745 を close（PR #750 merged 根拠のコメント付き）
- 実行経路: `/aidlc-v3 i`（Skill 起動 / plugin cache 366bcc657a50）。単文字 `i` は旧名 inception = define と解釈
- 前サイクル state.json（beta.3 / complete 導出・PR #750 merged 確認済み）を削除して state-init.sh で再生成（create-only 仕様のため / beta.2 / beta.3 サイクルの precedent に準拠）
- work item 複数 + risky 含みのため express 連続実行は適用外（フェーズ個別実行）

## 2026-07-12

- develop completed: 001-v2-maintenance-branch
- matrix_case: tiny_standard（design / review とも skip）。origin/main（2545af6b = beta.3 merge 後）から `v2-maintenance` branch を作成し remote へ push。skills/aidlc / reviewing-\* 等 v2 実装一式の包含と作成元 SHA（002 開始前の main）を検証済み

## 2026-07-24

- develop completed: 002-v3-mainline-replacement
- matrix_case: risky_standard（design: full + Rollback Note / review: code_security）。design 承認: manual approved / review: codex パス 1・2 rounds（P2 1 件 = state-init.sh の `..` ガード不整合を修正して Round 2 clean）
- 実施内容: `skills/aidlc-v3` → `skills/aidlc` 置換（同一パス残置原則 / 残置 v2 資産 14 ファイル）、v2 専用 8 スキル撤去、aidlc-migrate の v2→v3 専用化（v1 は v2-maintenance 案内）、marketplace `3.0.0-rc.1` 化（9 skills / 当初 10 と誤記・release 統合レビューで訂正）、bin / CI workflows / tests の参照整合（defaults-sync 撤去・migration-tests 削減）、残置 md の発リンク閉包
- 検証: v3 内部テスト 11 本 PASS / bats 113 件 pass / bin checks（skill-references / parse-guard / bash-substitution / test-isolation / size）全 exit 0 / markdownlint 0 issues / migrate preflight が候補 2（skills/aidlc/scripts/state-init.sh）解決で status:ok / `aidlc-v3` 残存は履歴（.aidlc / CHANGELOG / docs）と意図的参照のみ
- develop completed: 003-readme-docs-renewal
- matrix_case: normal_standard（design: simple / review: code）。design 承認: semi_auto auto approved / review: codex パス 1・4 rounds（R1 4 件 + R2 2 件 + R3 1 件を修正、R4 clean / defer 1 件 = Issue #754 defaults.toml の required_ci_zero_fallback 未収載を OUT_OF_SCOPE 起票）
- 実施内容: README を v3 前提へ全面刷新（badge rc.1 / v3 コマンド体系・引数なしルーティング・express・旧名エイリアス / 初期導線 = config.toml 手動作成 → /aidlc define / v2-maintenance 参照案内 + /aidlc-migrate 導線 / v2 固有機能記述の撤去）、docs/configuration.md を v3 終端 8 キーのリファレンスへ全面改稿、docs/v3-renewal-plan.md の doctor 正本ポインタ更新、docs/development/github-projects-setup.md の v2 Inception 統合記述を歴史的注記化
- 検証: markdownlint 0 issues / skill-reference-check no violations（74 files）/ README 残存 v2 表記 grep 0 件

## 2026-07-26

- release completed: v3.0.0-rc.1 (PR #755 merged)
- release-level review（codex / required）: premerge 中1低1（中: stale v2 テスト撤去 2ee683da / 低: Issue #756）、integration 中1低1（中: D8 設計変更反映 + Issue #757 / 低: 件数誤記訂正 0668c663）、deploy 高1中2 → R2 で全件解消確認（494a97cb / 572e01b1: Rollback Note 配布モデル訂正・CHANGELOG rc.1 を merge 前 PR に同梱・破壊的変更対応表）。merge_blocker_any = false → semi_auto 自動承認
- hard gate: main ruleset に撤去済み job の required context（Defaults TOML Sync Check）が残存し BLOCKED となったため、ruleset 11757623 から当該 context のみ除去（D7 の defaults-sync 撤去に伴う環境側後始末）。required 4 件（CodeQL / Skill Reference / Bash Substitution / Markdown Lint）全 pass + CLEAN を確認して merge 実行（--match-head-commit 11160c83）
- tag `v3.0.0-rc.1` は auto-tag.yml が merge commit a3c12bb1 に自動作成（config version_tag = false のため手動 tag なし / 正規経路）。CHANGELOG は deploy 指摘 #2 対応で merge 前に同梱済みのため Step 4 での追記なし
