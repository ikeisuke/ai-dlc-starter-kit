# Unit 001 計画: pr-ops.sh の auto-merge エラー判別精度向上

## 概要

`skills/aidlc/scripts/pr-ops.sh` の `set-auto-merge` 失敗時 `auto_error` grep パターン（line 444）を拡張し、auto-merge 無効リポジトリ + CI pending 状態での `error:unknown` 返却を解消する。GitHub CLI の実エラー文言（半角スペース型 `auto merge is not allowed` および GraphQL ミューテーション名 `enablePullRequestAutoMerge`）にもマッチするようにし、`pr:<N>:error:auto-merge-not-enabled` を返す。

> **Unit 定義のパス記述補正**: Unit 定義 `responsibilities` で `scripts/lib/pr-ops.sh:449` と記載されているが、実体は `skills/aidlc/scripts/pr-ops.sh:444`。`scripts/lib/` 階層は本リポジトリには存在しない（コードレビュー過程の記述ズレ）。本計画では実パスで進め、Unit 履歴に補正事実を記録する。

## 関連 Issue

- #665（[Feedback] pr-ops.sh merge: auto-merge 無効リポジトリで error:unknown が返る）
- 関連: DR-001（fixture 更新トリガーの記録先）

## 責務分離原則

| レイヤ | 役割 | ファイル |
|--------|------|---------|
| 実装 SoT | `auto_error` の grep パターン拡張、エラー分類分岐の維持。**設計フェーズで `pr-ops.sh` 内のローカルヘルパ関数 `_classify_auto_merge_error()` への分離を検討**（Unit 境界内: 同一ファイル内ヘルパ関数化のため、Intent OUT_OF_SCOPE「全エラーパターン網羅再設計」に該当しない） | `skills/aidlc/scripts/pr-ops.sh:444` |
| テスト SoT | エラー分類分岐のユニットテスト追加（gh モック方式は既存準拠） | `skills/aidlc/scripts/tests/test_pr_ops_auto_merge_error_classification.sh`（新規） |
| 履歴 | 実装進捗・DR-001 fixture 更新トリガー記録・パス記述補正記録 | `.aidlc/cycles/v2.5.5/history/construction_unit01.md` |

**ドリフト防止策**:

- `pr-ops.sh:444` の grep パターン拡張は単一行。テスト側で（a）半角スペース型、（b）camelCase 型、（c）既存パターン後方互換、（d）`permission-denied` / `unknown` への誤分類なし、の 4 ケースを担保する。
- 既存テスト `test_pr_ops_merge_skip_checks.sh` の gh モック方式（`GH_STATE_FILE` + `${GH_MOCK_DIR}/gh`）を踏襲して新規テストを追加し、テスト基盤の二重化を避ける。

### スコープ境界の明示（Round 1 指摘 #2 対応）

以下の構造改善は本 Unit 001 のスコープ外（Intent §「除外するもの」: 「`pr-ops.sh` 全エラーパターンの網羅再設計」OUT_OF_SCOPE 該当）として `OUT_OF_SCOPE` 扱いとし、Round 2 以降で defer 自動 Issue 起票（`backlog` + `type:defer-from-review` ラベル）にて記録する:

- **テストヘルパ共通化**: `tests/lib/gh_mock.sh` 等の共通ヘルパ層を定義し、複数テストファイル（`test_pr_ops_merge_skip_checks.sh` / 本 Unit 新規ファイル等）が共通の `gh_mock` インターフェース経由でモック構築する設計改善。**理由**: 単一テストファイル新設のみが本 Unit 責務であり、共通化メリットは複数 Unit にまたがるテストファイル群への展開時に発現する（本 Unit 単体では構造改善コストが効果に見合わない）。Intent OUT_OF_SCOPE 「テスト基盤再設計」は明示記述ないが、判定不能のためスコープ保護ルール（`rules-core.md`）に基づき安全側に倒し、ユーザー確認を経た上で Issue 化する。

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/scripts/pr-ops.sh` | 改修（実装 SoT） | line 444 の `grep -qi "auto-merge is not allowed\|not enabled\|auto_merge"` を `grep -qiE "auto[- ]merge is not allowed\|enablePullRequestAutoMerge\|not enabled\|auto_merge"` に拡張（`-E` 付与で交替パターン対応、case-insensitive 維持） |
| `skills/aidlc/scripts/tests/test_pr_ops_auto_merge_error_classification.sh` | 新規作成（テスト SoT） | gh `pr merge --auto` 失敗時の stderr fixture を 4 種（半角スペース型 / camelCase 型 / 既存ハイフン型 / permission-denied 経路）流し込み、それぞれの分類結果を assert |
| `.aidlc/cycles/v2.5.5/history/construction_unit01.md` | 新規作成 | Unit 001 の進捗履歴・パス記述補正・DR-001 fixture 更新トリガー記録 |

> 編集箇所の正確な文言・差分は **論理設計** で確定する（grep 検証クエリと併せて定義）。本計画では編集対象ファイルと SoT 構造のみを宣言する。

## 実装計画

### Phase 1（設計）

設計成果物として以下を作成する:

- ドメインモデル（`design-artifacts/domain-models/unit_001_pr_ops_auto_merge_error_classification_domain_model.md`）: `auto-merge エラー分類` のドメイン語彙整理（実エラー文言バリアント / 分類結果ラベル / fixture 更新トリガーとの関係）
- 論理設計（`design-artifacts/logical-designs/unit_001_pr_ops_auto_merge_error_classification_logical_design.md`）: `pr-ops.sh:444` の改訂前後文言、**`_classify_auto_merge_error()` ヘルパ関数化の採否判断とインターフェース定義**（Round 1 指摘 #1 対応）、新規テストファイルの構造（テストケース 4 種の入出力定義）、`grep -qiE` への移行による副作用検証クエリ

**ヘルパ関数化の採否方針**（Round 1 指摘 #1 対応）: 論理設計では以下 2 案を比較検討する:

- 案 A（インライン拡張）: 既存 `cmd_merge` 内の `grep` 連鎖をそのまま 1 行拡張（最小変更、テスト追加のみで責務確保）
- 案 B（ヘルパ関数化）: `_classify_auto_merge_error(auto_error) -> classification` をローカル関数として `pr-ops.sh` 内に定義し、`cmd_merge` から呼び出す形式（分類ルールと実行制御の責務分離）

判断基準: 案 B は同一ファイル内のローカルヘルパで Unit 境界内（Intent OUT_OF_SCOPE「全エラーパターン網羅再設計」に該当しない）。今回追加されるパターンが 2 種で、将来追加の見通しがあり、責務分離の効果が見込める場合は案 B を採用。設計フェーズの AI レビューで案 A / B のメリット・デメリットを評価し、最終決定する。

`depth_level=standard` のため Phase 1 はスキップしない。設計レビュー（`reviewing-construction-design`）を 5R 内で実施する。

### Phase 2（実装）

実装順序:

1. `pr-ops.sh:444` 改訂（grep パターン拡張、`-E` 付与）
2. `test_pr_ops_auto_merge_error_classification.sh` 新規作成（4 ケース）
3. テスト実行（既存テストへの regression がないことを併せて確認）
4. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）
5. 履歴記録（変更ファイル / レビュー round / 検証結果 / DR-001 fixture 更新トリガー記述 / パス記述補正）

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| `gh` CLI バージョン更新で auto-merge 実エラー文言が変わる | bats（または `.sh` テスト）の fixture が失敗することで気付ける（DR-001）。失敗時は実エラー文言を fixture に追加し、`grep -qiE` パターンに反映 |
| `grep -qi` → `grep -qiE` 移行による既存パターンの誤マッチ | 既存パターン `auto-merge is not allowed` / `not enabled` / `auto_merge` は basic regex でも extended regex でも同義（`\|` の交替は `grep` 拡張動作に依存）。`-E` 付与時は `\|` を素の `|` に書き換える必要があるため、拡張パターンは `|` 区切りで再定義する |
| `permission-denied` / `unknown` 経路への誤分類 | テストで「permission-denied キーワードを含むエラー」と「いずれにも該当しないエラー」のケースを追加し、誤分類検出 |
| 他のエラーパターン（merge conflict / branch protection 等）の再設計要求 | OUT_OF_SCOPE（Unit 定義「境界」に明記）。Issue 化はしない |

## NFR

- **パフォーマンス**: grep 1 行の交替パターン拡張のため計測対象外
- **セキュリティ**: 実エラー文言は公開済 GitHub CLI 仕様。機密情報の取り扱いに変更なし
- **後方互換**: 既存パターン（`auto-merge is not allowed` / `not enabled` / `auto_merge`）は新パターンに含まれる。既存テスト `test_pr_ops_merge_skip_checks.sh` の `merge_result=error` 経路は `some merge error` 文言で `unknown` に分類される現行挙動を維持する

## 完了条件チェックリスト

### 機能整合

- [ ] `pr-ops.sh:444` の grep パターンに `auto[- ]merge is not allowed` と `enablePullRequestAutoMerge` が含まれている
- [ ] 既存パターン `auto-merge is not allowed` / `not enabled` / `auto_merge` が後方互換として残存
- [ ] `grep -qi` → `grep -qiE` への変更により交替パターンが正しく動作（basic regex 残存なし）

### テスト

- [ ] `test_pr_ops_auto_merge_error_classification.sh` が新規作成され、以下 4 ケースを含む:
  - (a) 半角スペース型 `auto merge is not allowed` → `error:auto-merge-not-enabled`
  - (b) camelCase 型 `enablePullRequestAutoMerge` → `error:auto-merge-not-enabled`
  - (c) 既存ハイフン型 `auto-merge is not allowed` → `error:auto-merge-not-enabled`（後方互換）
  - (d) permission 系（`permission denied`）→ `error:permission-denied`（誤分類なし）
- [ ] `test_pr_ops_merge_skip_checks.sh` を含む既存テストが PASS（regression なし）

### CI 実行エントリへの接続（Round 1 指摘 #3 対応）

- [ ] 新規 `test_pr_ops_auto_merge_error_classification.sh` がローカルから `bash skills/aidlc/scripts/tests/test_pr_ops_auto_merge_error_classification.sh` で直接実行可能（exit 0 / FAIL=0）
- [ ] 新規テストが既存テスト群（`skills/aidlc/scripts/tests/test_pr_ops_*.sh`）と同じディレクトリに配置され、CI ジョブ（`.github/workflows/*` で `skills/aidlc/scripts/tests/` 配下を巡回するエントリ、または `bin/tests/` 経由のエントリ）で自動的に拾われることを確認する。確認手段は以下のいずれか:
  - (a) 既存 CI ワークフローが `skills/aidlc/scripts/tests/test_pr_ops_*.sh` を glob で巡回している場合、新規ファイルは自動接続される（grep で workflow 定義を確認）
  - (b) 個別エントリ列挙の場合は新規ファイル名を該当ワークフローに追加する（**本 Unit 範囲内で対応**、ファイル単位のリスト追記）
- [ ] **bats vs `.sh` 選択理由の明示**: Unit 定義は「bats テスト」と記載するが、本リポジトリの `pr-ops.sh` 関連既存テストは `skills/aidlc/scripts/tests/test_pr_ops_*.sh` の `.sh` テスト形式で運用されている。本計画は既存テスト基盤との整合性を保つため `.sh` 形式を選択する。Intent §「成功基準」Unit 001(b)(c) は「**追加テスト 1 件以上**」と記載しフォーマットを限定していないため、機能検証要件として `.sh` テストでも充足する

### 履歴

- [ ] `.aidlc/cycles/v2.5.5/history/construction_unit01.md` が新規作成され、変更ファイル一覧 / レビュー round / 検証結果 / DR-001 fixture 更新トリガー記述 / Unit 定義パス補正記録が含まれる

### 品質ゲート

- [ ] AI レビュー（`reviewing-construction-design` / `reviewing-construction-code` / `reviewing-construction-integration`）が完了条件（`is_completed()` 単一仕様: 1R clean 特例または直近 round clean）を満たす
- [ ] Codex レビュー（`codex review --base main`）でも追加指摘なし、または defer 化済み
- [ ] markdownlint（`markdown_lint=true` 設定）が変更対象 markdown ファイルで pass する

## 見積もり

- 設計フェーズ: 0.25 日（domain model / logical design / 4 ケース定義）
- 実装フェーズ: 0.25 日（grep 1 行 + テスト 1 ファイル + 既存テスト regression 確認 + レビュー）
- 合計: **0.5 日**（Unit 定義の見積もり「1〜2 時間」と一致）
