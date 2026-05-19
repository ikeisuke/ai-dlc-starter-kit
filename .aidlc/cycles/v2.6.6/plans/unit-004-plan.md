# Unit 004 実装計画: §1.5 Issue 起票フロー Try ループ化 + predecessor 互換 + dogfooding 検証

## 対象 Unit

- **Unit**: 004 - §1.5 Issue 起票フロー Try ループ化 + predecessor 互換 + dogfooding 検証
- **関連 Issue**: #710（CLOSED / 方針親 / 本 Unit の PR で `Comment` 記録）, #715（OPEN / 実例パターン / 本 Unit の PR で `Comment` 記録）。Unit 004 自体が新規に Close 対象とする Issue は無し（#704 / #652 は Unit 002 / Unit 003 でそれぞれ Close 済み）
- **優先度**: High（リリース判定の最終 Unit）
- **depth_level**: standard（Phase 1 設計を実施）

## 背景・目的

v2.6.6 Intent §1.5 で確定したとおり、`steps/retrospective.md` §1.5 の Issue 起票フローは現状「`Retrospective: {cycle}` 集約 Issue 1 件に Try を全部詰める」設計のため、Issue 起票自体が達成基準にすり替わり、Try が「次回から気をつける」「個別チェック 1 項目追加」で済まされる構造的欠陥を抱える（#710 親問題）。

本 Unit では Unit 001 で定義した `aggregate_issue_enabled` 仕様（既定 `false`）と cap 仕様（サイクル内 T Issue 起票合計の上限）を **利用する側** として、§1.5 Step 4 を Try 件数分のループに置き換え、各 T Issue 本文に 5 セクション（背景 / 主因切り分け / 構造課題昇格根拠 / 想定対策 / 関連）を必須化する。

同時に、集約 Issue 廃止に伴い `predecessor_resolve_issue` の既存 5 経路を破壊せず、集約 Issue 不在時の retrospective ラベル付き T Issue 群集計経路（内部サブ分岐 `t_issue_milestone_scope` / `t_issue_label_fallback`）を新規追加する。

最後に本サイクル自身の振り返り（v2.6.6 retrospective）を新フローで dogfooding 検証し、CI green と後方互換 fixture pass、PR Closes/Comment 運用までを完了させる。

本 Unit は SC-02 / SC-03 / SC-08 / SC-09 / SC-10 / SC-11 / SC-12 を充足し、SC-04 の **検証責務のみ**（一次責務 = fixture 整備 / 同等性テスト実装は Unit 001、本 Unit は Unit 001 で整備された fixture を最終 CI で再 pass 確認する責任のみ）を持つ。

## スコープ

### 含まれるもの（責務）

#### サブ責務 4A: §1.5 ループ起票（実装独立）

- **必須対応 1**: `skills/aidlc-retrospective/steps/retrospective.md` §1.5 Step 4 を Try 件数分ループに変更
  - `aggregate_issue_enabled = false`（既定）時: Try 件数分 `retrospective_api_create_issue` を反復呼び出し
  - `aggregate_issue_enabled = true`（opt-in）時: 旧集約 Issue 起票フローを維持（Unit 001 で実装済の分岐へ委譲）
  - cap 判定は Unit 001 で定義済の「サイクル内 T Issue 起票合計の上限」仕様に従う（cap 到達時は追加起票拒否）
- **必須対応 2**: 各 T Issue のタイトル生成ロジック
  - 形式: `[Retrospective: {cycle}] {Try 内容を 1 行で}`
  - `{Try 内容}` は Try セクションの本文先頭 1 行から生成（複数行 / 引用記号を除外）
- **必須対応 3**: 各 T Issue 本文に **5 見出し** + **配下本文非空** を保証
  - `## 背景` / `## 主因切り分け` / `## 構造課題昇格根拠` / `## 想定対策` / `## 関連`
  - 各見出し配下に最低 1 行の非空テキスト（空白行 / コメントのみは不可）
  - `## 構造課題昇格根拠` は §1.2.5 セルフレビューで「個別チェック追加で逃げていない」と判定した根拠を Unit 002 の選択肢ラベルから自動転記
