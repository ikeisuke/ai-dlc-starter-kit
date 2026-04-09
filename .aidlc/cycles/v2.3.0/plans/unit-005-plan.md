# Unit 005 計画: Tier 2 施策の統合（operations-release スクリプト化 + review-flow 簡略化）

## 目的

#519 Tier 2 施策のうち 2 つを統合適用する純粋なリファクタリングを実施し、コンテキスト圧縮の最終段を完成させる。

1. **operations-release.md のスクリプト化**: Operations Phase のリリース準備手順を `scripts/operations-release.sh` に集約し、markdown 本体のサイズを 50% 以上削減する
2. **review-flow.md 判定ロジック簡略化**: AI レビューのルーティング（CallerContext マッピング / 処理パス / 遷移判定）を `steps/common/review-routing.md` に抽出し、`review-flow.md` 本体は手順記述に特化させる

## 背景

- Intent で Tier 2/3 完遂がスコープ内として必達化されている（案 D: インデックス集約。Unit 001-004 で Tier 3 のインデックス化は完遂済み）
- 本 Unit は Unit 001-004 で確立した「インデックス + 詳細の分離構造」および「参照集約パターン」を、既存の肥大化した 2 つのファイル（`operations-release.md` / `review-flow.md`）にも適用する
- **operations-release.md**（2,877 tok / 212 行）は現状、宣言的な手順記述＋多数の bash コード塊からなる。shell で完全自動化可能な工程を `operations-release.sh` に移管することで、markdown 側は意思決定が必要な箇所＋スクリプト呼び出しの参照のみに縮約できる
- **review-flow.md**（3,989 tok / 215 行）は現状、ルーティング判定（設定テーブル / CallerContext マッピング / 処理パス分岐 / 遷移判定）と、反復レビューの手順（指摘対応判断フロー / スコープ保護 / OUT_OF_SCOPE バックログ登録 / レビューサマリ / 履歴記録 / AI レビュー却下禁止 / 外部入力検証）が混在している。ルーティング部分だけを別ファイルに切り出すことで、各フェーズインデックスからは「ルーティング」のみをロードし、「手順」の本体は必要時のみロードする形に切り替えられる

## スコープ

### 含むもの

#### operations-release.md のスクリプト化（ストーリー 6）

- **`skills/aidlc/scripts/operations-release.sh` を新規作成**: 既存 `operations-release.md` の 7.1〜7.13 のうち「純粋にシェルで置換可能な機能群」をサブコマンドとして実装する
  - **サブコマンドと節の対応ポリシー**: **節単位の 1:1 対応ではなく「機能群単位のラッパー」とする**。既存節を機能群に集約してから 1 サブコマンドに対応させる（例: `verify-git` = 7.9 + 7.10 + 7.11 の事前チェック群）。どの節がどのサブコマンドに含まれ、どの節が markdown に残るかは対象ファイル表（#1-#2）および下記「markdown に残す節（スクリプト化対象外）」で固定する
  - **markdown に残す節（スクリプト化対象外）**: 人間判断またはファイル編集を含む以下の節は `operations-release.md` 本体に残し、`operations-release.sh` には含めない
    - 7.2 CHANGELOG 更新（コンテンツ作成が人間判断）
    - 7.3 README 更新（コンテンツ作成が人間判断）
    - 7.4 履歴記録（既存 `/write-history` スキル呼び出しに統一済みで、追加のラップは不要）
    - 7.6 progress.md 更新（インメモリのファイル編集であり、対象ファイルパス・編集内容の意思決定は markdown 手順側に属する）
    - 7.7 Git コミット（コミットメッセージの生成が `commit-flow.md` の責務であり、本 Unit のスコープ外）
    - 7.12 PR マージ前レビュー（`codex review` や `reviewing-operations-premerge` スキル呼び出しを含む対話的フロー）
  - 各サブコマンドは**既存の個別スクリプト**（`suggest-version.sh` / `ios-build-check.sh` / `run-markdownlint.sh` / `pr-ops.sh` / `validate-git.sh` 等）を**直接 orchestration で呼び出す**薄いラッパーとして実装する（既存スクリプトの置換・再実装は行わない）
  - `--dry-run` モードをサポートし、実際の `gh` 呼び出しや `git` 変更を行わずに引数のみを出力する（動作等価性検証に使用）
  - **透過契約**: 既存スクリプト（`validate-git.sh` / `run-markdownlint.sh` / `pr-ops.sh` 等）の **stdout と終了コードをそのまま透過するパススルーラッパー**として実装する。正規化（0/1/2 への変換等）は行わない。例外的に `pr-ready` の `--body-file` 必須エラーのみ透過ではなく exit 1 を返す
  - **`$()` コマンド置換の扱い**: 既存スクリプト（`pr-ops.sh` 等）と同じスタイルで `$()` を使用してよい。`check-bash-substitution.sh` は `*.md` 内の fenced bash のみを検査対象とするため、`.sh` ファイル内の `$()` は対象外
- **`skills/aidlc/steps/operations/operations-release.md` を簡略化**: サブステップごとに「スクリプト呼び出し + 意思決定が必要な箇所の説明」のみに縮約する
  - CHANGELOG / README のコンテンツ作成指示（人間判断が必要）は本体に残す
  - `merge_method=ask` 時のユーザー選択、`PR マージ前レビュー` の判断フロー等の対話的要素も本体に残す
  - 純粋な bash コマンド塊（`gh` / `git` / 既存スクリプト呼び出し）は `operations-release.sh` 呼び出しに置き換える
