# Unit 004 計画: retrospective テンプレートと Operations 自動生成

## 概要

Operations Phase 完了時に「なぜ間違えたか」のプロセス学習を残す retrospective フローを導入する。具体的には:

1. `templates/retrospective_template.md` を新規作成（概要 / 問題項目（タイトル / 何が起きたか / なぜ起きたか / 損失と影響 / skill 起因判定 YAML フロントマター）/ 次サイクルへの引き継ぎ事項）
2. `skills/aidlc/steps/operations/04-completion.md` に retrospective サブステップを追加（v2.5.0 リリース後の Operations Phase からのみトリガー）
3. `skills/aidlc/config/defaults.toml` に `[rules.retrospective] feedback_mode = "silent"` を追加（user-global で `"mirror"` / `"disabled"` に上書き可能）
4. 自動生成された retrospective.md の空ファイル禁止ガード + skill 起因判定（3 問自問）の不正値ガード（10 文字未満 / 禁止語チェック）

`mirror` モードで `/aidlc-feedback` を呼び出す具体ロジックは Unit 005 のスコープ。本 Unit はローカル記録 + skill 起因判定フラグまでで完結する。

## 前提条件と関連 Unit

- **Unit 001 完了済み**: `defaults.toml` への新セクション追加が安全（4 階層マージ仕様維持）
- **Unit 005 / Unit 006 への引き継ぎ点**:
  - 本 Unit で生成される `retrospective.md` の YAML フロントマターを Unit 005 がパースして `/aidlc-feedback` 連動を実装
  - 本 Unit のテンプレート構造 / 安定 ID / `skill_caused_judgment` スキーマは Unit 005 / Unit 006 で参照する単一ソース

## 対象ストーリー

| # | ストーリー | 受け入れ基準（要約） |
|---|-----------|---------------------|
| 4 | retrospective テンプレートと Operations 自動生成 | テンプレート 3 セクション / サブステップ追加 / `feedback_mode ∈ {silent, mirror}` で自動実行 / `disabled` でスキップ / 空ファイル禁止 / markdownlint パス |
| 5 | skill 起因判定（3 問自問） | YAML フロントマター 6 キー / `q*_answer: yes` のいずれかで `skill_caused = true` / 不正値（空 / 10 文字未満 / 禁止語）で `false` に強制ダウングレード |

## 現状分析

### `skills/aidlc/steps/operations/04-completion.md`

- 既存セクション構成: バックトラック手順 → AI-DLC サイクル完了（1. フィードバック収集 / 2. 分析と改善点洗い出し / 3. バックログ記録 / 4. 次期サイクル計画 / 5. PR マージ後の手順 / 5.5 Milestone close / 6. 完了サマリ / 7. 次サイクル開始 / 8. ライフサイクル）
- マージ前完結契約（v2.3.5 / Unit 002）により、PR マージ（7.13）完了後は `.aidlc/cycles/{{CYCLE}}/**` 配下のファイル改変禁止
- **retrospective.md の生成タイミング**: マージ前完結契約に従い、**5. PR マージ後の手順より前**で実行する必要がある。具体的には「3. バックログ記録」直後 / 「4. 次期サイクル計画」前に挿入する（マージ前で `.aidlc/cycles/{{CYCLE}}/operations/retrospective.md` への書き込み完結）

### `skills/aidlc/config/defaults.toml`

- 現状 `[rules.retrospective]` セクション不在
- 既存 13 セクション（feedback / reviewing / release / depth_level / automation / construction / linting / cycle / version_check / git / documentation / github + retrospective 追加候補）
- 4 階層マージ仕様維持（user-global で `"mirror"` 上書き可能）

### `templates/` ディレクトリ

- 既存 27 テンプレート（27 ファイル）。すべて Markdown 形式 / `{{プレースホルダ}}` 記法で Markdown lint 対応済み
- `retrospective_template.md` が現状不在 → 新規作成

### v2.5.0 トリガー条件の選定

