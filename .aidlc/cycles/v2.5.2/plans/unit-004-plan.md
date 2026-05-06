# Unit 004 計画: Operations Phase 7.12 PR レビュー反映コミットの squash 統合

## 概要

`skills/aidlc/steps/operations/operations-release.md` の 7.12（PR マージ前レビュー）と 7.13（PR マージ）の間に **Squash サブステップ（7.12.5）** を追加し、`squash_enabled=true` 時は 7.12 で発生した複数 round のレビュー反映コミットを 1 コミットに squash 統合する。Squash 起点は `progress.md` の新規スロット `<!-- release_prep_commit: <40 桁 SHA> -->`（DR-009 / HTML コメント形式）から取得し、`HEAD` までの追加コミットを対象とする。`merge_method=merge` 維持下でも main 履歴に細粒度のレビュー反映コミットが残らないようにする。実装は `git reset --soft` 方式（DR-008）で完全非対話。

## 関連 Issue

- #639（Operations Phase で 7.12 PR レビュー反映コミットが squash されずに merge される）

## 変更対象ファイル

| ファイル | 操作 | 説明 |
|---------|------|------|
| `skills/aidlc/templates/operations_progress_template.md` | 改修 | 固定スロットセクション直後に専用エリアとして `<!-- release_prep_commit: -->`（空値）を追加（DR-009 確定仕様に従う） |
| `skills/aidlc/scripts/operations-release.sh` | 改修 | (1) `record-release-prep-commit` サブコマンドを新設（§7.7.1 から呼ぶ）/ (2) `squash-712` サブコマンドを新設（§7.12.5 の判定・実行・rollback ロジックを集約。`commit-flow.md` 前提チェックの結果を内部利用しつつ外部シグナルは `squash:success:<sha>` / `squash:skipped`（reason は内部 log）/ `squash:failed:reason=git_op_failed:<exit_code>` に統一） |
| `skills/aidlc/steps/operations/operations-release.md` | 改修（**正本**） | (1) §7.7 完了直後に **§7.7.1** を追加し `operations-release.sh record-release-prep-commit` を呼ぶ手順を記述 / (2) §7.12 と §7.13 の間に **§7.12.5 Squash サブステップ** を追加（`operations-release.sh squash-712` を呼ぶ + 戻り値ハンドリング + force-push 案内連動） |
| `skills/aidlc/steps/operations/02-deploy.md` | 改修（**非正本**） | `operations-release.md` への参照リンクを更新（Squash サブステップ本体は重複させない） |
| `skills/aidlc/steps/common/phase-recovery-spec.md` | 改修 | §5.3.5 grammar v1 への影響を明示（`release_prep_commit` は HTML コメント形式の独立スロットとして grammar v1 のキー=値パース対象外であり、別系統の正規表現 `^<!-- release_prep_commit: ([0-9a-f]{40})? -->$` でパースする旨を追記）+ `format_error` の取扱い |
| `bin/tests/operations-712-squash/release_prep_commit_slot.bats` | 新規 | `operations-release.sh record-release-prep-commit` の単体テスト（slot 不在時の追加 / 既存値の更新 / 不正値の format_error） |
| `bin/tests/operations-712-squash/squash_712_step.bats` | 新規 | `operations-release.sh squash-712` のサブコマンド契約テスト（disabled / release_prep_commit_missing / no_commits / 通常系 success / git_op_failed + rollback） |
| `CHANGELOG.md` | 更新 | v2.5.2 セクションに Operations 7.12.5 squash 追加と `release_prep_commit` slot 追加を記載 |

> **Codex round 1 指摘 #3 反映**: 当初「`operations-release.sh` 改修は本 Unit のスコープ外」と判断したが、Markdown 駆動だと BATS の安定したテスト境界を定義できない。Unit 定義「責務」(line 17) でも「7.7（最終コミット）完了時に commit hash を slot へ記録する処理を operations-release.md / **関連スクリプト** に追加」と明示されているため、Squash サブステップの判定・実行・rollback ロジックを `operations-release.sh` のサブコマンド (`record-release-prep-commit` / `squash-712`) として実装し、Markdown は手順説明のみ、スクリプトが実行契約、BATS がスクリプト契約を直接検証する 3 層構造に分離する。

