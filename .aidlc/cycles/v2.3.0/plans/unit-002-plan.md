# Unit 002 計画: 汎用復帰判定仕様の策定と Inception への先行適用（#553 解決込み）

## 概要

フェーズインデックスに集約する「現在位置判定ロジック」の共通仕様を策定し、Inception Phase インデックスに先行適用する。コンパクション復帰時にインデックスのみで一意判定できる仕組みの基盤を本 Unit で確立する。副次目的として #553（Inception 後半でのフェーズ誤判定バグ）を根本解決する。

Construction / Operations フェーズへの組み込みは Unit 003 / 004 の責務とし、本 Unit では**共通仕様の定義** + **Inception への先行適用** + **compaction.md/session-continuity.md の整理**のみを行う。

## 方針

- **仕様の正本は `phase-recovery-spec.md` に一本化（判定規則の本文は spec 側）**: `steps/common/phase-recovery-spec.md` を**規範仕様（normative spec）** として新規作成し、判定規則・reason_code・優先順位・ArtifactsState モデル等の本文はすべてこちらに置く。各フェーズインデックスは **"materialized binding"（具象化バインディング）** の位置付けとし、`checkpoint_id` と `input_artifacts` の具体パス（フェーズ固有の具象値）のみを保持し、判定ルール本文は spec への参照に置き換える。Unit 001 で `steps/inception/index.md` が自称していた「現在位置判定の正本」という宣言は本 Unit で「spec への binding であり、判定規則は spec を参照する」形に修正する
- **2段レゾルバ構造（Phase判定とStep判定の責務分離）**: recovery ロジックを以下の2段に分離して設計する:
  - `PhaseResolver`: どのフェーズに復帰するかを決定（`operations > construction > inception` の全体優先順位を適用）
  - `InceptionStepResolver`（phase-local）: Inception フェーズ内でどの step に復帰するかを決定（本 Unit で実装対象。Construction/Operations の phase-local resolver は Unit 003/004 の責務）
  - 依存方向: `compaction.md / session-continuity.md → PhaseResolver → PhaseLocalStepResolver`（一方向、循環なし）
- **暫定ディスパッチャで段階的切替（下流未実装問題の回避）**: `PhaseResolver` は Unit 002 完了時点で「Inception のみ新方式（spec 参照）、Construction/Operations は現行ルート維持」という暫定ディスパッチャとして振る舞う。`compaction.md` からは phase ごとに resolver を選択する形にし、全 phase の spec 一本化は Unit 004 完了後（Unit 006 で検証）まで延期する
- **機械的流し込みの前提を守る**: Unit 001 で確立した「判定チェックポイント骨格」のスキーマ（`checkpoint_id` / `input_artifacts` / `priority_order` / `undecidable_return` / `user_confirmation_required`）の**列構造・行構造**は変更しない。`TBD` セルを実値で埋める際、判定ルール本文は重複記述せず spec への参照コメントで代替する
- **戻り値を `result + diagnostics[]` に分離**: 論理インターフェース契約の戻り値を以下の2フィールドに分離する:
  - `result`: `step_id`（判定成功） / `undecidable:<reason_code>`（blocking failure）
  - `diagnostics[]`: warning 系イベント（`legacy_structure` など）を列挙。`diagnostics` があっても `result` は継続可能
  - これにより `legacy_structure` を blocking な `undecidable` ではなく warning diagnostic として扱い、「警告のみ・強制マイグレーションなし」という NFR と整合させる
- **異常系すべてで自動継続を禁止（blocking 系に限定）**: `result` が `undecidable:<reason_code>` の場合、`automation_mode=semi_auto` でも必ずユーザー確認を要求する。`diagnostics[]` のみ（`legacy_structure` 等の warning）の場合は継続可能だが、警告表示は必須
- **#553 を根本解決**: Inception 後半状態（`units/*.md` 存在 + `inception/progress.md` 未完了）で正しく Inception と判定されることを、`PhaseResolver` の判定ロジックに明示的に盛り込む
- **compaction.md の現在位置判定テーブル削除**: 本 Unit 完了時点で「非正本・暫定」マーカー付きの判定順テーブル（1〜4）を削除し、`PhaseResolver` の暫定ディスパッチャに置き換える。Inception 経由の step 判定は `inception/index.md` の既定ルート + `phase-recovery-spec.md` 参照で一本化
- **後方互換性**: v2.2.x 以前の成果物構造検出時は `diagnostics[]` に `legacy_structure` warning を追加し、警告表示のみ（強制マイグレーションはしない）。`result` 自体は可能な限り判定継続する
- **Construction/Operations 側の扱い**: 本 Unit では phase-local resolver を作らず、`PhaseResolver` 内で「Construction/Operations と判定された場合は現行の成果物ベース判定（Unit 定義ファイルの「実装状態」/`operations/progress.md` 読み込み）に委譲する」暫定ルートを維持する。Unit 003/004 で spec 参照形式に置き換える

