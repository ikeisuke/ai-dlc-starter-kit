# Unit 003 計画: 事実テーブル先抽出ステップ + 推定値検出ガード（#634 絞込）

## 概要

振り返り作業時の推測値混入バグを構造的に予防する。`skills/aidlc/steps/operations/04-completion.md` §1 の「§1.1 KPT テンプレ」と「§1.2 主因切り分け」の間に「事実テーブル先抽出ステップ」（§1.x）を新設し、`skills/aidlc/steps/common/review-flow.md` に「推定値検出ガード」を追加する。3 層検証 skill 化（jsonl 解析等）は OUT_OF_SCOPE（#652）として切り出し済。

## 関連 Issue

- #634（振り返りプロセスの構造的改善 - 取り込み範囲）
- 関連（OUT_OF_SCOPE 切出し）: #652（3層検証 skill 化）

## 変更操作の境界（Unit 001 不変条件保持 / 設計レビュー Round 1 指摘 #3 反映）

| 操作種別 | 許容/禁止 | 適用対象 |
|---------|---------|---------|
| 新規セクション追加（既存セクションの間に挿入） | **許容** | §1.x（事実テーブル先抽出ステップ）/ review-flow.md「推定値検出ガード」 |
| 既存セクション内の文言置換 | **禁止** | §1.0.5 / §1.1 / §1.2 / §1.5 およびすべての既存セクション |
| 既存セクション削除 | **禁止** | 同上 |
| 既存セクションの再採番（節番号変更） | **禁止** | 既存節番号を変えない（§1.x は新規追加のみ、既存 §1.1〜§1.6 は不変） |
| 既存定義の差し替え（特に retrospective-issue.sh の関数定義） | **禁止** | `retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify` / `retrospective_issue_create` |

完了処理ステップで上記境界の遵守を grep / awk ベースで検証する（AC-U003-RETRO-GUARD-IMMUTABLE-1〜3）。

## Unit 001 申し送り受け入れ条件の取り込み

`.aidlc/cycles/v2.5.3/plans/unit-001-plan.md` の「申し送り対象計画ファイル + 受け入れ条件 ID」表に従い、本 Unit の完了条件チェックリストに以下を含める:

- **AC-U003-RETRO-GUARD-IMMUTABLE-1**: 04-completion.md §1.0.5（対話必須ガード）の「禁止事項リスト」「必須事項リスト」「抽象操作レベル禁止表」「実装マッピング表」が改修後も保持されていること
- **AC-U003-RETRO-GUARD-IMMUTABLE-2**: §1.5 Step 4 起票直前の AskUserQuestion 必須化記述および `retrospective_dialog_token_record_response` 呼出手順が改修後も保持されていること
- **AC-U003-RETRO-GUARD-IMMUTABLE-3**: `retrospective_dialog_token_verify` 関数の存在と `retrospective_issue_create` からの呼び出し関係が改修後も保持されていること

本 Unit では §1.0.5 / §1.5 Step 4 / `retrospective-issue.sh` の verify/record_response 関数定義および呼出関係を **直接編集しない**。§1.x として「事実テーブル先抽出ステップ」を §1.1 と §1.2 の間に **追加挿入** することで、Unit 001 で確立した不変条件を破壊せずに新規セクションを併設する。

## 変更対象ファイル

| ファイル | 操作 | 説明 |
|---------|------|------|
| `skills/aidlc/steps/operations/04-completion.md` | 改修（追加） | §1.1 KPT テンプレと §1.2 主因切り分けの間に「§1.x 事実テーブル先抽出ステップ」を新設。§1.0.5 / §1.5 / その他既存セクションは編集しない（Unit 001 不変条件保持） |
| `skills/aidlc/steps/common/review-flow.md` | 改修（追加） | 末尾または「指摘対応判断フロー」の直後に「推定値検出ガード」セクション追加。検出マーカー / 数値隣接判定 / 根拠リンク併記例外 / 許容例・非許容例 2 件以上併記 |
| `.aidlc/cycles/v2.5.3/history/construction_unit03.md` | 新規作成 | Unit 003 の進捗履歴 |

## 実装計画

### Phase 1（設計）

設計成果物:

- ドメインモデル（`design-artifacts/domain-models/unit_003_fact_table_and_estimate_guard_domain_model.md`）: 事実テーブル / 推定値検出ガードのドメイン語彙
- 論理設計（`design-artifacts/logical-designs/unit_003_fact_table_and_estimate_guard_logical_design.md`）: §1.x 構造 / 推定値検出ガードの判定ルール / 許容例・非許容例の境界

`depth_level=standard` のため Phase 1 はスキップしない。

### Phase 2（実装）

#### 1. `skills/aidlc/steps/operations/04-completion.md` §1.x 追加