- **`skills/aidlc/steps/operations/index.md` を更新**: §1 目次・概要テーブルの `operations.02-deploy` 行の説明文に `operations-release.sh` を呼び出す旨の注記を追加する（サブステップ構成表の新設・編集は行わない）
- **`skills/aidlc/steps/operations/02-deploy.md` の参照を更新**: 「各サブステップの詳細手順は `steps/operations/operations-release.md` を参照」を「`steps/operations/operations-release.md` および `scripts/operations-release.sh` を参照」に変更
- **サイズ削減検証**: `operations-release.md` が **tiktoken (cl100k_base) で 1,438 tok 以下**（ベースライン 2,877 tok の 50%）になっていることを確認する
- **動作等価性検証**: `--dry-run` モードで以下の 4 シナリオを実行し、旧手順との差分ゼロを確認する
  - シナリオ A: `gh pr create --base main --title "{{CYCLE}}" --body-file <path>` 引数（Inception で作成済みドラフト PR が存在しない場合の新規 PR 作成パス、現行 `operations-release.md` §7.8「ドラフトPRが見つからない場合」と完全一致）
  - シナリオ B: `gh pr edit {PR番号} --body-file` 引数（テンプレート適用）
  - シナリオ C: `gh pr merge` 引数（`merge_method=merge` / `squash` / `rebase` の 3 パターン、`pr-ops.sh merge` 経由）
  - シナリオ D: `validate-git.sh uncommitted` / `remote-sync` の呼び出しと戻り値伝播

#### review-flow.md 判定ロジック簡略化（ストーリー 7）

- **`skills/aidlc/steps/common/review-routing.md` を新規作成**: ルーティング判定を集約する
  - 移管対象セクション: `設定` / `CallerContext マッピング` / `処理パス`（パス 1 / 2 / 3）/ `遷移判定` / `分割ファイル参照` の一部
  - `review-flow.md` 内部の「反復レビュー / エラーフォールバック / 千日手検出」の**判定表**のうち、**CallerContext → スキル名 + focus** の対応テーブル、および **mode × ツール利用可否 → 使用パス** の対応テーブルを本ファイルに集約する
  - 本ファイルは「ルーティング判定のみを持つ薄いテーブル集」であり、手順記述（反復の回し方、コミットのタイミング等）は保持しない
- **`skills/aidlc/steps/common/review-flow.md` を簡略化**: ルーティング判定を `review-routing.md` への参照に置き換える
  - 残存セクション: `指摘対応判断フロー` / `スコープ保護確認` / `OUT_OF_SCOPE バックログ登録` / `判断完了後` / `レビュー完了時の共通処理` / `レビューサマリファイル` / `履歴記録` / `AI レビュー指摘の却下禁止` / `外部入力検証` / `分割ファイル参照`（既存の `review-flow-reference.md` 参照を維持）
  - 冒頭に「ルーティング判定は `steps/common/review-routing.md` を参照すること」の注記を追加
- **各フェーズインデックスの参照更新**: 正しい節番号で更新する
  - `inception/index.md` §**2.9**「AI レビュー分岐」
  - `construction/index.md` §**2.8**「AI レビュー分岐」
  - `operations/index.md` §**2.9**「AI レビュー分岐」
  - 参照を `review-flow.md` から `review-routing.md` に変更する（手順本体が必要な場合は `review-flow.md` も追加ロード）
- **`operations/index.md` の編集範囲限定**: Unit 004 の Materialized Binding 構造（§1 目次 / §3 判定チェックポイント表 / §4 ステップ読み込み契約）を**変更しない**。編集は以下の 2 箇所のみに限定する:
  - §2.9「AI レビュー分岐」: 参照を `review-routing.md` + `review-flow.md` 併記に更新
  - §1 目次・概要テーブルの `operations.02-deploy` 行: 説明文に「`operations-release.sh` を呼び出す」旨の注記追加（新規セクションの追加やサブステップ表の追加は行わない）
- **ステップファイル内の個別参照更新**: **原則として個別更新を行わない**。ルーティング参照の更新はフェーズインデックスで完結させ、ステップファイルの「AI レビュー」セクションは現行の `review-flow.md` 参照を維持する（`review-flow.md` は手順本体の正本として残るため、既存参照は自然に手順本体への参照となる）
  - **例外**: ステップファイル内で `review_mode=disabled` 時のパス 3 直行判定等、**ルーティング判定の結果を明示的に参照している箇所**のみを最小限更新する。具体的には `inception/03-intent.md:42` / `inception/04-stories-units.md:49,93` / `construction/01-setup.md:82` の 4 箇所のみ、「`review_mode=disabled` の場合は `review-routing.md` のパス 3 に直行」に変更する
  - **更新対象外**: `construction/02-design.md:31,33` / `construction/03-implementation.md:12,142` は「`review-flow.md` の手順を確認」「`review-flow.md` に従う」という手順本体への参照であり、ルーティング判定を持ち込まないため変更しない。これにより index 集約原則（分岐は index、手順は step）と両立する
- **サイズ検証**: `review-flow.md` + `review-routing.md` の合計 tok 数が、整理前の `review-flow.md` 単体（3,989 tok）**以下**に収まることを tiktoken で確認する
- **動作等価性検証**: CallerContext 全 9 種を少なくとも 1 回ずつ通し、かつ mode × automation_mode × tools 状態の境界を網羅する検証ケースセットでルーティング判定が整理前後で一致することを**仕様レベルで静的照合**する（下記「動作等価性検証（review-routing.md）」§参照）

### 含まないもの

- **Tier 2 施策の 3 つ目（ステップファイル内 boilerplate 削減）**: Intent で「案 D 化の過程で自動解消扱い」と定義済み。Unit 006 の計測時に達成状況を確認する
- **インデックス構造自体の設計・実装**: Unit 001-004 で完了済み
- **新たな reviewing スキルの追加・既存スキルの内部実装変更**: Intent で除外済み。`reviewing-construction-plan` / `reviewing-inception-intent` 等のスキル呼び出し契約（args 形式、focus）は Unit 005 でも変更しない
- **`review-flow.md` 内の「AI レビュー指摘の却下禁止」「外部入力検証」「スコープ保護確認」等の手順記述**: これらは手順の本体であり、ルーティング判定ではないため `review-flow.md` 本体に残す
- **`operations-release.md` の機能変更**: 純粋なリファクタリング。新機能の追加、既存挙動の変更は一切行わない
- **既存 scripts/pr-ops.sh / validate-git.sh / run-markdownlint.sh 等の内部実装変更**: 本 Unit では呼び出すのみで、これらのスクリプト自体は触らない
- **`phase-recovery-spec.md` / 各フェーズ `index.md` の判定チェックポイント表**: Unit 001-004 で確立した規範仕様・Materialized Binding は変更しない
- **トークン予算の全体再計測**: Unit 006 の責務。Unit 005 では `operations-release.md` + `review-flow.md` + `review-routing.md` の **3 ファイル局所** のサイズ削減のみを検証する