- **必須対応 4**: `skills/aidlc/templates/retrospective_template.md` の Try セクションを 5 セクション必須形式に再構成（テンプレ自体が「単一 Try = 1 Issue 単位」の構造になるよう改修）
- **必須対応 5**: bats テスト追加（4A 担当範囲）
  - 起票件数観測: 既定動作で集約 Issue 起票 = 0、T Issue 起票 = Try 件数
  - 各見出し配下非空チェック: 5 見出しすべて非空である bats 陽性 / 1 見出しでも空であれば fail とする陰性
  - cap 判定境界: cap = N のとき N 件目 OK / N+1 件目で追加起票拒否

#### サブ責務 4B: predecessor 互換 + 新動作経路（実装独立 / 4A と並列可）

- **必須対応 6**: `skills/aidlc/scripts/lib/predecessor-issue.sh` に新動作経路を追加
  - 集約 Issue 0 件 + retrospective ラベル付き T Issue 1 件以上で発火する経路
  - 内部サブ分岐の正式名称: `t_issue_milestone_scope`（同 milestone 内の T Issue 群を集計）/ `t_issue_label_fallback`（milestone 無 / label のみで集計）
  - 既存 5 経路名（`milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue`）と衝突しない名前空間を採用
- **必須対応 7**: 既存 5 経路の挙動を保護
  - 既存 5 経路のシグネチャ / `resolution_path` 出力値 / NDJSON 形式は **完全不変**
  - 新経路は集約 Issue ヒットを優先評価した後、ヒット 0 件時のみ後段で評価される（既存経路の判定結果に介入しない）
- **必須対応 8**: bats 回帰テスト追加（4B 担当範囲）
  - 既存 5 経路（`milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue`）の `resolution_path` 出力が期待値と一致（v2.6.4 Unit 004 の手動再現を bats 化）
  - 新動作経路 2 サブ分岐（`t_issue_milestone_scope` / `t_issue_label_fallback`）で `candidates` 配列 ≥ 1 を返す
  - 旧サイクル fixture（v2.6.5 以前の `Retrospective: {cycle}` 集約 Issue 1 件あり想定）で `resolution_path = milestone_and_label` 維持、かつ新動作経路に入らない

#### サブ責務 4C: dogfooding + CI/後方互換 + PR 運用証跡（検証フェーズ依存）

**着手条件**: 4A + 4B の完了ゲート全項目 pass、かつ Unit 001 / Unit 002 / Unit 003 完了済み

- **必須対応 9**: 本サイクル v2.6.6 自身の振り返りを新フローで実施（Operations Phase §1 retrospective ステップで実行）
  - (a) 全 T Issue で「主因切り分け」「構造課題昇格根拠」セクションが非空であることを目視確認
  - (b) §1.2.5 セルフレビュー 3 観点の AskUserQuestion 応答が retrospective 実行ログ（`history/operations.md` 等）に記録される
  - (c) §1.2.5 差し戻し機構の動作検証は **bats 陽性ケース pass で担保**（dogfooding 実運用での差し戻し発生件数は 0 件以上を許容）
- **必須対応 10**: CI green + 後方互換 fixture 再 pass の最終確認
  - fixture 整備 / 同等性テスト実装は Unit 001 の一次責務、本 Unit は最終 CI ジョブで全テスト pass を確認する検証責務のみ
- **必須対応 11**: PR 本文必須記載
  - `Closes #704`（Unit 002 で対応 / PR 本文記載は本 Unit 責務）
  - `Closes #652`（Unit 003 で対応 / PR 本文記載は本 Unit 責務）
  - `Comment #710`（patch サブセット適用で minor 想定本体を先取り）
  - `Comment #715`（patch サブセット適用パターン実例）
