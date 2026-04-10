# 論理設計: Unit 005 Tier 2 施策の統合

## 概要

Unit 005 のドメインモデル（`OperationsReleaseOrchestrator` と `ReviewRoutingDecision` の 2 領域）に基づき、実装レベルの論理設計を行う。本 Unit は純粋リファクタリングであり、新機能は追加しない。したがって論理設計の主眼は:

1. **ファイル構造と責務境界の固定**: 新設 2 ファイル + 更新 10 ファイルの変更範囲と内容を事前確定する
2. **一方向依存の担保**: `review-routing.md` ↛ `review-flow.md` の依存方向を物理的に担保する配置
3. **動作等価性の保証**: 整理前後で `gh` / `git` / 既存スクリプトの呼び出し引数、およびルーティング判定結果が完全一致することを設計段階で保証する

本論理設計では**コードは書かず**、構造と契約のみを定義する。

---

## 領域 1: operations-release スクリプト化

### ファイル配置

```text
skills/aidlc/
├── scripts/
│   └── operations-release.sh              (新規)
└── steps/
    └── operations/
        ├── index.md                        (更新: §1 の operations.02-deploy 行に注記追加)
        ├── 02-deploy.md                    (更新: ステップ7参照を併記形式に変更)
        └── operations-release.md           (更新: 13 節 → 6 節 markdown 残存 + 5 サブコマンド呼び出し参照)
```

### コンポーネント 1: `operations-release.sh`（ディスパッチャ）

#### コンポーネント構成

```text
operations-release.sh
├── main(argv)                              # エントリポイント + サブコマンドディスパッチ
├── print_help()                            # 全体ヘルプ
├── print_help_<subcommand>()               # 各サブコマンドの個別ヘルプ
├── resolve_script_dir()                    # $0 からスクリプトディレクトリを解決
├── cmd_version_check(args)                 # サブコマンド: version-check
├── cmd_lint(args)                          # サブコマンド: lint
├── cmd_pr_ready(args)                      # サブコマンド: pr-ready
├── cmd_verify_git(args)                    # サブコマンド: verify-git
└── cmd_merge_pr(args)                      # サブコマンド: merge-pr
```

#### インターフェース契約（CLI）

```text
operations-release.sh <subcommand> [options...]

Subcommands:
  version-check    Operations Phase ステップ 7.1 - バージョン確認（iOS 分岐 + suggest-version.sh）
  lint             Operations Phase ステップ 7.5 - run-markdownlint.sh 実行
  pr-ready         Operations Phase ステップ 7.8 - ドラフト PR Ready 化 + PR 本文更新
  verify-git       Operations Phase ステップ 7.9-7.11 - コミット漏れ / リモート同期 / main 差分チェック
  merge-pr         Operations Phase ステップ 7.13 - PR マージ実行

Global options:
  --help, -h       ヘルプを表示
  --dry-run        実際の副作用を抑止し、呼び出される引数のみを stdout に出力
```

#### 終了コード・出力契約の基本方針【重要】

`operations-release.sh` は**既存スクリプトの stdout / exit code を透過するパススルーラッパー**として設計する。正規化（exit code の 0/1/2 への変換等）は行わない。理由:

- 既存スクリプト（`validate-git.sh` / `run-markdownlint.sh` / `pr-ops.sh` / `suggest-version.sh` / `ios-build-check.sh`）は本 Unit のスコープ外で変更できない
- 現行実装では各スクリプトの契約が独立している:
  - `validate-git.sh uncommitted` / `remote-sync`:
    - **通常ケース**: exit 0 + stdout に `status:ok` / `status:warning` を出力（warning も exit 0）
    - **ハードエラー**: `git status` / `git fetch` / upstream 解決 / `git log` 失敗時は `return 2`（exit code 2）+ stdout に `status:error`
    - **サブコマンド誤り**: `exit 1`
  - `run-markdownlint.sh`: exit code 0=成功 / 1=エラー、markdownlint 出力を透過
  - `pr-ops.sh merge`: exit code 0=成功 / 1=エラー、結果を stdout に `merged` / `auto-merge-set` / `error:<code>` 形式で伝達
  - `pr-ops.sh find-draft` / `ready` / `get-related-issues`: 各自の契約を持つ
- これらを 0/1/2 に再マッピングすると、呼び出し側（`operations-release.md` 手順）が**既存と新規で異なる契約を読む必要**が生じ、純粋リファクタリング制約に反する

**透過の実装**:

- 各サブコマンドは既存スクリプト呼び出しの終了コードをそのまま `exit` する（`cmd; exit $?`）
- 既存スクリプトの stdout は加工せずそのまま透過する
- サブコマンド自身が追加する出力（例: `verify-git` の集約結果）は既存出力の**後**に接頭辞付きで追加する（例: `verify-git:summary:uncommitted=warning:remote-sync=ok:default-branch=ok`）
- `--dry-run` 時のみ、実行せずに呼び出そうとしたコマンドを `would run: ...` 形式で stdout に出力し `exit 0`

**検証項目への追加**: 動作等価性検証に以下を追加する（Phase 2 の検証手順で明記）:

- **stdout 形式**: 既存スクリプトの stdout 出力が `operations-release.sh` 経由で透過されていること
- **warning/error の伝播**: `validate-git.sh` の `status:warning` 等が呼び出し側に届くこと
- **終了コード**: 既存スクリプトの終了コードがそのまま `operations-release.sh` の終了コードとなること

#### サブコマンド別インターフェース

##### cmd_version_check

