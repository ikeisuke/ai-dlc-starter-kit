# Unit 005 計画: mirror モードの /aidlc-feedback 連動

## 概要

`feedback_mode = "mirror"` 設定下で、Operations Phase の retrospective サブステップ（Unit 004 で導入された `## 3.5`）の Step 4 完了直後に動く mirror フローを実装する。具体的には:

1. retrospective.md の YAML フロントマター（Unit 004 の派生値ロジック）を再走査して `skill_caused = true` の問題項目を抽出
2. 抽出された各項目について Markdown スニペット形式の Issue 下書きを生成（タイトル / 本文 / 検出元: サイクル・Unit / 引用箇所）
3. `AskUserQuestion` で「送信する / 送信しない / 後で判断（保留）」の 3 択提示（Step 文書側の責務）
4. 「送信する」選択時: `/aidlc-feedback` スキル経路（または `gh issue create` 直接呼び出し）で upstream Issue 起票し、Issue URL を retrospective.md の該当項目に追記
5. 「送信しない / 保留」選択時: retrospective.md にローカル注記のみ追記（Issue 起票しない）
6. `feedback_mode != "mirror"` の場合（`silent` / `disabled`）は本フロー全体スキップ

Unit 004 が定義した `retrospective-schema.yml` を**単一ソース**として参照し、テンプレート文言には依存しない設計とする。Unit 006（重複検出 + サイクル毎上限）は本 Unit のフロー前段に挿入される設計のため、本 Unit では「skill_caused=true の全項目を順に処理する」最小フローを実装し、上限ガード / 重複統合は Unit 006 で導入する。

## 前提条件と関連 Unit

- **Unit 004 完了済み**: `retrospective-schema.yml` / `retrospective_template.md` / `retrospective-generate.sh` / `retrospective-validate.sh` / `04-completion.md ## 3.5` Step 1〜4 が実装済み
- **Unit 006 への引き継ぎ点**:
  - 本 Unit が導入する `retrospective-mirror.sh detect` 出力（TSV）のうち、Unit 006 はその「順序付き入力」を加工して重複統合 + 上限ガードを差し込む
  - 本 Unit のサブコマンド境界（detect / send / record）と TSV スキーマは Unit 006 でも単一ソースとして再利用される
- **Intent 確定範囲との整合**: feedback_mode 値の正式定義（DR-004 / Intent §「feedback_mode 値の正式定義」）に従い、`mirror` は「下書き生成 → 承認 → 起票」を行う唯一の値、`on` は v2.5.0 スコープ外（DR-002）

## 対象ストーリー

| # | ストーリー | 受け入れ基準（要約） |
|---|-----------|---------------------|
| 6 | feedback_mode=mirror の /aidlc-feedback 連動 | mirror モード時に下書き生成 / `AskUserQuestion` 3 択提示 / 「送信する」で upstream Issue 起票 + URL を retrospective.md に追記 / 「送信しない・保留」でローカル記録のみ / silent では丸ごとスキップ |

成功基準 #2（Intent §「成功基準」）の (a)〜(c) を満たすことが本 Unit の主目的:

- (a) 下書き本文生成（Markdown スニペット出力）
- (b) `AskUserQuestion` で承認取得（「送信する」選択時に進行）
- (c) `gh issue create` 成功（Issue URL 採番を stdout で確認）

## 現状分析

### `skills/aidlc/scripts/retrospective-validate.sh`（Unit 004 完了済み）

- `validate <path>` / `validate <path> --apply` の 2 段で 6 キー検証 + ダウングレード書き換えを実施
- summary 行末で `summary\tcounts\ttotal=<N>;downgraded=<M>;skill_caused_true=<K>` を出力（mirror フローはこの行で `skill_caused_true > 0` を判定可能）
- ただし「どの問題項目が skill_caused=true か」は summary 行には含まれない → mirror 側で 6 キーから派生計算する必要あり（Unit 004 の派生値原則に従う）

### `skills/aidlc-feedback/steps/feedback.md`（既存）

- `gh issue create --web` 経由で Issue 作成画面を**ブラウザで開く**設計（手動編集 + 手動送信）
- `--non-interactive` モードや `--body-file` での非対話送信は現状サポートなし
- mirror モードでは「下書き本文を作成 → ユーザー承認後に実 issue 化」という 1 ターンの自動送信が必要 → 既存スキルをそのまま流用すると体験が分断される

