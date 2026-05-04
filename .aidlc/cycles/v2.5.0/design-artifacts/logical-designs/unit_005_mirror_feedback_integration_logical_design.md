# 論理設計: Unit 005 mirror モードの /aidlc-feedback 連動

## 概要

`feedback_mode = mirror` 設定下で retrospective.md の skill_caused=true 項目を upstream Issue として起票する mirror フローを実装する。Unit 004 で確立した **Strict Step-Script Separation Pattern**（Step は呼び出し順序のみ / Script はドメインロジック）を踏襲し、機械可読契約スキーマ（`retrospective-schema.yml`）への拡張で `mirror_state` を単一ソース管理する。

**Unit 005 のスコープ（明示）**:

| 項目 | スコープ内／外 |
|------|---------------|
| `skills/aidlc/scripts/retrospective-mirror.sh` 新規作成（detect / send / record の 3 サブコマンド）| **スコープ内**（主目的）|
| `skills/aidlc/config/retrospective-schema.yml` への `mirror_state` セクション追加 | **スコープ内** |
| `skills/aidlc/config/defaults.toml` への `[rules.feedback] upstream_repo` 追加 | **スコープ内** |
| `skills/aidlc/templates/retrospective_template.md` への `mirror_state` 初期値ブロック追加 | **スコープ内** |
| `skills/aidlc/steps/operations/04-completion.md ## 3.5 Step 5` 追加（既存 Step 1〜4 はそのまま）| **スコープ内** |
| `tests/retrospective-mirror/*.bats` および helpers / fixtures 新規作成 | **スコープ内** |
| `.github/workflows/migration-tests.yml` の PATHS_REGEX + 実行コマンド拡張 | **スコープ内** |
| 重複検出 + サイクル毎上限ガード | **スコープ外**（Unit 006）|
| `on` モード（自動起票）| **スコープ外**（v2.6.x 以降）|
| `/aidlc-feedback` スキルの非対話モード対応 | **スコープ外**（DR-006 リファクタ条件達成後の別 Issue）|

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的な bash 実装 / bats アサーション / YAML 差分 / Markdown 文言は Phase 2（コード生成）で作成する。

## アーキテクチャパターン

**Strict Step-Script Separation Pattern**（Unit 004 から継承）+ **後方互換セーフフォールバック**（Unit 005 で追加）。Step 文書は呼び出し順序と分岐のみを記述、判定ロジック / I/O / 検証ルールは bash script に集約する。**機械可読契約スキーマ拡張**で `mirror_state` を導入し、Markdown 文言依存を完全排除（Codex Round 1 指摘 #4 / Round 2 指摘 #1 対応）。

**選定理由**:

- Unit 004 と同一パターンを踏襲することで、Unit 006 への引き継ぎが直線的になる（パターン認知の重複コスト排除）
- Step 文書側に AskUserQuestion を残すことで、ユーザー対話と機械処理の責務分離を明確化（mirror 固有の対話要件）
- mirror_state の機械可読化により、Markdown 文言変更で下流が壊れない単一ソース原則を維持
- 失敗契約の 2 系統分離（recoverable / fatal）はパターンとして Unit 003 から継続採用（DR-006）

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc/
├── config/
│   ├── retrospective-schema.yml                   [変更]  mirror_state セクション追加
│   └── defaults.toml                              [変更]  [rules.feedback] upstream_repo 追加
├── templates/
│   └── retrospective_template.md                  [変更]  mirror_state 初期値ブロック追加
├── scripts/
│   ├── retrospective-mirror.sh                    [新規]  detect / send / record の 3 サブコマンド
│   └── lib/
│       └── retrospective-skill-caused.sh          [新規/評価]  6 キーから派生値計算する共通ヘルパー（Unit 004 の validate と共有可否を Phase 2 設計で決定）
└── steps/operations/
    └── 04-completion.md                           [変更]  ## 3.5 Step 5 追加（既存 Step 1〜4 はそのまま）

tests/retrospective-mirror/
├── helpers/
│   └── setup.bash                                 [新規]
├── detect.bats                                    [新規]
├── send.bats                                      [新規]
├── record.bats                                    [新規]
└── step-integration.bats                          [新規]

