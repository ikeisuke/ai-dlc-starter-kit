# ユーザーストーリー

対象サイクル: v3.0.0-alpha.8（#741: doctor に `[phase]` / `[trace]` 領域を追加 / Epic #736 Phase 6 必須 follow-up）

## Epic: doctor 完全診断化（shallow 9 領域 → 完全 11 領域）

### ストーリー 1: フェーズ導出の整合診断（`[phase]`）
**優先順位**: Must-have

As a AI-DLC（v3）を使う開発者
I want to `/aidlc-v3 doctor` 実行時に、現在の state.json と work item から導出される正しいフェーズ（define / develop / release 可能 / complete）を導出根拠付きで確認したい
So that 着手前に「今どのフェーズに居るか」と「その根拠」を機械的に把握でき、状態と導出の不整合を早期に検出できる

**受け入れ基準**:
- [ ] `doctor` 出力に `[phase]` 行が追加され、`report()` 契約（`[area] severity detail`）に従って `[phase]  OK    <derived-phase> (derived: ...)` 形式で出力される（severity トークンが領域ラベル直後）。
- [ ] 導出規則が `docs/v3/data-model.md §5.1` の first-match（complete → define → develop → release 可能）に整合する。
- [ ] `define_completed=false` または state.json 不在のとき `define` を導出する（診断不能で落とさない）。
- [ ] `define_completed=true` かつ未完（`done`/`withdrawn` 以外の）work item があれば `develop`、全 work item が `done`/`withdrawn` なら `release 可能` を導出する。
- [ ] `release.merge_approved=true` の場合のみ、`release.pr_number` を用いて gh で read-only に PR merged を確認し、merged のときだけ `complete` を導出する。gh 利用不可 / pr_number null / 取得失敗のいずれかでは `complete` に導出せず、§5.1 評価順2以降にフォールバックし、不一致（merge_approved=true だが未 merged/確認不能）を WARN で併記する。
- [ ] state.json と frontmatter の矛盾（例: `define_completed=false` なのに `done` の work item）は導出を安全側に倒し WARN で報告する（自動修正しない）。
- [ ] `[phase]` 領域は read-only（state.json / work item / config を変更しない）。

**技術的考慮事項**:
入力は既存スクリプト（`state-read.sh` / `work-item-status.sh`）経由で取得し、frontmatter は `lib/frontmatter.sh` 経由（新規パース禁止規約）。

---

### ストーリー 2: trace 整合（design 欠落）の診断（`[trace]`）
**優先順位**: Must-have

As a AI-DLC（v3）を使う開発者
I want to `doctor` 実行時に、design が必須の work item に対応する design ファイルが揃っているかを確認したい
So that design 欠落などの trace chain（intent → work items → designs）前段の不整合を、release 直前ではなく着手前に検出できる

**受け入れ基準**:
- [ ] `doctor` 出力に `[trace]` 行が追加され、`report()` 契約に従い `[trace]  OK|WARN  <detail>` 形式で出力される。
- [ ] design 要否は `docs/v3/data-model.md §8` の size×depth_level マトリクスを正本とし、design 必須（`normal × standard` / `normal × comprehensive` / `risky × standard` / `risky × comprehensive`）/ 不要（`tiny × *` / `normal × minimal`）を正しく判定する。
- [ ] design 必須の work item に対応する `designs/<id>-<slug>.md` が存在すれば OK、欠落すれば WARN を出力する。
- [ ] `risky × minimal`（§8 で「risky は minimal 不可」）は不正組み合わせとして WARN（exit 0 維持）で報告する（ERROR にしない）。
- [ ] `depth_level` は `read-config.sh rules.depth_level.level` で取得し、キー未設定（rc1）時は `standard` としてフォールバック判定する。
- [ ] size は `lib/frontmatter.sh`（`fm_scalar`）経由で取得する（新規パース禁止規約）。
- [ ] `[trace]` の範囲は「design 必須 work item に対応する design ファイル存在確認」に限定し、intent.md 存在検証・Traceability セクションの意味検証・dependencies 実在検証（`work-item-validate.sh` 担当）は行わない。
- [ ] `[trace]` 領域は read-only。

