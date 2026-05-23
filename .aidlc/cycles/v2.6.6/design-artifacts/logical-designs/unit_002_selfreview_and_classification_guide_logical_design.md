# 論理設計: Unit 002 §1.2.5 セルフレビュー観点新ステップ + 3 問固定判別ガイド

## 概要

ドメインモデル（同 Unit 002 domain_model.md）を `skills/aidlc-retrospective` / `skills/aidlc/scripts/lib/retrospective-api.sh` 上に物理マッピングするための論理設計。**コードは書かず**、ファイル配置・コンポーネント責務・公開インターフェース・処理フロー・テスト構成のみを定義する。

---

## 事前コード読込み（ステップ 0 / v2.6.5 / #679 / Unit 002）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-retrospective/steps/retrospective.md`（350 行） | §1.2 主因切り分け（130-138）/ §1.3 格納先選択（140-150）/ §1.5 Issue 起票フロー（162-329）の現行構造を把握し、§1.2.5 挿入位置（h2 `## 1.2.5` / 既存 §1.2 と §1.3 の間）と dialog token TTL 300 秒制約（Step 4 直前 token verify）を確認 |
| `skills/aidlc/scripts/lib/retrospective-api.sh`（204 行） | 公開 API レイアウト（タイプ A / B、終了コード規約 0/1/2/3/4、SOURCED ガード、bootstrap）と `retrospective_api_aggregate_enabled` の fail-safe パターン（`if value=$(...); then ...; else rc=$?; fi` で caller errexit 保護）を把握し、新規 `retrospective_api_evaluate_selfreview_verdict` / `retrospective_api_ensure_label` / `retrospective_api_record_selfreview` を同等規約に揃える |
| `tests/retrospective-aggregate-enabled.bats`（Unit 001 で導入） | bats テストの記述パターン（`setup` / `teardown` / `AIDLC_PROJECT_ROOT` モック / `load_api_fresh` / SoT 文言の grep 検証）を把握し、新規 3 bats を同パターンに揃える |
| `tests/lib/retrospective_normalize.bash`（Unit 001 で導入） | bats helper の配置パターンを把握（ただし本 Unit では helper 追加は不要） |
| `skills/aidlc/SKILL.md`「AskUserQuestion 使用ルール」 | 「ユーザー選択（振り返り内容の決定）」種別仕様（auto mode 適用外 / 実行時ガード = 対話確認トークン）を把握し、§1.2.5 の AskUserQuestion 呼び出しが種別仕様に整合することを確認 |
| `skills/aidlc-retrospective/SKILL.md` | スキル冒頭の SoT 文言（v2.6.6 Unit 001 で追加済「目的: T を Issue 化…」）を確認し、§1.2.5 との文脈一貫性を担保 |
| `.aidlc/cycles/v2.6.6/story-artifacts/units/002-selfreview-and-classification-guide.md` | Unit 定義 39 行目「依存する Unit: なし」、NFR「可用性: AskUserQuestion 失敗時はセルフレビュー結果を `undecidable` 扱い」、責務「§1.2.5 ステップ追加」「3 問固定判別ガイド追加」「`selfreview-capped` ラベル fail-safe」を把握 |
| `.aidlc/cycles/v2.6.6/plans/unit-002-plan.md` | 計画書「公開契約」§1〜§3（`retrospective_api_ensure_label` exit 0/2/3 厳格 fail-fast、`history/operations.md` ログフォーマット、`selfreview_capped` 確定規則）、「責務分割」表（Unit 002 / Unit 004 境界）、「リスク・前提」（AskUserQuestion 失敗時 undecidable）を SoT として参照 |

### (b) 設計時に意識すべき挙動

