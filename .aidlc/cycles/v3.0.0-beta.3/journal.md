# Journal: v3.0.0-beta.3

<!--
追記型の軽量記録。日付見出し（## YYYY-MM-DD）配下に作業証跡を箇条書きで追記する。
全 step の詳細記録は義務化しない（要点のみ）。次サイクルの define で参照可能にする。
-->

## 2026-07-04

- define completed: intent and 3 work items created (001-v3-config-schema-final / normal / medium, 002-release-hard-gate-fallback / normal / medium / deps:001, 003-migrate-v2-to-v3-core / risky / high / deps:001)
- スコープ: #745（release hard gate required CI 0 件フォールバック / 7-d 残り）+ Epic #736 7-c（v2→v3 migration: new-cycle-only + archive-only）+ v3 config キー終端設計（SoT ギャップ解消）。best-effort モードは後続サイクルへ defer（ユーザー承認済み / Epic #736 へ注記予定）
- 付随: beta.2 で解消済みの #744 / #747 を close（PR #748 merged 根拠のコメント付き）
- 実行経路: `/aidlc-v3 i`（Skill 起動 / plugin cache 366bcc657a50）。単文字 `i` は旧名 inception = define と解釈
- 前サイクル state.json（beta.2 / complete 導出・PR #748 merged 確認済み）を削除して state-init.sh で再生成（create-only 仕様のため / beta.2 サイクルの precedent に準拠）

## 2026-07-05

- develop completed: 001-v3-config-schema-final
- matrix_case: normal_standard（design: simple / review: code）。design 承認: semi_auto auto 承認 / code review: codex 2R（R1 指摘 1 件低→resolved / R2 clean）auto_approved
- 確定内容: v3 config.toml 終端キー集合 = 8 キーを data-model.md §11 に新設（SoT 一意化）。キーパスは v2 互換 `[rules.<domain>]` 維持 / 維持 7 キー identity + 新規 1（`rules.release.required_ci_zero_fallback` / 既定 false）+ drop 27（警告）。002 の opt-in 発動形態は「config フラグ + 発動時ユーザー承認の二段」で確定。RFC §6.4 の終端値の揺れ（8 か 12 か）は 8 で確定。migration.md §8 SoT ギャップ注記を解消し §3.1 キーマッピング表を新設（参照は RFC §6.4 → data-model §11 ← migration §3.1 の一方向）
- develop completed: 002-release-hard-gate-fallback
- matrix_case: normal_standard（design: simple / review: code）。design 承認: semi_auto auto 承認 / code review: codex 2R（R1 指摘 1 件中〔security: 検証 0 件でも承認だけで merge 可能な経路〕→ fail-closed 化で resolved / R2 clean）auto_approved
- 確定内容: release.md Step 3-4 hard gate に「required CI 0 件フォールバック（opt-in / #745）」を明文化。適用条件 = フラグ true + PR identity 不変 + required 0 件の正常取得 + CLEAN/rollup 健全。発動 = ローカル検証（最低 1 件 pass 必須 / 0 件は停止）+ ユーザー明示承認（semi_auto でも自動承認しない）+ release.md 記録 → 3-4 再実行（再承認不要 / head 一致で担保）。既定 false = 現行 fail-closed 不変。検証: markdownlint 0 errors / test-release-flow.sh 65 pass
