# Unit 002 実装計画: レビューツール設定への self 正式統合と後方互換シム（#611）

## 対象

- Unit 定義: `.aidlc/cycles/v2.4.3/story-artifacts/units/002-review-tools-self-integration.md`
- 対象 Issue: #611（Closes 対象。サイクル PR でクローズ）
- **章番号の統一方針**: Unit 定義「責務」では `§3 設定 / §4 ToolSelection / §5 PathSelection / §6 FallbackPolicyResolution` と表記しているが、現行 `review-routing.md` は `## 2. 設定` / `## 4. ツール選択` / `## 5. 処理パス決定` / `## 6. エラーフォールバック対応表` の章番号構成（§2 / §4 / §5 / §6）。本計画書は **現行ファイル章番号に統一** し、Unit 定義の §3 表記は §2 に対応するものとして読み替える
- 主対象ファイル:
  - `skills/aidlc/steps/common/review-routing.md`(§2 設定 / §4 ToolSelection / §5 PathSelection / §6 FallbackPolicyResolution / §7 呼び出し形式)
  - `skills/aidlc/steps/common/review-flow.md`(パス 1 / パス 2 / Codex セッション管理 / フォールバック関連記述)
  - `skills/aidlc/config/defaults.toml`(現状維持の方針確認 + 注釈追加要否)
- 整合確認のみ（変更しない可能性が高い）:
  - `skills/aidlc/scripts/read-config.sh`(型・許容値の検証ロジック有無、本 Unit では振る舞い変更なしを確認)
  - `skills/aidlc/steps/common/review-flow-reference.md`(パス 2 / フォールバック表現の整合)
  - レビュー対象スキル群（`reviewing-construction-*` / `reviewing-inception-*` / `reviewing-operations-*`）の本体（ToolResolution の入口で吸収するため変更不要）

## スコープ

Issue #611 の最小実装方針（Unit 定義「責務」 / Intent §「成功基準」#611 由来）に整合させる:

- **`"self"` の正式統合**: `[rules.reviewing].tools` リストに `"self"` を正式エントリとして許容する（型・許容値・意味論を `review-routing.md §2` / §4 で明文化）
- **`"claude"` alias の正規化**: ToolSelection 入口で `"claude" -> "self"` の単純置換を実装（最小実装、汎用化は対象外）
- **暗黙末尾 self 補完シム**: 既存設定（`tools = ["codex"]` 等）で末尾に `"self"` が含まれない場合は暗黙的に末尾追加して扱う後方互換シムを `review-routing.md §4 ToolSelection` 内に記述
- **`tools = []` の扱い明文化**: 従来「セルフ直行シグナル」と意味付けされていた挙動を、シム適用結果 `["self"]` 相当と等価で動作することとして明文化
- **§5 PathSelection / §6 FallbackPolicyResolution の整理**: ツール解決順序の自然な延長として self に降りる構造へ整理し、`fallback_to_self` の記述を縮約 or 注記化（Construction Phase 設計レビューで縮約 / 注記のいずれかを確定）
- **`review-flow.md` の整合更新**: パス 1（外部 CLI）→ パス 2（セルフ）の遷移が「ツール解決の延長」として読める表現に修正、Codex セッション管理 / フォールバック関連記述を新仕様に整合
- **`defaults.toml` の方針記録**: `tools = ["codex"]` は維持（暗黙シムで実質 `["codex", "self"]` 相当）。注釈追加要否を Phase 1 設計レビューで確定
- **6 パターン後方互換 / 新規明示パターン動作確認**: 文書改訂主体のため、bats テスト導入の要否は Phase 1 設計レビューで確定。代替として `review-routing.md` 末尾または `design.md` に擬似 ToolSelection 実行表を追加して 6 パターンの解決結果を明示

### スコープ外（Unit 定義「境界」由来）

- `"self"` / `"claude"` 以外の汎用ツール名正規化拡張（任意 LLM CLI のエイリアス機構）
- 複数 LLM 並列実行
- セルフレビュー実行ロジックの再設計（既存パス 2 フローを流用）
- レビュー対象スキル群（`reviewing-construction-*` 等）本体修正
- `read-config.sh` の型検証強化（必要なら別 Issue 化）

## 実装方針

### Phase 1（設計）

#### ドメインモデル設計

