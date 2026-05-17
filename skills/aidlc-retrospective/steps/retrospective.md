# /aidlc-retrospective 実行ステップ

サイクルを振り返り、Keep（継続したい良い点）/ Problem（顕在化した課題）/ Try（次サイクル以降で試す改善）を整理する。Operations Phase §1（v2.5.x）から v2.6.0 で本スキルへ全量移転された。

## 0. bootstrap

AIDLC_BASE を解決し、公開 API 層と cycle-resolver を `source` する。

```bash
# AIDLC_BASE は SKILL.md と同じディレクトリ起点で解決される
# retrospective-api.sh が内部で AIDLC_BASE を解決済
source skills/aidlc/scripts/lib/retrospective-api.sh
source skills/aidlc/scripts/lib/cycle-resolver.sh
```

## 1. 対象サイクル特定（CycleResolver）

```bash
cycle_resolver_resolve "$ADDITIONAL_CONTEXT" > /tmp/aidlc-retro-resolver.txt
rc=$?
```

- `rc=0`: 解決成功 → `candidate=` の値を読み出して `cycle` 変数に格納
- `rc=1`: 候補ゼロ → AskUserQuestion で対象サイクルをユーザーに問い合わせる
- `rc=2`: fatal → 警告表示して exit 2

`/tmp/aidlc-retro-resolver.txt` に `conflict=true` 行がある場合（confidence != high かつ S3a/S3b 不一致）は、`conflict_s3a` / `conflict_s3b` の両候補を提示して AskUserQuestion で確定する。

確定した cycle は以降の bash コード例では `$cycle` 変数として参照する（テンプレート / 文章中の `{{CYCLE}}` プレースホルダは表記上のもの。bash 実行時は変数展開を経由する）。

## 1.0 feedback_mode 解決と実施判定【必須・最初に評価】

```bash
scripts/read-config.sh rules.retrospective.feedback_mode > /tmp/aidlc-raw.txt
read raw < /tmp/aidlc-raw.txt

retrospective_api_resolve_feedback_mode "$raw" > /tmp/aidlc-mode.txt
read mode < /tmp/aidlc-mode.txt

retrospective_api_is_interactive_env > /tmp/aidlc-env.txt
read env_interactive < /tmp/aidlc-env.txt
```

| feedback_mode（正規系） | 動作 |
|------------------------|------|
| `interactive`（既定 / 未設定 fallback） | 実施（手動 KPT + 自動生成 / wizard 経路で対話確定） |
| `local-issue-only` | 実施（local Issue のみ起票 / mirror 起票なし） |
| `mirror-only` | 実施（mirror 候補 upstream 起票 / local 記録なし） |
| `local-and-mirror` | 実施（local + mirror の両方を起票） |
| `disabled` | 全体スキップ（「振り返り機能は無効化されています（feedback_mode=disabled）」と表示して exit 0） |

旧値互換入力（`feedback_mode_normalize` で変換）:

| 旧値 | 正規化結果 |
|------|----------|
| `silent` | `interactive` |
| `mirror` | `mirror-only` |
| 未知値 | `disabled`（warn 通知付き） |

`mode == "disabled"` の場合は以降のステップを実施せず exit 0。

```bash
retrospective_api_requires_wizard "$mode" "$env_interactive" > /tmp/aidlc-wizard.txt
read need_wizard < /tmp/aidlc-wizard.txt
if [[ "$need_wizard" == "true" ]]; then
    retrospective_api_run_wizard > /tmp/aidlc-mode.txt
    read mode < /tmp/aidlc-mode.txt
fi
```

`retrospective_api_requires_wizard` が `true` を返した場合のみ `retrospective_api_run_wizard` で対話的に確定する。

## 1.0.5 対話必須ガード【Unit 001 / #647 / 必読】

> **重要**: 振り返りは判断要件を含むため、AI エージェントの auto mode（Claude Code 等の自動実行モード）動作に**関わらず**、必ずユーザー対話を経て進めること。本節は文書ガード（規範・手順）と実行時ガード（`retrospective_dialog_token_verify`）の二段防御の手順側 SoT を定義する。

