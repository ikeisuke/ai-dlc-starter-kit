# 論理設計: Construction Unit 完了処理 step5↔step8 分裂の構造的予防

## 概要

`steps/construction/04-completion.md` / `steps/common/commit-flow.md` / `scripts/write-history.sh` の三層改修により、Unit 完了処理での履歴ファイル staged 漏れを構造的に予防する。`HistoryStagedStatusChecker` ドメインサービスを `check_history_staged_status()` 関数として実装し、`--mode base` 完了フックから呼び出す。

**重要**: この論理設計では**コードは書かず**、構造と検証手段の定義のみを行います。具体的なコード文言は Phase 2 で確定します。

## アーキテクチャパターン

**インライン手続き型 + 専用関数化 + 多重防御**。シェルスクリプト言語特性に合わせ、状態を持たない純関数 `check_history_staged_status()` を `write-history.sh` 単一ファイル内に閉じる。文書層（Markdown）はリンクで実装層を参照し、ドリフト検知は grep クエリで担保する。

## コンポーネント構成

### レイヤー構成

```text
skills/aidlc/
├── steps/construction/04-completion.md         # レイヤー A（文書 / ステップ 5・8 関係明示）
├── steps/common/commit-flow.md                 # レイヤー B（チェックリスト / ドライラン手順）
└── scripts/write-history.sh                    # レイヤー C（実装 / check_history_staged_status）
    ├── main()                                  # 既存
    │   └── --mode base 正常終了フック          # 本 Unit で挿入
    │       └── check_history_staged_status     # 新規関数呼び出し
    └── check_history_staged_status()           # 新規関数定義
        ├── git diff --cached --name-only       # staged 判定
        ├── 判定不能時の警告スキップ            # 後方互換性保護
        └── stderr に warning 契約準拠出力      # warning 契約 SoT
```

### コンポーネント詳細

#### `check_history_staged_status()` 関数（新規定義）

- **責務**: `HistoryStagedStatusChecker` ドメインサービスの実装。引数で受けた履歴ファイルパスの staged 状態を判定し、unstaged 時に warning 契約に従って stderr 出力する
- **依存**: `git diff --cached --name-only`（外部コマンド）、warning 契約（計画書 SoT）
- **シグネチャ**: `check_history_staged_status <filepath>`
- **戻り値**: 常に exit 0（warning 経路でも判定不能経路でも）
- **stdout**: 出力なし
- **stderr**:
  - unstaged 時: `warning: history file unstaged: <絶対パス>\n`
  - staged 時 / 判定不能時: 出力なし

#### 関数内部フロー（pseudo / Round 1 指摘 #1 対応で正規化ステップを明示）

```text
check_history_staged_status(filepath):
  # ステップ 1: filepath の存在ディレクトリからリポジトリルートを取得
  local repo_root
  repo_root=$(git -C "$(dirname "$filepath")" rev-parse --show-toplevel 2>/dev/null)
  toplevel_exit=$?
  if [ "$toplevel_exit" != "0" ] || [ -z "$repo_root" ]:
    # 判定不能（git リポジトリ外 等）→ warning スキップで return 0
    return 0

  # ステップ 2: filepath を repo-root 相対パスに正規化
  # 例: $filepath = /repo/.aidlc/cycles/v2.5.5/history/construction_unit03.md
  #     $repo_root = /repo
  #     $rel_path = .aidlc/cycles/v2.5.5/history/construction_unit03.md
  local rel_path="${filepath#${repo_root}/}"
  if [ "$rel_path" = "$filepath" ]:
    # 接頭辞除去に失敗 → filepath が repo 配下でない
    # 判定不能扱いで warning スキップ（unknown）
    return 0

  # ステップ 3: git diff --cached の出力（既に repo-root 相対）と比較
  local staged_files
  staged_files=$(git -C "$repo_root" diff --cached --name-only -- "$filepath" 2>/dev/null)
  diff_exit=$?

  if [ "$diff_exit" != "0" ]:
    # git diff 失敗 → 判定不能 → warning スキップ
    return 0

  # ステップ 4: 出力に rel_path が完全一致する行が含まれるか判定
  if echo "$staged_files" | grep -Fxq "$rel_path":
    # staged → 警告なし
    return 0
  else:
    # unstaged → stderr 警告（filepath は絶対パスのまま表示）
    echo "warning: history file unstaged: $filepath" >&2
    return 0
```