**技術的考慮事項**:
`work-item-validate.sh` の dependencies 実在検証と役割を分担し、cross-artifact trace（design 存在）に焦点を当てる。

---

### ストーリー 3: `[phase]` / `[trace]` の契約テスト
**優先順位**: Must-have

As a 本キットのドッグフーディング開発者
I want to `[phase]` / `[trace]` の各診断分岐が契約テストで自動検証され、全領域 OK 正常系が 11 領域に拡張されていてほしい
So that doctor の回帰を防ぎ、Phase 7 本流化前に診断ロジックの信頼性を担保できる

**受け入れ基準**:
- [ ] `skills/aidlc-v3/scripts/tests/test-doctor.sh` に `[phase]` の各導出ケース（define / develop / release 可能 / complete）と根拠文字列の検証が追加される。
- [ ] `[phase]` の異常系 WARN 分岐がテストされる: (a) `merge_approved=true` かつ gh 不可 または PR 未 merged で `complete` に導出せず WARN 併記、(b) `define_completed=false` かつ `done` の work item が存在する矛盾で安全側（define/develop）導出 + WARN。
- [ ] `test-doctor.sh` に `[trace]` の各ケース（design 必須 × 存在=OK / 必須 × 欠落=WARN / 不要=OK / `normal × comprehensive` 必須 / `risky × minimal`=WARN / `depth_level` 未設定→standard 判定）が追加される。
- [ ] 既存「全領域 OK 正常系」テストが 9 領域 → 11 領域に拡張される。
- [ ] テストは既存ハーネス方針（fixture + stub / jq 前提 / ネットワーク非依存 / 冒頭 `bash -n`・shellcheck）を維持する。
- [ ] 既存 v3 テスト（`skills/aidlc-v3/scripts/tests/`）が green を維持する。

**技術的考慮事項**:
`assert_area <area> <severity>` でアサートするため、severity トークンを領域ラベル直後に固定する出力契約を前提とする。

---

### ストーリー 4: doctor 完全診断の SoT ドキュメント反映
**優先順位**: Must-have

As a 本キットのドッグフーディング開発者
I want to doctor の段階スコープ注記（alpha.8 defer）が実装済みに更新され、領域カウント表記が 11 領域で統一されていてほしい
So that ドキュメントが実装と一致し、Epic #736 Phase 6 の完了判定（doctor 全領域実装済み）が明確になる

**受け入れ基準**:
- [ ] `skills/aidlc-v3/steps/doctor.md` が「11 領域」に更新され、診断領域テーブルに `[phase]` / `[trace]` が追加、出力例に 2 行追加、末尾「## alpha.8 defer」セクションが実装済み記述へ置換される。`[trace]` と `[work-items]` の役割分担が明示される。
- [ ] `docs/v3/workflow.md` の §3.6（段階スコープ注記 / チェック項目テーブル / 出力例 / コマンド体系）の「alpha.8 defer」が「実装済み」へ更新される。
- [ ] `docs/v3-renewal-plan.md` の doctor セクションと Phase 6 完了条件の「alpha.8 defer」が「実装済み」へ更新される。
- [ ] ドキュメント（`doctor.md` / `workflow.md` / `docs/v3-renewal-plan.md`）の領域カウント表記が「11 領域」で統一される（「8 領域 + parse-guard」「9 領域」表記の揺れを解消）。なお `doctor.sh` ヘッダコメント自体のカウント更新は実装の一部として Unit 001 で行い、本ストーリーはその結果と整合する公開ドキュメント表記の統一を担う。
- [ ] ドキュメントの出力例が実装の実出力（severity トークン位置）と一致する。

**技術的考慮事項**:
出力例は実装の実出力に揃えるため、ストーリー1〜3（実装）完了後に反映する。`doctor.sh` ヘッダのカウントは Unit 001 完了条件として参照するのみ（本ストーリーでは編集しない）。