「v2.5.0 リリース後の Operations Phase からのみトリガー（既存サイクルへの遡及生成防止）」を実現する 2 候補:

| 候補 | 判定方法 | 採否 |
|------|---------|------|
| A. サイクルディレクトリ名（`{{CYCLE}}`）から semver 比較で `>= v2.5.0` | **bash 内蔵の major/minor/patch 数値比較**（GNU/BSD `sort -V` 差異の影響を排除） | **採用**（新規 helper を `scripts/lib/` 配下に最小実装） |
| B. `[project] starter_kit_version` の存在チェック | `read-config.sh project.starter_kit_version` | 不採用（`[project]` セクションが現状存在せず仕様拡大、判定基準が曖昧） |

実装は **候補 A**（サイクルディレクトリ名 `{{CYCLE}}` の `v` プレフィックス除去 → bash 数値比較で `v2.5.0` 以降か判定 / `sort -V` 不使用）。判定ロジックは新規 helper script `skills/aidlc/scripts/lib/cycle-version-check.sh` に切り出し、bats で検証する。入力フォーマットは `^v[0-9]+\.[0-9]+\.[0-9]+$` に厳格化し、違反時は exit 2 + stderr で明示する（環境依存性の排除）。

## 変更対象ファイル

### Phase 1: 新規テンプレート

1. **`skills/aidlc/templates/retrospective_template.md`** — retrospective.md の生成テンプレート
   - **構造**:

     ````markdown
     # Retrospective: {{CYCLE}}

     ## 概要

     本サイクルで発生したプロセス上の問題を振り返り、次サイクルに引き継ぐ。

     ## 問題項目

     <!-- 問題項目が 0 件の場合、以下のような明示行を 1 つ残すこと（空ファイル禁止）:
     ### 問題なし

     本サイクルでは特筆すべきプロセス問題は発生しなかった。
     -->

     ### 問題 1: {{タイトル}}

     **何が起きたか**: {{記述}}

     **なぜ起きたか**: {{記述}}

     **損失と影響**: {{記述}}

     **skill 起因判定**:

     ```yaml
     skill_caused_judgment:
       q1_answer: no    # skill 内の具体的な箇所を引用できるか?
       q1_quote: ""     # q1_answer=yes 時に必須、最小 10 文字
       q2_answer: no    # 別の skill ファイルとの矛盾を示せるか?
       q2_quote: ""     # q2_answer=yes 時に必須、最小 10 文字
       q3_answer: no    # 「どう読んでも複数解釈できる」と示せるか?
       q3_quote: ""     # q3_answer=yes 時に必須、最小 10 文字
     ```

     ## 次サイクルへの引き継ぎ事項

     {{引き継ぎ事項。なしの場合は「なし」と明示}}
     ````

   - **不変条件（テンプレート設計）**:
     - 問題項目は最低 1 件（または「問題なし」明示）→ 自動生成時に空ファイル禁止ガードで保証
     - YAML フロントマターは Markdown コードブロック内に配置（markdownlint 互換）
     - 3 問自問の質問文は `user_stories.md` ストーリー 5 と一字一句一致（コメント内）

### Phase 2: トリガーガード helper

2. **`skills/aidlc/scripts/lib/cycle-version-check.sh`** — `{{CYCLE}}` が `>= v2.5.0` か判定する純粋関数 helper
   - **関数**:
     - `aidlc_is_cycle_v25_or_later <cycle>`: 引数 cycle が `v2.5.0` 以降なら exit 0、`v2.5.0` 未満なら exit 1、入力フォーマット違反なら exit 2
   - **入力契約**:
     - 入力フォーマット: `^v[0-9]+\.[0-9]+\.[0-9]+$`（厳密 semver / pre-release suffix 非対応）
     - フォーマット違反 → exit 2 + `error\tcycle-version-check\tinvalid-format:<input>` を stderr 出力（プロジェクト全体の TSV 規約に統一 / GNU/BSD `sort` 差異の影響を受けない）
   - **実装**: `sort -V` 依存を避け、bash 内蔵の数値比較で major/minor/patch を順に評価（環境差分排除）。実装は `scripts/lib/` 内に関数定義 + 直接実行用 CLI 分岐（`if [ "${BASH_SOURCE[0]}" = "${0}" ]`）。step file からの `bash skills/aidlc/scripts/lib/cycle-version-check.sh "{{CYCLE}}"` 呼び出しと、他 script からの `source` 利用の両方をサポート
   - **副作用なし**: 標準入出力読まない / ファイル書かない / 環境変数依存なし
   - **失敗モード明文化**: 終了コード `0=v2.5.0 以降 / 1=v2.5.0 未満 / 2=フォーマット違反 or 引数不足`