```text
operations-release.sh version-check [--dry-run] [--ios-skip-marketing-version]

inputs:
  --ios-skip-marketing-version    Inception 履歴に「iOSバージョン更新実施」記録がある場合に
                                  AI エージェントが付与する informational フラグ。
                                  本スクリプト内部挙動は変更せず（オプションは受け付けるのみ）、
                                  `ios-build-check.sh` をそのまま呼び出す。
                                  MARKETING_VERSION の現行値確認は markdown 手順側の責務。

behavior:
  1. .aidlc/config.toml から project.type を取得（read-config.sh を利用、dry-run でも実行）
  2. project.type == "ios" の場合: ios-build-check.sh を呼び出し stdout / exit code を透過
  3. project.type != "ios"（general 扱い）の場合: suggest-version.sh を呼び出し stdout / exit code を透過

iOS 履歴参照の責務境界:
  - Inception 履歴（`.aidlc/cycles/{CYCLE}/history/inception.md` 等）から「iOSバージョン更新実施」記録を
    読み取る処理、および MARKETING_VERSION 現行値の表示は **markdown 側（operations-release.md）の責務** とする
  - スクリプト側は `--ios-skip-marketing-version` フラグをシグナルとして受け付けるだけで、スクリプト内の分岐動作には
    影響させない（削除可能な informational オプション。将来の拡張余地として残す）
  - 実装整合追従: コード生成後レビューで `--cycle` オプションが未使用のため削除、MARKETING_VERSION 表示はスクリプト
    側ではなく markdown 側の責務と確認（本 Unit での実装と整合）

出力: 既存スクリプト（ios-build-check.sh / suggest-version.sh）の stdout をそのまま透過
exit code: 既存スクリプトの終了コードをそのまま透過

delegated_scripts:
  - ios-build-check.sh (ios 時)
  - suggest-version.sh (general 等)
```

##### cmd_lint

```text
operations-release.sh lint [--dry-run] [--cycle <CYCLE>]

inputs:
  --cycle <CYCLE>   サイクル名

behavior:
  1. run-markdownlint.sh <CYCLE> を呼び出し、stdout を透過
  2. 終了コードを呼び出し元にそのまま透過（0=成功 / 非 0=エラー）

出力: run-markdownlint.sh の stdout をそのまま透過（`markdownlint:success` / `markdownlint:error` / `markdownlint:skipped` 等）
exit code: run-markdownlint.sh の終了コードをそのまま透過

delegated_scripts:
  - run-markdownlint.sh
```

##### cmd_pr_ready

```text
operations-release.sh pr-ready [--dry-run] [--cycle <CYCLE>] [--pr <PR_NUMBER>] [--body-file <PATH>]

inputs:
  --cycle <CYCLE>       サイクル名
  --pr <PR_NUMBER>      既知 PR 番号（省略時は pr-ops.sh find-draft で検索）
  --body-file <PATH>    PR 本文ファイル（markdown 側でテンプレート生成済みを想定）

behavior:
  1. pr-ops.sh get-related-issues <CYCLE> を呼び出し、stdout を透過
  2. --pr 未指定なら pr-ops.sh find-draft を呼び出し、その出力（PR 番号 or 空）を利用
  3. ドラフト PR が見つかった場合:
     a. pr-ops.sh ready <PR_NUMBER> を呼び出し、stdout と exit code を透過
     b. --body-file 指定時は gh pr edit <PR_NUMBER> --body-file <PATH> を呼び出し、透過
  4. ドラフト PR が見つからない場合:
     a. --body-file 未指定 → stderr に `pr-ready:error:body-file-required` を出力し、exit 1（markdown 側に本文生成を要求）
     b. --body-file 指定 → gh pr create --base main --title "<CYCLE>" --body-file <PATH> を呼び出し、透過
     c. --draft フラグは**付けない**（現行 operations-release.md L108 と完全一致）
  5. --dry-run 時: 上記コマンドを `would run: ...` 形式で stdout に出力し exit 0

出力: 各ステップで呼び出された既存スクリプト・gh コマンドの stdout をそのまま透過
exit code:
  - 最終ステップの終了コードを透過
  - --body-file 必須エラーのみ例外的に exit 1 を返す（透過ではない）

delegated_scripts:
  - pr-ops.sh (get-related-issues, find-draft, ready)
  - gh (pr edit, pr create)
```

##### cmd_verify_git

```text
operations-release.sh verify-git [--dry-run] [--default-branch <BRANCH>]

inputs:
  --default-branch <BRANCH>   デフォルトブランチ名（省略時は git remote show origin から取得、失敗時は main → master）

behavior:
  1. validate-git.sh uncommitted を呼び出し、stdout を透過し、終了コードを記録（$uncommitted_ec）
     - exit 0 + stdout に `status:ok` or `status:warning` → 続行
     - exit 2 + stdout に `status:error` → ハードエラーとして扱い、$uncommitted_ec=2 を記録するが続行（remote-sync の結果も呼び出し元に届けるため）
  2. validate-git.sh remote-sync を呼び出し、stdout を透過し、終了コードを記録（$remote_sync_ec）
     - 同様に exit 0 / exit 2 を記録
  3. 【7.11 推奨チェック、障害分離】git merge-base --is-ancestor origin/<DEFAULT_BRANCH> HEAD を評価する。
     - fetch 失敗時・default branch 取得失敗時は**スキップして続行**（現行 operations-release.md L149 の
       「fetch 失敗 → スキップして続行」を忠実に維持）。exit code には影響させない
     - 成功（up-to-date） → `default-branch:ok`
     - 失敗（behind） → `default-branch:warning`（merge/rebase 推奨）
     - fetch 失敗 → `default-branch:skipped`
  4. 3 つの結果を集約サマリとして stdout の**末尾**に追加（既存スクリプトの透過出力の後）:
     `verify-git:summary:uncommitted=<status>:remote-sync=<status>:default-branch=<status>`
  5. 終了コード: max($uncommitted_ec, $remote_sync_ec) を返す（7.11 は exit code に影響しない）
     - 両方とも exit 0 → verify-git exit 0
     - いずれかが exit 2 → verify-git exit 2（validate-git.sh のハードエラー契約を透過）
  6. --dry-run 時: 呼び出しコマンドを `would run: ...` 形式で stdout に出力し exit 0

障害分離の原則:
  - 7.9（uncommitted）と 7.10（remote-sync）は validate-git.sh の現行契約（通常は exit 0 + status:*、
    ハードエラーは exit 2 + status:error）をそのまま透過する。呼び出し元は stdout の `status:*` と
    終了コードの両方で結果を判定できる
  - 7.11（default branch 差分）は **推奨チェック**であり、fetch 失敗は error ではなく `skipped` として扱い、
    呼び出し元が続行可能な状態を保つ（exit code に影響させない）
  - verify-git は 7.9/7.10 のハードエラーは exit 2 で伝達するが、7.11 の失敗は集約サマリの `default-branch:skipped` のみで伝達する

出力:
  - validate-git.sh uncommitted の stdout（透過）
  - validate-git.sh remote-sync の stdout（透過）
  - `verify-git:summary:...` 形式の集約サマリ（追加）

exit code:
  - validate-git.sh 2 回の max 終了コード（0 または 2）
  - 7.11 の git merge-base 失敗は exit code に影響しない（skipped 扱い）

delegated_scripts:
  - validate-git.sh (uncommitted, remote-sync)
  - git (merge-base, remote)
```