**規範（SoT）**: AskUserQuestion 使用ルールの正本は `skills/aidlc/SKILL.md`「AskUserQuestion 使用ルール」節（「ユーザー選択（振り返り内容の決定）」種別）。

**禁止事項**:

- AskUserQuestion 応答を経ずに `retrospective_api_create_issue` / `retrospective_api_record_response` / state mutation を実行する経路（`dialog bypass`）
- KPT 各観点（Keep / Problem / Try）/ 主因切り分け / 格納先選択 / mirror 送信判断のすべてを AI エージェントが独断で決定すること
- auto mode（Claude Code 等の自動実行モード）を理由とした AskUserQuestion 省略

**必須事項**:

- §1.1 KPT 各観点（Keep / Problem / Try）について 1 項目ずつ AskUserQuestion で確認
- §1.2 主因切り分け（プロダクト固有 / AI-DLC Starter Kit 固有 / 両方に責任）について AskUserQuestion で確認
- §1.3 格納先選択（マージ前 / マージ後 / 横断改善）について AskUserQuestion で確認
- §1.5 Step 4 起票実行直前に「この内容で Issue を起票してよいか」を AskUserQuestion で確認 → 応答得た直後に `retrospective_api_record_response "$cycle" "$response"` を呼び出して**対話確認トークンを発行**する（実行時ガードへの引き継ぎ）

**実行時ガードとの連携**: 起票実行は `retrospective_api_create_issue` 経由。同関数は内部で `retrospective_dialog_token_verify` を呼び、対話確認トークン未発行 / 鮮度切れ（TTL 300 秒）/ `denied` 応答 / I/O 異常時は exit 4 でブロックする。

## 1.1 KPT テンプレ（推奨フォーマット）

| 観点 | 内容 |
|------|------|
| Keep | 次サイクル以降も継続したい良いプラクティス・成果 |
| Problem | 今回顕在化した課題・改善が必要な事象 |
| Try | Problem への対策として次サイクル以降で試す施策 |

各 Problem / Try には次の §1.2「主因切り分け」を必ず含める。AskUserQuestion で 1 項目ずつ確認する。

## 1.1.5 事実テーブル先抽出ステップ【Unit 003 / #634 / 必須・KPT 後・主因切り分け前】

§1.1 KPT 記入後、§1.2 主因切り分けの前に、推測値混入を予防するため以下の 3 source から事実を構造化抽出する。

**読み込み対象 source（最低 3 種別必須）**:

- (a) `.aidlc/cycles/{{CYCLE}}/inception/decisions.md` — Decision Record（DR-NNN）件数・経緯
- (b) `.aidlc/cycles/{{CYCLE}}/construction/units/*-review-summary.md` — review round 数・指摘件数・defer 件数
- (c) `.aidlc/cycles/{{CYCLE}}/history/*.md` — 時系列イベント

各 source を Read し、事実項目を markdown 表形式で構造化する。値は推測ではなく**実際に Read した結果のみ**を記載する。

**事実テーブル形式**:

| 項目 | 値 | 出典 |
|------|-----|------|
| DR 件数 | （Read 結果からの実数） | `inception/decisions.md` |
| review round 数（合計） | （集計値） | `construction/units/*-review-summary.md` |
| 指摘件数（合計） | （集計値） | 同上 |
| defer 件数 | （集計値） | 同上 |
| 時系列イベント（主要なもの） | （タイムスタンプ + 概要を 5 件程度） | `history/*.md` |

事実テーブル抽出後、§1.2 主因切り分けに進む。Try / mirror 候補本文の起草時には本テーブルの値のみを根拠として参照する（推測値の導入禁止）。

## 1.2 主因切り分け【必須・3 分類】

各 Problem / Try について、AskUserQuestion で以下の 3 分類のいずれかを選択する:

- **プロダクト固有**: プロダクトリポジトリ側で対応（GitHub Issue 起票 / 次サイクル Intent 反映）
- **AI-DLC Starter Kit 固有**: `/aidlc feedback` で起票（後述 §1.3 分岐 c）
- **両方に責任**: 両側で対応（プロダクト側は短期保険、AI-DLC 側は構造改善）

主因切り分けは markdown マトリクス記載（自由記述）で、機械判定は実施しない。

## 1.3 格納先の選択【必須・3 分岐から選ぶ】

実施タイミングと output の性質に応じて AskUserQuestion で選択する:

| 分岐 | 状況 | 格納先 | マージ前完結契約 |
|------|------|--------|----------------|
| (a) マージ前 | PR マージ前に本ステップを実施 | GitHub Issue（v2.5.1+ Issue 一本化方針） | 遵守（pre-merge stage） |
| (b) マージ後 | PR マージ後に本ステップを実施 | GitHub Issue（`retrospective` ラベル + `Retrospective: {cycle}` title）/ 次サイクル Inception §4a で `predecessor_resolve_issue` が解決 | 遵守（外部 GitHub Issue 領域） |
| (c) 横断改善 | AI-DLC Starter Kit への改善要望 | `/aidlc feedback` で Issue 起票 | 影響なし |

複数分岐の併用可。

## 1.4 write-history.sh ガードとの関係

| 分岐 | write-history.sh 呼び出し | exit code |
|------|----------------------------|-----------|
| (a) マージ前 | `--operations-stage pre-merge` 明示 OR 未指定（write-history.sh が実行コンテキストから導出） | 0（正常） |
| (b) マージ後 | 次サイクル領域への書き込み（本サイクルへの追記なし） | ガード対象外 |
| (c) 横断改善 | GitHub Issue 起票のみ | ガード対象外 |

**v2.6.0 fail-closed 仕様**: `--operations-stage` 引数 / `AIDLC_OPERATIONS_STAGE` 環境変数はヒント値扱いとなり、`write-history.sh` 内で実行コンテキスト導出値と cross-check される。不一致時 / 未検証値 / 判定不能時は exit 3 でブロック。本スキルから呼び出す場合も `AIDLC_OPERATIONS_STAGE` を恣意的に上書きせず、未指定で起動して `write-history.sh` 側に判定を委ねるのが原則。

## 1.5 Issue 起票フロー（v2.5.1+ / Unit 002）

分岐 (a) マージ前を選択した場合、以下の Issue 起票フローで retrospective Issue を作成する。

### Step 1: feedback_mode の確定（§1.0 で完了済 / 復元）

§1.0 で確定した `mode` を再利用する。

### Step 2: KPT テンプレ展開 + cap 判定 + prefill フック

```bash
# KPT テンプレ展開（prefill フックの入力 + Step 3 の本文構築で再利用するため Step 2 冒頭で先に展開）
kpt_md_path=/tmp/aidlc-retro-kpt.md
# テンプレート内の {{CYCLE}} プレースホルダを実値 $cycle で置換（cycle に "/" が含まれる想定はないが、念のためエスケープ）
sed "s|{{CYCLE}}|${cycle//|/\\|}|g" skills/aidlc/templates/retrospective_template.md > "$kpt_md_path"

scripts/read-config.sh rules.retrospective.feedback_max_per_cycle > /tmp/aidlc-limit.txt
read limit < /tmp/aidlc-limit.txt

# current_count: cycle 内の retrospective ラベル付き Issue 数
gh issue list --label retrospective --milestone "$cycle" --state all --limit 100 --json url > /tmp/aidlc-issues.json 2>/dev/null || printf '[]\n' > /tmp/aidlc-issues.json
jq 'length' < /tmp/aidlc-issues.json > /tmp/aidlc-current.txt
read current_count < /tmp/aidlc-current.txt

retrospective_api_check_cap "$mode" "$current_count" "$limit" > /tmp/aidlc-cap.txt
grep '^over=true$' /tmp/aidlc-cap.txt > /tmp/aidlc-over.txt 2>/dev/null || : > /tmp/aidlc-over.txt
```

