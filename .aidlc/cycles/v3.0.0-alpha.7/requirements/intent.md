# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit — v3 リニューアル Phase 6「reflect + doctor + status 拡充」

## 開発の目的

v3（`skills/aidlc-v3`）に **reflect（振り返り）フロー**と **doctor（診断）コマンド**を実装し、**status を拡充**することで、v3 単独で `define → develop → release → reflect` のフルサイクルを完走できる状態にする。これは Epic #736「v3 リニューアル Phase 4–7 完遂ロードマップ」の **Phase 6** にあたり、設計 SoT は `docs/v3-renewal-plan.md`「Phase 6」、`docs/v3/workflow.md §3.4（reflect）/ §3.5（status）/ §3.6（doctor）`、`docs/v3/data-model.md §5（フェーズ導出）/ §7（journal）/ §10（成果物）`。

Phase 5（alpha.6）までで `define → develop → release` は v3 単独で回せるが、reflect（任意の振り返り→改善 Issue 化）と doctor（環境・状態の診断）が未実装のため「フルサイクル完走 = v3 をスキルとして使える」状態に届いていない。本サイクルでこの最後の歯抜けを埋め、Phase 7（dogfooding + 本流化）の前提を揃える。

あわせて、ドッグフーディングで踏んだツール不具合 **#735（`squash-unit.sh` の複数 `--message` footgun）** を修正し、Phase 番外（alpha.4）で Try 全件が実装・CI ガード済みであることを確認した **#733（v3系通し振り返り）をクローズ**する。

## ターゲットユーザー

- **AI-DLC を使う開発者**: `/aidlc-v3 reflect` で前サイクルの振り返りと改善 Issue 化ができ、`/aidlc-v3 doctor` で config / git / gh / state / work-items の問題を着手前に診断できる。`/aidlc-v3 status` で現在地と次アクションを正確に把握できる。
- **本キットのドッグフーディング開発者（自分）**: Phase 7 で v3 を本流化する前提として、reflect + doctor + status の完成（= v3 単独フルサイクル完走）を必要とする。また `squash-unit.sh` を `git commit` の慣習どおり複数 `--message` で安全に呼べるようになる。

## ビジネス価値

- v3 が `define → develop → release → reflect` の 4 フェーズと `status` / `doctor` を通しで提供できるようになり、Epic #736 のマイルストーン「Phase 6 完了 = v3 をスキルとして使える状態」を達成する。
- v2 では preflight + recovery spec に分散していた診断を `doctor` に**集約**し、振り返りを `reflect`（core から upstream mirror / cap 管理 / dialog token / aggregate issue を外した軽量版）に**簡素化**することで、v3 設計目標「読み込み量・成果物数の削減」を運用フェーズでも実証する。
- ドッグフーディングで頻出する `squash-unit.sh` の subject 消失 footgun を断ち、AI エージェントのコミットメッセージ規約破壊を防ぐ。

## 成功基準

### reflect

- `skills/aidlc-v3/steps/reflect.md` が新規作成され、`docs/v3/workflow.md §3.4` の Step 1–4（材料収集 / KPT 抽出 / 行動化（Try の Issue 化 + `reflect.md` 記録）/ 完了（`journal.md` 追記））を手順として記述している。
- `skills/aidlc-v3/templates/reflect.md`（reflect 成果物テンプレート）が新規作成されている。
- reflect は明示の承認ゲートを持たず、Step 2 で人間が KPT を編集、Step 3 で Issue 化を人間に確認する手順になっている。
- **core から外す項目**（upstream mirror / cap 管理 / dialog token / aggregate retrospective issue）を**実装しない**ことが手順・ドキュメントで明示されている。

### doctor

- `skills/aidlc-v3/scripts/doctor.sh`（診断ロジック集約 / **自動修正しない**）と `skills/aidlc-v3/steps/doctor.md`（出力仕様）が新規作成されている。
- 診断領域は **config / state / cycle / work-items / git / gh / pr / scripts** の shallow check + **禁止パースパターン検出（`bin/check-frontmatter-parse-guard.sh` 相当の流用）**。既存スクリプト（`state-validate.sh` / `work-item-validate.sh` / native git・gh コマンド）を再利用する。
- `[phase]` 導出 code 化と `[trace]` 整合チェックは**本サイクルでは実装せず alpha.8 以降へ defer** する旨が `doctor.md` / Intent / journal に明記されている。
- doctor は state.json / work item が壊れている場合に**診断結果と推奨のみ**を提示し、自動修正しない。