## 設計方針

### operations-release.sh の設計

- **ディスパッチャ方式**: `operations-release.sh <subcommand> [args...]` の形式で、機能群単位のサブコマンドを提供する
- **サブコマンド設計**（機能群単位での集約。節単位の 1:1 対応は採用しない）:

| # | サブコマンド | 対応節（機能群） | 責務 | 呼び出す既存スクリプト | markdown 側に残す責務 |
|---|-------------|----------------|------|---------------------|--------------------|
| 1 | `version-check` | 7.1 | iOS プロジェクト判定 + `ios-build-check.sh` + `suggest-version.sh` の orchestration + 結果表示 | `ios-build-check.sh`, `suggest-version.sh` | バージョン更新の最終承認（ユーザー判断） |
| 2 | `lint` | 7.5 | `run-markdownlint.sh {{CYCLE}}` 呼び出しと戻り値伝播 | `run-markdownlint.sh` | エラー発生時の修正内容 |
| 3 | `pr-ready` | 7.8 | `pr-ops.sh get-related-issues` → `pr-ops.sh find-draft` → `pr-ops.sh ready` → `gh pr edit --body-file` の一連フロー、およびドラフト PR 不在時の `gh pr create --base main --title "{{CYCLE}}" --body-file <path>` 呼び出しを orchestration | `pr-ops.sh` | PR 本文テンプレート（`templates/pr_body_template.md`）の生成・レビューサマリ挿入判断 |
| 4 | `verify-git` | 7.9, 7.10, 7.11 | `validate-git.sh uncommitted` + `validate-git.sh remote-sync` + main ブランチとの差分チェック（`git merge-base --is-ancestor`）の一括実行と結果集約 | `validate-git.sh` | `warning` / `error` に対するユーザー判断（追加コミット、push、merge/rebase 選択） |
| 5 | `merge-pr` | 7.13 | `pr-ops.sh merge {PR番号} [--squash|--rebase]` 呼び出しと戻り値伝播 | `pr-ops.sh` | `merge_method=ask` 時のユーザー選択、エラー種別別の対処案内 |

**節単位との対応一覧**（上記サブコマンド 5 個 + markdown 残存 6 節 = 合計 11 節、現行 13 節からの差分 2 節は 7.12 PR マージ前レビューが対話的でスクリプト化対象外、7.4 履歴記録が `/write-history` スキル呼び出しですでに orchestration 済みのため）:

| 節 | 扱い |
|----|-----|
| 7.1 バージョン確認 | `operations-release.sh version-check` |
| 7.2 CHANGELOG 更新 | markdown 本体に残す（人間判断） |
| 7.3 README 更新 | markdown 本体に残す（人間判断） |
| 7.4 履歴記録 | markdown 本体に残す（`/write-history` スキル呼び出しで既に orchestration 済み） |
| 7.5 Markdownlint 実行 | `operations-release.sh lint` |
| 7.6 progress.md 更新 | markdown 本体に残す（ファイル編集の意思決定） |
| 7.7 Git コミット | markdown 本体に残す（`commit-flow.md` の責務） |
| 7.8 ドラフト PR Ready 化 | `operations-release.sh pr-ready` |
| 7.9 コミット漏れ確認 | `operations-release.sh verify-git`（7.9-7.11 を集約） |
| 7.10 リモート同期確認 | `operations-release.sh verify-git` |
| 7.11 main ブランチ差分チェック | `operations-release.sh verify-git` |
| 7.12 PR マージ前レビュー | markdown 本体に残す（対話的、`codex review` / reviewing スキル呼び出し） |
| 7.13 PR マージ | `operations-release.sh merge-pr` |

- **`--dry-run` モード**: 全サブコマンドで `--dry-run` をサポート。実際の副作用（`gh` 呼び出し、`git push`、`git merge` 等）を抑止し、呼び出される引数だけを `stdout` に出力する
- **実装スタイル**: 本 script は fixture 生成ではなく既存コマンドの orchestration なので、`verify-*-recovery.sh` のような FIXTURE_CONTENT パターンは使わない。既存スクリプト（`pr-ops.sh` 等）と同じく `$()` コマンド置換を自由に使用してよい（`check-bash-substitution.sh` は `.md` 内 fenced bash のみ検査対象、`.sh` ファイルは対象外）
- **終了コード契約**: **既存スクリプトの終了コードをそのまま透過**する（0/1/2 への正規化は行わない）。`validate-git.sh` は通常 exit 0 + stdout `status:warning`、ハードエラー時 exit 2 + stdout `status:error` を返す現行契約を尊重。`pr-ops.sh merge` は 0=成功 / 1=エラーを透過。例外として `pr-ready` の `--body-file` 必須エラーのみラッパー固有の exit 1 を返す
- **`--help` サポート**: 各サブコマンドと全体のヘルプを表示可能にする（保守性確保）

### review-routing.md の設計

- **位置づけ**: `review-routing.md` は**ルーティング判定専用の正本**であり、呼び出し層（フェーズインデックス / ステップファイル / `review-flow.md`）に対して**構造化された判定結果**を提供する純粋な参照ファイルとする。手順記述（反復方法、コミットタイミング、セッション管理等）は持たない
- **論理インターフェース契約**（`review-flow.md` への出力契約）:

```text
input (ReviewRoutingInput):
  caller_context: { 計画承認前 | 設計レビュー | コード生成後 | 統合とレビュー
                    | Intent承認前 | ストーリー承認前 | Unit定義承認前
                    | デプロイ計画承認前 | PRマージ前 }
  review_mode: { required | recommend | disabled }
  automation_mode: { manual | semi_auto }
  configured_tools: string[]                     # [rules.reviewing].tools 優先順位リスト（空配列可）
  available_tools: string[]                      # command -v で検出された使用可能 CLI の集合
  tools_runtime_status: { ok | cli_runtime_error | cli_output_parse_error }
                                                 # 実行時エラーのみ。cli_missing は tool_name=none で表現

output (ReviewRoutingDecision):
  selected_path: { 1 | 2 | 3 }               # 1=外部CLI, 2=セルフレビュー, 3=ユーザーレビュー
  skill_name: string                           # 例: reviewing-construction-plan
  focus: string[]                              # 例: [architecture] / [code, security]
  tool_name: string | none                     # 使用する CLI 名（パス 2/3 時は none）
  fallback_policy: {
    on_cli_missing: { fallback_to_self | prompt_user_choice },
    on_runtime_error: { retry_1_then_prompt | retry_1_then_user_choice },
    on_parse_error: { fallback_to_self | prompt_user_choice }
  }
  skip_reason_required: bool                   # required mode でユーザー承認に落ちる場合 true
  user_rejection_allowed: bool                 # recommend で semi_auto 時は false
```

