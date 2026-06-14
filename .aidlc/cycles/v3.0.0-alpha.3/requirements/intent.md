# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit / v3.0.0-alpha.3（Phase 3: define + develop tiny フロー実装）

## 開発の目的

alpha.2（Phase 2）で「読める手順」として固定した `skills/aidlc-v3/` の define と state スクリプト群を、**実際に動作する実行実装**へ進める（`status` の実行実装は計画書 Phase 6 のため本サイクル対象外。本サイクルでは define / develop 後の状態が既存 status 出力仕様どおりフェーズ導出できることのみ確認する）。具体的には:

- `define` を**実行可能**にする（cycle ディレクトリ作成・`intent.md` / `work-items/*.md` 生成・`state.json` 初期化・`journal.md` 追記・branch / commit）
- `develop` の **tiny フロー**を実装する（design / review なしで 1 tiny work item を完了し、frontmatter status を `done` に更新、journal 追記）
- `work-item-next.sh`（依存グラフ解決による次 work item 選定）を実装する
- `marketplace.json` に `aidlc-v3` を登録し `/aidlc-v3` 起動を有効化する（実行実装が入るためドッグフーディング・検証が可能になる）
- alpha.2 レビューで defer した **#731**（`state-validate.sh` の `schema_version` 値互換性検証 + `state-write.sh` の未知 `schema_version` 更新防止ガード）を `docs/v3/data-model.md` §6 の WARN / migration 案内方針に沿って解消する

本サイクル（alpha.3）は v3 リニューアル全体（7〜8 サイクル）の **Phase 3** に相当し、計画書（`docs/v3-renewal-plan.md`）の Phase 3「define + develop tiny flow」を実行する。

なぜ必要か:

- alpha.2 の skeleton は「読める手順 + 検証可能な state 操作」までで、フローを**実際に実行できない**。Phase 4 以降（develop normal/risky、release、reflect/doctor）はこの実行実装を土台とする
- 実行実装と起動有効化により、本リポジトリで v3 フローを**ドッグフーディング**できる状態を作り、設計（`docs/v3/*.md`）と実装の乖離を早期に検出する
- 前フェーズ defer の #731 を未解消のまま放置すると、非互換 `state.json` が `state-write.sh` で更新・保持され得る状態が残るため、define が state を実書き込みする本サイクルで解消する

## ターゲットユーザー

- **直接**: AI-DLC starter kit の開発者（本リポジトリ。ドッグフーディングで v2 を使い v3 を構築）
- **間接**: 将来 v3 を利用する consumer プロジェクト（実行可能な define / develop tiny フローが以降のフロー実装・利用体験の土台になる）

## ビジネス価値

- v3 の最初の「動く」フロー（define → develop tiny）を確立し、Phase 4 以降が拡張する実行基盤を 1 サイクルで固める
- `/aidlc-v3` 起動有効化により v3 の実利用検証を開始し、設計乖離・UX 課題を本流化（Phase 7）前に発見する
- #731 解消により state 検証の安全境界（未知 schema_version の扱い）を data-model 規定に整合させる

## スコープ

### 含まれるもの（このサイクルの成果物）

- **define 実行実装**: `skills/aidlc-v3/steps/define.md` を実行手順として具体化（Step 1 環境チェック / Step 2 Intent 定義 + 承認ゲート / Step 3 Work Item 分割 + 承認ゲート / Step 4 初期化）。Step 4 で cycle ディレクトリ作成・`intent.md` / `work-items/*.md` 生成・`state.json` 初期化（`define_completed: true` 書き込み）・`journal.md` 追記・git branch / commit を実際に行う（`docs/v3/workflow.md` §3.1）
- **develop tiny フロー実装**: `skills/aidlc-v3/steps/develop.md` を新規作成し、**tiny サイズのみ**のフローを実装。`docs/v3/workflow.md` §3.2 準拠で frontmatter status を **`pending → in_progress`（Step 1 work item 選定時）→ `done`（Step 6 完了時）** と遷移させ、実装内容を **work item 単位で commit** し、journal に完了記録を追記する。design / review はスキップ（tiny の定義どおり）（計画書 Phase 3）
- **`work-item-next.sh`**: `work-items/*.md` の frontmatter（status / dependencies）を走査し、依存がすべて `done` の未完了 work item から次候補を選定するスクリプト（`docs/v3/data-model.md` の frontmatter 仕様準拠）
- **cycle ディレクトリ作成ロジック**: v3 形式（フラット構造: `intent.md` / `work-items/` / `journal.md`、v2 の inception/construction/operations サブディレクトリは持たない）の cycle ディレクトリを作成するロジック（define Step 4 から呼ばれる）
- **`marketplace.json` への `aidlc-v3` 登録**: plugins リストに `./skills/aidlc-v3` を追加し `/aidlc-v3` 起動を有効化する
- **#731 解消**: `state-validate.sh` の `schema_version` 値互換性検証。`docs/v3/data-model.md` §6 の方針（未知バージョンは「invalid（exit 1）」ではなく **WARN + migration / 手動対応案内**）に沿って実装し、サポート対象 `schema_version`（初版 `"3.0"`）と未知バージョンを区別する。あわせて **`state-write.sh` の最小ガード**（未知 `schema_version` の既存 `state.json` を更新せず不変保持 + migration / 手動対応案内）を実装し、#731 の本質リスク（writer が非互換 state を更新・保持する事故）を塞ぐ。validator・writer 両方の境界テストを追加する