##### cmd_merge_pr

```text
operations-release.sh merge-pr [--dry-run] --pr <PR_NUMBER> --method <merge|squash|rebase>

inputs:
  --pr <PR_NUMBER>   必須。マージ対象 PR 番号
  --method <method>  必須。マージ方法（merge / squash / rebase、ask は markdown 側で事前解決）

behavior:
  1. --method に応じて pr-ops.sh merge を呼び出す:
     - merge  → pr-ops.sh merge <PR_NUMBER>
     - squash → pr-ops.sh merge <PR_NUMBER> --squash
     - rebase → pr-ops.sh merge <PR_NUMBER> --rebase
  2. pr-ops.sh の stdout と exit code をそのまま透過
  3. --dry-run 時: 呼び出しコマンドを `would run: ...` 形式で stdout に出力し exit 0

出力: pr-ops.sh merge の stdout をそのまま透過（`merged` / `auto-merge-set` / `error:<code>` 等）
exit code: pr-ops.sh merge の終了コードをそのまま透過

エラー種別別の対処案内:
  - pr-ops.sh の stdout に含まれるエラーコード（`error:auto-merge-not-enabled` / `error:checks-failed` /
    `error:permission-denied` / `error:not-mergeable` / `error:review-required` 等）の解釈と対処は
    **markdown 側（operations-release.md）の責務**とする
  - 本サブコマンドは純粋な透過ラッパーであり、エラーメッセージの整形・対処案内は行わない

delegated_scripts:
  - pr-ops.sh (merge)
```

#### `$()` コマンド置換の扱いと検証手法

**背景**: 現行 `bin/check-bash-substitution.sh` は **`*.md` 内の fenced bash ブロック**のみを検査対象とし、`.sh` ファイル自体は検査しない（スクリプトソース: `DEFAULT_TARGET_PATTERN="*.md"`）。したがって、`operations-release.sh` の実装内で `$(...)` を使用しても CI 検知されない。

**本 Unit の設計方針**: 既存 `.sh` スクリプト（`pr-ops.sh` 等）は `$()` を自由に使用しており、`operations-release.sh` も同じ実装スタイルで構わない。理由:

- `.sh` ファイル内の `$()` は Claude Code の安全ヒューリスティクスの対象外（確認ダイアログが出るのは対話セッション内で bash を実行する時のみ）
- `.md` 内の fenced bash ブロックは AI エージェントがコピペ実行する可能性があるため制限が必要だが、実行可能な `.sh` はその対象外
- 既存スクリプト（`validate-git.sh` の `files=$(git status ...)` 等）と実装スタイルを揃える方が保守性が高い

**実装パターン**（既存スクリプトと整合）:

- **コマンド出力の変数代入**: `var=$(cmd)` を許容する（`.sh` ファイル内のため検査対象外）
- **エラー処理**: `cmd || return $?` / `set -euo pipefail` を活用
- **サブコマンドディスパッチ**: `case "$1" in ...` パターンで分岐（既存 `validate-git.sh` / `pr-ops.sh` と同じ）
- **`--dry-run` の実装**: グローバル変数 `DRY_RUN=0` を初期化し、オプション解析時に `DRY_RUN=1` に設定。各コマンド呼び出し箇所で `if [ "$DRY_RUN" = "1" ]; then echo "would run: ..."; else cmd; fi` の形式で分岐

**検証手法**: `operations-release.sh` の品質は以下で担保する（`check-bash-substitution.sh` は `.md` 検査のみのため使用しない）:

- **`bash -n skills/aidlc/scripts/operations-release.sh`**: 構文チェック（パースエラー検出）
- **`shellcheck` が利用可能なら実行**: 静的解析（プロジェクトの既存スクリプトでも任意実行）
- **`--dry-run` の実行テスト**: 全サブコマンドを `--dry-run` で実行し、想定どおりの `would run: ...` 出力を得ることを確認
- **実際のサブコマンド実行**: セーフな環境（テスト用ブランチ等）で各サブコマンドを実際に実行し、stdout / exit code の透過を確認

### コンポーネント 2: `operations-release.md`（簡略化後）

#### 章構成（簡略化後）

