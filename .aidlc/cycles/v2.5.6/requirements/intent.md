# Intent（開発意図） — v2.5.6

## プロジェクト名

ai-dlc-starter-kit / cycle v2.5.6

## 開発の目的

v2.5.5 リリース時に浮上した残務・追記修正を patch サイクルとしてまとめて処理する。

v2.5.5 Operations Phase 完了処理のさなかにユーザー指摘・自動監査・運用ノイズの観測から発生した 4 件のギャップを、リリース後の再発を最小化するため次サイクルに繰り越さず本サイクルで埋め込む。

## ターゲットユーザー

- AI-DLC Starter Kit 自身の開発者（メタ開発）
- AI-DLC を依存として取り込むダウンストリーム消費プロジェクトの利用者（CI ガード・パーミッション衛生の波及）

## ビジネス価値

- **構造的健全性ガードの強化**: cycle/* PR で 3 Phase 完了が CI レベルで強制されることで、不完全状態のサイクルが main に取り込まれる事故を防止
- **パーミッション衛生**: `/tools:suggest-permissions --review all` の継続検出 9 件を解消し、リリースごとの監査ノイズを削減
- **運用ノイズ削減**: main-repo-health-check の fixture 誤検出 12 件を消し、サイクル開始時の AskUserQuestion 確認回数を削減
- **対話 UX の改善**: Inception での Issue 選択フローが「複数選択を前提とする」よう明示化し、現状の単一選択誘導パターンを是正

## 成功基準

- **A** (Must): サイクル完了判定は以下「通常完了条件」を **デフォルト** として用いる
  - **通常完了条件（デフォルト）**: A-1 と A-2 の **両方** を満たす
    - **A-1: コード/CI 実装完了**: cycle/* ブランチの PR で `bin/check-cycle-phase-completion.sh` が CI で実行され、Inception/Construction/Operations 3 Phase の完了状態を検証する。ローカル dry-run スクリプトとヘルプが提供される
    - **A-2: GitHub 管理設定適用完了**: Repository Ruleset（または Branch protection）で当該 CI チェックが必須化される。`gh api` でスクリプト化できる場合は CI/手順に組み込み、UI 手動作業のみ可能な場合は手順 doc + 適用証跡（スクリーンショットまたは設定 JSON）を残す
  - **暫定完了条件（例外）**: A-2 が UI 手動作業のみで本サイクル中に管理者適用未完了となる場合に **限り**、ユーザー（リポジトリ管理者）が明示的に「暫定承認」した場合のみ適用可能。要件は次の 3 点すべて
    1. A-1 達成済み
    2. A-2 用の follow-up Issue を起票し、適用予定マイルストーン（v2.5.7 等）を明記
    3. ユーザーが Operations Phase 完了直前に AskUserQuestion 経由で「暫定完了承認」を選択
  - 上記いずれかの条件を満たせば A 達成とみなす。デフォルトは通常完了条件、暫定完了条件は明示承認時のみ
- **B** (Must): 次の 3 点を満たす
  - クリーンな main worktree で `scripts/main-repo-health-check.sh` 実行時に `conflict-marker:ok:count=0` が返る
  - 受け入れテストで **除外対象のサンプルパス**（例: `tests/main-repo-health-check.bats`、`.aidlc/cycles/**/design-artifacts/**` のサンプル fixture）を含むケースが除外されることを確認
  - 受け入れテストで **除外されない実コンフリクト例**（テスト用 fixture を tracked ファイル外に作る等）が引き続き warning として検出されることを確認
- **C** (Must): `/tools:suggest-permissions --review all` 再実行時、Issue #671 で検出された 9 件すべてが ask 追加または acknowledgedFindings 登録（note 必須）で「対処済み」となっていること。具体的判定基準:
  - **HIGH と CRITICAL は 0 件**: 検出されてはならない（acknowledgedFindings 登録による抑制も不可、必ず ask 追加で対処）
  - **MED は対処済み件数で判定**: Issue #671 検出 7 件すべてに対して ask 追加または note 付き acknowledgedFindings 登録のいずれかが施されていること。再実行時に MED として残ること自体は許容（acknowledgedFindings はそもそも検出を抑制せず note 付きで残す仕様のため）
  - **LOW は本サイクルの対処対象外**（件数制約なし、新規発生も問題視しない）
- **D** (Must): `steps/inception/02-preparation.md` §16 の Issue 選択フローで「複数 Issue を取り込む前提」が明示され、AI エージェントが一律に単一 Issue 選択を誘導しないよう指示が整備される。**D の対象 GitHub Issue が Construction Phase 開始までに採番済みであること**（Inception 完了条件として先行必須）

## 優先度・規模・未達時持ち越し条件

| ID | 優先度 | 規模感 | 未達時の持ち越し条件 |
|----|--------|--------|------------------|
| A | Must | 中（CI workflow 新設 + check スクリプト + doc + Ruleset 設定） | A-1 / A-2 のいずれかが未達なら次サイクル v2.5.7 へ Issue として繰り越し（A-2 のみ未達は本 Intent §A 末尾の暫定措置に従う） |
| B | Must | 小（pathspec 追加 + テスト追記） | 未達なら v2.5.7 へ Issue 繰り越し |
| C | Must | 小〜中（settings.json 編集 + 設定文書化） | HIGH/CRITICAL 1 件でも残れば未達扱い、v2.5.7 へ Issue 繰り越し |
| D | Must | 小（02-preparation.md §16 文言修正 + 対象 Issue 起票） | 文言修正未達なら v2.5.7 へ繰り越し、Issue 起票だけ Construction 開始前に必達 |

依存関係なし（ユーザー方針: 「やりやすい順で良い」）。Construction Phase の Unit 順序は計画フェーズで決定する。

## 期限とマイルストーン

- 本サイクルは v2.5.5 直後の patch リリース（v2.5.6）として 1 サイクルで完結
- 中間スプリントなし、Inception → Construction → Operations を順次実施
- リリース時に CHANGELOG / README / version.txt を更新（rules.md「カスタムワークフロー」に従う）

## 制約事項

- メタ開発リポジトリ（AI-DLC スターターキット自身）の dev worktree (`.worktree/dev`) で作業
- ブランチ: `cycle/v2.5.6`（先ほど作成済み、HEAD: 9ab4572f アップグレード commit を含む）
- automation_mode: `semi_auto`、review_mode: `required`、review_tools: `['codex']`
- depth_level: `standard`、unit_branch_enabled: `false`、merge_method: `merge`
- `bin/check-bash-substitution.sh` ガードに従い、コマンド置換（コード置換）の使用禁止
- starter_kit 自身を編集するため、スキル内リソースは `skills/aidlc/**` プロジェクトルート相対で編集（META-001 例外）

## 含まれるもの

| ID | 概要 | 関連 Issue |
|----|------|----------|
| A | cycle/* ブランチで 3 Phase 完了強制する CI ガード追加 + Repository Ruleset（または Branch protection）の追加・手順 doc 化（手動 UI 作業を含む可能性あり）+ ローカル実行スクリプト・ヘルプ | #672 |
| B | `scripts/main-repo-health-check.sh` の `check_conflict_marker` から tests/docs fixture を pathspec で除外 | #670 |
| C | permissions audit 9 件の解消（settings.json の ask 追加 + acknowledgedFindings 登録） | #671 |
| D | `steps/inception/02-preparation.md` §16 の Issue 選択フローで「複数選択前提」を明確化 | #674 |

## 明示的に除外するもの

- `AskUserQuestion` API そのものの設計見直し（D は Issue 選択フローのみが対象）
- 全スキル全面監査（D は §16 周辺の局所修正のみ）
- cycle/* 以外のブランチパターン（chore/* / fix/* 等）への CI ガード拡張（A は cycle/* 限定）
- D の対象を「他の AskUserQuestion 呼び出し全般」に広げること（範囲は Intent / Issue 選択時に限定）

## 不明点と質問（Inception Phase中に記録）

[Question] D の Issue 起票は本サイクル内で行うか、Construction Phase 開始までに行うか
[Answer] **Construction Phase 開始までに必達**（成功基準 D に組み込み済み、Inception 完了条件として扱う）

[Question] A の `bin/check-cycle-phase-completion.sh` がローカル dry-run と CI 実行で同一スクリプトを共有する設計で問題ないか（ローカル/CI で挙動分岐が必要かどうか）
[Answer] （Construction Phase の設計時に確認）

[Question] A の Repository Ruleset 追加は GitHub UI 経由の手動作業として Operations Phase で「ユーザー依頼ステップ」を組み込む形が良いか、それとも `gh api` (REST/GraphQL) でスクリプト化できるか
[Answer] （Construction Phase の設計時に確認）