### 共通仕様書の構造（`phase-recovery-spec.md`）

| セクション | 内容 |
|-----------|------|
| 1. 仕様の位置付けとスコープ | 規範仕様宣言、各 phase index との関係（binding 定義）、Unit 002 との責務境界 |
| 2. 2段レゾルバ構造 | `PhaseResolver` / `PhaseLocalStepResolver` の責務分離、依存方向、暫定ディスパッチャの扱い |
| 3. 判定の入力モデル（ArtifactsState） | サイクル配下のファイル存在マップ、progress.md パース結果、v2.2.x 旧構造マーカーの一覧化方法 |
| 4. フェーズ判定仕様（PhaseResolver） | `operations > construction > inception` の優先順位ルール、progress.md 完了マークによる補正、#553 ケースの扱い |
| 5. Step 判定仕様（PhaseLocalStepResolver） | Inception の各 `checkpoint_id` → `input_artifacts` の具体値と判定条件（本 Unit で実値化）。Construction/Operations 側は Unit 003/004 で追記する旨の placeholder |
| 6. 戻り値インターフェース契約（result + diagnostics[]） | `result` の有効値（`step_id` / `undecidable:<reason_code>`）、`diagnostics[]` の warning 種別、呼び出し側での扱い方 |
| 7. 異常系4系統の処理仕様 | `missing_file` / `conflict` / `format_error`（blocking）/ `legacy_structure`（warning）の判定条件と分類 |
| 8. ユーザー確認必須性ルール | blocking `undecidable` は `automation_mode=semi_auto` でも自動継続禁止、warning は継続可（警告必須） |
| 9. フェーズインデックスからの参照方法 | 各 phase index が本仕様を参照する際の定型文、`checkpoint_id` 命名規約、materialized binding の書き方 |
| 10. Inception への適用例 | Inception index の判定チェックポイント表に埋める実値とその根拠、spec 参照コメントの書き方 |

### 判定ロジックの設計原則

1. **ファイル存在チェック + 簡易パース**: 複雑な構文解析は避け、ファイルの有無 + 行数カウント + 見出し存在確認で判定
2. **PhaseResolver の優先順位**: Operations 成果物があれば Operations、Construction 成果物があれば Construction、どちらもなければ Inception。ただし #553 特異ケース（下記4）による補正を適用
3. **progress.md 完了マーク補正**: `inception/progress.md` / `operations/progress.md` の完了ステータスを考慮して補正
4. **#553 特異ケース**: `story-artifacts/units/*.md` が存在しても `inception/progress.md` に未完了ステップがあれば Inception と判定（Unit 001 の暫定ガードを本仕様化）
5. **blocking と warning の明確な区別**: 判定継続不能な異常（`missing_file` / `conflict` / `format_error`）は `result=undecidable:<reason_code>` として返す。判定継続可能な警告（`legacy_structure`）は `diagnostics[]` に追加して `result` は通常判定を継続する
6. **戻り値の単値性**: 同一 `ArtifactsState` 入力に対して `result` は常に単一の `step_id` を返す（境界条件の許容幅を持たせない）

### Inception 判定チェックポイントの実値設計

Unit 001 で骨格のみ定義された以下5チェックポイントに、binding 層として必要な最小限の情報（具体的な `input_artifacts` パスと spec 参照トークン）のみを埋める。`priority_order` / `undecidable_return` / `user_confirmation_required` 列はポリシー値そのものを index に再複製せず、spec への参照トークン形式（例: `spec§4`, `spec§6`, `spec§8`）とする。これにより binding 層は「具象パスと spec への参照」だけを持つ構造となり、ポリシー変更は spec 側の 1 箇所のみで反映できる:

| checkpoint_id | input_artifacts（具象パス） | priority_order | undecidable_return | user_confirmation_required |
|---------------|----------------------|----------------|--------------------|----------------------------|
| `inception.setup_done` | `.aidlc/cycles/{{CYCLE}}/inception/progress.md`, `.aidlc/cycles/{{CYCLE}}/` | `spec§4` | `spec§6` | `spec§8` |
| `inception.preparation_done` | `inception/progress.md`（ステップ2完了マーク参照） | `spec§4` | `spec§6` | `spec§8` |
| `inception.intent_done` | `inception/intent.md`, `inception/progress.md`（ステップ3完了マーク） | `spec§4` | `spec§6` | `spec§8` |
| `inception.units_done` | `story-artifacts/units/*.md`, `story-artifacts/user_stories.md`, `inception/progress.md`（ステップ4完了マーク） | `spec§4` | `spec§6` | `spec§8` |
| `inception.completion_done` | `history/inception.md`, `inception/decisions.md`（任意）, `inception/progress.md`（全完了） | `spec§4` | `spec§6` | `spec§8` |

判定規則の本文（「左記すべて存在すれば completion_done と判定」等のポリシー記述）は `phase-recovery-spec.md` §5 にまとめて記載し、`inception/index.md` には重複記述しない。

**04 → 05 境界の単値化**: `inception.units_done` と `inception.completion_done` の境界は `progress.md` の「完了処理」セクションの完了マーク + `history/inception.md` の存在の**両方**で判定する。一方のみ存在する場合は前段（`units_done`）と判定することで単値性を保つ（詳細ルールは spec §5 に記載）。

※ 設計ステップで上記想定を詳細化し、論理設計ドキュメントに確定版を記載する。

### 異常系4系統の判定条件（暫定案）

| reason_code | 分類 | 検出条件 | 戻り値への反映 | 期待動作 |
|------------|------|---------|--------------|---------|
| `missing_file` | blocking | checkpoint の必須 `input_artifacts` のいずれかが存在しない | `result=undecidable:missing_file` | ユーザー確認 + 再開点の提示（`semi_auto` でも停止） |
| `conflict` | blocking | 複数フェーズの進捗源が同時に未完了状態で存在（例: inception/progress.md 未完了 + operations/progress.md 存在） | `result=undecidable:conflict` | ユーザー確認 + 優先順位ルール表示（`semi_auto` でも停止） |
| `format_error` | blocking | progress.md のテーブル構造パース失敗、見出し欠落、異常な行数 | `result=undecidable:format_error` | ユーザー確認 + 修復手順の案内（`semi_auto` でも停止） |
| `legacy_structure` | warning | `session-state.md` 残存、v2.2.x 以前の旧ファイル構造検出 | `diagnostics[].push({type: "legacy_structure", ...})`、`result` は通常判定継続 | 警告表示 + マイグレーション案内（強制はしない。`result` が有効なら継続可） |

**排他性**: 判定順は `blocking > warning` の優先順位で評価し、blocking 検出時は warning 評価を継続しつつ `result=undecidable:<reason_code>` を優先する。blocking が複数同時検出された場合は `missing_file > conflict > format_error` の順で優先（設計段階で検証）。

## 対象ファイル

| # | ファイル | 操作 | 主な変更内容 |
|---|---------|------|-------------|
| 1 | `skills/aidlc/steps/common/phase-recovery-spec.md` | **新規** | 共通判定仕様書（規範仕様）。上記10セクションを収録。判定規則の本文はすべて本ファイルに置く |
| 2 | `skills/aidlc/steps/inception/index.md` | 更新 | (a) セクション先頭の「現在位置判定と分岐ロジックの正本」宣言を「`phase-recovery-spec.md` の materialized binding」形式に修正。(b) 判定チェックポイント骨格（セクション3）の `TBD` セルを実値で埋める（`input_artifacts` にはパスを記載、判定ルール本文は spec 参照コメントで代替）。(c) 論理インターフェース契約（セクション3.1）を `result + diagnostics[]` 分離形式に更新し、`user_confirmation_required` の決定ルールを `phase-recovery-spec.md` 参照形式に変更 |
| 3 | `skills/aidlc/steps/common/compaction.md` | 更新 | 「復帰フローの確認手順」の判定順テーブル（判定順1〜4）を削除し、`PhaseResolver` の暫定ディスパッチャ記述に置き換える（Inception は新方式、Construction/Operations は現行ルート維持）。Inception 復帰時の手順を `inception/index.md` + `phase-recovery-spec.md` 参照形式に更新。`automation_mode` 復元手順は存続 |
| 4 | `skills/aidlc/steps/common/session-continuity.md` | 更新 | 新フロー（2段レゾルバ構造）に合わせて記述を更新。フェーズ別進捗源は Inception のみ「`inception/index.md` + `inception/progress.md` + `phase-recovery-spec.md`」に変更、Construction/Operations は Unit 003/004 で更新予定のため現状維持 + コメント追記 |