### 含まれないもの（明示的除外 / 後続フェーズ）

- 既存 `skills/aidlc`（v2）への変更（クリーンカット / 共存。v2 は一切触らない）
- `develop` の **normal / risky** フロー（design / risk analysis / review ルーティング）の実装（Phase 4）
- `release` フロー（PR 整備・merge・post-merge cleanup）の実装（Phase 5）
- `reflect` / `doctor` の実装、`status` 出力の拡張を超える変更（Phase 6）
- `aidlc-review` 統合スキル（10→1）の実装（Phase 4 以降）
- `steps/recovery.md` / `steps/rules.md` の実体作成（後続 Phase。#731 は recovery.md ではなく `state-validate.sh` + `state-write.sh` の最小ガードのレイヤーで data-model §6 方針に沿って解消する）
- v2 → v3 migration スクリプト（`aidlc-migrate`）の実装（別フェーズ）
- `work-item-state.sh`（frontmatter の atomic 書き込み + schema validation）の実装は、tiny フローで status 更新に必要な最小範囲に留め、汎用 work item 状態 API としての完全実装は後続に委ねる
- `express` 連続実行ラッパの実装（define + develop + release が揃う Phase 5 以降）

## 成功基準（受け入れ基準）

- [ ] `/aidlc-v3 define` 実行で、新しい v3 形式 cycle ディレクトリ・`intent.md`・`work-items/*.md`・`state.json`（`define_completed: true`）・`journal.md` が**実際に生成**される
- [ ] define Step 4 で **指定した cycle ブランチが作成され、初回 commit が作成される**（`git status` / `git log` で確認できる）
- [ ] `state.json` が `state-write.sh` 経由の atomic 書き込みで初期化され、`state-validate.sh` で valid と判定される
- [ ] `/aidlc-v3 develop` 実行で、tiny work item が design / review なしで完了し、frontmatter `status` が **`pending → in_progress → done`** と遷移し、実装内容が **work item 単位で commit** され、`journal.md` に完了記録が追記される
- [ ] `work-item-next.sh` が依存解決して次 work item を正しく選定する（`bash -n` / shellcheck（利用可能時）を通過する）。境界条件として **(a) 依存がすべて `done` の未完了 work item が選定される / (b) 依存が未完了（`pending` / `in_progress`）の work item は候補から除外される / (c) 依存先が `withdrawn` の場合は自動充足とせず（`done` のみ自動充足。`docs/v3/data-model.md` §5.2 が正本規定）、当該 dependent item は候補外（`blocked` 相当）とし、人間判断で「依存解除（当該依存先を `dependencies` から除去）」または「dependent も `withdrawn`」を選ぶまで進めない / (d) 存在しない dependency ID を持つ work item は WARN を出して候補外とする（`docs/v3/data-model.md` §6 の trace 整合エラー規定に整合） / (e) 候補が複数ある場合の選定順（または提示方式）が定義されている** を満たし、それぞれに対応するテストがある
- [ ] develop 完了後の `state.json` + frontmatter が、既存 status 出力仕様（`steps/status.md`）どおりフェーズを導出できる状態になっている。具体的に **未完了 work item が残る場合は `develop`、全 work item が `done` / `withdrawn` の場合は `release 可能`（`docs/v3/data-model.md` §5.1 評価順 3 / 4）** を導出できること。**tiny work item 1 件のみのサイクル（完了で `release 可能`）と複数 work item の途中完了（`develop` 継続）の両方**を検証対象にする（`status` 実行実装自体は Phase 6 / 本サイクル対象外）
- [ ] `marketplace.json` の plugins に `./skills/aidlc-v3` が追加され、`/aidlc-v3` が起動できる
- [ ] **#731**: 未サポート `schema_version` 値を含む `state.json` が `state-validate.sh` で `docs/v3/data-model.md` §6 方針（WARN / migration・手動対応案内、invalid 扱いにしない）に沿って処理され、かつ **`state-write.sh` が未知 `schema_version` の既存 `state.json` を更新しない**（不変保持 + 案内）。validator・writer 両方の境界テストが追加されている
- [ ] **v2 非影響**: `skills/aidlc/` 配下に一切の変更がない（`git diff` で確認）。v3 フローの動作検証は本リポジトリの v2 ドッグフーディング用 `.aidlc/`（`config.toml` / `cycles/` の v2 成果物）を破壊しない方法（サンドボックス / テストハーネス、alpha.2 の `test-state-scripts.sh` 踏襲）で行う
- [ ] markdownlint を通過し、シェルスクリプトは `bash -n` / shellcheck（利用可能時）を通過する