### Phase 3: defaults.toml セクション追加

3. **`skills/aidlc/config/defaults.toml`** — `[rules.retrospective]` セクション追加
   - **追加内容**:

     ```toml
     [rules.retrospective]
     feedback_mode = "silent"
     # 許容値: "silent"（自動生成 + ローカル記録のみ） / "mirror"（自動生成 + 下書き → 承認 → upstream Issue 起票）/ "disabled"（自動生成スキップ）
     # mirror モードの実装は Unit 005 / 上限ガードは Unit 006 を参照
     ```

   - **未対応値の扱い**: `"on"` は v2.6.x 以降スコープ。本 Unit では受け付けない（読み取りロジックは `silent` / `mirror` / `disabled` の 3 値のみ判定）

### Phase 4: ステップファイル追加

4. **`skills/aidlc/steps/operations/04-completion.md`** — retrospective サブステップ追加
   - **挿入位置**: 「3. バックログ記録」と「4. 次期サイクル計画」の間に **「3.5. retrospective 作成」** を挿入（既存番号 4〜8 / 5.5 / 7 はそのまま）
   - **責務分離方針（Step は呼び出し順序と分岐のみ / 実ロジックは script に集約）**: Step 文書は `aidlc_is_cycle_v25_or_later` ガード → `retrospective-generate.sh` 呼び出し → `retrospective-validate.sh` 呼び出しの**順序と分岐のみ**を記述する。`feedback_mode` 解決 / 値判定 / テンプレート展開 / 空ファイル補完 / YAML 解析 / ダウングレードロジックは Step に書かず、全て下記 Phase 5（generate / validate スクリプト）に委譲する。Step が参照するのは「スクリプトの引数 / 終了コード / 出力プレフィックス」の入出力契約のみ
   - **新セクション本文構成**:
     - 安定 ID コメントアンカー: `<!-- guidance:id=unit004-retrospective-creation -->`
     - **Step 1**: `aidlc_is_cycle_v25_or_later "{{CYCLE}}"` で判定（exit 0 → 続行 / exit 1 → `retrospective\tskip\tcycle-too-old` 表示してスキップ / exit 2 → `error\tcycle-version-format\t<input>` 表示して停止）
     - **Step 2**: `retrospective-generate.sh "{{CYCLE}}"` を呼び出し（**`feedback_mode` 解決は generate スクリプトが一元実施**。戻り値: `0=正常終了 / 2=fatal`、出力プレフィックス行で分岐表示）
     - **Step 3（複数行出力時の判定ルール）**: Step 2 の出力に `retrospective\tcreated\t<path>` 行が **1 行以上存在すれば**続行（`warn\t...` 行は無視）/ `retrospective\tskip\tdisabled` または `retrospective\tskip\talready-exists` 行が存在すればスキップ。`retrospective\t...` プレフィックスで始まる行が 0 件かつ `error\t...` 行があれば停止。**判定対象は `retrospective\t` プレフィックス行のみ**で、`warn\t` / `error\t` は補助情報として表示するのみ
     - **Step 4**: 続行時のみ `retrospective-validate.sh validate <生成パス> --apply` を呼び出し（戻り値: `0=正常 / 2=fatal`、`downgrade\t...` プレフィックス行をユーザに表示）
     - **mirror モード固有処理**: Step は「mirror モードの場合は Unit 005 で導入される下書き生成フローに引き継ぐ」旨を明記するのみ。本 Unit ではフロー記述のみで実装は Unit 005
   - **マージ前完結契約との整合**: 本サブステップは `.aidlc/cycles/{{CYCLE}}/**` 配下に retrospective.md を **書き込む**ため、5. PR マージ後の手順より前に配置することが必須（マージ後は exit 3 ガードで拒否される）

