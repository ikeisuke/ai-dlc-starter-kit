# 論理設計: Unit 003 — Operations §7.12.5 squash-712 と write-history operations-round の整合性

## 概要

採用案 **A + B 併用**（ユーザー確定済）に基づき、`write-history.sh --mode operations-round` への auto-commit ロジック追加（案 A）と `operations-release.sh squash-712` への dirty 検出 fail-fast ガード追加（案 B）の論理設計を行う。両改修の連鎖により Issue #677 致命的バグを構造的に解消する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成・インターフェース・処理フローの定義のみを行う。実装は Phase 2 で行う。

---

## アーキテクチャパターン

「コマンド単位の責務追加 + 既存契約踏襲」。新規アーキテクチャ層は導入せず、既存 `write-history.sh` / `operations-release.sh` の関数粒度の責務追加で実現する。レイヤード構造は不変。

選定理由:
- 既存スクリプトの動作契約（出力フォーマット / 終了コード / セッション継続）を破壊しない
- 既存テスト構造（bats）と直接対応する関数粒度で設計することで、テスト追加コストを最小化
- 既存規約踏襲（tab 区切り stderr / `recommended_command:` 案内 / dry-run サポート）

---

## コンポーネント構成

### モジュール構成（既存 + 本 Unit 追加）

```text
skills/aidlc/scripts/
├── write-history.sh
│   ├── main()                                        ← 既存（dispatcher）
│   ├── operations-round 必須引数検証                    ← 既存
│   ├── operations-round セクション append              ← 既存
│   ├── _commit_operations_round_history()             ← 本 Unit 追加（案 A）
│   └── check_history_staged_status()                  ← 既存（--mode base 経路のみ）
├── operations-release.sh
│   ├── cmd_squash_712()                              ← 既存
│   │   ├── Step 1: squash_enabled 取得                ← 既存
│   │   ├── __squash_712_check_history_clean()         ← 本 Unit 追加（案 B）
│   │   ├── Step 2: release_prep_commit パース          ← 既存
│   │   ├── Step 3: 対象 commit 数判定                  ← 既存
│   │   ├── Step 4: git reset --soft                  ← 既存
│   │   └── Step 5: git commit                        ← 既存
│   └── ...

tests/
├── write-history-modes.bats                          ← 既存（拡張）
├── write-history-operations-round-commit.bats        ← 本 Unit 新規（案 A）
├── operations-release-squash712-dirty-history.bats   ← 本 Unit 新規（案 B）
└── operations-release-squash712-integration.bats     ← 本 Unit 新規（A+B 連鎖検証）

skills/aidlc/steps/operations/
└── operations-release.md                             ← 本 Unit 編集（§7.12 / §7.12.5 手順 SoT 更新）

CHANGELOG.md                                          ← 本 Unit 編集
```

### コンポーネント詳細

#### コンポーネント 1: `_commit_operations_round_history()`（案 A / 新規）

- **所属**: `write-history.sh`
- **責務**: `--mode operations-round` の append 完了後に履歴ファイルを git add + commit する
- **依存**: `git`, `emit_error`
- **公開インターフェース**: 内部関数（同スクリプト内のみ呼び出し）
- **配置**: `main()` 内の append 完了処理（行 1071 付近、`echo "history:${filepath}:appended"` 直後）に、既存 `--mode base` 経路の `check_history_staged_status` 呼び出しと同様の条件分岐ブロックとして追加

#### コンポーネント 2: `__squash_712_check_history_clean()`（案 B / 新規）

- **所属**: `operations-release.sh`
- **責務**: `cmd_squash_712()` の Step 1（squash_enabled 取得）と Step 2（release_prep_commit パース）の間で、`history/operations.md` の dirty 状態を検出する
- **依存**: `git status --porcelain`
- **公開インターフェース**: 内部関数（`cmd_squash_712()` からのみ呼び出し）
- **配置**: `cmd_squash_712()` 内、行 952 付近（Step 1 完了直後・Step 2 開始前）

#### コンポーネント 3: `--no-commit` フラグ（案 A / 既存変更）

- **所属**: `write-history.sh` 引数パース
- **責務**: auto-commit を skip し、append のみの旧挙動を維持
- **依存**: なし
- **配置**: 既存引数パース（`main()` 内 `while [[ $# -gt 0 ]]; do case "$1" in ...`）に新規 case 追加