> **正規化契約（Round 1 指摘 #1 対応）**: `git diff --cached --name-only` の出力は git が repo-root 相対パスを返すため、絶対パスである `$filepath` と直接 `grep -F` できない。比較前に `git rev-parse --show-toplevel` で repo-root を取得し、`$filepath` から接頭辞除去して repo-root 相対 `$rel_path` を導出する。`grep -Fxq "$rel_path"` は **完全一致行**判定（部分マッチ防止）。
>
> **set -e 影響**: シェルスクリプトでは `set -e` 等の有効状態によっては `git ... rev-parse` / `git diff` 失敗で関数が中断される可能性があるため、各 git コマンドは `2>/dev/null` で stderr を捨て、直後に `local toplevel_exit=$?` 等でステータス保持し if 文で明示的に分岐する設計とする。`return 0` は warning 出力後も含めて全分岐で固定。

#### `main()` 関数からの呼び出し位置

`--mode base` 経路の正常終了フック（最終 `echo "history:..."` の直前または直後、`exit 0` の直前）で `check_history_staged_status "$filepath"` を呼び出す。`exit 1`/`exit 2` 経路（エラー終了）からは呼び出さない。

```text
main():
  ... 既存処理 ...
  case "$MODE" in
      base)
          : # 既存: 追加処理なし
          ;;
      ...
  esac

  # 成功出力（既存）
  if is_new_file: echo "history:${filepath}:created"
  else:           echo "history:${filepath}:appended"

  # ↓↓↓ Unit 003 で追加 ↓↓↓
  if [[ "$MODE" == "base" ]]; then
      check_history_staged_status "$filepath"
  fi

  exit 0
```

## インターフェース設計

### スクリプトインターフェース

`write-history.sh` の公開インターフェース（CLI 引数 / stdout 出力契約 / exit code）は本 Unit で変更しない。`stderr 警告のみ追加`。caller が stderr を grep していない限り挙動不変。

### 文書インターフェース（提案 A: 04-completion.md）

ステップ 5（履歴記録）の説明に以下を追加:

```text
**履歴ファイルとコミットの整合性**:

- `write-history.sh` 実行後、生成・更新された履歴ファイルは **必ずステップ 8 の Unit 完了 commit に含める**
- write-history.sh は `--mode base` 完了時に履歴ファイルが unstaged の場合、stderr に warning を出力する（判定主体は scripts/write-history.sh の `check_history_staged_status()`、warning 契約は計画書 § warning 契約 / DR-002 参照）
- ステップ 5 で履歴を作成し、ステップ 8 でコミットする際は `git add` で staged 化することを忘れない
```

ステップ 8（Gitコミット）の説明に以下を追加:

```text
**事前確認**: ステップ 5 で作成された履歴ファイルが staged されていることを `git status` または `git diff --cached --name-only` で確認する。staged されていない場合は `git add` を実行（commit-flow.md の「コミット前確認チェックリスト」を参照）。
```

完了基準に以下を追加:

```text
- 履歴ファイルが Unit 完了 commit に含まれている（step5↔step8 分裂なし）
```

### 文書インターフェース（提案 B: commit-flow.md）

「コミット前確認チェックリスト」に以下の項目を追加:

```text
- [ ] 履歴ファイル staged 確認（**自動判定**: `write-history.sh` が `--mode base` 完了時に stderr 警告を出力。判定主体は `scripts/write-history.sh` の `check_history_staged_status()`、判定方式は DR-002）
```

ドライラン手順を以下の 3 点固定で文書化:

```text
**履歴ファイル staged 確認のドライラン手順**:

(d-1) **write-history 実行**: `bash skills/aidlc/scripts/write-history.sh --mode base ...` を実行し、stderr の warning（`warning: history file unstaged: ...`）の有無を確認
(d-2) **staged 確認**: `git status` または `git diff --cached --name-only` で履歴ファイルが staged 一覧に含まれることを確認
(d-3) **未 staged 時の対応**: `git add <履歴ファイルパス>` を実行し、再度 `git status` で staged を確認
```

### bats テストインターフェース

`tests/write-history-history-staged-warning.bats` を新規作成。3 ケース構造:

```text
@test "write-history --mode base: unstaged → stderr warning + exit 0" {
  setup_test_repo  # git init 済みディレクトリ
  echo "stub" > "$HISTORY_PATH"  # 履歴ファイルを作成（git add しない → unstaged）

  run bash "$WRITE_HISTORY" --mode base --phase construction --cycle test --content "test"
  [ "$status" -eq 0 ]
  printf '%s' "$stderr" | grep -qF "warning: history file unstaged: $HISTORY_PATH"
  ! printf '%s' "$output" | grep -qF "warning"  # stdout に warning なし
}

@test "write-history --mode base: staged → 警告なし + exit 0" {
  setup_test_repo
  echo "stub" > "$HISTORY_PATH"
  git -C "$REPO" add "$HISTORY_PATH"  # staged 化

  run bash "$WRITE_HISTORY" --mode base --phase construction --cycle test --content "test"
  [ "$status" -eq 0 ]
  ! printf '%s' "$stderr" | grep -qF "warning"  # stderr に warning なし
}

@test "write-history --mode base: git リポジトリ外 → 警告スキップ + exit 0" {
  setup_non_git_dir  # git init していないディレクトリ

  run bash "$WRITE_HISTORY" --mode base --phase construction --cycle test --content "test"
  [ "$status" -eq 0 ]
  ! printf '%s' "$stderr" | grep -qF "warning: history file unstaged"
}
```

> **fixture 構築**: bats の `setup()` でテンポラリディレクトリを作成し、`git init` の有無で 2 種類の状態を切り替える。`teardown()` でテンポラリディレクトリを削除。

## 処理フロー概要

### ユースケース 1: 通常運用（履歴を staged してコミット）

1. ユーザーが Unit 完了処理ステップ 5 で `write-history.sh --mode base` 実行
2. write-history.sh が履歴ファイル更新 → stdout に `history:<path>:appended`
3. `check_history_staged_status` が呼ばれ、未 staged を検出 → stderr に `warning: history file unstaged: <path>`
4. ユーザーが warning を見て `git add <履歴ファイル>` を実行
5. ステップ 8 で `git commit` → 履歴ファイル含めて 1 commit に統合

### ユースケース 2: 警告無視シナリオ（旧運用）

1. write-history.sh 実行 → stderr 警告
2. ユーザーが warning を読み飛ばし `git commit` → 履歴ファイルが含まれない
3. 後でユーザーが気付き `git commit --amend` 等で履歴ファイルを追加

→ 旧運用と挙動は変わらないが、レイヤー A / B のチェックリストで気付く確率が向上する

### ユースケース 3: git リポジトリ外実行

1. ユーザーがリポジトリ外で write-history.sh を実行
2. 履歴ファイルは更新される（write-history.sh 自体はリポジトリ依存しない）
3. `check_history_staged_status` の `git diff` が exit 非 0
4. warning スキップで exit 0 維持
5. ユーザーは通常運用通り処理（リポジトリ外用途は本警告対象外）

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: write-history.sh 末尾に `git diff` 1 回追加（Unit 計画 NFR）
- **対応策**: `git diff --cached --name-only -- <path>` は index のみアクセスで O(1) 相当。実時間影響 < 100ms

### セキュリティ

- **要件**: 該当なし（Unit 計画 NFR）
- **対応策**: 履歴ファイルパスは機密情報を含まない（既存 stdout 出力と同レベル）。warning メッセージにも機密情報は含まれない

### 後方互換

- **要件**: write-history.sh の exit code / stdout 出力契約を維持（Unit 計画 NFR）
- **対応策**: `check_history_staged_status()` は常に return 0、stdout に何も出力しない設計とする。stderr 警告は既存挙動に存在しなかったため、stderr を捕捉していない caller には透過的

## 技術選定

- **言語**: Bash 4+（既存 write-history.sh 準拠）
- **テストランナー**: bats（既存 `tests/write-history-*.bats` の構造踏襲）
- **gitコマンド呼び出し**: `git diff --cached --name-only` のみ（`git status` は出力フォーマット依存度が高いため不採用）

## 実装上の注意事項

