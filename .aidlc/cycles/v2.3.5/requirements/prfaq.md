# PRFAQ: AI-DLC Starter Kit v2.3.5

## Press Release（プレスリリース）

**見出し**: AI-DLC Starter Kit v2.3.5 - Operations Phase の復帰判定・リモート同期・マージフローを堅牢化

**副見出し**: 「マージ前完結」ルールの整合回復、squash 後の divergence 誤検知解消、CIチェック未設定リポジトリでの `merge-pr` バイパスサポート

**発表日**: 2026-04-17

**本文**:

AI-DLC の Operations Phase は本来、PR マージ直前までに全ての履歴記録・判定ソースを完結させる「マージ前完結」設計で動いています。しかし v2.3.4 までは、復帰判定チェックポイントが PR Ready 化・PR マージ**後**に書かれる `history/operations.md` を参照していたため、AI エージェントが「復帰判定のために履歴を記録したほうがよい」と誤判断し、worktree に未コミット変更が残るケースがありました。v2.3.5 では復帰判定の参照先を `operations/progress.md`（7.7 コミット時点の記録）と GitHub の PR 実態確認の AND に移行し、「マージ前完結」ルールと整合させます。

また、Construction Phase で squash を行った後に Operations Phase を開始すると、リモート同期チェックが squash 前の中間コミット数を behind として誤検知し、不要なユーザー選択肢（「取り込む / スキップ」）が表示されていました。v2.3.5 では `git merge-base --is-ancestor` の先行チェックで up-to-date を正確に判定し、divergence は `diverged` ステータスとして `behind` と区別し、`git push --force-with-lease` の案内のみを表示します（自動実行はしません）。

さらに、CIチェックが設定されていないリポジトリでの `operations-release.sh merge-pr` が `checks-status-unknown` で中断する問題に対して、`--skip-checks` オプションを追加しました。このオプションは `checks-status-unknown` 限定でバイパスを許可し、`failed` / `pending` などの状態では従来通り拒否することで安全性を損ないません。

## FAQ（よくある質問）

### Q1: 復帰判定の参照先を progress.md に移行することで、既存サイクルに影響はありますか？

A: ありません。v2.3.4 以前のサイクルの `progress.md` には新しいサブステップフラグが存在しないため、新フラグが不在の場合は従来の `history/operations.md` 参照へフォールバックするロジックを設けます。既存サイクルのファイルには遡及的な変更を加えず、読み取り時の互換性のみ担保します。

### Q2: 「progress.md の予約フラグ」と「GitHub 実態確認の AND」はどういう意味ですか？

A: 7.7 最終コミット時点で `operations/progress.md` に「7.8 Ready 化を行う」「7.13 マージを行う」の予約フラグを書き込みます。復帰判定時にはこのフラグに加え、`gh pr view` で GitHub 側の実態（PR の Ready 状態・マージ済み状態）を確認し、両方が一致したときのみ「完了」と判定します。片方だけなら「予約は立っているが実行は未完」と認識し、再開時に必要なステップから再実行します。

### Q3: GitHub API が利用できない環境（オフライン等）ではどうなりますか？

A: 復帰判定は `phase-recovery-spec.md` §6 の `undecidable:<reason_code>` を返し、`automation_mode=semi_auto` でも自動継続せずユーザー確認フローに遷移します。保守的に「未完」扱いで黙って再実行する挙動は取らず、安全側に倒します。

### Q4: squash 後の push 案内は自動で実行されますか？

A: いいえ。`git push --force-with-lease <remote> <branch>` はあくまで推奨コマンドとして表示するだけで、AIエージェントやスクリプトが自動実行することはありません。ユーザーが明示的にコマンドを実行する設計です。force push は影響が大きい操作のため、ユーザー承認を必須としています。

### Q5: `--skip-checks` は CIチェックを完全に無効化してしまいますか？

A: いいえ。`--skip-checks` は CI 状態が `checks-status-unknown`（`gh pr checks` が `no checks reported` を返すケース）と解釈される場合**のみ**バイパスを許可します。CI が `failed`（失敗）、`pending`（進行中）、その他の既知状態の場合は、`--skip-checks` を指定しても従来通りエラー終了します。安全性を損なう広いバイパスにはなりません。

### Q6: 既存の `operations-release.sh merge-pr` 呼び出しへの影響はありますか？

A: ありません。`--skip-checks` オプションを指定しない既存の呼び出しは、v2.3.4 と完全に同じ挙動で動作します。下位互換を維持しています。

### Q7: Unit 002 と Unit 003 は並行で実装できますか？

A: 論理要件は独立していますが、両 Unit が `scripts/operations-release.sh` を共通で更新するため、並行実装は禁止です。Unit 002 完了後に Unit 003 に着手する順序としています。Unit 004 も Unit 002 の `diverged` ステータス仕様を前提とするため、Unit 002 完了後の着手となります。

### Q8: 本サイクルのスコープに含まれない Operations 改善は何ですか？

A: Construction Phase 復帰判定のステップレベル化（#554）、Inception progress.md の命名統一（#565）、`suggest-permissions` の既知安全な監査指摘抑制（#576）、`write-config.sh` デフォルト書き込み防止（#578）、`config.toml.template` の `ai_author` デフォルト変更（#577）、config.toml 旧キー自動移行（#573）、原始人プロンプト（#568）は、本サイクルのスコープ外としています（別サイクルで対応予定）。