### doctor 段階スコープの SoT 反映（AIレビュー指摘 #1 対応）

- `docs/v3/workflow.md §3.6`（doctor チェック項目表）に、各項目が **alpha.7 で実装 / alpha.8 へ defer** のいずれかであるかの段階注記を追加する（`[phase]` / `[trace]` = alpha.8）。
- `docs/v3-renewal-plan.md` は **Phase 6 定義だけでなく、同ファイル内の doctor チェック項目一覧（`[phase]` / `[trace]` を含む箇所）にも** alpha.7 / alpha.8 の段階注記を追加し、「全項目 alpha.7 実装」と読める余地を残さない（AIレビュー Round 2 指摘対応）。あわせて Phase 6 完了条件と Epic #736 の完了条件を「doctor 全チェック項目」から「**alpha.7 = doctor shallow（8項目 + parse-guard） / phase・trace = alpha.8 必須 follow-up**」へ明示更新し、完了判定の二重化を防ぐ。
- alpha.8 の必須 follow-up（doctor `[phase]` / `[trace]`）を Epic #736 ロードマップまたは backlog Issue として切り出す。

### status 拡充

- `status` の出力が `docs/v3/workflow.md §3.5` の出力例（`Remaining` / `Suggested command` / `Phase` の導出根拠併記 / `No active cycle` 時の案内）に揃うよう拡充されている。

### SKILL.md

- `SKILL.md` の `reflect` / `doctor` コマンドが「予約」から実装済みに更新され、ルーティング先（`steps/reflect.md` / `steps/doctor.md`・`scripts/doctor.sh`）を指す。express ラッパ・旧名エイリアス（retrospective）整合が取れている。

### #735（squash-unit footgun）

- `skills/aidlc/scripts/squash-unit.sh` が複数 `--message` を `git commit` 同様の**段落結合**（1 個目 = subject、以降 = 本文段落）でサポートし、Co-Authored-By トレーラの重複が起きない。
- 複数 `--message` / Co-Authored-By 重複の回帰テストが `skills/aidlc/scripts/tests/` に追加されている。

### #733（クローズ）

- alpha.4 完了証跡（`lib/frontmatter.sh` / `tests/test-frontmatter-parser.sh` / `tests/test-cycle-resolution.sh` / `bin/check-frontmatter-parse-guard.sh` + CI / `state-read.sh` の CycleResolver）をコメントして #733 をクローズする。**実装作業は発生しない**。

### テスト（AIレビュー指摘 #2 対応 / 成果物別に分離）

- **doctor.sh（契約テスト必須）**: `skills/aidlc-v3/scripts/tests/` に doctor の契約テストを追加し、少なくとも以下の失敗・分岐モードを検証する — `state.json 不在` / `state.json 破損（schema 不正）` / `work item frontmatter 不正` / `必須スクリプト不在` / `git dirty/clean` / `gh 未認証` / `active PR あり・なし` / `gh 未認証・不可時の pr 診断` / `parse-guard 違反検出` / `No active cycle`（全領域 OK の正常系を含む）。各ケースで `OK`/`WARN`/`NG` + 推奨表示・自動修正なしを確認する。
- **status 拡充（出力整合の検証）**: `docs/v3/workflow.md §3.5` の出力例（active cycle 時の `Remaining` / `Suggested command` / 導出根拠、`No active cycle` 時の案内）に出力が一致することを検証（テストまたは再現可能なドライ検証）。
- **reflect（手順ドライ検証可）**: reflect は対話・人間編集主体のため、手順のドライ検証（Step 1–4 の入出力・成果物生成パスの確認）でよい。
- 既存 v3 テスト（`scripts/tests/`）および #735 修正後の `skills/aidlc/scripts/tests/` が green を維持する。