- **dialog token TTL 300 秒制約**: §1.5 Step 4 直前の `retrospective_dialog_token_verify` が TTL 切れすると起票がブロックされる（既存 `retrospective-api.sh exit 4 / reason=dialog-required`）。§1.2.5 の AskUserQuestion 3 観点 + 差し戻し（最大 3 回）は **token 発行前** に完了する必要がある（§1.2.5 完了 → §1.3 → §1.5 Step 1〜3 → §1.5 Step 4 直前で token 発行 → 起票確認 AskUserQuestion → token verify → 起票）
- **`retrospective_api_*` シグネチャ不変規約**: Unit 001 bats で固定済の既存関数群（`retrospective_api_resolve_feedback_mode` / `retrospective_api_is_interactive_env` / `retrospective_api_requires_wizard` / `retrospective_api_run_wizard` / `retrospective_api_check_cap` / `retrospective_api_compose_body` / `retrospective_api_prefill` / `retrospective_api_aggregate_enabled` / `retrospective_api_record_response` / `retrospective_api_create_issue` / `retrospective_api_update_issue`）には触らず、新規 helper のみ純粋追加
- **タイプ B / タイプ A 規約**: 新規 `retrospective_api_evaluate_selfreview_verdict` は副作用なし（タイプ B / stdout 1 行 / exit 0 統一 fail-safe）。`retrospective_api_ensure_label` と `retrospective_api_record_selfreview` は副作用あり（タイプ A / exit code で判定）
- **`set -e` / errexit 保護**: 既存 `retrospective_api_aggregate_enabled`（135-180 行）の `if value=$(...); then rc=0; else rc=$?; fi` パターンを新規 helper でも採用し、caller の errexit を変更しない
- **`gh label create` の冪等性**: gh CLI の exit code は version 依存。事前に `gh label list --search <name> --json name --jq '.[].name'` で厳密一致判定を行い、不在時のみ `gh label create` 1 回試行（リトライなし）
- **bats での AskUserQuestion 不在**: bats 環境では `AskUserQuestion` ツールを起動できないため、§1.2.5 の判定純粋ロジックを `retrospective_api_evaluate_selfreview_verdict` として関数化し、bats では純粋関数の単体テストのみ実施
- **コマンド置換禁止（リポジトリ規約）**: `CLAUDE.md` § AI エージェント Bash ツール経由の安全パターン に従い、bats 内 / steps/retrospective.md 内ともに `$(...)` / backtick を引数文字列に含めない
- **計画書「責務分割」整合（指摘 #1 反映 / 重要）**: §1.2.5 内では `retrospective_api_ensure_label` を**呼び出さない**。capped 確定時は `selfreview_capped=true` を `history/operations.md` に記録するのみ。実呼び出し（§1.5 起票直前 + ラベル付与）は Unit 004 責務

### (c) 既存実装に基づく代替案検討

| 案 | 採用判断 | 根拠 |
|----|---------|------|
| **案 A: §1.2.5 のループ制御フロー全体を bash 関数化（`retrospective_api_run_selfreview`）し、bats で全経路をテスト** | **却下** | `AskUserQuestion` 自体は外部ツールで bash から呼べない。bash 関数化しても結局 AskUserQuestion 呼び出し部はステップ文書側に残り、二重定義になる |
| **案 B: §1.2.5 の判定純粋ロジックのみを関数化し（`retrospective_api_evaluate_selfreview_verdict <a_yes> <b_yes> <c_yes> <rebuttal_count>` → `pass\|rebuttal\|capped\|undecidable`）、AskUserQuestion 呼び出しと差し戻しループはステップ文書側に残す。bats は関数の判定論理だけを網羅** | **採用** | 純粋関数化で bats 単体テスト可能。AskUserQuestion ループはステップ文書側で対話制御し、判定論理だけを SoT として固定できる。`undecidable` ケースも純粋判定でテスト可能 |
| **案 C: §1.2.5 を新ステップとして追加せず、§1.5 Step 4 の対話必須ガード内に組み込む** | **却下** | Unit 定義 SC-05 が「§1.2.5 という独立ステップ追加」を要求。§1.5 Step 4 内では既存 token verify との順序が崩れる |
| **案 D: `retrospective_api_ensure_label` を `gh label list --search` で事前判定 → 不在時のみ `gh label create`** | **採用** | `gh label create` の exit 22（HTTP 422 / already exists）解釈は gh version 依存（エラー文字列の安定性に依存しない）。事前 list で冪等性を担保する方が堅牢 |
| **案 E: `retrospective_api_ensure_label` を fail-safe（exit 0 統一 + warn のみ）にする** | **却下** | 計画書「公開契約」§1 で「`exit 2/3` で起票中断（厳格 fail-fast）」を確定済。`exit 0` 統一は不整合 |
| **案 F: §1.2.5 内で `retrospective_api_ensure_label` を呼び、capped 確定と同時にラベル作成を実行する** | **却下**（指摘 #1 反映） | 計画書「責務分割」表で「§1.5 Step 4 起票直前での helper 呼び出し統合」は Unit 004 責務として明確化済。Unit 002 が §1.2.5 内で実呼び出しすると責務境界違反 |

