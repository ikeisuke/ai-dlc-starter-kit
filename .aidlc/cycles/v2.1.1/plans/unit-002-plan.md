# Unit 002 計画: スコープ管理強化

## 概要

レビュー指摘対応時のスコープ縮小がユーザー確認なしに行われる問題を修正し、Unit完了時に残課題を可視化する。

## 変更対象ファイル

1. `skills/aidlc/steps/common/rules.md` — スコープ保護の原則を追加
2. `skills/aidlc/steps/common/review-flow.md` — OUT_OF_SCOPE判断時のスコープ縮小検出・ユーザー確認を実装
3. `skills/aidlc/steps/construction/04-completion.md` — Unit完了時の残課題可視化ステップを追加

## 実装計画

### #497: スコープ縮小時のユーザー確認必須化

**rules.md（原則定義）**:

- 「Overconfidence Prevention原則」セクション付近に「スコープ保護ルール」を新設
- 内容: レビュー指摘への対応でIntentの「含まれるもの」に記載された要件を制限・除外する場合、`automation_mode` に関わらずユーザー確認を必須とする原則

**review-flow.md（実行時の強制）**:

- 「指摘対応判断フロー」のOUT_OF_SCOPE選択箇所（選択肢3）に以下を追加:
  1. **スコープ縮小判定**: OUT_OF_SCOPE選択時に、Intent内要件への影響を判定する
     - 参照元: `.aidlc/cycles/{{CYCLE}}/requirements/intent.md` の「含まれるもの」セクション
     - 比較対象: 指摘対象の機能・要件が「含まれるもの」の項目に該当するか
     - Intentが曖昧/未記載の場合: ユーザー確認へフォールバック（安全側）
  2. **Intent内要件に該当する場合**: `automation_mode` に関わらずユーザー確認を必須とする。「この指摘はIntentの要件に含まれる機能に影響します。スコープから除外してよろしいですか？」と明示的に確認
  3. **確認結果の記録**: レビューサマリの「対応」列に `OUT_OF_SCOPE(理由)` として記録し、ユーザー確認済みであることを履歴に記録

### #498: Unit完了時の残課題提示

- `04-completion.md` の「完了条件の確認」（ステップ1）と「設計・実装整合性チェック」（ステップ2）の間に「残課題の集約提示」ステップを追加
- **責務**: レビューサマリからOUT_OF_SCOPE項目を可視化する（集約表示のみ。バックログ登録はreview-flow.md側で完了済みの前提）
- 集約条件:
  - 当該Unitの全review-summary.mdの全Set横断で、「対応」列が `OUT_OF_SCOPE(` で始まる行を抽出
  - 「バックログ」列も併せて表示（`#NNN` / `PENDING_MANUAL` / `SECURITY_PRIVATE`）
- OUT_OF_SCOPE項目がある場合: 一覧を提示。バックログ列が `PENDING_MANUAL` の項目があれば「未登録の残課題があります。手動登録を確認してください」と警告
- OUT_OF_SCOPE項目がない場合: 「残課題なし」と明示表示
- review-summary.mdが存在しない場合: 「レビューサマリなし（レビュー未実施または指摘0件）」と表示してスキップ

## 完了条件チェックリスト

- [ ] rules.mdにスコープ保護の原則が追加されている
- [ ] review-flow.mdのOUT_OF_SCOPE判断箇所にIntent照合・ユーザー確認が実装されている
- [ ] スコープ縮小判定の参照元（intent.md）・照合方法・曖昧時フォールバックが明文化されている
- [ ] 04-completion.mdにOUT_OF_SCOPE項目の集約表示ステップが追加されている（責務は可視化+未登録警告に限定）
- [ ] Unit完了時に残課題一覧または「残課題なし」が表示される仕組みになっている
