# Unit 002 計画: retrospective Issue 一本化 + spool + mirror_state ラベル化

## 概要

`steps/operations/04-completion.md §1.5` を「ローカル `retrospective.md` 生成 + mirror Issue 起票」の二段構造から、
**最初から GitHub Issue 起票で完結する単一フロー**に刷新する。`mirror_state` の状態は Issue ラベルで保持し、
`gh_status != available` 時は `cycles/{{CYCLE}}/history/retrospective-spool.md` にスプールして次回 `gh` 利用可能時に
`scripts/retrospective-resend.sh` で再送する経路を提供する。v2.5.0 の `retrospective.md` ファイル / `mirror_state`
YAML 形式は読み取り側で互換維持する。

本 Unit は他 Unit から呼び出される **共有 I/F の編集主体** であり、Unit 003（LLM 下書き）は本 Unit が用意する
`prefill` 入力経路を経由して下書きを Issue 本文に埋め込む。Unit 004（predecessor 検索）は本 Unit が定義する
`RETROSPECTIVE_LABEL` / `MIRROR_STATE_LABEL_PREFIX` 命名規約定数を検索キーとして利用する。

## 関連 Issue

- #590 partial（retrospective テンプレ + Operations Phase 自動生成、v2.5.0 で導入済 → 本 Unit で Issue 化により一本化）
- #592 partial（個人好み設定の user-global 寄せ、v2.5.0 で導入済 → 本 Unit はテンプレを Issue 本文用に転換するのみで、設定階層は変更しない）

## 関連サイクル設計判断（Intent 参照）

- §「主要設計判断 6.1」ラベル / Milestone 命名規約: 本 Unit が `RETROSPECTIVE_LABEL` / `MIRROR_STATE_LABEL_PREFIX` を起票時に付与する正本
- §「主要設計判断 6.2」retrospective Issue 本文構造: 本 Unit が `retrospective_body_compose()` で生成する正本
- §「主要設計判断 6.3」LLM 下書き出力契約: Unit 003 → Unit 002 の prefill 経路として、本 Unit が受け入れスキーマを固定
- §「主要設計判断 6.4」`human_reviewed` 付与責任: 本 Unit は `false` で起票し、Unit 003 が `true` へ更新する責務分界
- §「主要設計判断 6.5」04-completion §1.5 編集主体: 本 Unit が §1.5 ステップ記述を全面書き換えする
- §「主要設計判断 5」`feedback_max_per_cycle` モード別適用範囲: 本 Unit が Unit 001 の `feedback_cap_check()` を呼ぶ際の `mode` 引数渡し方を確定
- §「リスク 1」緩和策（スプール）: 本 Unit が `gh_status != available` 時に `history/retrospective-spool.md` へ書き込み、`retrospective-resend.sh` で再送する経路を実装
- §「リスク 4」緩和策（mirror_state ラベル化 + YAML 互換）: 本 Unit がラベル付与と YAML 埋め込みを両方行う

## 変更対象ファイル

### 新規作成

- `skills/aidlc/scripts/lib/retrospective-issue.sh`（共有関数: `retrospective_issue_create()` / `retrospective_body_compose()` / 命名規約定数 / 重複検出 / スプール書込）
- `skills/aidlc/scripts/retrospective-resend.sh`（新規 CLI: スプールエントリ → Issue 起票 → スプール削除）
- `tests/retrospective-issue-create.bats`（重複検出 / `feedback_mode` 別の起票先振り分け / `gh_status` 別動作 / cap 超過時のスキップ）
- `tests/retrospective-body-compose.bats`（共有契約 6.2 構造 / Unit 003 prefill 入力スキーマ受け入れ / `human_reviewed:false` 初期値 / `mirror_state` YAML 埋め込み）
- `tests/retrospective-spool.bats`（gh 不可時のスプール書込 / 既存スプールへの追記 / スプールフォーマット契約）
- `tests/retrospective-resend.bats`（スプール読取 → Issue 起票 → スプール削除の正常系 / 部分失敗時の残存スプール / gh 復旧確認）
- `tests/operations-04-completion-section1-5.bats`（§1.5 ステップ呼び出しの統合テスト: feedback_mode 解決 → wizard → cap → 起票 / spool / mirror_state ラベル付与）

### 変更

- `skills/aidlc/steps/operations/04-completion.md`（**§1.5 全面書き換え**: ローカル `retrospective.md` 生成撤廃 / Issue 起票統合 / Unit 001 関数呼び出し / Unit 003 prefill フック差し込み口 / spool 分岐）
- `skills/aidlc/scripts/retrospective-generate.sh`（**互換アダプタ層化** / 指摘 #3 反映で保証範囲を下記表に固定）
- `skills/aidlc/scripts/retrospective-mirror.sh`（**互換アダプタ層化** / 指摘 #3 反映で保証範囲を下記表に固定）

#### 互換アダプタ層 保証範囲（指摘 #3 反映）

「互換アダプタ層化」の保証 / 非保証 / 廃止予定を以下に固定する。これにより `04-completion.md §1.5` 以外の既存呼び出し元（ある場合）が後方互換で動作することを確認できる。