---

## アーキテクチャパターン

- **既存パターンの踏襲**: `skills/aidlc/scripts/lib/retrospective-api.sh` の Facade（公開 API 層）+ 内部 lib（`skills/aidlc/scripts/lib/*.sh`）の単方向境界を維持
- **新規追加 helper の規約**: 既存の「タイプ A（副作用あり / exit code で判定）」「タイプ B（純粋値 / stdout 1 行）」分類に従う
- **判定純粋ロジック分離**: ドメインモデル §「採用案 B」に従い、AskUserQuestion 制御フローはステップ文書側、判定純粋関数（`retrospective_api_evaluate_selfreview_verdict`）は `retrospective-api.sh` 側
- **selfreview-capped ラベル fail-safe**: 既存 `gh label` 操作は `retrospective-api.sh` 経由を採用しておらず、本 Unit で初めて導入（新規 helper `retrospective_api_ensure_label`）

---

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc-retrospective/                            （独立スキル / ドキュメント層）
├── SKILL.md                                            （変更なし / 既存）
├── steps/
│   └── retrospective.md                                （§1.2.5 新セクション追加）
└── templates/                                          （新規ディレクトリ）
    └── try_classification_guide.md                     （新規 / 3 問固定）

skills/aidlc/scripts/lib/                              （内部 lib 層）
└── retrospective-api.sh                                （タイプ A / B helper 追加）
    ├── retrospective_api_evaluate_selfreview_verdict   （新規 / タイプ B / 純粋判定）
    └── retrospective_api_ensure_label                  （新規 / タイプ A / 副作用 gh label）