- `review-routing.md` は上記 input → output の**判定テーブル**のみを記述し、呼び出し層は `ReviewRoutingDecision` を消費する
- `review-flow.md` は**実行意味論の正本**として、`ReviewRoutingDecision` を受け取った後の反復レビュー手順・指摘対応判断フロー・履歴記録等を記述する。ルーティング判定ロジック自体は持たず、すべて `review-routing.md` に委譲する
- **依存方向の一方向化**: 依存は `review-flow.md → review-routing.md`（flow が routing を参照する）の一方向のみ。`review-routing.md` は `review-flow.md` を参照しない。これにより循環依存を回避し、将来変更時にルーティング拡張（新 CallerContext 追加等）が `review-routing.md` 内で閉じる
- **章構成**:
  1. 概要（本ファイルの位置づけ、`review-flow.md` との分担、論理インターフェース契約 `ReviewRoutingDecision` の定義）
  2. 設定（`[rules.reviewing]` から取得する `mode` / `tools` / `exclude_patterns` のテーブル、既存 `review-flow.md` の §設定 を移管）
  3. CallerContext マッピング（9 呼び出し元 × スキル名 × focus のテーブル、既存 §CallerContext マッピング を移管）
  4. 処理パス決定（`mode` × ツール利用可否 × `automation_mode` → パス 1 / 2 / 3 + `user_rejection_allowed` の対応テーブル、既存 §処理パス / §遷移判定 を移管）
  5. エラーフォールバック対応表（CLI 不在 / CLI 実行エラー / 出力解析不能 の 3 系統 × `mode=recommend` / `mode=required` の対応テーブル、既存 §パス 1 のエラー時フォールバック を移管）
  6. 呼び出し形式（`skill=...`, `args="..."` の契約、現行記述を移管）
- **サイズ目標**: 1,200 tok 程度（`review-flow.md` から 1,500 tok 程度の削減、合計で整理前以下を維持）
- **Materialized Binding 風の構造は採用しない**: Unit 001-004 の「規範 spec + binding」パターンとは異なる、ルーティング判定専用の純粋テーブル集として実装する。ただし「依存方向は一方向、判定は本ファイル集約 / 手順は `review-flow.md` に分離」の原則は共通

### review-flow.md 簡略化の設計

- **残存セクション**（整理前から引き継ぐ手順記述のみ）:
  - 冒頭: 「ルーティング判定は `review-routing.md` を参照」の注記
  - `指摘対応判断フロー`（千日手検出 / 各指摘への判断 / 理由バリデーション）
  - `スコープ保護確認`（OUT_OF_SCOPE 選択時）
  - `OUT_OF_SCOPE バックログ登録`
  - `判断完了後`
  - `レビュー完了時の共通処理`
  - `レビューサマリファイル`
  - `履歴記録`
  - `AI レビュー指摘の却下禁止`
  - `外部入力検証`
  - `分割ファイル参照`（`review-flow-reference.md` への既存参照）
- **削除セクション**（`review-routing.md` に移管）:
  - `設定`
  - `CallerContext マッピング`
  - `処理パス`（パス 1 / 2 / 3 の説明本体、および遷移判定）
  - `パス 1 のエラー時フォールバック表`
- **サイズ目標**: 2,200 tok 程度（`review-flow.md` 単体で 45% 程度の削減）

### 参照更新の設計

- **各フェーズインデックスの「AI レビュー分岐」更新**（節番号は各 index の現行構造に従う）:
  - `inception/index.md` §**2.9**
  - `construction/index.md` §**2.8**
  - `operations/index.md` §**2.9**
  - 更新内容（3 ファイル共通テンプレート）:

```markdown
### 2.X AI レビュー分岐

各承認ポイントで AI レビューを実施する。**ルーティング判定（スキル名・focus・処理パス選択）は `steps/common/review-routing.md` を参照**、**反復・指摘対応・完了処理の手順は `steps/common/review-flow.md` を参照**する。`review_mode=disabled` 時は `review-routing.md` のパス 3（ユーザーレビュー）へ直行。
```

- **ステップファイル内の個別参照更新（最小限、4 箇所のみ）**: 「AI レビュー」セクションで `review_mode=disabled` 時のパス参照を持つ 4 箇所（`inception/03-intent.md:42` / `inception/04-stories-units.md:49,93` / `construction/01-setup.md:82`）のみ、以下の形式に更新する。`construction/02-design.md` / `construction/03-implementation.md` は手順本体参照（`review-flow.md` を手順として読む）であり、ルーティング判定を持ち込まないため**変更しない**:

```markdown
**AI レビュー**: `steps/common/review-flow.md` に従って実施（ルーティング判定の詳細は `steps/common/review-routing.md` 参照）。`review_mode=disabled` の場合は `review-routing.md` のパス 3（ユーザーレビュー）に直行。
```

### 削減見込み

| ファイル | 整理前 | 整理後（想定） | 差分 |
|---------|-------|-------------|------|
| `operations-release.md` | 2,877 tok | ≈ 1,400 tok | **-1,477 tok（-51%）** |
| `review-flow.md` | 3,989 tok | ≈ 2,200 tok | -1,789 tok（-45%） |
| `review-routing.md`（新設） | - | ≈ 1,200 tok | +1,200 tok |
| **review-flow.md + review-routing.md 合計** | 3,989 tok | ≈ 3,400 tok | **-589 tok（合計でも整理前以下）** |
| `operations-release.sh`（新設） | - | シェルスクリプト（tok 計測対象外） | - |

