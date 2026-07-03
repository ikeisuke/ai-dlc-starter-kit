# ユーザーストーリー

## Epic: v3 リニューアル Phase 6 — reflect + doctor + status 拡充（v3 単独フルサイクル完走）

### ストーリー 1: reflect で振り返り→改善 Issue 化
**優先順位**: Must-have

As a AI-DLC を使う開発者
I want to `/aidlc-v3 reflect` でサイクルを振り返り、必要な改善だけを Issue 化したい
So that 振り返りが反省文で終わらず、次の define で参照される具体的な行動（Issue / lesson）に変わる

**受け入れ基準**:
- [ ] `/aidlc-v3 reflect` 実行で `steps/reflect.md` の Step 1（材料収集: journal.md / release.md / work item の withdrawn・blocked 理由）→ Step 2（KPT 提案→人間編集）→ Step 3（Try の Issue 化を人間に確認・必要分のみ作成 + `reflect.md` 記録）→ Step 4（journal.md に reflect 完了を追記）が順に実行される
- [ ] reflect は明示の承認ゲートを持たず、Step 2 で人間が KPT を編集、Step 3 で Issue 化を人間に確認する
- [ ] `templates/reflect.md` が存在し、reflect 成果物の章立て（Keep / Problem / Try / Issue リンク）を提供する
- [ ] core から外す項目（upstream mirror / cap 管理 / dialog token / aggregate retrospective issue）が手順・ドキュメントで「実装しない」と明示される
- [ ] `SKILL.md` の `reflect` が「予約」から実装済み（ルーティング先 `steps/reflect.md`）に更新され、`retrospective` エイリアス・express ラッパと整合する
- [ ] reflect 手順のドライ検証で、Step 1–4 の入出力・`reflect.md` 生成・`journal.md` 追記に加え、「Try の Issue 化を承認しない場合は Issue を作らない」「一部のみ承認時は必要分のみ作る」ことが確認される

**技術的考慮事項**:
- `docs/v3/workflow.md §3.4` / `docs/v3/data-model.md §7（journal）・§10（成果物）` が SoT。
- frontmatter の生パースは `lib/frontmatter.sh` に委譲（grep/sed/awk 直書き禁止）。

---

### ストーリー 2: doctor で着手前診断
**優先順位**: Must-have

As a AI-DLC を使う開発者
I want to `/aidlc-v3 doctor` で config / git / gh / state / work-items の問題を着手前に診断したい
So that フェーズを進める前に環境・状態の不整合を発見でき、壊れた state で作業を始めずに済む

**受け入れ基準**:
- [ ] `/aidlc-v3 doctor` 実行で `[config] [state] [cycle] [work-items] [git] [gh] [pr] [scripts]` の各領域に `OK` / `WARN` / `NG`（+推奨）が表示される
- [ ] 禁止パースパターン検出（`bin/check-frontmatter-parse-guard.sh` 相当の流用）の結果が doctor 出力に含まれる
- [ ] doctor は state.json / work item が壊れていても**診断結果と推奨のみ**を提示し、自動修正しない
- [ ] `[phase]`（フェーズ導出 code 化）/ `[trace]`（intent_refs 整合）は本サイクルでは出力せず、`doctor.md` に「alpha.8 へ defer」と明記される
- [ ] `scripts/doctor.sh` の契約テストが追加され、`state.json 不在` / `state.json 破損` / `work item frontmatter 不正` / `必須スクリプト不在` / `git dirty/clean` / `gh 未認証` / `active PR あり` / `active PR なし` / `gh 未認証・不可時の pr 診断` / `parse-guard 違反` / `No active cycle` / 全領域 OK の正常系 を検証する（各ケースで `OK`/`WARN`/`NG` + 推奨表示・自動修正なしを確認）
- [ ] `SKILL.md` の `doctor` が「予約」から実装済み（`steps/doctor.md` / `scripts/doctor.sh`）に更新される