---

## インターフェース設計

### スクリプトインターフェース設計

#### `write-history.sh`（拡張）

##### 概要

既存責務に加え、`--mode operations-round` 経路で append 後の auto-commit を行う。

##### 追加引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--no-commit` | 任意（新規） | `--mode operations-round` のみで意味を持つ。指定時 auto-commit を skip し append のみ実行（旧挙動維持） |

`--no-commit` のスコープ:
- `--mode operations-round` 指定時のみ意味を持つ
- それ以外の mode で指定された場合: **stderr に warning（exit 0 維持）を出力**（Round 1 MEDIUM 指摘 #1 対応）
  - 出力: `warning: --no-commit is only effective with --mode operations-round (got mode: <mode>); flag ignored`
  - 動作: フラグは無視するが誤指定は明示通知（運用ミス検知）。エラー（exit 1）にはしない（将来拡張余地のため）

##### 追加成功時出力

通常経路（append + auto-commit 成功時）:

```text
history:<filepath>:appended
history-commit:<sha>:operations-round-round-<round>
```

`--no-commit` 経路（既存と同一、append のみ）:

```text
history:<filepath>:appended
```

dry-run + `--mode operations-round` + auto-commit 経路:

```text
history:<filepath>:would-append
history-commit:would-commit:operations-round-round-<round>
```

- 終了コード: 既存と同じ（`0` = 成功）
- 出力先: stdout

##### 追加エラー時出力（auto-commit 失敗時）

**設計修正（Round 1 HIGH 指摘 #1 対応）**: write-history.sh の既存 `emit_error` 契約（`scripts/lib/validate.sh:19`）に従い、出力フォーマットを既存と一貫させる:

- 既存 `emit_error` の動作: `error:<code>:<message>` を **stdout** に出力 + 同内容を **stderr** にもミラー（`echo "error:${payload}" 1>&2` 既存パターン）
- 本 Unit の auto-commit 失敗時もこの既存契約を踏襲する（tab 区切り stderr 単独出力は**採用しない**）

```text
error:failed-auto-commit-operations-round:<reason>
```

- 終了コード: `1`（既存 `emit_error` 経路と整合）
- 出力先: stdout + stderr（既存 `emit_error` パターン踏襲、consumer パーサ破壊リスク回避）
- `<reason>` には git の stderr 出力先頭行を 1 行に正規化して埋め込む（複数行は半角空白で連結）

**index rollback の安全化（Round 1 HIGH 指摘 #2 対応）**: `git reset HEAD -- <filepath>` 一律巻き戻しは、実行前から同ファイルに存在した staged 差分まで巻き戻して index を破壊するリスクがある。本 Unit の rollback 設計は以下のとおり安全化する:

1. **事前 staged 状態 check**: auto-commit 開始前に `git diff --cached --name-only -- <filepath>` で `<filepath>` の事前 staged 状態を判定（同経路は既存 `check_history_staged_status` と同様の git -C リポジトリチェック付き）
2. **事前 staged の場合**: 本 Unit の auto-commit を **skip** し、append のみで処理を完了する。stderr に warning（`warning: history file already staged: <絶対パス>`、exit 0 維持）を出力。呼び出し側が既に staged 管理中の前提として尊重する
3. **事前 unstaged の場合**: 通常経路で `git add` + `git commit`。失敗時の rollback は **`git reset HEAD -- <filepath>`** で安全（事前は unstaged のため、リセット対象は本 Unit が add した分のみ）
4. **git リポジトリ外の場合（Round 1 HIGH 指摘 #3 対応）**: 既存 `check_history_staged_status` と同様 `git -C <dir> rev-parse --show-toplevel` で git 配下判定し、git 外実行時は auto-commit を **skip**（stderr に `warning: not inside a git repository, skipping auto-commit` 出力、exit 0 維持）。これにより非 git テスト環境（既存 `write-history-history-staged-warning.bats` case (c) 等）の挙動を破壊しない

この 3 ガードの組み合わせにより:
- 通常運用（unstaged の history を append）: auto-commit が動く
- 事前 staged 運用（呼び出し側が手動 commit したい）: skip + warning（後方互換性）
- 非 git 環境（テスト等）: skip + warning（既存挙動踏襲）

##### 使用コマンド（既存 + 本 Unit）

