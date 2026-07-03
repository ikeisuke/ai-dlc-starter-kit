# Unit 003 実装計画: doctor v1 実装 + 段階スコープ SoT 反映

## 対象

- **Unit**: 003-doctor-v1
- **関連 Issue**: Relates to #736（Epic / Phase 6）/ Closes #733（alpha.4 で対応済み・本 Unit でクローズ）
- **depth_level**: standard / **automation_mode**: semi_auto / **review_mode**: required

## 背景・目的

v3 に診断コマンド `doctor` を shallow scope（8 領域 + parse-guard 検出）で実装する。**診断のみ・自動修正しない**。あわせて doctor の alpha.7/alpha.8 段階スコープを設計 SoT に明示反映し、解消済みの #733 をクローズする。SoT: `docs/v3/workflow.md §3.6` / `docs/v3-renewal-plan.md` Phase 6。

## 前提（調査で確定した訂正点）

- v3 に `guides/` は無い → exit code 規約は v2 `skills/aidlc/guides/exit-code-convention.md` を SoT 参照（v3 に複製を作らない）。
- v3 に `read-config.sh` は無い → `[config]` 診断は v2 `skills/aidlc/scripts/read-config.sh` を wrap。
- `bin/check-frontmatter-parse-guard.sh` は既存（alpha.4 / #733 T4） → `[parse-guard]` 領域はこれを呼ぶだけで成立。

## 実装方針

新規ロジックを最小化し既存スクリプト再利用を優先（renewal-plan の doctor 設計）。

### 変更1: `skills/aidlc-v3/scripts/doctor.sh`（新規）

8 領域 + parse-guard を診断し OK/WARN/ERROR を出力（自動修正・状態変更なし）。各領域の再利用スクリプトと判定:

| 領域 | 再利用 | OK / WARN / ERROR（指摘#1-#3 反映） |
|------|--------|-------------------|
| `[config]` | `skills/aidlc/scripts/read-config.sh` | **ファイル存在 + キー確認を分離**。`.aidlc/config.toml` 不在→ERROR。**alpha.7 の必須キーは確定済みキーに限定**（`rules.depth_level.level`）。キー取得 rc0→OK / キー不在 rc1→WARN。**dasel 未導入は doctor 依存不足（[config] ERROR ではなく診断不能系 / exit 2 と同列）**として扱う（no-dasel fallback はしない / 依存不足を明示） |
| `[state]` | `scripts/state-validate.sh` | **state.json 不在（No active cycle）→ WARN/INFO（exit 0 / `/aidlc-v3 define` 案内）**。`status:valid`→OK / `status:warn:*`→WARN / **破損 JSON・schema 不正（rc1）→ ERROR** / rc2→ERROR（診断不能系） |
| `[cycle]` | `scripts/state-read.sh current_cycle` + dir 存在 | state 不在→SKIP（No active cycle に従属）/ dir 存在→OK / 取得不能・dir 不在→WARN |
| `[work-items]` | `scripts/work-item-validate.sh <dir>` | **前提ゲート**: state 不在→**SKIP** / active cycle あり + work-items dir 不在→**WARN**（define 前）/ dir あり + rc0→OK / dir あり + rc1→**ERROR**(stderr 要約) / rc2→ERROR。**doctor 側で前提（state 存在・current_cycle・dir 存在）を判定してから validator を呼ぶ**（dir 不在/0件を validator rc1 で ERROR 誤判定しない） |
| `[git]` | native `git status --porcelain` 等 | clean→OK / dirty→WARN / repo 外→ERROR |
| `[gh]` | native `gh auth status` | 認証OK→OK / 未認証・gh 不在→**WARN/skip** |
| `[pr]` | native `gh pr list/view` | gh 不可→**WARN/skip**（[gh]従属）/ PR あり→OK(番号+draft) / 0件→OK(未作成情報) |
| `[scripts]` | `[[ -f ]]` 必須スクリプト存在（下記集合） | 全存在→OK / 欠落→ERROR |
| `[parse-guard]` | `bin/check-frontmatter-parse-guard.sh` | スクリプト不在→SKIP（opt-in シグナル / consumer 想定）/ rc0→OK / rc1→ERROR / rc2→ERROR |

