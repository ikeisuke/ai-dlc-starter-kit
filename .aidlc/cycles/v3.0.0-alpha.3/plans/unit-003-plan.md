# Unit 003 計画: v3 develop tiny フロー実行実装

## 対象 Unit

- **Unit**: 003-v3-develop-tiny-flow（v3 develop tiny フロー実行実装）
- **サイクル**: v3.0.0-alpha.3（Phase 3）
- **依存 Unit**: 001-v3-define-flow（完了）/ 002-work-item-next（完了）
- **関連 Issue**: なし
- **depth_level**: standard（設計フェーズあり）/ **review_mode**: required

## 目的（1 文）

`skills/aidlc-v3/steps/develop.md` を新規作成し、`size: tiny` の work item を design / review なしで `pending → in_progress → done` まで完了させる develop フロー（work item 単位 commit・journal 追記・完了後フェーズ導出可能化を含む）を、`workflow.md` §3.2 を正本として実装する。

## 設計方針（前提認識）

- develop.md は define.md / status.md と同列の AI 駆動 steps ファイル（markdown プロンプト）。実装の主成果物はプロンプト本体であり、テスト可能な振る舞いは「補助スクリプトの動作」と「e2e ハーネスによるフロー再現」で担保する（define.md の `run_define_step4` ドライバ方式を踏襲）。
- フロー手順の正本は `docs/v3/workflow.md` §3.2。size × review マトリクス（§6.2）により tiny は design（Step 2）/ review（Step 5）をスキップする。
- Step 1 の work item 選定は Unit 002 の `work-item-next.sh` を利用（出力 `next:<id>:<size>:<relpath>` / 候補なし `next:none` / resume 優先で in_progress を返す / exit 0/1/2）。**size がペイロードに含まれるため tiny 判定で再パース不要**。
- フェーズ導出の正本は `docs/v3/data-model.md` §5.1（評価順）。develop 完了後、未完了 item が残れば `develop` 継続、全 item が done/withdrawn なら `release 可能`。**フェーズ導出は全 work item frontmatter の `status` を走査して判定する**（§5.1 評価順 3/4）。`work-item-next.sh` の `next:none` は「新規/resume 可能 item なし」を意味するだけで blocked 相当の未完了 item 残存時にも発生しうるため、release 可能の根拠には**しない**（item 選定とフェーズ導出は別レイヤ / §5.2）。本 Unit は「導出できる状態になること」の検証までを責務とし、`status` コマンド実装（Phase 6）には踏み込まない。
- 検証はサンドボックス（`mktemp -d`）で行い、v2 ドッグフーディング用 `.aidlc/` を一切破壊しない。

## 主要な実装対象

1. **`skills/aidlc-v3/steps/develop.md`（新規）**: tiny フロー専用の Step 1 / 3 / 4 / 6（Step 2 設計・Step 5 レビューは tiny スキップを明記）。
   - Step 1: `work-item-next.sh` で次 item 選定 → **status を `in_progress` 更新する前に `size: tiny` を確認**。`next:none` の場合は**全 work item frontmatter status を走査**し、全 done/withdrawn なら release 可能、未完了（blocked 等）残存なら develop 継続を案内（next:none を release 可能の根拠にしない / §5.1・§5.2）。`size: normal` / `risky` なら**未サポート案内のみで停止し、frontmatter / journal / commit を一切変更しない（副作用なし）**。
   - Step 1（tiny 確定後）: frontmatter `status` を `in_progress` に更新。
   - Step 3: acceptance criteria に沿った実装 + work item 単位 commit。
   - Step 4: acceptance criteria チェック（検証）。
   - Step 6: frontmatter `status` を `done` に更新、journal 追記、次 item / release 可能の案内。
2. **frontmatter `status` 更新スクリプト `skills/aidlc-v3/scripts/work-item-status.sh`（新規 / D1 で確定済み）**: work item の frontmatter の `status` 行のみを安全に atomic 更新する専用スクリプト。`pending → in_progress → done` の遷移を担う。期待現在 status チェック・enum 検証・終了コード 0/1/2 規約を持つ（既存に frontmatter 書き込み手段が無く、Unit 002 が atomic 書き込みを本 Unit へ defer したため新設。詳細インターフェースは設計フェーズで確定）。
3. **`skills/aidlc-v3/SKILL.md` 更新**: `develop` を「予約」から実装済みに変更し、`steps/develop.md` を手順ファイルとして登録・ルーティング参照を追加。
4. **テストハーネス**（`skills/aidlc-v3/scripts/tests/test-develop-flow.sh` 想定 / D5）: (1) tiny 完了後のフェーズ導出（全 status 走査による develop 継続 / release 可能）、(2) normal/risky 選定時（新規 pending）の副作用なし停止、(3) resume（in_progress）経路（tiny 継続 / normal・risky 副作用なし停止）、(4) `work-item-status.sh` 単体（正常遷移 / enum 不正 / 期待現在 status 不一致 / 終了コード）を検証。