```bash
# 既存（auto-commit あり / デフォルト）
bash scripts/write-history.sh --cycle vX.X.X --phase operations --mode operations-round \
  --round 1 --findings 0 --critical 0 --high 0 --medium 0 --low 0 \
  --resolved-count 0 --deferred-count 0 \
  --content-file /tmp/content.txt

# 新規（--no-commit opt-out / 旧挙動維持）
bash scripts/write-history.sh --cycle vX.X.X --phase operations --mode operations-round \
  --no-commit \
  --round 1 --findings 0 --critical 0 --high 0 --medium 0 --low 0 \
  --resolved-count 0 --deferred-count 0 \
  --content-file /tmp/content.txt
```

#### `operations-release.sh squash-712`（拡張）

##### 概要

既存責務に加え、起動時に `history/operations.md` の dirty 状態を検出し fail-fast する。

##### 引数

既存と同一（`--cycle <CYCLE>` 必須、`--dry-run` 任意）。**新規引数なし**（escape hatch 不提供方針）。

##### 追加成功時出力

dirty 検出ガード合格時は既存出力と完全同一。新規出力なし。

##### 追加エラー時出力（dirty 検出時）

```text
error	squash-712:uncommitted-history	<path>
recommended_command:git add <path> && git commit -m "<履歴記録メッセージ>" の後に <squash-712 起動コマンド> を再実行してください
squash:failed:reason=dirty_history
```

**Round 1 MEDIUM 指摘 #2 対応**: dirty 検出時点で round 番号情報は持たないため、推奨コマンド文言に round 番号入りの固定 commit message を含めない。代わりに `<履歴記録メッセージ>` プレースホルダーに留め、運用者が文脈に応じて message を決定する設計とする。

- 終了コード: `1`（既存 `git_op_failed` 系の exit 1 と整合）
- 出力先: stderr（error / recommended_command 行）、stdout（`squash:failed:reason=dirty_history` 行 = 既存 `squash:failed:reason=...` パターン踏襲）
- dry-run 時もこのガードは実行（実行前検証目的、既存 dry-run の return 0 経路より前で stop）

##### 使用コマンド（既存と同一）

```bash
bash scripts/operations-release.sh squash-712 --cycle vX.X.X
bash scripts/operations-release.sh squash-712 --cycle vX.X.X --dry-run
```

#### integration テスト用スクリプト構造

##### 一時 git リポジトリ生成（既存パターン踏襲）

```text
$TEST_TMPDIR/
├── repo/
│   ├── .git/
│   ├── .aidlc/
│   │   ├── config.toml                # project.name 等の最小 stub
│   │   ├── operations.md              # 任意（バージョン情報 stub）
│   │   └── cycles/v2.6.2/
│   │       ├── history/operations.md  # 初期空ファイル
│   │       └── operations/progress.md # release_prep_commit slot 含む
│   └── (任意の追加ファイル)
└── content.txt                        # write-history --content-file 用
```

`release_prep_commit` slot のフォーマット（既存契約）:

```text
<!-- release_prep_commit: <40 桁 SHA> -->
```

##### integration 検証ステップ

1. 初期 commit 作成（`.aidlc/config.toml` + 初期ファイル群）
2. `release_prep_commit` の SHA を取得し `progress.md` slot に書き込み、追加 commit（このコミットを `RELEASE_PREP_SHA` として記録）
3. 修正コミット 1 件以上（テスト用任意ファイル）
4. `write-history.sh --mode operations-round` を呼ぶ（auto-commit 経路）
5. `operations-release.sh squash-712 --cycle v2.6.2` を実行
6. 観測点アサート:
   - `git log <RELEASE_PREP_SHA>..HEAD --oneline` の行数 = 1
   - `git show --stat HEAD` 出力に `history/operations.md` が含まれる

`--no-commit` 経路の検証ケース:

1. ステップ 4 で `--no-commit` を指定
2. ステップ 5 で `squash-712` 実行 → fail-fast（exit 1 / `squash:failed:reason=dirty_history`）を期待

---

## データモデル概要

### ファイル形式

#### `.aidlc/cycles/<cycle>/history/operations.md`（既存）

- **形式**: Markdown（append-only）
- **追記内容**: `operations-round` モードでは `## 補足（round <N> AI レビュー）` セクション + 集計テーブル（既存契約）
- **本 Unit での変更**: ファイル内容自体に変更なし。auto-commit のタイミング追加のみ

