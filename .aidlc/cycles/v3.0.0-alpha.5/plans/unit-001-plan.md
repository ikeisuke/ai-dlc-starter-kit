# Unit 001 実装計画: develop size×depth_level 分岐基盤

- **サイクル**: v3.0.0-alpha.5（Phase 4 = develop normal/risky 分岐）
- **Unit**: 001-develop-size-depth-branching
- **depth_level**: standard（Phase 1 設計あり）
- **automation_mode**: semi_auto / review_mode: required
- **関連 Issue**: #736（部分対応 / Phase 4）

## 1. 目的

`skills/aidlc-v3/steps/develop.md` Step 1 の「`size != tiny` 停止ブロック」を解除し、work item の `size`（frontmatter）と cycle の `depth_level`（config.toml）を解決して `docs/v3/data-model.md` §8 マトリクスに基づき後続 Step（設計 Step 2 / レビュー Step 5）の実行可否を決める分岐基盤を実装する。本 Unit 単体で `normal + minimal`（実装 + テストのみ）が end-to-end で完走できる状態を作る。

判定の正本は `docs/v3/data-model.md` §8。Unit 002（design 生成）/ Unit 003（review 実行）が参照する単一の判定結果を提供することが本 Unit のスコープ。

## 2. 実装アプローチ

### 2.1 対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc-v3/steps/develop.md` | Step 1 の `size != tiny` 停止ブロック（現行 行 71-81 付近）を size×depth_level 分岐に置換。depth_level 解決手順・§8 判定・後続 Step スキップ/実行/エラー停止の分岐・designs/reviews 出力先パス解決を追記 |
| `docs/v3/workflow.md` | §3.2 の「risky 一般 = design+risk analysis+test plan」の文言に depth_level 注記を補う。さらに §6.3 の size×depth_level マトリクス表（data-model.md §8 の重複）を「非正本ビュー（正本は data-model.md §8）」と明記する。§3.2 / §6.3 の両方を SoT 注記対象とし、§8 を唯一の正本とする方針を徹底（SoT 二重定義回避 / DR 準拠） |
| `skills/aidlc-v3/scripts/tests/test-develop-flow.sh` | 最小の動作確認のみ（本格的な全マトリクス回帰は Unit 004）。normal+minimal 完走 / risky+minimal 停止の最小ケース確認 |

### 2.2 既存安全境界の利用（局所パース禁止 / #733 P1/P2 再発防止）

- `size` 読取: 既存 `work-item-next.sh` の出力 `next:<id>:<size>:<path>` を利用（develop.md 内で frontmatter を grep/sed しない）。**enum ガード**: `work-item-next.sh` は「validate 済み前提」で size の enum 検証を行わないため、出力された `<size>` を `tiny` / `normal` / `risky` の単純 case で検証し（局所 frontmatter パースは足さない / 出力トークンの case 照合のみ）、enum 外の値は §8 セルへ写像不能として mutation なしでエラー停止する（risky+minimal 停止と同様の副作用なし様式）
- `status` 読取/遷移: 既存 `work-item-status.sh`（`--read` / atomic write）を経由
- frontmatter パース: 局所 grep/sed を develop.md に足さず、既存安全境界スクリプト経由
- `depth_level` 読取: `skills/aidlc/scripts/read-config.sh rules.depth_level.level`（公開 API スクリプト）。**正規化契約**: exit code（未設定=1 / エラー=2）だけでなく stdout の enum 検証を行い、`minimal` / `standard` / `comprehensive` 以外（未設定・読取失敗・無効値すべて）は警告付きで安全側に `standard` へ正規化して停止しない（`skills/aidlc/steps/common/rules-reference.md` の「無効値は standard フォールバック」規定に準拠）

### 2.3 size×depth_level 判定（§8 正本）

| size \ depth_level | minimal | standard | comprehensive |
|---|---|---|---|
| tiny | 実装のみ（非回帰） | 実装のみ（非回帰） | 実装 + 短い理由記録 |
| normal | 実装 + テスト | 実装 + 簡易 design + テスト + review | 実装 + design + リスク分析 + テスト + review |
| risky | **不可（エラー停止）** | design + テスト + review + rollback note | design + リスク分析 + テストプラン + 複数 review + rollback note |

本 Unit が出力する判定結果（後続 Step が参照する単一の真実）。Unit 002/003 が §8 を再解釈せず参照できるよう、bool だけでなく正規化入力と派生要件を含む契約とする:

**正規化入力**:

- `normalized_size`: `tiny` / `normal` / `risky`（`work-item-next.sh` 出力の `<size>` を enum case 検証した結果。enum 外は写像不能としてエラー停止し判定結果を生成しない）
- `normalized_depth_level`: `minimal` / `standard` / `comprehensive`（§2.2 の正規化契約適用後）
- `matrix_case`: §8 セルの識別子（例: `normal_standard` / `risky_comprehensive`）。後続 Step はこのキーで分岐できる