#### opt-in 基盤フラグ（v2.6.4 / #710 / Unit 004）

`auto_issue_creation = false` が設定されている場合、集約 Issue 起票（Step 3/4/5）をスキップする。
`read-config.sh` の終了コードを区別して、未設定キーと取得失敗を fail-open で扱う:

```bash
# read-config.sh の終了コード: 0=値あり / 1=キー不在（→ true fallback）/ 2+=取得失敗（→ true fallback + warn）
set +e
scripts/read-config.sh rules.retrospective.auto_issue_creation > /tmp/aidlc-auto-issue.txt 2>/tmp/aidlc-auto-issue.err
rc_auto_issue=$?
set -e
case "$rc_auto_issue" in
    0)
        read auto_issue < /tmp/aidlc-auto-issue.txt
        ;;
    1)
        # キー不在: defaults.toml の値（true）に解決されていないケースは通常発生しないが、保険として true fallback
        auto_issue="true"
        ;;
    *)
        # 取得失敗: warn 表示 + 既定（既存動作）として true を採用（fail-open）
        echo "[warn] auto_issue_creation の読み取りに失敗しました（rc=$rc_auto_issue）。既定動作（auto_issue_creation=true 相当）で続行します。" >&2
        cat /tmp/aidlc-auto-issue.err >&2 2>/dev/null || :
        auto_issue="true"
        ;;
esac
if [[ "$auto_issue" == "false" ]]; then
    echo "opt-out=true" > /tmp/aidlc-opt-out.txt
else
    : > /tmp/aidlc-opt-out.txt
fi
```

`/tmp/aidlc-over.txt` が非空（cap 超過）**または** `/tmp/aidlc-opt-out.txt` が非空（auto_issue_creation=false / opt-out）の場合は Step 3 / Step 4 / Step 5 をすべてスキップして §1.6 へ進む。opt-out 経路では以下のメッセージを info 表示する:

```text
集約 Issue 起票をスキップしました（auto_issue_creation=false / v2.6.4 / #710 opt-in 基盤）。
KPT は振り返りローカル記録として保持されます。Try/改善が必要な場合は個別 Issue 起票を検討してください。
```

```bash
# prefill フック呼び出し（cap 超過 / opt-out 時はスキップ）
if [[ ! -s /tmp/aidlc-over.txt && ! -s /tmp/aidlc-opt-out.txt ]]; then
    draft_yaml_path=/tmp/aidlc-retro-draft.yml
    : > "$draft_yaml_path"
    retrospective_api_prefill "$cycle" "$kpt_md_path" > "$draft_yaml_path" || : > "$draft_yaml_path"
fi
```

### Step 3: 本文構築

```bash
# kpt_md_path は Step 2 冒頭で展開済（テンプレ展開を Step 2/3 共通の前段に集約）
body_path=/tmp/aidlc-retro-body.md
retrospective_api_compose_body "$draft_yaml_path" "$kpt_md_path" "$cycle" > "$body_path"
```

### Step 4: Issue 起票

> **対話必須ガード（Unit 001 / #647）**: §1.0.5 必須事項に従い、起票実行直前に AskUserQuestion で「この内容で Issue を起票してよいか」をユーザーに確認すること（auto mode 動作下でも省略禁止）。応答が `approved` の場合のみ次の `retrospective_api_record_response` 呼出に進む。応答が `denied` の場合は同関数に `denied` を渡す（実行時ガードが起票をブロックする明示的な意思表示として記録される）。

```bash
# AskUserQuestion 応答得た直後（response = "approved" or "denied"）
retrospective_api_record_response "$cycle" "$response"
```

`retrospective_api_create_issue` は内部で `retrospective_dialog_token_verify` を呼び、対話確認トークン未発行 / 鮮度切れ（TTL 300 秒）/ `denied` 応答 / I/O 異常時は exit 4（`reason=dialog-required`）で起票をブロックする。