#### `.aidlc/cycles/<cycle>/operations/progress.md`（既存）

- **形式**: Markdown + HTML コメント独立スロット
- **`release_prep_commit` slot**: `<!-- release_prep_commit: <40 桁 SHA> -->`（既存）
- **本 Unit での変更**: なし

---

## 処理フロー概要

### ユースケース 1: §7.12 レビュー反映 → write-history → squash-712（A+B 通常経路）

**ステップ**:

1. `§7.12` codex review 実施・指摘対応コミット
2. `write-history.sh --mode operations-round --round N ...` 呼び出し
3. write-history 内部: append → `_commit_operations_round_history()` が `git add` + `git commit`
4. stdout に `history:<path>:appended` + `history-commit:<sha>:operations-round-round-N`
5. `operations-release.sh squash-712 --cycle <cycle>` 呼び出し
6. squash-712 内部: Step 1（squash_enabled 取得）→ **`__squash_712_check_history_clean()`** 実行（合格、dirty 差分なし）→ Step 2-5（通常経路）
7. 結果: `git log <release_prep_commit>..HEAD` が 1 commit（squash 統合 commit、history 差分を含む）

**関与するコンポーネント**: `write-history.sh`, `_commit_operations_round_history()`, `operations-release.sh`, `__squash_712_check_history_clean()`, `cmd_squash_712`

### ユースケース 2: `--no-commit` opt-out 経路（案 B が検知層として機能）

**ステップ**:

1. `§7.12` codex review 実施・指摘対応コミット
2. `write-history.sh --mode operations-round --no-commit --round N ...` 呼び出し
3. write-history 内部: append のみ（auto-commit skip）→ stdout に `history:<path>:appended`
4. `operations-release.sh squash-712 --cycle <cycle>` 呼び出し
5. squash-712 内部: Step 1 → **`__squash_712_check_history_clean()`** 検出 → exit 1 + `squash:failed:reason=dirty_history`
6. ユーザーが推奨コマンドに従って `git add` + `git commit` → 再実行 → 通常経路へ復帰

**関与するコンポーネント**: 同上

### ユースケース 3: write-history.sh 経由でない append 漏れ（案 B が検知層として機能）

**ステップ**:

1. 何らかの理由（手動編集 / 他スクリプト経由）で `history/operations.md` に unstaged 差分が残った
2. `operations-release.sh squash-712 --cycle <cycle>` 呼び出し
3. squash-712 内部: `__squash_712_check_history_clean()` 検出 → exit 1 + 推奨コマンド案内
4. ユーザーが復旧

**関与するコンポーネント**: `__squash_712_check_history_clean()`, `cmd_squash_712`

---

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 既存スクリプトの実行時間に著しい悪化を生じない
- **対応策**:
  - 案 A の `git add` + `git commit` は O(1) 程度の追加コスト（1 ファイルの commit）
  - 案 B の `git status --porcelain -- <path>` は対象 1 ファイル指定で軽量

### セキュリティ

- **要件**: 不正なパス注入を防止する
- **対応策**:
  - 案 A: filepath は既存 append 経路で生成された値を再利用（再構築しない）。引数からの直接注入経路なし
  - 案 B: `<cycle>` は既存 `--cycle` 引数バリデーションを通過した値を使用。`git status --porcelain -- "<path>"` は `--` 区切りで path treated as literal（git 仕様）

### 可搬性

- **要件**: macOS / Linux 双方の bash で動作
- **対応策**: `git status --porcelain` / `git add` / `git commit` は POSIX レベルの git 標準コマンド。OS 依存なし

### 後方互換性

- **要件**:
  - 案 A: `--no-commit` で既存 append-only 挙動を完全保持
  - 案 B: dirty 状態でない正常運用は影響を受けない
- **対応策**:
  - 案 A: `--no-commit` 未指定がデフォルトで auto-commit、指定時 skip。デフォルト挙動の変更により「過去に append のみで運用していた consumer」は新規 commit が増えるが、AI-DLC フロー上はむしろ正しい挙動。`--no-commit` が緊急時 opt-out 経路
  - 案 B: 通常運用では auto-commit 経路で dirty 状態にならないため fail-fast は発火しない

### テスタビリティ

