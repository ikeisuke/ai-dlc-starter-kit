# Unit 001 計画: review-flow 5R 化と defer 自動化

## 概要

`skills/aidlc/steps/common/review-flow.md`（正本）の review round 上限を 3R → 5R に拡張し、完了条件を「最後 2 round 連続で指摘ゼロまたは defer 化」へ改定する。あわせて、defer 判定時の自動 Issue 起票フロー（必須ラベル: `backlog`, `type:defer-from-review`）と、Round 4 以降の新領域指摘の自動 backlog 化フロー（必須ラベル: `backlog`, `type:new-area-from-round4plus` / 領域キー差分による準機械判定）を新設する。

本 Unit 完了直後から本サイクル後続 Unit（002/003/004）の review に対しても 5R / 自動 Issue 化が有効化（自己適用の閉ループ）される。

## 関連 Issue

- #635 review-flow 規定の運用実態適合（round 上限 5R 化 + defer 即時 Issue 化 + 新領域指摘の自動 backlog 化）

## 変更対象ファイル

| ファイル | 操作 | 説明 |
|---------|------|------|
| `skills/aidlc/steps/common/review-flow.md` | 改修（正本） | round 上限 3 → 5、完了条件改定、defer 自動 Issue 起票フロー、Round 4+ 新領域 backlog 化フロー、機密情報注意書きを追記 |
| `skills/aidlc/steps/common/review-flow-reference.md` | 同期 | round 上限 / 完了条件 / 新フロー記述を正本に合わせる（該当箇所のみ） |
| `skills/aidlc/templates/review_summary_template.md` | 改修 | `**反復回数**: [1〜3]` → `[1〜5]`、`## Round 4 新領域判定` セクション（`K_old` / `K_new` / `K_new - K_old` を JSON 配列で記録）追加 |
| `skills/reviewing-common/reviewing-common-base.md` | 条件付き同期 | 5R / 完了条件 / 自動 Issue 起票 / 新領域 backlog 化に関する記述があれば正本同期。該当箇所が見つかった場合は本ファイルを変更後に `bin/sync-reviewing-common.sh` を実行し各 reviewing スキルへ伝播させる（該当記述なしの場合も `bin/sync-reviewing-common.sh` を実行して伝播経路の健全性を確認） |
| `bin/sync-reviewing-common.sh` | 実行 | `reviewing-common-base.md` 改修有無に関わらず本 Unit 完了前に実行し、各 reviewing スキル配下 references が最新であることを保証 |
| `skills/reviewing-{construction,operations,inception}-*/SKILL.md` および配下 | 確認＋必要時のみ同期 | 直接 round 上限値や完了条件を記述している箇所のみ正本に同期。ほとんどは review-flow.md を参照する記述になっているはず |
| `skills/aidlc/steps/{inception,construction,operations}/index.md` | 確認のみ | round 数値の直書きがないか確認（無ければ無修正） |
| `bin/check-skill-references.sh` | 動作確認のみ | 改修後 pass することを確認。スクリプト自体の改修は不要 |
| `bin/tests/` および `tests/` 配下 | 既存依存テストの追従修正（実装対象） | review-flow 記述（round 上限・完了条件・defer 扱い）に依存する既存 BATS テストがあれば 5R / 新フローに追従させる。新規 BATS 基盤の拡張（テストランナー差し替え、CI 連携の根本改修）は本 Unit のスコープ外 |

## 実装計画

### Phase 1（設計）

設計成果物として以下を作成する:

- ドメインモデル（`design-artifacts/domain-models/unit_001_review-flow-5r-and-defer-automation_domain_model.md`）: review round / defer 判定 / 新領域判定のドメイン語彙と関係を整理
- 論理設計（`design-artifacts/logical-designs/unit_001_review-flow-5r-and-defer-automation_logical_design.md`）: 5R フロー、自動 Issue 起票の状態遷移、ラベル検証の入出力契約、新領域キー正規化ルールの形式仕様

`depth_level=standard` のため Phase 1 はスキップしない。設計レビュー（`reviewing-construction-design`）を 5R 内で実施する。

### Phase 2（実装）

