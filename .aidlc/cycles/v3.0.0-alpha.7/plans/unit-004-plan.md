# Unit 004 実装計画: status 出力拡充

## 対象

- **Unit**: 004-status-enrichment
- **関連 Issue**: Relates to #736（Epic / Phase 6）
- **depth_level**: standard / **automation_mode**: semi_auto / **review_mode**: required

## 背景・目的

`/aidlc-v3 status` の出力を `docs/v3/workflow.md §3.5` の出力例に揃え、残作業・次の推奨コマンド・導出根拠を含む現在地表示に拡充する。現状 `skills/aidlc-v3/steps/status.md` は出力フォーマット自体は §3.5 と一致しているが、(1) 位置づけが「v3.0.0-alpha.2 / Phase 2 skeleton / 実行実装は Phase 3 以降」と stale、(2) 各フィールドの導出手順が未記載、(3) 出力整合の検証が無い。

## 前提（調査で確定）

- status は **スクリプトを持たず**（`status.sh` 不在）、AI エージェントが `state-read.sh` + work item frontmatter を読んで出力を構成する手順ベース。
- 出力フォーマット（Cycle / Phase / Current work item / Completed / Blocked / Remaining / Suggested command）と No active cycle 案内は現 status.md に既存（§3.5 と一致）。
- フェーズ導出の正本は `docs/v3/data-model.md §5`（status は導出結果の表示のみ・再定義しない）。

## 実装方針

既存 v3 ステップ（release.md / reflect.md）の記法に揃え、status.md を skeleton → 実行手順に拡充する。

### 変更1: `skills/aidlc-v3/steps/status.md` 拡充

- **位置づけ更新**: 「v3.0.0-alpha.2 / Phase 2 skeleton / 出力生成の実行実装は Phase 3 以降」を **実装済み（v3.0.0-alpha.7 / Phase 6）**に更新。status は読み取り専用・状態変更しない旨を明記（既存）。
- **Step 0: 前提確認（指摘#4 / 不在・読取失敗・schema 不正を分離）**:
  1. **`.aidlc/state.json` の存在を先に確認**。**不在のみ** → `No active cycle found.` + `Suggested command: /aidlc-v3 define` を出力して終了。
  2. state.json 存在 → **`scripts/state-validate.sh` で schema 検証**（Round 2 指摘）。**stdout で分岐し、後続へ進むのは `status:valid` のみ**:
     - `status:warn:unsupported-schema-version:*`（未知 schema / `data-model.md §6` の復帰不可 WARN）→ **No active cycle にせず・active cycle status も構成せず**、`state read error`（未対応 schema / migration・`Suggested command: /aidlc-v3 doctor` 推奨）の診断案内を出力（Round 3 指摘 / 未知構造のまま status を組まない）。
     - rc1（破損 / schema 不正）/ rc2（読取不能）→ `state read error`（`Suggested command: /aidlc-v3 doctor`）の診断案内を出力。
     - `status:valid` → 次へ。`state-read.sh` は schema 妥当性を検証しない（型不正でもキー存在で exit 0 になり得る）ため、schema 検証を `state-validate.sh` に委譲する。
  3. `status:valid` 確認後に `state-read.sh current_cycle` を実行。**`current_cycle` が非空 string** かつ **doctor と同等のパス安全検証**（`..` を含まない、かつ `^[A-Za-z0-9][A-Za-z0-9._-]*$` に一致 / Round 4 指摘 / doctor.sh `diagnose_cycle` と同基準）を満たすことを手順側で確認し、成功 → その cycle で以降を構成。`current_cycle` が空 / 取得失敗 / 不正識別子（パストラバーサル等）→ **active cycle status を構成せず** `state read error` 診断案内（`/aidlc-v3 doctor`）に倒す（`.aidlc/cycles/<cycle>` の境界外参照を防ぐ）。
  - 破損 state・schema 不正・current_cycle 欠落を **define 案内に潰さない**（No active cycle は state.json 不在のみ）。
- **各出力フィールドの導出手順を明記**（active cycle 時）:
  - `Cycle`: `state-read.sh current_cycle`。
  - `Phase`: `data-model.md §5` の導出規則に従い導出（**導出規則は再定義せず参照**）。導出根拠（例: `define_completed=true, 2/4 items remaining`）を併記。
  - `Current work item` / `Completed` / `Blocked` / `Remaining`: work item を列挙し、**status は `work-item-status.sh --read` 経由**、**size / risk は `lib/frontmatter.sh` の公開関数経由**（指摘#2: `fm_extract_block <file>` で frontmatter ブロック抽出 → `fm_scalar "$fm" size '[A-Za-z_]'` / `fm_scalar "$fm" risk '[A-Za-z_]'`。専用 `fm_size`/`fm_risk` は実在しないため使わない）で読む（**frontmatter 生パース禁止** / RFC P4）。enum 妥当性（`tiny|normal|risky` / `low|medium|high`）は表示前に手順側で検証する。Completed は done / withdrawn の内訳、Blocked は blocked、Remaining は未完了を表示。
  - `Suggested command`: 導出フェーズに対応する次コマンド（develop / release / reflect 等）。
