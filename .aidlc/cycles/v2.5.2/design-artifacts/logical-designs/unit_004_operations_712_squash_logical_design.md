# 論理設計: Operations Phase 7.12 PR レビュー反映コミットの squash 統合

## 概要

`operations-release.sh` に `record-release-prep-commit`（§7.7.1）と `squash-712`（§7.12.5）の 2 サブコマンドを追加する。Markdown は手順記述のみ、シェルスクリプトが実行契約を担い、BATS がスクリプト契約を直接検証する 3 層構造を採る。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコードは Phase 2 で作成します。

## アーキテクチャパターン

**採用パターン**: Subcommand Dispatcher Pattern（既存 `operations-release.sh` の `cmd_*` 関数 + `main` dispatch 構造を踏襲）

**選定理由**:
- `operations-release.sh` は既に同パターンで `version-check` / `pr-ready` / `verify-git` / `merge-pr` の 4 サブコマンドを実装済み
- 新規 2 サブコマンドも同じパターンで追加することで一貫性を確保
- BATS テストも既存テストと同形式で書けるため学習コスト最小

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc/scripts/
├── operations-release.sh       # 【改修】サブコマンド 2 つ追加
│   ├── cmd_record_release_prep_commit  (新規)
│   └── cmd_squash_712                  (新規)
└── lib/
    └── (既存ライブラリ流用、新規追加なし)

skills/aidlc/steps/
├── operations/
│   ├── operations-release.md   # 【改修】§7.7.1 / §7.12.5 追加（正本）
│   └── 02-deploy.md            # 【改修】参照リンク更新（非正本）
└── common/
    └── phase-recovery-spec.md  # 【改修】§5.3.5 に slot 仕様追記

skills/aidlc/templates/
└── operations_progress_template.md  # 【改修】HTML コメント slot 追加

bin/tests/
└── operations-712-squash/      # 【新規】BATS テスト 2 ファイル
    ├── release_prep_commit_slot.bats
    └── squash_712_step.bats
```

### コンポーネント詳細

#### `cmd_record_release_prep_commit`（operations-release.sh 内 / 新規）

- **責務**: progress.md の `<!-- release_prep_commit: <SHA> -->` slot を最新 HEAD SHA で更新（既存行があれば置換、なければ末尾追加）
- **依存**: `git rev-parse` / `sed` / `progress.md` ファイル
- **公開インターフェース**: `operations-release.sh record-release-prep-commit --cycle <CYCLE>`

#### `cmd_squash_712`（operations-release.sh 内 / 新規）

- **責務**: §7.12.5 の判定（`squash_enabled` / slot 取得 / 対象数判定）+ `git reset --soft + git commit` 実行 + 失敗時 rollback
- **依存**: `scripts/read-config.sh`（`squash_enabled` 値取得）、`progress.md`、git コマンド群
- **公開インターフェース**: `operations-release.sh squash-712 --cycle <CYCLE>`

#### Markdown 側（operations-release.md §7.7.1 / §7.12.5）

- **責務**: 上記 2 サブコマンドを呼ぶ手順を記述。シグナル戻り値の解釈と分岐表のみ
- **依存**: `cmd_record_release_prep_commit` / `cmd_squash_712`

## インターフェース設計

## スクリプトインターフェース設計

### `operations-release.sh record-release-prep-commit`

#### 概要

§7.7 のコミット完了後に最新 HEAD SHA を `progress.md` の HTML コメント slot に記録する。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--cycle <CYCLE>` | 必須 | サイクル名（例: `v2.5.2`）。`progress.md` のパス解決に使用 |
| `--dry-run` | 任意 | 副作用なしで実行予定を `would run: ...` 出力 |
| `-h, --help` | 任意 | ヘルプ表示 |

#### 成功時出力

```text
release_prep_commit:recorded:<40 桁 SHA>
```

または既存値の上書き時:

```text
release_prep_commit:updated:<40 桁 SHA>
```

- 終了コード: `0`
- 出力先: stdout
- 副作用: `progress.md` の slot 行を更新（行不在時は固定スロットセクション末尾に追加）+ `git add operations/progress.md && git commit -m "chore: [<CYCLE>] release_prep_commit 記録 - <SHA-prefix>"` で自動コミット

#### エラー時出力

```text
error\trecord-release-prep-commit:progress-not-found\t<path>
error\trecord-release-prep-commit:git-rev-parse-failed
error\trecord-release-prep-commit:write-failed\t<reason>
```

- 終了コード: `1`（バリデーションエラー / 書き込み失敗）
- 出力先: stderr

### `operations-release.sh squash-712`

#### 概要