### `skills/aidlc/steps/operations/04-completion.md ## 3.5`（Unit 004 完了済み）

- Step 1（cycle-version-check）→ Step 2（generate）→ Step 3（出力プレフィックス分岐）→ Step 4（validate --apply）の 4 ステップ構成
- 「Mirror モード固有処理（Unit 005 引き継ぎ）」セクションが既に予約され、本 Unit はそこに `## 3.5 Step 5 (mirror フロー)` を追加する

### Issue 送信経路の選定

| 候補 | 経路 | メリット | デメリット | 採否 |
|------|------|---------|-----------|------|
| A. `/aidlc-feedback` スキル拡張 | スキル本体に `--reason mirror --non-interactive --body-file ...` を追加 | スキル単一窓口に集約 | `aidlc-feedback` の責務が複雑化、テストパスが分散、ブラウザ経路（`--web`）を破壊するリスク | 不採用 |
| B. mirror 側で `gh issue create --body-file` 直接呼び出し（送信先設定は共通化） | retrospective-mirror.sh が `gh issue create` を直接呼ぶ。送信先 owner/repo は `defaults.toml` の `[rules.feedback] upstream_repo` から解決 | 経路が明示的、ロールバック容易、テスト範囲狭い、送信先設定が単一ソース | (緩和済) スキル間の重複は upstream_repo 単一ソースで解消 | **採用** |

**採用根拠**: Story 6 の受け入れ基準は「`/aidlc-feedback` スキル（または `gh issue create`）」で **OR 条件**。Unit 005 の境界（「単純に skill_caused=true なら下書き生成 → 承認 → 送信」）に照らすと、`gh issue create` 直接呼び出しの方が責務が単一に閉じる。Unit 005 は `aidlc-feedback` の挙動には触れない（既存ブラウザ経路を破壊しない）。

#### Unit 定義「`/aidlc-feedback` スキル経路」との差分理由（トレーサビリティ）

Unit 定義 §責務に「`/aidlc-feedback` スキル経由で Issue 起票」と記載があるが、本計画では `gh issue create` 直接呼び出し（候補 B）を採用する。差分理由:

1. **Story 6 受け入れ基準は OR 条件**: 「`/aidlc-feedback` スキル（または `gh issue create`）」と明記
2. **既存 `/aidlc-feedback` のブラウザ経路（`gh issue create --web`）破壊回避**: 既存スキルは `--web` 前提でブラウザ確認画面を開くため、非対話 `--body-file` への拡張は責務複雑化
3. **`AskUserQuestion` 承認は Step 文書側に既に存在**: スキル内の確認画面と二重承認になるため経路が明確な直接呼び出しの方が簡素

将来 `/aidlc-feedback` を非対話モード対応にリファクタリングする場合の条件:

- `/aidlc-feedback` 自体が `--non-interactive --body-file` を 1 級サポートに拡張
- 送信先 owner/repo の単一ソース化が `aidlc-feedback` 側で完了
- mirror フローと CLI 引数互換のラッパー API が用意される

上記 3 条件が揃った場合に Unit 005 のリファクタとして本計画の候補 B → 候補 A 切替を別 Issue で実施する。本判断は意思決定記録 DR-006（本計画と同時に追記予定）にリンクする。

#### 送信先設定の単一ソース化（Codex 指摘 #1 対応）

`gh issue create` の `--repo` 値は `defaults.toml` の `[rules.feedback] upstream_repo` キーから読み込む（Unit 005 で新規追加）。`/aidlc-feedback` 側はリファクタ時に同キーを参照するように切り替える計画とし、**現時点ではキーの新規導入のみ Unit 005 スコープ内**とする（aidlc-feedback の書き換えは別 Issue）。これにより:

- 送信先のハードコードを mirror フローから排除
- 将来 `/aidlc-feedback` も同キー参照へリファクタ可能
- メタ開発リポジトリ以外でセルフホストする利用者が `~/.aidlc/config.toml` で上書き可能

**Unit 技術考慮事項**: `--reason mirror` を本文先頭の機械可読タグ（`[mirror-reason] cycle=<v>; problem_index=<N>`）として注入し、送信先側で経路識別が可能になる。