| スクリプト | 保証する旧 I/F（互換維持） | 非保証 / 廃止する I/F | 廃止予定時期 |
|-----------|----------------------------|----------------------|--------------|
| `retrospective-generate.sh` | 旧 stdout プレフィックス契約: `retrospective\tcreated\t<path>` / `retrospective\tskip\tdisabled` / `retrospective\tskip\talready-exists` の **行構造**は維持。引数 `<CYCLE>` 受け入れ。終了コード（0=正常 / 2=fatal）。 | ローカル `retrospective.md` ファイル生成（**廃止**）。新フローでは `<path>` は **起票された Issue URL** にリプレース（`retrospective\tcreated\t<issue_url>` を返す）するか、`retrospective\tskip\tissue-only-mode` に置換。設計フェーズで確定。 | v2.6.x 以降で完全削除候補（外部呼び出し元を grep して影響なしを確認後） |
| `retrospective-mirror.sh` | 旧 stdout プレフィックス契約: `mirror\tskip\tnot-mirror-mode` / `mirror\tskip\tno-skill-caused` / `mirror\tskip\tall-processed` / `mirror\tcandidate\t<idx>\t<title>\t<draft_path>` / `mirror\tsent\t<idx>\t<url>` / `mirror\tsend-failed\t<idx>\t<reason>` / `mirror\trecorded\t<idx>\t<state>`。サブコマンド `detect` / `send` / `record` の引数受け入れ。終了コード（0=正常 / 2=fatal）。 | candidate ループ + AskUserQuestion 形式のフロー（**廃止**）。`detect` は新フローの起票結果を旧プレフィックスで再構成し（`sent` / `send-failed` / `recorded` のいずれかへマッピング）出力。`record` の `pending` / `skipped` 引数受理は旧 retrospective.md 書き込み機能ではなく Issue ラベル更新に置換。 | v2.6.x 以降で完全削除候補 |

**外部呼び出し元の影響判定**: 設計フェーズで `rg "retrospective-(generate|mirror)\.sh"` 検索を実施し、`§1.5` 以外の呼び出し元が無いことを確認する。呼び出し元が存在する場合は廃止予定を v2.7.x 以降に延期し、deprecation warning を stdout 補助行（プレフィックス `warn\t...`）として追加する。

#### 互換アダプタ層 旧→新 意味マッピング（指摘 #4 反映）

旧プレフィックス出力を canonical に変換する際の意味マッピングを以下に確定する。**意味が一致しない曖昧語彙は非保証扱い**として明示する。

| 旧プレフィックス語彙 | 旧の意味 | canonical 値 | 意味の一致度 | 取扱 |
|----------------------|----------|--------------|-------------|------|
| `mirror\tsent` | upstream 起票成功 | `created` | 完全一致 | 保証 |
| `mirror\tsend-failed` | upstream 起票失敗（再送可能） | `error` | 完全一致 | 保証 |
| `mirror\trecorded\tskipped` | ユーザーが「送信しない」を明示選択 | `skipped:max_exceeded` または `skipped:duplicate`（コンテキスト不明時 `skipped:max_exceeded`） | 部分一致（cap / duplicate の区別不能） | **非保証**（warn + 保守的選択） |
| `mirror\trecorded\tpending` | ユーザーが「後で判断」を選択 | （なし） | 一致しない | **非保証**: 旧 `recorded:pending` は新 canonical `pending`（spool 待機）とは意味が異なる。受理時は warn + canonical `created` 互換扱い + stderr に意味差を明示 |

**設計判断**:

- 完全一致の語彙のみ保証する
- 部分一致（区別不能）は warn + 保守的選択
- 意味が異なる語彙は **非保証** として明示し、呼出元が古いユースケースを使い続けないように促す（v2.7.x で旧フロー完全削除予定の前提）
- canonical 中間語彙 `legacy-deferred` は **導入しない**（旧フロー削除予定のため一時的な意味差は warn で十分）

#### Unit 003 フック契約（指摘 #5 反映）

Unit 002 が `04-completion.md §1.5` で source 経由で呼び出すフック関数の契約を以下に明文化する。Unit 003 は本契約に従って関数を実装する。

| フック関数名 | 必須/任意 | 引数 | 戻り値 | exit code | 未定義時の挙動 |
|--------------|----------|------|--------|-----------|----------------|
| `retrospective_prefill_hook(cycle, kpt_md_path)` | 任意 | `cycle: string` / `kpt_md_path: string` | stdout に Intent §6.3 スキーマの YAML | 0=成功 / 非0=失敗 | **no-op**（stdout 空 + exit 0）。Unit 002 は空 YAML フォールバックで本文構築継続 |
| `retrospective_update_hook(issue_url, cycle)` | 任意 | `issue_url: string` / `cycle: string` | （任意） | 0=成功 / 非0=失敗（警告のみ） | **no-op**（exit 0）。Unit 002 は §1.5 を継続 |

**未定義時の検出**: `command -v retrospective_prefill_hook >/dev/null 2>&1` で関数の存在を確認し、不在時は no-op を呼ぶ（Unit 002 内部で空関数を fallback 定義）。

**失敗時のフォールバック**:

- prefill 失敗（exit 非 0）: 空 YAML として扱い、Unit 002 が `_pure_compose_body` の空 YAML フォールバックパスで本文構築を継続
- update 失敗（exit 非 0）: 警告ログ「Unit 003 update フック失敗: <issue_url>」+ §1.5 を継続終了（**Unit 002 は exit 0 を維持**）

**依存逆転回避**:

- Unit 002 は Unit 003 の実装ファイル（`lib/retrospective-llm.sh` 等）を直接参照しない
- §1.5 ステップ記述では `command -v` で関数存在を確認し、未定義時は内部 no-op を呼ぶ
- BATS テストではモック関数 `retrospective_prefill_hook() { ... }` を BATS setup で定義する
- `skills/aidlc/scripts/retrospective-validate.sh`（**書き込み先変更**: ローカル `retrospective.md` ではなく Issue 本文（`gh issue edit --body`）または起票前の本文文字列に対して `--apply` / `downgrade` を行う。検証ルール（q*_answer / quote 整合）はそのまま維持）
- `skills/aidlc/templates/retrospective_template.md`（**Issue 本文用テンプレに転換**: 共有契約 6.2 の構造に整合。ローカルファイル前提の YAML フロントマター等を削除し、`retrospective_body_compose()` のテンプレ入力として使用する）

### 編集対象外（境界）