tests/                                                  （bats 層）
├── retrospective-selfreview-verdict.bats               （新規 / 判定純粋関数の単体 / 陽性・陰性・cap・undecidable）
└── retrospective-ensure-label.bats                     （新規 / ensure_label の単体 / label 既存・自動作成・権限不足・gh 不可）
```

### コンポーネント詳細

#### `steps/retrospective.md §1.2.5 Try 構造性セルフレビュー`（新規セクション）

- **責務**: §1.2 主因切り分け完了後・§1.3 格納先選択前に、各 Try について `AskUserQuestion` で 3 観点を確認し、差し戻しループを制御する手順を文書化
- **依存**: ドメインモデル §「SelfReviewSession」/ §「SelfReviewEvaluator」/ `retrospective-api.sh` の新規 helper / `templates/try_classification_guide.md`
- **公開インターフェース**:
  - 入力: §1.2 主因切り分け結果 + KPT テンプレ展開済み Try リスト
  - 出力: 各 Try について確定 `verdict` + `selfreview_capped` フラグ + `history/operations.md` 追記
- **配置位置**: 既存 §1.2（130-138 行）と §1.3（140-150 行）の間に挿入

#### `templates/try_classification_guide.md`（新規）

- **責務**: 3 問固定（再発性 / 対象レイヤ / 再入余地）の判別質問テンプレ。ユーザーにそのまま提示可能な markdown
- **依存**: なし（静的テンプレ）
- **公開インターフェース**: ファイル本体が SoT。`steps/retrospective.md §1.2.5` から相対 link `../templates/try_classification_guide.md` で参照

#### `scripts/lib/retrospective-api.sh::retrospective_api_evaluate_selfreview_verdict`（新規 / タイプ B）

- **責務**: 4 引数の純粋判定。AskUserQuestion 応答列を入力に受けて `pass | rebuttal | capped | undecidable` を 1 行で返す
- **依存**: bash 組み込みのみ（外部コマンド呼び出しなし）

#### `scripts/lib/retrospective-api.sh::retrospective_api_ensure_label`（新規 / タイプ A）

- **責務**: 指定ラベルが repository に存在することを保証。不在時 1 回試行で作成
- **依存**: `gh label list` / `gh label create`

#### `scripts/lib/retrospective-api.sh::retrospective_api_record_selfreview`（新規 / タイプ A / 履歴記録ヘルパ）

- **責務**: SelfReviewSession の確定状態を `write-history.sh` 経由で `history/operations.md` 追記。**呼び出し側は steps/retrospective.md §1.2.5** で 1 Try 1 回呼ぶ
- **依存**: `scripts/write-history.sh`（既存）

> 補足: `retrospective_api_record_selfreview` は便宜的な薄いラッパだが、計画書公開契約 §2 のログフォーマットを bash 関数 1 箇所に集約することで、文書側（steps/retrospective.md）でのフォーマット重複を避ける。タイプ A 規約に従い stdout は空、exit code は write-history.sh 経由の値を中継

---

## インターフェース設計

### スクリプトインターフェース設計

#### `retrospective_api_evaluate_selfreview_verdict <a_yes> <b_yes> <c_yes> <rebuttal_count>`

##### 概要

3 観点の応答（`true`/`false`）と現在の差し戻し回数（`0..3`）から最終 verdict を判定する純粋関数（タイプ B / 副作用なし）。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `<a_yes>` | 必須 | 観点 A の回答（`true`=該当する=表面的 / `false`=該当しない / `undecidable`=AskUserQuestion 失敗センチネル） |
| `<b_yes>` | 必須 | 観点 B の回答（同上の 3 値） |
| `<c_yes>` | 必須 | 観点 C の回答（同上の 3 値） |
| `<rebuttal_count>` | 必須 | 現在までの差し戻し回数（整数 `0..3`、本呼び出しが回数 N+1 回目の判定なら N を渡す） |

##### 成功時出力

```text
pass
```

または `rebuttal` / `capped` / `undecidable` を 1 行（末尾改行あり）。

- 終了コード: `0`
- 出力先: stdout

##### エラー時出力

```text
[warn] retrospective_api_evaluate_selfreview_verdict: 引数不正 ("<入力値>")。既定 undecidable にフォールバックします
undecidable
```

- 終了コード: `0`（fail-safe）
- 出力先: stderr (warn) + stdout (`undecidable`)

##### 判定論理（疑似コード）

```text
if a_yes == "undecidable" OR b_yes == "undecidable" OR c_yes == "undecidable":
    -> "undecidable"
elif a_yes == "false" AND b_yes == "false" AND c_yes == "false":
    -> "pass"
elif rebuttal_count >= 3:
    -> "capped"
else:
    -> "rebuttal"
```

入力値正規化:

- `true|yes|該当する` → `true`
- `false|no|該当しない` → `false`
- `undecidable|undef|?` → `undecidable`
- それ以外 → warn + `undecidable` フォールバック

##### 使用コマンド

```bash
# 初回応答 (rebuttal_count=0) で全観点 no
retrospective_api_evaluate_selfreview_verdict false false false 0  # -> pass