- **必須対応 12**: CHANGELOG / リリースノート 3 項目必須記載
  - 「集約 Issue が既定で生成されなくなる」
  - 「旧動作を維持するには `aggregate_issue_enabled = true` を明示設定」
  - 「retrospective ラベル付き T Issue 群が集約 Issue の代替として `predecessor_resolve_issue` で解決される」

#### 共通

- **設計ドキュメント**: ドメインモデル + 論理設計を `.aidlc/cycles/v2.6.6/design-artifacts/` 配下に作成
- AI レビュー（計画 / 設計 / コード / 統合）を codex で実施（`review_mode=required`）

### 含まれないもの（境界）

- **`aggregate_issue_enabled` フラグ仕様 / cap 仕様の SoT 定義** → Unit 001（完了済 / 本 Unit は利用側）
- **§1.2.5 セルフレビュー観点 + 判別ガイド整備** → Unit 002（完了済）
- **三層検証 helper の実装** → Unit 003（完了済）
- **既存 5 経路の挙動変更** → 禁止（経路追加のみ許可）
- **`Retrospective: {cycle}` タイトル運用の完全廃止** → v2.7.0+ defer（後方互換解決経路として残す）
- **`retrospective_api_*` の破壊的シグネチャ変更** → v2.7.0+ defer
- **`predecessor_resolve_issue` の経路再設計** → v2.7.0+ defer（既存 5 経路 + 新規経路追加のみ）

## 実装方針

### Phase 1: 設計

- **ドメインモデル**:
  - `TryIssueCommitment`: 1 Try = 1 Issue の運用契約（タイトル / 5 セクション本文 / 関連 / cap カウント対象）
  - `IssueTitleRule`: タイトル形式 `[Retrospective: {cycle}] {Try 1 行要約}` の生成規則
  - `RequiredSectionSet`: 5 必須見出し集合（背景 / 主因切り分け / 構造課題昇格根拠 / 想定対策 / 関連）
  - `SectionNonEmptyContract`: 各見出し配下に最低 1 行の非空テキストを要求する契約
  - `CapCounter`: サイクル内 T Issue 起票合計の上限カウンタ（Unit 001 で SoT 定義済を参照）
  - `PredecessorResolution`: 既存 5 経路 + 新規 2 サブ分岐の `resolution_path` 列挙
  - `PredecessorResolutionPath`: 既存 `milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue` + 新規 `t_issue_milestone_scope` / `t_issue_label_fallback`
  - `DogfoodingEvidence`: dogfooding (a)(b)(c) を充足する証跡集合
- **論理設計**:
  - **§1.5 Step 4 ループ起票フロー**: Try 件数分の反復構造、各 T に対する dialog token 検証 → cap 判定 → タイトル生成 → 本文 5 セクション組み立て → `retrospective_api_create_issue` 呼び出し
  - **タイトル生成ロジック**: Try セクション本文先頭非空行を抽出 → 引用記号 / 箇条書きマーカー除去 → 80 文字で truncate → `[Retrospective: {cycle}]` を prefix（末尾スペース + summary を連結して 1 行タイトル化）
  - **5 セクション組み立てロジック**: テンプレートから 5 見出しを展開、各見出し配下の本文は以下から動的補完
    - `## 背景`: 該当 K/P 要旨（Unit 002 §1.2 主因切り分け結果から取得）
    - `## 主因切り分け`: §1.2 の 3 分類（プロダクト固有 / AI-DLC 固有 / 両方）+ 根拠
    - `## 構造課題昇格根拠`: §1.2.5 セルフレビュー応答の選択肢ラベル（「再発性 = 直近 3 サイクル再発」「対象レイヤ = skill / プロンプト / SoT / CI ガード」「再入余地 = 残らない」等）から自動転記
    - `## 想定対策`: Try 本文
    - `## 関連`: サイクル番号 / `Relates: #<集約>`（`aggregate_issue_enabled = true` 時のみ）
  - **5 セクション非空保証**: 起票直前に各見出し配下を行数カウント、0 行検出時は起票せず `selfreview-incomplete` ラベル付きで warn + skip
  - **predecessor-issue.sh 新動作経路追加**: 既存 `resolve_issue()` の経路評価順序を保ち、5 経路すべて 0 件ヒット時にのみ新経路評価へ遷移。新経路は (1) 同 milestone 内 retrospective ラベル付き T Issue ≥ 1 → `t_issue_milestone_scope` / (2) milestone 無 + retrospective ラベル付き T Issue ≥ 1 → `t_issue_label_fallback` の 2 分岐
  - **既存 5 経路保護**: シグネチャ / `resolution_path` 出力値 / NDJSON フィールドは **完全不変**。新経路は既存経路の判定ロジック内部には介入しない（後段追加のみ）
  - **テンプレ改修方針**: `skills/aidlc/templates/retrospective_template.md` の Try セクションを「1 Try = 1 Issue 単位」の 5 見出し構造へ再構成。Unit 001 の `aggregate_issue_enabled = true` 時用の旧テンプレ参照も保持