- **要件**: 採用案ごとの専用 AC が bats / integration テストで自動検証可能
- **対応策**:
  - 案 A: `write-history-operations-round-commit.bats` で「auto-commit / `--no-commit` opt-out / dry-run」3 ケース網羅
  - 案 B: `operations-release-squash712-dirty-history.bats` で以下 4 ケース網羅（Round 1 LOW 指摘 #1 対応で `--dry-run + dirty` を独立ケース化）:
    - dirty（実行 / exit 1）
    - clean（実行 / 通常経路継続）
    - `--dry-run + dirty`（実行 / exit 1、回帰耐性確保）
    - `--dry-run + clean`（実行 / dry-run 出力経路継続）
  - A+B 連鎖: `operations-release-squash712-integration.bats` で normal / opt-out 経路を網羅

---

## 技術選定

- **言語**: Bash（既存スクリプトと同一）
- **既存依存**: git, bash, POSIX `wc` 等（既存）
- **テスト**: bats（既存）
- **lint**: shellcheck / shellharden（既存）

---

## 実装上の注意事項

### 規約踏襲

- 既存 `operations-release.sh` の `set +e ... set -e` パターン（exit code 保持）を維持
- 機械可読出力は tab 区切り（`error\t<code>\t<context>`）形式
- `recommended_command:` プレフィックスでの案内（既存規約）
- `--dry-run` ではすべての副作用を skip し `would-*` ログのみ出力

### コマンド置換 `$(...)` 禁止

CLAUDE.md / `.aidlc/rules.md` の規約に従い、新規実装で `$(...)` を使用しない。既存スクリプトでは `$(...)` 利用箇所が残っているが、本 Unit の追加分は `read` / 一時変数経由で対応する。

### ドッグフーディング特殊処理禁止

採用案ロジックは consumer プロジェクトでも同一動作。自リポジトリ判定による分岐は導入しない（CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」原則準拠）。

### auto-commit の失敗時挙動

`git add` 成功・`git commit` 失敗時は `git reset HEAD -- <filepath>` で index を巻き戻す（既存 `cmd_squash_712` の rollback パターンに倣う）。テスト時の冪等性を保護する。

### dirty 検出範囲の限定

案 B の dirty 検出対象は `.aidlc/cycles/<cycle>/history/operations.md` のみ（path argument で限定）。他のファイル（成果物 / progress.md / .git 関連）は対象外（§7.13 pre-flight check が別途検出する責務）。

### 手順書 SoT 更新

`steps/operations/operations-release.md` §7.12 完了条件記述に「§7.12.5 への遷移は write-history.sh の auto-commit 経路（デフォルト）か手動 commit のいずれかが必須」と明文化。§7.12.5 起動時の前提として案 B fail-fast の存在を脚注として記録。

---

## 不明点と質問（設計中に記録）

[Question] `_commit_operations_round_history()` の commit message に round 番号を含める方針で確定するか？ `--round` は 1-5 整数で既存契約あり、参照可能。

[Answer] 確定。commit message フォーマット: `chore: [<cycle>] §7.12 レビュー round <round> 履歴記録`。round 番号は引数 `--round` から導出。

[Question] dirty 検出で `git status --porcelain -- <path>` を使うが、staged のみ / unstaged のみ / mixed の場合分けは必要か？

[Answer] 不要。任意の非空出力（staged / unstaged / 両方）すべて dirty として扱う。検知の単純性とユーザー対応の単純性（「`git add` + `git commit` してから再実行」案内）を優先。

[Question] `--no-commit` を `--mode operations-round` 以外で指定した場合、警告 / エラー / 無視のどれが正しいか？

[Answer] **stderr warning + exit 0**（Round 1 MEDIUM #1 / Round 2 で確定）。フラグそのものは無視するが、誤指定の検知のため warning を必ず出す。エラー（exit 1）にはしない（将来拡張余地のため）。具体的フォーマットは「コマンド 1: write-history.sh `--mode operations-round`」セクション内 `--no-commit` のスコープ記述を SoT とする。`--mode operations-round` のみで意味を持つことは help テキストにも明記する。

[Question] integration テストで `gh` CLI への依存は発生するか？

[Answer] 発生しない。本 Unit の検証範囲は local git 操作のみ（`git log` / `git show --stat`）。GitHub API は不要。