### Phase 5: ドメインロジック層スクリプト

#### Phase 5-A: 契約スキーマ（単一参照源）

5a. **`skills/aidlc/config/retrospective-schema.yml`** — retrospective.md の機械可読契約スキーマ
   - **責務**: テンプレート / 生成 / 検証 / Unit 005 / Unit 006 が**唯一参照する**機械可読インターフェース定義（Markdown テンプレートは表示層として扱い、契約はこのスキーマに集約）
   - **内容**:

     ```yaml
     retrospective_schema:
       version: 1
       required_sections:
         - "## 概要"
         - "## 問題項目"
         - "## 次サイクルへの引き継ぎ事項"
       skill_caused_judgment:
         keys:
           - q1_answer
           - q1_quote
           - q2_answer
           - q2_quote
           - q3_answer
           - q3_quote
         questions:
           q1: "skill 内の具体的な箇所を引用できるか?"
           q2: "別の skill ファイルとの矛盾を示せるか?"
           q3: "「どう読んでも複数解釈できる」と示せるか?"
         answer_enum: ["yes", "no"]
         quote_min_length: 10
         quote_forbidden_words: ["該当", "あり", "該当箇所", "あります"]
       skill_caused_rule: "q1_answer / q2_answer / q3_answer のいずれかが yes かつ対応する quote が valid → skill_caused = true"
       valid_feedback_modes: ["silent", "mirror", "disabled"]
       default_feedback_mode: "silent"
       stable_id: "unit004-retrospective-creation"
     ```

   - **下流 Unit との結合方法**: Unit 005 / Unit 006 はこのスキーマを `dasel` でパースしてキー・許容値・禁止語・最小文字数を取得する（テンプレートの文言変更で下流が壊れない構造）

#### Phase 5-B: 生成スクリプト

5b. **`skills/aidlc/scripts/retrospective-generate.sh`** — feedback_mode 解決 + テンプレート展開 + 空ファイル禁止補完を担うドメインロジック
   - **サブコマンド**: `<cycle>` を必須引数として受け取り、内部で `read-config.sh rules.retrospective.feedback_mode` を実行 → 4 分岐:
     - `feedback_mode = disabled` → `retrospective\tskip\tdisabled`（exit 0）
     - 既存ファイルあり → `retrospective\tskip\talready-exists`（exit 0）
     - 不正値（3 値以外） → `warn\tfeedback-mode-invalid\t<value>:downgrade-to-silent` を stderr 出力 + 通常生成へ進む（exit 0）
     - 通常（silent / mirror） → テンプレート展開 + 空ファイル禁止補完 → `retrospective\tcreated\t<path>`（exit 0）
   - **入力**: コマンドライン引数 `<cycle>` のみ（環境変数依存なし）
   - **出力契約（厳密仕様）**: 全行タブ区切り `<kind>\t<code>\t<payload>` フォーマット（`<kind>` は `retrospective` / `warn` / `error` のいずれか / `<code>` は `created` / `skip` / `feedback-mode-invalid` / 各種 error code / `<payload>` は path や value 等）。コロン区切りは使わない（既存 migration 系 `migrate:add-section:<name>` 互換性は廃止し、本 Unit 内で統一）
   - **終了コード**: `0=正常 / 2=fatal`（`1` 不使用）
   - **書き込み方式**: `_safe_transform` 相当（テンプレート読み込み → 一時ファイル → mv の安全パターン）
   - **責務外（明示）**: YAML スキーマ検証 / `q*_answer` ダウングレード判定 / Markdown 内 YAML 抽出は **5c の validate スクリプト** が担当

