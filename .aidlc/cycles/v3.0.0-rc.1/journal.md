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
