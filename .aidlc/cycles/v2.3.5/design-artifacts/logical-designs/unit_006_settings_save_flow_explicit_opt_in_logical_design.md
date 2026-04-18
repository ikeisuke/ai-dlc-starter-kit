# 論理設計: Unit 006 設定保存フローの暗黙書き込み防止

## 概要

ドメインモデル（`unit_006_settings_save_flow_explicit_opt_in_domain_model.md`）を、SKILL.md の対話プロトコル仕様と 3 ステップファイルの記述構成として写像する論理設計。対象は 4 ファイルの Markdown 記述変更のみで、外部スクリプト変更は行わない。

**重要**: この論理設計では**コードは書かず**、Markdown 記述の構成とインターフェース（配置位置・記述雛形・文言）のみを定義する。

## 責務境界の再確認

| ドメイン層 | 実装対象 | 記述形式 |
|-----------|---------|---------|
| 対話プロトコルの正本 | `skills/aidlc/SKILL.md` § AskUserQuestion 使用ルール | 既存テーブルの「具体例」列への追記（1 行） |
| 対話フロー実装記述 × 3 | `skills/aidlc/steps/inception/01-setup.md` §9-1, `05-completion.md` §5d-1, `operations/operations-release.md` 設定保存フロー | 共通雛形に揃えた Markdown 記述（質問文・注記・選択肢・保存先説明） |
| 書き込み実装（既存、変更なし） | `skills/aidlc/scripts/write-config.sh` | 本 Unit では変更しない |
| 保存先選択フロー（既存、変更なし） | 各ステップファイル内の「はい」選択後のサブフロー | 既存記述を維持 |

## アーキテクチャパターン

**対話プロトコルの正本 + 実装記述の派生整合**:

- SKILL.md「AskUserQuestion 使用ルール」を**正本**とし、「ユーザー選択」種別に『設定保存確認（3 キー）』が該当することを 1 行追記する
- 3 ステップファイルはこの正本を参照しつつ、各場面で具体的な質問文・選択肢・トリガー条件・値マッピングを定義する
- 共通部分（質問文・選択肢ラベル・保存先説明）は統一雛形で揃える。固有部分（トリガー条件・値マッピング）はキー別に記述する
- `write-config.sh` の引数仕様は既存のまま、呼び出し側のプロトコル記述のみ更新

## 編集設計

### 1. `skills/aidlc/SKILL.md` § AskUserQuestion 使用ルール

**現状**（該当テーブル抜粋、line 90-94 付近）:

```text
| ユーザー選択 | ... | `AskUserQuestion` 必須 | 自動化対象外 | 「マージ方法を選んでください」「force pushしてよろしいですか？」 |
```

**変更後**（具体例列に 1 項目追記）:

```text
| ユーザー選択 | ... | `AskUserQuestion` 必須 | 自動化対象外 | 「マージ方法を選んでください」「force pushしてよろしいですか？」「設定保存確認（`branch_mode` / `draft_pr` / `merge_method`）」 |
```

**設計判断**: 計画書の候補 A（既存テーブル具体例列への追記）を採用。行追加・列追加・新規セクション追加は行わず、最小変更で目的を達成する。

### 2. 3 ステップファイルの共通雛形（最小注記版）

step ファイル側は**最小注記**にとどめ、詳細ルールは SKILL.md「AskUserQuestion 使用ルール」に委譲する。これにより、将来 SKILL.md のルール本文が変わったときに 3 ファイルを同期更新する負担を軽減できる（Codex 設計レビュー指摘 #3 対応）。

```markdown
**設定保存フロー【ユーザー選択】**（<トリガー条件>）:

本確認は SKILL.md「AskUserQuestion 使用ルール」の「ユーザー選択」種別のため、`automation_mode` に関わらず `AskUserQuestion` 必須（詳細は SKILL.md 参照）。

選択後、`AskUserQuestion` で「この選択を設定に保存しますか？」と確認:

- **いいえ（今回のみ使用） (Recommended)**: 保存せず、今回の選択のみ使用して続行
- **はい（保存する）**: 保存先を選択（デフォルト: `config.local.toml`（個人設定）、代替: `config.toml`（プロジェクト共有））
  ```bash
  scripts/write-config.sh <key_name> "<value>" --scope <local|project>
  ```
  成功時: 「設定を保存しました」と表示。失敗時: 警告表示して続行

<固有補足: value_mapping があればここで記述>
```