#### Phase 5-C: 検証スクリプト（3 段責務分割）

5c. **`skills/aidlc/scripts/retrospective-validate.sh`** — retrospective.md のスキーマ検証 + ダウングレード（3 段責務 extract / validate / apply に内部分割）
   - **3 段責務**:
     1. **extract**: Markdown コードブロック内の YAML を抽出し、中間表現として TSV を stdout に出力（`<problem_index>\t<key>\t<value>`）
     2. **validate**: extract の結果を input にして 6 キー存在 / `q*_answer: yes` 時の quote 長 / 禁止語をチェックし `downgrade\t<problem_index>\t<question>\t<reason>` を出力
     3. **apply**: validate の downgrade 行を input にして retrospective.md の YAML を書き換え（backup + rollback でトランザクション化）
   - **サブコマンド**:
     - `extract <retrospective_path>`: 中間表現 TSV のみ出力（責務 1）
     - `validate <retrospective_path>`: extract → validate を実行し downgrade 行 + summary 行を出力（責務 1+2、デフォルト挙動）
     - `validate <retrospective_path> --apply`: extract → validate → apply の全段階を実行（責務 1+2+3）
   - **出力フォーマット（厳密仕様）**: 全行タブ区切り `<kind>\t<code>\t<payload>` フォーマット（generate と統一）
     - `extract`: `extracted\t<problem_index>\t<key>=<value>` / `summary\textracted_keys\t<N>`
     - `validate`: `downgrade\t<problem_index>\t<question>:<reason>` / `summary\tcounts\ttotal=<N>;downgraded=<M>;skill_caused_true=<K>`
     - `--apply`: validate 出力 + 末尾に `applied\t<problem_index>\t<question>` 行
     - 警告 / エラー: `warn\t<code>\t<payload>` / `error\t<code>\t<payload>`
   - **入力**: コマンドライン引数（環境変数依存なし）
   - **終了コード**: `0=正常 / 2=fatal`（`1` 不使用）
   - **書き込み方式**: `--apply` 時のみ `_safe_transform` + backup + rollback。Python YAML パース（既存 fixture 検証で安全性確認）
   - **契約参照**: 検証ルール（quote_min_length=10 / 禁止語 4 種 / 6 キー）は **5a のスキーマ（`retrospective-schema.yml`）から動的に読み込む**（ハードコード回避 / 契約の単一ソース）
   - **テスト分離**: extract / validate / apply の 3 段階それぞれに対して bats ケースを分離し、回帰時の障害切り分けを容易化

### Phase 6: テスト

6. **`tests/retrospective/template-structure.bats`** — テンプレート構造検証
   - **観点 T**: テンプレート存在 + 必須セクション（概要 / 問題項目 / 次サイクルへの引き継ぎ事項）3 件 + skill 起因判定 6 キー + markdownlint パス
7. **`tests/retrospective/cycle-version-check.bats`** — トリガーガード検証（責務 1: helper）
   - **観点 V**: v2.5.0 / v2.5.1 / v2.6.0 / v3.0.0 → exit 0、v2.4.3 / v2.4.0 / v1.0.0 → exit 1、`2.5.0`（v 抜き） / `v2.5` / `vX.Y.Z` / 空文字 → exit 2 の異常系 4 ケース
8. **`tests/retrospective/feedback-mode-resolution.bats`** — feedback_mode 解決検証（責務 2: read-config 連携）
   - **観点 F**: defaults.toml `silent` / user-global `mirror` 上書き / project `disabled` 上書き / 不正値 → silent ダウングレード の 4 ケース
9. **`tests/retrospective/schema-contract.bats`** — 契約スキーマ参照検証（責務 3: 単一ソース）
   - **観点 K**: `retrospective-schema.yml` の 6 キー / 禁止語 4 種 / `quote_min_length=10` / `valid_feedback_modes` 3 値が validate スクリプトから dasel で読み出せる
   - **観点 K2**: テンプレートのコメント内質問文がスキーマの `questions.q1/q2/q3` と一字一句一致（テンプレート文言変更時の検出）