### Phase 2: 実装

1. `skills/aidlc-retrospective/steps/retrospective.md` §1.5 Step 4 を Try ループ化（4A）
2. `skills/aidlc/templates/retrospective_template.md` の Try セクション 5 見出し再構成（4A）
3. `skills/aidlc/scripts/lib/predecessor-issue.sh` 新動作経路 + 内部サブ分岐 `t_issue_milestone_scope` / `t_issue_label_fallback` 追加（4B）
4. bats テスト追加（4A: 起票件数 / 5 見出し非空 / cap 境界）
5. bats テスト追加（4B: 5 経路回帰 / 新動作 / 旧サイクル維持）
6. shellcheck pass 確認
7. markdownlint pass 確認

### Phase 3: テスト

- bats 全テスト pass（4A 範囲 + 4B 範囲 + 既存 retrospective_* 全 regression なし）
- shellcheck pass
- markdownlint pass
- パフォーマンス NFR 確認: T 件数 N に対し O(N) 起票時間（dialog token TTL 300 秒内に N ≤ cap 値の起票が完了）

## 完了条件チェックリスト

### 4A 完了ゲート（実装独立）

- [x] §1.5 Step 4 が Try ループ化されている（`steps/retrospective.md` Step 4-A TryLoopCreationStrategy 追加）
- [x] 各 T Issue タイトル形式 `[Retrospective: {cycle}] {Try 1 行要約}` の生成ロジックが確定し実装されている（Step 4-A SectionComposer 手順内に明記）
- [x] 5 見出し（背景 / 主因切り分け / 構造課題昇格根拠 / 想定対策 / 関連）非空 bats テストが pass（`tests/retrospective-issue-loop-create.bats` T-LOOP-3 / T-LOOP-7 / T-LOOP-8）
- [x] cap 判定境界 bats テスト記述が pass（T-LOOP-9 制御フロー仕様表で cap 到達時 break / skipped_count 計上ルールを担保 / 実起票の bats 化は Operations Phase dogfooding で実機検証）
- [x] `skills/aidlc/templates/retrospective_template.md` の Try セクションが 5 見出し構造に再構成されている（`try_loop_block` マーカー導入 + `aggregate_block` で旧構造保持）

### 4B 完了ゲート（実装独立 / 4A と並列可）