## 設計フェーズで確定すべき主要判断

| # | 論点 | 選択肢候補 | 備考 |
|---|------|-----------|------|
| D1 | frontmatter `status` 更新方式（**確定: (a) 専用スクリプト新設**） | (a) 専用スクリプト `work-item-status.sh`（work item パス + 期待現在 status + 新 status を受け、frontmatter の status 行のみ atomic 更新 / enum・期待現在 status 検証 / 終了コード 0/1/2）を新設し develop.md / テストの双方が利用【採用】/ (b) AI の Edit による frontmatter 直接編集 / (c) sed インライン更新 | RFC P4「frontmatter は安全境界が必要」「状態変更は guard」、既存に frontmatter 書き込み手段が無いこと、Unit 002 の atomic 書き込み defer 経緯、テスト可能性（e2e がスクリプト呼出で決定的に再現）より (a) を計画段階で確定。**設計フェーズで確定するのは引数シグネチャ・atomic 書き込み実装・検証範囲の詳細のみ** |
| D2 | size 確認と副作用なし停止の実装位置 | (a) Step 1 冒頭で `work-item-next.sh` 出力の size を判定し、`tiny` 以外は status 更新前に return（mutation 一切なし）/ (b) status 更新後に size 判定（ロールバック必要） | 責務「副作用なし停止」より (a) を強く推奨。設計で stop シグナル（案内文 / 終了挙動）の形を確定 |
| D3 | resume（in_progress）item が tiny でない場合の扱い | (a) resume された in_progress item の size が normal/risky なら未サポート案内で停止（status/journal/commit 変更なし＝副作用なし / develop tiny フロー対象外）/ (b) in_progress は size 不問で継続 | `work-item-next.sh` は resume 優先で in_progress を返す（in_progress があれば pending 選定ロジックに到達しない）。本 Unit は tiny のみ対象。(a) を推奨し、resume された tiny は継続・normal/risky は副作用なし停止とする方針を設計で確定。**完了条件・テストにも resume ケースを反映済み（下記）** |
| D4 | commit / journal 追記の形式と **commit 境界** | commit メッセージ: `develop: <id>-<slug> <要約>` 等（define の `define: <cycle> ...` 規約と整合）/ journal: `- develop completed: <id>` 等（data-model §7 形式）。**commit 境界（方針固定）**: tiny フローは **work item 単位で最終 commit を 1 つに集約**する。実装中の中間 commit を許す場合も、Step 6 完了時に `git commit --amend` または squash で**最終 commit 単体に「実装変更 + 検証後 `status: done` + journal 追記」がすべて含まれる**状態にする（追加 commit を残さない）。これにより完了条件「最終 commit に実装変更 + status:done + journal 追記が含まれる」と一致する | define.md の記法に揃える。work item 単位 commit の粒度・status:done/journal の commit 含有関係を明記（workflow.md §3.2 は Step 6 squash のみで含有関係が曖昧なため本 Unit で明文化） |
| D5 | テストハーネスの構成 | tiny e2e は AI ステップ（実装内容）を含むため、`run_develop_tiny` ドライバで「AI が行う mutation（`work-item-status.sh` 経由の status 更新・journal 追記・commit）」を模擬し、(1) 完了後 state がフェーズ導出可能、(2) normal/risky 選定時に副作用なし、(3) **resume（in_progress）経路**の挙動をアサート（test-define-flow.sh 方式踏襲）| 何を「テスト対象」とし何を「ドライバ模擬」とするかの境界を設計で確定 |
| D6 | フェーズ導出確認の検証手段 | **全 work item frontmatter の `status` を走査**して `develop` 継続（done/withdrawn 以外あり）/ `release 可能`（全 done/withdrawn）を導出（§5.1 評価順 3/4）。`work-item-next.sh` の `next:none` は item 選定の結果であり、blocked 残存時にも発生するためフェーズ導出の根拠には使わない（§5.2 別レイヤ）。status コマンド本体（Phase 6）は呼ばない | 責務「導出できる状態の確認まで」を厳守。レビュー指摘 #1 反映 |

> フロー手順の正本は `docs/v3/workflow.md` §3.2、フェーズ導出は `docs/v3/data-model.md` §5.1、frontmatter / status enum は §4。