## 期限とマイルストーン

- サイクル: **v3.0.0-alpha.7**（Phase 6 = 1 サイクル / Epic #736）。
- 後続: Phase 7（dogfooding + 本流化 / `aidlc-v3 → aidlc` 置換）→ v3.0.0 RC→GA。
- 本サイクルは Inception → Construction → Operations を通常どおり v2（`/aidlc`）で進行する（v3 の dogfooding 適用は Phase 7）。
- 本 Intent は Epic #736 を `Relates to #736` で紐付け、進捗 SoT のトレースを繋ぐ。

## 含まれるもの（スコープ）

- `skills/aidlc-v3/steps/reflect.md` の新規作成（workflow.md §3.4 Step 1–4 / data-model.md §7・§10 を正本として参照）。
- `skills/aidlc-v3/templates/reflect.md` の新規作成。
- `skills/aidlc-v3/scripts/doctor.sh` + `skills/aidlc-v3/steps/doctor.md` の新規作成（config / state / cycle / work-items / git / gh / pr / scripts + parse-guard の shallow 診断 / 既存スクリプト再利用 / 自動修正なし）。
- doctor 段階スコープの SoT 反映（`docs/v3/workflow.md §3.6` への alpha.7/alpha.8 段階注記 / `docs/v3-renewal-plan.md` の **Phase 6 定義および doctor チェック項目一覧（`[phase]` / `[trace]` を含む箇所）** への alpha.7/alpha.8 段階注記 + Epic #736 完了条件の明示更新 / alpha.8 必須 follow-up の切り出し）。
- `status` 出力の拡充（workflow.md §3.5 出力例への整合）。
- `SKILL.md` の `reflect` / `doctor` を実装済みに更新（ルーティング・express ラッパ・retrospective エイリアス整合）。
- `skills/aidlc/scripts/squash-unit.sh` の複数 `--message` 段落結合対応（#735）+ 回帰テスト。
- #733 のクローズ（alpha.4 完了証跡コメント / 実装なし）。
- 新規分テスト追加と既存テストの green 維持。

## 含まれないもの（非スコープ）

- doctor の `[phase]` 導出 code 化・`[trace]` 整合チェックの**実装**（実装コスト中〜重 / 機能確定待ち → **alpha.8 以降へ defer**）。ただし本サイクルでは defer を SoT（workflow.md §3.6 / renewal-plan / Epic #736）へ明示反映する作業のみ行う（スコープに含む / 上記参照）。
- v3 の本流化（`skills/aidlc-v3 → skills/aidlc` 置換 / v2 maintenance branch 化 / README 刷新 / marketplace の v3.0.0 化 / v2→v3 migration）= Phase 7。
- 9 reviewing スキルの `aidlc-review`（9→1）統合（後続 Phase / RFC §1 課題 3）。
- `state.json` schema の拡張・変更（既存スキーマのまま）。
- #733 Try（T1/T2'/T4/T6）の再実装（**alpha.4 で実装・CI ガード済み**。本サイクルはクローズのみ）。
- reflect の upstream mirror（starter kit 固有）/ cap 管理 / dialog token / aggregate retrospective issue（v3 で core から外す方針 / workflow.md §3.4）。
- alpha.7 自身のリリースを v3 release フローで実行すること（dogfooding は Phase 7）。本サイクルの実リリースは v2 Operations で行う。

## 不明点と質問（Inception Phase中に記録）

[Question] #735（`squash-unit.sh`）の複数 `--message` 修正方針は？
[Answer] 段落結合（`git commit` 準拠 / 1 個目 = subject、以降 = 本文段落）。

[Question] #733 Try（parser 構造改善）の本サイクル取り込み範囲は？
[Answer] alpha.4（Phase 番外）で T1/T2'/T4/T6 すべて実装・CI ガード済み。本サイクルでは**実装せずクローズ**する。

[Question] Phase 6 doctor の診断スコープは？
[Answer] 7（+pr）領域の shallow check + parse-guard 流用。`[phase]` 導出 code 化と `[trace]` 整合は alpha.8 へ defer（やり過ぎ回避）。