**雛形設計の責務分離**:

- 見出し `【ユーザー選択】` と本文「`automation_mode` に関わらず `AskUserQuestion` 必須」で最小限の宣言のみ行う
- `manual` / `semi_auto` / `full_auto` の各モード別挙動・`auto_approved` の扱いなど詳細ルールは SKILL.md 側に集約する
- step ファイルはユーザー体験に直結する「質問文・選択肢ラベル・保存先説明」の共通化に集中する

### 3. `skills/aidlc/steps/inception/01-setup.md` §9-1 の適用

**トリガー条件**: `branch_mode=ask` でユーザーが `worktree` / `branch` を選択した場合のみ。「現在のブランチで続行」選択時は本フローに入らない（既存仕様維持）

**value_mapping**: ユーザーが選んだ `worktree` / `branch` の値をそのまま保存

**書き換え方針**: 既存の「設定保存フロー」サブセクション全体を上記雛形に差し替え。`<key_name>` = `rules.git.branch_mode`, `<value>` = `worktree|branch`, 固有補足は不要。

### 4. `skills/aidlc/steps/inception/05-completion.md` §5d-1 の適用

**トリガー条件**: `action=ask_user` の場合のみ（`skip_never` / `create_draft_pr` では本フローに入らない）

**value_mapping**: `AskUserQuestion`（PR 作成の可否）応答「はい（作成）」→ `always` / 「いいえ（作成しない）」→ `never` に変換した値を保存値とする。この変換は 2 段階対話の (1) 段目であり、(2) 段目が本設定保存確認

**書き換え方針**: 既存の「ステップ5d-1. 設定保存フロー」全体を上記雛形に差し替え。`<key_name>` = `rules.git.draft_pr`, `<value>` = `always|never`, 固有補足で「value_mapping: 『はい（作成）』→ `always` / 『いいえ（作成しない）』→ `never`」を明記。

### 5. `skills/aidlc/steps/operations/operations-release.md` 設定保存フローの適用

**トリガー条件**: `merge_method=ask` の場合のみ

**value_mapping**: ユーザーが選んだ `merge` / `squash` / `rebase` の値をそのまま保存

**書き換え方針**: 既存の「設定保存フロー」サブセクション全体を上記雛形に差し替え。`<key_name>` = `rules.git.merge_method`, `<value>` = `merge|squash|rebase`, 固有補足は不要。

## 挙動マトリクスとの整合

ドメインモデルの挙動マトリクス A（デフォルト選択） / B（`AskUserQuestion` 必須化）がそれぞれ以下の記述要素で担保される。step ファイル側は最小注記で、詳細は SKILL.md 正本に委譲する（指摘 #3 対応）。

| マトリクス観点 | step ファイル側の担保 | SKILL.md 側の担保 |
|--------------|-------------------|------------------|
| A: デフォルトが「いいえ」 | 共通雛形の選択肢順序（「いいえ（今回のみ使用） (Recommended)」が先頭、label に `(Recommended)` サフィックス付与） | - |
| B: 全 `automation_mode` で `AskUserQuestion` 必須 | 共通雛形の見出し『【ユーザー選択】』+ 本文「`automation_mode` に関わらず `AskUserQuestion` 必須（詳細は SKILL.md 参照）」 | 「AskUserQuestion 使用ルール」テーブルの「ユーザー選択」行が `automation_mode` 全モードで必須と規定 |
| B: ゲート承認として自動化されない | - | 同テーブルの「ユーザー選択」行 `semi_auto` 列「自動化対象外（常に `AskUserQuestion`）」。設定保存確認が「ユーザー選択」種別の具体例として明記されるため、セミオートゲート判定対象外であることが正本で担保される |

## API 設計

本 Unit は**Markdown 記述の変更のみ**で、公開インターフェース（コマンド、関数、スクリプト）の追加・変更はない。