```text
# Operations Phase - ステップ7: リリース準備

前書き（前提条件、operations-release.sh への委譲方針）

## 7.1 バージョン確認
  → operations-release.sh version-check を呼び出し
  → 最終承認は markdown 側（ユーザー判断）

## 7.2 CHANGELOG 更新（markdown 残存）
  → CHANGELOG 内容作成指示（人間判断）
  → 既存の Keep a Changelog 記述をそのまま残す

## 7.3 README 更新（markdown 残存）
  → 既存記述をそのまま残す

## 7.4 履歴記録（markdown 残存）
  → /write-history スキル呼び出し（既存）

## 7.5 Markdownlint 実行
  → operations-release.sh lint を呼び出し
  → エラー発生時の修正指示のみ markdown 側

## 7.6 progress.md 更新（markdown 残存）
  → 既存記述をそのまま残す

## 7.7 Git コミット（markdown 残存）
  → commit-flow.md の「Operations Phase 完了コミット」を参照

## 7.8 ドラフト PR Ready 化
  → operations-release.sh pr-ready を呼び出し
  → PR 本文テンプレート生成（templates/pr_body_template.md）は markdown 側で実施
  → レビューサマリ挿入判断は markdown 側

## 7.9 - 7.11 事前チェック（コミット漏れ / リモート同期 / main 差分）
  → operations-release.sh verify-git を呼び出し
  → warning / error 時のユーザー判断は markdown 側

## 7.12 PR マージ前レビュー（markdown 残存）
  → 既存の対話的フロー（codex review / reviewing-operations-premerge）をそのまま残す

## 7.13 PR マージ
  → merge_method=ask 時のユーザー選択は markdown 側
  → 選択後に operations-release.sh merge-pr --method <method> を呼び出し
  → エラー種別別の対処案内は markdown 側
```

#### サイズ目標

- 整理前: 2,877 tok（212 行）
- 整理後: ≤ 1,438 tok（約 110 行）
- 削減率: ≥ 50%

#### 削減の実現方針

以下の要素を削除することで 50% 削減を達成する:

1. **bash コードブロック**: 7.5（`scripts/run-markdownlint.sh {{CYCLE}}`）、7.8（`pr-ops.sh find-draft` / `pr-ops.sh ready` 等の複数コードブロック）、7.9（`scripts/validate-git.sh uncommitted`）、7.10（`scripts/validate-git.sh remote-sync`）、7.11（`git merge-base --is-ancestor`）、7.13（`scripts/pr-ops.sh merge` の 3 バリエーション）を削除し、`operations-release.sh <subcommand>` の 1 行参照に置き換える
2. **エラー分類テーブル**: 7.13 のマージエラー種別テーブル（11 行）を `operations-release.sh merge-pr` の `--help` に移管し、markdown 側は「エラー発生時は `operations-release.sh merge-pr --help` を参照」の 1 行に縮約
3. **段階説明の重複**: 7.8 の「段1: マージ方法の決定」「段2: 実行モード決定」のような段階見出しを削除し、フラットな手順記述に統一

### コンポーネント 3: `operations/index.md` の更新

#### 編集範囲（厳密に 2 箇所のみ）

1. **§1 目次・概要テーブルの `operations.02-deploy` 行**: 説明文末尾に以下を追記
   ```markdown
   | `operations.02-deploy` | デプロイ実作業 | ... **ステップ7の自動化可能な工程は `scripts/operations-release.sh` を呼び出す** |
   ```
2. **§2.9「AI レビュー分岐」**: 参照を以下に更新（領域 2 の作業と同時）

#### 変更しない箇所

- §2.1〜§2.8（Operations 固有分岐）
- §3 判定チェックポイント表（Unit 004 の Materialized Binding）
- §4 ステップ読み込み契約
- §5 汎用構造仕様

### コンポーネント 4: `operations/02-deploy.md` の更新

#### 編集範囲（1 箇所のみ）

L168 の「サブステップ一覧」直前の注記を以下に変更:

```markdown
**サブステップ一覧**（順番に実行、各サブステップの詳細手順は `steps/operations/operations-release.md` および `scripts/operations-release.sh` を参照して従うこと）:
```

---

## 領域 2: review-flow 簡略化

### ファイル配置

```text
skills/aidlc/steps/
├── common/
│   ├── review-flow.md                      (更新: 手順記述のみに縮約)
│   └── review-routing.md                   (新規: ルーティング判定集約)
├── inception/
│   ├── index.md                            (更新: §2.9 の参照更新)
│   ├── 03-intent.md                        (更新: L42 の参照更新)
│   └── 04-stories-units.md                 (更新: L49, L93 の参照更新)
├── construction/
│   ├── index.md                            (更新: §2.8 の参照更新)
│   ├── 01-setup.md                         (更新: L82 の参照更新)
│   ├── 02-design.md                        (変更なし: 手順本体参照)
│   └── 03-implementation.md                (変更なし: 手順本体参照)
└── operations/
    └── index.md                            (更新: §2.9 の参照更新、領域1と同時編集)
```

### コンポーネント 5: `review-routing.md`（新規）

#### 章構成

本ファイルは**判定テーブル集のみ**を持つ。他のドキュメント（`review-flow.md` 等）への参照文を冒頭に置かない（一方向依存の物理的担保）。

