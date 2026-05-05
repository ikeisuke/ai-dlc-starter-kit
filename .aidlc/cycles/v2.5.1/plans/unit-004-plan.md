# Unit 004 計画: predecessor handoff の Issue 検索化

## サイクル

v2.5.1

## 対象 Unit 定義

`.aidlc/cycles/v2.5.1/story-artifacts/units/004-predecessor-issue-handoff.md`

## 含まれるユーザーストーリー

- ストーリー 4: predecessor handoff の Issue 検索化（Must-have）

## 関連 Intent / 設計判断

- Intent §「主要設計判断 6.1」: ラベル / Milestone 命名規約の正本（`retrospective` ラベル + サイクル番号 Milestone）
- Inception decisions DR-005: 「predecessor handoff の Issue 検索キー = closed Milestone + retrospective ラベル AND 検索」
- Unit 002 の起票実装による上流データ生成依存（命名規約は Intent §6.1 が canonical / Unit 002 への直接依存ではない）

## 責務（読み取り側のみ）

- `skills/aidlc/steps/inception/01-setup.md §4a` の改修
  - 手動配置参照（`predecessor_retrospective.md` / `operations/retrospective.md`）を削除し、Issue 検索ロジックに置き換え
  - v2.5.0 互換 fallback として既存 `cycles/{{PREV_CYCLE}}/operations/retrospective.md` 読み取りは維持（Issue 検索 0 件時の追加 fallback）
- Issue 検索ロジック実装（共通ライブラリ化を検討）
  - `gh issue list --milestone <PREV_CYCLE> --label retrospective --state all` を canonical 経路
  - `milestone_enabled=false` 環境では label 単独検索 + `closedAt` 降順最新採用 + 確認に fallback
  - `gh_status != available` 環境では spool（`cycles/{{PREV_CYCLE}}/history/retrospective-spool.md`）を読む fallback
- 検索結果分岐判定（厳密な判定順）
  - 0 件 / 1 件 / 複数件 / `gh` 不可 / `milestone_enabled=false` の各経路
- 旧テンプレート廃止
  - `skills/aidlc/templates/predecessor_retrospective.md` を本 Unit のコミットで物理削除する（実行時の残存検出 warn は §4a の実装ロジックに含めるが、計画方針としては「物理削除必須」で単一化）
- コンテキスト変数 `predecessor_retrospective_issue_url` の設定（Issue 採用時のみ）
- BATS テスト `tests/predecessor-issue-handoff.bats`

## 境界保護（編集禁止 / 参照のみ）

- **Unit 002 中核ライブラリは参照のみ**: `skills/aidlc/scripts/lib/retrospective-issue.sh` / `retrospective-resend.sh` / `templates/retrospective_template.md` への変更を含まない。spool 読み取りは **必ず Unit 002 が既に提供する公開関数 `_spool_extract_entries` を source して使う**（NDJSON 各行を取得 → Unit 004 では `issue_url` フィールド抽出までに留め、`partial_state.local_created` / `partial_state.mirror_created` 等の内部構造を Unit 004 側で直接解釈してはならない / 不足機能があれば Unit 002 へ reader 公開関数追加を依頼してから Unit 004 を進める）
- **Unit 001 / Unit 003 ファイルは参照のみ**: `feedback-mode*.sh` / `retrospective-llm-draft.sh` / `retrospective-human-review.sh` / `retrospective-verify.sh` / `agents/retrospective-drafter.md` への変更を含まない
- **§1.5（Operations 04-completion）への変更ゼロ**: Unit 002 で確定した起票フローには触らない

## 変更対象ファイル

### 改修

- `skills/aidlc/steps/inception/01-setup.md` §4a: 手動配置参照を Issue 検索 + 判定順 + spool fallback + v2.5.0 互換 fallback に置換

### 新規

- `skills/aidlc/scripts/lib/predecessor-issue.sh`（候補 / 後続設計フェーズで確定）: Issue 検索ロジック共通関数（`predecessor_resolve_issue(prev_cycle)` / `--milestone` / label fallback / spool fallback / v2.5.0 retrospective.md 互換 fallback / `closedAt` 降順並び替え）
- `tests/predecessor-issue-handoff.bats`: 0 件 / 1 件 / 複数件 / `gh` 不可 / `milestone_enabled=false` / spool fallback / v2.5.0 互換の 7 経路を BATS でモック検証

### 削除

- `skills/aidlc/templates/predecessor_retrospective.md`（テンプレ廃止: 本 Unit のコミットで削除する。実行時の残存検出 warn は §4a に含めるが、ユニット完了時点で物理的に削除済であることを完了条件で必須化）

### 編集しない（境界保護）

