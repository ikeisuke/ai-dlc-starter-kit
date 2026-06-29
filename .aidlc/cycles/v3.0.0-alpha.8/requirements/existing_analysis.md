# 既存コードベース分析

本サイクル（v3.0.0-alpha.8 / #741: doctor に `[phase]` / `[trace]` 追加）に関係する範囲に絞った brownfield 分析。

## ディレクトリ構造・ファイル構成

doctor 関連の主要構成（深さ 2-3）:

- `skills/aidlc-v3/scripts/doctor.sh` — 診断ロジック本体（9 領域 / read-only / 自動修正なし）
- `skills/aidlc-v3/scripts/tests/test-doctor.sh` — doctor 契約テスト（自己完結ハーネス / jq 前提 / ネットワーク非依存）
- `skills/aidlc-v3/scripts/` — doctor が wrap する依存スクリプト群（`state-read.sh` / `state-validate.sh` / `work-item-status.sh` / `work-item-validate.sh` / `lib/frontmatter.sh`）
- `skills/aidlc-v3/steps/doctor.md` — doctor の出力仕様（実装は doctor.sh）
- `skills/aidlc-v3/templates/work-item.md` / `templates/design.md` — work item / design の構造（trace 整合の根拠）
- `skills/aidlc-v3/steps/develop.md` — design ファイル名規約（`develop.md:139-147,202`）
- `docs/v3/data-model.md` — データモデル正本（§3 state / §4 work item / §5 phase 導出 / §6 破損扱い / §8 size×depth / §9 trace chain）
- `docs/v3/workflow.md` — ワークフロー正本（§3.6 doctor 段階スコープ / §7.3 trace chain）
- `docs/v3-renewal-plan.md` — v3 リニューアル設計 SoT（Phase 6 / doctor チェック項目）

## アーキテクチャ・パターン

- **diagnostic-only / read-only パターン**: doctor.sh は state.json / work item / config を一切変更しない（根拠: `doctor.sh:11-13`）。全関数は依存スクリプトを read のみで wrap。
- **severity 写像パターン**: 各診断領域は依存スクリプトの exit code（および stdout prefix）を OK/WARN/ERROR/SKIP に写像するのみで新規パースを持たない。領域別 wrap 契約はヘッダコメント `doctor.sh:25-36` に一覧化。
- **stdout prefix 判定**: `[state]` は rc だけでなく `state-validate.sh` の stdout prefix（`status:valid` / `status:warn:*`）で分岐（`doctor.sh:118-150`）。
- **前提ゲートパターン**: `[work-items]` は doctor 側で state・cycle・dir・件数を前提ゲートしてから validator を呼ぶ（`doctor.sh:192-235`）。
- **新規パース禁止規約**: frontmatter は共有パーサ `lib/frontmatter.sh`（`fm_scalar` / `fm_deps` 等）経由で取得し、領域関数が独自パースを書かない（`lib/frontmatter.sh:24-30`）。
- **出力フォーマット**: `report()`（`doctor.sh:69-77`）が `printf '%-14s%-6s%s\n' "[$name]" "$severity" "$detail"` で固定幅出力。サマリ行はなく、総合 exit code（`HAS_UNDIAGNOSABLE` > `HAS_ERROR` > OK、`doctor.sh:327-334`）で集約。
- **契約テストパターン**: `test-doctor.sh` は fixture（実 v3 スクリプト + 契約 stub）を構築し、`assert_area <area> <severity>` / `assert_rc` でアサート。冒頭に `bash -n` / shellcheck 静的検査。

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash（POSIX 寄り / `set -euo pipefail`） | `skills/aidlc-v3/scripts/doctor.sh` |
| 実行依存 | `jq`（テスト・JSON 抽出）、`git` / `gh`（診断対象）、`dasel`（config 読取） | `test-doctor.sh`、`doctor.sh` |
| テスト | 自己完結 bash ハーネス（fixture + stub / ネットワーク非依存） | `skills/aidlc-v3/scripts/tests/test-doctor.sh` |
| 静的検査 | `bash -n` / shellcheck | `test-doctor.sh` 冒頭 |

## 依存関係

