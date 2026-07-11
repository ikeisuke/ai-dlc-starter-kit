# Design 002: release hard gate の required CI 0 件フォールバック（#745）

- trace: work item 002-release-hard-gate-fallback
- matrix_case: normal_standard
- design_mode: simple

## Goal

v3 release フロー Step 3-4 hard gate の前提「base ブランチに required CI が存在する」が満たされない環境（required check 0 件）でも、一般化された opt-in の安全手順で release を完走できるようにする（#745）。既定挙動（required 0 件 = fail-closed 停止）は不変で維持する。

## Context

- **現行仕様**（`skills/aidlc-v3/steps/release.md` 3-4）: 「headRefOid と同一 SHA の required check が 1 件以上存在し、すべて成功」を要求し、required 0 件・pending・取得不能は fail-closed 停止。**ユーザー確認でも bypass 不可**。
- **問題**（#745）: base ブランチに required CI が構成されていない環境（例: 統合ブランチ宛て PR で CI が一切起動しない構成）では hard gate が必ず停止する。consumer プロジェクトでも同構成はあり得るため、一般化した挙動が必要（starter kit 固有判定は埋めない / Issue 論点 b）。
- **前提（001 で確定済み）**: opt-in 発動形態は「config フラグ `rules.release.required_ci_zero_fallback`（bool / 既定 `false`）+ 発動時ユーザー承認の二段」（`docs/v3/data-model.md` §11 キー #8）。フラグは経路の解放のみを担う。
- **既存の再アンカーパターン**: 3-0 / 3-5 に「head が変わったら 3-2〜3-4 をやり直す」再評価ループが既にあり、フォールバック記録による head 更新も同パターンで扱える。
- **スコープ外**: 統合ブランチへの CI トリガー追加（論点 c）、既定挙動の変更、スクリプト実装の変更（本変更は release.md 手順書のみ）。

## Design

### D1: 変更対象は release.md 3-4 のみ（手順書中心）

`skills/aidlc-v3/steps/release.md` Step 3-4 に「required CI 0 件フォールバック（opt-in）」サブセクションを追加する。スクリプト（doctor / release 系）・テンプレート・state schema は変更しない。フォールバック記録は既存 `release.md` 成果物の「CI 状態」「Merge 記録」セクションへの追記で表現する（テンプレート非変更）。workflow.md は hard gate の詳細を持たないため変更不要。

### D2: フォールバック適用条件（narrow scope / 既定不変）

フォールバック経路は以下を**すべて**満たす場合のみ開く。1 つでも欠ければ従来どおり fail-closed 停止:

1. `rules.release.required_ci_zero_fallback == true`（`read-config.sh` で取得。取得失敗・不正値は安全側 `false` = fail-closed）
2. 3-4 条件 1・2（PR OPEN / head・base identity / headRefOid 一致)は**フォールバックでも不変で必須**
3. required check の列挙が**空集合として正常取得**できた（`gh pr checks <N> --required` 系の取得結果が「0 件」と確定できる場合のみ。コマンドエラー・取得不能・pending は 0 件と区別し、従来どおり停止）
4. `mergeStateStatus == CLEAN` かつ `statusCheckRollup` が**空または全 entry SUCCESS**（non-required check の失敗・pending が 1 件でもあればフォールバック不可）

フォールバックが緩和するのは 3-4 条件 3 の「required count > 0」要求**のみ**。CI FAILURE / pending / 取得不能 / PR identity 不一致 / MERGED への停止は、フラグ値に関わらず bypass 不可のまま維持する。

### D3: 代替根拠 = ローカル検証 pass（一般化）

フォールバック発動には、merge 対象と同一内容（3-3 push 後の final head のワーキングツリー）に対する**ローカル検証 pass** を代替根拠として要求する:

- 検証項目（リポジトリに存在するものを実行 / 存在自体を opt-in シグナルとする汎用論理。starter kit 固有判定なし）:
  1. cycle 内 done work item の Traceability「Verification」に列挙された test command / manual check
  2. プロジェクト標準の検証資産（テストスイート / lint / 構文チェック等、リポジトリに定義がある場合）
- 実行結果（コマンドと pass/fail）を記録し、1 件でも fail があればフォールバック不成立（停止）。
- **少なくとも 1 件の検証が実行・記録され pass していることを成立必須条件とする**。検証資産が 1 件も存在しない場合はフォールバック不成立（停止 / 無検証 merge の経路を開かない）。CI トリガー追加または work item Traceability への manual check 追記を案内する（review 指摘 #1 反映 / 当初案の「代替根拠なしでユーザー判断」は無検証 merge 経路となるため廃止）。

### D4: 発動時ユーザー承認（automation_mode 非依存の必須ゲート）

`automation_mode == semi_auto` でも**自動承認しない**。`AskUserQuestion` で以下を提示し、明示承認を得た場合のみ発動する:

- required CI 0 件の観測事実（取得コマンドと結果）
- ローカル検証の実行結果一覧（D3）
- 「無 CI での merge となる」旨のリスク

拒否 → フォールバック不成立（従来どおり停止 / 論点 c の CI 追加等を案内）。

### D5: 記録と再評価ループ（TOCTOU 整合）

承認後、フォールバック発動を記録してから hard gate を再評価する（記録 commit で head が変わるため、既存 3-5 の再アンカーパターンに合流）:

1. `release.md` 成果物の「CI 状態」に required 0 件の観測を、「Merge 記録」に `required_ci_zero_fallback` 発動行（観測事実 / ローカル検証サマリ / ユーザー承認）を追記
2. 3-3 と同様に feature branch へ commit + push（head 更新）
3. **3-4 冒頭から再実行**。再実行時に required 0 件（D2 条件充足）かつ最終 head に発動記録が含まれる場合、条件 3 を「フォールバック充足」とみなし 3-5 へ進む（**再承認は求めない**: 記録 commit が承認の証跡であり、headRefOid 一致で対象の同一性を担保）
4. 再実行で required check が出現した場合（base 側で CI が構成された等）→ 通常経路（required 全 pass 要求）で判定する（発動記録は残るが無害)

journal へは Step 4-2 の release 完了追記時に fallback 発動を 1 行含める。

### 検証方針

- release.md（steps）の仕様レビュー（外部 CLI review / focus: code, security）
- markdownlint pass。スクリプト変更なしのため shellcheck / テストスイートは対象変更なし（既存 green を維持）
- work item AC との突合: opt-in 明文化 / 既定 fail-closed 不変 / 代替根拠 + 承認・記録手順の定義 / starter kit 固有判定なし