tests/fixtures/retrospective-mirror/
├── single-skill-caused-empty/                     [新規]  skill_caused=true × 1 件 / mirror_state.state=Empty
├── multiple-skill-caused-empty/                   [新規]  skill_caused=true × 3 件 / 全て Empty
├── mixed-state/                                   [新規]  Sent / Skipped / Pending / Empty が混在（detect 候補抽出の境界）
├── no-skill-caused/                               [新規]  全項目 skill_caused=false（detect スキップ条件）
├── feedback-mode-silent/                          [新規]  feedback_mode=silent（detect スキップ条件）
├── feedback-mode-disabled/                        [新規]  feedback_mode=disabled（同上）
└── legacy-no-mirror-state/                        [新規]  Unit 004 形式（mirror_state ブロック不在 / 後方互換検証）

.github/workflows/
└── migration-tests.yml                            [変更]  PATHS_REGEX 4 種追加 + 実行コマンド拡張
```

### コンポーネント間の依存関係

```text
[04-completion.md ## 3.5 Step 5（mirror フロー）]
   │
   │ Step 1: retrospective-mirror.sh detect 呼び出し
   ▼
[retrospective-mirror.sh detect <retrospective.md>]
   │
   ├──→ [read-config.sh rules.retrospective.feedback_mode]
   │       │ (4 階層マージで mirror 判定)
   │       │ (mirror 以外は mirror\tskip\tnot-mirror-mode 出力 / exit 0)
   │       ▼
   │     [defaults.toml + user-global + project-shared + project-local]
   │
   ├──→ [retrospective-schema.yml] (dasel で動的読み込み)
   │       │ (mirror_state.keys / state_enum / 既存 skill_caused_judgment)
   │       ▼
   │     検証ルール + 状態列挙（ハードコードなし）
   │
   ├──→ [retrospective-validate.sh extract] 経由 or 共有ヘルパー
   │       │ (Unit 004 の extract ロジック共有)
   │       ▼
   │     6 キー TSV 中間表現
   │
   ├──→ [retrospective-skill-caused.sh] (Phase 2 で要否決定)
   │       │ (派生値計算 / 6 キー → skill_caused)
   │       ▼
   │     候補判定（is_candidate × skill_caused）
   │
   ├──→ stdout: mirror\tskip\t<reason> / mirror\tcandidate\t<idx>\t<title>\t<draft_path> / summary\t...
   │            + IssueDraft を /tmp/retrospective-mirror-draft.<idx>.<random>.md へ書き出し
   └──→ stderr: warn\t* / error\t*
   │
   │ Step 2-3: Step 文書側で AskUserQuestion（Send / Skip / Pending）
   ▼
[retrospective-mirror.sh send <retrospective.md> <idx> <title> <draft_body_path>]   ← UserDecision == Send 時
   │
   ├──→ [gh auth status]
   │       │ (失敗時は mirror\tsend-failed\t<idx>\tgh-not-authenticated / exit 0)
   │       ▼
   │     recoverable failure 分類
   │
   ├──→ [read-config.sh rules.feedback.upstream_repo]
   │       │ (UpstreamRepo 解決 / 不正値はデフォルトフォールバック)
   │       ▼
   │     [defaults.toml [rules.feedback] upstream_repo]
   │
   ├──→ [gh issue create --repo <upstream_repo> --title <title> --body-file <draft_body_path>]
   │       │ (成功時は Issue URL 取得 / 失敗時は SendFailureReason 分類)
   │       ▼
   │     upstream Issue（GitHub 側）
   │
   ├──→ [_safe_transform で mirror_state を Sent に書き換え]
   │       │ (backup → tmp → mv → rollback)
   │       ▼
   │     [retrospective.md の YAML フロントマター内 mirror_state ブロック]
   │
   ├──→ stdout: mirror\tsent\t<idx>\t<url> / mirror\tsend-failed\t<idx>\t<reason>
   └──→ stderr: error\t<code>\t<payload>（fatal / exit 2）
   │
   │ または Step 文書側で record 呼び出し（UserDecision == Skip / Pending 時）
   ▼
[retrospective-mirror.sh record <retrospective.md> <idx> <decision>]
   │
   ├──→ decision バリデーション（skipped / pending 以外は exit 2）
   │
   ├──→ [_safe_transform で mirror_state を Skipped/Pending に書き換え]
   │       │ (mirror_state ブロック欠落時は新規追加 / 後方互換)
   │       ▼
   │     [retrospective.md]
   │
   ├──→ stdout: mirror\trecorded\t<idx>\t<decision>
   └──→ stderr: error\tinvalid-decision\t<value>（fatal / exit 2）
   │
   │ Step 4: 全 candidate 処理完了後にサマリ表示
   ▼
[ユーザに完了サマリ提示（sent=N / skipped=M / pending=K / send-failed=L）]
```

**依存方向の原則**:

- Step → Script 単方向（Script は Step を知らない）
- Script → Schema 単方向（Schema は Script を知らない）
- Script → defaults.toml は read-only 経由（read-config.sh）
- mirror サブコマンド間の依存は Step 文書側のオーケストレーションのみ（detect → send/record）

**循環依存なし**:

- detect → schema / validate ロジック / config（DAG 構成）
- send / record → schema / config / retrospective.md（DAG 構成）
- Unit 004 の retrospective-validate.sh は本 Unit から read-only 参照（書き換えなし）

## モジュール / コンポーネント詳細

### コンポーネント A: `skills/aidlc/scripts/retrospective-mirror.sh`（新規）

#### 目的

mirror フロー全体のドメインロジック（detect / send / record）を 1 ファイルに集約。Unit 004 の `retrospective-validate.sh` と同等の責務粒度・終了コード規約・出力フォーマットを採用する。

#### サブコマンド構成

| サブコマンド | 引数 | 主要責務 | exit code |
|------------|------|---------|----------|
| `detect` | `<retrospective.md>` | feedback_mode 解決 / candidate 抽出 / IssueDraft 生成 | 0（候補ありなしいずれも） / 2（fatal） |
| `send` | `<retrospective.md> <problem_index> <title> <draft_body_path>` | gh issue create + mirror_state を Sent に更新 | 0（成功 + recoverable failure） / 2（fatal） |
| `record` | `<retrospective.md> <problem_index> <decision>` | mirror_state を Skipped/Pending に更新 | 0（成功） / 2（fatal） |

#### 終了コード規約（DR-006 対応）

| exit code | 出力 | 意味 |
|-----------|------|------|
| `0` + 主要ステータス | `mirror\tsent\|recorded\|...` | 正常完了 |
| `0` + recoverable | `mirror\tsend-failed\t<idx>\t<reason>` | 個別 candidate 単位の失敗（5 種固定: gh-not-installed / gh-not-authenticated / gh-rate-limit / gh-network-error / gh-unknown-error）。値は `retrospective-schema.yml` の `send_failure_reasons` と単一ソース同期 |
| `2` + fatal | `error\t<code>\t<payload>` | フロー継続不能（retrospective 書き込み失敗 / schema 不在 / dasel 不在 / 引数不正） |

`1` は使用しない（Unit 004 と同方針 / set -e 文脈での誤判定回避）。

### コンポーネント B: `skills/aidlc/config/retrospective-schema.yml`（変更）

#### 目的

`mirror_state` セクションを既存 `skill_caused_judgment` セクションに並列して追加。Unit 005 / Unit 006 が共有する単一ソース。

#### 追加内容

```yaml
retrospective_schema:
  # ...(既存定義: version / required_sections / skill_caused_judgment / valid_feedback_modes / default_feedback_mode / stable_id)
  mirror_state:
    keys: [state, issue_url, recorded_at]
    state_enum: ["sent", "skipped", "pending", ""]
    state_default: ""
    issue_url_default: ""
    recorded_at_default: ""
    issue_url_pattern: '^https://github\.com/[^/]+/[^/]+/issues/[0-9]+$'
    recorded_at_pattern: '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
  mirror_reason_tag_format: "[mirror-reason] cycle={cycle}; problem_index={problem_index}"
```

#### 動的読み込み契約

- detect / send / record いずれも `dasel query -i yaml` で動的読み込み
- 後方互換: 旧形式 retrospective.md（mirror_state ブロック未保持）は state="" 同等扱い（Rule 5）

### コンポーネント C: `skills/aidlc/config/defaults.toml`（変更）

#### 目的

`[rules.feedback] upstream_repo` セクションを既存 13 セクションに追加。`/aidlc-feedback` 側の将来リファクタで参照源にする想定（DR-006）。

#### 追加内容

```toml
[rules.feedback]
# Issue 送信先 owner/repo（v2.5.0 で追加 / Unit 005）
# - mirror モードの retrospective Issue 送信先
# - フォーク利用や貢献先変更時のみ user-global で上書きする
# - 形式: <owner>/<repo>（正規表現: ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ / `/` はちょうど 1 個）
upstream_repo = "ikeisuke/ai-dlc-starter-kit"
```

#### 静的検証

- `feedback-config.bats`（観点 D 内）で defaults / user-global / project の各層からの読み出しと不正値フォールバックを検証

### コンポーネント D: `skills/aidlc/templates/retrospective_template.md`（変更）

#### 目的

各問題項目内の YAML フロントマターに `mirror_state` 初期値ブロックを追加。Unit 004 の派生値原則を維持しつつ、状態管理キーを別 namespace で扱う。

#### 追加内容（問題項目テンプレート末尾の YAML ブロック内）

```yaml
skill_caused_judgment:
  # ...(既存 6 キー)
mirror_state:
  state: ""
  issue_url: ""
  recorded_at: ""
```

#### 静的検証

- `retrospective-mirror/template-structure.bats`（既存 template-structure.bats を拡張）で mirror_state の初期値存在 + markdownlint パスを検証

### コンポーネント E: `skills/aidlc/steps/operations/04-completion.md`（変更）

#### 目的

`## 3.5 Step 5 (mirror フロー)` を既存 Step 1〜4 直後に追加。既存番号 4 / 5 / 5.5 / 6 / 7 / 8 はそのまま。

#### 静的構造

- 安定 ID コメントアンカー: `<!-- guidance:id=unit005-mirror-flow -->` を `## 3.5 Step 5` 直前行に配置
- 本文構成: Step 1（detect 呼び出し）→ Step 2（出力プレフィックス分岐）→ Step 3（candidate ループ + AskUserQuestion + send/record 分岐）→ Step 4（サマリ表示）
- `feedback_mode` 解決は detect 内一本化のため、Step では `read-config.sh` を呼ばない

#### Step 5 の判定優先順位

1. **最優先 / exit code != 0**: detect / send / record の exit が `2` の場合、即時停止（`error\t...` 行を表示）
2. **続行判定 / `mirror\tcandidate\t...`**: 1 行以上存在で Step 3（candidate ループ）へ
3. **スキップ判定 / `mirror\tskip\t<reason>`**: フロー終了（next Step / `## 4. 次期サイクル計画` へ）
4. **send 結果分岐**:
   - `mirror\tsent\t...` → サマリに加算
   - `mirror\tsend-failed\t...` → 警告表示してループ続行（recoverable）
5. **record 結果**: `mirror\trecorded\t...` → サマリに加算

### コンポーネント F: `skills/aidlc/scripts/lib/retrospective-skill-caused.sh`（新規 / Phase 2 で要否決定）

#### 目的

6 キーから skill_caused を派生計算する純粋関数 helper。Unit 004 の `retrospective-validate.sh` 内ロジックと共有する。

#### Phase 2 での評価ポイント

- Unit 004 の validate スクリプト内では awk で一括処理しており切り出しコスト > 共有メリットの可能性
- 切り出し採用条件: detect 側でも awk ベースで実装可能 ∧ 既存 validate に対する rewrite が低コスト
- 切り出し見送り条件: 各スクリプト内で独立実装した方がテスト分離しやすい場合

決定は Phase 2 コード生成時にコスト見積もりして確定する。本論理設計では「共通ヘルパー候補」として記録のみ。

### コンポーネント G: `tests/retrospective-mirror/*.bats`（新規）

各観点に対応する bats テスト群。

| ファイル | 観点 | ケース数 | カバレッジ目的 |
|---------|------|---------|--------------|
| `detect.bats` | D（候補抽出）| 6 | mirror モード以外スキップ × 3（silent / disabled / 不正値） + skill_caused あり candidate 抽出 + skill_caused なし時 skip + legacy fixture |
| `send.bats` | S（送信）| 5 | gh 成功 / gh 未認証 recoverable / gh ネットワークエラー recoverable / retrospective 書き込み失敗 fatal / mirror_state 書き込み確認 |
| `record.bats` | R（記録）| 4 | skipped 記録 / pending 記録 / 不正 decision fatal / legacy fixture への新規 mirror_state 追加 |
| `step-integration.bats` | IM（ステップ統合）| 5 | `## 3.5 Step 5` セクション存在 + 安定 ID `unit005-mirror-flow` + retrospective-mirror.sh detect/send/record 呼び出し記述 + AskUserQuestion 3 択言及 + 既存 Step 1〜4 保持 |
| **合計** | - | **20** | - |

#### Fixture 設計

| Fixture | 用途 |
|---------|------|
| `single-skill-caused-empty` | skill_caused=true × 1 件 / state=Empty（detect が candidate 1 件出力）|
| `multiple-skill-caused-empty` | skill_caused=true × 3 件 / 全て Empty（detect が candidate 3 件出力 / Unit 006 用にも再利用）|
| `mixed-state` | Sent / Skipped / Pending / Empty 各 1 件（detect は Empty かつ skill_caused=true のみ抽出）|
| `no-skill-caused` | 全項目 skill_caused=false（detect が `mirror\tskip\tno-skill-caused` 出力）|
| `feedback-mode-silent` | feedback_mode=silent（detect が `mirror\tskip\tnot-mirror-mode` 出力）|
| `feedback-mode-disabled` | feedback_mode=disabled（同上）|
| `legacy-no-mirror-state` | mirror_state ブロック未保持（detect / send / record 全てが Empty 同等扱い + record 時に新規ブロック追加）|

## インターフェース定義

### 入力インターフェース

| インターフェース | 入力源 | フォーマット |
|------------------|--------|-------------|
| `retrospective-mirror.sh detect <retrospective.md>` | コマンドライン | 既存ファイルパス |
| `retrospective-mirror.sh send <retrospective.md> <problem_index> <title> <draft_body_path>` | コマンドライン | 上記 + 整数 + 文字列 + ファイルパス |
| `retrospective-mirror.sh record <retrospective.md> <problem_index> <decision>` | コマンドライン | 上記 + 整数 + `skipped\|pending` |
| `read-config.sh rules.retrospective.feedback_mode` | 4 階層マージ | TOML 値（silent / mirror / disabled / 不正値） |
| `read-config.sh rules.feedback.upstream_repo` | 4 階層マージ | TOML 値（`<owner>/<repo>` フォーマット） |
| `retrospective-schema.yml` | dasel 動的読み込み | YAML |

### 出力インターフェース（厳密タブ区切り `<kind>\t<code>\t<payload>`）

| 出力 | 出力先 | 例 |
|------|--------|-----|
| candidate 抽出 | stdout | `mirror\tcandidate\t1\tタイトル\t/tmp/retrospective-mirror-draft.1.abc.md` |
| feedback_mode スキップ | stdout | `mirror\tskip\tnot-mirror-mode` |
| no-skill-caused スキップ | stdout | `mirror\tskip\tno-skill-caused` |
| 全件処理済みスキップ | stdout | `mirror\tskip\tall-processed` |
| Issue 起票成功 | stdout | `mirror\tsent\t1\thttps://github.com/ikeisuke/ai-dlc-starter-kit/issues/700` |
| recoverable failure | stdout | `mirror\tsend-failed\t1\tgh-not-authenticated` |
| 記録成功 | stdout | `mirror\trecorded\t1\tskipped` |
| 集計 | stdout 最終行 | `summary\tmirror-flow\tsent=1;skipped=0;pending=0;send-failed=1` |
| 致命エラー | stderr + exit 2 | `error\tapply-failed\trollback-completed` |

### 終了コード

- `0`: 正常終了 + recoverable failure 含む
- `2`: fatal エラー
- `1`: **使用しない**（Unit 003 / 004 と同方針）

## エラーハンドリング戦略

### エラーカテゴリと対応

| カテゴリ | 例 | 対応 | 出力プレフィックス |
|---------|-----|------|------------------|
| 引数不足 | `detect` 引数なし | exit 2 + stderr | `error\tusage\tretrospective-mirror.sh detect\|send\|record ...` |
| retrospective.md 不在 | 指定パス存在せず | exit 2 + stderr | `error\tretrospective-not-found\t<path>` |
| schema 不在 | retrospective-schema.yml 不在 | exit 2 + stderr | `error\tschema-not-found\t<path>` |
| dasel 未インストール | dasel 不在 | exit 2 + stderr | `error\tdasel-not-installed\tinstall-required` |
| feedback_mode 不正値 | 値が不正値 | warn + skip | detect が `mirror\tskip\tnot-mirror-mode` を出力（warn ログは stderr）|
| upstream_repo 不正値 | 値がフォーマット違反 | warn + デフォルトフォールバック | stderr に `warn\tupstream-repo-invalid\t<value>:fallback-to-default` |
| gh 未インストール | `command -v gh` 失敗 | recoverable failure | `mirror\tsend-failed\t<idx>\tgh-not-installed` + exit 0 |
| gh 未認証 | `gh auth status` 失敗 | recoverable failure | `mirror\tsend-failed\t<idx>\tgh-not-authenticated` + exit 0 |
| gh rate limit | gh stderr に rate limit 文言 | 同上 | `mirror\tsend-failed\t<idx>\tgh-rate-limit` |
| gh network error | gh stderr に DNS / timeout | 同上 | `mirror\tsend-failed\t<idx>\tgh-network-error` |
| gh その他 | 上記いずれにも該当しない gh 失敗 | 同上 | `mirror\tsend-failed\t<idx>\tgh-unknown-error` |
| retrospective 書き込み失敗 | _safe_transform で mv 失敗 | rollback + exit 2 | `error\tapply-failed\trollback-completed` |
| invalid decision | `record` の 3 引数が不正 | exit 2 | `error\tinvalid-decision\t<value>` |

### NFR 観点との対応

| NFR | 該当エラー | 検証方法 |
|-----|-----------|---------|
| 誤起票防止 | AskUserQuestion 承認なしの起票 | step-integration.bats（観点 IM）で `## 3.5 Step 5` 内の AskUserQuestion 言及を検証 |
| 送信失敗ハンドリング | gh エラーで retrospective に PENDING_MANUAL 記録 | send.bats（観点 S）の recoverable ケースで mirror_state.state が Empty のまま残る + send-failed 出力を検証 |
| トレーサビリティ | Issue URL 追記 | send.bats（観点 S）の成功ケースで mirror_state.issue_url が GitHub URL パターンと一致することを検証 |
| 後方互換 | mirror_state 欠落時 | 全 fixture 群の `legacy-no-mirror-state` で detect / send / record 全件成功を検証 |

## テスト戦略

### テスト分類と観点

合計 20 ケース PASS（Phase 1 計画値の +4 ケース）:

- detect.bats: 6 ケース（観点 D）
- send.bats: 5 ケース（観点 S）
- record.bats: 4 ケース（観点 R）
- step-integration.bats: 5 ケース（観点 IM）

### 統合テストカバレッジ目標

- 既存 158 件（Unit 004 完了時点）+ 新規 20 件 = **178 件**（170+ 件想定 +α）
- ローカル `bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/ tests/aidlc-migrate-prefs/ tests/retrospective/ tests/retrospective-mirror/` で全件 PASS を確認

## CI 接続

### `.github/workflows/migration-tests.yml` 拡張

#### PATHS_REGEX 追加

- `tests/retrospective-mirror/.*\.bats`
- `skills/aidlc/scripts/retrospective-mirror\.sh`
- `skills/aidlc/scripts/lib/retrospective-skill-caused\.sh`（Phase 2 で採用された場合）
- `skills/aidlc/templates/retrospective_template\.md`（既存だが mirror_state 追加変更を検出するため）

#### 実行コマンド追加

- `bats tests/retrospective-mirror/`

## 後方互換性 / 既存テストへの影響

### 影響範囲（明示）

- 既存 retrospective テスト（`tests/retrospective/`）: **影響あり**。template-structure.bats で mirror_state 初期値ブロック追加に対する検証を追加（既存テストは PASS 維持）
- 既存 4 階層マージテスト（`tests/config-defaults/`）: 影響なし（`[rules.feedback]` セクションは新規追加のみ）
- 既存 migration テスト（`tests/migration/`）: 影響なし
- 既存 aidlc-setup / aidlc-migrate-prefs テスト: 影響なし

### Unit 004 との互換性

- Unit 004 で生成された retrospective.md（mirror_state 不在）は Unit 005 detect でも fatal 拒否されない（Rule 5 / 後方互換）
- Unit 004 の retrospective-validate.sh は Unit 005 から read-only 参照（書き換えなし）
- Unit 004 のスキーマ + テンプレート + Step は、本 Unit 拡張で**破壊変更を受けない**

### 04-completion.md への影響

- **既存 Step 1〜4 / 既存 ## 4 / ## 5 / ## 5.5 / ## 6 / ## 7 / ## 8 は変更せず**、`## 3.5 Step 5` を新設のみ
- step-integration.bats（観点 IM）で既存 Step 1〜4 の保持を回帰検証

## ドキュメント差分

### 新規ファイル（10 件）

- `skills/aidlc/scripts/retrospective-mirror.sh`
- `skills/aidlc/scripts/lib/retrospective-skill-caused.sh`（Phase 2 で採用判定）
- `tests/retrospective-mirror/helpers/setup.bash`
- `tests/retrospective-mirror/detect.bats`
- `tests/retrospective-mirror/send.bats`
- `tests/retrospective-mirror/record.bats`
- `tests/retrospective-mirror/step-integration.bats`
- `tests/fixtures/retrospective-mirror/*`（7 fixtures）

### 変更ファイル（4 件）

- `skills/aidlc/config/retrospective-schema.yml`（mirror_state セクション追加）
- `skills/aidlc/config/defaults.toml`（[rules.feedback] upstream_repo 追加）
- `skills/aidlc/templates/retrospective_template.md`（mirror_state 初期値ブロック追加）
- `skills/aidlc/steps/operations/04-completion.md`（## 3.5 Step 5 追加）
- `.github/workflows/migration-tests.yml`（PATHS_REGEX + 実行コマンド拡張）

## Unit 006 への引き継ぎ点（明示）

### Unit 006（重複検出 + サイクル毎上限ガード）

- **参照点**: `retrospective-mirror.sh detect` の TSV 出力スキーマ（`mirror\tcandidate\t<idx>\t<title>\t<draft_path>`）
- **挿入位置**: Step 5 の Step 1（detect 呼び出し）と Step 3（candidate ループ）の間に「重複検出 + 上限ガード」フィルタ層を差し込む（detect 出力を Unit 006 がフィルタリング → Step 3 へ渡す）
- **インターフェース**: 同じ TSV スキーマを入力 → フィルタ後の TSV を出力（追加で `mirror\tskip\tduplicate\t<idx>` / `mirror\tskip\tover-limit\t<idx>` 出力種別を追加）
- **再利用**: detect / send / record の境界は Unit 006 でも維持される（Unit 006 は detect の出力後・send 呼び出し前のフィルタ層として実装される）

## ガイド照合チェック（メタ開発時）

- `guides/exit-code-convention.md`: 終了コード規約（0 / 2 / 3 ガード）と整合 → ✓ 0 = 正常 + recoverable / 2 = fatal / 3 = post-merge ガード（本 Unit ではマージ前完結のため発生しない）
- `guides/error-handling.md`: 出力プレフィックス規約 / stdout-stderr 分離 → ✓ Unit 004 と同方針
- `guides/backlog-management.md`: バックログ運用 → ✓ Unit 005 のスコープ外（Unit 006 / v2.6.x 追加分）は GitHub Issue として登録予定
