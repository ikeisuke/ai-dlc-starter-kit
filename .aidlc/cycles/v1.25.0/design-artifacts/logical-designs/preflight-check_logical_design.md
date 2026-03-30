# 論理設計: プリフライトチェック・設定値一括提示

## 概要

`common/preflight.md` の内部構造と各フェーズプロンプトへの統合方式を定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

共通プロンプトファイル参照パターン（既存の `common/rules.md`, `common/review-flow.md` と同一）。`preflight.md` は各フェーズプロンプトから `【次のアクション】` 指示で参照され、AIエージェントが手順に従って実行する。

## コンポーネント構成

### モジュール構成

```text
common/
├── preflight.md          ← 新規作成
├── rules.md              ← 既存（参照のみ）
├── review-flow.md        ← 既存（参照のみ）
└── ...

inception.md              ← 修正（preflight参照追加）
construction.md           ← 修正（preflight参照追加）
operations.md             ← 修正（preflight参照追加）
```

### コンポーネント詳細

#### common/preflight.md

- **責務**: 環境チェック・設定値取得・結果提示の一連の手順を定義
- **依存**: `env-info.sh`, `check-backlog-mode.sh`, `read-config.sh`（全て既存、変更なし）
- **公開インターフェース（コンテキスト変数契約）**:

| コンテキスト変数名 | 取得元 | 値の例 | 互換エイリアス |
|-------------------|--------|--------|--------------|
| `gh_status` | `env-info.sh` の `gh:` 行 | `available` / `not-installed` / `not-authenticated` | `gh`（既存フェーズプロンプトとの互換） |
| `backlog_mode` | `check-backlog-mode.sh` の出力 | `git` / `issue` / `git-only` / `issue-only` | - |
| `depth_level` | `read-config.sh` 単一キー取得 | `minimal` / `standard` / `comprehensive` | - |
| `automation_mode` | `read-config.sh` 単一キー取得 | `manual` / `semi_auto` | - |
| `review_mode` | `read-config.sh` 単一キー取得 | `required` / `recommend` / `disabled` | - |
| `review_tools` | `read-config.sh` 単一キー取得 | `['codex']` / `[]` | - |
| `squash_enabled` | `read-config.sh` 単一キー取得 | `true` / `false` | - |
| `markdown_lint` | `read-config.sh` 単一キー取得 | `true` / `false` | - |
| `unit_branch_enabled` | `read-config.sh` 単一キー取得 | `true` / `false` | - |
| `history_level` | `read-config.sh` 単一キー取得 | `standard` / `detailed` / `minimal` | - |

**互換性ルール**: 既存フェーズプロンプトで `gh:available` 形式で参照している箇所は、`gh_status` コンテキスト変数を参照するよう書き換える。移行期間中は `gh` エイリアスも有効とする。

## preflight.md の内部構成

### セクション1: 環境チェック

**手順**:

1. `env-info.sh` を実行し、基本ツール状態を取得
2. 結果を解析し、各チェック項目のCheckResultを生成
3. チェック項目定義テーブル（ドメインモデル参照）の順に判定

**実行コマンド**:

```bash
docs/aidlc/bin/env-info.sh
```

出力から以下を抽出:
- `gh:{status}` → `gh_status` コンテキスト変数（`env-info.sh` が唯一の情報源。`check-gh-status.sh` の追加呼び出しは不要）
- `git:{status}` → git存在確認の判定
- `dasel:{status}` → 情報保持（直接使用しないが記録）

**ghチェックの単一情報源**: `env-info.sh` の `gh:` 出力を正とする。`env-info.sh` 内部で `gh auth status` を実行し `available` / `not-installed` / `not-authenticated` の3状態を返すため、`check-gh-status.sh` と同等の判定が含まれる。preflightからの `check-gh-status.sh` 呼び出しは行わない。

**backlog_mode取得**:

```bash
docs/aidlc/bin/check-backlog-mode.sh
```

出力: `backlog_mode:{mode}` → `backlog_mode` コンテキスト変数

### セクション2: aidlc.toml確認

**手順**:

1. `docs/aidlc.toml` の存在確認

```bash
ls docs/aidlc.toml 2>/dev/null
```

2. 存在しない場合: blocker判定→フェーズ中断メッセージ
3. 存在する場合: `[project].name` の確認

```bash
docs/aidlc/bin/read-config.sh project.name
```

### セクション3: レビューツール確認（条件付き）

**実行条件**: `review_mode != disabled` かつ `review_tools` が非空（`tools = []` でない）場合のみ

- `review_mode == disabled` の場合: スキップ（情報表示なし）
- `review_tools` が空配列 `[]` の場合: 「外部CLIを使用しない設定です（tools = []）」と情報表示し、whichチェックをスキップ（`review-flow.md` の `cli_available=false` 仕様と整合）

**手順**（条件を満たす場合）:

1. `review_tools` リストの先頭から `which` で存在確認

```bash
which codex >/dev/null 2>&1
```

2. 結果を情報提示（info レベル、中断しない）

### セクション4: 設定値一括取得

**取得方式**: 各キーを `read-config.sh` の単一キーモード + `--default` で個別に取得する。これにより、キーごとにデフォルト値が確実に補完される。

**手順**:

```bash
docs/aidlc/bin/read-config.sh rules.depth_level.level --default "standard"
docs/aidlc/bin/read-config.sh rules.automation.mode --default "manual"
docs/aidlc/bin/read-config.sh rules.reviewing.mode --default "recommend"
docs/aidlc/bin/read-config.sh rules.reviewing.tools --default "['codex']"
docs/aidlc/bin/read-config.sh rules.squash.enabled --default "false"
docs/aidlc/bin/read-config.sh rules.linting.markdown_lint --default "false"
docs/aidlc/bin/read-config.sh rules.unit_branch.enabled --default "false"
docs/aidlc/bin/read-config.sh rules.history.level --default "standard"
```

**注記**: `backlog_mode` はセクション1で `check-backlog-mode.sh` から取得済みのため、ここでは取得しない。

**キー→コンテキスト変数の対応表**:

| 設定キー | コンテキスト変数名 | デフォルト値 |
|---------|-------------------|------------|
| rules.depth_level.level | `depth_level` | standard |
| rules.automation.mode | `automation_mode` | manual |
| rules.reviewing.mode | `review_mode` | recommend |
| rules.reviewing.tools | `review_tools` | ['codex'] |
| rules.squash.enabled | `squash_enabled` | false |
| rules.linting.markdown_lint | `markdown_lint` | false |
| rules.unit_branch.enabled | `unit_branch_enabled` | false |
| rules.history.level | `history_level` | standard |

**エラー処理**: `read-config.sh` が exit code 2（エラー）を返した場合、警告を表示し `--default` で指定したデフォルト値を使用する。exit code 0（値あり）は正常。exit code 1（キー不在）は `--default` によりデフォルト値が返されるため正常。

### セクション5: 結果判定と提示

**判定ロジック**:

1. blocker項目が1つでもfail → `can_proceed=false`
2. それ以外 → `can_proceed=true`

**提示フォーマット**:

```text
【プリフライトチェック結果】

■ 環境チェック
  ✓ git: available
  ✓ aidlc.toml: 存在
  ⚠ gh: not-authenticated（gh依存機能は制限されます）
  ℹ レビューツール (codex): available

■ 主要設定値
  depth_level: standard
  automation_mode: semi_auto
  review_mode: required
  squash_enabled: true
  markdown_lint: false
  unit_branch_enabled: false
  history_level: standard
  backlog_mode: issue-only

■ 判定: 続行可能（警告1件）
```

**can_proceed=falseの場合**:

```text
【プリフライトチェック失敗】

以下の問題を解決してから再実行してください:
- git が見つかりません。gitをインストールしてください。

問題を解決したら「再チェック」と入力してください。
```

### セクション6: 再チェックフロー

**トリガー**: ユーザーが「再チェック」「retry」等を入力
**対象**: 直前のチェックでfailしたblocker/warn項目のみ
**最大回数**: 3回（超過時はフェーズ中断）

## 各フェーズプロンプトへの統合方式

### inception.md の変更

**現在のPart 1 ステップ1**:

```markdown
#### 1. 依存コマンド確認
docs/aidlc/bin/env-info.sh --setup
```

**変更後**:

```markdown
#### 1. プリフライトチェック
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/preflight.md` を読み込んで、手順に従ってください。

#### 1a. Inception固有の追加情報取得
プリフライト後に以下を実行し、Inception固有の情報を取得する:
- `current_branch`: `git branch --show-current` で取得（サイクル判定に使用）
- `latest_cycle`: `ls -1 docs/cycles/ | grep -E '^v[0-9]+' | sort -V | tail -1` で取得（バージョン確認に使用）
```

**preflight内での `env-info.sh` 使用**: `--setup` オプションなしで実行する。`--setup` が提供する `project.name`, `backlog.mode` はpreflight内で個別に取得済み。`current_branch`, `latest_cycle` のみInception固有ステップで取得する。

- Part 2 ステップ14の環境確認は「preflightで取得済みのコンテキスト変数を参照」に置換

### construction.md の変更

**現在のステップ3**:

```markdown
### 3. 環境確認
docs/aidlc/bin/check-gh-status.sh
docs/aidlc/bin/check-backlog-mode.sh
```

**変更後**:

```markdown
### 3. プリフライトチェック
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/preflight.md` を読み込んで、手順に従ってください。
```

- ステップ5（Depth Level確認）はpreflight結果の `depth_level` を参照するだけに変更

### operations.md の変更

construction.md と同一パターンを適用。

## 非機能要件（NFR）への対応

### パフォーマンス
- 該当なし（プロンプト変更のみ）

### セキュリティ
- gh認証状態の確認結果にトークン等の機密情報を含めない
- `gh auth status` の stderr出力は提示しない

### スケーラビリティ
- 該当なし

### 可用性
- blocker以外のチェック失敗でフェーズが中断しないよう、severity分類を厳密に適用

## 実装上の注意事項

- `env-info.sh` は `--setup` オプションなしで実行する（Inception固有の追加情報はpreflight後のステップ1aで取得）
- `gh` チェックは `env-info.sh` を唯一の情報源とする（`check-gh-status.sh` はpreflight内では呼び出さない）
- 設定値は `read-config.sh` の単一キーモード + `--default` で取得し、キー欠落を確実に防止する
- 既存スクリプト（env-info.sh, check-gh-status.sh, check-backlog-mode.sh, read-config.sh）の本体は一切変更しない
- `docs/aidlc/` 配下は直接編集禁止。変更は `prompts/package/` で行う

## 不明点と質問（設計中に記録）

（なし）