- §1.1 KPT テンプレと §1.2 主因切り分けの間に「§1.x 事実テーブル先抽出ステップ」（仮: §1.1.5 または §1.x という相対参照）を新設
- 事実テーブル先抽出ステップの内容:
  - **目的**: KPT 記入後・主因切り分けの**前**に「事実」を構造化して抽出し、主因分析・Try 立案・mirror 送信判断における推測値混入を予防する（KPT 自体は §1.1 で記入済み、本ステップでは事実裏付けを構造化）。設計レビュー Round 1 指摘 #1 反映
  - **読み込み対象 source（最低 3 つ）**:
    - (a) `.aidlc/cycles/{{CYCLE}}/inception/decisions.md`
    - (b) `.aidlc/cycles/{{CYCLE}}/construction/units/*-review-summary.md`
    - (c) `.aidlc/cycles/{{CYCLE}}/history/*.md`
  - **事実テーブル形式**: markdown 表形式で展開
    - 列: `項目` / `値` / `出典`
    - 行例: DR 件数 / review round 数 / 指摘件数 / defer 件数 / 時系列イベント
  - **手順記述レベル**: AI エージェントが上記 source を Read し、事実テーブルを markdown で展開する手順を §1.x として明示
  - **実装スクリプト化なし**: 自動抽出ツール化は #652 として OUT_OF_SCOPE
- §1.0.5 / §1.5 / その他既存セクションは触らない（AC-U003-RETRO-GUARD-IMMUTABLE-1〜3 保持）

#### 2. `skills/aidlc/steps/common/review-flow.md` 推定値検出ガード追加

- 「指摘対応判断フロー」の直後または末尾に「推定値検出ガード」セクションを追加
- セクション内容:
  - **適用スコープ（明文化 / 設計レビュー Round 1 指摘 #3 反映）**: 本ガードは振り返り Issue 本文（retrospective: ラベル付き Issue）および振り返り作業時の KPT / 主因切り分け / Try / mirror 候補本文に適用する。それ以外のレビュー文脈（コードレビュー指摘内容 / Plan / Design / 統合レビューサマリ等）は適用対象外。レビューワーは適用スコープ判定を「対象が振り返り文脈か」で行う
  - **判定原則（最重要 / Intent 境界条件直接引用 / 設計レビュー Round 1 指摘 #4 反映）**: 「**一次情報を Read 済みでも、根拠リンクや出典参照が併記されていない近似語付き数値は flag する**。一次情報の有無は flag 判定に使わず、Intent 上で明示された『根拠リンク併記』のみが許容条件」（Intent v2.5.3 §「推定値検出ガードの境界条件」、user_stories.md ストーリー 3 受け入れ基準）。本原則は「判定原則」セクションとして検出マーカー / 数値隣接判定の前に独立明記する
  - **検出マーカー**: `約`, `およそ`, `approximately`, `approx.`, `推定`, `〜くらい`, `〜程度`
  - **数値隣接判定**: マーカーの直前または直後 5 文字以内に算用数字（`[0-9]`）または日本語数字（一〜十、百、千、万）が出現する場合のみ flag
  - **根拠リンク併記時の例外（許容条件）**: 同一段落内に PR/Commit/Issue リンク（`#NNN` / `https://github.com/...` / `<sha>` 等）または対象ファイルパス参照（`` `path/to/file.md` ``）があり、数値の出典が明示されている場合は flag しない
  - **flag 出力フォーマット**: AI レビューワーの応答に「指摘 #N - 推定値混入: `<該当箇所>`」の形式の文言が必ず 1 件以上含まれる
  - **許容例（flag されない）2 件以上併記**:
    - 「約束された動作」「推定エンジン」（数値を伴わない概念用法）
    - 「DR-001〜DR-010（約 10 件、`requirements/decisions.md` 参照）」（根拠リンク併記）
    - コードブロック内の数値（`approximately = 5` のような変数定義）
  - **非許容例（flag される）2 件以上併記**:
    - 「DR-001〜DR-035 の 35 件（推定）」
    - 「約 50 round」「approximately 130 件」「推定 35 件」
    - 「DR-001〜DR-010（**約 10 件**）」（根拠リンク併記なし）
- 実装方針: 自然言語の判定ルール記述で十分（機械実装の regex は本 Unit では確定しない）

#### 3. 履歴記録

- `.aidlc/cycles/v2.5.3/history/construction_unit03.md` を新規作成し、`/write-history` skill で進捗を逐次追記
- Unit 完了直前に Unit 002 で導入した `--mode unit-complete-short-note` を本 Unit に適用（self-apply）

### 実装順序