- `skills/aidlc/scripts/lib/feedback-mode.sh` / `feedback-mode-wizard.sh`（Unit 001 担当。本 Unit は呼び出すのみ）
- `skills/aidlc-migrate/scripts/migrate-feedback-mode.sh`（Unit 001 担当）
- LLM 下書き呼び出し処理（Unit 003 が `04-completion §1.5` の本 Unit 改修済ステップに対し下書きフックを差し込む）
- `predecessor_retrospective.md` テンプレ廃止 / `01-setup.md §4a` の Issue 検索化（Unit 004 担当）
- `scripts/operations-release.sh verify-git` の未コミットガード追加（Unit 005 担当）

## I/F 契約（cross-unit、設計フェーズで詳細化 / Unit 003-004 が依存）

各関数 / 定数は引数・標準出力・終了コード・異常時フォールバックを明文化し、他 Unit から呼び出される共有契約として固定する。詳細仕様は Phase 1 論理設計で確定するが、本計画段階で以下の骨子を確定する。

### I/F 正本の統一規則（指摘 #1 / #3 反映）

**全資料（plan / domain model / logical design）における共有関数 I/F の正本は本セクション**。他資料は本仕様を参照する。

公開関数は **path 渡し 3 引数を正本**とし、純粋関数（文字列入力→文字列出力）は内部関数として `lib/retrospective-issue.sh` に分離する（指摘 #3 純粋/IO 層境界）。

| レイヤー | 関数名 | 引数 | 役割 |
|----------|--------|------|------|
| 純粋関数（内部 / `_pure_*`） | `_pure_compose_body(draft_yaml_string, kpt_md_string, cycle) → body_markdown` | 文字列 3 つ | 文字列入力 → 文字列出力。副作用なし |
| Orchestration（公開） | `retrospective_body_compose(draft_yaml_path, kpt_md_path, cycle) → body_markdown to stdout` | path 2 + cycle 1 | path 読取 → `_pure_compose_body` 呼出 → stdout 出力 |
| Orchestration（公開） | `retrospective_issue_create(body_path, feedback_mode, cycle) → key=value lines + exit code` | path 1 + 文字列 2 | path 読取 → 起票 / spool 経路に分岐 |

呼出側（§1.5 / Unit 003）は **公開関数（path 渡し）** のみを利用する。純粋関数は `retrospective-issue.sh` 内部から呼ばれ、BATS テストでも内部関数として直接 verify する（純粋性の確認用）。

### `retrospective_body_compose(draft_yaml_path, kpt_md_path, cycle)`（公開）

- 入力:
  - `draft_yaml_path`: Unit 003 が出力する Intent §6.3 スキーマの YAML ファイルパス。空ファイルまたは存在しない場合は LLM 下書き未生成 / 失敗フォールバックとして全フィールド空 + `primary_cause="product"` 仮置き + `human_reviewed:false` で本文を構築
  - `kpt_md_path`: KPT セクション（Keep / Try / Problem 表）の Markdown ファイルパス。`templates/retrospective_template.md` 展開済みの内容を想定
  - `cycle`: サイクル識別子（`<CYCLE>`）
- 出力: 共有契約 6.2 構造に整合した Markdown 本文を **標準出力に出力**
- 終了コード: 0=成功（部分欠損フォールバック含む） / 1=ランタイム異常（path 読取失敗等） / 2=YAML パース失敗 or 引数エラー
- 異常時フォールバック: スキーマ部分欠損は警告 + 該当フィールドを空文字列で埋めて構築継続（exit 0）。完全な YAML パース失敗のみ exit 2
- 副作用: なし（**ファイル読取は orchestration 層が行うが、結果はメモリ上の文字列として処理し、新規ファイル書込みはしない**）

### `_pure_compose_body(draft_yaml_string, kpt_md_string, cycle)`（純粋関数 / 内部）

- 入力: すべて文字列（path ではなく内容そのもの）
- 出力: Markdown 本文文字列
- 終了コード: 0=成功 / 2=YAML パース失敗
- 副作用: なし（純粋関数）
- BATS 直接呼出: 純粋性検証のため、内部関数だが外部からも呼べる形で公開する

### `retrospective_issue_create(body_path, feedback_mode, cycle)`

- 入力:
  - `body_path`: `retrospective_body_compose()` の出力 Markdown を書込んだファイルパス
  - `feedback_mode`: **Unit 001 `feedback_mode_normalize` の出力（5 値正規化済）** — `interactive` / `local-issue-only` / `mirror-only` / `local-and-mirror` / `disabled`。本関数は内部で `feedback_mode_resolve()` を呼んで 4 値（`local_only` / `mirror_only` / `both` / `disabled`）に解決し、さらに `RetrospectiveTargetResolver` で `RetrospectiveTarget`（`local` / `mirror` / `both` / `none`）に翻訳する
  - `cycle`: サイクル識別子（`<CYCLE>`）。`^[A-Za-z0-9._-]+$` 以外は exit 2（path traversal 防御）
- 拡張環境変数（オプショナル / 主に `retrospective-resend.sh` および §1.5 から使用）:
  - `AIDLC_RETRO_FORCE_TARGET`: `local` / `mirror` / `both` / `none`。指定時は `feedback_mode` 由来の target 解決を上書きする（resend で `retry_target` を尊重するため）
  - `AIDLC_RETRO_CURRENT_COUNT` + `AIDLC_RETRO_LIMIT`: 両方が非空の整数で指定された場合のみ cap 判定を実施。`current_count >= limit` で `result=skipped reason=cap-exceeded mirror_state=skipped:max_exceeded` を返す
  - `AIDLC_RETRO_SKIP_LOCAL`: `1` の時、target に `local` / `both` が含まれていても local 側起票をスキップする（resend で `partial_state.local_created` が非 null の時に二重起票防止）