**`[scripts]` 必須スクリプト集合（指摘#4 / 正本リスト）**: `state-read.sh` / `state-write.sh` / `state-validate.sh` / `state-init.sh` / `work-item-next.sh` / `work-item-validate.sh` / `work-item-status.sh` / `lib/frontmatter.sh`（いずれもスキルベース `scripts/` 相対 / 実在の core スクリプト）。**SKILL.md パス解決一覧（L118）も本集合に一致させる**（現状 `state-init.sh` / `lib/frontmatter.sh` が未列挙のため追記。doctor の required 集合を正本とし SKILL.md を同期）。

- **gh 不可用時**: `[gh]`/`[pr]` を WARN/skip し他 7 領域は継続（NFR 可用性）。
- **alpha.8 defer（実装しない）**: `[phase]`（フェーズ導出 code 化）/ `[trace]`（intent→work items→designs 整合チェック）。

### 変更2: `skills/aidlc-v3/steps/doctor.md`（新規）

doctor の出力仕様。`[phase]`・`[trace]` は **alpha.8 defer** と明記。診断のみ・自動修正しない旨を明記。

### 変更3: `skills/aidlc-v3/scripts/tests/test-doctor.sh`（新規 / 契約テスト）

既存ハーネス（`test-state-scripts.sh` 方式 / 自己完結 / jq 前提 / 一時 git repo + fixture / `mktemp -d` + trap cleanup / cd-guard 遵守）。最低ケース:

1. state.json 不在→No active cycle（`[state]` WARN/INFO + **総合 exit 0**）/ 2. state.json 破損→`[state]` ERROR + **exit 1** / 3. work item frontmatter 不正→`[work-items]` ERROR + exit 1 / 4. 必須スクリプト不在→`[scripts]` ERROR + exit 1 / 5. git dirty→WARN・clean→OK / 6. gh 未認証→`[gh]` WARN/skip + `[pr]` skip + 他継続（**exit 非 0 にしない**）/ 7. active PR あり→OK・なし→OK / 8. gh 不可時 pr→WARN/skip / 9. parse-guard 違反→`[parse-guard]` ERROR + exit 1・なし→OK / 10. 全領域 OK 正常系→exit 0 / 11. 静的検査 bash -n + shellcheck。

**総合 exit code 代表ケース（指摘#5 / 必須）**:

- **WARN-only（state 不在 + git dirty 等）→ exit 0**（警告付き完了 / state-validate の `status:warn:unsupported-schema-version` も WARN-only に含める）。
- **ERROR あり（state 破損 / work-items 不正 / 必須スクリプト不在 / parse-guard 違反）→ exit 1**。
- **doctor 自身が診断不能（jq 欠落、または dasel 欠落で `[config]` 依存不足、git repo 外）→ exit 2**（PATH 操作 / stub で再現 / 実環境を壊さない）。
- gh 未認証は WARN/skip で exit に影響しないことを明示検証。

**`[config]` 契約ケース（Round 2 指摘 / 必須・明示）**:

- `.aidlc/config.toml` **不在** → `[config]` ERROR、総合 **exit 1**。
- config.toml あり + 確定キー `rules.depth_level.level` **不在（rc1）** → `[config]` WARN、総合 **exit 0**。
- config.toml あり + キー取得成功（rc0） → `[config]` OK、総合 exit 0。
- （上記により `read-config.sh` の rc2=依存不足/exit2 と rc1=キー不在/WARN の混同を回帰検出する。）

### 変更4: `skills/aidlc-v3/SKILL.md`（更新）

doctor を「予約」→実装済み: description（L9）/ 位置づけ注記（L17-22）/ 補助コマンド表（L55）/ パス解決 `scripts/` 列挙に `doctor.sh`・`steps/` 列挙に `doctor.md` 追加（L118/L120）。あわせて **`[scripts]` 必須集合との同期**として `scripts/` 列挙に `state-init.sh` / `lib/frontmatter.sh`（現状未列挙）を追記し、doctor の required 集合と一致させる。

### 変更5: SoT 段階スコープ反映

