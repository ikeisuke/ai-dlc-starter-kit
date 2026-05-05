# PRFAQ: AI-DLC Starter Kit v2.5.1 - 振り返りエコシステム総仕上げ

## Press Release（プレスリリース）

**見出し**: AI-DLC v2.5.1 リリース — 振り返り運用が GitHub Issue 一本化、主因分析が LLM 自動下書きで進化

**副見出し**: 振り返りローカルファイルを廃止、初回 wizard で起票先を選び、主因分類を Claude Code が下書きする「使い続けられる振り返り」エコシステムを完成

**発表日**: 2026-05 中旬（v2.5.1 patch リリース）

**本文**:

**背景**: v2.5.0 で導入した retrospective 自動生成 + mirror モード + 主因切り分け 3 分類は強力な仕組みだったが、運用上は ① ローカル `retrospective.md` ファイルと mirror Issue の二重管理、② プロダクト固有 / AI-DLC 固有 / 両方 の主因分類が完全手作業、③ 起票先選択肢の不足、④ マージ前 write-history 追加コミット漏れの運用バグ、という 4 つの課題が残っていた。これらは「振り返りはやるけど続かない」「Issue が氾濫する」「事故再発」を生む種となっていた。

**プロダクト**: v2.5.1 では振り返りを **最初から GitHub Issue で完結する** 単一の起票フローへ刷新する。具体的には:

- Operations Phase 振り返り起票直前に **初回 wizard** が起動し、「プロダクト Issue / upstream Issue / 両方 / disabled」から起票先を選択（`feedback_mode` の 5 値拡張）
- 主因分類（3 値）と `skill_caused_judgment` 3 質問の引用文は **Claude Code 自身が下書き** し、人間は確認・修正のみ
- 次サイクル Inception では、ファイル参照ではなく **前サイクル closed Milestone + retrospective ラベル の Issue 検索** で振り返りを取得
- マージ前 write-history 追加コミット漏れには **必ず exit ≥ 1 のガード** が発火、事故再発を防止
- v2.5.0 既存ユーザーへは **同意プロンプト付きマイグレーション** で、知らないうちに動作変更が起きないことを保証

**顧客の声**:
- AI-DLC スターターキット開発者: 「振り返りがファイル/Issue 二重管理から解放されて、cycle ブランチ削除後も全部 Issue で参照できる。LLM 下書きで主因分析が 5 分以内に終わるようになった」
- ダウンストリーム消費プロジェクト開発者: 「初回 wizard でプロダクト Issue 起票を選べるので、振り返り内容がうちのリポの Issue に積まれて backlog 化が自然に進む」

**今後の展開**: v2.6.x 以降では #621（mirror Issue 自動重複統合 workflow / GitHub Models 駆動）と CI 環境向け LLM 自動下書きを段階的に導入予定。本サイクルで完成した「Issue 一本化基盤」が前提となる。

## FAQ（よくある質問）

### Q1: 既存の v2.5.0 環境からアップグレードすると振り返り動作が変わる？

A: 動作変更を伴う `silent → interactive` マッピングは、`aidlc-migrate` 実行時に必ず同意プロンプトが表示されます。拒否すれば `disabled` フォールバックで動作変更を回避できます。`mirror` → `mirror-only` は名前変更のみで動作互換、警告なしです。マイグレーション失敗時は `aidlc-migrate --rollback` で元に戻せます。

### Q2: GitHub CLI が利用できない環境でも振り返りができる？

A: はい。`gh` 不可時は `cycles/{{CYCLE}}/history/retrospective-spool.md` に振り返り内容を **必ずスプール** します（消失禁止）。`history/` 配下のため cycle ブランチ削除後も main に保持されます。次回 `gh` 利用可能時に `scripts/retrospective-resend.sh` で Issue 起票へ再送できます。

### Q3: LLM 下書きが誤判定したら？

A: LLM 出力は必ず人間確認を経由する設計で、確認後の最終結果が LLM 下書きと異なる場合は `[llm-diff]` プレフィックス付きの Issue コメントで差分が記録されます。これは将来の自動分析（誤判定傾向の観察）に使えます。LLM 失敗 / タイムアウト時は手動入力フォールバックです。

### Q4: 前サイクルの振り返りはどうやって参照する？

A: 新サイクル Inception 開始時に `gh issue list --milestone <PREV_CYCLE> --label retrospective` で前サイクル振り返り Issue を自動検索します。1 件ヒット → 自動採用、複数件 → 対話確認、0 件 → spool fallback、`gh` 不可 → spool fallback の判定順で動作します。`predecessor_retrospective.md` 手動配置は不要になります（テンプレ自体が廃止）。

### Q5: CI 環境で意図しない Issue 起票は起きない？

A: 起きません。CI / 非対話環境では wizard が起動できないため、`feedback_mode = "interactive"` 設定や旧 `silent` 残存環境では常に `disabled` フォールバックが選ばれます。これにより CI ワークフローで意図しない Issue 起票が発生しないことを保証します。

### Q6: 主因分類の機械判定は外部 LLM（GitHub Models / Codex）と連携する？

A: v2.5.1 では Claude Code 自身（メインエージェントまたは `retrospective-drafter` subagent）のみが下書き生成を担います。外部 CLI / CI 連携は OUT_OF_SCOPE で、必要に応じて将来サイクル（v2.6.x 以降）で追加予定です。

### Q7: #616 のマージ前 write-history 追加コミット漏れガードは具体的にどこで発火する？

A: 7.12 PR マージ前レビュー反映後に未コミット差分が残った状態でフェーズ完了処理を実行すると exit ≥ 1 を返すガードが発火します。実装 Option（A: review-flow ガード / B: write-history --commit / C: verify-git 必須化 / D: write-history 1 回限定）の選定は Construction Phase で確定しますが、Option 非依存の観測点（exit code, BATS テスト）は必ず満たします。