- 出力（標準出力、`<key>=<value>` 形式の複数行 / 行順は固定）:
  - 起票成功（local-issue-only / mirror-only）: `result=created`, `target=local|mirror`, `issue_url=<URL>`, `mirror_state=created`
  - 起票成功（local-and-mirror）: `result=created`, `target=both`, `local_issue_url=<URL>`, `mirror_issue_url=<URL>`, `mirror_state=created`
  - 重複検出（既存 Issue あり）: `result=skipped`, `reason=duplicate`, `existing_issue_url=<URL>`, `mirror_state=skipped:duplicate`
  - cap 超過: `result=skipped`, `reason=cap-exceeded`, `mirror_state=skipped:max_exceeded`
  - `disabled` または `interactive`（解決後 `disabled`）: `result=skipped`, `reason=mode-disabled`
  - スプール（gh 不可）: `result=spooled`, `spool_path=<path>`, `mirror_state=pending`
  - 起票失敗（再送可能）: `result=failed`, `reason=<gh-error-code>`, `mirror_state=error` + stderr に診断
  - **mirror_state ラベル付け替え失敗**（起票自体は成功 / `pending → created` への relabel が 3 回リトライしても失敗）: `result=failed`, `reason=relabel-failed-local|relabel-failed-mirror`, `mirror_state=pending`, `<local|mirror>_issue_url=<URL>` + spool 退避（`retry_target` には失敗側を記録 / 次回 resend で relabel 再試行）
- **終了コード（指摘 #4 反映: failed と spool / 受理可能スキップを exit code で明確に分離）**:
  - 0: `result=created` / `result=skipped` / `result=spooled`（受理可能経路。spool は再送経路に乗っているため成功扱い）
  - 1: `result=failed`（gh 起票失敗等の **再送可能失敗** / `mirror_state=error`）+ ランタイム異常（書込み失敗 等）
  - 2: 引数エラー（`feedback_mode` 未知 等）
- 異常時フォールバック: `gh_status != available` → スプール（exit 0）。`gh` 起票失敗 → `result=failed` + stderr 警告（**exit 1**、再送可能だが失敗扱い）。`feedback_mode` 未知 → exit 2
- **呼出規約（指摘 #4 反映 / §1.5 改修案で必須分岐として明記）**: 上位オーケストレーションは exit 1 を `failed`（再送可能だが当該サイクルでは未起票）として扱い、サマリ表示で警告 + Issue URL 不在を明示する。`spool` は exit 0 で受理可能扱いだが、`scripts/retrospective-resend.sh` 案内を表示する責務を上位に持たせる
- 副作用:
  - 成功時: GitHub に Issue を作成（`retrospective` ラベル + `mirror-state:<value>` ラベル + Milestone 紐付け）
  - スプール時: `cycles/{{CYCLE}}/history/retrospective-spool.md` への追記（同一サイクル複数エントリは順次追記）

### `RETROSPECTIVE_LABEL` / `MIRROR_STATE_LABEL_PREFIX` 命名規約定数

- 種別: shell 定数（`retrospective-issue.sh` 内で `readonly` 宣言、`source` した呼出側から参照可）
- 値:
  - `RETROSPECTIVE_LABEL="retrospective"`（Intent §6.1）
  - `MIRROR_STATE_LABEL_PREFIX="mirror-state:"`（Intent §6.1）
- 利用 Unit: Unit 004（predecessor 検索の `gh issue list --label retrospective` 検索キー）

### `mirror_state` 状態語彙 canonical 仕様（指摘 #5 反映）

**canonical 値（Intent §6.2 整合）**:

| canonical 値 | 意味 | 対応ラベル |
|--------------|------|-----------|
| `""`（空文字 / 未起票） | 起票試行前 / 該当なし | （ラベル付与なし） |
| `pending` | スプール中 / 後で再送 | `mirror-state:pending` |
| `created` | 起票成功 | `mirror-state:created` |
| `skipped:max_exceeded` | cap 超過によるスキップ | `mirror-state:skipped-max-exceeded` |
| `skipped:duplicate` | 重複検出によるスキップ | `mirror-state:skipped-duplicate` |
| `error` | 起票失敗（再送可能） | `mirror-state:error` |

**ラベル変換ルール**: canonical 値の `:` を `-` に置換（YAML 値とラベルで形式差を吸収）。Intent §6.1 「YAML 値の `:` は `-` に変換」と整合。

**旧語彙正規化規則（v2.5.0 互換）**: 旧 `retrospective-mirror.sh` 出力 `mirror\tsent\t...` / `mirror\tsend-failed\t...` / `mirror\trecorded\t...` を受け入れ、以下の写像で canonical 値に変換する。互換アダプタ層 `retrospective-mirror.sh` が呼び出された際は逆写像で旧プレフィックスを返却する（指摘 #3 互換アダプタ層保証範囲と整合）。

| 旧語彙（旧 stdout プレフィックス由来） | canonical 値 | 備考 |
|----------------------------------------|--------------|------|
| `sent` | `created` | 動作互換。`mirror-state:sent` ラベルが既存 Issue に残存している場合は **読み取り側で `created` と等価扱い**（後方互換） |
| `send-failed` | `error` | reason 文字列（`gh-not-authenticated` 等）は YAML `mirror_state.last_error` フィールドに保存（任意） |
| `recorded:pending` | `created`（**互換扱い + warn 必須**） | **意味が完全には一致しない非保証マッピング**。旧 `recorded:pending` は「ユーザーが後で判断」、新 canonical `pending` は「spool 待機」で意味差があるため、互換アダプタ層では `created` 互換扱いとして warn を出す（中間語彙 `legacy-deferred` は導入しない）。詳細は本ファイル §「互換アダプタ層 旧→新 意味マッピング」を参照 |
| `recorded:skipped` | `skipped:max_exceeded` または `skipped:duplicate`（呼出元コンテキストから判定） | コンテキスト不明時は `skipped:max_exceeded` を保守的選択 |

