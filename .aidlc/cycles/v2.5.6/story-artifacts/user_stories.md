# ユーザーストーリー — v2.5.6

## Epic: v2.5.5 リリース時の残務・追記修正の一括処理

v2.5.5 Operations Phase 完了処理のさなかにユーザー指摘・自動監査・運用ノイズの観測から発生した 4 件のギャップを、リリース後の再発を最小化するため次サイクルに繰り越さず本サイクルで埋め込む。各ストーリーは互いに独立、Construction Phase で並列処理可能。

---

### ストーリー 1: cycle/* PR で 3 Phase 完了を CI で強制したい（A）

**優先順位**: Must-have（関連 Issue: #672 priority:high）

As a AI-DLC Starter Kit のメンテナ・利用者
I want to cycle/* ブランチの PR について、Inception/Construction/Operations 3 Phase の完了状態を CI レベルで自動検証してマージブロックしたい
So that 不完全状態のサイクルが main に取り込まれる事故（progress.md 固定スロット未確定 / Unit 未完 / 履歴欠損）を構造的に防げる

**受け入れ基準** (実装完了条件 A-1 と 運用完了条件 A-2 を明確に分離):

**[A-1 実装完了条件] チェックスクリプト + CI**:
- [ ] `bin/check-cycle-phase-completion.sh <cycle>` が CLI として提供され、`--help` で使用方法と検証ロジックが説明される
- [ ] 同スクリプトは Inception/Construction/Operations 3 Phase それぞれの完了状態を以下の基準で検証する:
  - Inception: `.aidlc/cycles/{cycle}/inception/progress.md` の全ステップが「完了」または「スキップ」
  - Construction: `.aidlc/cycles/{cycle}/story-artifacts/units/*.md` 全ファイルの「実装状態」が「完了」または「取り下げ」
  - Operations: `.aidlc/cycles/{cycle}/operations/progress.md` のステップ7が「完了」かつ固定スロット 3 つ（`release_gate_ready=true` / `completion_gate_ready=true` / `pr_number=<対象 PR 番号>`）
- [ ] **`pr_number` 検証方法**: CI 実行時、`progress.md` の `pr_number` 値が `${{ github.event.pull_request.number }}`（または `gh api repos/:owner/:repo/pulls/:number` で取得した PR 番号）と数値一致することを確認。bats テストでは固定値の擬似 progress.md と擬似 PR 番号の対比で検証する
- [ ] CI 失敗時のエラーメッセージは「どの phase / どのファイル / どの欠損か」を特定できる（`error:phase=<phase>:file=<path>:reason=<code>` 形式を推奨）
- [ ] `.github/workflows/cycle-phase-completion-check.yml`（または既存 workflow への job 追加）で `pull_request` イベント時、`startsWith(github.head_ref, 'cycle/')` の場合のみ実行
- [ ] cycle/* 以外のブランチ（chore/* / fix/* 等）には適用されない（明示的除外）
- [ ] ローカル dry-run コマンド（CI 実行前にメンテナが事前確認できる）
- [ ] bats テストで「completion / Inception 未完 / Construction 未完 / Operations 固定スロット欠損 / pr_number 不一致」の各ケースを検証

**[A-2 運用完了条件] Repository Ruleset 適用**:
- [ ] Repository Ruleset（または Branch protection）で当該 CI チェックを必須化する手順が `docs/` 配下に doc 化される（`gh api` REST/GraphQL スクリプト化または UI 操作手順の両論併記）
- [ ] 通常完了経路: 上記手順に沿って必須化が適用済みであること。適用証跡（設定 JSON または UI スクリーンショット）を `docs/` または PR description に残す
- [ ] 暫定完了経路（管理者適用未完了の場合）: Operations Phase 完了直前に AskUserQuestion で「暫定完了承認」を得る + follow-up Issue 起票 + 適用予定マイルストーン（v2.5.7 等）明記。本経路適用時は本サイクル DoD 上は A-1 達成のみで A 達成とみなす（Intent 成功基準 A 参照）

**技術的考慮事項**:
- 既存 workflow（pr-check.yml 等）と並列、コンフリクトなし
- Inception/Construction/Operations の完了判定ロジックは既存 progress.md / units/ パース helper を再利用候補（重複ロジック生成を避ける）
- Construction Phase 設計時に「ローカル dry-run と CI 実行の挙動分岐の有無」を判断する（Intent 内 Question として残置）

---

### ストーリー 2: main-repo-health-check の fixture 誤検出をなくしたい（B）

**優先順位**: Must-have（関連 Issue: #670 bug）

As a AI-DLC Starter Kit を `aidlc-setup` / Operations Phase で使う開発者
I want to サイクル開始時の health-check で `conflict-marker` warning が fixture/docs 引用に対しては発生せず、本物の未解決コンフリクトのみが検出されるようにしたい
So that 毎サイクル開始時に「これは fixture です」と AskUserQuestion 回答する運用ノイズが消え、real な warning に集中できる

**受け入れ基準**:

- [ ] `scripts/main-repo-health-check.sh` の `check_conflict_marker()` 関数が `git grep` 実行時に以下を pathspec で除外する:
  - `tests/main-repo-health-check.bats`（BATS テスト fixture は意図的に conflict marker を含む）
  - `.aidlc/cycles/**/design-artifacts/**`（過去サイクルの設計ドキュメント引用）
- [ ] クリーンな main worktree で `scripts/main-repo-health-check.sh` 実行時に `health-check:conflict-marker:ok:count=0` が返る
- [ ] `tests/main-repo-health-check.bats` に以下 2 種の受け入れテストが追加される:
  - **除外サンプル検証**: 除外対象パスに conflict marker を含むファイルがあっても warning にならないことを確認
  - **実コンフリクト検出維持**: 除外対象外のテンポラリパスに conflict marker を作成すると warning として検出されることを確認
- [ ] **主基準**: `tests/main-repo-health-check.bats` の関連テストスイート（health-check 関連 BATS）が全件 pass する
- [ ] **補助基準**: 影響範囲外のテストスイートに新規退行が生じていないこと（PR CI 全体 green）。本基準は本ストーリー価値の主成果ではなく、間接的な退行防止確認として扱う

**技術的考慮事項**:
- 単一関数 + 単一 git grep コマンドの修正、影響範囲は最小
- 除外パターンは `':(exclude)tests/main-repo-health-check.bats' ':(exclude).aidlc/cycles/**/design-artifacts/**'` を想定
- BATS テストの heredoc 連結 escape 案は採用しない（テスト可読性優先で pathspec 除外を採用）

---

### ストーリー 3: permissions audit 9 件の検出を解消したい（C）

**優先順位**: Must-have（関連 Issue: #671）

As a AI-DLC Starter Kit のメンテナ
I want to `/tools:suggest-permissions --review all` で v2.5.5 リリース前から継続検出されている 9 件（1 CRITICAL / 1 HIGH / 7 MED）を、リリースごとに監査ノイズを再確認しなくて済む状態にしたい
So that 各サイクルのリリース時のパーミッション監査が「合格」もしくは「対処済み」で短時間に完了し、新規の真の脅威にフォーカスできる

**受け入れ基準** (リポジトリ成果物と環境適用を分離):

**[主成果物] リポジトリ管理下の設定テンプレート + 手順書**:
- [ ] `.claude/settings.json` の `suggestPermissions.acknowledgedFindings` に以下 7 件を登録（各エントリに `pattern` / `severity` / `note` / `acknowledgedAt` を必ず含む）:
  - `Bash(bash -n *)` (CRITICAL): 構文チェック専用
  - `Bash(rm /tmp/aidlc-*)` (HIGH): /tmp/aidlc- プレフィックス限定
  - `Bash(gh issue list *)` / `Bash(gh issue view *)` / `Bash(gh pr view *)` (MED): read-only サブコマンド
  - `Bash(git tag *)` / `Bash(git push *)` (MED): -d / --force ガード追加後の残余
- [ ] **対処証跡**: PR description または `docs/permissions-audit-v2.5.6.md` に以下を表形式で記録:

  | pattern | severity | 対処方法 (`ask` 追加 / `acknowledged` 登録) | 設定ファイル | note 内容 |
  |---------|----------|-----------------------------------------|-------------|----------|

- [ ] `~/.claude/settings.json`（user-global）の `permissions.ask` 配列追加候補を `docs/permissions-audit-v2.5.6.md`（または同等の手順書）に明記:
  - `Bash(git push --force *)`
  - `Bash(git push --force-with-lease *)`
  - `Bash(git tag -d *)`
- [ ] 手順書には「適用前に `/tools:suggest-permissions --review all` を実行 → 適用 → 再実行 → before/after の出力ログを保存」の確認手順を含める

**[環境適用 + 確認記録] ユーザーグローバル設定の適用**:
- [ ] `~/.claude/settings.json` への ask 追加適用は、ユーザー（管理者）の明示的承認を経て実施。AskUserQuestion で「適用 / 手順のみ受領 / 中止」の選択を提示
- [ ] 適用後、`/tools:suggest-permissions --review all` 再実行ログを保存（PR description または `docs/permissions-audit-v2.5.6.md` に before/after の対比を残す）
- [ ] 適用結果が以下を満たす:
  - HIGH と CRITICAL は 0 件（必須）
  - Issue #671 検出 7 件 (MED) すべてに対して ask 追加または acknowledgedFindings 登録のいずれかが施されている
  - LOW は本サイクル対象外

**技術的考慮事項**:
- `~/.claude/settings.json` はユーザーの個人環境にも影響するため、書き換え前に明示的に確認を取る
- `acknowledgedFindings` は検出を抑制せず note 付きで残す仕様（再実行時に MED として検出されること自体は許容）
- ask 追加と acknowledgedFindings 登録の使い分け: 危険な拡張サブコマンドは ask、ワイルドカードオーバーマッチの誤検出は acknowledgedFindings

---

### ストーリー 4: Inception の Issue 選択で複数選択を前提としたい（D）

**優先順位**: Must-have（関連 Issue: 本サイクル内で起票予定。Construction Phase 開始前に必達）

As a AI-DLC Starter Kit を Inception Phase から使う開発者
I want to `/aidlc inception` 開始時の Issue 選択フローで、AI エージェントが複数 Issue を 1 サイクルに含める提案を自然に行うようにしたい
So that 1 サイクルに複数の小〜中規模 Issue を取り込みたい場合に、毎回手動で「複数選びたい」と AI を誘導しなくて済む（現状は単一選択を誘導されることが多い）

**受け入れ基準**:

**受け入れ基準** (必須基準と補助基準を分離):

**[必須基準] §16 文言修正の存在**:
- [ ] `steps/inception/02-preparation.md` §16「GitHub Issue確認」内に以下が**両方**存在する:
  - 「複数選択可」を明示する文言（例: 「対応する Issue を**複数選択可で**選択させ」）
  - AskUserQuestion 呼び出し例または推奨パターン（`multiSelect: true` の利用例を含む 1 ブロック以上）
- [ ] 文言修正は §16 周辺の局所修正にとどめ、他の AskUserQuestion 呼び出し全般には言及しない（Intent 明示除外を遵守）
- [ ] D 対応の GitHub Issue が起票され、Construction Phase 開始までに採番済み（Inception 完了条件）

**[補助基準] 観測条件**（任意、定量化が可能なら追跡）:
- [ ] AI エージェントが §16 に従った場合、AskUserQuestion を multiSelect: true で構成する確率が向上することを、手動 review または以降のサイクル運用で観測する。本観測は本サイクル DoD には含まれず、後続サイクルの振り返り材料として扱う

**技術的考慮事項**:
- 単純な Markdown 文言修正、影響範囲は §16 のみ
- AI エージェントの解釈バイアスを完全に排除することは不可能（LLM の特性）。文言の明示化と推奨例の掲載でバイアスを軽減することが目的
- 既存の `scripts/check-open-issues.sh` の出力フォーマットは変更不要（表示テキストのみ調整）