```text
# AI レビューのルーティング判定

本ファイルは AI レビューのルーティング判定（どのスキル・どの focus・どの処理パス・どの CLI ツールで実行するか）を定義する判定テーブル集である。

## 1. 概要

- 本ファイルの位置づけ: ルーティング判定の正本（判定テーブル集のみ、実行手順は含まない）
- 論理インターフェース契約: ReviewRoutingInput → ReviewRoutingDecision（純粋関数的な判定）
- 不変条件（4 項目、詳細は後述）

## 2. 設定

- .aidlc/config.toml [rules.reviewing] の設定テーブル（mode / tools / exclude_patterns）
- デフォルト除外パターン

## 3. CallerContext マッピング

- 9 呼び出し元 × skill_name × focus のテーブル（CallerContextMapping の判定表）

## 4. ツール選択（ToolSelection）

- configured_tools × available_tools → tool_name のルール
- configured_tools=[] 時のセルフレビュー直行シグナル
- どのツールも利用不可の場合の cli_missing_permanent シグナル

## 5. 処理パス決定（PathSelection）

- review_mode × tool_name（ToolSelection の出力）× automation_mode → selected_path + user_rejection_allowed のテーブル
- 遷移判定のフローチャート（review_mode=disabled → 3、required → 1/2、recommend → 1/2、semi_auto + recommend の分岐）

## 6. エラーフォールバック対応表（FallbackPolicyResolution）

- 3 系統（CLI 不在 / CLI 実行エラー / 出力解析不能）× 2 review_mode のテーブル
- skip_reason_required の導出ルール（review_mode=required + CLI 不可時）

## 7. 呼び出し形式

- skill="reviewing-[stage]", args="[対象ファイル] 優先ツール: [tool]" の契約形式
- focus のテーブル参照先（本ファイル §3）
```

**注**: 本章構成には `review-flow.md` への参照文を**置かない**。`exclude_patterns` / `focus` は設定値・属性として列挙するのみで、利用場面（security 指摘の非公開扱い等）の記述は `review-flow.md` 側に残す（実行時ポリシーは手順の正本で管理）。`review-routing.md` は「入力・出力・判定表」のみに厳密に限定する。

#### サイズ目標

- 新設: ≈ 1,200 tok
- 本ファイルに含まれる情報は現行 `review-flow.md` の §設定 + §CallerContextマッピング + §処理パス（パス1/2/3/遷移判定）+ §パス1のエラー時フォールバック表 を等価移管する

#### 論理インターフェース契約（§1 に記述）

```text
## 論理インターフェース契約: ReviewRoutingInput → ReviewRoutingDecision

本ファイル（review-routing.md）が提供する判定の入出力契約。純粋関数的であり、
入力が同じであれば常に同じ出力を返す。

input: ReviewRoutingInput
  caller_context: CallerContext
    # 9 種のいずれか
  review_mode: required | recommend | disabled
  automation_mode: manual | semi_auto
  configured_tools: string[]
    # [rules.reviewing].tools から取得した優先順位リスト（空配列可）
  available_tools: string[]
    # command -v で検出された使用可能 CLI の集合（configured_tools のサブセット）
  tools_runtime_status: ok | cli_runtime_error | cli_output_parse_error
    # 選択されたツールの実行時ステータス（初回呼び出し時は ok）

output: ReviewRoutingDecision
  selected_path: 1 | 2 | 3
    # 1 = 外部CLI レビュー
    # 2 = セルフレビュー
    # 3 = ユーザーレビュー直行
  skill_name: string
    # CallerContextMapping が決定（例: reviewing-construction-plan）
  focus: string[]
    # CallerContextMapping が決定（例: [architecture] / [code, security] / [inception]）
  tool_name: string | none
    # ToolSelection が決定
    # - configured_tools を先頭から走査し available_tools に含まれる最初のツールを返す
    # - どれも使えない場合は none
  fallback_policy:
    on_cli_missing: fallback_to_self | prompt_user_choice
    on_runtime_error: retry_1_then_prompt | retry_1_then_user_choice
    on_parse_error: fallback_to_self | prompt_user_choice
  skip_reason_required: bool
    # review_mode=required でユーザー承認に落ちる場合 true
  user_rejection_allowed: bool
    # automation_mode=semi_auto ∧ review_mode=recommend のとき false

internal services（ReviewRoutingRule が合成する）:
  - CallerContextMapping: caller_context → {skill_name, focus}
  - ToolSelection: {configured_tools, available_tools} → tool_name
  - PathSelection: {review_mode, automation_mode, tool_name, tools_runtime_status} → {selected_path, user_rejection_allowed, skip_reason_required}
  - FallbackPolicyResolution: review_mode → fallback_policy

invariants:
  - selected_path=3 → tool_name=none
  - selected_path=1 → tool_name!=none
  - review_mode=required → on_cli_missing = prompt_user_choice
  - review_mode=recommend → on_cli_missing = fallback_to_self
  - automation_mode=semi_auto ∧ review_mode=recommend → user_rejection_allowed=false
  - 入力が同じであれば常に同じ ReviewRoutingDecision を返す（純粋関数的）
```

### コンポーネント 6: `review-flow.md`（簡略化後）

#### 章構成

```text
# AI レビューフロー

> ルーティング判定（スキル選択・処理パス決定・エラーフォールバック）は `review-routing.md` を参照。
> 本ファイルは ReviewRoutingDecision を受け取った後の実行手順（反復ループ・指摘対応・履歴記録）を扱う。

## 1. 概要

- review-routing.md との関係（flow は routing を消費する立場）
- mode=disabled 時は review-routing.md のパス3 に直行

## 2. 実行手順（ReviewRoutingDecision 消費後）

### 2.1 反復レビュー（パス1 / 2）

- 最大 3 回の反復
- Codex セッション管理（session id 記録、codex exec resume）
- レビュー前コミット
- 機密情報除外スキャン

### 2.2 ユーザーレビュー（パス3）

- レビュー前コミット → 成果物提示 → 承認要求
- 修正依頼 → 反映 → レビュー後コミット → 再提示

## 3. 指摘対応判断フロー

- 千日手検出
- 各指摘への判断（修正する / TECHNICAL_BLOCKER / OUT_OF_SCOPE）
- 理由バリデーション

## 4. スコープ保護確認（OUT_OF_SCOPE 選択時）

- Intent 内要件への影響判定
- ユーザー確認

## 5. OUT_OF_SCOPE バックログ登録

- gh issue create の形式
- security 指摘の非公開扱い

## 6. 判断完了後

## 7. レビュー完了時の共通処理

- シグナル生成
- レビュー後コミット
- レビューサマリ更新
- セミオートゲート判定

## 8. レビューサマリファイル

- テンプレート / パス / バックログ列の有効値

## 9. 履歴記録

- 主要イベントとステップ名の対応

## 10. AI レビュー指摘の却下禁止

## 11. 外部入力検証

- AI レビュー応答の検証（サブエージェント委譲）
- ユーザー入力の検証

## 12. 分割ファイル参照

- review-flow-reference.md への既存参照
```