## 実装計画

### Phase 1（設計）

`depth_level=standard` のため Phase 1 を実施する。

設計成果物:

- ドメインモデル（`design-artifacts/domain-models/unit_004_operations_712_squash_domain_model.md`）: `ReleasePrepCommit`（値オブジェクト）/ `SquashRange`（値オブジェクト）/ `SquashOutcome`（値オブジェクト：`success` / `skipped:disabled` / `skipped:release_prep_commit_missing` / `skipped:no_commits` / `failed:git_op_failed:<exit_code>`）/ `OperationsSquashService`（ドメインサービス）の関係と不変条件
- 論理設計（`design-artifacts/logical-designs/unit_004_operations_712_squash_logical_design.md`）: progress.md slot grammar 拡張仕様、§7.7 への記録ロジック、§7.12.5 サブステップの判定フロー、`commit-flow.md` Squash 統合フロー再利用方法、rollback 契約

設計レビュー（`reviewing-construction-design`）は review-flow に従い実施。

### Phase 2（実装）

#### 1. `templates/operations_progress_template.md` の改修

固定スロットセクションを以下に変更（DR-009 確定仕様: HTML コメント形式の独立スロット）:

```text
## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=false
completion_gate_ready=false
pr_number=

<!-- release_prep_commit: -->
```

**設計意図**:
- `release_gate_ready` / `completion_gate_ready` / `pr_number` は既存 grammar v1（`key=value` 形式）でパース対象
- `release_prep_commit` は **grammar v1 とは別系統の独立スロット** として HTML コメント形式 `<!-- release_prep_commit: <40 桁 SHA> -->` で記述（DR-009）
- 空値時は `<!-- release_prep_commit: -->` のまま、`record-release-prep-commit` サブコマンドが値を埋める

**後方互換性**: v2.5.1 以前のサイクルから引き継いだ progress.md は本 slot を含まないため、§7.12.5 の判定で「未存在」として skip（`squash:skipped` + 内部 log `reason: release_prep_commit_missing`）。

#### 2. `operations-release.sh` への `record-release-prep-commit` サブコマンド追加

```bash
scripts/operations-release.sh record-release-prep-commit --cycle <CYCLE>
```

**動作**:
1. `git rev-parse HEAD` で 40 桁 SHA を取得
2. `progress.md` の `<!-- release_prep_commit: ... -->` 行を取得した SHA で更新（既存値の上書き）
3. 行が存在しない場合（v2.5.1 以前のサイクル再開時）: 固定スロットセクション末尾に `<!-- release_prep_commit: <SHA> -->` を追加
4. `git add operations/progress.md && git commit -m "chore: [<CYCLE>] release_prep_commit 記録 - <SHA-prefix>"` でコミット
5. stdout: `release_prep_commit:recorded:<SHA>` / `release_prep_commit:updated:<SHA>` のいずれか
6. exit 0 で完了。失敗時は stderr に `error\trelease_prep_commit_*\t<msg>` を出力して exit 1

#### 3. `operations-release.md` §7.7.1 追加

§7.7（Git コミット）完了直後に以下を追加:

```markdown
### 7.7.1 release_prep_commit slot 記録【Unit 004 / #639 追加】

§7.7 のコミット完了後、Squash 起点 commit を progress.md の HTML コメント形式 slot `<!-- release_prep_commit: <40 桁 SHA> -->` に記録する。

実行コマンド:

\`\`\`bash
scripts/operations-release.sh record-release-prep-commit --cycle {{CYCLE}}
\`\`\`

stdout: `release_prep_commit:recorded:<SHA>` または `release_prep_commit:updated:<SHA>`
exit 0 で完了。失敗時は exit 1 + stderr 表示で Operations Phase block。
```

#### 4. `operations-release.sh` への `squash-712` サブコマンド追加

```bash
scripts/operations-release.sh squash-712 --cycle <CYCLE>
```

**判定・実行ロジック**:

1. **前提チェック**: `commit-flow.md` の Squash 統合フロー前提チェックロジックを内部呼び出し（`scripts/read-config.sh rules.git.squash_enabled` の結果評価）
   - `squash_enabled=false` → stdout `squash:skipped` + stderr `info\treason\tsquash_enabled=false` → exit 0
   - `read-config.sh` failed → stdout `squash:skipped` + stderr `info\treason\tread-config-failed` → exit 0（安全側）
2. **slot 取得**: `progress.md` から `<!-- release_prep_commit: ([0-9a-f]{40})? -->` を grep で抽出
   - 行不在 / 空値 → stdout `squash:skipped` + stderr `info\treason\trelease_prep_commit_missing` → exit 0
   - 不正値（39 桁 / 41 桁 / 非 hex）→ stderr `error\trelease_prep_commit_format_error\t<value>` → exit 1
3. **対象コミット数判定**: `git log <release_prep_commit>..HEAD --oneline | wc -l`
   - 0 件 → stdout `squash:skipped` + stderr `info\treason\tno_commits` → exit 0
   - 1 件以上 → 次へ
4. **Squash 実行**（`git reset --soft` 方式 / DR-008）:
   - `git reset --soft <release_prep_commit>`
   - `git commit -m "chore: [<CYCLE>] PR レビュー反映 squash 統合"`
   - 両方成功 → stdout `squash:success:<new_sha>` → exit 0
5. **Squash 失敗時 rollback**:
   - `git reset --soft` または `git commit` が exit != 0
   - `git reset --hard ORIG_HEAD` で作業ツリーを Squash 開始前に復旧
   - stdout `squash:failed:reason=git_op_failed:<exit_code>`
   - stderr `error\tsquash_failed\t<details>` + `recommended_command:<手動 squash 案内>`
   - exit 1（Operations Phase block）

**外部シグナル契約**（`commit-flow.md` 既存契約準拠）:

| 状況 | stdout | stderr ログ | exit code |
|------|--------|-----------|-----------|
| `squash_enabled=false` | `squash:skipped` | `info\treason\tsquash_enabled=false` | 0 |
| `release_prep_commit` 未存在 | `squash:skipped` | `info\treason\trelease_prep_commit_missing` | 0 |
| 対象 0 件 | `squash:skipped` | `info\treason\tno_commits` | 0 |
| 通常系 | `squash:success:<sha>` | （なし） | 0 |
| `format_error` | `squash:failed:reason=format_error` | `error\trelease_prep_commit_format_error\t<value>` | 1 |
| git op 失敗 | `squash:failed:reason=git_op_failed:<exit_code>` | `error\tsquash_failed\t<details>` | 1 |

> **Codex round 1 指摘 #2 反映**: 外部シグナルは `commit-flow.md` の既存契約「`squash:skipped` 固定 / 理由は別ログ `reason: ...`」に準拠。新シグナル `squash:skipped:reason=*` は導入しない。失敗系の `squash:failed:reason=*` は新規だが既存契約とは衝突しない（`commit-flow.md` には failed シグナルが定義されていないため）。

#### 5. `operations-release.md` §7.12.5 追加

§7.12 と §7.13 の間に以下を追加:

```markdown
## 7.12.5 PR レビュー反映コミット Squash 統合【Unit 004 / #639 追加】

7.12 で発生した複数 round のレビュー反映コミット（修正コミット + 履歴コミット）を 1 コミットに統合する。`merge_method=merge` 設定下でも main 履歴に細粒度コミットが残らないようにする。

実行コマンド:

\`\`\`bash
scripts/operations-release.sh squash-712 --cycle {{CYCLE}}
\`\`\`

戻り値ハンドリング:

- `squash:success:<sha>` → §7.13 へ進行 + force-push 案内（§7.9 の `verify-git remote-sync=diverged` 検出で既存案内発動）
- `squash:skipped` (stderr の `reason:` を表示) → §7.13 へ進行（block しない）
- `squash:failed:reason=*` → exit 1 で Operations Phase を block。`recommended_command:` で手動対応案内

§7.13 pre-flight check との整合: `git reset --soft + git commit` の組み合わせは作業ツリー clean を維持するため、`validate-git.sh uncommitted` は `uncommitted=ok` を返し続ける。
```