## 期限とマイルストーン

- 本サイクル（alpha.3）= Phase 3。後続は alpha.4（develop normal/risky）, alpha.5（release）, alpha.6（reflect + doctor）, alpha.7〜（ドッグフーディング + 本流化）と段階進行
- 全 alpha 完走後に統合ブランチ `v3.0.0` を `main` へマージ

## 制約事項

- **ドッグフーディング**: v2 starter kit（2.6.6）の Inception/Construction を使って v3 の define + develop tiny 実行実装を構築する
- **共存（クリーンカット）**: 成果物は `skills/aidlc-v3/` および `marketplace.json` の plugins 追加 1 行に隔離し、v2 `skills/aidlc` の runtime / ファイルに影響を与えない
- **ブランチ**: 作業は `cycle/v3.0.0-alpha.3`（`v3.0.0` ベース）。release で `cycle/v3.0.0-alpha.3 → v3.0.0` の PR
- **入力と正本優先順位**: `docs/v3-renewal-plan.md`（Phase 3）を実行計画の入力とし、`docs/v3/*.md`（alpha.1 で確定した RFC / workflow / data-model / migration）を**設計の正本**とする。用語・コマンド名・schema・フェーズ導出が両者で食い違う場合は確定 RFC（`docs/v3/*.md`）を優先する（Construction コマンド名は `develop`、renewal plan の `build` 表記は `develop` に読み替える）
- **#731 の実装層**: `recovery.md` / migration はまだ存在しないため、#731 は `state-validate.sh` + `state-write.sh` の最小ガードのレイヤーで data-model §6 方針に沿って解消する。未知 `schema_version` を invalid（exit 1）にして §6 の WARN 規定と矛盾させない。`state-write.sh` の一般的な状態遷移制御（`define_completed` / `release.*` の許可・禁止遷移）の本格実装は Phase 3+ の別範囲とし、本サイクルは「未知 schema_version の既存 state を更新しない」ガードに限定する
- **Reverse Engineering**: 計画書 + alpha.1 の `docs/v3/*.md` + alpha.2 の `skills/aidlc-v3/` skeleton が設計インプットを内包するため、別途 `existing_analysis.md` は作成しない

## 不明点と質問（Inception Phase中に記録）

[Question] alpha.3 のスコープ範囲は Phase 3 全体（define 実行実装 + develop tiny + work-item-next.sh + cycle dir 作成）とするか、define のみに絞るか。
[Answer] Phase 3 全体 + 前フェーズで defer した Issue（#731）も本サイクルで対応する（ユーザー承認済み 2026-06-12）。

[Question] `marketplace.json` への `aidlc-v3` 登録（`/aidlc-v3` 起動有効化）を alpha.3 に含めるか（skeleton では Phase 3+ へ defer されていた）。
[Answer] 含める。alpha.3 で登録し起動を有効化する。実行実装が入るため `/aidlc-v3 define` / `develop` を実際に起動・ドッグフーディングできるようにする（ユーザー承認済み 2026-06-12）。