- `skills/aidlc/steps/operations/04-completion.md`（§1.5 起票フロー / Unit 002 の正本）
- `skills/aidlc/scripts/lib/retrospective-issue.sh` / `retrospective-resend.sh`（Unit 002 ライブラリ / 参照のみ）
- `skills/aidlc/scripts/lib/retrospective-llm-draft.sh` / `retrospective-human-review.sh`（Unit 003）
- `skills/aidlc/scripts/retrospective-verify.sh`（Unit 003 CLI）
- `skills/aidlc/scripts/lib/feedback-mode.sh` / `feedback-mode-wizard.sh`（Unit 001）
- `skills/aidlc/templates/retrospective_template.md`（Unit 002 の起票テンプレ）

## ストーリー受け入れ基準とのトレース

### 正常系 / 検索成功

- [ ] §4a で前サイクル closed Milestone + `retrospective` ラベル の AND 検索を実行する
- [ ] ヒット 1 件 → 自動採用、`predecessor_retrospective_issue_url` に格納
- [ ] ヒット ≥ 2 件 → AskUserQuestion で対話確認（候補一覧から選択）

### 異常系 / フォールバック判定順（統一優先順位表）

すべての環境で以下の優先順位を厳密に守る（上位経路が成功すれば下位は実行しない）:

| 優先順位 | 経路 | 適用条件 | 動作 | コンテキスト変数 |
|---------|------|---------|------|----------------|
| 1 | Issue 検索（canonical） | `gh_status=available` × `milestone_enabled=true` | closed Milestone + retrospective ラベル AND 検索 → 1 件: 自動採用 / ≥ 2 件: AskUserQuestion / 0 件: 次経路 | 採用時 `predecessor_retrospective_issue_url` 設定 |
| 1' | Issue 検索（label fallback） | `gh_status=available` × `milestone_enabled=false` | retrospective ラベル単独検索 → 1 件: 自動採用 / ≥ 2 件: `closedAt` 降順最新 + AskUserQuestion / 0 件: 次経路 | 採用時 `predecessor_retrospective_issue_url` 設定 |
| 2 | spool fallback | 経路 1 / 1' で 0 件、または `gh_status != available` | `cycles/{{PREV_CYCLE}}/history/retrospective-spool.md` を Unit 002 `_spool_extract_entries` 経由で読み取り、issue_url フィールドを取得 → 取得成功で自動採用 / 失敗で次経路 | 採用時 `predecessor_retrospective_issue_url` 設定（spool 内 issue_url 値） |
| 3 | v2.5.0 互換 fallback | 経路 1 / 1' / 2 すべて 0 件 | 既存 `cycles/{{PREV_CYCLE}}/operations/retrospective.md` ファイル読み取り → ファイル存在で Intent 前提として参照 | コンテキスト変数は未設定（issue_url 取得経路ではないため）/ `predecessor_retrospective_file_path` のみ設定 |
| 4 | warn / continue | 経路 1 / 1' / 2 / 3 すべて 0 件 | predecessor 参照なしで継続（warn 表示） | コンテキスト変数すべて未設定 |

BATS 検証ケースもこの 4 経路 + label fallback 経路（1'）の **5 経路 + 各経路の複数件分岐 = 7 ケース**を直接検証する。

### 旧資産削除と廃止境界

- [ ] **新規生成禁止**: `01-setup.md` から `predecessor_retrospective.md` 関連の手動配置案内が grep で 0 件
- [ ] **テンプレ削除必須**: `skills/aidlc/templates/predecessor_retrospective.md` を本 Unit のコミットで **削除する**（残存時 warn は §4a の実行時検出ロジックに含めるが、テストでは「削除されている」ことを必須として検証 / 二重定義を排除）
- [ ] **旧資産読み取りのみ許可**: 既存 `cycles/{{PREV_CYCLE}}/operations/retrospective.md` ファイルは読み取り経路として維持（v2.5.0 互換 / 上記優先順位 3 の追加 fallback）

## NFR

- **検索精度**: 前サイクル retrospective Issue を一意に特定（複数件時の対話確認で誤り参照を防止）
- **可用性**: `gh` 不可 / 0 件時も処理が継続できる（spool fallback / warn 表示）
- **互換性**: v2.5.0 ユーザーの旧 `retrospective.md` ファイル参照経路を読み取りに限り維持

## 完了条件チェックリスト

### Unit 責務由来

