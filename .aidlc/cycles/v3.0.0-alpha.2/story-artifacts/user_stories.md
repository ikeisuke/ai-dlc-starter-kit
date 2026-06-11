# ユーザーストーリー

## Epic: aidlc-v3 skeleton 構築（Phase 2）

alpha.1 で `docs/v3/*.md` に確定した v3 設計を、v2 と共存する `skills/aidlc-v3/` の最初の骨組みとして具現化する。skeleton は「読める手順 + 検証可能な state 操作 + 確定テンプレート」までを範囲とし、define / develop / release フローの実行実装は Phase 3 以降に委ねる。

---

### ストーリー 1: state.json 操作スクリプト基盤を確立する
**優先順位**: Must-have

As a AI-DLC starter kit の開発者
I want to state.json を read / write / validate する 3 本のスクリプトを `skills/aidlc-v3/scripts/` に確立する
So that Phase 3 以降の define / status フロー実装が、確定スキーマに基づく atomic な state 操作 API を前提に組み立てられる

**受け入れ基準**:
- [ ] `skills/aidlc-v3/scripts/state-read.sh` が state.json から指定フィールド（`schema_version` / `current_cycle` / `define_completed` / `release.*` / `updated_at`）を抽出できる
- [ ] `skills/aidlc-v3/scripts/state-write.sh` が state.json を temp file + mv で atomic に書き込む（直接編集を回避する設計）。本サイクルの範囲は schema validation + 許可フィールド更新に限定し、許可/禁止状態遷移ルールの具体化は Phase 3 へ defer する
- [ ] `skills/aidlc-v3/scripts/state-validate.sh` が必須フィールド（`schema_version`: string / `current_cycle`: string / `define_completed`: boolean / `release`: object / `updated_at`: ISO 8601 string）の存在・型を検証し、有効な state.json には exit 0、欠落・型不正・JSON 破損には非 0 を返す
- [ ] `state-validate.sh` が `release` object 内の必須サブフィールド `release.pr_number`（integer or null）/ `release.ready`（boolean）/ `release.merge_approved`（boolean）の存在・型も検証する（`docs/v3/data-model.md` §3.2 準拠。欠落・型不正で非 0）
- [ ] 3 本とも `bash -n` を通過し、shellcheck（利用可能時）で重大警告がない
- [ ] schema は `docs/v3/data-model.md` §3 の確定スキーマに準拠している

**技術的考慮事項**:
state.json の schema 正本は `docs/v3/data-model.md` §3。`updated_at` は必須。状態遷移ルールの詳細化は Phase 3（flow 実装）で行う。

---

### ストーリー 2: v3 成果物テンプレートを確定する
**優先順位**: Must-have

As a AI-DLC starter kit の開発者
I want to intent / work-item / journal の 3 テンプレートを `skills/aidlc-v3/templates/` に確定する
So that Phase 3 の define フロー実装が、確定済みテンプレートを参照して成果物を生成できる

**受け入れ基準**:
- [ ] `skills/aidlc-v3/templates/intent.md` が v3 の Intent 構成（目的 / スコープ / 受け入れ基準等）を持つ
- [ ] `skills/aidlc-v3/templates/work-item.md` が `docs/v3/data-model.md` §4 準拠の frontmatter（必須キー id/status/size/risk/assigned/dependencies + 各 enum）と本文必須 6 セクション（`Goal`, `Scope`, `Acceptance Criteria`, `Traceability`, `Size / Risk`（`Size / Risk` で 1 見出し）, `Dependencies`）を持つ
- [ ] `skills/aidlc-v3/templates/journal.md` が `docs/v3/data-model.md` の追記型 journal 形式に準拠している
- [ ] 各テンプレートが markdownlint を通過する

**技術的考慮事項**:
work item frontmatter / journal の正本は `docs/v3/data-model.md`。enum 値（status / size / risk）は SoT と一致させる。

---

### ストーリー 3: aidlc-v3 skill の骨組みを作る
**優先順位**: Must-have

As a AI-DLC starter kit の開発者
I want to `skills/aidlc-v3/SKILL.md`（ルーティング）と `steps/define.md` / `steps/status.md`（手順・出力仕様）を作る
So that v3 の define 手順と status 出力仕様が読める形で固定され、Phase 3 の実装インプットが明確になる

**受け入れ基準**:
- [ ] `skills/aidlc-v3/SKILL.md` に define / develop / release / reflect / status / doctor + 連続実行ラッパ `express` + 旧名エイリアス（inception / construction / operations / retrospective）+ 引数なし実行のフェーズ導出ルーティングが記述されている（`build` / `implement` はエイリアスにしない）
- [ ] `SKILL.md` に `express` が単一 work item サイクル専用の連続実行ラッパ（define + develop + release）であり、複数 work item / risky の場合は個別実行へ案内する旨が記述されている（`docs/v3/workflow.md` §4）
- [ ] `skills/aidlc-v3/steps/define.md` に define フローの Step 1-4（環境チェック / Intent 定義 / Work Item 分割 / 初期化）が**読める手順**として記述されている（`docs/v3/workflow.md` §3.1 準拠）
- [ ] `skills/aidlc-v3/steps/status.md` に status の出力仕様（フェーズ導出ロジック + 出力例）が記述され、**complete 判定は `release.merge_approved` と PR の merged 実態の両方を参照**し、PR 実態未確認時は complete としない旨を含む（`docs/v3/data-model.md` §5）
- [ ] define.md がテンプレート（ストーリー 2）を、status.md が state-read（ストーリー 1）を正しいパスで参照している

**技術的考慮事項**:
コマンド名は確定 RFC（DG-1）準拠で `develop`。フェーズ導出ロジックの正本は `docs/v3/data-model.md` §5 であり、SKILL.md / status.md はその導出結果を参照する（再定義しない）。

---

## 共通受け入れ基準（全ストーリー）

- [ ] **v2 非影響**: `skills/aidlc/`（v2）配下に一切の変更がない（`git diff` で確認）
- [ ] 成果物が `skills/aidlc-v3/` および `.aidlc/cycles/` 配下に限定され、define/develop/release フローの実行実装を含んでいない
- [ ] 用語・コマンド名・schema が確定 RFC（`docs/v3/*.md`）と一致している
- [ ] markdownlint を通過する