**技術的考慮事項**:
- `docs/v3/workflow.md §3.6` が SoT。既存 `state-validate.sh` / `work-item-validate.sh` / native git・gh を再利用し新規ロジックを最小化する。

---

### ストーリー 3: status の現在地表示拡充
**優先順位**: Must-have

As a AI-DLC を使う開発者
I want to `/aidlc-v3 status` で現在地・残作業・次の推奨コマンドを正確に把握したい
So that サイクルのどこにいるか・次に何を打てばよいかを会話履歴に頼らず判断できる

**受け入れ基準**:
- [ ] active cycle 時、`Cycle` / `Phase`（導出根拠併記）/ `Current work item`（size・risk・status）/ `Completed`（done・withdrawn 内訳）/ `Blocked` / `Remaining` / `Suggested command` が `docs/v3/workflow.md §3.5` の出力例どおり表示される
- [ ] state.json 不在時に `No active cycle found.` + `Suggested command: /aidlc define` が表示される
- [ ] 出力整合がテストまたは再現可能なドライ検証で確認される
- [ ] status は状態を変更しない（読み取り専用）

**技術的考慮事項**:
- フェーズ導出の SoT は `docs/v3/data-model.md §5`。status は導出結果の表示のみで導出規則を再定義しない。

---

### ストーリー 4: squash-unit.sh を複数 --message で安全に呼ぶ（#735）
**優先順位**: Must-have

As a ドッグフーディング開発者（および AI エージェント）
I want to `squash-unit.sh` を `git commit` の慣習どおり複数 `--message` で呼んでも subject が失われないようにしたい
So that コミットメッセージ規約（subject 行）がサイレントに壊れず、`git commit --amend` の手動補正が不要になる

**受け入れ基準**:
- [ ] `skills/aidlc/scripts/squash-unit.sh` に `--message` を複数回渡すと、1 個目が subject、2 個目以降が本文段落として段落結合される（`git commit` 準拠）
- [ ] Co-Authored-By トレーラが重複しない（最後の `--message` と別経路付与の二重出力が起きない）
- [ ] 複数 `--message` / Co-Authored-By 重複の回帰テストが `skills/aidlc/scripts/tests/` に追加され、green になる
- [ ] 単一 `--message` の既存挙動は後方互換を維持する

**技術的考慮事項**:
- `parse_args` の `--message` 後勝ち上書きと Co-Authored-By 付与経路を修正。v2 ツール（`skills/aidlc/`）であり v3 サブシステムへの依存はない。

---

### ストーリー 5: doctor 段階スコープの SoT 一貫性 と #733 クローズ
**優先順位**: Must-have

As a 本キットのメンテナ（メタ開発者）
I want to doctor の alpha.7/alpha.8 段階スコープが設計 SoT に明示され、解消済みの #733 がクローズされていてほしい
So that Phase 6 完了判定が「全項目診断」と「shallow doctor」で二重化せず、未対応 Issue が滞留しない

**受け入れ基準**:
- [ ] `docs/v3/workflow.md §3.6` の doctor チェック項目表に、各項目の alpha.7 実装 / alpha.8 defer 段階注記が追加される（`[phase]` / `[trace]` = alpha.8）
- [ ] `docs/v3-renewal-plan.md` の Phase 6 定義および doctor チェック項目一覧に alpha.7/alpha.8 段階注記が追加され、Epic #736 の Phase 6 完了条件が「alpha.7 = doctor shallow / phase・trace = alpha.8 必須 follow-up」へ更新される
- [ ] alpha.8 の必須 follow-up（doctor `[phase]` / `[trace]`）が Epic #736 ロードマップまたは backlog Issue として切り出される
- [ ] #733（v3系通し振り返り）が alpha.4 完了証跡（`lib/frontmatter.sh` / conformance test / `bin/check-frontmatter-parse-guard.sh` + CI / `state-read.sh` CycleResolver）をコメントしてクローズされる

**技術的考慮事項**:
- #733 は実装作業ゼロ（クローズのみ）。SoT 反映は doctor 実装の範囲を文書に正しく固定する作業。