- 追加スクリプト: なし
- 変更スクリプト: なし（`write-config.sh` は呼び出し引数含めて既存のまま）
- 変更設定キー: なし（本 Unit は既存キー `branch_mode` / `draft_pr` / `merge_method` の**確認フロー**のみを更新）
- 新規 CLI フラグ: なし

## 検証設計

### 検証項目と検証方法

本 Unit の重要要件（`AskUserQuestion` 必須化、既存分岐条件の維持）は文字列存在確認だけでは担保できないため、**コンテキストトレース観点**（周辺記述との整合確認）を追加する（Codex 設計レビュー指摘 #2 対応）。

#### A. 正本側（SKILL.md）の検証

| # | 検証項目 | 検証方法 | ドメイン対応 |
|---|---------|---------|------------|
| A-1 | SKILL.md の「ユーザー選択」種別の具体例に「設定保存確認」が明記されている | grep で「設定保存確認」を検索し、該当行がテーブル「ユーザー選択」行の具体例列にあることを確認 | `SaveDecisionPrompt.interaction_type = user_choice` の正本宣言 |
| A-2 | テーブル構造（3 種別行 × 5 列）が壊れていない | SKILL.md の該当テーブル全体を目視確認 | 非侵襲性の担保 |

#### B. 派生側（3 ステップファイル）の対話種別整合

| # | 検証項目 | 検証方法 | ドメイン対応 |
|---|---------|---------|------------|
| B-1 | 各 step の見出しに「【ユーザー選択】」が含まれる | 3 ファイル grep | `SaveDecisionPrompt.interaction_type` の派生記述 |
| B-2 | 各 step の本文に「`automation_mode` に関わらず `AskUserQuestion` 必須（詳細は SKILL.md 参照）」の注記がある | 3 ファイル grep + 周辺コンテキスト確認 | マトリクス B（起動形態） |
| B-3 | 対象 3 フローがステップファイル内でセミオートゲート判定として扱われていない | 各 step の該当セクション周辺で「セミオートゲート判定」「`auto_approved`」などの扱いを目視トレース確認（セクション見出し・前後文脈で用語誤用がないこと） | マトリクス B（ゲート承認対象外） |

#### C. 選択肢形式の検証

| # | 検証項目 | 検証方法 | ドメイン対応 |
|---|---------|---------|------------|
| C-1 | 各 step で 2 択が「いいえ（今回のみ使用） (Recommended)」「はい（保存する）」の順で記述されている | 3 ファイル grep | `SaveOption` 不変条件（先頭 label に `(Recommended)` サフィックス） |
| C-2 | `(Recommended)` サフィックスが「いいえ」option のみに付与されている | 3 ファイル grep（「はい（保存する） (Recommended)」のような誤記がないこと） | 同上 |

#### D. 既存分岐条件（トリガー条件）の維持

| # | 検証項目 | 検証方法 | ドメイン対応 |
|---|---------|---------|------------|
| D-1 | `01-setup.md` §9-1 で `branch_mode=ask` + 「現在のブランチで続行」**以外**のときのみ保存フローに入る記述 | 該当セクションを目視トレース（雛形のトリガー条件記述と、続行選択時のフロー全体をスキップする旨が両立していること） | `ConfigKeyContext.trigger_condition` (branch_mode) |
| D-2 | `05-completion.md` §5d-1 で `action=ask_user` の場合のみ保存フローに入り、`skip_never` / `create_draft_pr` ではスキップされる記述 | 該当セクションを目視トレース | `ConfigKeyContext.trigger_condition` (draft_pr) |
| D-3 | `operations-release.md` 設定保存フローで `merge_method=ask` の場合のみ保存フローに入る記述 | 該当セクションを目視トレース | `ConfigKeyContext.trigger_condition` (merge_method) |

#### E. 既存 value_mapping の維持

| # | 検証項目 | 検証方法 | ドメイン対応 |
|---|---------|---------|------------|
| E-1 | `draft_pr` の value_mapping「はい（作成）→ `always` / いいえ（作成しない）→ `never`」が 05-completion.md に明記 | grep + 周辺確認 | `ConfigKeyContext.value_mapping` (draft_pr) |
| E-2 | `branch_mode` が選択値そのまま保存（`worktree` / `branch`） | 01-setup.md 記述確認 | `ConfigKeyContext.value_mapping` (branch_mode) |
| E-3 | `merge_method` が選択値そのまま保存（`merge` / `squash` / `rebase`） | operations-release.md 記述確認 | `ConfigKeyContext.value_mapping` (merge_method) |