10. **`tests/retrospective/generate-script.bats`** — retrospective-generate.sh 検証（責務 4: 生成）
    - **観点 GE**: 通常生成（`retrospective\tcreated\t<path>`）/ disabled スキップ（`retrospective\tskip\tdisabled`）/ already-exists スキップ（`retrospective\tskip\talready-exists`）/ 不正値 silent ダウングレード警告（`warn\tfeedback-mode-invalid\t<value>:downgrade-to-silent`）+ 生成 の 4 ケース
11. **`tests/retrospective/validate-script.bats`** — retrospective-validate.sh 検証（責務 5: 検証 / 3 段責務分離）
    - **観点 EX（extract）**: コードブロック内 YAML から TSV 抽出が 6 キー × N 問題 = 6N 行 + summary 1 行 で出力される 1 ケース
    - **観点 VA（validate）**: 6 キー揃い + 全部 no → downgrade 0 件、q1_answer=yes + q1_quote 空 → downgrade 1 件、5 文字 / 禁止語単独 → downgrade 1 件、10 文字以上正常値 → skill_caused=true → downgrade 0 件 の 4 ケース
    - **観点 AP（apply）**: --apply で `q1_answer: yes` + 空 quote の項目の `skill_caused` を false に書き換え + ファイル sha 変化、--dry-run 同等（デフォルト）で sha 変化なし の 2 ケース
    - **観点 RB（rollback）**: --apply 中に書き込み失敗（write 不可シミュレーション）→ 元ファイル sha 一致 + `error:apply-failed:rollback-completed` 出力 1 ケース
12. **`tests/retrospective/step-integration.bats`** — 04-completion.md セクション静的検証（責務 6: ステップ）
    - **観点 IS**: ## 3.5 セクション存在 / 安定 ID コメントアンカー / `aidlc_is_cycle_v25_or_later` 呼び出し記述 / `retrospective-generate.sh` 呼び出し記述 / `retrospective-validate.sh validate ... --apply` 呼び出し記述 / Unit 005 引き継ぎ言及 / 既存 4. 5. 5.5 6. 7. 8. の番号がそのままであること

### Phase 7: CI 接続

13. **`.github/workflows/migration-tests.yml`** — テストファイルパス追加
    - `PATHS_REGEX` に `tests/retrospective/.*\.bats` + `skills/aidlc/scripts/retrospective-.*\.sh` + `skills/aidlc/scripts/lib/cycle-version-check\.sh` + `skills/aidlc/config/retrospective-schema\.yml` + `skills/aidlc/templates/retrospective_template\.md` を追加
    - 実行コマンドに `bats tests/retrospective/` を追加

## 完了条件チェックリスト