- [x] `skills/aidlc/scripts/lib/predecessor-issue.sh` に新動作経路が追加されている（`_pure_classify_resolution_path` 引数 6/7 拡張 + `predecessor_resolve_issue` case 拡張 + `__pred_gh_query_t_issue` / `_pure_sort_by_closed_at_desc_null_safe` 新規追加）
- [x] サブ分岐名 `t_issue_milestone_scope` / `t_issue_label_fallback` が正式名称として確定されている
- [x] 既存 5 経路（`milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue`）の回帰 bats が pass（`tests/predecessor-issue-handoff.bats` 17 件すべて pass / fixture を canonical title に更新）
- [x] 新動作経路 bats（`candidates` 配列 ≥ 1）が pass（`tests/predecessor-issue-t-loop.bats` T1 / T2）
- [x] 旧サイクル維持 bats（`resolution_path = milestone_and_label` 維持 + 新動作経路に入らない）が pass（T4）

### 4C 完了ゲート（Operations Phase §1 retrospective ステップで実施 / Construction Phase では未実施 = 委譲）

- [ ] **(委譲: Operations §1)** dogfooding (a) (b) (c) 3 条件達成 — Construction 完了後の本サイクル振り返り実行時に達成
- [ ] **(委譲: Operations 完了処理)** CI green（既定動作系 SC-02 / SC-03 のテスト群 + opt-in 復元系 SC-04 のテスト群を CI で pass / Intent §「patch として許容する条件」3 へのトレース）
- [ ] **(委譲: Operations 完了処理)** 後方互換 fixture 再 pass 確認（fixture 自体は Unit 001 で整備済）
- [ ] **(委譲: Operations release PR 作成時)** PR 本文に `Closes #704` / `Closes #652` / `Comment #710` / `Comment #715` 4 項目記載
- [ ] **(委譲: Operations release 準備)** CHANGELOG / リリースノート 3 項目（集約 Issue 既定 off / `aggregate_issue_enabled = true` で旧動作復元 / retrospective ラベル付き T Issue 群が代替解決される）記載

### 共通

- [x] 設計ドキュメント（ドメインモデル + 論理設計）が `.aidlc/cycles/v2.6.6/design-artifacts/` 配下に作成されている
- [x] AI レビュー（計画 / 設計 / コード / 統合）を codex で実施し全 clean（計画 2R / 設計 3R / コード 2R / 統合 2R / 全 auto_approved）
- [x] shellcheck pass（warning は既存と同型のみ / 本 Unit 追加分由来なし）
- [x] markdownlint pass（`markdown_lint=true` / 0 error）

## SC マッピング（Intent との対応）

- **SC-02**: 既定動作で集約 Issue 起票 = 0、T Issue 起票 = Try 件数（4A の bats で達成）
- **SC-03**: 各 T Issue 本文に 5 セクション非空（4A の bats で達成）
- **SC-04（検証責務のみ）**: Unit 001 で整備された v2.6.5 同等性 fixture を最終 CI で再 pass 確認
- **SC-08**: 既存 5 経路の `resolution_path` 出力が期待値と一致（4B の bats 回帰テストで達成）
- **SC-09**: 新動作経路 2 サブ分岐で `candidates` 配列 ≥ 1（4B の bats 新動作テストで達成）
- **SC-10**: dogfooding (a)(b)(c) 3 条件達成（4C / Operations Phase §1 retrospective で達成）
- **SC-11**: 全 CI green + 後方互換テスト pass（4C / 最終 CI で達成）
- **SC-12**: PR Closes/Comment 4 項目記載（4C / Operations Phase release PR で達成）

## 依存関係

- **実装依存（Unit 定義「依存する Unit」と一致）**: Unit 001（`aggregate_issue_enabled` 仕様 SoT + cap 仕様 SoT + 同等性 fixture）, Unit 002（§1.2.5 セルフレビュー応答からの「構造課題昇格根拠」自動転記）
- **運用上の着手前提（実装依存ではないが 4C の dogfooding 検証フロー実行時に必須）**: Unit 003 完了確認（一次情報三層検証 helper が利用可能な状態であることが、本サイクル振り返りを新フローで自家検証する前提となる）
- **依存される Unit**: なし（最終 Unit）
- **外部依存**: 既存 `retrospective_api_create_issue` / `retrospective_dialog_token_verify` API（シグネチャ不変）, v2.6.4 で導入された `auto_issue_creation` opt-in 基盤（挙動維持 / 干渉しないこと）, GitHub Issue API（gh CLI 経由 / 既存経路）