- **出力フォーマットの正本一致と launch prefix（指摘#1 / 重要な判断）**:
  - **フィールド構造（名前・順序・`No active cycle found.` 文言）は `workflow.md §3.5` の出力例を正本として一致**させる。
  - **launch prefix は `/aidlc-v3` を用いる**（`/aidlc` ではない）。根拠: `SKILL.md`「コマンド表記について」が「本 skeleton の手順・出力例は `/aidlc-v3` 表記を用いる（現状の v2 共存を反映 / 最終表面 `/aidlc` への切替は Phase 7）」と規定し、既存 skeleton step（`define.md` / `develop.md` / `release.md` / `reflect.md` / `doctor.md`）も全て `/aidlc-v3` を使用。status.md だけ `/aidlc` にすると skeleton 内不整合になるため、prefix は `/aidlc-v3` で統一する。§3.5（end-state 表記 `/aidlc`）との prefix 差は **documented な skeleton↔end-state 差**であり Phase 7 で一括統一する。
- **境界明記**: フェーズ導出規則は再定義しない（SoT: data-model §5）。doctor の `[phase]` 導出 code 化は対象外（alpha.8 / #741）。status は状態を変更しない（`state-write.sh` を呼ばない）。

### 変更2: `skills/aidlc-v3/scripts/tests/test-status.sh` 新規（出力整合検証）

`test-release-flow.sh` / `test-reflect-flow.sh` と同方式（自己完結 / jq 前提 / ネットワーク非依存 / 静的構造検証 / pass-fail）。検証項目:

1. `bash -n` + shellcheck（テスト自身）。
2. 成果物存在（`steps/status.md`）。
3. status.md に §3.5 全 7 フィールド（`Cycle` / `Phase` / `Current work item` / `Completed` / `Blocked` / `Remaining` / `Suggested command`）が**この順序**で記載。
4. No active cycle 案内（`No active cycle found.` + `Suggested command: /aidlc-v3 define`）が **exact string** で記載。
5. **§3.5 整合の厳密検証（指摘#3）**: `workflow.md §3.5` の active cycle 出力例ブロックと No active cycle 出力例ブロックを抽出し、`status.md` 側の出力例ブロックと **フィールド名・順序・`No active cycle found.` を exact match で比較**する。prefix は §3.5 が `/aidlc`、status.md が `/aidlc-v3` という documented 差を許容し、**フィールド構造の一致**を検証する（prefix を除いた構造一致 / status.md 側は `/aidlc-v3` prefix で統一されていることを別途検証）。
6. **launch prefix 整合（指摘#1）**: status.md の `Suggested command` が `/aidlc-v3`（skeleton 統一 prefix）で記載され、`/aidlc ` 単独 prefix が混在しないこと。
7. **frontmatter 生パース禁止の委譲**（`work-item-status.sh` / `lib/frontmatter.sh`（`fm_extract_block` / `fm_scalar`）参照、status.md に直接 grep/sed/awk の frontmatter パースがない）。
8. **状態非変更**（status.md にコマンド位置の `state-write.sh` 呼び出しがない）。
9. **Step 0 の分離（指摘#4）**: state.json 不在→No active cycle / 存在+読取失敗→診断案内（doctor 推奨）が記載。
10. **フェーズ導出 SoT 参照**（`data-model.md` §5 を参照し再定義しない旨）。
11. **stale 注記なし**（「skeleton」「実行実装は Phase 3」等の stale 表現が残らない）。

## 完了条件チェックリスト

- [x] `status.md` を active cycle 時の全フィールド出力仕様に拡充（位置づけ skeleton→実装済み / 各フィールド導出手順 / §3.5 整合）
- [x] state.json 不在時の `No active cycle found.` + `Suggested command: /aidlc-v3 define` を明記（存在+読取失敗は診断案内に分離）
- [x] 出力整合の検証（`test-status.sh` / 35 件）を追加
- [x] フェーズ導出規則を再定義しない（SoT: data-model §5）
- [x] frontmatter 生パース禁止（status は `work-item-status.sh` / `lib/frontmatter.sh` 委譲）
- [x] status は状態を変更しない（読み取り専用）

## スコープ外（Unit 境界）

- フェーズ導出規則そのものの再定義（SoT は data-model §5）
- doctor の `[phase]` 導出 code 化（alpha.8 / #741 / Unit 003 で defer 反映済み）
- status の状態変更（読み取り専用）

## リスク・考慮事項

- `workflow.md §3.5` の出力例を正本として一致させる（フィールド名・Suggested command 表記）。
- frontmatter 生パース禁止（`lib/frontmatter.sh` / `work-item-status.sh` の公開関数を使用）。size/risk 読取の委譲先関数を設計で確定。
- SKILL.md の status 記述（`steps/status.md`（実在 / Unit 001 で実装））との整合確認（拡充により実装済みの実態に合わせる / 必要なら注記更新）。
- Bash ツール経由コマンド置換禁止（#697）/ test-isolation cd-guard 遵守。