**正規化責務の所在**: `retrospective-issue.sh` の内部関数 `_normalize_mirror_state()` で 1 箇所に集約する（**読み取り側 / 書き込み側の双方向変換を 1 関数で担保**）。互換アダプタ層 `retrospective-mirror.sh` は `_normalize_mirror_state()` を呼び出す薄いラッパーとし、独自の語彙判定ロジックを持たない。

**読み取り側の優先順位（Intent §6.2 整合）**: ラベル経路（`mirror-state:<value>`）を優先し、ラベル不在時に YAML `mirror_state.state` を fallback 参照。両方ある場合は **ラベル値を真として YAML を更新**（不整合検出時の警告は stderr 出力）。

### `retrospective-resend.sh` CLI I/F

- 呼び出し: `bash scripts/retrospective-resend.sh [--cycle <CYCLE>] [--dry-run]`
- 動作:
  1. `cycles/<CYCLE>/history/retrospective-spool.md` を読み取る（`<CYCLE>` 未指定時は最新 cycle）
  2. 各スプールエントリに対し `retrospective_issue_create()` を呼び出す
  3. 起票成功したエントリをスプールから削除
  4. 残存エントリは次回再送のためそのまま保持
- 終了コード:
  - **0**: 全エントリが `created` または `skipped` で完結（**failed が 1 件もない場合のみ**）
  - **1**: `failed` が 1 件以上含まれる（処理は走り切ったが部分失敗あり / 上位はエラーとして検知し再送リトライを促す） / 中断 / ランタイム異常
  - **2**: 引数エラー / spool 不正 / cycle 不在
- 出力: 各エントリの処理結果を `<key>=<value>` 形式で出力（`retrospective_issue_create()` の出力契約を踏襲）

> 上記は計画段階の骨子。スプールファイル形式（区切り記号 / メタデータ / 順序）と CLI フラグの最終形は Phase 1 論理設計で確定する。

## スプールファイル形式（骨子 / 設計で確定）

**指摘 #2 反映**: 元案（Markdown 区切り + `<!-- body-start/end -->` マーカー）は、本文中に同一マーカーやコードフェンスが偶発的に出現すると `retrospective-resend.sh` のパースが壊れる。曖昧性ゼロを担保するため、**body は base64 エンコードして JSON フィールドに格納する NDJSON 形式**を採用する。Intent §「リスク 1」の `cycles/{{CYCLE}}/history/retrospective-spool.md` ファイル名は維持しつつ、内部の機械可読部分は単一の fenced block 内に閉じ込める。

`cycles/{{CYCLE}}/history/retrospective-spool.md` 構造:

````markdown
<!-- retrospective-spool v1 -->

# Retrospective Spool

> このファイルは `retrospective-resend.sh` 専用の機械可読スプールです。手動編集禁止。
> 機械パース対象は下記 `ndjson` fenced block のみ。block 外の Markdown は人間向け参考情報。

## 機械可読エントリ（NDJSON / 1 行 1 エントリ / 追記専用 / v1 必須フィールド完全版）

```ndjson
{"id":"550e8400-e29b-41d4-a716-446655440000","version":"1","cycle":"v2.5.1","feedback_mode":"local-and-mirror","attempted_at":"2026-05-05T10:00:00+09:00","target":"both","retry_target":"both","partial_state":{"local_created":null,"mirror_created":null},"attempt_reason":"gh-not-available","body_b64":"<base64 of body>","body_sha256":"<hex>"}
{"id":"7c4f1a2e-b3d5-4f6a-9b8c-1d2e3f4a5b6c","version":"1","cycle":"v2.5.1","feedback_mode":"local-and-mirror","attempted_at":"2026-05-05T10:05:00+09:00","target":"both","retry_target":"mirror","partial_state":{"local_created":"https://github.com/owner/repo/issues/42","mirror_created":null},"attempt_reason":"mirror-failed-after-local-created","body_b64":"<base64>","body_sha256":"<hex>"}
{"id":"a1b2c3d4-e5f6-7890-abcd-ef1234567890","version":"1","cycle":"v2.5.1","feedback_mode":"local-issue-only","attempted_at":"2026-05-05T10:10:00+09:00","target":"local","retry_target":"local","partial_state":{"local_created":null,"mirror_created":null},"attempt_reason":"gh-rate-limit","body_b64":"<base64>","body_sha256":"<hex>"}
```
````

> **v1 最小必須キー集合**: `id`, `version`, `cycle`, `feedback_mode`, `attempted_at`, `target`, `retry_target`, `partial_state`, `attempt_reason`, `body_b64`, `body_sha256` の **11 キーすべて必須**。1 つでも欠けるエントリは parse 失敗扱い（skip + warn）。

**スキーマ（必須フィールド / 指摘 #2 / #6 反映）**:

| フィールド | 型 | 説明 |
|------------|-----|------|
| `id` | string（UUID v4） | エントリ一意識別子。再送時の **ID ベース削除** で誤削除を防ぐ（指摘 #6） |
| `version` | string | スプールスキーマバージョン（現在 `"1"`） |
| `cycle` | string | サイクル識別子 |
| `feedback_mode` | string | 試行時の `feedback_mode`（5 値正規化後） |
| `attempted_at` | string | ISO8601 タイムスタンプ |
| `target` | string | `local` / `mirror` / `both` |
| `retry_target` | string | **再送時に対象とする target**（指摘 #2）。`local` / `mirror` / `both` のいずれか。partial 起票時は `target=both` でも `retry_target=mirror` のみとなる |
| `partial_state` | object | partial 起票の進捗。`{"local_created":"<URL or null>","mirror_created":"<URL or null>"}`。再送時に `null` でない側は再起票しない |
| `attempt_reason` | string | `gh-not-available` / `gh-rate-limit` / `gh-network-error` / `gh-unknown-error` / `mirror-failed-after-local-created` / その他失敗コード |
| `body_b64` | string | `retrospective_issue_create()` に渡す本文 Markdown 全体の base64 エンコード（改行・特殊文字保護） |
| `body_sha256` | string | デコード後 body の SHA256 hex（再送前 integrity 検証用） |