§7.7 で記録した `release_prep_commit` から HEAD までのコミットを 1 コミットに squash 統合（`git reset --soft` 方式 / DR-008）。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--cycle <CYCLE>` | 必須 | サイクル名 |
| `--dry-run` | 任意 | 副作用なしで判定結果のみ出力 |
| `-h, --help` | 任意 | ヘルプ表示 |

#### 判定フロー

```text
1. read-config.sh rules.git.squash_enabled を取得（commit-flow.md 既存契約準拠）
   - exit 0 + "true"  → 次へ
   - exit 0 + "false" → squash:skipped + stderr "info\treason\tsquash_enabled=false" で exit 0
   - exit 1 (unset)   → squash:skipped + stderr "info\treason\tsquash_enabled=unset" で exit 0
   - exit 2 (error)   → squash:skipped + stderr "info\treason\tread-config.sh failed" で exit 0（安全側 / commit-flow.md と reason 文字列を統一）
2. progress.md から release_prep_commit slot を 2 段階判定でパース（DomainModel ParseResult 仕様準拠）
   2a. 行存在判定: `grep -cE '^<!-- release_prep_commit:( |$)' progress.md` でマッチ件数取得（コロン後にスペースまたは行末で終わる行をマッチ / 空値 `<!-- release_prep_commit: -->` も「行存在」として扱う / 値空のケースは 2b の trim 後判定で Missing 化）
       - 0 件 → ParseResult.Missing → squash:skipped + stderr "info\treason\trelease_prep_commit_missing" で exit 0
   2b. 値抽出: マッチ行から sed/awk で `<!-- release_prep_commit:` と ` -->` の間の値を取り、両端空白を trim
       - 値空 → ParseResult.Missing → squash:skipped + stderr "info\treason\trelease_prep_commit_missing" で exit 0
       - 値非空 + ^[0-9a-f]{40}$ 合致 → ParseResult.Found(sha) → 次へ
       - 値非空 + 非合致（39/41 桁・非 hex 等）→ ParseResult.FormatError(rawValue) → squash:failed:reason=format_error + stderr "error\trelease_prep_commit_format_error\t<rawValue>" で exit 1
3. git log <release_prep_commit>..HEAD --oneline | wc -l で対象数判定
   - 0 件 → squash:skipped + stderr "info\treason\tno_commits" で exit 0
   - 1 件以上 → 次へ
4. git reset --soft <release_prep_commit>
   - 失敗（exit != 0）→ HEAD は変更されていないため rollback 不要（DomainModel INV-4 の rollback 前提条件 不成立）
   - stderr に "error\tsquash_712:reset-soft-failed\t<exit_code>" + recommended_command:<手動 squash 案内>
   - squash:failed:reason=git_op_failed:<exit_code> で exit 1
   - 成功 → ORIG_HEAD が Squash 開始前 HEAD を指す。次へ
5. git commit -m "chore: [<CYCLE>] PR レビュー反映 squash 統合"
   - 成功 → squash:success:<new_sha> で exit 0
   - 失敗（exit != 0）→ DomainModel INV-4 rollback 条件成立: git reset --hard ORIG_HEAD で復旧
     - rollback 自身も失敗 → stderr に "error\tsquash_712:rollback-failed\t<details>" + recommended_command で手動対応案内（fatal）
     - rollback 成功時も squash:failed:reason=git_op_failed:<exit_code> で exit 1
   - stderr に "error\tsquash_712:commit-failed\t<exit_code>" + recommended_command:<手動 squash 案内>
```

#### 成功時出力

```text
squash:success:<新規コミット SHA>
```

または skip 時:

```text
squash:skipped
```

stderr に `info\treason\t<reason>` の補助 log 出力（reason は `commit-flow.md` 既存契約準拠で stdout には乗せない）。

- 終了コード: `0`
- 出力先: stdout（外部シグナル）/ stderr（reason ログ）

#### エラー時出力

```text
squash:failed:reason=format_error
squash:failed:reason=git_op_failed:<exit_code>
```

- 終了コード: `1`
- 出力先: stdout（外部シグナル）+ stderr（`error\t<sub_code>\t<details>` + `recommended_command:<手動 squash 案内>`）

#### 使用コマンド

```bash
# §7.7 のコミット完了後
scripts/operations-release.sh record-release-prep-commit --cycle v2.5.2

# §7.12 のレビュー完了後
scripts/operations-release.sh squash-712 --cycle v2.5.2
```

## データモデル概要

### `progress.md` HTML コメント slot 形式

```text
## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=true
completion_gate_ready=true
pr_number=123