- **set -e 影響**: `write-history.sh` 全体で `set -e` が有効な場合、`git diff` 失敗で関数中断のリスク。`check_history_staged_status` 内では `local diff_exit; staged_files=$(git diff ... 2>/dev/null) || true; diff_exit=$?` のような明示的ステータス保持を行う
- **空文字 staged_files の扱い**: `git diff --cached --name-only -- "$filepath"` の出力が空の場合、unstaged かつ index に変更なし（=既存ファイル無変更）の両方が含まれる。本 Unit では「unstaged 判定」として一括して warning 出力する（書き込み直後は変更ありの前提）
- **絶対パス比較（Round 1 指摘 #1 対応で確定）**: `git diff` 出力はリポジトリルート相対パスを返すため、`$filepath`（絶対パス）と直接 grep -qF してはならない。比較前に `git rev-parse --show-toplevel` でリポジトリルートを取得し、`$filepath` から repo-root 接頭辞を除去して repo-root 相対パスへ正規化する。比較は `grep -Fxq` で完全一致行判定（部分マッチ防止）。`realpath` は POSIX 非標準のため不採用
- **多重 source ガードとの相互作用**: `write-history.sh` は通常スタンドアロン実行されるが、稀に source される場合の冪等性は既存挙動に依存（本 Unit で変更しない）

### 将来拡張点（Round 1 指摘 #2 対応 / B 層の機械判定化候補）

ドメインモデル §「多重防御の意味」で示したように、A / B 層は同種依存（人間の確認）であり、真の独立性は A 系（人間）と C 系（機械）の 2 系統。B 層をより機械判定に寄せる将来拡張案を以下に記録（**本 Unit のスコープ外、次サイクル以降の検討候補**）:

- **案 B-機械化**: pre-commit hook（`.git/hooks/pre-commit` 相当）で「履歴ファイル更新（working tree 変更あり）の検出 + staged 状態確認」を実施。staged されていない履歴ファイルがある場合は commit を中断し、ユーザーに `git add` を促す
- **トリガー**: 同種事故が再発、または開発者から半自動化の要望がある場合
- **対応案**: `.aidlc/hooks/pre-commit-history-check.sh` 等を新規作成し、リポジトリのセットアップ手順で hook シンボリックリンクを案内
- **スコープ**: 次サイクル以降の minor / chore で対応候補
- **記録先**: 本論理設計 + Unit 003 完了履歴 `history/construction_unit03.md`

本 Unit では起票しない（陳腐化リスク回避、トリガー発火時に再評価）。

## 検証クエリ（Phase 2 完了時に実行）

| 検証項目 | コマンド | 期待結果 |
|---------|---------|---------|
| `check_history_staged_status` 関数定義の存在確認 | `grep -nE "^check_history_staged_status\(\)" skills/aidlc/scripts/write-history.sh` | 1 行ヒット |
| `--mode base` 完了フックからの呼び出し確認 | `grep -nE "check_history_staged_status \"\\\$filepath\"" skills/aidlc/scripts/write-history.sh` | 1 行以上ヒット |
| warning 文言の存在確認 | `grep -nE "warning: history file unstaged" skills/aidlc/scripts/write-history.sh` | 1 行ヒット |
| 04-completion.md 参照リンク | `grep -nE "DR-002\|check_history_staged_status\|warning: history file unstaged" skills/aidlc/steps/construction/04-completion.md` | 1 行以上ヒット |
| commit-flow.md 参照リンク | `grep -nE "DR-002\|check_history_staged_status\|履歴ファイル staged" skills/aidlc/steps/common/commit-flow.md` | 1 行以上ヒット |
| 新規 bats テスト実行 | `bats tests/write-history-history-staged-warning.bats` | 全件 PASS（3 ケース） |
| 既存テスト regression 確認 | `bats tests/aidlc-helpers-zsh-source.bats` 等 | 全件 PASS |

## 不明点と質問（設計中に記録）

[Question] `check_history_staged_status` を関数化する際、write-history.sh のどこに定義するか（main 直前 / main 内 / ファイル冒頭の helper 群）
[Answer] **main 関数の直前（既存 helper 群の末尾）**。write-history.sh は既に `emit_error` 等のヘルパ関数を main 関数の直前に持っているため、同等位置に配置することで既存構造との整合を取る。

[Question] 絶対パス比較で `realpath` を使うか `git rev-parse --show-toplevel` 経由で正規化するか
[Answer] **`realpath` 不採用、git のリポジトリルート相対化を採用**。`realpath` は macOS / Linux で挙動差があり POSIX 非標準。実装では `git -C <dir> rev-parse --show-toplevel` でリポジトリルートを取得し、`$filepath` をリポジトリ相対パスに変換した上で `git diff --cached --name-only` の出力と比較する。失敗時は警告スキップで safety を担保。