1. `04-completion.md` §1.x（事実テーブル先抽出ステップ）追加
2. `review-flow.md` 推定値検出ガード追加
3. AC-U003-RETRO-GUARD-IMMUTABLE-1〜3 不変条件の grep 確認
4. AI レビュー実施
5. self-apply（Unit 002 の short note モード適用）+ 履歴記録

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| `04-completion.md` §1.0.5 が改修により希釈される | 完了処理ステップで `awk '/^#### 1\.0\.5/,/^#### 1\.1/' skills/aidlc/steps/operations/04-completion.md` で §1.0.5 範囲を抽出し、4 要素（禁止事項リスト / 必須事項リスト / 抽象操作レベル禁止表 / 実装マッピング表）の見出し・キーワード（`禁止事項` / `必須事項` / `抽象操作` / `実装マッピング`）が存在することを確認（AC-U003-RETRO-GUARD-IMMUTABLE-1）。設計レビュー Round 1 指摘 #2 反映 |
| `04-completion.md` §1.5 Step 4 の `record_response` 呼出記述が消失 | 完了処理ステップで `grep "retrospective_dialog_token_record_response" skills/aidlc/steps/operations/04-completion.md` を実行し、1 件以上ヒットすることを確認（AC-U003-RETRO-GUARD-IMMUTABLE-2） |
| `retrospective-issue.sh` の `retrospective_dialog_token_verify` 呼出が消失 | 完了処理ステップで `grep "retrospective_dialog_token_verify" skills/aidlc/scripts/lib/retrospective-issue.sh` を実行し、関数定義と `retrospective_issue_create` からの呼出が両方ヒットすることを確認（AC-U003-RETRO-GUARD-IMMUTABLE-3） |
| `review-flow.md` 500 行制限超過 | 現状 247 行 + 数十行追加で 300 行未満に収まる |
| 推定値検出ガードの誤検知 | 許容例・非許容例を 2 件以上併記して境界を明確化 |

## NFR

- **パフォーマンス**: ドキュメント / 手順改訂のみのため、ランタイム性能影響なし
- **セキュリティ**: 機密情報の取り扱いに変更なし
- **後方互換**: 既存の振り返りフロー / review-flow / セミオートゲート判定を破壊しない。Unit 001 で確立した対話必須ガードを保持
- **可用性**: 影響なし

## 完了条件チェックリスト

### 04-completion.md §1.x 追加

- [x] §1.1 KPT テンプレと §1.2 主因切り分けの間に「事実テーブル先抽出ステップ」が追加されている（`grep -E "事実テーブル|fact[- _]table" skills/aidlc/steps/operations/04-completion.md` で 1 件以上）
- [x] 事実テーブル先抽出ステップに最低 3 source（`decisions.md` / `construction/units/*-review-summary.md` / `history/*.md`）が「読み込み対象」として明示されている
- [x] 事実テーブル形式（markdown 表）が手順記述レベルで定義されている

### review-flow.md 推定値検出ガード追加

- [x] `skills/aidlc/steps/common/review-flow.md` に「推定値検出ガード」セクションが追加されている
- [x] **適用スコープ**（振り返り文脈のみ適用、他レビュー文脈は対象外）が明文化されている
- [x] **判定原則**（一次情報 Read 済みでも根拠リンク併記がなければ flag）が独立セクションとして固定記載されている
- [x] 検出マーカー（`約` / `およそ` / `approximately` / `approx.` / `推定` / `〜くらい` / `〜程度`）が記述されている
- [x] 数値隣接判定（直前または直後 5 文字以内に算用数字または日本語数字）が記述されている
- [x] 根拠リンク併記時の例外が記述されている（PR/Commit/Issue リンクまたはファイルパス参照）
- [x] 許容例 2 件以上 + 非許容例 2 件以上が併記されている
- [x] flag 出力フォーマット「指摘 #N - 推定値混入: `<該当箇所>`」が記述されている
- [x] review-flow.md 全体行数が 500 行制限を超えていない

### Unit 001 申し送り受け入れ条件（不変条件保持）

- [x] **AC-U003-RETRO-GUARD-IMMUTABLE-1**: §1.0.5 の禁止事項リスト / 必須事項リスト / 抽象操作レベル禁止表 / 実装マッピング表が改修後も保持されている（grep 確認）
- [x] **AC-U003-RETRO-GUARD-IMMUTABLE-2**: §1.5 Step 4 起票直前の AskUserQuestion 必須化記述および `retrospective_dialog_token_record_response` 呼出手順が改修後も保持されている（grep 確認）
- [x] **AC-U003-RETRO-GUARD-IMMUTABLE-3**: `retrospective_dialog_token_verify` 関数定義と `retrospective_issue_create` からの呼出関係が改修後も保持されている（grep 確認）

### 検証 + 履歴

- [x] AI レビューワー（Codex）に対し、入力例 A「DR-001〜DR-035 の 35 件（推定）」が flag されることを review-flow ドライランで確認
- [x] AI レビューワーに対し、入力例 B-flag「DR-001〜DR-010（**約 10 件**）」が flag されることを確認
- [x] AI レビューワーに対し、入力例 B-allow「DR-001〜DR-010（約 10 件、`requirements/decisions.md` 参照）」が flag されないことを確認
- [x] `.aidlc/cycles/v2.5.3/history/construction_unit03.md` に対話必須ガード強化反映の記録（Unit 002 short note モードで self-apply）が追記されている（完了処理ステップで実施完了）

### 品質ゲート

- [x] markdownlint が pass する
- [x] AI レビュー（design / code / integration）が完了条件（最後 2 round 連続 clean）を満たす（design 3R / code 2R / integration 3R すべて連続 clean 達成）
- [x] Codex レビューでも追加指摘なし、または defer 化済み（全 6 件指摘 → 全件修正済み）

## 見積もり

- 設計フェーズ: 0.5 日
- 実装フェーズ: 1 日（docs 改訂 / AC-U003-* 不変条件確認 / レビュー）
- 合計: **1.5 日**