ツール解決ロジック領域の概念モデルを以下で整理する（小〜中規模）:

- エンティティ:
  - `ReviewToolList`(`[rules.reviewing].tools` の論理表現)
    - エントリ: `ConfiguredTool { name: string }` の順序付きリスト
    - 不変条件: 重複は許容するが解決時は先頭優先
  - `ToolName`(解決時の正規化名)
    - 値: `"codex"` / `"self"` / その他外部 CLI 名
    - 正規化規則: `"claude" -> "self"`
  - `SelfBackcompatShim`(後方互換シム)
    - 振る舞い: `tools` リスト内に `"self"` が**一度も出現しない**場合、暗黙的に末尾へ `"self"` を追加して扱う
    - **no-op 条件（明示）**: リスト内に `"self"` が一度でも出現する場合は no-op（位置・出現回数を問わない）
    - alias 正規化との順序: `"claude" -> "self"` 正規化を先に適用してからシムを評価する（例: `["claude"]` → 正規化後 `["self"]` → シム判定 no-op）
- ルール:
  - リストの並び順 = 優先順位 = フォールバック順序
  - **`"self"` の配置位置**: 末尾配置を推奨。末尾以外（例: `["self", "codex"]`）に配置された場合の解釈は「ToolSelection の走査が先頭から行われ、`"self"` が先にヒットすれば `self_review_forced` を出力」とする（シムは適用済みリストに `"self"` が含まれるため no-op）
  - `tools = []` は「シム適用結果 `["self"]` 相当」として `self_review_forced` シグナルを出力
- イベント:
  - `ToolResolutionPerformed`(ToolSelection 完了 → `tool_name` 確定)
  - `SelfShimApplied`(シムが暗黙末尾追加を行った場合の構造化マーカー)

#### 論理設計

1. **`review-routing.md §2 設定` 改訂内容**:
   - `tools` の説明に `"self"`(正式名) と `"claude"`(alias) の扱いを追加
   - `[]` の意味を「シム適用結果 `["self"]` 相当として `self_review_forced` を出力」と注記
   - `tools` の許容値を「外部 CLI 名 / `"self"` / `"claude"`(`"self"` への alias)」と列挙

2. **`review-routing.md §4 ToolSelection` 改訂内容**:
   - 入口で `"claude" -> "self"` の単純置換を行う処理を記述
   - 暗黙末尾 self 補完シム（`SelfBackcompatShim`）を ToolSelection ロジック内の前処理として記述
   - `configured_tools=[]` の扱いをシム適用結果 `["self"]` と等価に整理し、`self_review_forced` シグナルを出力する分岐に統合
   - `configured_tools` 走査ロジックは現行のまま維持（先頭優先・available_tools との一致判定）
   - `"self"` エントリは `available_tools` チェックを必要としない（常時 available と扱う）旨を明記

3. **`review-routing.md §5 PathSelection` 改訂内容**:
   - `self_review_forced` の発生経路を「ToolSelection の前処理結果として `["self"]` が解決された場合」に統一
   - `cli_missing_permanent` の発生経路を「`configured_tools` から `"self"` を除外した残りが `available_tools` と一致しない場合」に整理
   - 表のフォーマットは現行を維持し、説明欄のみ調整

4. **`review-routing.md §6 FallbackPolicyResolution` 改訂方針**(Phase 1 設計レビューで A/B 確定):
   - **§6-A（縮約）**: 表自体を残し、注記のみで「ツール解決順序の延長として self に降りる」表現を追加。最小変更で後方互換性最大
   - **§6-B（注記化）**: 表を `cli_runtime_error` / `cli_output_parse_error` のみに縮約し、`cli_missing_permanent` 行を §4 ToolSelection の前処理側に吸収。記述重複を削減
   - **判定トリガー**: `review-flow.md` および `review-flow-reference.md` から `review-routing.md §6` への明示参照箇所を Phase 1 で grep 集計し、**3 箇所以上 → §6-A（縮約）**（参照整合のリスク回避優先）、**2 箇所以下 → §6-B（注記化）**（記述重複削減を優先）
   - **grep 検索パターン定義（指摘#2 対応）**: `review-flow.md` および `review-flow-reference.md` を対象に、以下のいずれかを含む行を集計（重複行は 1 箇所として数える）:
     - `review-routing.md §6` または `review-routing.md` と同一行内に `§6` を含む行
     - `FallbackPolicyResolution` を含む行
     - `fallback_to_self` を含む行
     - `cli_missing_permanent` または `cli_runtime_error` または `cli_output_parse_error` を含む行
   - 集計コマンド例: `grep -nE '(review-routing\.md.*§6|FallbackPolicyResolution|fallback_to_self|cli_missing_permanent|cli_runtime_error|cli_output_parse_error)' skills/aidlc/steps/common/review-flow.md skills/aidlc/steps/common/review-flow-reference.md`

