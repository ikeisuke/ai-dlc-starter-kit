# ドメインモデル: Unit 003 doctor v1 実装

## 概要

v3 診断コマンド `doctor` のドメインを、8 領域 + parse-guard の診断（診断のみ・自動修正しない）と総合終了コード導出としてモデル化する。

**重要**: 本ドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2 で行う。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/scripts/state-validate.sh` | `[state]` 診断の wrap 契約（stdout `status:valid` / `status:warn:*`、exit 0/1/2） |
| `skills/aidlc-v3/scripts/work-item-validate.sh` | `[work-items]` 診断の wrap 契約（exit 0/1/2、dir 不在・0件は rc1） |
| `skills/aidlc-v3/scripts/state-read.sh` | `[cycle]` 診断（`current_cycle` 取得 / exit 0/1/2） |
| `skills/aidlc/scripts/read-config.sh` | `[config]` 診断の wrap 契約（exit 0=値 / 1=キー不在 / 2=config 不在・dasel 不在） |
| `bin/check-frontmatter-parse-guard.sh` | `[parse-guard]` 診断（exit 0=違反なし/skip / 1=違反 / 2=エラー） |
| `skills/aidlc/guides/exit-code-convention.md` | doctor の総合 exit code 設計（0=警告付き完了含む / 1=バリデーション / 2=システム） |
| `skills/aidlc-v3/scripts/tests/test-state-scripts.sh` | 契約テストハーネス方式（自己完結 / jq 前提 / mktemp + trap / 一時 git repo fixture） |
| `skills/aidlc-v3/SKILL.md` | doctor の予約記述（L9 / L17-22 / L55 / L118-120）の更新点、補助コマンド分類 |
| `skills/aidlc-v3/steps/release.md` | native git/gh 診断の既存パターン（`git status --porcelain` / `gh pr list/view` / `gh auth status`） |

### (b) 設計時に意識すべき挙動

- doctor は**診断のみ**（state 変更・自動修正しない）。各領域は既存スクリプトを wrap し exit code を OK/WARN/ERROR に写像する（新規ロジック最小化）。
- **No active cycle（state.json 不在）は通常分岐**（WARN/INFO + 総合 exit 0）。未開始リポジトリを失敗扱いにしない。
- `work-item-validate.sh` は dir 不在・0件を **rc1（バリデーションエラー）** にするため、doctor 側で前提（state 存在・current_cycle・dir 存在）を判定してから呼ぶ（define 前を ERROR 誤判定しない）。
- `read-config.sh` の **rc2 は config 不在も dasel 不在も同一**。doctor は config 不在（ERROR）と dasel 不在（依存不足 / exit 2 系）を区別して扱う。
- gh 不可用時は `[gh]`/`[pr]` を WARN/skip し他 7 領域は継続（NFR 可用性 / exit に影響させない）。
- exit code 規約: 警告付き完了は exit 0（警告を exit 2 にしない / v1.27.3 の教訓）。
- `[phase]` / `[trace]` は alpha.8 defer（本 Unit では実装しない / SoT への defer 反映のみ）。

### (c) 既存実装に基づく代替案検討

| 方針 | 既存実装との適合性 | 判定 |
|------|------------------|------|
| `reuse-wrap`（既存 validate/read/parse-guard スクリプトを wrap し exit code を写像） | renewal-plan の doctor 設計（新規ロジック最小化）に合致。回帰リスク小 | **採用** |
| `reimplement`（doctor 内で frontmatter/state/config を再パース） | 安全境界スクリプトの重複・parse-guard 違反リスク。DRY 違反 | 却下 |
| `full-scope`（[phase]/[trace] も alpha.7 で実装） | Unit 境界（alpha.8 defer）逸脱・スコープ超過 | 却下 |

## エンティティ / 値オブジェクト

### DiagnosisArea（診断領域 / 値オブジェクト）

- **属性**:
  - `name`: string - `config` / `state` / `cycle` / `work-items` / `git` / `gh` / `pr` / `scripts` / `parse-guard`
  - `severity`: `OK` | `WARN` | `ERROR` | `SKIP`
  - `detail`: string - 診断結果の要約（機密マスク済み）
- **不変性**: 1 回の doctor 実行で各領域につき 1 つ確定。
- **振る舞い**: 対応する再利用スクリプトを wrap し exit code → severity を写像。gh 従属領域（gh/pr）は gh 不可用時 WARN/skip。

### DiagnosisReport（診断レポート / 集約）

- **集約ルート**: DiagnosisReport
- **含まれる要素**: `DiagnosisArea[]`（9 領域）
- **不変条件**: 全領域を評価する（gh 不可用でも他領域は継続）。診断中に state を変更しない。
- **振る舞い**: `overall_exit_code()` を導出（下記ドメインサービス）。

## ドメインサービス

### ExitCodeResolver（総合終了コード導出）

- **責務**: `DiagnosisArea[]` から doctor の総合 exit code を導出（exit-code-convention.md 準拠）。
- **規則**:
  - いずれかの領域が **診断不能**（jq 欠落 / dasel 欠落で `[config]` 依存不足 / git repo 外）→ **exit 2**。
  - 上記以外で **ERROR 領域あり**（state 破損・schema 不正 / 必須スクリプト不在 / parse-guard 違反 / work-items 不正（dir あり時））→ **exit 1**。
  - OK / WARN / SKIP のみ（No active cycle・git dirty・gh 未認証・schema warn 等）→ **exit 0**。

### ScriptPresenceChecker（`[scripts]` 必須集合確認）

- **責務**: 必須スクリプトの存在を確認。
- **必須集合（doctor v1 の正本 / SoT）**: `state-read.sh` / `state-write.sh` / `state-validate.sh` / `state-init.sh` / `work-item-next.sh` / `work-item-validate.sh` / `work-item-status.sh` / `lib/frontmatter.sh`（スキルベース `scripts/` 相対 / 計 8 件）。**本集合が doctor の必須スクリプト正本である**（指摘#1）。
- **SKILL.md との関係**: 現行 `SKILL.md:118` の `scripts/` 列挙は `state-init.sh` / `lib/frontmatter.sh` を**未列挙**。SKILL.md は本正本集合への **反映先**であり、Phase 2 で `state-init.sh` / `lib/frontmatter.sh` を追記して本集合に一致させる（「現状参照」ではなく「実装で同期する目標」）。

## ユビキタス言語

- **shallow scope**: alpha.7 の doctor 診断範囲（8 領域 + parse-guard）。`[phase]`/`[trace]` を含まない。
- **診断のみ**: doctor は問題を検出・推奨するが**自動修正・状態変更をしない**。
- **No active cycle**: state.json 不在（未開始）。doctor では WARN/INFO + exit 0 の通常分岐。
- **依存不足**: doctor 自身が診断に必要なツール（jq / dasel / git）を欠く状態。exit 2。
- **gh 従属領域**: `[gh]` / `[pr]`。gh 不可用時に WARN/skip し他領域に影響させない。

## core から外す（alpha.8 defer / 実装しない）

- `[phase]`: フェーズ導出 code 化（doctor.md に alpha.8 defer 明記 / 実装しない）。
- `[trace]`: intent→work items→designs の整合チェック（同上）。

## 不明点と質問（設計中に記録）

[Question] なし（計画レビュー Round 3 で指摘0件 / SoT・再利用スクリプト契約を codex が実読検証）
[Answer] -