**partial 起票時の典型例（指摘 #2 対応）**:

```json
{"id":"...","target":"both","retry_target":"mirror","partial_state":{"local_created":"https://github.com/owner/repo/issues/N","mirror_created":null},"attempt_reason":"mirror-failed-after-local-created",...}
```

再送時は `retry_target=mirror` を見て mirror 起票のみ実行する。local 側は `partial_state.local_created` の URL がそのまま採用される（再起票しない）。

**パース要件（resend）**:

- `<!-- retrospective-spool v1 -->` ヘッダ行を確認し、無ければエラー停止
- ` ```ndjson` fenced block を抽出（block 開閉マーカーは正規表現 `/^```ndjson\b/` ～ `/^```$/`）
- block 内の各行を JSON.parse → `body_b64` を base64 デコード → `body_sha256` で検証 → `retry_target` を見て `retrospective_issue_create()` に再起票指示
- 起票成功エントリは **`id` をキーに block から削除**（インプレース上書き / 行番号ではなく ID ベース）
- ID ベース削除のため、複数プロセス並行実行時の race condition を緩和

**排他制御（指摘 #6）**:

- spool ファイル書込み（追記 / 削除 / 圧縮）は `flock(1)` 相当の排他ロックで保護する
  - 実装方針: `flock -x <fd> -c "..."` または `lockfile-create`（Linux）/ `shlock`（macOS）の利用可能性を実装フェーズで確定。fallback として `mkdir <lockdir>` のアトミック性を利用した手書きロックを検討
- ロック取得不能（5 秒タイムアウト）時は exit 1 + stderr 警告「retrospective-spool ロック取得失敗（他プロセス操作中）」
- 一時ファイル + `mv` の原子的置換は ID ベース削除と併用（部分書込み時の整合保護）

**追記要件（spool 書込）**: 既存ファイルが存在しなければヘッダ + fenced block を生成。存在すれば fenced block 末尾の閉じ ` ``` ` の前に新エントリを 1 行追記。block 外への追記は禁止。書込み開始前に `id` を生成し、書込み完了後に標準出力に `id` を返却する（呼出側が再送時に参照可能）。

> 設計フェーズで `version` フィールドの将来互換規約と integrity チェック失敗時の挙動（停止 / スキップ / 警告）を確定する。UUID 生成手段は `uuidgen`（macOS / Linux 共通） / fallback として `od -An -N16 -tx1 /dev/urandom | tr -d ' '` を採用予定。

## §1.5 改修案（骨子 / 設計で確定）

**指摘 #1 反映**: Unit 003 フックは「起票前 prefill（draft YAML 供給のみ）」と「起票後 update（`human_reviewed:true` 更新 + LLM 推論結果と人間確認後の差分コメント追記）」の 2 段に分離する。Step 5 で起票、Step 6 で起票後更新フック。

**指摘 #4 反映**: `retrospective_issue_create()` の exit code を上位で必ず分岐し、`failed`（exit 1）はサマリ警告 + Issue URL 不在を明示。`spooled` は exit 0 だが `retrospective-resend.sh` 案内を表示。

現行 §1.5 の Step 2-5 構造を以下に置き換える:

| 旧構造 | 新構造 |
|--------|--------|
| Step 2: `retrospective-generate.sh` 呼び出し（ローカル `retrospective.md` 生成） | **Step 2**: `feedback_mode` 解決（Unit 001 `feedback_mode_normalize` + `feedback_mode_resolve`）+ wizard 起動判定（未設定 / `interactive` の場合は Unit 001 `feedback_mode_wizard` を起動 → 確定値で再評価） |
| Step 3: 出力プレフィックス分岐 | **Step 3**: cap 判定（Unit 001 `feedback_cap_check`）+ Unit 003 **prefill フック**呼び出し（draft YAML 取得、失敗時は空 YAML フォールバック） |
| Step 4: `retrospective-validate.sh --apply` | **Step 4**: `retrospective_body_compose(draft_yaml, kpt_md)` で本文構築 + `retrospective-validate.sh` を本文文字列に対して実行（違反項目を `q*_answer: yes → no` ダウングレード） |
| Step 5: mirror フロー（candidate ループ + AskUserQuestion） | **Step 5**: `retrospective_issue_create(body_path, feedback_mode, cycle)` 呼び出し + exit code 分岐（0=created/spooled/skipped、1=failed、2=fatal）+ 結果サマリ表示 |
| （新規） | **Step 6**: 起票後フック（Unit 003 / 起票成功時のみ）— Unit 003 は LLM 推論結果と人間確認後の最終結果を比較し、`gh issue edit <N> --body-file ...` で `human_reviewed:true` に更新し、必要に応じて差分を Issue コメントで追記する。本 Unit 002 は Step 6 に **コール口（issue_url 引き渡し）** のみを設置し、更新処理本体は Unit 003 が実装する |

`disabled` モード時はすべてのステップをスキップし、§1.6 へ進む。`interactive` モード時は wizard で確定後、再帰的に再評価する。

### 共通契約: `human_reviewed` 付与責任の Step 別分離（指摘 #1 反映 / Intent §6.4 整合）