```bash
set +e
AIDLC_RETRO_CURRENT_COUNT="$current_count" \
AIDLC_RETRO_LIMIT="$limit" \
    retrospective_api_create_issue "$body_path" "$mode" "$cycle" > /tmp/aidlc-retro-result.txt
rc=$?
set -e

case "$rc" in
    0)
        if grep -q '^result=created' /tmp/aidlc-retro-result.txt; then
            grep -E '^(local|mirror)?_?issue_url=' /tmp/aidlc-retro-result.txt > /tmp/aidlc-retro-url.txt
            head -n 1 /tmp/aidlc-retro-url.txt > /tmp/aidlc-retro-url-first.txt
            cut -d= -f2 /tmp/aidlc-retro-url-first.txt > /tmp/aidlc-retro-issue-url.txt
            read issue_url < /tmp/aidlc-retro-issue-url.txt
            echo "起票成功: $issue_url"
        elif grep -q '^result=spooled' /tmp/aidlc-retro-result.txt; then
            echo "gh が利用不可のためスプールしました。次回 gh 利用可能時に bash skills/aidlc/scripts/retrospective-resend.sh を実行してください。"
        else
            grep '^reason=' /tmp/aidlc-retro-result.txt > /tmp/aidlc-retro-reason.txt
            read reason_line < /tmp/aidlc-retro-reason.txt
            echo "起票スキップ: $reason_line"
        fi
        ;;
    1)
        grep '^reason=' /tmp/aidlc-retro-result.txt > /tmp/aidlc-retro-reason.txt
        read reason_line < /tmp/aidlc-retro-reason.txt
        echo "[警告] 起票失敗（再送可能）: $reason_line"
        ;;
    2)
        echo "[エラー] retrospective_api_create_issue 引数 / fatal エラー" >&2
        ;;
    4)
        echo "[エラー] 対話必須ガード: 対話確認トークンの発行 / 検証に失敗したため起票をブロックしました。AskUserQuestion で起票実行可否を確認した上で再実行してください。" >&2
        ;;
esac
```

### Step 5: update フック（起票成功時のみ）

```bash
if [[ -n "${issue_url:-}" ]]; then
    retrospective_api_update_issue "$issue_url" "$cycle" || \
        printf 'warn\tunit003_update_hook_failed\t%s\n' "$issue_url" >&2
fi
```

`retrospective_api_update_issue` 内部の `retrospective_update_hook` は `gh issue edit` で `human_reviewed: false → true` 更新と差分コメント追記を行う。フック失敗時は警告のみで処理は継続する。

## 1.6 次サイクル Intent への反映

Try のうちプロダクト固有事項は、次サイクル Inception の `requirements/intent.md` 前置きで「前サイクル振り返り由来の前提」として参照する。次サイクル Inception 開始時、`steps/inception/01-setup.md §4a` の `predecessor_resolve_issue` が以下 5 経路で前サイクル振り返りを解決する（v2.5.1 Unit 004 / 本スキルの起票結果も Issue として参照可能）:

- 経路 1/1': 分岐 (a)/(b) 採用時 GitHub Issue（`retrospective` ラベル + Milestone or title 一致）
- 経路 2: spool fallback（`gh` 不可時に履歴 spool から URL 抽出）
- 経路 3: v2.5.0 互換 fallback（`cycles/{{PREV_CYCLE}}/operations/retrospective.md` 存在時）
- 経路 4: 全経路 0 件 → warn + continue

参照手順は `skills/aidlc/steps/inception/01-setup.md §4a` を参照。

## 完了サマリ

```text
【振り返り完了】
  対象サイクル: {{CYCLE}}
  feedback_mode: <interactive|local-issue-only|mirror-only|local-and-mirror|disabled>
  起票結果: <created|spooled|skipped|disabled> （Issue URL: ...）
  cap: <current_count>/<limit>
```