## 完了条件チェックリスト

Unit 003「責務」から抽出:

- [ ] `skills/aidlc-v3/steps/develop.md` が新規作成され、tiny フロー（Step 1 / 3 / 4 / 6）を記述している
- [ ] Step 2（設計）/ Step 5（レビュー）が tiny ではスキップされることが明記されている（`workflow.md` §6.2 size × review マトリクス）
- [ ] Step 1 で `work-item-next.sh` を利用して次 work item を選定する
- [ ] status を `in_progress` 更新する**前に** `size: tiny` を確認し、`normal` / `risky` の場合は未サポート案内のみで停止する（frontmatter / journal / commit を一切変更しない＝副作用なし）
- [ ] `next:none`（選定可能 item なし）の場合に、**全 work item frontmatter status を走査**して release 可能（全 done/withdrawn）/ develop 継続（blocked 残存）を判定し案内を分岐する（next:none を release 可能の根拠にしない / §5.1・§5.2）
- [ ] tiny 確定後に `work-item-status.sh` 経由で frontmatter `status` を `in_progress` に更新する
- [ ] `in_progress` の work item が resume された場合、size が `tiny` なら継続する
- [ ] `in_progress` の work item が resume され size が `normal` / `risky` の場合、status/journal/commit を変更せず未サポート案内のみで停止する（副作用なし）
- [ ] Step 3 で acceptance criteria に沿った実装と work item 単位 commit を行う
- [ ] Step 4 で acceptance criteria のチェック（検証）を行う
- [ ] Step 6 で `work-item-status.sh` 経由で frontmatter `status` を `done` に更新し、journal を追記し、次 item / release 可能を案内する
- [ ] work item 単位の最終 commit に「実装変更 + 検証後 `status: done` + journal 追記」が含まれる（commit 境界が明文化されている / D4）
- [ ] `work-item-status.sh` が frontmatter の `status` 行のみを atomic 更新し、enum・期待現在 status を検証し、終了コード 0/1/2 規約に従う
- [ ] develop 完了後の state がフェーズ導出可能な状態（`develop` 継続 / `release 可能`）になることがテストで検証されている（全 status 走査 / §5.1）
- [ ] normal / risky 選定時（新規 pending・resume in_progress の双方）に副作用なしで停止することがテストで検証されている
- [ ] `SKILL.md` で `develop` が実装済みとして登録され、`steps/develop.md` がルーティングから参照される
- [ ] **v2 非影響**: `skills/aidlc/`（v2）配下に変更がない（`git diff` で確認）
- [ ] `bash -n` / shellcheck（利用可能時）/ markdownlint を通過する

## 検証方針

- サンドボックス（`mktemp -d`）に state.json + work-items フィクスチャを構築し、(1) tiny 完了後のフェーズ導出（全 status 走査による develop 継続 / release 可能）、(2) normal/risky 副作用なし停止（新規 pending）、(3) resume（in_progress）経路（tiny 継続 / normal・risky 副作用なし停止）、(4) `work-item-status.sh` 単体をアサート（Unit 001/002 の test-*.sh 方式踏襲）。
- v2 ドッグフーディング用 `.aidlc/` は一切変更しない。
- `bash -n` / shellcheck（新設スクリプトがある場合）/ markdownlint。

## スコープ境界（本 Unit に含まれないもの）

- normal / risky 分岐（design / risk analysis / review ルーティング）→ Phase 4
- aidlc-review 統合スキルの実装 → Phase 4 以降
- release フロー → Phase 5
- `status` コマンドの実行実装 → Phase 6（本 Unit は「導出できる状態」の確認まで）
- frontmatter の汎用 atomic 書き込みライブラリ化（status 以外のフィールド更新含む）は本 Unit スコープ外。`work-item-status.sh` は status 遷移に必要な最小範囲のみ実装する（D1）

## リスク

- **R1**: `work-item-status.sh`（D1 で新設確定）の詳細インターフェース・atomic 書き込み実装・検証範囲に不備が生じるリスク → 設計レビューで RFC P4 安全境界・テスト可能性・Unit 002 defer 経緯と整合させ詳細を確定。
- **R2**: 「副作用なし停止」の不完全実装（status 更新後に停止判定する等）→ D2 で status 更新前の size 判定を確定し、テストで副作用なしをアサート。
- **R3**: develop.md が AI プロンプトのためテストで直接実行できない → D5 のドライバ模擬方式で「AI が行う mutation」を再現し検証境界を明示。
- **R4**: v2 `.aidlc/` 破壊リスク → サンドボックス隔離を徹底。
