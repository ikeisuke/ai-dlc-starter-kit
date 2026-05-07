# PRFAQ — ai-dlc-starter-kit v2.5.4

## Press Release

**ai-dlc-starter-kit v2.5.4 リリース — Operations / worktree / レビュー運用の構造的健全化**

AI-DLC（AI-Driven Development Lifecycle）スターターキット v2.5.4 を本日リリース。v2.5.3 リリース直後に顕在化した 4 件の構造的脆弱性 / 運用ノイズを統合解消した patch リリース。

主な改善点:

- **Operations §7 ステップ7「完了」更新タイミング統一**: AI エージェントが PR マージ前完結契約に違反する経路をドキュメントレベルで構造的に消す
- **メインリポジトリ health check**: worktree 環境での Operations Phase 開始時に、過去のマージ残骸 / コンフリクトを早期検出
- **設計レビュー早期 defer ガイド**: Round 3 終了時点で千日手予兆を検出し、5R 到達前にユーザー判断を促す
- **helper の zsh source 互換性保証**: Claude Code のデフォルトシェル（zsh）から AI エージェントが手順記述通りに動作することを保証

## FAQ

### Q1: なぜ v2.5.4 patch リリースか？

A: v2.5.3 リリース直後に AI エージェントの auto mode 動作で顕在化した運用ノイズ（progress.md マージ後編集 / post-merge-cleanup 失敗 / zsh source 互換性）を、次の minor リリース（v2.6.0）まで温存せず即時解消するため。各 Unit の改修規模も patch スコープに収まる小規模なもの。

### Q2: 既存の AI-DLC 利用者への影響は？

A: 後方互換を維持。既存の Operations Phase progress.md / history / Operations release scripts の挙動は破壊しない。Unit 001（記述変更のみ）/ Unit 003（記述追加のみ）は既存挙動に影響なし。Unit 002（health check 新設）は Operations Phase 開始時に新ステップが追加されるが、健全状態では exit 0 で続行する。Unit 004（predecessor-issue.sh の zsh 互換性）は bash 動作が完全互換。

### Q3: v2.5.3 で起票した Issue #648（suggest-permissions 拡張）/ #652（振り返り 3 層検証 skill 化）は対応されないのか？

A: 本 patch サイクルでは規模が大きいため OUT_OF_SCOPE とし、次サイクル以降で対応予定。本サイクルは「直近で顕在化した運用ノイズの即時解消」をテーマとして 4 件に絞っている。

### Q4: メインリポジトリ health check は Operations Phase 以外でも実行されるのか？

A: 本サイクルでは Operations Phase 開始時のみ。Inception / Construction Phase での呼び出しは OUT_OF_SCOPE（次サイクル候補）。worktree 環境を主対象とし、通常リポジトリでの動作は best-effort。

### Q5: 設計レビュー特化の早期 defer ガイドは Inception / Operations Phase のレビューにも適用されるか？

A: いいえ、Construction Phase の設計レビュー（ドメインモデル / 論理設計）に **限定**。Inception / Operations Phase のレビューには適用しない（Unit 003 境界で明示）。これは設計レビュー特有の議論密度・後半での仮説追加・個別点漸進パターンに特化したガイドのため。

### Q6: zsh 互換性は他の helper（feedback-mode.sh / validate-git.sh 等）でも保証されるのか？

A: 本サイクルでは `predecessor-issue.sh` の修正のみが必須対象。他 5 helper（`aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` / `retrospective-issue.sh`）はテスト追加のみで構造変更しない（patch スコープ保護）。`feedback-mode.sh` / `validate-git.sh` 等への確認は OUT_OF_SCOPE（次サイクル候補）。
