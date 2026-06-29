# 論理設計: Unit 003 doctor v1 実装

## 概要

doctor を「既存スクリプト wrap + 軽診断」で実装し、9 領域（8 領域 + parse-guard）の OK/WARN/ERROR/SKIP 診断と総合 exit code 導出、出力手順、契約テスト、SoT 段階反映、#733 クローズを行う論理設計。

**重要**: 本論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体コードは Phase 2 で作成する。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/scripts/state-validate.sh` / `work-item-validate.sh` / `state-read.sh` | 各領域 wrap の exit code 契約 |
| `skills/aidlc/scripts/read-config.sh` | `[config]` wrap（exit 0/1/2 / rc2 は config 不在・dasel 不在共通） |
| `bin/check-frontmatter-parse-guard.sh` | `[parse-guard]` wrap（exit 0/1/2） |
| `skills/aidlc-v3/scripts/tests/test-state-scripts.sh` / `test-release-flow.sh` | 契約テストハーネス（fixture / pass-fail / 一時 git repo / ネットワーク非依存方針） |
| `skills/aidlc-v3/SKILL.md` | doctor 予約記述・scripts/steps 列挙の更新点 |
| `docs/v3/workflow.md §3.6` / `docs/v3-renewal-plan.md` | SoT 段階反映先 |
| `skills/aidlc/guides/exit-code-convention.md` | 総合 exit code 設計 |

### (b) 設計時に意識すべき挙動

- doctor は診断のみ（state 非変更）。各領域は既存スクリプトの exit code を severity に写像。
- `work-item-validate.sh` は dir 不在/0件を rc1 にするため doctor 側で前提ゲート必須。
- `read-config.sh` rc2 は config 不在と dasel 不在が同一 → doctor で区別（config 不在=ERROR / dasel 不在=依存不足 exit 2）。
- No active cycle（state.json 不在）は WARN/INFO + exit 0。
- gh 不可用は `[gh]`/`[pr]` WARN/skip（他継続 / exit 非 0 にしない）。
- 警告付き完了は exit 0（exit 2 にしない）。

### (c) 既存実装に基づく代替案検討

| 方針 | 適合性 | 判定 |
|------|-------|------|
| `reuse-wrap`: 既存 validate/read/parse-guard を wrap | renewal-plan の doctor 設計に合致・最小侵襲 | **採用** |
| `reimplement`: doctor 内で再パース | 安全境界重複・parse-guard 違反リスク | 却下 |

## アーキテクチャパターン

- **既存安全境界スクリプトの wrap + exit code 写像**。新規パースロジックを書かない（parse-guard 違反回避）。診断結果の集約と総合 exit code 導出のみ doctor.sh が担う。

## コンポーネント構成

```text
skills/aidlc-v3/
├── scripts/doctor.sh           [新規] 9 領域診断 + 総合 exit code 導出（診断のみ）
├── steps/doctor.md             [新規] 出力仕様（[phase]/[trace] は alpha.8 defer 明記）
├── scripts/tests/test-doctor.sh [新規] 契約テスト（一時 git repo fixture）
└── SKILL.md                    [変更] doctor 予約→実装済み + scripts 列挙同期
docs/
├── v3/workflow.md              [変更] §3.6 に段階注記（alpha.7/alpha.8）
└── v3-renewal-plan.md          [変更] doctor チェック項目・Phase 6 完了条件に段階注記
（GitHub）Epic #736 本文更新 / #733 クローズ / alpha.8 follow-up Issue 起票
```

### コンポーネント詳細

#### `scripts/doctor.sh`（新規）

- **責務**: 9 領域を順に診断し、各 `DiagnosisArea` の severity と detail を出力。最後に `ExitCodeResolver` で総合 exit code を返す。
- **依存**: `state-validate.sh` / `work-item-validate.sh` / `state-read.sh`（スキルベース相対）、`skills/aidlc/scripts/read-config.sh`、`bin/check-frontmatter-parse-guard.sh`、native `git` / `gh`。
- **副作用**: なし（read のみ / state 非変更 / 自動修正なし）。

#### `steps/doctor.md`（新規）

- **責務**: doctor の出力仕様・各領域の意味・`[phase]`/`[trace]` の alpha.8 defer 明記・診断のみ（自動修正しない）の宣言。

#### `scripts/tests/test-doctor.sh`（新規）

- **責務**: doctor.sh の領域診断と総合 exit code の契約検証（自己完結 / jq 前提 / 一時 git repo fixture / ネットワーク非依存）。

## スクリプトインターフェース設計

### doctor.sh

#### 概要

v3 環境の 9 領域を診断し OK/WARN/ERROR/SKIP を表示する（診断のみ・自動修正しない）。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| （なし / v1） | - | カレントリポジトリの `.aidlc/` を診断対象とする |

#### 成功時出力（例 / stdout）

```text
[config]      OK
[state]       WARN  No active cycle（/aidlc-v3 define で開始）
[cycle]       SKIP  （state なし）
[work-items]  SKIP  （define 前）
[git]         OK    clean
[gh]          WARN  未認証（gh auth status / [pr] を skip）
[pr]          SKIP  （gh 不可用）
[scripts]     OK    8/8 present
[parse-guard] OK
```

- 終了コード: OK/WARN/SKIP のみ → `0`
- 出力先: stdout（診断行）/ 詳細・エラー要約は stderr 可

#### エラー時出力 / 終了コード

| 状況 | severity 例 | 総合 exit |
|------|------------|----------|
| state 破損・schema 不正 / work-items 不正（dir あり）/ 必須スクリプト不在 / parse-guard 違反 | ERROR | `1` |
| jq 欠落 / dasel 欠落（[config] 依存不足）/ git repo 外 | （診断不能） | `2` |
| No active cycle / git dirty / gh 未認証 / schema warn | WARN/SKIP | `0` |

### 領域別 wrap 契約（exit code 写像）

| 領域 | 呼び出し | 写像 |
|------|---------|------|
| `[config]` | `read-config.sh rules.depth_level.level`（確定キー）+ config.toml 存在チェック | config 不在→ERROR(exit1) / rc1→WARN / rc0→OK / dasel 不在(rc2 かつ config あり)→依存不足(exit2) |
| `[state]` | state.json 存在 + `state-validate.sh` | 不在→WARN(No active cycle) / `valid`→OK / `warn:*`→WARN / rc1(破損)→ERROR / rc2→exit2 |
| `[cycle]` | `state-read.sh current_cycle` + dir 存在 | state なし→SKIP / dir 存在→OK / 取得不能・dir 不在→WARN |
| `[work-items]` | 前提（state・cycle・dir）判定後 `work-item-validate.sh <dir>` | state なし→**SKIP**(exit0) / dir 不在→**WARN**(exit0) / dir あり+0件→**WARN**(exit0) / dir あり+1件以上+rc0→**OK**(exit0) / dir あり+1件以上+rc1→**ERROR**(exit1) / rc2→**exit2**。dir 不在・0件は validator に渡さず doctor 側ゲートで WARN にする |
| `[git]` | `git status --porcelain` 等 | clean→OK / dirty→WARN / repo 外→exit2 |
| `[gh]` | `gh auth status` | OK→OK / 未認証・gh 不在→WARN/skip |
| `[pr]` | `gh pr list/view`（gh 可用時のみ） | gh 不可→SKIP / PR あり→OK / 0件→OK |
| `[scripts]` | 必須集合 `[[ -f ]]` | 全存在→OK / 欠落→ERROR |
| `[parse-guard]` | `bin/check-frontmatter-parse-guard.sh` | **スクリプト不在→SKIP（opt-in シグナル）** / rc0→OK / rc1→ERROR / rc2→exit2 |

> **`[parse-guard]` スクリプト不在は SKIP（opt-in シグナル / 重要）**: `bin/check-frontmatter-parse-guard.sh` は starter kit 本体に存在するが、consumer プロジェクトには無い場合がある。CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」§ opt-in シグナル方針に従い、**スクリプトの存在自体を opt-in シグナル**として扱い、不在なら SKIP（diagnostic 対象外）とする（starter kit 判定を doctor に埋め込まない）。starter kit 本体ではスクリプトが存在するため通常 OK/ERROR で評価され、#733 T4 の doctor 側検出条件を満たす。

## 処理フロー概要

1. 依存前提（jq / git repo）を確認。欠落→診断不能（exit 2）。
2. 9 領域を順に診断（gh 不可用なら gh/pr を WARN/skip し継続）。
3. 各領域の severity を表示。
4. `ExitCodeResolver` で総合 exit code（2 > 1 > 0 優先）を導出して終了。

## 非機能要件（NFR）への対応

- **パフォーマンス**: shallow check（既存スクリプト wrap + 軽診断）。
- **セキュリティ**: 診断出力にトークン等の機密情報を含めない（マスク）。
- **スケーラビリティ**: 診断領域は段階追加可能な構造（alpha.8 で phase/trace 追加）。
- **可用性**: gh 不可用時 `[gh]`/`[pr]` WARN/skip、他領域継続。

## 技術選定

- **言語**: bash（`set -uo pipefail` / 既存 v3 スクリプト準拠 / pipefail は wrap exit code 取得を阻害しないよう留意）。
- **テスト**: 自己完結シェル + jq（`test-state-scripts.sh` 方式 / 一時 git repo fixture）。

## 契約テスト設計（test-doctor.sh）

計画「変更3」+ exit code 代表ケース + `[config]` 契約ケースを実装:

- 領域別: state 不在/破損 / 必須スクリプト不在 / git dirty・clean / gh 未認証 / PR あり・なし / parse-guard 違反・なし / 全 OK 正常系。
- **`[state]` schema-warn（指摘#2）**: 未知 schema_version（`state-validate.sh` が rc0 + `status:warn:unsupported-schema-version:*`）→ `[state]` **WARN**、総合 exit 0。**doctor は rc だけでなく stdout prefix（`status:valid` / `status:warn:*`）を見て severity を分岐する**契約をテストで固定（rc0 のみ判定して WARN を OK 誤表示する実装を検出）。
- **`[work-items]` 前提ゲート（指摘#3 / 確定契約・曖昧表現排除）**:
  - state なし → `[work-items]` **SKIP** / 総合 exit 0
  - cycle dir 不在 → `[cycle]` WARN / 総合 exit 0
  - work-items dir 不在（define 前） → `[work-items]` **WARN** / 総合 exit 0
  - work-items dir あり + 0 件 → `[work-items]` **WARN** / 総合 exit 0
  - work-items dir あり + 1 件以上 + validator rc0 → `[work-items]` **OK** / 総合 exit 0
  - work-items dir あり + 1 件以上 + validator rc1 → `[work-items]` **ERROR** / 総合 exit 1
  - validator rc2 → 総合 **exit 2**
  - （dir 不在・0件は validator に渡さず doctor 側ゲートで WARN にする。validator にそのまま渡して ERROR/exit1 にする実装を検出する。）
- 総合 exit: WARN-only→0 / ERROR→1 / 診断不能(jq・dasel・git)→2 / gh 未認証は exit 非影響。
- `[config]`: config 不在→ERROR/exit1 / 確定キー不在→WARN/exit0 / 取得成功→OK/exit0。
- 静的検査: `bash -n` + shellcheck。
- ネットワーク非依存（gh 依存ケースは PATH 操作 / stub で再現 / 実 gh を叩かない）。test-isolation cd-guard 遵守。

## SoT 反映設計

- `docs/v3/workflow.md §3.6`: チェック項目表に段階列（alpha.7: 8 領域+parse-guard / alpha.8: phase・trace）。`[parse-guard]` 行が未記載なら追記。
- `docs/v3-renewal-plan.md`: doctor チェック項目 + Phase 6 完了条件を段階化。
- Epic #736: Phase 6 完了条件を「alpha.7=doctor shallow / phase・trace=alpha.8 必須 follow-up」へ更新。
- alpha.8 follow-up（phase 導出 code 化・trace 整合）を新規 backlog Issue として起票しロードマップ紐付け。
- #733: alpha.4 完了証跡（T1/T2'/T4/T6 + #736 ロードマップ）+ doctor `[parse-guard]` が T4 doctor 側条件を満たす旨をコメントしてクローズ。

## 実装上の注意事項

- exit code 規約整合（警告付き完了を exit 2 にしない / ガイド照合）。
- `set -e` と wrap スクリプトの非 0 exit の取り扱い（`rc=0; cmd || rc=$?` 形式で exit code を捕捉し、doctor 自身が途中終了しないようにする）。
- doctor は state 非変更（`state-write.sh` を呼ばない）。
- Bash ツール経由コマンド置換禁止（#697）/ test-isolation cd-guard / コメント内 `rm -rf` 文字列回避。

## 不明点と質問（設計中に記録）

[Question] なし（計画レビュー Round 3 指摘0件 / 再利用スクリプト契約は codex 実読検証済み）
[Answer] -