#### 4. `02-deploy.md` の参照リンク更新

§7.12 / §7.13 への参照を §7.12 → §7.12.5 → §7.13 の流れに更新（本体記述は `operations-release.md` のみ）。

#### 6. `phase-recovery-spec.md` §5.3.5 への slot 仕様追記

`release_prep_commit` は **HTML コメント形式の独立スロット**として grammar v1 のキー=値パース対象**外**。別系統の正規表現でパースする旨を §5.3.5 に追記:

```markdown
- `release_prep_commit`: **HTML コメント形式の独立スロット（grammar v1 のキー=値パース対象外）**。フォーマット: `<!-- release_prep_commit: <40 桁 SHA> -->`（値部は `^[0-9a-f]{40}$`）。空値 `<!-- release_prep_commit: -->` 行不在は「未存在」扱い（`format_error` ではなく `release_prep_commit_missing`）。値が非空で正規表現に合致しない場合のみ `format_error`。Operations Phase 7.7.1 で書き込まれ、§7.12.5 で参照される。
```

#### 7. BATS テスト追加

`bin/tests/operations-712-squash/release_prep_commit_slot.bats`（`record-release-prep-commit` サブコマンドの単体テスト）:

- 既存 progress.md（slot 行あり、空値）→ `release_prep_commit:updated:<HEAD-SHA>` を出力 + slot 行が更新される
- 既存 progress.md（slot 行なし）→ `release_prep_commit:recorded:<HEAD-SHA>` を出力 + slot 行が末尾に追加される
- 既存 progress.md（slot 行あり、既存値あり）→ `release_prep_commit:updated:<HEAD-SHA>` を出力 + 既存値が新値で上書きされる
- progress.md 不在 → exit 1 + stderr `error\trelease_prep_commit_progress_not_found\t...`

`bin/tests/operations-712-squash/squash_712_step.bats`（`squash-712` サブコマンドの契約テスト）:

- `squash_enabled=false` → stdout `squash:skipped` + stderr `info\treason\tsquash_enabled=false` + exit 0
- slot 行なし → stdout `squash:skipped` + stderr `info\treason\trelease_prep_commit_missing` + exit 0
- slot 値空 → stdout `squash:skipped` + stderr `info\treason\trelease_prep_commit_missing` + exit 0
- slot 値が 39 桁（不正フォーマット）→ stdout `squash:failed:reason=format_error` + stderr `error\trelease_prep_commit_format_error\t...` + exit 1
- 対象 0 件（slot 値 ＝ 現 HEAD SHA で `<release_prep_commit>..HEAD` 範囲が空）→ stdout `squash:skipped` + stderr `info\treason\tno_commits` + exit 0
- 通常系（複数コミット）→ `git reset --soft + git commit` 実行 → stdout `squash:success:<new_sha>` + exit 0 + `git log <release_prep_commit>..HEAD --oneline` が 1 行
- git commit 失敗（pre-commit hook で人工的に exit 1）→ `git reset --hard ORIG_HEAD` で rollback + stdout `squash:failed:reason=git_op_failed:1` + exit 1 + 作業ツリーが Squash 開始前と一致

#### 7. CHANGELOG 更新

```text
- Operations Phase 7.12 PR レビュー反映コミット squash 統合: §7.12 と §7.13 の間に Squash サブステップ (§7.12.5) を追加し、`squash_enabled=true` 設定下で複数 round のレビュー反映コミットを 1 コミットに統合。`progress.md` の HTML コメント形式スロット `<!-- release_prep_commit: <40 桁 SHA> -->` (新規 / DR-009) で起点 commit を追跡する (#639 / Unit 004)
- `templates/operations_progress_template.md` の固定スロットセクション直後に `<!-- release_prep_commit: -->` を追加 (Unit 004)
```

### 実装順序