- `docs/v3/workflow.md §3.6`（L156-192）: チェック項目表に段階注記（8 領域+parse-guard=alpha.7 / `[phase]`・`[trace]`=alpha.8）。`[parse-guard]` 行が未記載なら追記。
- `docs/v3-renewal-plan.md`: doctor チェック項目（L905-916）+ Phase 6 完了条件（L1080-1085）に段階注記。`[parse-guard]` 追記。
- Epic #736: Phase 6 完了条件を「alpha.7=doctor shallow（8 領域+parse-guard）/ phase・trace=alpha.8 必須 follow-up」へ更新（`gh issue edit 736` またはコメント）。

### 変更6: alpha.8 必須 follow-up の切り出し

phase 導出 code 化・trace 整合チェックを **新規 backlog Issue** として起票し、Epic #736 ロードマップに紐付け。

### 変更7: #733 クローズ

alpha.4 完了証跡（T1: `lib/frontmatter.sh` / T2': `test-frontmatter-parser.sh` / T4: `bin/check-frontmatter-parse-guard.sh` / T6: `test-cycle-resolution.sh` + #736 ロードマップ alpha.4 行）をコメントに付して `gh issue close 733`。**加えて（指摘#6）**: #733 T4 の「CI または doctor で機械検出」条件について、本 Unit で doctor の `[parse-guard]` 領域が `bin/check-frontmatter-parse-guard.sh` を呼ぶため **doctor 側条件も満たす**旨をコメントに明記する。

## exit code 設計（v2 exit-code-convention 準拠）

- OK/WARN のみ → **exit 0**（警告付き完了も完了 / 規約 L8・L21）。**state.json 不在（No active cycle）は WARN/INFO で exit 0**（未開始リポジトリを失敗扱いにしない / `status` SoT の `/aidlc-v3 define` 通常案内分岐と整合）。
- ERROR 領域あり（**state 破損・schema 不正** / 必須スクリプト不在 / parse-guard 違反 / work-items 不正（dir あり時）等）→ **exit 1**（前提条件不成立）。
- doctor 自身が診断不能（jq 欠落 / **dasel 欠落で `[config]` 依存不足** / git repo 外）→ **exit 2**。
- gh 不可用は WARN/skip（exit に影響させない）。

## 完了条件チェックリスト

ローカル成果物（実装フェーズで完了）:

- [x] `doctor.sh` 新規（8 領域 + parse-guard / 診断のみ・自動修正なし / gh 不可用時 WARN/skip 他継続）
- [x] `doctor.md` 新規（出力仕様 / `[phase]`・`[trace]` は alpha.8 defer 明記）
- [x] `test-doctor.sh` 新規（最低ケース全件 / 一時 git repo fixture / PASS 80）
- [x] `SKILL.md` の doctor を予約→実装済みに更新
- [x] SoT 段階スコープ反映（workflow.md §3.6 / renewal-plan）
- [x] exit code 規約整合（ガイド照合 / 診断結果と終了コードの設計）

GitHub 完了処理（完了処理フェーズで実施 / 完了）:

- [x] SoT 段階スコープ反映（Epic #736 Phase 6 完了条件の更新 / コメントで段階反映）
- [x] alpha.8 必須 follow-up を backlog Issue として切り出し（#741）
- [x] #733 を alpha.4 完了証跡 + doctor [parse-guard] T4 充足コメント付きでクローズ

## スコープ外（Unit 境界）

- `[phase]` 導出 code 化・`[trace]` 整合チェックの**実装**（alpha.8 defer / SoT への defer 反映のみ）
- doctor の自動修正・状態変更（診断のみ）
- reflect / status / #735（別 Unit）

## リスク・考慮事項

- exit code 規約（v2 ガイド）と整合させる（警告付き完了を exit 2 にしない / v1.27.3 の教訓）。
- 既存スクリプト再利用の契約（exit code 写像）を正確に。
- 契約テストはネットワーク非依存（gh 依存ケースは PATH 操作 / stub で再現 / 実 gh を叩かない）。
- test-isolation cd-guard 規約遵守（rm -rf 前に安全 dir へ cd / コメントに `rm -rf` 文字列を書かない）。
- Bash ツール経由コマンド置換禁止（#697）遵守。