# 1 回差し戻し後 (rebuttal_count=1) で観点 A だけ yes
retrospective_api_evaluate_selfreview_verdict true false false 1   # -> rebuttal

# 3 回差し戻し到達 (rebuttal_count=3) で観点 yes が残る
retrospective_api_evaluate_selfreview_verdict true false false 3   # -> capped

# AskUserQuestion 失敗センチネル
retrospective_api_evaluate_selfreview_verdict undecidable false false 0  # -> undecidable
```

---

#### `retrospective_api_ensure_label <label_name>`

##### 概要

指定ラベルが repository に存在することを保証する（タイプ A / 副作用あり）。不在時のみ `gh label create` を 1 回試行する fail-safe 経路。**計画書「公開契約 §1」が SoT**。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `<label_name>` | 必須 | 保証対象ラベル名（例: `selfreview-capped`） |

##### 成功時出力

```text
（空 stdout）
```

- 終了コード: `0`（ラベル存在確認済 = 既存 OR 自動作成成功）
- 出力先: stdout（空）

##### エラー時出力

```text
[warn] retrospective_api_ensure_label: ラベル "<name>" の自動作成に失敗しました（理由: permission_denied）
```

- 終了コード:
  - `0`: 成功（既存 or 作成成功）
  - `2`: 自動作成失敗（権限不足等 / fail-fast、呼び出し側は当該 T Issue 起票を中断）
  - `3`: `gh` CLI 利用不能（`gh_status != available` / network 断等 / fail-fast、呼び出し側は当該 T Issue 起票を中断）
- 出力先: stderr

##### 副作用

- ラベル不在時 `gh label create <name> --color BFD4F2 --description "Try 構造性セルフレビュー上限到達"` を 1 回試行（リトライなし）
- 既存ラベル時は no-op

##### 処理フロー（疑似コード）

```text
1. `command -v gh` で gh の存在確認
   - 不在 -> exit 3
2. `gh label list --search <name> --json name --jq '.[].name'` で既存判定
   - 厳密一致あり -> exit 0（既存）
   - 厳密一致なし -> 次のステップ
3. `gh label create <name> --color BFD4F2 --description "..."` を 1 回試行
   - exit 0 -> exit 0（作成成功）
   - その他 -> exit 2（権限不足等 / fail-fast）
```

##### caller の errexit 保護

既存 `retrospective_api_aggregate_enabled` と同様、caller の `set -e` 状態を変更しないよう `if value=$(...); then ...; else rc=$?; fi` パターンで gh CLI 呼び出しを評価する。

##### 使用コマンド

```bash
# 既存ラベル時 (no-op)
retrospective_api_ensure_label selfreview-capped   # -> exit 0

# 自動作成成功時
retrospective_api_ensure_label selfreview-capped   # -> exit 0 + 副作用: ラベル作成

# 権限不足時
retrospective_api_ensure_label selfreview-capped   # -> exit 2 + stderr warn