## 変更対象ファイル

### Phase 1: 新規スクリプト（mirror フローのドメインロジック）

| ファイル | 種別 | 用途 |
|----------|------|------|
| `skills/aidlc/scripts/retrospective-mirror.sh` | 新規 | mirror フローの 3 サブコマンド（`detect` / `send` / `record`）|

### Phase 2: スキーマ拡張（mirror_state を機械可読契約として追加）

| ファイル | 種別 | 用途 |
|----------|------|------|
| `skills/aidlc/config/retrospective-schema.yml` | 変更 | `mirror_state` セクション追加（state enum / issue_url / recorded_at の 3 キー）。Unit 004 の単一ソース原則に従い、Markdown 文言ではなく機械可読キーで「送信済み / 保留 / 送信しない」状態を表現する（Codex 指摘 #4 対応）|
| `skills/aidlc/config/defaults.toml` | 変更 | `[rules.feedback] upstream_repo = "ikeisuke/ai-dlc-starter-kit"` 新規追加（送信先 owner/repo の単一ソース、Codex 指摘 #1 対応）|

### Phase 3: Step 文書（呼び出し順序のみ）

| ファイル | 種別 | 用途 |
|----------|------|------|
| `skills/aidlc/steps/operations/04-completion.md` | 変更 | `## 3.5 Step 5 (mirror フロー)` 追加。`feedback_mode` 解決は `retrospective-mirror.sh detect` に一本化、Step は `mirror\tskip\|candidate` 行のみ解釈（Codex 指摘 #3 対応）|

### Phase 4: テスト

| ファイル | 種別 | 用途 |
|----------|------|------|
| `tests/retrospective-mirror/helpers/setup.bash` | 新規 | mirror テスト共通ヘルパー（fixture コピー + gh モック設定）|
| `tests/retrospective-mirror/detect.bats` | 新規 | `detect` サブコマンドの観点 D（4 ケース：skill_caused=true / 全 false / mirror モード以外 / retrospective.md 不在）|
| `tests/retrospective-mirror/send.bats` | 新規 | `send` サブコマンドの観点 S（4 ケース：gh 成功 / gh 失敗 / URL 追記 / `--reason mirror` ヘッダ反映）|
| `tests/retrospective-mirror/record.bats` | 新規 | `record` サブコマンドの観点 R（3 ケース：保留 / 送信しない / 不明な選択肢）|
| `tests/retrospective-mirror/step-integration.bats` | 新規 | `## 3.5 Step 5` セクション存在 + 安定 ID + retrospective-mirror.sh 呼び出し記述 + AskUserQuestion 分岐記述 + `feedback_mode != mirror` スキップ言及（観点 IM）|
| `tests/fixtures/retrospective-mirror/`（複数 fixture） | 新規 | mirror フロー検証用 retrospective.md 雛形 |

### Phase 5: CI 接続

| ファイル | 種別 | 用途 |
|----------|------|------|
| `.github/workflows/migration-tests.yml` | 変更 | PATHS_REGEX 追加（`tests/retrospective-mirror/.*\.bats`、`skills/aidlc/scripts/retrospective-mirror\.sh`）+ 実行コマンドに `bats tests/retrospective-mirror/` を追記 |

## 実装方針

### `retrospective-mirror.sh` のサブコマンド構成

#### 終了コード規約（Codex 指摘 #2 対応 / 失敗分類の 2 系統化）

全サブコマンドで以下の規約を統一適用する:

| exit code | 出力プレフィックス | 意味 | Step 5 側の動作 |
|-----------|------------------|------|----------------|
| `0` + `mirror\tsent\|recorded\|...` | 主要ステータス | 正常完了 | 次の candidate 処理へ続行 |
| `0` + `mirror\tsend-failed\t<idx>\t<reason>` | recoverable failure | 個別 candidate 単位の失敗（gh-not-authenticated / gh-rate-limit / network-timeout 等）| 警告表示して次の candidate へ続行（フロー全体は止めない）|
| `2` + `error\t<code>\t<payload>` | fatal failure | フロー継続不能（retrospective.md 書き込み失敗 + rollback 完了 / schema 不在 / dasel 不在 / 引数不正 等）| Step 5 全体を停止し、ユーザーに通知 |

