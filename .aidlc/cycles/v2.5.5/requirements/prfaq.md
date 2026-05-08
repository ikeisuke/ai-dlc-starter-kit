# PRFAQ: AI-DLC Starter Kit v2.5.5

## Press Release（プレスリリース）

**見出し**: AI-DLC Starter Kit v2.5.5 リリース — Operations / Construction レビュー周辺の運用ノイズを 5 件統合解消

**副見出し**: pr-ops.sh の auto-merge エラー判別精度向上、retrospective-issue.sh の zsh source 互換性復元、Construction 履歴コミット分裂の構造的予防、Operations CI 自動 tag 競合対処、gh pr edit スコープ不足 fallback の 5 件を 1 つの patch リリースに統合し、AI エージェント auto mode の完走率を底上げします

**発表日**: 2026-05-13 想定（v2.5.4 リリースから 1 週間後）

**本文**:

[背景] v2.5.4 リリース後、AI-DLC Starter Kit を採用した複数のプロジェクト（Visitory v1.14.2 / v1.15.0、ai-dlc-starter-kit メタ開発）で Operations / Construction Phase の自動化フロー上で AI エージェントが手動 fallback を強いられる場面が 5 件報告されました。いずれも個別対応は可能ですが、類似シナリオの再発を抑制するには構造的健全化が必要です。

[プロダクト] v2.5.5 では以下 5 つの構造改善を 1 つの patch として統合提供します:

1. **pr-ops.sh の auto-merge エラー判別**: GitHub CLI 実エラー文言（`Auto merge is not allowed` / `enablePullRequestAutoMerge`）に網羅的にマッチするよう grep パターンを拡張し、auto-merge 無効リポジトリ + CI pending 状態でも具体的なエラー種別を返します
2. **retrospective-issue.sh の zsh source 互換性**: v2.5.4 で predecessor-issue.sh のみ救済された shell 判定分岐方式を retrospective-issue.sh にも適用し、AI エージェント実行環境（Claude Code 含む）の互換性を helper 全体に拡張完了します
3. **Construction Unit 完了処理 step5↔step8 の分裂予防**: 文書整合 + commit-flow チェックリスト + write-history.sh 自身の警告経路の三層化により、利用者が手順を取り違えても Unit 完了 commit と履歴 commit が分裂しない構造を作ります
4. **Operations CI 自動 tag 競合対処**: GitHub Actions 等の CI で release tag を自動作成するワークフローを併用するプロジェクト向けに、ローカル `git tag → push` 前のリモート tag 状態確認手順 + 衝突時の判定マトリクス（不在 / 同 SHA / 異 SHA） + fallback 手順を 04-completion.md に追加します
5. **gh pr edit スコープ不足 fallback**: `read:org` / `read:discussion` 等のスコープ不足エラーを検出した際に `gh api -X PATCH` で REST 直叩きする fallback を operations-release.sh pr-ready に組み込み、エンタープライズ環境でも Operations 自動化が完走できるようにします

[顧客の声] 「v2.5.4 と同じパターンで、5 件の運用ノイズが 1 つの patch でまとめて消えるのは助かる。特に CI 自動 tag 競合は手順書がなく毎回判断に時間がかかっていたので、判定マトリクスがあるだけで安心です」（想定 AI エージェント運用者）

[今後の展開] v2.6.0 では「振り返りフローを Operations Phase から分離 / `/aidlc r | retrospective` で独立起動」（#667）を含む、フェーズ構造の見直しを minor リリースとして検討します。本サイクルで確立した「5 件統合解消パターン」は、今後も patch リリースの標準的な進め方として継続適用します。

## FAQ（よくある質問）

### Q1: なぜ 5 件をまとめて 1 つの patch にしたのですか？個別 patch（v2.5.5 / v2.5.6 / ...）にしないのは？

A: v2.5.4 で「5 件の構造的脆弱性を 1 patch で統合解消する」パターンを確立し、リリース運用ノイズ（CHANGELOG / version bump / マージ作業）を最小化できることを実証しました。各 Unit は完全に独立しており並列実装可能なため、統合 patch のリスクは小さく、ユーザーへの提供速度が向上します。

### Q2: write-history.sh の警告追加は破壊的変更にならないのですか？

A: なりません。warning は stdout/stderr に出力するのみで、exit code 0 を維持します（DR-002）。既存の write-history.sh 呼び出しは exit code でしか分岐していないため、warning 出力を読み飛ばす実装は完全に後方互換です。`git diff` 実行失敗時（git リポジトリ外等）も警告スキップで exit 0 維持します。

### Q3: pr-ops.sh の grep パターン拡張で既存マッチが壊れる懸念はないですか？

A: 既存の `auto-merge is not allowed`（ハイフン付き）パターンは引き続きマッチします（拡張のみ）。後方互換テストを Unit 001 の bats テストで明示的に保護します。

### Q4: 振り返りフロー分離（#667）はなぜ v2.5.5 に含めなかったのですか？

A: 振り返りフロー分離は新スキル `/aidlc-retrospective` の追加 + parser 改修を伴う変更で、規模が minor リリース（v2.6.0）に相当します。本サイクルは patch リリース v2.5.5 として 5 件の高優先度バックログ統合に集中し、振り返り分離は後続サイクルで対応します。

### Q5: gh CLI のエラー文言が将来変わったら、Unit 001 / 005 の grep パターンが効かなくなるのではないですか？

A: その懸念は DR-001 で対応しています。各 Unit の bats テストは現行 `gh` 出力を fixture として固定化しており、`gh` バージョン更新でエラー文言が変わった場合に bats が失敗することで早期検知できます。fixture 更新トリガーの運用ルールは Unit 001 / Unit 005 の完了履歴 `history/construction_unit{NN}.md` に明示記録します（Unit 001 / Unit 005 共通の保守方針）。

### Q6: Unit 003 の write-history 警告は write-history.sh 自身が判定するとのことですが、git リポジトリ外で実行されたらどうなりますか？

A: `git diff --cached --name-only` の実行が失敗（exit code 非 0）した場合は警告をスキップし exit code 0 を維持します（DR-002）。これにより、既存の write-history.sh 呼び出し経路（git リポジトリ前提だが万一外部で呼ばれた場合）も後方互換性を保ちます。
