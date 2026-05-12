# Construction Phase 履歴: Unit 06

## 2026-05-12T21:13:44+09:00

- **フェーズ**: Construction Phase
- **Unit**: 06-ai-prompt-zsh-oom-prevention（AI エージェント Bash プロンプト経由 zsh OOM クラス予防）
- **ステップ**: Unit 006 完了
- **実行内容**: ## Unit 006 完了

### 概要

「AI エージェントが Bash ツール経由で渡す文字列内のコマンド置換（`$(...)` / backtick）が zsh `command_not_found_handler` 再帰により OOM クラッシュを起こす根本原因クラス」への予防策を、リポジトリ配布規約（CLAUDE.md / AGENTS.md / SKILL.md / steps/common/ ガイド / CHANGELOG.md）の改訂として確立した。Issue #697（primary / feedback / v2.6.1 Inception Phase 中に実発生）への対応。スクリプト本体動作・引数仕様は無変更（後方互換性 100%）。

### 主要な変更

- **CLAUDE.md**: 「AI エージェント Bash ツール経由の安全パターン」セクションを新設（規約 SoT）。コマンド置換禁止 / 適用範囲 / 背景 / 安全パターン（第一推奨・第二推奨・禁止）/ file-based 経路参考表（履歴記録 / PR 本文 / PR Ready / 外部 CLI レビュー の 4 行）/ 関連 Issue（#697 primary / #688 sibling_resolved）
- **AGENTS.md**: 新規作成（リポジトリルート）。CLAUDE.md ① への参照リンクと最低限の防御 2 項目
- **skills/aidlc/steps/common/bash-tool-safety.md**: 新規ガイド（運用補足）。規約本文は持たず CLAUDE.md SoT を参照する構造で、禁止パターンサンプル / 安全パターン実装スニペット / file-based interface 経路別一覧 / トラブルシューティングを提供
- **skills/aidlc/SKILL.md**: §バージョン表示 §注意セクションを「Bash ツール経由 zsh OOM 回避ルール」として一般化。Issue #688 の `/aidlc v` 経路固有対応は本ルールの一例として位置付け、規約本文 CLAUDE.md / 運用詳細 steps/common/bash-tool-safety.md を実 Markdown リンクで参照
- **skills/write-history/SKILL.md**: `--content` / `--content-file` 使い分けを AI 第一推奨明示に更新（既存 API 動作 無変更）
- **skills/aidlc/steps/common/commit-flow.md**: line 91「プロジェクトルール準拠」表記を CLAUDE.md ① への実 Markdown リンクに格上げ
- **skills/aidlc/steps/common/review-flow.md**: review-summary 引用パス記法と Bash ツール引数規約の責務分離注記を追加
- **CHANGELOG.md**: v2.6.2 セクションを新規追加し、§Changed に本 Unit の規約改訂を記録

### 設計判断（DR-011 / DR-012）

- **DR-011**: SKILL.md 一般化の「案 b（共通ガイド分離）」を採用。4 基準スコアリングで案 a 0 / 案 b 4 → 案 b 採用。decisions.md に追記済
- **DR-012**: AGENTS.md を最小骨格 + CLAUDE.md ① 参照リンクで新規作成（MUST 化）。codex 計画レビュー R1 指摘 #1（高）を解消。decisions.md に追記済

### AI レビュー実施結果

- **計画レビュー（reviewing-construction-plan / codex）**: 3R 完了 / 指摘 5 件解消（R1: 高 1 / 中 2、R2: 中 1 / 低 1、R3: 0 件 clean）/ auto_approved
- **設計レビュー（reviewing-construction-design / codex）**: 3R 完了 / 指摘 5 件解消（R1: 高 1 / 中 2 / 低 1、R2: 低 1、R3: 0 件 clean）/ auto_approved / 対象タイミング: 設計レビュー
- **コードレビュー（reviewing-construction-code / codex）**: 2R 完了 / 指摘 2 件解消（R1: 中 1 / 低 1、R2: 0 件 clean）/ auto_approved
- **統合レビュー（reviewing-construction-integration / codex）**: 2R 完了 / 指摘 2 件解消（R1: 中 1 / 低 1、R2: 0 件 clean）/ auto_approved / 対象タイミング: 統合とレビュー

### 完了条件達成状況

計画 §完了条件チェックリスト 9 項目 + Issue #697 受け入れ基準 4 項目 + Intent 制約適合 4 項目すべて達成。markdownlint-cli2 で改訂ファイル 8 件を検証し新規エラー 0 件（既存 MD038 違反 3 件は #705 backlog 起票済 / Unit 006 改訂前から存在）。

### 関連参照

- Issue: #697（primary / feedback / open）/ #688（CLOSED / v2.6.1 Unit 001 で `/aidlc v` 経路を個別解決済 / 本 Unit はその一般化）/ #705（Unit 006 起票 backlog: 既存 MD038 違反）
- 計画: `.aidlc/cycles/v2.6.2/plans/unit-006-plan.md`
- 設計（ドメインモデル）: `.aidlc/cycles/v2.6.2/design-artifacts/domain-models/unit_006_ai_prompt_zsh_oom_prevention_domain_model.md`
- 設計（論理設計）: `.aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_006_ai_prompt_zsh_oom_prevention_logical_design.md`
- 意思決定記録: `.aidlc/cycles/v2.6.2/inception/decisions.md` DR-011 / DR-012

### 残課題・バックログ

- `#705 [Backlog] review-flow.md の既存 MD038 違反 3 件（区切り規約表現と lint の両立）`（priority:low / type:chore / 本 Unit のスコープ外として記録）
- **成果物**:
  - `CLAUDE.md`
  - `AGENTS.md`
  - `skills/aidlc/SKILL.md`
  - `skills/write-history/SKILL.md`
  - `skills/aidlc/steps/common/commit-flow.md`
  - `skills/aidlc/steps/common/review-flow.md`
  - `skills/aidlc/steps/common/bash-tool-safety.md`
  - `CHANGELOG.md`

---