## 想定リスク・留意点

- **既存 5 経路保護**: predecessor-issue.sh への追加経路が既存経路の判定順序に介入すると後方互換が崩れる。新経路は既存 5 経路すべて 0 件ヒット時のみ評価される後段追加とする。bats 回帰テストで強制
- **dialog token TTL 300 秒**: Try 件数 N が大きい場合に TTL 切れリスク。N ≤ cap（既定 5 件想定）であれば余裕があるが、cap 上限到達ケースでも 300 秒以内完走を NFR で担保
- **bash dynamic scope shadowing**: predecessor-issue.sh の result-out 関数に local 追加する場合、CLAUDE.md「printf -v 系 result-out 関数の local 命名規約」（`_local_<関数省略名>_<名>` プレフィックス）を遵守
- **Bash ツール経由のコマンド置換禁止**: CLAUDE.md「AI エージェント Bash ツール経由の安全パターン」遵守。テスト fixture 作成 / steps/retrospective.md 内 Bash ブロック / predecessor-issue.sh 内部実装ともに `$(...)` / backtick を Bash ツール引数文字列に直書きしない
- **5 セクション非空保証の false positive**: 自動補完で「該当なし」と入る場合の判定基準を明確化（明示的に `該当なし` と書かれた行は非空扱い）
- **dogfooding 検証の循環依存**: 本 Unit 実装の振り返りを本 Unit のフローで検証するため、4A/4B 実装に不具合があると dogfooding 自体が失敗する。Operations Phase 開始前に Construction 内 bats で全 pass を担保

## レビュー観点

### 計画レビュー

- 4A / 4B / 4C のサブ責務分割が Unit 定義と整合しているか
- 完了ゲート 15 項目（4A: 5 / 4B: 5 / 4C: 5）が漏れなく定義されているか
- SC マッピング（SC-02/03/08/09/10/11/12 + SC-04 検証責務）が正しく対応付けされているか
- 既存 5 経路保護の論理保証が計画に明示されているか
- patch リリース条件（後方互換 opt-in / dialog token 維持 / 既存 5 経路不変）が計画でも担保されているか

### 設計レビュー

- ドメインモデルが Unit 004 のスコープ（4A: ループ起票 / 4B: predecessor 互換 + 新経路 / 4C: 検証）に過不足なく対応しているか
- 後方互換（`aggregate_issue_enabled = true` 時の旧動作維持 + 既存 5 経路の `resolution_path` 不変）の論理保証が設計に組み込まれているか
- 5 見出し非空保証ロジックが「明示的に該当なし」を弾かない設計か
- predecessor-issue.sh 新経路の評価タイミング（既存 5 経路すべて 0 件ヒット後）が設計で明確化されているか

### コードレビュー

- shellcheck pass
- result-out 関数の命名規約遵守
- Bash ツール経由のコマンド置換禁止遵守
- 既存 5 経路の判定ロジックに変更が入っていないこと（diff で確認）

### 統合レビュー

- bats テスト全 pass（4A + 4B + 既存 retrospective_*）
- shellcheck pass
- markdownlint pass
- dogfooding 検証は Operations Phase §1 retrospective ステップに委譲（Construction 内では 4A/4B 完了ゲート pass まで）

## 次のアクション

承認後、Phase 1（設計）に着手:

1. ドメインモデル設計 → `.aidlc/cycles/v2.6.6/design-artifacts/domain-models/unit_004_loop_issue_flow_and_validation_domain_model.md`
2. 論理設計 → `.aidlc/cycles/v2.6.6/design-artifacts/logical-designs/unit_004_loop_issue_flow_and_validation_logical_design.md`
3. 設計 AI レビュー（codex）
4. 設計承認