#### F. 保存先選択フローの現状維持

| # | 検証項目 | 検証方法 | ドメイン対応 |
|---|---------|---------|------------|
| F-1 | 3 ファイルで「デフォルト: `config.local.toml`、代替: `config.toml`」の既存記述が残っている | 3 ファイル grep | `SaveTargetScope`（参照のみ、変更なし） |
| F-2 | `write-config.sh` の呼び出し例が既存の引数仕様（`--scope <local|project>`）と整合 | 雛形および 3 ファイルの `write-config.sh` 行を確認 | 既存スクリプトへの非侵襲性 |

#### G. Markdown 構文・lint

| # | 検証項目 | 検証方法 |
|---|---------|---------|
| G-1 | Markdown 構文確認（見出しレベル・表・箇条書きの崩れなし） | 4 ファイル目視 |
| G-2 | markdownlint 実行 | `markdown_lint=false` ならスキップ（本プロジェクト設定） |

### 検証順序

1. **正本側（A）**: SKILL.md の具体例追記とテーブル構造維持を確認
2. **派生側対話種別（B）**: 3 step ファイルで見出し・注記・セミオートゲート非該当を確認
3. **選択肢形式（C）**: 2 択順序と `(Recommended)` サフィックスを確認
4. **トリガー条件（D）**: 3 step ファイルで既存分岐条件が維持されていることを目視トレース
5. **value_mapping（E）**: 3 キーそれぞれの保存値変換ルールが維持されていることを確認
6. **保存先選択（F）**: `config.local.toml` / `config.toml` の既存記述と `write-config.sh` 呼び出しが壊れていないことを確認
7. **構文（G）**: Markdown 構文と lint（有効時）を実施

## スコープ外（論理設計でも明示）

- `write-config.sh` 実装の変更
- `AskUserQuestion` 本体の UI・挙動変更
- 保存先選択フローの 2 択（local/project）変更
- 3 場面以外の設定保存フロー（本 Unit のスコープ外）
- 既存 `.aidlc/config.local.toml` の遡及処理

## 不明点と質問

[Question] 3 ステップファイルで共通雛形を使うとき、トリガー条件や value_mapping を雛形の前後どちらに配置すべきか？

[Answer] **雛形の前（トリガー条件）** と **雛形の後（value_mapping など固有補足）** で配置を分ける。トリガー条件は「本フローに入るかどうか」の前提であり、雛形冒頭の見出し行（`（<トリガー条件>）`）に組み込む。value_mapping はユーザーが「はい」を選んだ場合に書き込む値を決める補足情報で、雛形後半の「固有補足」セクションにまとめる。これにより、読み手は上から順に「前提 → 質問 → 選択肢 → 保存先 → 書き込み値変換」の流れで理解できる。

[Question] 既存の `AskUserQuestion` option 実装では `(Recommended)` を label に直接含める形と、`is_recommended` フラグ的な属性を持たせる形のどちらを採用すべきか？

[Answer] **label に直接含める**形を採用（Unit 定義「技術的考慮事項」に準拠）。理由: 既存の `AskUserQuestion` ツール契約は label 文字列で表示を制御しており、フラグ属性の追加は本 Unit のスコープ外（Unit 定義「境界」で UI 仕様変更を除外）。Markdown 記述でも視覚的に分かりやすい。

[Question] `action=create_draft_pr` や `skip_never` の場合に本 Unit の変更が適用されないことを、ステップファイル側でどう明示するか？

[Answer] **雛形冒頭の見出し行の「<トリガー条件>」で明示する**。例: 05-completion.md §5d-1 の見出しは「設定保存フロー【ユーザー選択】（`action=ask_user` の場合のみ。`skip_never` / `create_draft_pr` ではスキップ）」とする。トリガー条件の明示により、該当しない分岐では本フロー全体がスキップされることが読み手に伝わる（`automation_mode` に関わらず `AskUserQuestion` 必須である旨は見出し直下の最小注記で示し、詳細は SKILL.md 参照）。