- **doctor.sh → 依存スクリプト**（wrap 対象、read-only 再利用）:
  - `state-read.sh <field>` — state.json 単一フィールド取得（許容キー: `schema_version|current_cycle|define_completed|release.pr_number|release.ready|release.merge_approved|updated_at`、`state-read.sh:43-58`）。`[phase]` 導出に `define_completed` / `release.merge_approved` / `release.pr_number` が利用可。
  - `state-validate.sh` — state.json 検証（`status:valid` / `status:warn:*`）。
  - `work-item-status.sh --read <path>` — work item frontmatter status を堅牢取得（`[phase]` の status 集計に利用可）。
  - `work-item-validate.sh <dir>` — 全 work item の必須キー/enum/dependencies 実在を検証（`[trace]` の dependencies 整合の一部を既にカバー、`work-item-validate.sh:22,180-186`）。
  - `lib/frontmatter.sh` — 共有 frontmatter パーサ（`fm_scalar <fm> size` で size 抽出 → `[trace]` の design 必須判定に利用可）。
  - `read-config.sh rules.depth_level.level` — depth_level 取得（size×depth マトリクスで design 要否判定）。
- **方向の一貫性**: doctor → 依存スクリプト の単方向。循環依存なし。

## 特記事項

### phase 導出の正本（data-model.md §5）

first-match / 上から評価（`data-model.md:209-216`）:

1. `release.merge_approved: true` かつ PR が merged 状態 → **complete**
2. `define_completed: false`（または state.json 不在）→ **define**
3. `define_completed: true` かつ work item に `done`/`withdrawn` 以外がある → **develop**
4. `define_completed: true` かつ全 work item が `done`/`withdrawn` → **release 可能**

- `complete` は承認記録（`merge_approved`）と PR 実態（実際に merged）の両方が必要。
- 導出根拠の併記フォーマット参考: `workflow.md:198` の `[phase] develop (derived: define_completed=true, 2 items remaining)`。

### trace chain の定義（data-model.md §9 / workflow.md §7.3）

- chain: `intent.md` → `work-items/*.md`（frontmatter + Traceability）→ `designs/*.md`（normal/risky のみ）→ `reviews/*.md` → `journal.md` → `release.md` → `reflect.md`。
- **design 必須判定**（§8 size×depth マトリクス / 唯一の正本 `data-model.md:292-296`）:
  - `normal × standard` → design 必須
  - `normal × minimal` → design 不要（`data-model.md:311`）
  - `risky` → 常に design 必須
- **design ファイル名規約**（`develop.md:139-147,202`）: work item `work-items/<id>-<slug>.md` に対し design は `designs/<id>-<slug>.md`（同一ファイル名）。`[trace]` の design 存在チェックはこの規約に基づく。
- **dependencies 実在検証**: `work-item-validate.sh` が既に担う（§6 `data-model.md:247`）。`[trace]` はこれと役割分担し、cross-artifact trace（design 存在）に焦点を当てる必要あり。

### severity 設計（既存ドキュメントとの整合）

- `[phase]`: 導出結果の表示（OK 相当 + derived 根拠併記、`workflow.md:198`）。
- `[trace]`: 参照欠落を WARN（`workflow.md:199` / `data-model.md §6`）。

### SoT 注記の更新対象（alpha.8 defer → 実装済み）

- `skills/aidlc-v3/steps/doctor.md` 末尾「## alpha.8 defer」セクション、診断領域テーブル（9→11 領域）、出力例。
- `docs/v3/workflow.md` §3.6（`workflow.md:160-161` / テーブル `:176-177` / 出力例 `:195-200` / コマンド体系 `:31`）。
- `docs/v3-renewal-plan.md`（doctor セクション `:905` / `:917-918` / `:940-944` / Phase 6 完了条件 `:1092`）。

### 用語の揺れ（注意）

doctor.sh ヘッダ（`doctor.sh:3`）は「9 領域」と明記（内訳: config/state/cycle/work-items/git/gh/pr/scripts/parse-guard）。一方ドキュメントでは「8 領域 + parse-guard」という表現も併存。#741 で「11 領域」へ更新する際は、この内訳カウントの一貫性も揃える。