5. **`review-routing.md §7 呼び出し形式` 整合**:
   - 現行のパス 2 呼び出し形式（`skill="reviewing-[stage]", args="self-review [対象ファイル]"`）を維持
   - パス 1 → パス 2 の遷移が「ツール解決の自然な延長」として読める注記を追加

6. **`review-flow.md` 改訂内容**:
   - パス 1 → パス 2 の遷移記述を「ツール解決順序の延長」として読み替えできる表現に整理
   - Codex セッション管理（`codex exec resume`）の記述は現行維持、エラー時のフォールバック先を `review-routing.md §6` 改訂版にリンク
   - フォールバック関連記述（パス 2 直行シグナルの説明等）を `review-routing.md` の改訂と整合

7. **`defaults.toml` 改訂方針**(Phase 1 設計レビューで A/B 確定):
   - **defaults-A（現状維持）**: `tools = ["codex"]` のまま。コメントで「暗黙シムにより末尾 self 補完される」旨を 1〜2 行で注記
   - **defaults-B（明示化）**: `tools = ["codex", "self"]` に変更し、シム挙動と等価な明示形式に統一
   - **判定トリガー**: Phase 1 で `aidlc-setup` 経由の `.aidlc/config.toml` テンプレート（`skills/aidlc-setup/templates/` 配下、または同等の生成元）に `tools = ["codex"]` 文字列が直接含まれているかを grep で確認。**含まれない → defaults-A（現状維持）**（既存生成物との差分が出ないため安全）、**含まれる → defaults-B（明示化）**（テンプレート側を `["codex", "self"]` に同期更新して整合）。**判定指針補足**: 既存ダウンストリームプロジェクトの `.aidlc/config.toml` を変更せずに動作する後方互換性を最優先（暗黙シムで吸収済みのため defaults 変更は既存プロジェクトに影響なし）

8. **6 パターン動作確認方針**:
   - **検証手段の選択**(Phase 1 設計レビューで A/B 確定):
     - **検証-A（擬似実行表）**: `review-routing.md` 末尾または論理設計成果物に「ToolSelection 解決結果テーブル」を追加し、6 パターンの入力 → 出力（解決後 tools / `selected_path` / `tool_name`）を明示
     - **検証-B（bats テスト導入）**: `tests/` 配下に bats テストを新規追加し、ToolSelection ロジックを擬似的に再現する shell 関数 + テストケース 6 件を追加
     - **判定トリガー**: Phase 1 で既存 `tests/` 配下の bats テストインフラと CI 連動状況を grep / find で確認。**bats テストインフラなし、または CI 連動が確立されていない → 検証-A（擬似実行表）**（最小実装、文書改訂主体に整合）、**bats テストインフラあり、CI 連動あり、かつ Unit 003 / 004 の改訂対象と整合する → 検証-B（bats）**。**優先候補は検証-A**

9. **A/B 確定結果の記録先（指摘#4 対応）**:
   - 上記 §6-A/B、defaults-A/B、検証-A/B のすべての確定結果は **論理設計成果物（`design-artifacts/logical-designs/unit_002_review_tools_self_integration_logical_design.md`）の冒頭「設計判断記録」セクション**に明記する
   - `history/construction_unit02.md` の Phase 1 設計レビュー完了エントリでも上記決定を要約参照する（記録の冗長化により完了確認時のトレース性を担保）
   - **6 パターン**:
     - A: `["codex"]` → シム適用 `["codex", "self"]` → `selected_path=1, tool_name="codex"`(codex available 時)
     - B: `[]` → シム適用 `["self"]` → `self_review_forced` → `selected_path=2`
     - C: `["codex", "self"]` → 明示形式 → `selected_path=1, tool_name="codex"`(codex available 時)
     - D: `["self"]` → 明示形式 → `self_review_forced` → `selected_path=2`
     - E: `["claude"]` → alias 正規化 `["self"]` → `self_review_forced` → `selected_path=2`
     - F: 未設定 → `defaults.toml` 適用（**defaults-A 選択時** → `["codex"]` で A と同等 / **defaults-B 選択時** → `["codex", "self"]` で C と同等）。F の解決結果は Phase 1 で確定する defaults-A/B に依存