1. ドメインモデル + 論理設計（Phase 1）
2. 設計レビュー
3. `templates/operations_progress_template.md` の改修（HTML コメント形式 slot 追加）
4. `operations-release.sh` への `record-release-prep-commit` / `squash-712` サブコマンド追加
5. `operations-release.md` §7.7.1 + §7.12.5 追加（サブコマンド呼び出し手順）
6. `02-deploy.md` 参照リンク更新
7. `phase-recovery-spec.md` §5.3.5 追記
8. BATS テスト追加（2 ファイル）+ pass 確認
9. CHANGELOG 更新
10. コードレビュー → 統合レビュー

## エラーハンドリング / 異常系

| 状況 | stdout | stderr | exit code |
|------|--------|--------|-----------|
| `squash_enabled=false` | `squash:skipped` | `info\treason\tsquash_enabled=false` | 0 |
| `release_prep_commit` slot 未存在 / 空文字 | `squash:skipped` | `info\treason\trelease_prep_commit_missing` | 0 |
| 対象コミット 0 件 | `squash:skipped` | `info\treason\tno_commits` | 0 |
| `release_prep_commit` 値が不正フォーマット（非 40 桁 hex） | `squash:failed:reason=format_error` | `error\trelease_prep_commit_format_error\t<value>` | 1 |
| `git reset --soft` / `git commit` 失敗 | `squash:failed:reason=git_op_failed:<exit_code>` | `error\tsquash_failed\t<details>` + `recommended_command:` | 1（rollback `git reset --hard ORIG_HEAD` 実行後） |

## NFR

- **パフォーマンス**: 通常 Squash 操作（数コミット）で 1 秒以内
- **セキュリティ**: rollback 保証（`git reset --soft` 方式 / DR-008、失敗時は `git reset --hard ORIG_HEAD`）
- **後方互換性**: v2.5.1 以前のサイクルから引き継いだ progress.md は `release_prep_commit_missing` で自動 skip される（追加対応不要）
- **可用性**: `git` 不可時は exit 1（事実上 git 必須環境のみ）

## 完了条件チェックリスト

- [x] `templates/operations_progress_template.md` の固定スロット直後に `<!-- release_prep_commit: -->` が追加されている（DR-009 確定仕様 / HTML コメント形式）
- [x] `operations-release.sh record-release-prep-commit` サブコマンドが新設されている
- [x] `operations-release.sh squash-712` サブコマンドが新設されている（前提チェック / slot 取得 / 対象数判定 / `reset --soft` 実行 / rollback）
- [x] `operations-release.md` §7.7.1 で `record-release-prep-commit` 呼び出し手順が追加されている
- [x] `operations-release.md` §7.12.5 で `squash-712` 呼び出し手順 + 戻り値ハンドリング + force-push 案内連動が追加されている
- [x] `02-deploy.md` の参照リンクが §7.12 → §7.12.5 → §7.13 の流れに更新されている
- [x] `phase-recovery-spec.md` §5.3.5 に `release_prep_commit` slot 仕様（grammar v1 対象外の独立スロット）が追記されている
- [x] `bin/tests/operations-712-squash/release_prep_commit_slot.bats` が追加され、すべて pass する（5/5）
- [x] `bin/tests/operations-712-squash/squash_712_step.bats` が追加され、7 ケースすべて pass する（disabled / slot 行なし missing / slot 値空 missing / format_error / no_commits / 通常系 success / git_op_failed + rollback）
- [x] 全 BATS テストが pass する（422/422）
- [x] 外部シグナル契約が `commit-flow.md` 既存契約に準拠する（`squash:skipped` 固定 / 理由は別ログ / 失敗系 `squash:failed:reason=*`）
- [x] `bin/check-bash-substitution.sh` / `bin/check-skill-references.sh` / `bin/check-test-isolation.sh` が pass する（exit 0 確認済）
- [x] CHANGELOG に Operations 7.12.5 squash と `release_prep_commit` slot 追加が記載されている
- [x] Issue #639 の close 技術条件（Squash サブステップ追加 + slot 追加 + 異常系契約 5 種実装 + サブコマンド 2 種実装）が満たされている