#### サイズ目標

- 整理前: 3,989 tok
- 整理後: ≈ 2,200 tok
- 削減率: ≈ 45%

#### 削減される要素（`review-routing.md` に移管）

- §設定（mode / tools / exclude_patterns のテーブル）
- §CallerContext マッピング（9 行テーブル）
- §処理パス §パス1 / パス2 / パス3 の分岐本体と遷移判定
- §パス1 のエラー時フォールバック表

### コンポーネント 7: 各フェーズインデックスの §2.8 / §2.9 更新

#### 更新対象

| ファイル | 節番号 | 現行記述 | 更新後 |
|---------|--------|---------|-------|
| `inception/index.md` | §**2.9** | 各承認ポイントで `common/review-flow.md` に従う。`review_mode=disabled` 時は `review-flow.md` のパス3（ユーザーレビュー）へ直行。 | 各承認ポイントで AI レビューを実施する。**ルーティング判定は `steps/common/review-routing.md` を参照**、**反復・指摘対応・完了処理の手順は `steps/common/review-flow.md` を参照**する。`review_mode=disabled` 時は `review-routing.md` のパス 3（ユーザーレビュー）へ直行。 |
| `construction/index.md` | §**2.8** | 同上 | 同上 |
| `operations/index.md` | §**2.9** | 同上 | 同上 |

### コンポーネント 8: 4 ステップファイルの最小限更新

#### 更新対象

| ファイル | 行 | 現行記述 | 更新後 |
|---------|---|---------|-------|
| `inception/03-intent.md` | L42 | **AIレビュー**: Intent承認前に `steps/common/review-flow.md` に従ってAIレビューを実施すること（`review_mode=disabled` の場合は `review-flow.md` のパス3に直行）。 | **AI レビュー**: Intent 承認前に `steps/common/review-flow.md` に従って実施（ルーティング判定の詳細は `steps/common/review-routing.md` 参照）。`review_mode=disabled` の場合は `review-routing.md` のパス 3 に直行。 |
| `inception/04-stories-units.md` | L49 | 同様（ストーリー承認前） | 同様のパターンで更新 |
| `inception/04-stories-units.md` | L93 | 同様（Unit 定義承認前） | 同様のパターンで更新 |
| `construction/01-setup.md` | L82 | **AIレビュー**: 計画承認前に `review-flow.md` に従って実施... | 同様のパターンで更新 |

#### 更新対象外（手順本体参照）

- `construction/02-design.md` L31: `> **順序制約**: steps/common/review-flow.md の手順を確認してから...`
- `construction/02-design.md` L33: `1. **AI レビュー実施**（steps/common/review-flow.md に従う...）`
- `construction/03-implementation.md` L12: `2. **AI レビュー実施**（steps/common/review-flow.md に従う）`
- `construction/03-implementation.md` L142: `4. **AI レビュー実施**（steps/common/review-flow.md に従う...）`

これらは「手順本体（`review-flow.md`）を参照する」という記述であり、ルーティング判定を持ち込まないため変更しない。

---

## API 設計（サブコマンド境界の契約）

### `operations-release.sh` のサブコマンド契約

全サブコマンドに共通する契約:

| 契約項目 | 規約 |
|---------|------|
| 入力形式 | `operations-release.sh <subcommand> [options]`（ポジショナル引数はサブコマンド名のみ） |
| 出力形式 | **既存スクリプトの stdout を透過**（加工しない）。集約サマリが必要な場合は既存出力の末尾に `<subcommand>:summary:...` 形式で追加 |
| 終了コード | **既存スクリプトの終了コードを透過**（0/1/2 への正規化は行わない）。例外: `pr-ready` の `--body-file` 必須エラーのみ exit 1 を返す |
| `--dry-run` | 副作用抑止 + 呼び出しコマンドを `would run: ...` 形式で stdout に出力し exit 0 |
| `--help` | サブコマンド別ヘルプを表示 |
| エラー出力 | 既存スクリプトの stderr を透過。スクリプト自身のエラーは stderr に `<subcommand>:error:<message>` 形式 |
| タイムアウト | 設けない（呼び出される既存スクリプトのタイムアウトに従う） |

**透過契約の重要性**: 本ラッパーは純粋リファクタリングのため、既存スクリプト（`validate-git.sh` / `run-markdownlint.sh` / `pr-ops.sh` 等）の公開契約（stdout 形式、exit code セマンティクス）を**変更しない**。各既存スクリプトは独自の契約を持つ（例: `validate-git.sh` は exit 0 で `status:warning` を stdout に出力する）が、本ラッパーはそれらをそのまま透過する。呼び出し側（`operations-release.md` 手順）は既存と同じ契約を読む。

### `review-routing.md` の論理インターフェース契約

`ReviewRoutingDecision` は宣言的な値オブジェクトであり、実行時の関数呼び出しではなく **判定テーブルの照合結果** として呼び出し層（`review-flow.md` / 各フェーズ `index.md` / 各ステップファイル）が導出する。本契約はドキュメントとして `review-routing.md` §1 に記述され、呼び出し層はこの契約のフィールド名・型・不変条件を守ってルーティング判定を行う。

