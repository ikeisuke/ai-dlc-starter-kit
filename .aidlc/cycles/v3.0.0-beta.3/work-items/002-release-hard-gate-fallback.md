---
id: "002"
status: done
size: normal
risk: medium
assigned: null
dependencies: ["001"]
---

# Work Item 002: release hard gate の required CI 0 件フォールバック（#745）

## Goal

v3 release フロー（`skills/aidlc-v3/steps/release.md`）Step 3-4 hard gate が前提とする「base ブランチに required CI が存在する」が満たされない環境（required check 0 件）でも、一般化された安全手順で release を完走できるようにする（#745）。既定挙動は現行の fail-closed を不変で維持する。

## Scope

- 含むもの: release.md Step 3-4 へのフォールバック仕様の明文化（opt-in 発動 / 発動形態は 001 の判断に従う）、フォールバック時にローカル検証 pass を代替根拠とする条件の定義（検証項目・ユーザー承認手順・release.md / journal への記録要件）、関連テスト（doctor / release 系スクリプトに変更が及ぶ場合）
- 含まないもの: `v3.0.0` 統合ブランチ等への CI トリガー追加（#745 論点 c）、starter kit 固有判定の埋め込み、既定挙動（required 0 件 = fail-closed 停止）の変更

## Acceptance Criteria

- [ ] required CI 0 件時のフォールバック手順が release.md Step 3-4 に opt-in として明文化されている
- [ ] opt-in が発動していない既定状態では、現行どおり required 0 件で fail-closed 停止する（既定挙動非影響）
- [ ] フォールバック発動時の代替根拠（ローカル検証項目）と人間承認・記録の手順が定義されている
- [ ] consumer プロジェクトでも成立する一般化された仕様であり、starter kit 固有判定を含まない

## Traceability

- Intent refs: scope:#745（release hard gate フォールバック）
- Acceptance refs: AC-1, AC-6
- Verification: release.md の仕様レビュー + スクリプト変更が及ぶ場合は該当テストスイート実行 / shellcheck / parse-guard
- Release note required: yes（既知制約 #745 の解消）

## Size / Risk

- Size: normal
- Risk: medium
- Reason: merge 安全性に関わるゲート仕様の変更だが、既定挙動不変（opt-in 追加）かつ手順書中心の変更であるため。設計選択（発動形態）は 001 で確定済みの判断に従う

## Dependencies

- 001（フォールバック opt-in を config フラグとする場合、キー終端集合に含める必要があるため）