**recoverable failure 列の reason 列挙**: `gh-not-authenticated` / `gh-rate-limit` / `gh-network-error` / `gh-unknown-error` の 4 種に固定。これ以外（書き込み権限・スキーマ違反など）は fatal 系へマッピングする。

#### サブコマンド詳細

```text
retrospective-mirror.sh detect <retrospective.md>
  入力: retrospective.md パス
  出力（stdout）:
    - mirror\tskip\t<reason>（feedback_mode != mirror or skill_caused=true 0 件 or 全件処理済み）
    - mirror\tcandidate\t<problem_index>\t<title>\t<draft_body_path>（複数行可、未処理項目のみ）
    - summary\tcounts\ttotal=<N>;skill_caused_true=<M>;already-processed=<P>
  出力（stderr）: warn\t* / error\t*
  責務:
    - feedback_mode 解決を**本サブコマンドに一本化**（read-config.sh 経由 / Step は呼ばない / Codex 指摘 #3 対応）
    - mirror 以外は mirror\tskip\tnot-mirror-mode を 1 行出力して exit 0
    - validate スクリプトの extract ロジックを共有（共通ヘルパー scripts/lib/retrospective-extract.sh への切り出しを設計フェーズで再評価）
    - skill_caused=true の問題項目を派生値として再計算（Unit 004 の派生値原則）
    - **mirror_state.state ∈ {sent, skipped, pending}**（スキーマ機械可読キー / Codex 指摘 #4 対応）の項目は candidate 対象外
    - 各 candidate について Markdown スニペット下書きを `/tmp/retrospective-mirror-draft.<index>.<random>.md` へ書き出し
  exit 0: 正常（candidate あり / mirror\tskip\t* いずれも 0）
  exit 2: fatal（schema 不在 / dasel 不在 / retrospective.md 不在 / 引数不正）

retrospective-mirror.sh send <retrospective.md> <problem_index> <title> <draft_body_path>
  入力: retrospective.md / 問題インデックス / Issue タイトル / 下書き本文ファイル
  出力（stdout）:
    - mirror\tsent\t<problem_index>\t<issue_url>（成功）
    - mirror\tsend-failed\t<problem_index>\t<reason>（recoverable failure / exit 0）
  出力（stderr）:
    - error\t<code>\t<payload>（fatal / exit 2）
  責務:
    - send 先の owner/repo は read-config.sh rules.feedback.upstream_repo から解決（defaults.toml の `[rules.feedback] upstream_repo` を単一ソースとする / Codex 指摘 #1 対応）
    - `gh auth status` を事前チェック → 失敗時は mirror\tsend-failed\t<idx>\tgh-not-authenticated + exit 0（recoverable）
    - `gh issue create --repo <upstream_repo> --title <title> --body-file <draft_body_path>` を実行
    - 本文先頭に `[mirror-reason] cycle=<v>; problem_index=<N>` を機械可読タグとして挿入
    - `gh` の exit code を gh-rate-limit / gh-network-error / gh-unknown-error に分類し recoverable 化（exit 0 + send-failed）
    - 採番 Issue URL を取得し、retrospective.md の該当問題項目末尾の YAML フロントマター block の `mirror_state` セクションへ書き込み（state=sent / issue_url=<url> / recorded_at=<ISO8601>）
    - 書き込みは _safe_transform 相当（backup → tmp → mv → rollback）で実施
    - retrospective.md 書き込み失敗 → exit 2 + error\tapply-failed\trollback-completed
  exit 0: 正常 + recoverable failure
  exit 2: fatal（retrospective.md 書き込み失敗 / 引数不正 / schema 不在）

retrospective-mirror.sh record <retrospective.md> <problem_index> <decision>
  入力: retrospective.md / 問題インデックス / decision（`skipped` / `pending`）
  出力（stdout）: mirror\trecorded\t<problem_index>\t<decision>
  出力（stderr）: error\tinvalid-decision\t<value>（fatal / exit 2）
  責務:
    - retrospective.md の該当問題項目の YAML フロントマター内 `mirror_state` を書き込み（state=skipped|pending / recorded_at=<ISO8601>、issue_url は空文字）
    - decision の不正値（skipped / pending 以外）は exit 2
  exit 0: 正常
  exit 2: fatal（不正値 / 書き込み失敗 / 引数不正）
```