#### 1. `review-flow.md` 改修（正本）

- 「実行手順」内の `反復レビュー（最大 3 回）` を `最大 5 回` に変更
- 「指摘対応判断フロー」内の `反復レビュー 3 回後` を `5 回後` に変更
- 完了条件節を新設: 「最後 2 round 連続で指摘ゼロまたは defer 化」
- defer 判定時の自動 Issue 起票フローを新設:
  - 必須ラベル: `backlog`, `type:defer-from-review`
  - 起票後 `gh issue view <N> --json labels --jq '[.labels[].name]'` で必須ラベル両方の付与確認
  - 失敗時 `PENDING_MANUAL`（warn 継続 / review 中断しない）
  - review-summary の「バックログ」列に Issue 番号を記録（`#NNN`）
- Round 4 以降の新領域指摘の自動 backlog 化フローを新設:
  - 領域キーは User Stories 1C「境界条件」テーブルに従って正規化
  - 判定手順 0〜7 を review-flow.md に手順記載
  - `内容` 列のパス記法規約（repo-relative path を backtick で囲む）を明記
  - 起票時ラベル: `backlog`, `type:new-area-from-round4plus`、起票後検証手順は defer と同等
- 機密情報除外注意書きを追記（NFR セキュリティ）
- **削除対象を限定**: defer 起票の裁量文言（「ユーザー判断に委ねる」「Issue 化保留」など、起票を保留する判断を許容する記述）のみを削除する。スコープ保護確認（OUT_OF_SCOPE 時のユーザー確認）/ 千日手判断 / 指摘対応判断フロー（修正・TECHNICAL_BLOCKER・OUT_OF_SCOPE 選択）のユーザー確認フローは AI とユーザーの意思決定責務境界として維持対象（削除しない）

#### 2. `review-flow-reference.md` 同期

- 正本との不整合があれば該当箇所のみ同期。round 上限値は本 reference 側に直書きされていないため、新フローの参照リンク（review-flow.md 側に追加した節）が必要なら追加する

#### 3. `review_summary_template.md` 改修

- `**反復回数**: [1〜3]` を `[1〜5]` に変更
- 末尾に `## Round 4 新領域判定` セクションを追加（`K_old` / `K_new` / `K_new - K_old` を JSON 配列で記録するブロックを示す）
- 「良い例」「悪い例」内の `最大3回の反復制限を追記` 等の履歴文言は本文の文脈として保持しつつ、誤解防止のため当該テーブルの直前または直後に「（注: 当時の上限値。本サイクル v2.5.2 以降は 5 回 / 完了条件は最後 2 round 連続で指摘ゼロまたは defer 化）」相当の補注 1 行を追記する

#### 4. reviewing-common-base.md / reviewing-* スキルの同期

- `skills/reviewing-common/reviewing-common-base.md` を確認し、5R / 完了条件 / defer 自動 Issue 起票 / 新領域 backlog 化に関する記述があれば正本同期
- `bin/sync-reviewing-common.sh` を実行し、reviewing-common-base.md の内容を各 reviewing-* スキル配下の `references/reviewing-common-base.md` に伝播させる（reviewing-common-base.md に変更があった場合は伝播必須、なくとも伝播経路の健全性確認のため実行）
- 各 reviewing-* スキル（construction-{plan,design,code,integration} / operations-{deploy,premerge} / inception-{intent,stories,units}）の SKILL.md と配下 references を grep し、round 上限値や完了条件の直書きがあれば正本同期
- `session-management.md` 内の `[3 回目]` は session 継続のサンプル例（独立コンテキスト）であり改変不要

#### 5. 既存 BATS テスト追従

- `bin/tests/` および `tests/` 配下を grep し、review-flow 記述（round 上限・完了条件・defer 扱い）に依存する既存 BATS テストがあれば 5R / 新フローに追従させる
- 検出されない場合は明示的に「該当テスト未検出」と履歴記録する

#### 6. `check-skill-references.sh` pass 確認

- 改修後 `bin/check-skill-references.sh` を実行し pass を確認。検出された不整合は本 Unit 内で解消

#### 7. 自己適用の検証