- **operations-release.md**: 50% 以上の削減を厳守（完了条件）
- **review-flow.md + review-routing.md 合計**: 整理前以下を厳守（完了条件）
- **初回ロード全体**: Unit 006 で再計測するため本 Unit では局所サイズのみ検証

## 対象ファイル

| # | ファイル | 操作 | 主な変更内容 |
|---|---------|------|-------------|
| 1 | `skills/aidlc/scripts/operations-release.sh` | **新規** | 5 サブコマンド（`version-check` / `lint` / `pr-ready` / `verify-git` / `merge-pr`）を持つディスパッチャ。`--dry-run` サポート、**透過契約**（既存スクリプトの stdout と終了コードをそのまま透過）、既存 `suggest-version.sh` / `ios-build-check.sh` / `run-markdownlint.sh` / `pr-ops.sh` / `validate-git.sh` を orchestration。`.sh` ファイル内の `$()` は既存スクリプトと同じく使用可 |
| 2 | `skills/aidlc/steps/operations/operations-release.md` | 更新 | 各サブステップを「`operations-release.sh {subcommand}` 呼び出し + 人間判断が必要な箇所の説明」に縮約。CHANGELOG/README のコンテンツ作成指示、`merge_method=ask` 時のユーザー選択、PR マージ前レビューの対話的部分は本体に残す。サイズ 2,877 → 1,400 tok 以下 |
| 3 | `skills/aidlc/steps/operations/index.md` | 更新 | **編集範囲限定**: (a) §1 目次・概要テーブルの `operations.02-deploy` 行に `operations-release.sh` 呼び出しの注記追加、(b) §2.9「AI レビュー分岐」の参照を `review-routing.md` + `review-flow.md` 併記に変更。§2〜§8 の構造変更、§3 判定チェックポイント表・§4 ステップ読み込み契約の編集は行わない（Unit 004 の Materialized Binding 構造を完全に保持） |
| 4 | `skills/aidlc/steps/operations/02-deploy.md` | 更新 | ステップ 7 のサブステップ参照を「`steps/operations/operations-release.md` および `scripts/operations-release.sh` を参照」に変更 |
| 5 | `skills/aidlc/steps/common/review-routing.md` | **新規** | ルーティング判定集約。6 章構成（概要（`ReviewRoutingDecision` 論理インターフェース契約を含む）/ 設定 / CallerContext マッピング / 処理パス決定 / エラーフォールバック対応表 / 呼び出し形式）。1,200 tok 程度。`review-flow.md` への依存を持たない（一方向依存） |
| 6 | `skills/aidlc/steps/common/review-flow.md` | 更新 | 冒頭に「ルーティング判定は `review-routing.md` 参照」の注記を追加。§設定 / §CallerContext マッピング / §処理パス / §遷移判定 を削除（`review-routing.md` へ移管）。残存セクションは `指摘対応判断フロー` 以降の手順記述のみ。`review-routing.md` の `ReviewRoutingDecision` を消費する立場として記述。サイズ 3,989 → 2,200 tok 以下 |
| 7 | `skills/aidlc/steps/inception/index.md` | 更新 | §**2.9**「AI レビュー分岐」の参照を `review-flow.md` から「ルーティング判定は `review-routing.md` + 手順は `review-flow.md`」に変更 |
| 8 | `skills/aidlc/steps/construction/index.md` | 更新 | §**2.8**「AI レビュー分岐」の参照を同上の形式に変更 |
| 9 | `skills/aidlc/steps/inception/03-intent.md` | 更新 | L42「AI レビュー」セクションの `review_mode=disabled` 時のパス参照を `review-flow.md` から `review-routing.md` に変更（ルーティング判定の結果参照のみ） |
| 10 | `skills/aidlc/steps/inception/04-stories-units.md` | 更新 | L49 / L93 の「AI レビュー」セクションの `review_mode=disabled` 時のパス参照を同上の形式に変更（2 箇所） |
| 11 | `skills/aidlc/steps/construction/01-setup.md` | 更新 | L82「AI レビュー」セクションの `review_mode=disabled` 時のパス参照を同上の形式に変更 |
| 12 | `skills/aidlc/steps/construction/02-design.md` | **更新対象外** | 現行の `review-flow.md` 参照は手順本体への参照であり、ルーティング判定を持ち込まないため変更しない |
| 13 | `skills/aidlc/steps/construction/03-implementation.md` | **更新対象外** | 同上（L12 / L142 ともに手順本体への参照） |

## 設計成果物（Phase 1）

- `.aidlc/cycles/v2.3.0/design-artifacts/domain-models/unit_005_tier2_integration_domain_model.md`
- `.aidlc/cycles/v2.3.0/design-artifacts/logical-designs/unit_005_tier2_integration_logical_design.md`

## 実装記録（Phase 2）

- `.aidlc/cycles/v2.3.0/construction/units/unit_005_tier2_integration_verification.md`

## 検証手順

### 静的検証

1. `operations-release.sh` の全サブコマンドが `--help` を持ち、計画の「節単位との対応一覧」表（5 サブコマンド + markdown 残存 6 節）の機能群境界が実装と完全一致していることを確認（節単位の 1:1 対応ではなく、機能群単位の集約であることに留意）
2. `operations-release.md` 本体に `$(...)` コマンド置換が残存しないこと、かつ shell コマンド塊がサブコマンド呼び出しに置き換わっていることを確認
3. `review-routing.md` の全テーブル（CallerContext マッピング / 処理パス / エラーフォールバック）が `review-flow.md` 整理前と情報等価であることを 1 対 1 の対応表で確認
4. `review-flow.md` 残存セクションに「ルーティング判定に関する記述」が混入していないことを grep で確認（`CallerContext` / `mode == ` / `パス 1` / `パス 2` / `パス 3` の表が残っていないこと）
5. フェーズインデックス 3 箇所（Inception §**2.9** / Construction §**2.8** / Operations §**2.9**）およびステップファイル 4 箇所（`inception/03-intent.md:42` / `inception/04-stories-units.md:49,93` / `construction/01-setup.md:82`）の参照が新形式に更新されていること。`construction/02-design.md` / `construction/03-implementation.md` は変更対象外として維持されていること

### 動作等価性検証（operations-release.sh）