### Phase 2（実装）

- `review-routing.md` 改訂: Phase 1 で確定した §2 / §4 / §5 / §6 / §7 の改訂を反映
- `review-flow.md` 改訂: Phase 1 で確定した整合更新を反映
- `review-flow-reference.md` 整合確認: パス 2 / フォールバック表現が改訂版 `review-routing.md` と矛盾していないかを必ず確認し、必要なら追記・整合更新を行う（不要な場合は「変更なし」を `history/construction_unit02.md` に明記）
- `defaults.toml` 改訂: Phase 1 で defaults-A / defaults-B のいずれかを反映（注釈追加 or `tools` 明示化）
- 6 パターン動作確認: Phase 1 で確定した検証-A（擬似実行表）または検証-B（bats）を実施
- grep 検証: 改訂後に以下を実行し、結果を `history/construction_unit02.md` に記録（**対象範囲**: `skills/aidlc/steps/common/review-routing.md`、`review-flow.md`、`review-flow-reference.md`、`config/defaults.toml`、および `skills/aidlc/steps/**` 全体への横断 grep）
  - `fallback_to_self` の言及箇所が新仕様と整合しているか
  - `self-review` / `self_review_forced` の表現が statement と一致しているか
  - `claude` alias の言及が ToolSelection 入口に集約されているか

### Phase 3（完了処理）

- 設計 / コード / 統合 AI レビュー（`review_mode=required`）
- Unit 定義ファイル状態を「完了」に更新
- 履歴記録（`construction_unit02.md`）
- Markdownlint 実行（`markdown_lint=true`）
- Squash 実行（`squash_enabled=true`）
- Git コミット

## 完了条件チェックリスト

> **観測条件の境界**: 本 Unit は文書改訂主体で、実走行検証は擬似実行表 or bats テストによる解決結果一致をもって完了とする。完了条件は **「ドキュメント内に該当記述が存在すること」「6 パターンの解決結果が期待値と一致すること」** を基準とする。

### 機能要件（Unit 定義「責務」由来）

- [ ] `review-routing.md §2` で `"self"` / `"claude"` の許容値が明文化されている
- [ ] `review-routing.md §4 ToolSelection` に `"claude" -> "self"` alias 正規化処理が記述されている
- [ ] `review-routing.md §4 ToolSelection` に暗黙末尾 self 補完シム（`SelfBackcompatShim`）が記述されている
- [ ] `review-routing.md §4` で `tools = []` の扱いがシム適用結果 `["self"]` と等価で動作することが明文化されている
- [ ] `review-routing.md §4` でシムの no-op 条件（リスト内に `"self"` が一度でも出現する場合）と、`"self"` が末尾以外に配置された場合の解釈（先頭優先で `self_review_forced` を出力）が明文化されている
- [ ] `review-routing.md §6 FallbackPolicyResolution` が Phase 1 設計レビューで選択した §6-A / §6-B のいずれかで更新されている
- [ ] `review-routing.md §5 PathSelection` の `self_review_forced` / `cli_missing_permanent` 発生経路が改訂版 §4 と整合している
- [ ] `review-flow.md` のパス 1 → パス 2 遷移記述、Codex セッション管理エラー時記述、フォールバック関連記述が改訂版 `review-routing.md` と整合している
- [ ] `review-flow-reference.md` の整合確認が完了している（変更なしの場合は明記）
- [ ] `defaults.toml` の方針が defaults-A / defaults-B のいずれかで確定し、必要な変更が反映されている
- [ ] §6-A/B、defaults-A/B、検証-A/B の確定結果が論理設計成果物の「設計判断記録」セクションに明記されている
- [ ] 6 パターン（A〜F）の動作確認が検証-A（擬似実行表）または検証-B（bats）で記録されている
- [ ] grep 検証結果が `history/construction_unit02.md` に記録されている