- 本 Unit 自身の Phase 1/Phase 2 の review-flow から、改訂後 5R / 自動 Issue 起票が機能することを実地確認
- `gh` CLI が available の前提で defer 判定→ Issue 起票→ ラベル検証フローのドリル（実 Issue 起票なし、手順確認のみ）

### 実装順序

1. review-flow.md の正本改修（5R / 完了条件 / 自動 Issue 起票 / Round 4+ 新領域 backlog 化 / 削除対象限定の明文化）
2. review_summary_template.md の改修
3. review-flow-reference.md の同期
4. reviewing-common-base.md の同期判定 + `bin/sync-reviewing-common.sh` 実行（伝播）
5. reviewing-* スキル各 references の同期確認
6. 既存 BATS テスト追従（`bin/tests/` / `tests/` を grep し依存テストがあれば修正、なければ履歴に明記）
7. `bin/check-skill-references.sh` 実行で pass 確認
8. 自己適用の検証（5R / 自動 Issue 起票が機能することを実地確認）
9. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| `gh issue create` 失敗（権限不足 / API エラー） | warn 継続 + review-summary 「バックログ」列に `PENDING_MANUAL` 記録（review 自体は中断しない） |
| 起票後ラベル検証で必須ラベル欠落 | `PENDING_MANUAL` 扱い（同上） |
| review-summary パス抽出で backtick 規約違反 | warn 表示 + 当該指摘を新領域判定から除外 |
| `gh_status != available` | review 自体は継続、Issue 起票は warn + `PENDING_MANUAL` 記録 |
| `check-skill-references.sh` 失敗 | Unit 内で不整合解消（reviewing-* スキルの同期漏れを再確認） |

## NFR

- パフォーマンス: review 1 round の所要時間に追加負荷なし（ドキュメント改修中心）
- セキュリティ: 起票時に機密情報を Issue 本文に含めない注意書きを review-flow.md に追記
- 可用性: `gh` 不可時は warn 継続（review 中断しない）

## 完了条件チェックリスト

- [x] `skills/aidlc/steps/common/review-flow.md` の round 上限が `5` と明記されている
- [x] 完了条件「最後 2 round 連続で指摘ゼロまたは defer 化」が明記されている
- [x] defer 判定時の自動 Issue 起票フロー（必須ラベル `backlog`, `type:defer-from-review` / 起票後ラベル検証 / 失敗時 `PENDING_MANUAL`）が記述されている
- [x] Round 4 以降の新領域指摘の自動 backlog 化フロー（必須ラベル `backlog`, `type:new-area-from-round4plus` / 領域キー差分 / `内容` 列パス記法規約 / 判定手順 0〜7）が記述されている
- [x] defer 起票の裁量文言（「ユーザー判断に委ねる」「Issue 化保留」等）が review-flow.md / 関連スキルから削除されている（スコープ保護確認・千日手判断・指摘対応判断フローのユーザー確認は維持されていること）
- [x] `skills/aidlc/steps/common/review-flow-reference.md` が正本に同期されている（必要箇所のみ）
- [x] `skills/aidlc/templates/review_summary_template.md` の反復回数表記が `[1〜5]` に更新されている
- [x] `## Round 4 新領域判定` セクションがテンプレートに追加されている
- [x] 5R 化が `reviewing-construction-{plan,design,code,integration}` / `reviewing-operations-{deploy,premerge}` / `reviewing-inception-{intent,stories,units}` の各スキルに反映（直書きなしの場合は確認のみで OK）
- [x] `reviewing-common-base.md` の同期判定が完了し、`bin/sync-reviewing-common.sh` が実行されて各 reviewing-* スキル配下の `references/reviewing-common-base.md` が正本と一致している
- [x] `bin/tests/` および `tests/` 配下の review-flow 記述依存テストが 5R / 新フローに追従している（該当テスト未検出の場合は履歴に明記）
- [x] `bin/check-skill-references.sh` が pass する
- [x] 機密情報除外注意書きが review-flow.md に追加されている
- [x] 既存 v2.5.1 review-summary 記述様式との後方互換性が確認されている（既存記述は読み取り可能）