## 設計成果物（Phase 1）

- `.aidlc/cycles/v2.3.0/design-artifacts/domain-models/unit_002_universal_recovery_base_domain_model.md`
- `.aidlc/cycles/v2.3.0/design-artifacts/logical-designs/unit_002_universal_recovery_base_logical_design.md`

## 実装記録（Phase 2）

- `.aidlc/cycles/v2.3.0/construction/units/unit_002_universal_recovery_base_implementation.md`

## 検証手順

### 正常系検証（Inception フェーズ）

代表的な進行中状態で復帰判定が期待通りに動作することを確認する。検証方法は**静的検証**（仕様書の判定条件テーブルとサンプル入力の照合）を主とし、実サイクルでの対話フロー再実行は行わない。

**検証ケース**（各ケースは単一 `step_id` を期待値として固定する）:

| # | シナリオ | 期待される step_id |
|---|---------|------------------|
| 1 | サイクルディレクトリ + 空 progress.md のみ（intent.md なし） | `inception.01-setup` |
| 2 | Intent 完了時点（intent.md 存在、user_stories.md なし、units/ 空） | `inception.03-intent` |
| 3 | ストーリー完了時点（user_stories.md 存在、units/ 空） | `inception.04-stories-units` |
| 4a | Unit 定義作成済み、progress.md「完了処理」未着手（units/*.md 存在、history/inception.md なし） | `inception.04-stories-units` |
| 4b | Unit 定義完了・完了処理進行中（units/*.md 存在、progress.md「完了処理」行が「進行中」、history/inception.md なし） | `inception.05-completion` |
| 5 | 完了処理中盤（history/inception.md 存在、progress.md 一部未完了） | `inception.05-completion` |

**手順**: 本 Unit で作成する検証用スクリプト（または手順書）で各ケースを `.aidlc/cycles/vTEST-*` ディレクトリに再現し、`phase-recovery-spec.md` の判定条件に照らして期待 `step_id` が導出されることを確認。

### 異常系検証（Inception フェーズ・4系統）

| # | reason_code | 分類 | 再現方法 | 期待動作 |
|---|------------|------|---------|---------|
| 1 | `missing_file` | blocking | `inception/progress.md` を削除 | `result=undecidable:missing_file`、ユーザー確認フロー起動 |
| 2 | `conflict` | blocking | `inception/progress.md` 未完了 + `operations/progress.md` 存在 | `result=undecidable:conflict`、優先順位ルール表示 |
| 3 | `format_error` | blocking | `inception/progress.md` を空ファイルまたは見出し欠落に改変 | `result=undecidable:format_error`、修復手順の案内 |
| 4 | `legacy_structure` | warning | `.aidlc/cycles/{{CYCLE}}/session-state.md` を作成 | `result` は通常判定継続、`diagnostics[]` に `legacy_structure` 追加、警告表示のみ |

**重要**:
- **blocking（ケース1〜3）**: `automation_mode=semi_auto` でも自動継続せずユーザー確認を要求する
- **warning（ケース4）**: `automation_mode=semi_auto` では警告表示後も判定継続可。ただし `result` が blocking 条件にも該当する場合は blocking が優先される

### #553 根本解決検証

正常系 4a/4b と同じ境界条件（progress.md「完了処理」セクションの完了マーク + `history/inception.md` 存在）に統合し、各シナリオで単一の `step_id` を期待値として固定する:

| シナリオ | progress.md 状態 | history/inception.md | v2.2.3 の挙動 | v2.3.0 Unit 002 実装後の期待挙動 |
|---------|----------------|--------------------|------------|-------------------------------|
| 再現シナリオ1a: PRFAQ 未着手（units/*.md 存在、progress.md「完了処理」行が「未着手」、history/inception.md なし） | 「完了処理」未着手 | なし | Construction と誤判定 | `PhaseResolver` → Inception、`InceptionStepResolver` → `inception.04-stories-units`（単値） |
| 再現シナリオ1b: PRFAQ 着手済み・完了処理進行中（units/*.md 存在、progress.md「完了処理」行が「進行中」、history/inception.md なし） | 「完了処理」進行中 | なし | Construction と誤判定 | `PhaseResolver` → Inception、`InceptionStepResolver` → `inception.05-completion`（単値） |
| 再現シナリオ2: PRFAQ 完了・完了処理完了（units/*.md 存在、progress.md 全完了、history/inception.md 存在） | 全完了 | 存在 | Construction と判定（正しい） | `PhaseResolver` → Construction（Inception 完了に伴い正常遷移） |

**対比記録**: v2.2.3 タグ（`d88b0074`）の判定ロジックを手動で適用した場合に再現シナリオ1a/1b 両方で Construction と誤判定されることを**仕様書内に明記**（実機再実行は不要、仕様レベルでの対比記録）。

### compaction.md リファクタ検証

- 判定順テーブル（判定順1〜4）が完全に削除されていること（grep で確認）
- `automation_mode` 復元手順（手順1〜5）が変更されていないこと（diff で確認）
- 新フローへの案内が追加され、`inception/index.md` + `phase-recovery-spec.md` への参照リンクが機能していること

### session-continuity.md 更新検証

- フェーズ別進捗源テーブルの Inception 行が更新され、`index.md` 経由の復帰を指示していること
- Construction/Operations 行は暫定のまま維持（Unit 003/004 で更新予定のコメント付き）
- 既存の責務（コンパクション復帰時の `compaction.md` 読み込み指示）が維持されていること

## 完了条件チェックリスト

- [ ] **【共通仕様策定】** `steps/common/phase-recovery-spec.md` が新規作成され、以下10セクションを含む:
  - (1) 仕様の位置付けとスコープ（規範仕様宣言、各 phase index との binding 関係）
  - (2) 2段レゾルバ構造（`PhaseResolver` / `PhaseLocalStepResolver` の責務分離）
  - (3) 判定の入力モデル（ArtifactsState）
  - (4) フェーズ判定仕様（PhaseResolver、`operations > construction > inception` + #553 補正）
  - (5) Step 判定仕様（Inception は実値、Construction/Operations は Unit 003/004 placeholder）
  - (6) 戻り値インターフェース契約（`result + diagnostics[]` 分離）
  - (7) 異常系4系統の処理仕様（`missing_file`/`conflict`/`format_error` は blocking、`legacy_structure` は warning）
  - (8) ユーザー確認必須性ルール（blocking は `semi_auto` でも停止、warning は継続可）
  - (9) フェーズインデックスからの参照方法と materialized binding の書き方
  - (10) Inception への適用例
- [ ] **【正本の一本化】** `phase-recovery-spec.md` が判定規則の本文を持ち、`steps/inception/index.md` の先頭宣言が「spec の materialized binding」形式に修正されている（「判定の正本」を自称する記述が削除または変更されている）
- [ ] **【2段レゾルバ構造】** 仕様書内で `PhaseResolver` と `PhaseLocalStepResolver` の責務分離と依存方向が明記されている
- [ ] **【暫定ディスパッチャ】** `compaction.md` の記述で「Inception は新方式、Construction/Operations は現行ルート維持」の暫定ディスパッチャが明示されている
- [ ] **【Inception 適用 - binding 層】** `steps/inception/index.md` の判定チェックポイント表（セクション3）の全 `TBD` セルが埋まっている。ただし binding 層の原則に従い、`input_artifacts` 列は具象パスを記載、`priority_order` / `undecidable_return` / `user_confirmation_required` の3列はポリシー値ではなく **spec 参照トークン形式**（例: `spec§4` / `spec§6` / `spec§8`）で記載されている。判定ルール本文は index 側に重複記述していない
- [ ] **【骨格スキーマ不変】** `steps/inception/index.md` のチェックポイント表の列構造・行構造（5チェックポイント）が Unit 001 から変更されていない
- [ ] **【論理インターフェース契約更新】** `steps/inception/index.md` セクション3.1 の論理インターフェース契約が `result + diagnostics[]` 分離形式に更新され、`phase-recovery-spec.md` 参照形式に変更されている
- [ ] **【04/05 境界の単値化】** `inception.04-stories-units` と `inception.05-completion` の境界が progress.md 「完了処理」セクション + `history/inception.md` 存在の両方で判定される形で仕様化され、一方のみ存在する場合は単一の `step_id` に固定されている
- [ ] **【正常系検証】** Inception の代表6ケース（1/2/3/4a/4b/5）すべてで**単一の期待 step_id** が導出されることを検証記録済み（許容幅なし）
- [ ] **【異常系4系統検証】** blocking 3系統（`missing_file` / `conflict` / `format_error`）で `result=undecidable:<reason_code>` が返り `automation_mode=semi_auto` でも自動継続しないこと、warning 1系統（`legacy_structure`）で `diagnostics[]` に追加されるが `result` は継続可能であることが検証記録されている
- [ ] **【#553 根本解決】** 再現シナリオ1a（PRFAQ 未着手、完了処理未着手）で `inception.04-stories-units`、再現シナリオ1b（完了処理進行中）で `inception.05-completion`、再現シナリオ2（全完了）で Construction と、それぞれ**単一の値**に判定されることが仕様書内に明記されている
- [ ] **【#553 対比記録】** v2.2.3 タグ（`d88b0074`）の判定ロジックを手動適用した場合に再現シナリオ1a/1b 両方で Construction と誤判定されることが仕様書内に対比記録されている
- [ ] **【compaction.md リファクタ】** 「復帰フローの確認手順」の判定順テーブル（判定順1〜4）が完全削除され、`PhaseResolver` 暫定ディスパッチャ記述に置き換わっている
- [ ] **【compaction.md 存続部分】** `automation_mode` 復元手順（手順1〜5）が変更されていない（diff 確認）
- [ ] **【session-continuity.md 更新】** Inception 行が 2段レゾルバ構造の新フローに更新されている。Construction/Operations 行は暫定維持のコメント付き
- [ ] **【後方互換性】** v2.2.x 以前の成果物構造検出時は `diagnostics[]` に `legacy_structure` warning が追加されるのみで `result` 判定は継続可能（強制マイグレーションなし）であることが仕様書に明記されている
- [ ] **【Unit 003/004 接続点】** 共通仕様書の §5（Step 判定仕様）に Construction/Operations の placeholder セクションが存在し、Unit 003/004 で埋める旨が明記されている
- [ ] **【全チェックポイントの非正本マーカー撤去】** compaction.md の「非正本・暫定」マーカー付きテーブルに残された参照が本 Unit 完了時点ですべて解消されている

## 依存関係

### 前提 Unit

- Unit 001（Inception インデックスファイルの骨格が前提）

### 本 Unit を依存元とする Unit

- Unit 003（Construction インデックスへの判定仕様組み込み）
- Unit 004（Operations インデックスへの判定仕様組み込み）

## 関連 Issue

- #519: コンテキスト圧縮メイン Issue
- #553: コンパクション時の Inception 後半フェーズ誤判定

## リスクと留意事項

- **共通仕様の過度な抽象化**: 仕様書は「機械的流し込み」が前提のため、抽象度を上げすぎると Unit 003/004 での組み込みが難しくなる。逆に Inception 寄りすぎると他フェーズに流用できない。設計ステップで抽象度のバランスを議論する
- **異常系4系統の網羅性**: 4系統の判定条件が互いに排他的であることを保証する必要がある。設計段階で判定優先順位（`non_recoverable > transient > recoverable` のような）を明確化する
- **compaction.md からの判定テーブル削除時の互換性**: 旧判定テーブルを参照していた既存ドキュメント（もしあれば）への影響を grep で確認する
- **検証コストの抑制**: 実サイクルでの対話フロー再実行は本 Unit では行わず、仕様書＋サンプル入力による静的検証のみとする。実地回帰は Unit 006 で一括実施
- **Unit 001 との責務境界**: Unit 001 で確立した骨格スキーマ（列構造・行構造）は本 Unit で変更しない。変更が必要になった場合は Unit 001 計画への手戻りとなるため、設計段階でスキーマ適合性を確認する