# gh 利用不能時
retrospective_api_ensure_label selfreview-capped   # -> exit 3 + stderr warn
```

---

#### `retrospective_api_record_selfreview <cycle> <try_id> <verdict> <selfreview_capped> <responses_json>`

##### 概要

セルフレビュー確定状態を `history/operations.md` に追記する薄いラッパ（タイプ A）。計画書「公開契約 §2」のログフォーマット 1 箇所集約点。

##### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `<cycle>` | 必須 | 対象サイクル（例: `v2.6.6`） |
| `<try_id>` | 必須 | Try 番号 |
| `<verdict>` | 必須 | `pass` / `rebuttal` / `capped` / `undecidable` |
| `<selfreview_capped>` | 必須 | `true` / `false`（`verdict=capped` のときのみ `true`） |
| `<responses_json>` | 必須 | 応答列を JSON 配列文字列にしたもの（差し戻し回数 + 1 件、各要素 `{a,b,c,undecidable}`） |

##### 成功時出力

```text
（空 stdout）
```

- 終了コード: `write-history.sh` 経由の値（`0` 成功 / `1` 引数不正 / `2` I/O 失敗 / `3` ガード拒否）
- 出力先: stderr (write-history.sh の出力をそのまま中継)

##### 内部実装方針

`write-history.sh --content-file <一時ファイル>` 経由で計画書公開契約 §2 のテキストフォーマットを追記する。コマンド置換 (`$(...)`) は使用せず、引数文字列に embed しない（プロジェクト規約「Bash ツール経由の安全パターン」遵守）。

---

## データモデル概要

### 一時ファイル（dialog token TTL 300 秒内で揮発）

| ファイルパス | 形式 | 用途 |
|------------|------|------|
| `/tmp/aidlc-retro-selfreview-<cycle>-<try_id>.log` | text | 1 セッション中の AskUserQuestion 応答ログ（diagnostic 用、TTL 切れ判定不要） |
| `/tmp/aidlc-retro-selfreview-<cycle>-<try_id>.json` | JSON | `responses_json` 構築用の中間ファイル |

### `history/operations.md` 追記フォーマット（計画書公開契約 §2 SoT を再掲）

```text
- イベント: AIDLC retrospective セルフレビュー実行
- サイクル: {{CYCLE}}
- Try ID: <try-N>
- 観点 A 応答: yes | no
- 観点 B 応答: yes | no
- 観点 C 応答: yes | no
- 差し戻し回数: <0-3>
- 確定 verdict: pass | rebuttal | capped | undecidable
- selfreview_capped: true | false
- 構造課題昇格根拠: <ユーザー追記テキスト / 未記入時は "-">
```

---

## 処理フロー概要

### §1.2.5 セルフレビュー実行フロー（Unit 002 責務範囲のみ）

**ステップ**:

1. 各 Try について以下を最大 4 回繰り返す（初回 + 差し戻し 3 回）:
   1. `try_classification_guide.md` を参照し、ユーザーに 3 問のうち必要に応じて参照を促す（テンプレ link 提示）
   2. `AskUserQuestion`（multiSelect=true、observations 3 観点）で「該当する観点」を選択させる
   3. AskUserQuestion 失敗時 → `undecidable` センチネル
   4. 回答を `responses` 配列に蓄積
   5. `retrospective_api_evaluate_selfreview_verdict <a> <b> <c> <rebuttal_count>` で `verdict` を取得
   6. `verdict=pass` → ループ終了、`selfreview_capped=false`
   7. `verdict=capped` → ループ終了、`selfreview_capped=true`（**ラベル付与本体は Unit 004 責務 / §1.2.5 内では `retrospective_api_ensure_label` を呼ばない**）
   8. `verdict=undecidable` → ループ終了、起票保留（Unit 004 側で skip）
   9. `verdict=rebuttal` → ユーザーに Try 起草差し戻し提示、`rebuttal_count++`、ループ継続
2. ループ終了後、`retrospective_api_record_selfreview <cycle> <try_id> <verdict> <selfreview_capped> <responses_json>` で `history/operations.md` に追記
3. §1.3 格納先選択へ進む

**関与するコンポーネント**: §1.2.5 セクション文書 / `retrospective_api_evaluate_selfreview_verdict` / `retrospective_api_record_selfreview` / `try_classification_guide.md`

> **責務境界（指摘 #1 反映）**: 上記フローには `retrospective_api_ensure_label` の呼び出しを含まない。§1.5 Step 4 起票直前で `ensure_label` を呼び、起票 payload に `selfreview-capped` ラベルを組み込む処理は **Unit 004** の責務であり、本 Unit では同 helper の公開契約定義と単体 bats のみを完結させる。Unit 004 は `history/operations.md` の `selfreview_capped` 値を読み、`true` の Try について `ensure_label` 呼び出し → ラベル付与 → 起票を実装する。

### dialog token TTL との関係

- §1.2.5 完了 → §1.3 格納先選択 → §1.5 Step 1〜3 → **§1.5 Step 4 直前で dialog token を発行** → AskUserQuestion で起票確認 → token verify → 起票
- §1.2.5 の AskUserQuestion は **token 発行前** に完了する（TTL 300 秒の枠外）

---

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 「セルフレビュー 1 回あたりの追加対話 ≤ 3 質問 × Try 件数 + 差し戻し時 再質問。dialog token TTL 内で完了」
- **対応策**: 3 観点は 1 件の `AskUserQuestion`（multiSelect=true）にまとめて 1 回の対話で完結。差し戻しは最大 3 回 × Try 件数で頭打ち。dialog token 発行前に完了するため TTL 300 秒の影響を受けない

### セキュリティ

- **要件**: 「セルフレビュー回答ログに機密情報を含めない」
- **対応策**: `retrospective_api_record_selfreview` で書き込む `history/operations.md` は AskUserQuestion 選択肢（`true`/`false`/`undecidable`）と Try 番号のみを含む構造化フィールド。自由記述「構造課題昇格根拠」は機密マスク済テキストのみを許容（既存 `review-flow.md` 「機密情報マスク」セクションのルールを準用）

### スケーラビリティ

- **要件**: Unit 定義に明記なし。retrospective 1 サイクルあたり Try 件数は通常 1 桁台
- **対応策**: 純粋判定関数とラベル ensure はサイクル毎に高々 Try 件数回呼ばれるのみ。スケール懸念なし

### 可用性

- **要件**: 「AskUserQuestion 失敗時はセルフレビュー結果を `undecidable` 扱いとして差し戻し不可（ユーザー判断待ち）」
- **対応策**: `evaluate_selfreview_verdict` 第 1〜3 引数で `undecidable` センチネルを受理し、いずれか 1 つでも `undecidable` なら verdict 自体を `undecidable` 確定する。差し戻しループに入らず、当該 Try の起票は Unit 004 側で skip + warn 記録される（計画書「リスク・前提」の `AskUserQuestion` 失敗時フォールトモデル整合）

---

## 技術選定

- **言語**: bash（既存 `scripts/lib/*.sh` 群と統一）
- **テストフレームワーク**: bats（既存 `tests/retrospective-*.bats` 群と統一）
- **外部依存**: `gh` CLI（v2.x 系、既存 retrospective 起票フローと同じ要件）
- **テンプレ形式**: markdown（既存 `templates/*.md` と統一）

---

## 実装上の注意事項

- **`set -e` 状態保持**: 新規 helper は既存 `retrospective_api_aggregate_enabled` と同じ `if value=$(...); then ...; else rc=$?; fi` パターンで caller の errexit を変更しない
- **コマンド置換禁止**: 本リポジトリ規約「Bash ツール経由の安全パターン」（CLAUDE.md）に従い、bats テスト中の引数文字列に `$(...)` / backtick を含めない。一時ファイル経由の file-based interface を優先
- **dasel 直接呼び出し回避**: 本 Unit では `.aidlc/config.toml` 値の参照は不要のため、`read-config.sh` も呼び出さない
- **既存 `retrospective_api_*` シグネチャ不変**: Unit 001 bats で固定済の既存関数群は触らない（純粋な追加のみ）
- **テンプレディレクトリ新規作成**: `skills/aidlc-retrospective/templates/` ディレクトリ自体が新規。`mkdir -p` で先に作成してから `try_classification_guide.md` を配置
- **§1.2.5 セクション挿入時の見出しレベル**: 既存 §1.2（h2 = `## 1.2`）と §1.3（h2 = `## 1.3`）の間に挿入するため、新セクションも `## 1.2.5 Try 構造性セルフレビュー` の h2 とする
- **try_classification_guide.md からの参照リンク**: `steps/retrospective.md §1.2.5` から `[判別ガイド](../templates/try_classification_guide.md)` の相対 link で参照

---

## テスト設計

### `tests/retrospective-selfreview-verdict.bats`（新規）

判定純粋関数の単体テスト。

| ケース | 入力 | 期待出力 | SC 対応 |
|--------|------|---------|---------|
| 全観点 no / 差し戻し 0 | `false false false 0` | `pass` (exit 0) | SC-05（陰性） |
| 観点 A だけ yes / 差し戻し 0 | `true false false 0` | `rebuttal` (exit 0) | SC-05（陽性差し戻し発生） |
| 観点 A だけ yes / 差し戻し 2 | `true false false 2` | `rebuttal` (exit 0) | SC-05（差し戻し上限到達前） |
| 観点 A だけ yes / 差し戻し 3 | `true false false 3` | `capped` (exit 0) | SC-05（capped 経路） |
| 全観点 yes / 差し戻し 3 | `true true true 3` | `capped` (exit 0) | SC-05 |
| 観点 A undecidable | `undecidable false false 0` | `undecidable` (exit 0) | 計画書 undecidable 経路 |
| 観点 B undecidable | `false undecidable false 1` | `undecidable` (exit 0) | 同上 |
| 不正値（数字）| `1 0 0 0` | `undecidable` (exit 0) + stderr warn | fail-safe |

### `tests/retrospective-ensure-label.bats`（新規）

`retrospective_api_ensure_label` の単体テスト。`gh` CLI を `PATH` の前段にモック shim 配置して挙動制御。

| ケース | gh shim 挙動 | 期待出力 | SC 対応 |
|--------|--------------|---------|---------|
| ラベル既存 | `gh label list --search` がラベル名を返す | exit 0 + stdout 空 + 副作用なし | SC-05（label 既存） |
| ラベル自動作成成功 | `gh label list` 空 / `gh label create` exit 0 | exit 0 + stdout 空 + `gh label create` 1 回呼ばれた記録 | SC-05（label 自動作成） |
| 権限不足 | `gh label list` 空 / `gh label create` exit 非 0 | exit 2 + stderr warn | SC-05（権限不足 fail-fast） |
| gh CLI 不在 | `PATH` から `gh` を除外 | exit 3 + stderr warn | 公開契約 §1 exit 3 |

### `tests/retrospective-selfreview-history.bats`（新規）

`retrospective_api_record_selfreview` の単体テスト。`write-history.sh` をモックして呼び出し引数を検証。

| ケース | 入力 verdict | 期待 history 追記内容 |
|--------|--------------|---------------------|
| pass | `pass` / `selfreview_capped=false` | `確定 verdict: pass` + `selfreview_capped: false` |
| capped | `capped` / `selfreview_capped=true` | `確定 verdict: capped` + `selfreview_capped: true` |
| undecidable | `undecidable` / `selfreview_capped=false` | `確定 verdict: undecidable` + `selfreview_capped: false` |

### SC マッピング

| SC | 対応テスト |
|----|----------|
| SC-05（§1.2.5 ステップ追加 + 差し戻し + 警告ラベル） | `retrospective-selfreview-verdict.bats` 全ケース + `retrospective-ensure-label.bats` 全ケース + `retrospective-selfreview-history.bats` capped ケース |
| SC-06（判別ガイドテンプレ + 参照） | grep ベース検証: `templates/try_classification_guide.md` 内に 3 問固定見出しが存在 + `steps/retrospective.md` §1.2.5 から相対 link が存在（`tests/retrospective-aggregate-enabled.bats` と同等 SoT 文言検証パターンで `retrospective-selfreview-doc.bats` 新設 or 既存 bats に追加） |

---

## 不明点と質問（設計中に記録）

[Question] なし（計画書「公開契約」「責務分割」「リスク・前提」が確定済のため設計対話で追加質問は発生せず）