#### `mirror_state` スキーマ拡張（Codex 指摘 #4 対応）

`retrospective-schema.yml` に以下を追加:

```yaml
retrospective_schema:
  # ...(既存定義)
  mirror_state:
    keys: [state, issue_url, recorded_at]
    state_enum: [sent, skipped, pending, ""]  # 空文字は未処理
    state_default: ""
    issue_url_default: ""
    recorded_at_default: ""
```

`retrospective_template.md` の各問題項目内 YAML フロントマターに `mirror_state` 初期値ブロックを追加（Unit 004 の派生値原則を維持しつつ、状態管理キーは別 namespace）:

```yaml
skill_caused_judgment:
  q1_answer: "no"
  q1_quote: ""
  # ...(既存)
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
```

これにより detect の「処理済み判定」は Markdown 文言ではなく機械可読キー（`mirror_state.state != ""`）で行える。

##### 後方互換ルール（旧形式 retrospective.md 対応 / Codex Round 2 指摘 #1 対応）

`mirror_state` キーは Unit 005 で新規追加されるため、Unit 004 で生成された retrospective.md には存在しない。detect は以下の互換ルールに従う:

- `mirror_state` ブロック欠落時 → `state=""` と同等扱い（candidate 対象として処理続行 / fatal 扱い禁止）
- `mirror_state.state` キー欠落時 → 同上（state=""）
- `mirror_state.issue_url` / `recorded_at` キー欠落時 → 空文字とみなす
- 旧形式 retrospective.md に対して send / record を実行する場合、書き込み時に `mirror_state` ブロックを新規追加する（テンプレート全文書き換えではなく該当 YAML ブロックの末尾追記）

**理由**: Unit 005 リリース後、利用者が v2.5.0 アップグレード前に生成した retrospective.md を mirror モードで再走査するケースが想定される。旧形式 fatal 扱いはユーザー体験を損ねるため、欠落キーは安全側にデフォルト値で吸収する。

**テスト fixture 追加**: `tests/fixtures/retrospective-mirror/legacy-no-mirror-state/`（mirror_state ブロック欠落 retrospective.md）を追加し、detect / send / record の各サブコマンドが旧形式入力でも正常動作することを観点 D / S / R で検証する。

### Step 5（`## 3.5 Step 5 (mirror フロー)`）の本文構成

`feedback_mode` 解決は detect サブコマンドが一元管理する（Codex 指摘 #3 対応 / Step では呼ばない）。Step は detect の出力プレフィックス（`mirror\tskip` / `mirror\tcandidate`）のみで分岐する。

```text
1. retrospective-mirror.sh detect <retrospective.md> 呼び出し
2. detect 出力を解析（exit code != 0 は fatal stop）
   - mirror\tskip\t<reason> 行 → スキップ理由（not-mirror-mode / no-skill-caused / all-processed）を表示してフロー終了
   - mirror\tcandidate 行 1 件以上 → ループ処理へ
3. 各 candidate について:
   a. AskUserQuestion で「送信する / 送信しない / 後で判断（保留）」の 3 択提示
   b. 「送信する」 → retrospective-mirror.sh send <retrospective> <idx> <title> <draft_body_path>
      - exit 0 + mirror\tsent\t... → サマリに記録
      - exit 0 + mirror\tsend-failed\t<idx>\t<reason> → 警告表示して次の candidate へ（recoverable）
      - exit 2 + error\t... → フロー全体停止（fatal）
   c. 「送信しない」 → retrospective-mirror.sh record <retrospective> <idx> skipped
      - exit 0 + mirror\trecorded\t... → 記録完了表示
      - exit 2 → fatal stop
   d. 「保留」 → retrospective-mirror.sh record <retrospective> <idx> pending
4. 全 candidate 処理完了後、サマリ行を集計表示（sent=N / skipped=M / pending=K / send-failed=L）
```

### 派生値（skill_caused）再計算の責務

- `validate --apply` で q*_answer がダウングレード済み（yes → no）の retrospective.md を入力とする
- detect スクリプトは validate と同じスキーマファイル（retrospective-schema.yml）を `dasel` で動的読み込み
- 6 キー（q1_answer / q1_quote / q2_answer / q2_quote / q3_answer / q3_quote）から `is_skill_caused()` を都度計算（Unit 004 の派生値原則）
- 一致するロジックを Unit 004 から取り込むため、`scripts/lib/retrospective-skill-caused.sh` 共通ヘルパーへ切り出すことを設計フェーズで再評価する（決定は Phase 1 ドメインモデル時）