`operations-release.sh` の各サブコマンドを `--dry-run` モードで実行し、旧 `operations-release.md` 手順で呼び出される `gh` / `git` / 既存スクリプトの引数と完全一致することを確認する:

```bash
skills/aidlc/scripts/operations-release.sh version-check --dry-run
skills/aidlc/scripts/operations-release.sh lint --dry-run
skills/aidlc/scripts/operations-release.sh pr-ready --dry-run --pr 123
skills/aidlc/scripts/operations-release.sh verify-git --dry-run
skills/aidlc/scripts/operations-release.sh merge-pr --dry-run --pr 123 --method merge
skills/aidlc/scripts/operations-release.sh merge-pr --dry-run --pr 123 --method squash
skills/aidlc/scripts/operations-release.sh merge-pr --dry-run --pr 123 --method rebase
```

各 `--dry-run` 出力から `gh` / `git` / 既存スクリプト呼び出しを抽出し、旧 `operations-release.md` の記載と比較する（差分ゼロが合格条件）。

### 動作等価性検証（review-routing.md）

**検証の原則**: CallerContext 全 9 種を少なくとも 1 回ずつ通し、かつ mode × automation_mode × tools 状態の境界を網羅する 12 ケースのセットでルーティング判定を `review-routing.md` のテーブルから演繹し、整理前 `review-flow.md` の該当セクションの判定結果と**完全一致**することを静的照合で確認する。

**CallerContext カバレッジ**（9 種すべて）:

| # | CallerContext | 入力条件 | 期待スキル | 期待 focus | 期待 `ReviewRoutingDecision` |
|---|--------------|---------|----------|-----------|-------------------------------|
| 1 | 計画承認前 | `mode=required` / `automation_mode=manual` / codex available | `reviewing-construction-plan` | architecture | path=1, tool=codex, user_rejection_allowed=true（manual + required） |
| 2 | 設計レビュー | `mode=recommend` / `automation_mode=semi_auto` / codex available | `reviewing-construction-design` | architecture | path=1, tool=codex, user_rejection_allowed=false（`semi_auto + recommend` 境界、拒否スキップ） |
| 3 | コード生成後 | `mode=required` / `automation_mode=semi_auto` / codex available | `reviewing-construction-code` | code, security | path=1, tool=codex, skip_reason_required=false, user_rejection_allowed=true（semi_auto でも `required` なら拒否可） |
| 4 | 統合とレビュー | `mode=required` / `automation_mode=manual` / codex available | `reviewing-construction-integration` | code | path=1, tool=codex, user_rejection_allowed=true |
| 5 | Intent 承認前 | `mode=disabled` / `automation_mode=manual` | `reviewing-inception-intent` | inception | path=3 直行（disabled 境界）、user_rejection_allowed=false |
| 6 | ストーリー承認前 | `mode=required` / `automation_mode=semi_auto` / codex available | `reviewing-inception-stories` | inception | path=1, tool=codex, user_rejection_allowed=true |
| 7 | Unit 定義承認前 | `mode=required` / `automation_mode=manual` / codex available | `reviewing-inception-units` | inception | path=1, tool=codex, user_rejection_allowed=true |
| 8 | デプロイ計画承認前 | `mode=recommend` / `automation_mode=manual` / codex available | `reviewing-operations-deploy` | architecture | path=1, tool=codex, user_rejection_allowed=true（`manual + recommend` 境界） |
| 9 | PR マージ前 | `mode=required` / `automation_mode=manual` / codex available | `reviewing-operations-premerge` | code, security | path=1, tool=codex, user_rejection_allowed=true |

**tools 状態の境界ケース**（上記 9 ケースに追加で 3 ケース）:

| # | 入力条件 | 期待 `ReviewRoutingDecision` | 検証目的 |
|---|---------|-------------------------------|---------|
| 10 | 設計レビュー / `mode=recommend` / `configured_tools=[]` | `ToolSelection` → `tool_name=none`、`PathSelection` → `selected_path=2`（セルフレビュー） | `configured_tools=[]` 境界（`ToolSelection` セルフレビュー直行シグナル） |
| 11 | コード生成後 / `mode=required` / `configured_tools=["codex"]` / `available_tools=["codex"]` / `tools_runtime_status=cli_runtime_error` | `PathSelection` → `selected_path=1` + `fallback_policy.on_runtime_error=retry_1_then_user_choice`（CLI 実行エラー時のフォールバック） | runtime_error のフォールバック境界 |
| 12 | 計画承認前 / `mode=required` / `configured_tools=["codex"]` / `available_tools=[]`（どの configured_tools も使えない） | `ToolSelection` → `tool_name=none`、`PathSelection` → `selected_path=2` + `skip_reason_required=true` + `fallback_policy.on_cli_missing=prompt_user_choice` | CLI 不在時の `mode=required` ブロック動作（`ToolSelection` で `tool_name=none` が返り、`PathSelection` が `path=2` + `skip_reason_required=true` を設定） |

**カバレッジ正当化**:

- **CallerContext**: 現行 9 種すべてを 1 回以上網羅
- **mode**: `required` / `recommend` / `disabled` 全 3 種を網羅
- **automation_mode**: `manual` / `semi_auto` 全 2 種を網羅
- **tools 状態**: `configured=available`（通常）/ `configured_tools=[]` / `tools_runtime_status=cli_runtime_error` / `available_tools=[]` の 4 種を網羅
- **focus**: `architecture` / `code` / `security` / `inception` / `code, security` 全 focus 種を網羅
- **境界ケース**: `semi_auto + recommend`（#2）、`manual + recommend`（#8）、`mode=disabled`（#5）、フォールバック 2 系統（#11 / #12）を明示的に含む
- **ドメインモデルとの整合**: 全ケースは `ReviewRoutingInput`（`caller_context` / `review_mode` / `automation_mode` / `configured_tools` / `available_tools` / `tools_runtime_status`）を入力とし、`ToolSelection` → `PathSelection` の評価順で `ReviewRoutingDecision` を導出する

**検証方法**: 各ケースについて (a) 整理前 `review-flow.md` の記述から判定結果を手動抽出、(b) 新規 `review-routing.md` のテーブルから同じ入力で判定結果を導出、(c) 両者の `ReviewRoutingDecision` 全フィールドが完全一致することを確認する。差分があれば `review-routing.md` を修正して再照合する。