### Issue 終了条件（Issue #611 由来、観測単位はドキュメント記述）

- [ ] **#611**: `[rules.reviewing].tools` に `"self"`(および alias `"claude"`) が正式に許容される旨が `review-routing.md §2` / §4 に明文化されている
- [ ] **#611**: `tools = ["codex"]` のような既存設定が暗黙シムで従来通り動作する旨が `review-routing.md §4` に明文化されている
- [ ] **#611**: `tools = []` がシム適用結果 `["self"]` と等価で動作する旨が `review-routing.md §4` に明文化されている
- [ ] **#611**: `tools = ["codex", "self"]` のような新規明示形式が正しく解釈される旨が動作確認に含まれている
- [ ] **#611**: `fallback_to_self` 分岐がツール解決ロジックに畳み込まれた表現に整理されている

### プロセス要件

- [ ] 設計 AI レビュー承認（`review_mode=required`）
- [ ] コード AI レビュー承認（同上）
- [ ] 統合 AI レビュー承認（同上）
- [ ] Unit 定義ファイル状態を「完了」に更新
- [ ] 履歴記録（`construction_unit02.md`）
- [ ] Markdownlint 実行（`markdown_lint=true`）
- [ ] Squash 実行（`squash_enabled=true`）
- [ ] Git コミット

## 依存関係

- **依存する Unit**: なし（Unit 001 完了済み、Unit 003 / 004 と独立並列実装可能）

## 見積もり

- Phase 1（設計）: 0.20〜0.30 日
- Phase 2（実装）: 0.20〜0.35 日
- Phase 3（完了処理）: 0.20〜0.25 日

合計: 0.6〜0.9 日規模（Unit 定義の見積もり「M（Medium）: 文書改訂 + 後方互換テスト 6 パターン。1-2 セッション」と整合）。

## リスク・留意点

- **既存ダウンストリーム設定の後方互換性**: `tools = ["codex"]` のまま運用しているプロジェクトが、本サイクル後も従来通りのフォールバック挙動を保てることを擬似実行表で必ず明示する（パターン A）
- **`fallback_to_self` 記述の縮約と参照整合**: §6 を縮約 / 注記化する際、`review-flow.md` 側で `review-routing.md §6` を参照している箇所が壊れないよう、grep で参照箇所を洗い出してから改訂方向を確定する
- **`"self"` の available_tools 扱い**: パス 2 はサブエージェント呼び出しで常時利用可能だが、`available_tools` リストへの含め方次第で `cli_missing_permanent` 判定に影響が出る。Phase 1 設計レビューで「`"self"` は available_tools チェックを skip する」ことを明示記述する
- **alias 正規化の最小実装範囲**: `"claude" -> "self"` のみ対応し、他の任意 LLM CLI への汎用化は対象外。Issue 本文の「self（または claude）」記述に限定する
- **defaults.toml 変更の波及**: defaults-B（明示化）を選択した場合、`aidlc-setup` 経由で生成される `.aidlc/config.toml` テンプレートとの整合確認が必要。Phase 1 設計レビューで波及範囲を確認する
- **bats テスト導入の判断**: 検証-B（bats）を選択した場合、既存テストインフラとの整合性、`tests/` 配下の構造、CI 連動の要否を確認する。本サイクルでは検証-A（擬似実行表）を優先候補とする
- **メタ開発時の即時検証困難性**: `review-routing.md` は純粋参照ファイルのため、ロジック検証は擬似実行表で代替する。実走行検証は次サイクル以降のレビュー実行時に観測する
- **他 Unit との改訂対象重複リスク（指摘#6 対応）**: Phase 1 着手時に Unit 003（migrate-backlog UTF-8 fix）/ Unit 004（markdownlint hook + ops75 削除）の改訂対象ファイル一覧と本 Unit の主対象ファイル（`review-routing.md` / `review-flow.md` / `defaults.toml`）の重複が無いことを必ず確認する。Intent §「含まれるもの」の現時点判断では Unit 004 が `defaults.toml` に触れる可能性は低いが、`.claude/settings.json` 改訂の波及で `[rules.linting]` 周辺に間接影響が出る場合に備えて Phase 1 で確認する。重複が判明した場合はマージ順序（Unit 002 を先にマージ → Unit 003/004 が rebase）を Operations Phase で調整する