- [ ] `01-setup.md §4a` が「優先順位表 1 / 1' / 2 / 3 / 4」順の Issue 検索 + spool fallback + v2.5.0 互換 fallback + warn/continue に書き換わっている（判定順は 1 本の優先順位表で統一）
- [ ] 手動配置案内（`predecessor_retrospective.md`）が `01-setup.md` から完全削除（grep で 0 件）
- [ ] `skills/aidlc/templates/predecessor_retrospective.md` が **本 Unit のコミットで物理削除** されている（テストで存在チェック）
- [ ] Issue 検索（経路 1: milestone_enabled=true）0 件 / 1 件 / 複数件の 3 ケースが BATS で verify
- [ ] Issue 検索（経路 1': milestone_enabled=false / label fallback）0 件 / 1 件 / 複数件の 3 ケースが BATS で verify
- [ ] spool fallback（経路 2 / `_spool_extract_entries` 経由）読み取り経路が BATS で verify
- [ ] v2.5.0 互換（経路 3 / `operations/retrospective.md`）読み取り経路が BATS で verify
- [ ] 全経路 0 件（経路 4 / warn + continue）が BATS で verify
- [ ] `gh_status != available` 環境での経路 2 直接遷移が BATS で verify
- [ ] コンテキスト変数 `predecessor_retrospective_issue_url` が経路 1 / 1' / 2 採用時のみ設定（経路 3 / 4 では未設定 / 経路 3 は `predecessor_retrospective_file_path` のみ設定）

### Intent / decisions 由来

- [ ] **DR-005 整合**: 検索キー = closed Milestone + retrospective ラベル AND（`milestone_enabled=false` 時のみ label のみ fallback）
- [ ] **判断 6.1 整合**: ラベル / Milestone 命名は Intent §6.1 を canonical source として参照（Unit 002 への直接依存はしない）

### NFR 由来

- [ ] **検索精度**: ≥ 2 件時の対話確認 / 1 件時の自動採用が動作（BATS で verify）
- [ ] **可用性**: gh 不可 / 0 件時の spool fallback / warn 表示が動作（BATS で verify）
- [ ] **互換性**: v2.5.0 互換 `operations/retrospective.md` 読み取り fallback が動作（BATS で verify）

### 境界・責務由来（逆方向非依存検証）

- [ ] **Unit 002 中核ライブラリの参照のみ**: `git diff` で `lib/retrospective-issue.sh` / `retrospective-resend.sh` / `templates/retrospective_template.md` への変更ゼロ
- [ ] **Unit 001 / Unit 003 への変更ゼロ**: `git diff` で `feedback-mode*.sh` / `retrospective-llm-draft.sh` / `retrospective-human-review.sh` / `retrospective-verify.sh` / `agents/retrospective-drafter.md` への変更ゼロ
- [ ] **§1.5 への変更ゼロ**: `git diff skills/aidlc/steps/operations/04-completion.md` が本 Unit のコミットで 0 件

### `bin/check-bash-substitution.sh` 規約準拠

- [ ] 新規スクリプト・テストファイルで `$()` / バッククォート使用 0（CI で violation 0 を verify）

## リスク

- **R1**: Issue 検索の N+1 / レート制限。**緩和**: `--limit 50` 程度で打ち切り、ヒット ≥ 2 件は対話確認に倒すことでリトライ負荷を抑える
- **R2**: spool ファイル形式（NDJSON v1 / Unit 002 確定）の読み取り依存が Unit 002 の内部実装に密結合する。**緩和**: spool 読み取りは Unit 002 の既存公開関数 `_spool_extract_entries`（`skills/aidlc/scripts/lib/retrospective-issue.sh` line 602 で提供）を source して使用する。Unit 004 では NDJSON 各行を取得した後 `jq -r .issue_url` 程度の最小限のフィールド抽出に留め、`partial_state` 等の内部構造を Unit 004 側で直接解釈しない。`_spool_extract_entries` で不足する経路（例: spool が複数件ある場合の優先順）が判明した場合は Unit 002 へ reader 公開関数追加を先に依頼してから Unit 004 を進める運用を必須化
- **R3**: `milestone_enabled` 設定の解決経路が Unit 001/002 と分散。**緩和**: `read-config.sh` で統一参照、設定値は `[project].milestone_enabled` のみを参照する
- **R4**: v2.5.0 互換 fallback の優先順位曖昧（「Issue 検索 → spool → v2.5.0 互換」の順序）。**緩和**: 設計フェーズで判定順の優先度を表として明示、テストで全パス分岐を verify
- **R5**: `gh issue list` の `--state all` で closed Milestone 内の Issue が確実に取得できるかの検証。**緩和**: 設計フェーズで gh CLI 仕様を再確認、BATS モックで closed Milestone 配下 Issue の取得経路を verify

## 出力先（参考）

- 設計: `.aidlc/cycles/v2.5.1/design-artifacts/domain-models/unit_004_predecessor_issue_handoff_domain_model.md` / `.aidlc/cycles/v2.5.1/design-artifacts/logical-designs/unit_004_predecessor_issue_handoff_logical_design.md`
- 実装: `skills/aidlc/scripts/lib/predecessor-issue.sh`（候補）/ `skills/aidlc/steps/inception/01-setup.md` §4a 改修
- テスト: `tests/predecessor-issue-handoff.bats`
- 履歴: `.aidlc/cycles/v2.5.1/history/construction_unit04.md`
- レビュー履歴: `.aidlc/cycles/v2.5.1/construction/units/004-review-summary.md`