### バージョニング・後方互換性

- `operations-release.sh`: 本 Unit で新設。将来のサブコマンド追加は互換性を保ちつつ行える
- `review-routing.md`: 本 Unit で新設。`ReviewRoutingDecision` の属性追加はオプションフィールドとして行える
- `review-flow.md`: 既存ファイルの簡略化のみ。既存 API（スキル呼び出し、履歴記録等）は変更しない
- `operations-release.md`: 既存ファイルの簡略化のみ。既存の番号付けと順序を維持

---

## 依存関係（全体構造）

### コンポーネント依存グラフ

```text
                  [領域 1: operations-release]

  operations/index.md ──→ operations/02-deploy.md ──→ operations-release.md
                                                              │
                                                              ↓
                                                   operations-release.sh
                                                              │
                                                              ↓
                            既存スクリプト（本 Unit では変更しない）
                            ├─ pr-ops.sh
                            ├─ validate-git.sh
                            ├─ suggest-version.sh
                            ├─ ios-build-check.sh
                            └─ run-markdownlint.sh


                  [領域 2: review-flow 簡略化]

    各フェーズ index.md          各ステップファイル（4 箇所）
    §2.8 / §2.9                  inception/03-intent.md
    inception/index.md           inception/04-stories-units.md
    construction/index.md        construction/01-setup.md
    operations/index.md
         │                                │
         │  ┌──────────────────────────── │
         │  │                             │
         ↓  ↓                             ↓
    review-flow.md ───────→ review-routing.md
    (手順の正本)              (判定の正本)

    【参照の向き】
    - 呼び出し層（phase index / step file）は review-routing.md を直接参照可能（ルーティング判定の詳細が必要な場合）
    - 呼び出し層は review-flow.md を直接参照する（手順本体を実行する場合）
    - review-flow.md は review-routing.md を参照する（手順実行時に判定結果を消費）
    - review-routing.md は他のどのファイルも参照しない（純粋テーブル集）
```

### 依存方向の原則

- **`review-routing.md` は最下層**: 他のどのファイルも参照しない純粋テーブル集
- **`review-flow.md` は `review-routing.md` を参照する**（手順実行時に判定結果を消費）
- **呼び出し層（phase index / step file）は `review-routing.md` と `review-flow.md` の両方を直接参照できる**:
  - 「ルーティング判定の詳細を知りたい」場合は `review-routing.md` を参照
  - 「手順本体を実行する」場合は `review-flow.md` を参照
  - これは `review-flow.md` が手順の正本である以上、呼び出し層が直接手順を実行する構造を維持するため
- **循環依存は存在しない**: 参照の向きは常に「呼び出し層 → {review-flow.md, review-routing.md}」および「review-flow.md → review-routing.md」であり、逆方向は存在しない
- **operations-release 領域**:
  - `operations/index.md` → `operations/02-deploy.md` → `operations-release.md` → `operations-release.sh` → 既存スクリプト の単方向依存
  - `operations-release.sh` は呼び出し元の markdown 構造に依存しない（サブコマンド単位で独立）

### 障害の伝播と分離

- **`review-routing.md` の記述ミス** → `review-flow.md` の手順も呼び出し層も誤ったルーティング判定を受け取るが、影響範囲は AI レビュー機能のみに限定（リリース機能には影響なし）
- **`operations-release.sh` の不具合** → Operations Phase のリリース機能のみに影響。AI レビュー機能、Inception / Construction Phase には影響なし
- **既存スクリプトの非互換変更** → `operations-release.sh` が影響を受ける可能性があるが、本 Unit のスコープでは既存スクリプトは変更しないため問題なし。依存関係は `operations-release.sh` ヘッダーコメントに明記

---

## 設計段階での決定事項

### 決定 1: サブコマンド境界を機能群単位とする

節単位の 1:1 対応ではなく、**機能群単位（機能的に関連するサブステップのグループ）** でサブコマンドを定義する。理由:

- 7.9-7.11 は事前チェック 3 種の連続実行であり、1 つのサブコマンドに集約する方が呼び出し側にとって使いやすい
- 7.6 progress.md 更新 / 7.7 Git コミット は人間判断やファイル編集を含むため、スクリプト化対象外
- 7.4 履歴記録はすでに `/write-history` スキル経由で orchestration 済み

ただし **7.11 の障害分離は維持する**: `verify-git` サブコマンド内で 7.9/7.10（必須チェック）と 7.11（推奨チェック）を分離し、7.11 の fetch 失敗は `skipped` として扱い呼び出し元が継続可能とする。これは現行 `operations-release.md` L149 の「fetch 失敗 → スキップして続行」を忠実に移管するための決定。

### 決定 1b: iOS バージョン確認の Inception 履歴参照は markdown 側に残す

現行 `operations-release.md` §7.1 の「Inception 履歴に『iOSバージョン更新実施』記録あり → MARKETING_VERSION 確認スキップ」ロジックは、スクリプト側で実装するか markdown 側で実装するかの選択肢がある。本設計では **markdown 側の責務** とし、スクリプト側には `--ios-skip-marketing-version` フラグ引数のみを提供する。理由:

- Inception 履歴の内容解釈（記録の有無判定）は AI エージェントが行う方が柔軟
- スクリプト側に履歴パースロジックを持ち込むと、履歴フォーマット変更時の影響範囲が広がる
- 現行の「AI エージェントが履歴を読んで判断 → スクリプトにフラグを渡す」の流れに最も近い実装となる

### 決定 2: `--draft` フラグを付けない