### 下書き本文テンプレート

```markdown
**検出元**: mirror（v2.5.0+ / cycle: <cycle> / problem_index: <N>）

**問題タイトル**: <title>

**何が起きたか**:

<what_happened>

**なぜ起きたか（skill 起因判定）**:

<why_happened>

**skill 内の引用箇所**:

- q1_quote: <q1_quote>（answer: <q1_answer>）
- q2_quote: <q2_quote>（answer: <q2_answer>）
- q3_quote: <q3_quote>（answer: <q3_answer>）

**損失と影響**:

<loss_and_impact>

---
> このドラフトは AI-DLC v2.5.0+ の mirror モードで自動生成されました。
> 元の retrospective: `.aidlc/cycles/<cycle>/operations/retrospective.md` の問題 <N>
```

## 完了条件チェックリスト

### スコープ完遂

- [x] `retrospective-mirror.sh` の 3 サブコマンド（detect / send / record）が実装され、それぞれの観点（D / S / R）でテストが PASS する（detect 7 / send 6 / record 6 = 19 ケース PASS）
- [x] `## 3.5 Step 5 (mirror フロー)` が `04-completion.md` に追加され、step-integration.bats（観点 IM）が PASS する（5 ケース PASS）
- [x] `feedback_mode = "mirror"` 設定下で「下書き生成 → AskUserQuestion 3 択 → gh issue create + URL 追記」のフローが動作する（成功基準 #2 (a)(b)(c) 充足 / send.bats 観点 S 5 ケースで検証済み）
- [x] `feedback_mode = "silent"`（デフォルト）と `"disabled"` の場合、本フロー全体がスキップされる（detect.bats で `mirror skip not-mirror-mode` 検証済み）

### 品質基準

- [x] bats テスト合計 14 件以上が PASS（実績: detect 7 + send 6 + record 6 + step-integration 5 = **24 件 PASS**）
- [x] shellcheck で警告ゼロ（`retrospective-mirror.sh` / SC1091 SC2016 info のみ。actionable 0 件）
- [x] markdownlint で警告ゼロ（`04-completion.md` 差分。`bats tests/retrospective/` の T3 / IS テストで間接検証）
- [x] 既存 retrospective テスト（`tests/retrospective/`）が引き続き全件 PASS（実績: **43/43 PASS**）
- [x] `.github/workflows/migration-tests.yml` に PATHS_REGEX 追加 + 実行コマンド拡張済み（`tests/retrospective-mirror/.+` / `tests/fixtures/retrospective-mirror/.+` 追加）

### Issue 受け入れ基準（#590 Story 6）との対応

- [x] mirror モード時 retrospective サブステップが各 `skill_caused=true` 項目について Markdown スニペット形式の下書きを生成（detect サブコマンドが `IssueDraft` を `/tmp/retrospective-mirror-draft.<idx>.<random>.md` に書き出し、検出元 / タイトル / 引用箇所 / 損失影響を含む）
- [x] 各下書きについて `AskUserQuestion` で「送信する / 送信しない / 後で判断（保留）」の 3 択を提示（Step 5-3 に明記、step-integration.bats で検証）
- [x] 「送信する」選択時: Issue URL が stdout で確認できる + retrospective.md に追記される（send.bats で検証）
- [x] 「送信しない / 保留」選択時: retrospective.md にローカル注記のみ追記、Issue 起票しない（record.bats で検証）
- [x] `feedback_mode = "silent"` ではフロー全体がスキップされる（detect.bats で検証）
- [x] `defaults.toml` の `[rules.retrospective] feedback_mode = "silent"` が引き続き有効（Unit 004 から変更なし）

### Unit 006 への引き継ぎ点

- [x] `retrospective-mirror.sh detect` の TSV 出力スキーマが安定し、Unit 006 の重複検出 + 上限ガードが間に挿入できる構造であること（フィルタ層を後付け可能 / `mirror\tcandidate\t<idx>\t<title>\t<draft_path>` 固定）
- [x] サブコマンド境界（detect / send / record）が独立しており、Unit 006 で送信前ガードを `record` 経路へリダイレクトする実装が可能（送信先決定は Step 5-3 のみで行うためフィルタ層を間に挟みやすい構成）