| Step | Unit 002 責務 | Unit 003 責務 |
|------|----------------|----------------|
| Step 3（起票前 prefill） | Unit 003 prefill フックの呼び出し（入力契約: 当該 cycle の Problem 一覧） | LLM 推論で Intent §6.3 スキーマの draft YAML を出力。失敗時は空 YAML を返す（Unit 002 側で空 YAML フォールバック） |
| Step 4（本文構築） | `retrospective_body_compose(draft_yaml, kpt_md)` で本文に `human_reviewed:false` を埋め込む | （関与しない） |
| Step 5（起票） | `retrospective_issue_create()` で起票 | （関与しない） |
| Step 6（起票後 update） | Unit 003 update フックを呼び出し、`issue_url` を引き渡す | `gh issue edit` で本文の `human_reviewed:false → true` 更新 + LLM 推論結果と人間確認後の差分があればコメント追記 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**（`design-artifacts/domain-models/unit_002_retrospective_issue_only_domain_model.md`）
   - `RetrospectiveIssue` 集約（labels / body / milestone / target_repo）
   - `RetrospectiveBody` 値オブジェクト（KPT + Problem 配列 + 主因切り分け + skill_caused_judgment + mirror_state YAML）
   - `RetrospectiveSpoolEntry` 値オブジェクト（cycle / body / target / attempt_reason / timestamp）
   - `MirrorStateLabel` 値オブジェクト（state → ラベル文字列変換: `:` → `-` 規則）
   - `RetrospectiveDuplicateDetector` ドメインサービス（タイトル + サイクル + リポによる検出）
   - `ResendOperation` 集約（spool 読取 → 起票 → spool 削除）
   - `RetrospectiveIssueRepository`（gh CLI 経由）
   - `RetrospectiveSpoolRepository`（`history/retrospective-spool.md` ファイル）
2. **論理設計**（`design-artifacts/logical-designs/unit_002_retrospective_issue_only_logical_design.md`）
   - 関数 I/F 仕様（`retrospective_issue_create()` / `retrospective_body_compose()`）
   - 命名規約定数の export 方針
   - `feedback_mode` 別の起票先振り分けアルゴリズム（Unit 001 `feedback_mode_resolve()` の戻り値を mapping）
   - 重複検出アルゴリズム（`gh issue list --label retrospective --milestone <CYCLE>` + タイトル正規化）
   - スプールファイル形式と追記アルゴリズム
   - `retrospective-resend.sh` の処理フロー
   - `04-completion.md §1.5` 改修案の最終形（Step 2-5 の置き換え記述）
   - 互換アダプタ層（`retrospective-generate.sh` / `retrospective-mirror.sh`）の責務範囲
   - `retrospective_template.md` 改修方針（YAML フロントマター削除 / セクション順序）
   - BATS テストケース一覧
3. **設計レビュー**（`reviewing-construction-design` スキル / 優先ツール codex）
4. **設計承認**（semi_auto → 自動承認 or fallback）

### Phase 2: 実装

5. **コード生成**
   - `scripts/lib/retrospective-issue.sh` 新規作成（共有関数 + 定数）
   - `scripts/retrospective-resend.sh` 新規作成
   - `scripts/retrospective-generate.sh` を互換アダプタ層化
   - `scripts/retrospective-mirror.sh` を互換アダプタ層化
   - `scripts/retrospective-validate.sh` を Issue 本文対応化
   - `templates/retrospective_template.md` を Issue 本文用に転換
   - `steps/operations/04-completion.md §1.5` 全面書き換え
6. **コード AI レビュー**（`reviewing-construction-code` スキル / 優先ツール codex）
7. **テスト生成**（**Unit 002 のテストスコープは関数 / スクリプト単体 + §1.5 統合**。Unit 003 LLM 推論呼び出しはモック化、Unit 004 predecessor 検索はテスト範囲外）
   - `tests/retrospective-issue-create.bats`（feedback_mode 別動作 / 重複検出 / cap 超過 / `gh_status != available` の spool 分岐）
   - `tests/retrospective-body-compose.bats`（共有契約 6.2 構造の verify / Unit 003 prefill 入力スキーマ受け入れ / `human_reviewed:false` 初期値 / 部分欠損フォールバック）
   - `tests/retrospective-spool.bats`（NDJSON v1 必須 11 キー検証 / fenced block 抽出 + 1 行 1 JSON parse / id ベース削除 / partial 起票時の retry_target / 排他ロック / SHA256 integrity）
   - `tests/retrospective-resend.bats`（正常系 / 部分失敗時の残存 / gh 復旧確認）
   - `tests/operations-04-completion-section1-5.bats`（§1.5 ステップの統合: Unit 001 関数呼び出し → Unit 003 prefill フック（モック）→ 起票 / spool / disabled）
8. **ビルド・テスト実行**（BATS / shellcheck / markdownlint。Self-Healing ループで修正）
9. **統合 AI レビュー**（`reviewing-construction-integration` スキル / 優先ツール codex）
10. **実装承認**（semi_auto → 自動承認 or fallback）

### 完了処理

11. 完了条件チェック / 設計・実装整合性チェック / 意思決定記録参照確認 / AI レビュー実施確認
12. Unit 定義ファイル状態を「完了」に更新
13. 履歴記録（`/write-history` で `history/construction_unit02.md`）
14. Markdownlint 実行（`markdown_lint=true`）
15. Squash（`squash_enabled=true` / `squash-unit.sh`）
16. Git コミット
17. コンテキストリセット提示

## 完了条件チェックリスト

Unit 定義「責務」セクション + Intent §「成功基準」+ Intent §「リスクと代替案検討」 + 共有契約 6.x から抽出。

### Unit 責務由来

- [ ] `steps/operations/04-completion.md §1.5` の改修が完了し、ローカル `retrospective.md` 生成パスが撤廃されている
- [ ] `retrospective_body_compose(problem_drafts, kpt_sections)` 関数が共有契約 6.2 構造に整合した Markdown を生成する
- [ ] `retrospective_issue_create(body_path, feedback_mode, cycle)` 関数が `feedback_mode` 別の起票先振り分けと結果出力契約を満たす
- [ ] `RETROSPECTIVE_LABEL` / `MIRROR_STATE_LABEL_PREFIX` 命名規約定数が `retrospective-issue.sh` で提供され、source による参照ができる
- [ ] 起票時に `retrospective` ラベルが付与される
- [ ] `mirror_state` がラベル化される（`mirror-state:created` / `mirror-state:skipped-duplicate` 等、`:` → `-` 変換規則準拠）
- [ ] `gh_status != available` 時に `cycles/{{CYCLE}}/history/retrospective-spool.md` へスプールされる
- [ ] `scripts/retrospective-resend.sh` がスプール → 起票 → スプール削除の経路を提供する
- [ ] 既存 `cycles/{{PREV_CYCLE}}/operations/retrospective.md` の **読み取り経路**は維持されている（v2.5.0 互換 / 廃止対象は新規生成のみ）
- [ ] `templates/retrospective_template.md` が Issue 本文用テンプレに転換され、共有契約 6.2 構造に整合
- [ ] Unit 003 が出力する LLM 下書き（Intent §6.3 スキーマ）を本文 prefilled として埋め込む処理が実装されている