- [x] `skills/aidlc/templates/retrospective_template.md` が新規作成され、3 セクション（概要 / 問題項目 / 次サイクルへの引き継ぎ事項）+ skill 起因判定 6 キー（q1_answer/q1_quote/q2_answer/q2_quote/q3_answer/q3_quote）が含まれている
- [x] テンプレート差分の markdownlint パス
- [x] `skills/aidlc/config/retrospective-schema.yml` が新規作成され、6 キー / 質問文 / `quote_min_length=10` / 禁止語 4 種 / `valid_feedback_modes` 3 値 / stable_id を機械可読 YAML として保持している
- [x] `skills/aidlc/scripts/lib/cycle-version-check.sh` が `aidlc_is_cycle_v25_or_later` 関数を提供し、v2.5.0 以降は exit 0 / 未満は exit 1 / フォーマット違反は exit 2 を返す
- [x] `skills/aidlc/config/defaults.toml` に `[rules.retrospective] feedback_mode = "silent"` が追加されている
- [x] `skills/aidlc/steps/operations/04-completion.md` に「3.5. retrospective 作成」サブステップが追加され、安定 ID コメントアンカー `unit004-retrospective-creation` が直前行に配置されている
- [x] サブステップは Step 1（cycle-version-check）→ Step 2（retrospective-generate.sh 呼び出し / feedback_mode 解決は generate 側責務）→ Step 3（出力プレフィックス分岐 / created なら続行 / skip なら停止）→ Step 4（続行時のみ retrospective-validate.sh validate --apply 呼び出し）の 4 ステップ構成で**呼び出し順序と分岐のみ**を記述し、判定ロジックは含まない
- [x] 既存 4. 5. 5.5 6. 7. 8. のセクション番号は変更されていない（追加のみ）
- [x] サブステップの位置はマージ前完結契約に従い「3. バックログ記録」と「4. 次期サイクル計画」の間（5. PR マージ後の手順より前）
- [x] `skills/aidlc/scripts/retrospective-generate.sh` が `<cycle>` 引数 + `feedback_mode` 解決一元化 + テンプレート展開 + 4 分岐（disabled スキップ / already-exists スキップ / 不正値 silent ダウングレード警告 / 通常生成）+ 空ファイル禁止補完 + 全行タブ区切り `<kind>\t<code>\t<payload>` フォーマット出力（`retrospective\tcreated\t<path>` / `retrospective\tskip\tdisabled` / `retrospective\tskip\talready-exists` / `warn\t...` / `error\t...`）を実装している
- [x] `skills/aidlc/scripts/retrospective-validate.sh` が **3 段責務（extract / validate / apply）** に内部分割され、`extract` / `validate` / `validate --apply` の 3 サブコマンド + タブ区切り出力（extracted / downgrade / summary / applied）を実装している
- [x] validate スクリプトが検証ルール（quote_min_length=10 / 禁止語 4 種 / 6 キー）を **`retrospective-schema.yml` から動的に読み込む**（ハードコード回避）
- [x] script の終了コードが `0=正常 / 2=fatal`（generate / validate 共通）。`1` を使用しない
- [x] generate / validate `--apply` が `_safe_transform` 相当（backup + rollback）で retrospective.md を保護する
- [x] **観点 T テスト**: template-structure.bats が必須セクション + skill 起因判定 6 キー + markdownlint パスの 3 ケース PASS
- [x] **観点 V テスト**: cycle-version-check.bats が v2.5.0 以降 4 種 + 未満 3 種 + フォーマット違反異常系 4 種の 11 ケース PASS
- [x] **観点 F テスト**: feedback-mode-resolution.bats が defaults / user-global / project / 不正値 の 4 ケース PASS
- [x] **観点 K テスト**: schema-contract.bats が validate スクリプトのルール参照 + テンプレート文言一致の 2 ケース PASS
- [x] **観点 GE テスト**: generate-script.bats が 通常生成 / disabled / already-exists / 不正値ダウングレード の 4 ケース PASS
- [x] **観点 EX/VA/AP/RB テスト**: validate-script.bats が EX（抽出 1）+ VA（検証 4）+ AP（適用 2）+ RB（ロールバック 1）の 8 ケース PASS
- [x] **観点 IS テスト**: step-integration.bats が ## 3.5 セクション存在 + 安定 ID + cycle-version-check 呼び出し + retrospective-generate.sh 呼び出し + retrospective-validate.sh --apply 呼び出し + Unit 005 引き継ぎ言及 + 既存番号保持 の 7 ケース PASS
- [x] CI 接続: `.github/workflows/migration-tests.yml` の PATHS_REGEX 拡張（schema yml / generate / validate / lib helper / template 5 種を追加）と実行コマンド追加で PR 上で `bats tests/retrospective/` が走る
- [x] 既存の `tests/migration/` / `tests/config-defaults/` / `tests/aidlc-setup/` / `tests/aidlc-migrate-prefs/` のテストが回帰せずパスする（119 件 → 150+ 件想定）
- [x] `.md` 差分の markdownlint パス
- [x] Unit 004 定義（`story-artifacts/units/004-retrospective-template-and-step.md`）の実装状態が「完了」に更新されている

## NFR チェック