## 既知のリスクとミティゲーション

### リスク 1: gh CLI の認証状態（recoverable failure として扱う）

- **リスク**: メタ開発環境では `gh auth status` が通っているが、利用者環境で未認証の場合 `gh issue create` が失敗する
- **ミティゲーション**: send サブコマンドは `gh auth status` を事前チェックし、未認証時は `mirror\tsend-failed\t<index>\tgh-not-authenticated` を出力して **exit 0**（recoverable）で次の candidate に進む。フロー全体は停止しない。本動作は §「終了コード規約」と整合（fatal failure は retrospective.md 書き込み失敗 / schema 不在のみが該当）

### リスク 2: 同時並行起動による Issue 重複

- **リスク**: Unit 006 の重複検出は同一サイクル内に限定される（Intent 制約）。複数セッションで同時に mirror フローを動かすと同一項目が二重起票される可能性
- **ミティゲーション**: send 完了時に retrospective.md の YAML フロントマター `mirror_state.state` を `sent` に書き込み（**機械可読キー / Markdown 文言ではない / 単一ソース原則維持**）。後続の detect は同フィールドが空文字以外の項目を candidate 対象外とする（Codex 指摘 #4 対応の派生形）

### リスク 3: ネットワーク障害でフローが長時間ブロック

- **リスク**: `gh issue create` がタイムアウトしない場合、ユーザー体験が悪化
- **ミティゲーション**: `gh issue create` は Unix 環境の標準タイムアウト（gh 内蔵）に任せ、Step 文書側で「タイムアウトを観測した場合は record pending にフォールバックする」運用ガイドを Step 5 末尾に注記する（自動リトライは v2.6.x 以降）

### リスク 4: 送信先 owner/repo の設定揺れ

- **リスク**: defaults.toml の `[rules.feedback] upstream_repo` を user-global で上書きされた場合、メタ開発リポジトリ以外への送信が発生する
- **ミティゲーション**: `defaults.toml` のコメントで「フォーク利用や貢献先変更時のみ user-global で上書きする」ガイドを残す。値は `^[a-zA-Z0-9._/-]+$` で形式検証し、不正値は警告表示してデフォルト（`ikeisuke/ai-dlc-starter-kit`）にフォールバック

## 推定工数

- Phase 1（設計）: 0.4 セッション（ドメインモデル + 論理設計 + AI レビュー対応）
- Phase 2（実装）: 0.5 セッション（mirror.sh 実装 + Step 5 追記 + bats テスト 16 件 + 修正反映）
- Phase 3（完了処理）: 0.1 セッション

合計 1.0 セッション（Unit 定義の見積もりと一致）

## 関連ドキュメント

- Intent: `.aidlc/cycles/v2.5.0/requirements/intent.md`
- ストーリー 6: `.aidlc/cycles/v2.5.0/story-artifacts/user_stories.md`
- Unit 005 定義: `.aidlc/cycles/v2.5.0/story-artifacts/units/005-mirror-feedback-integration.md`
- Unit 004 ドメインモデル: `.aidlc/cycles/v2.5.0/design-artifacts/domain-models/unit_004_retrospective_template_and_step_domain_model.md`
- Unit 004 論理設計: `.aidlc/cycles/v2.5.0/design-artifacts/logical-designs/unit_004_retrospective_template_and_step_logical_design.md`
- 意思決定記録: `.aidlc/cycles/v2.5.0/inception/decisions.md`
  - DR-002: #590 のスコープ範囲
  - DR-004: feedback_mode 値設計
  - DR-005: skill_caused 判定の入力スキーマ
  - **DR-006**: Unit 005 mirror フローの送信経路と失敗契約（本計画と同時に追記）
- Unit 004 既存実装:
  - `skills/aidlc/scripts/retrospective-generate.sh`
  - `skills/aidlc/scripts/retrospective-validate.sh`
  - `skills/aidlc/templates/retrospective_template.md`
  - `skills/aidlc/config/retrospective-schema.yml`
  - `skills/aidlc/steps/operations/04-completion.md`（`## 3.5` Step 1〜4）