### サイズ検証

```bash
/tmp/venv-tok/bin/python -c "
import tiktoken
enc = tiktoken.get_encoding('cl100k_base')
files = [
    'skills/aidlc/steps/operations/operations-release.md',
    'skills/aidlc/steps/common/review-flow.md',
    'skills/aidlc/steps/common/review-routing.md',
]
results = {}
for f in files:
    with open(f) as fh:
        c = fh.read()
    results[f] = len(enc.encode(c))
    print(f'{results[f]:>6} tok  {f}')
print()
print(f'operations-release.md: {results[\"skills/aidlc/steps/operations/operations-release.md\"]} tok (target: <= 1438, baseline 2877)')
rf_total = results['skills/aidlc/steps/common/review-flow.md'] + results['skills/aidlc/steps/common/review-routing.md']
print(f'review-flow.md + review-routing.md: {rf_total} tok (target: <= 3989, baseline 3989)')
"
```

**判定基準**:

- `operations-release.md` ≤ 1,438 tok（ベースライン 2,877 tok の 50%）
- `review-flow.md + review-routing.md` 合計 ≤ 3,989 tok（整理前の `review-flow.md` 単体以下）

### lint / 構文 / bash substitution 検証

以下のコマンドがすべてエラーゼロで完了すること:

```bash
# 1. CI デフォルトスコープ（.md 内の fenced bash の check、既存通り）
bash bin/check-bash-substitution.sh

# 2. operations-release.sh 構文チェック（bash -n、パースエラー検出）
bash -n skills/aidlc/scripts/operations-release.sh

# 3. operations-release.sh 静的解析（shellcheck 利用可能時のみ）
command -v shellcheck >/dev/null 2>&1 && shellcheck skills/aidlc/scripts/operations-release.sh || echo "shellcheck not available, skipped"

# 4. markdownlint
skills/aidlc/scripts/run-markdownlint.sh v2.3.0
```

**`check-bash-substitution.sh` の適用範囲について**: 現行 `check-bash-substitution.sh` は `*.md` 内の fenced bash ブロックのみを検査対象とする（`.sh` ファイル自体は検査しない）。したがって `operations-release.sh` の内部での `$()` 使用は既存スクリプト（`pr-ops.sh` / `validate-git.sh` 等）と同じく許容し、代わりに `bash -n` と `shellcheck`（任意）で品質を担保する。

### 参照整合性検証

```bash
grep -rn 'review-flow' skills/aidlc/steps/
grep -rn 'review-routing' skills/aidlc/steps/
grep -rn 'operations-release' skills/aidlc/
```

- `review-flow.md` への参照のうち、ルーティング判定を目的とするものが存在しないこと（手順本体参照のみ残存）
- `review-routing.md` への参照が新設された（フェーズインデックス 3 箇所 + ステップファイル 4 箇所 + `review-flow.md` 冒頭の注記 1 箇所 = 合計 8 箇所）
- `operations-release.sh` への参照が `steps/operations/operations-release.md` および `steps/operations/index.md` から存在すること

## 完了条件チェックリスト

- [ ] **【operations-release.sh 新設】** `skills/aidlc/scripts/operations-release.sh` が新規作成され、5 サブコマンド（`version-check` / `lint` / `pr-ready` / `verify-git` / `merge-pr`）および `--dry-run` モードをサポートしている
- [ ] **【operations-release.sh: 構文チェック】** `bash -n skills/aidlc/scripts/operations-release.sh` がエラーゼロで完了する。`shellcheck` 利用可能時は追加で実行し、警告ゼロであること（既存スクリプトと同じスタイルで `$()` 使用可）
- [ ] **【operations-release.sh: 既存スクリプト orchestration】** サブコマンド内で既存 `suggest-version.sh` / `ios-build-check.sh` / `run-markdownlint.sh` / `pr-ops.sh` / `validate-git.sh` を呼び出す薄いラッパーとして動作し、これらの内部実装は変更していない
- [ ] **【operations-release.sh: 透過契約】** 全サブコマンドが既存スクリプトの stdout と終了コードをそのまま透過する（0/1/2 への正規化は行わない）。例外: `pr-ready` の `--body-file` 必須エラーのみ exit 1。動作等価性検証では stdout 形式透過・warning/error 伝播・終了コード透過の 3 軸で確認
- [ ] **【operations-release.sh: --help】** 全サブコマンドと全体の `--help` が表示可能
- [ ] **【operations-release.md 簡略化】** `steps/operations/operations-release.md` が `operations-release.sh` 呼び出し + 人間判断が必要な箇所の説明のみに縮約されている
- [ ] **【operations-release.md サイズ】** `operations-release.md` が tiktoken (cl100k_base) で **1,438 tok 以下**（ベースライン 2,877 tok の 50%）
- [ ] **【operations-release.md 節マッピング整合】** スクリプト化対象の節（7.1 / 7.5 / 7.8 / 7.9-7.11 / 7.13）と markdown 残存節（7.2 / 7.3 / 7.4 / 7.6 / 7.7 / 7.12）の境界が計画の「節単位との対応一覧」表と実装で完全一致
- [ ] **【operations-release.md 動作等価性】** 4 シナリオで `--dry-run` 出力が旧手順と一致している: A: `gh pr create --base main --title "{{CYCLE}}" --body-file <path>`（ドラフト PR 不在時の新規 PR 作成、`--draft` フラグは付けない） / B: `gh pr edit --body-file` / C: `gh pr merge` × 3 方法（`merge` / `squash` / `rebase`）/ D: `validate-git.sh uncommitted` / `remote-sync` の戻り値伝播
- [ ] **【02-deploy.md 参照更新】** ステップ 7 サブステップ参照が `operations-release.md` + `operations-release.sh` 併記に更新されている
- [ ] **【operations/index.md 編集範囲限定】** §1 目次の `operations.02-deploy` 行説明文への注記追加 + §2.9「AI レビュー分岐」の参照差し替え の 2 箇所のみ変更され、§3 判定チェックポイント表 / §4 ステップ読み込み契約 / その他 Materialized Binding 構造は変更されていない
- [ ] **【review-routing.md 新設】** `skills/aidlc/steps/common/review-routing.md` が新規作成され、6 章構成（概要（`ReviewRoutingDecision` 論理インターフェース契約を含む）/ 設定 / CallerContext マッピング / 処理パス決定 / エラーフォールバック対応表 / 呼び出し形式）を持つ
- [ ] **【review-routing.md 論理インターフェース契約】** §1 概要に `ReviewRoutingDecision`（selected_path / skill_name / focus / tool_name / fallback_policy / skip_reason_required / user_rejection_allowed）の output 契約が記述され、`review-flow.md` への依存を持たない一方向依存構造が明示されている
- [ ] **【review-flow.md 簡略化】** `review-flow.md` 冒頭に `review-routing.md` 参照の注記が追加され、§設定 / §CallerContext マッピング / §処理パス / §遷移判定 セクションが削除されている
- [ ] **【review-flow.md 残存セクション】** `指摘対応判断フロー` / `スコープ保護確認` / `OUT_OF_SCOPE バックログ登録` / `判断完了後` / `レビュー完了時の共通処理` / `レビューサマリファイル` / `履歴記録` / `AI レビュー指摘の却下禁止` / `外部入力検証` / `分割ファイル参照` が保持されている
- [ ] **【review-flow.md は review-routing.md の ReviewRoutingDecision 消費者として記述】** 手順本体に独自のルーティング判定ロジックが混入していない
- [ ] **【review-flow.md + review-routing.md サイズ】** 合計 tok 数が整理前の `review-flow.md` 単体（3,989 tok）**以下**
- [ ] **【フェーズインデックス §2.8/§2.9 更新】** `inception/index.md` §**2.9** / `construction/index.md` §**2.8** / `operations/index.md` §**2.9** 「AI レビュー分岐」が `review-routing.md` + `review-flow.md` 両方を参照する形に更新されている
- [ ] **【ステップファイル個別参照更新（最小限）】** `inception/03-intent.md:42` / `inception/04-stories-units.md:49,93` / `construction/01-setup.md:82` の 4 箇所のみ「`review_mode=disabled` の場合は `review-routing.md` のパス 3 に直行」に更新されている。`construction/02-design.md` / `construction/03-implementation.md` は手順本体参照のため更新されていない
- [ ] **【ルーティング動作等価性】** CallerContext 全 9 種 + mode × automation_mode × tools 状態境界を含む 12 ケースの静的照合でルーティング判定が整理前後で完全一致
- [ ] **【markdownlint】** `skills/aidlc/scripts/run-markdownlint.sh v2.3.0` がエラーゼロ
- [ ] **【bash substitution check（steps スコープのみ）】** `bash bin/check-bash-substitution.sh`（CI デフォルトスコープ `skills/aidlc/steps/`、.md 内 fenced bash 検査）が違反ゼロ
- [ ] **【スコープ遵守】** 既存スクリプト内部実装の変更、新 reviewing スキルの追加、`phase-recovery-spec.md` / 各フェーズインデックスの判定チェックポイント表の変更が行われていない（純粋なリファクタリングのみ）