**派生要件（§8 セルから決定）**:

- `design_required`: bool（Step 2 を実行するか）
- `design_mode`: `none` / `simple` / `full`（normal+standard=simple / normal・risky+comprehensive 等=full。Unit 002 が design 本体の詳細度を決める）
- `risk_analysis_required`: bool（design に `## Risk Analysis` を含めるか / comprehensive 系）
- `test_plan_required`: bool（risky+comprehensive で `## Test Plan`）
- `rollback_note_required`: bool（risky 系で `## Rollback Note` 非空）
- `review_required`: bool（Step 5 を実行するか）
- `review_mode`: `none` / `code` / `code_security` / `code_security_design`（§6.2/§8 正本。Unit 003 の routing 入力）
- `reason_record_required`: bool（tiny+comprehensive の短い理由記録）

**出力先・エラー**:

- `designs_path` / `reviews_path`: `<id>-<slug>.md` の解決済みパス（生成自体は Unit 002 / 003）
- `risky_minimal_error`: risky+minimal 時のエラー停止シグナル（mutation なし）

> 注: 上記フィールドはすべて §8 マトリクス 1 セルから機械的に導出される（二重の正本を作らない）。本 Unit は「§8 セル → 派生要件」の写像を 1 箇所に実装し、Unit 002/003 はこの写像結果のみを消費する。

### 2.4 分岐挙動

- **normal + minimal**: design_required=false / review_required=false → Step 2 / Step 5 をスキップし、実装 + テスト + 完了まで end-to-end で進む
- **risky + minimal**: 「risky は minimal 不可」として副作用なしでエラー停止（frontmatter/journal/commit 変更なし。既存 normal/risky 停止ブロックの「副作用なし」様式を踏襲）
- **tiny + comprehensive**: §8 に従い「短い理由記録」を追加（journal への 1 行理由記録等）
- **tiny + {minimal, standard}**: Phase 3 挙動から不変（非回帰）

## 3. 完了条件チェックリスト

Unit 定義「責務」セクションから抽出:

- [ ] develop.md Step 1 の `size != tiny` 停止ブロックが size×depth_level 分岐に置換されている
- [ ] `depth_level` を `.aidlc/config.toml` から解決する（`read-config.sh` 経由）。未設定・読取失敗・**無効値（enum 外）はすべて警告付きで `standard` に正規化**して停止しない
- [ ] size×depth_level 判定ロジックが §8 マトリクスを正本として成果物・レビュー要否を決定し、後続 Step が参照する単一の判定結果を提供する。判定結果は `matrix_case` と派生要件（`design_mode` / `risk_analysis_required` / `test_plan_required` / `rollback_note_required` / `review_mode` 等）を含み、Unit 002/003 が §8 を再解釈しなくてよい契約になっている
- [ ] `normal + minimal`: Step 2 / Step 5 をスキップし実装 + テスト + 完了まで end-to-end で進む
- [ ] `risky + minimal`: エラー停止（mutation なし／副作用なし）
- [ ] `size` enum 外（`tiny`/`normal`/`risky` 以外）は `work-item-next.sh` 出力の case 検証で検出し、mutation なしでエラー停止する（局所 frontmatter パースを足さない）
- [ ] `tiny + comprehensive`: 「短い理由記録」を追加する。`tiny + {minimal, standard}` は Phase 3 挙動から不変（非回帰）
- [ ] `designs/` / `reviews/` 出力先パス（`<id>-<slug>.md`）の解決・配線（生成自体は Unit 002 / 003）
- [ ] frontmatter / status のパースは既存安全境界スクリプト経由（develop.md 内に局所 grep/sed を足さない / #733 P1/P2 再発防止）
- [ ] ドッグフーディング特殊処理（自リポジトリ判定）を埋め込まない
- [ ] workflow.md §3.2 の文言差を §8 正本に整合し、§6.3 のマトリクス表を「非正本ビュー（正本は data-model.md §8）」と明記（§3.2 / §6.3 両方を SoT 注記対象とし二重定義回避）
- [ ] 最小の動作確認テストが緑（normal+minimal 完走 / risky+minimal 停止）。既存 test-develop-flow.sh が緑

## 4. 境界（本 Unit に含まないもの）

- design 成果物の生成・design template（Unit 002）
- レビューのルーティング・実行（Unit 003）
- 全 size×depth_level 組合せの回帰テスト（Unit 004。本 Unit は最小の動作確認のみ）

## 5. リスク・考慮事項

- **NFR 可用性**: depth_level 読取失敗時は `standard` フォールバックで停止しない
- **非回帰**: tiny フローの実行時間・挙動に有意な影響を与えない
- **SoT 整合**: §8（data-model.md）を唯一の正本とし、workflow.md §3.2 は注記参照に留める