- **空ファイル禁止**: generate-script.bats（観点 GE）で問題項目が 0 件のテンプレート展開時に「問題なし」明示が自動補完されることを実機検証（generate スクリプト責務）
- **markdownlint パス**: テンプレート + 04-completion.md + retrospective-schema.yml 差分を `markdownlint-cli2` で実機検証（CI で自動）
- **トリガー精度**: cycle-version-check.bats（観点 V）で v2.5.0 未満のサイクル（v2.4.3 / v1.0.0 等）に対して exit 1 を返し、フォーマット違反入力（`2.5.0` / `v2.5` / 空文字 等）に対して exit 2 を返すことを実機検証

## 想定リスクと対策

| リスク | 対策 |
|--------|------|
| YAML フロントマターのパースが MD のコードブロック内記述で破壊される（dasel が直接 YAML として認識しない） | `retrospective-validate.sh` 内で「Markdown コードブロック → YAML 抽出 → dasel パース」の 2 段階処理を実装。テスト fixture でコードブロック有無両方をカバー |
| 04-completion.md の既存番号繰り下げで他ドキュメントの相互参照が壊れる | 番号を**変更せず**「3.5」を新設する設計（既存 4 / 5 / 5.5 / 6 / 7 / 8 はそのまま）。step-integration.bats（観点 IS）で番号保持を回帰検証 |
| マージ前完結契約違反（retrospective.md がマージ後に書き込まれる） | サブステップ位置を「3. バックログ記録」と「4. 次期サイクル計画」の間（5. PR マージ後の手順より前）に固定。step-integration.bats（観点 IS）で位置を grep 検証 |
| `feedback_mode` の不正値（`"on"` 等 v2.6.x 以降スコープ）が誤って動作する | サブステップで 3 値（silent / mirror / disabled）以外を `silent` にダウングレード + 警告ログ。feedback-mode-resolution.bats（観点 F）で実機検証 |
| skill 起因判定の不正値（10 文字未満 / 禁止語）検出ロジックが LLM が記述するテンプレートで揺れる | `retrospective-validate.sh` で機械的に判定（bash + python YAML パース）。validate-script.bats（観点 G）で禁止語 4 種 + 10 文字未満 + 空文字の網羅検証 |
| Unit 005 / 006 への引き継ぎ点が曖昧で二重保守が発生する | 本 Unit で **`retrospective-schema.yml`** を機械可読契約として単一ソース化。Unit 005 / 006 はテンプレート文言ではなくスキーマファイルを `dasel` でパースしてキー・許容値・禁止語を取得する。テンプレート文言変更で下流が壊れない設計（schema-contract.bats 観点 K2 で文言一致を回帰検証） |
| Step とドメインロジックの責務が混在し Step 文書とスクリプトが二重保守になる | Step は呼び出し順序と分岐のみ記述、ロジックは generate / validate スクリプトに集約。step-integration.bats（観点 IS）でスクリプト呼び出し記述の存在を grep 検証 |
| validate スクリプトが extract / validate / apply の混在で障害切り分けが困難 | スクリプトを 3 段サブコマンド（extract / validate / validate --apply）に分割し、各段で TSV 中間表現を介してインターフェース固定。bats も EX / VA / AP / RB の 4 観点に分離して回帰時の責務単位検証を可能にする |
| `sort -V` の GNU/BSD 差異で cycle-version-check が環境依存になる | bash 内蔵の数値比較で major/minor/patch を順に評価する実装に切替。入力フォーマット契約（`^v[0-9]+\.[0-9]+\.[0-9]+$`）を厳格化し、違反時は exit 2 + stderr で明示。cycle-version-check.bats（観点 V）で異常系 4 ケースを実機検証 |

## 関連 Issue

- #590（部分対応: 実装スコープ 1, 2, 3, 4 を担当 / 5 は Unit 005 / 7-a 7-b は Unit 006）

## 見積もり

1.0 セッション（テンプレート設計 + ステップ追加 + validate script 実装 + テスト 5 ファイル + 既存ステップ番号保持確認込み）