## 依存関係

### 前提 Unit

- Unit 001（Inception Phase Index の確立。`inception/index.md` §2.9 参照元）
- Unit 003（Construction Phase Index の確立。`construction/index.md` §2.8 参照元）
- Unit 004（Operations Phase Index の確立。`operations/index.md` §2.9 参照元、`operations-release.sh` 参照元）

### 本 Unit を依存元とする Unit

- Unit 006（計測・クローズ判断、Unit 001-005 で確立した全成果物の一括検証と初回ロード総合計測）

## 関連 Issue

- #519: コンテキスト圧縮メイン Issue（Tier 2 施策の統合適用）

## リスクと留意事項

- **operations-release.md の対話的部分の残存**: `merge_method=ask` 時のユーザー選択、`PR マージ前レビュー` のローカルレビュー判断、CHANGELOG/README のコンテンツ作成等は人間判断が必要であり、`operations-release.sh` に移せない。これらは markdown 本体に残すが、「どこまで script 化し、どこから markdown に残すか」の境界を設計フェーズで明確化する
- **動作等価性検証の範囲**: 本 Unit では `--dry-run` モードでの引数照合のみを行う。実運用での `gh pr merge` / `git push` 等の実行は Unit 006 の最終検証で行う（破壊的操作のため）
- **review-flow.md 内の「処理パス」記述の分割点**: 「パス 1 の反復レビュー手順」自体は手順記述として `review-flow.md` に残し、「パス 1 / 2 / 3 のどれを選ぶか」の判定のみを `review-routing.md` に移管する。両者の境界を設計フェーズで明確化する
- **参照更新の網羅性**: `review-flow.md` への参照箇所は複数存在するため、更新漏れが発生しやすい。`grep -rn 'review-flow' skills/aidlc/steps/` で整理前後の差分を網羅的に確認し、更新対象（4 step ファイル）と更新対象外（`construction/02-design.md` / `construction/03-implementation.md`、手順本体参照として維持）を明示的に照合する
- **既存スクリプトへの暗黙依存**: `operations-release.sh` は `suggest-version.sh` / `pr-ops.sh` 等の既存スクリプトの終了コード・出力形式に依存する。これらに非互換変更があると壊れるが、本 Unit のスコープでは既存スクリプトは変更しないため問題なし。依存関係はヘッダーコメントに明記する
- **`operations-release.md` のサイズ目標達成困難時のフォールバック**: 50% 削減が困難な場合は、設計段階で「追加で削減できる候補（重複する前置き文、例示の簡略化等）」を洗い出す。それでも達成できない場合は 40%〜50% 未満の削減に留め、完了条件の再定義をユーザー確認する
- **`check-bash-substitution.sh` の適用範囲**: 現行実装は `*.md` 内の fenced bash ブロックのみを検査対象とし、`.sh` ファイル自体は検査しない。したがって `operations-release.sh` 内部での `$()` 使用は既存スクリプト（`pr-ops.sh` / `validate-git.sh` 等）と同じく許容する。`.sh` の品質担保は `bash -n` と `shellcheck`（任意）で行う。CI 検査スコープの `.sh` への拡張は Unit 005 のスコープ外（別 Issue として扱う）
