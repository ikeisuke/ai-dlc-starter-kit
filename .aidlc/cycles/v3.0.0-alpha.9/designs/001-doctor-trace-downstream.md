# Design 001: doctor `[trace]` 後段検証拡充

- trace: work item 001-doctor-trace-downstream
- matrix_case: normal_standard
- design_mode: simple

## Goal

`doctor.sh` の `diagnose_trace`（現状は design 要否 + `designs/<id>-<slug>.md` 存在確認まで）に、trace chain 後段の 3 検証（intent 存在 / Traceability 健全性 / journal 整合）を追加し、`[trace]` を read-only のまま深化させる。領域数は 11 のまま（領域追加ではなく `[trace]` 内の検証拡充）。

## Context

- 既存 `diagnose_trace`（`doctor.sh:453-533`）は、STATE_PRESENT / STATE_DERIVABLE / CYCLE_DIR / WORK_ITEMS_INVALID の前提ゲート通過後、work item を走査して §8 size×depth_level で design 要否を判定し、design 必須 work item の `designs/<basename>` 存在を確認して単一の `report trace WARN|OK` を出す。
- 共有パーサ境界: frontmatter は `fm_extract_block` / `fm_scalar`（`lib/frontmatter.sh`）、本文は `fm_extract_body` を再利用する。**個別 consumer での raw grep/sed/awk による frontmatter/本文構造解釈は禁止**（`bin/check-frontmatter-parse-guard.sh` が doctor.sh を走査）。本文の Traceability 解析は bash 組込み（`while read` / `case` / パラメータ展開）+ `cat` のみで実装し、parse-guard のトークン検出（grep/sed/awk/jq）に一切触れない。
- 後段検証の対象成果物（intent.md / journal.md）は define/develop の deliverable であり、その欠落は trace chain の破断を意味する。

## Design

### 検証の追加（すべて WARN 止まり / exit 0 維持 / read-only）

既存ゲート（frontmatter 不在 / state なし / STATE_DERIVABLE / CYCLE_DIR / WORK_ITEMS_INVALID / work-items 不在・0 件）は変更しない。work item 走査ループを拡張し、走査後に 2 検証を追加する。

1. **Traceability 健全性検証**（work item 単位 / ループ内）:
   - `body="$(fm_extract_body "$f")"` で本文を取得。
   - ヘルパー `_trace_traceability_healthy <body>`: `## Traceability` セクション内の `Intent refs:` / `Acceptance refs:` / `Verification:` の 3 フィールドが、いずれも「空白除去後に非空」かつ「`{{` プレースホルダを含まない」なら健全（return 0）。1 つでも欠ければ不備（return 1）。
   - 不備 work item の basename を `trace_bad_list` に集約。

2. **done 集約**（work item 単位 / ループ内 / journal 整合用）:
   - `st="$(fm_scalar "$fm" status)"` で status を読取（frontmatter 再パースなし）。`done` の basename を `done_list` に集約。

3. **intent.md 存在検証**（cycle 単位 / ループ後）:
   - `[[ ! -f "$CYCLE_DIR/intent.md" ]]` → `intent_missing=1`。

4. **journal 整合検証**（cycle 単位 / ループ後）:
   - `[[ ! -f "$CYCLE_DIR/journal.md" ]]` → `journal_missing=1`。
   - 存在時は `journal_txt="$(cat "$CYCLE_DIR/journal.md")"` を取得し、`done_list` の各 basename（`.md` 除去）が journal 本文に含まれるか bash グロブ照合（`[[ "$journal_txt" == *"$name"* ]]`）。未記録の basename を `journal_uncovered_list` に集約。

### 結果集約（単一 report）

既存の design 判定（`missing_list` / `invalid_list` / `warn_depth`）に上記後段結果を加え、**いずれかが非空なら単一の `report trace WARN`**、すべて充足なら `report trace OK` を出す（既存同様、行は 1 本）。detail は次元別トークンを連結:

```
trace 整合 WARN: design 欠落[...] risky×minimal[...] depth_level enum 外→standard \
                 intent.md 欠落 Traceability 不備[...] journal.md 欠落 journal 未記録[...]
```

`depth_level enum 外→standard` トークンは既存テスト（`assert_area_detail trace "enum 外"`）互換のため文言を保持する。

### 出力契約・exit code

- `report trace <severity> <detail>`（`printf '%-14s%-6s%s'`）を厳守。severity は OK / WARN のみ（後段検証は ERROR / 診断不能を立てない）。
- 総合 exit code 集約（`HAS_UNDIAGNOSABLE` > `HAS_ERROR` > 0）に影響を与えない（WARN は exit 0）。

### コメント更新

- ヘッダ [trace] wrap 契約コメント（`doctor.sh:36-38`）と `diagnose_trace` 関数コメント（`445-451`）を「design 要否 + 後段（intent/Traceability/journal）整合」に更新。領域数「11」は不変。

### テスト（test-doctor.sh）

- `make_valid_work_item` の `## Traceability` を健全内容（`Intent refs:` / `Acceptance refs:` / `Verification:` 非空・プレースホルダなし）に更新（work-item-validate は section 存在のみ検証のため valid 維持）。
- `seed_cycle_meta <cycle_dir> [done_basenames...]` ヘルパーを追加し、intent.md と（done を記録した）journal.md を生成。
- 既存「trace OK」/「全領域 OK」フィクスチャに `seed_cycle_meta` を適用（後段健全 → OK 維持）。
- 新規ケース: intent.md 欠落 → WARN / Traceability プレースホルダ残存 → WARN / Traceability フィールド空 → WARN / journal.md 欠落 → WARN / done work item が journal 未記録 → WARN / 後段すべて健全 → OK。いずれも exit 0。