新規 PR 作成時（ドラフト PR 不在時）の `gh pr create` 呼び出しは、現行 `operations-release.md` §7.8 の記述「`gh pr create --base main --title "{{CYCLE}}" --body-file <一時ファイルパス>`」に完全一致させる。`--draft` フラグを追加することは新機能追加に該当し、純粋リファクタリング制約に反する。

### 決定 3: `review-routing.md` は純粋な判定テーブル集とする

Unit 001-004 の Materialized Binding パターンのような規範 spec + binding 層の構造は採用しない。`review-routing.md` は実行意味論を持たない宣言的な判定テーブル集であり、手順記述（反復ロジック、セッション管理、履歴記録）は `review-flow.md` に残す。

### 決定 4: ステップファイル個別参照更新は最小限

原則として個別更新を行わず、フェーズインデックスで完結させる。例外として「`review_mode=disabled` 時のパス 3 直行判定」を明示参照している 4 箇所のみ更新する。`construction/02-design.md` / `03-implementation.md` は手順本体（`review-flow.md` に従う）を参照しているため、ルーティング判定を持ち込まないよう変更しない。

### 決定 5: `operations/index.md` の編集は 2 箇所のみに限定

Unit 004 で確立した Materialized Binding 構造（§1 目次 / §2 分岐ロジック / §3 判定チェックポイント表 / §4 ステップ読み込み契約 / §5 汎用構造仕様）を破壊しないため、編集を以下の 2 箇所のみに限定する:

1. §1 目次・概要テーブルの `operations.02-deploy` 行の説明文に `operations-release.sh` 呼び出しの注記を追加
2. §2.9「AI レビュー分岐」の参照を `review-routing.md` + `review-flow.md` 併記に変更

---

## 動作等価性の保証方針

### operations-release 領域

以下の 3 軸で動作等価性を検証する。全て差分ゼロが合格条件:

1. **呼び出し引数の照合**: `--dry-run` モードで全サブコマンドを実行し、出力される `gh` / `git` / 既存スクリプトの呼び出し引数を、現行 `operations-release.md` の bash コードブロックと**テキスト比較**する
2. **stdout 形式の透過確認**: サンプル入力で実際に各サブコマンドを実行し、既存スクリプトの stdout 出力（`validate-git.sh` の `status:warning` / `run-markdownlint.sh` の `markdownlint:success` / `pr-ops.sh merge` の `merged` 等）がラッパー経由で透過されていることを確認する
3. **終了コードの伝播**: 既存スクリプトの終了コード（0 / 1）がラッパーの終了コードとして透過されていることを確認する。`verify-git` の 7.11 `skipped` 扱い（fetch 失敗時の継続可能性）も検証する

### review-routing 領域

現行 `review-flow.md` の判定記述から導出した期待値（12 ケース）と、新規 `review-routing.md` のテーブルから導出した実際値を**フィールド単位で比較**する。全フィールド完全一致が合格条件。

### サイズ検証

- `operations-release.md` ≤ 1,438 tok（ベースライン 2,877 tok の 50%）
- `review-flow.md` + `review-routing.md` 合計 ≤ 3,989 tok（整理前の `review-flow.md` 単体以下）

---

## 実装順序（Phase 2 での実装計画）

### 順序 1（領域 1 先行、領域 2 後続）

1. `operations-release.sh` の新規作成（全サブコマンド実装 + `--dry-run` + `--help`）
2. `operations-release.sh` 構文チェック（`bash -n`）+ `shellcheck`（任意）
3. `operations-release.md` の簡略化
4. `operations/index.md` の §1 行注記追加
5. `operations/02-deploy.md` の参照更新
6. 動作等価性検証（`--dry-run` × 4 シナリオ + stdout 形式透過 + warning/error 伝播 + 終了コード透過の 3 軸）
7. サイズ検証（`operations-release.md` ≤ 1,438 tok）
8. `review-routing.md` の新規作成
9. `review-flow.md` の簡略化
10. 各フェーズインデックス §2.8 / §2.9 の更新（3 ファイル）
11. 4 ステップファイルの個別参照更新
12. ルーティング動作等価性検証（12 ケース、`ReviewRoutingInput` → `ReviewRoutingDecision` の完全一致）
13. サイズ検証（`review-flow.md` + `review-routing.md` 合計）
14. 最終 lint / check（markdownlint / `check-bash-substitution.sh` は `.md` steps スコープのみ / grep 参照整合性）

### 順序の根拠

- 領域 1 と領域 2 は独立しているため、どちらを先にしても問題ない
- 領域 1（`operations-release.sh`）の実装が検証サイクル（`--dry-run`）を持つため、先に完了させて品質を担保する方がリスクが低い
- 領域 2 は純粋なテキスト編集が主であり、領域 1 の後に並行または順次で実施できる

---

## まとめ

Unit 005 の論理設計は、ドメインモデルで定義した 2 領域（`OperationsReleaseOrchestrator` / `ReviewRoutingDecision`）をそれぞれ具体的なファイル構造・コンポーネント・API 契約・依存関係に落とし込んだ。主要な決定は以下のとおり:

1. `operations-release.sh` は 5 サブコマンドのディスパッチャとして実装し、既存スクリプトを orchestration する薄いラッパーとする
2. `review-routing.md` は純粋な判定テーブル集として新設し、`review-flow.md` からの一方向依存を担保する
3. Unit 004 で確立した Materialized Binding 構造は `operations/index.md` の編集を 2 箇所に限定することで保持する
4. ステップファイルの個別更新は 4 箇所に最小化し、手順本体参照は変更しない
5. 動作等価性は `--dry-run` + ルーティング静的照合（12 ケース）で保証する

実装段階（Phase 2）では、本設計の順序に従って領域 1 → 領域 2 の順で実装し、各ステップで検証を実施する。