### Intent 成功基準由来

- [ ] **ローカルファイル生成撤廃**: `04-completion.md §1.5` 実行後、`.aidlc/cycles/{{CYCLE}}/operations/retrospective.md` が **存在しない**（`test ! -f` で 0 を返す）
- [ ] **Issue 起票確認**: `gh issue view <N> --json url` で起票済み Issue の URL が取得できる
- [ ] **gh 不可時のスプール保存**: `gh_status != available` 時、Issue 起票内容が `cycles/{{CYCLE}}/history/retrospective-spool.md`（永続）にスプールされる
- [ ] **再送スクリプト**: `scripts/retrospective-resend.sh` でスプール → Issue 起票への再送ができる
- [ ] **本文構造**: 起票された Issue 本文に主因分類（3 分類のいずれか）と `skill_caused_judgment`（q1/q2/q3 + 引用文）の YAML ブロックが含まれる（`gh issue view <N> --json body | jq` で抽出可能）

### Intent リスクと代替案検討由来

- [ ] **リスク 1 緩和**: `gh_status != available` 時のスプール書込みが BATS でテストされ、`feedback_mode = "disabled"` のみスプール不要であることが verify されている
- [ ] **リスク 4 緩和**: `mirror_state` ラベル付与と本文 YAML 埋め込みが両方行われ、読み取り側が **新ラベル経路を優先 / YAML を fallback** とできる構造になっている

### NFR 由来

- [ ] **冪等性**: 同一サイクル + 同一タイトルの retrospective Issue が二重起票されない（重複検出 BATS で verify）
- [ ] **可用性**: `gh_status != available` でも振り返り内容が消失しない（スプール BATS で verify）
- [ ] **後方互換**: 旧 `retrospective.md` ファイルが残っていても新フローが正常動作する（読み取り経路維持の BATS で verify）

### 共有契約 6.x 由来

- [ ] **6.1 ラベル命名規約**: `retrospective` / `mirror-state:<value>` の付与が起票テストで verify される
- [ ] **6.2 本文構造**: `retrospective_body_compose()` の出力が共有契約 6.2 の章立て + YAML ブロック構造に整合する（BATS で verify）
- [ ] **6.3 LLM 下書き入力スキーマ**: Unit 003 から渡される YAML（Intent §6.3 スキーマ）が `retrospective_body_compose()` で受理され、本文に prefilled で埋め込まれる（BATS で verify）
- [ ] **6.4 human_reviewed**: 本 Unit が起票時に `human_reviewed: false` で埋め込み、`true` への更新は本 Unit の責務外（Unit 003 が行う）であることが BATS / コードコメントで明示されている
- [ ] **6.5 §1.5 編集主体**: `git diff` で `04-completion.md §1.5` の Step 2-5 が本 Unit によって書き換えられている

### 境界・責務由来（指摘 #6 反映: 逆方向非依存検証を強化）

- [ ] **Unit 001 関数の呼び出しのみ**: `git diff` で `skills/aidlc/scripts/lib/feedback-mode.sh` / `feedback-mode-wizard.sh` への変更が含まれていない（Unit 001 の境界を侵していない）
- [ ] **Unit 003 への prefill 入力経路**: `retrospective_body_compose()` の引数仕様が Intent §6.3 スキーマを受け入れ、Unit 003 が呼び出せる契約として固定されている
- [ ] **Unit 003 への update フック**: §1.5 Step 6 に `issue_url` 引き渡し口があり、Unit 003 update フック呼び出しが Unit 002 範囲内で `gh issue edit` を実行しないこと（責務分離 / 指摘 #1 対応）
- [ ] **Unit 004 への命名規約提供**: `RETROSPECTIVE_LABEL` / `MIRROR_STATE_LABEL_PREFIX` が source 経由で参照できる shell 定数として提供されている
- [ ] **逆方向非依存テスト（consumer モック固定）**: Unit 002 BATS テストは以下のモックのみで成立する:
  - Unit 003 prefill フック → 固定 YAML（成功 / 空 / 不正の 3 パターン）を返すモック関数で代替
  - Unit 003 update フック → モック関数で `issue_url` 受領のみを assert
  - Unit 004 predecessor 検索 → 本 Unit テスト範囲外（呼び出さない / 呼ぶ場合はモック）
  - `gh` CLI → bats 用 stub で `gh issue create` / `edit` / `view` の応答を固定
- [ ] **逆方向非依存検証**: Unit 002 BATS テストが Unit 003 / 004 の **実装ファイル**を参照しない（`grep` で確認）。本 Unit の I/F 契約のみで成立する

## 出力先（参考）

- 設計: `.aidlc/cycles/v2.5.1/design-artifacts/domain-models/unit_002_retrospective_issue_only_domain_model.md` / `.aidlc/cycles/v2.5.1/design-artifacts/logical-designs/unit_002_retrospective_issue_only_logical_design.md`
- 履歴: `.aidlc/cycles/v2.5.1/history/construction_unit02.md`
- 実装記録: `.aidlc/cycles/v2.5.1/construction/units/unit_002_retrospective_issue_only.md`（テンプレ `implementation_record_template.md`）