<!-- release_prep_commit: a1b2c3d4e5f6789012345678901234567890abcd -->
```

- 既存 grammar v1（key=value）の 3 スロットは独立して維持
- `<!-- release_prep_commit: ... -->` は別系統の正規表現でパース（grammar v1 対象外）
- 空値時は `<!-- release_prep_commit: -->`、行不在時は「未存在」扱い

## 処理フロー概要

### ユースケース 1: §7.7 完了時の commit hash 記録

1. 7.2〜7.6 で progress.md / history / README / CHANGELOG 等を更新
2. 7.7 で `git add` + `git commit` を実行
3. **7.7.1（新規）**: `operations-release.sh record-release-prep-commit --cycle v2.5.2` を実行
4. progress.md の `<!-- release_prep_commit: -->` 行が `<!-- release_prep_commit: <SHA> -->` に更新される
5. `git add operations/progress.md && git commit -m "chore: ... release_prep_commit 記録 ..."` で自動コミット

**関与するコンポーネント**: `cmd_record_release_prep_commit`, `git rev-parse`, `sed`

### ユースケース 2: §7.12 完了 → §7.12.5 Squash 実行 → §7.13

1. 7.12 で PR マージ前レビュー完了（複数 round の修正コミット + 履歴コミットが累積）
2. **7.12.5（新規）**: `operations-release.sh squash-712 --cycle v2.5.2` を実行
3. 判定:
   - `squash_enabled=true` ✓
   - slot から `release_prep_commit` を取得 ✓
   - 対象数 ≥ 1 ✓
4. `git reset --soft <release_prep_commit>` でコミットのみ取り消し（作業ツリー保持）
5. `git commit -m "chore: [v2.5.2] PR レビュー反映 squash 統合"` で単一コミット作成
6. `squash:success:<new_sha>` を出力 → §7.13 へ
7. `git push --force-with-lease` 案内（§7.9 の `verify-git remote-sync=diverged` 検出で既存案内発動）

**関与するコンポーネント**: `cmd_squash_712`, `read-config.sh`, `git reset --soft`, `git commit`, `git reset --hard ORIG_HEAD`（rollback）

### ユースケース 3: Squash 失敗時の rollback

1. 7.12.5 で `git commit` が hook で失敗（exit 1）
2. `git reset --hard ORIG_HEAD` を自動実行 → 作業ツリーが Squash 開始前の状態に戻る
3. `squash:failed:reason=git_op_failed:1` を出力
4. stderr に `error\tsquash_712:commit-failed\t1` + `recommended_command:` で手動 squash 案内
5. exit 1 で Operations Phase を block → ユーザー判断で対応

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 通常 Squash 操作（数コミット）で 1 秒以内
- **対応策**: 標準 git コマンドのみ使用。外部 fetch なし

### セキュリティ

- **要件**: rollback 保証（DR-008 / `git reset --soft + git commit` 失敗時 `git reset --hard ORIG_HEAD`）
- **対応策**: BATS で人工的に commit hook 失敗を作り、rollback 後の作業ツリー一致を検証

### スケーラビリティ

- **要件**: 対象外
- **対応策**: 該当なし

### 可用性

- **要件**: 後方互換性（v2.5.1 以前のサイクル再開時は `release_prep_commit_missing` で skip）
- **対応策**: progress.md に slot 行不在の場合の skip 経路を BATS で検証

## 技術選定

- **言語**: bash 4 以上（既存 operations-release.sh と同じ）
- **テストフレームワーク**: bats-core（既存 `bin/tests/check-test-isolation/` と同形式）
- **依存ライブラリ**: なし（標準 git コマンド + sed + grep のみ）

## 実装上の注意事項

- **DR-008 遵守**: `git reset --soft` 方式を採用。`git rebase` は使わない（コンフリクト系の異常系を排除）
- **DR-009 遵守**: HTML コメント形式 `<!-- release_prep_commit: ... -->` で記録。grammar v1 とは独立系統
- **commit-flow.md 既存契約準拠**: 外部シグナルは `squash:skipped` 固定 / 理由は別 log（`info\treason\t<value>`）
- **check-test-isolation 対応**: 新規 BATS は `cd "$BATS_TEST_TMPDIR"` を `setup` または各 `@test` 冒頭に置く
- **check-bash-substitution 対応**: `bin/*.sh` は対象外、`scripts/*.sh` も対象外。本 Unit 改修ファイルは制約対象外（`$()` 使用可）
- **既存サイクル再開時の安全性**: v2.5.1 以前 progress.md には slot 行不在 → `release_prep_commit_missing` で skip
- **ORIG_HEAD の挙動**: `git reset --soft <commit>` を実行すると `ORIG_HEAD` が直前の HEAD で更新される。後続の `git commit` 失敗時に `git reset --hard ORIG_HEAD` を実行することで Squash 開始前の状態に正確に復旧できる
- **CHANGELOG 反映**: v2.5.2 セクションに追記（計画書 §7）

## 不明点と質問

該当なし。
