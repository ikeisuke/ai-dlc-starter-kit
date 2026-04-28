# 既存コードベース分析（v2.4.3 patch サイクル限定スコープ）

> Intent §「含まれるもの」に基づき、本サイクルで修正対象となるファイル群と直接の隣接実装に限定して解析する。プロジェクト全体構造解析は v2.4.x で確立済みのため省略（standard 深度の冗長回避）。前サイクル `v2.4.2/requirements/existing_analysis.md` で記録した「アーキテクチャ・パターン」「技術スタック」「依存関係」は本サイクルでも有効で変化なし。差分のみ後段に記載する。

## ディレクトリ構造・ファイル構成

本サイクルで参照／変更する主要ファイル:

```text
.
├── .aidlc/
│   ├── rules.md                                       # 修正対象 (#612: ブランチ運用フロー)
│   └── config.toml                                    # 修正対象 (starter_kit_version 同期)
├── .claude/
│   └── settings.json                                  # 修正対象 (#609: PostToolUse hook 追加)
├── bin/
│   ├── post-merge-sync.sh                             # 参考（変更対象外）
│   └── markdownlint-on-md-changes.sh                  # 新規 (#609, 命名は Construction 確定)
├── skills/
│   ├── aidlc/
│   │   ├── config/
│   │   │   └── defaults.toml                          # 修正対象 (#611: tools 既定値整合)
│   │   ├── scripts/
│   │   │   └── operations-release.sh                  # 修正対象 (#609: lint サブコマンド削除)
│   │   └── steps/
│   │       ├── common/
│   │       │   ├── review-routing.md                  # 修正対象 (#611: ToolSelection / PathSelection / FallbackPolicyResolution)
│   │       │   ├── review-flow.md                     # 修正対象 (#611: パス1/2 / フォールバック整理)
│   │       │   └── review-flow-reference.md           # 参考（必要に応じて #611 で追記）
│   │       └── operations/
│   │           ├── operations-release.md              # 修正対象 (#609: §7.5 削除)
│   │           └── 02-deploy.md                       # 修正対象 (#609: §7.5 参照削除)
│   ├── aidlc-setup/
│   │   ├── SKILL.md                                   # 修正対象 (#612: 案 B 文言)
│   │   ├── steps/
│   │   │   └── 03-migrate.md                          # 修正対象 (#612: chore/aidlc-v*-upgrade 命名 / アップグレードフロー文言)
│   │   └── scripts/
│   │       └── migrate-backlog.sh                     # 修正対象 (#610: perl -CSD -Mutf8)
│   └── aidlc-migrate/
│       └── steps/
│           └── 03-verify.md                           # 修正対象（候補、#612 案 B の波及）
└── .aidlc/cycles/v2.4.3/                              # 本サイクル成果物
```

ファイル命名規則は v2.4.2 から変更なし（`NN-<slug>.md` / `<verb>-<noun>.sh` / `*-template.md` / `{NNN}-{name}.md`）。

## アーキテクチャ・パターン（差分）

v2.4.2 解析からの差分のみ記載。それ以外は変更なし。

| 項目 | 差分内容 | 根拠 |
|------|---------|------|
| markdownlint 実行点 | 現状: Operations §7.5（`scripts/operations-release.sh lint --cycle {{CYCLE}}`）+ CI（`pr-check.yml` の `markdownlint-cli2-action@v18`）の二点 | `skills/aidlc/steps/operations/operations-release.md:28`、`.github/workflows/pr-check.yml:46` |
| レビューツール解決 | 現状: `ToolSelection`（`review-routing.md §4`）と `FallbackPolicyResolution`（§6）が分離。`tools=[]` は `self_review_forced` シグナルで暗黙パス2直行、空 ≠ self 明示の区別なし | `review-routing.md:45,68-70` |
| アップグレードブランチ命名 | 現状: ダウンストリーム向けは `chore/aidlc-v<version>-upgrade`（`aidlc-setup` / `aidlc-migrate` が作成）。`.aidlc/rules.md:274` には旧表記 `upgrade/vX.X.X` が残存 | `.aidlc/rules.md:274`、`skills/aidlc-setup/steps/03-migrate.md:66,75,129,...` |

## 技術スタック

v2.4.2 から変更なし。Bash 3.x+ / Markdown / `gh` / `dasel` / `git` / `markdownlint-cli2` / `codex`（optional）。

## 依存関係（差分）

- `.claude/settings.json` の PostToolUse hook が新規依存項目に追加される（既存 `check-utf8-corruption.sh` と同枠組み）
- `bin/markdownlint-on-md-changes.sh`（新規）は Bash + `markdownlint-cli2`（任意）に依存。未インストール時はスキップ動作（`exit 0`）
- `scripts/operations-release.sh lint` サブコマンド削除に伴い、`operations-release.sh` 本体から markdownlint 関連コードパスが消える

循環依存・新規外部ライブラリの追加なし。

## 修正対象ファイルの現状把握（要点のみ）

### `.aidlc/rules.md`（修正対象 #612）

- L274 に `upgrade/vX.X.X` 表記が残存。aidlc-setup スキルが案内する命名と整合させる必要あり
- 修正方針: ダウンストリーム向け `chore/aidlc-v<version>-upgrade` を正式名称として明記し、スターターキット自身は `cycle/vX.X.X` を使う旨の対比を追加（Intent 案 B）

### `skills/aidlc-setup/SKILL.md` / `steps/03-migrate.md`（修正対象 #612）

- 03-migrate.md の §9 周辺と §10（HEAD 同期 / ブランチ削除案内）が `chore/aidlc-v<version>-upgrade` 前提で実装済み
- 修正方針: SKILL.md / 03-migrate.md の文言冒頭で「本フローはダウンストリームプロジェクト向け、スターターキット自身は cycle/vX.X.X を使う」を明示。命名は既に `chore/aidlc-*` のため命名変更コードパスは少ない（rules.md の旧表記更新が中心）

### `skills/aidlc-migrate/steps/03-verify.md`（修正候補 #612）

- v2.4.2 で post-merge フォローアップ追加済み
- 修正方針: #612 の文言追加範囲が migrate 側にも波及するか Construction 着手時に再評価。最小修正で済ませる

### `skills/aidlc/steps/common/review-routing.md` / `review-flow.md` / `defaults.toml`（修正対象 #611）

- `review-routing.md §4` の `ToolSelection` で `configured_tools=[]` を `self_review_forced` シグナル化、§6 の `FallbackPolicyResolution` で `cli_missing_permanent` / `cli_runtime_error` / `cli_output_parse_error` を別表で扱っている
- 修正方針:
  - `ToolSelection` で `self`（および alias `claude`）を正式に許容
  - `tools=[]` は従来通り「セルフ直行」と扱い、シム適用結果（`["self"]` 相当）であることを明記
  - 暗黙シム: `tools` リストに `self` / `claude` のいずれも含まれない場合、末尾に `self` を補完（後方互換）
  - alias 正規化: ToolResolver 入口で `claude → self` を単純置換
  - `fallback_to_self` 分岐の整理: `cli_missing_permanent` / `cli_output_parse_error` の `fallback_to_self → 2` は通常のツール解決順序の延長として表現（§6 を縮約 or 注記化）
  - `defaults.toml`: `[rules.reviewing].tools = ["codex"]` を `["codex", "self"]` に変更するか、暗黙シムに任せるかは Construction で確定

### `skills/aidlc-setup/scripts/migrate-backlog.sh`（修正対象 #610）

- `generate_slug()` 関数（推定 L71-80）の Perl invocation が `-CSD -Mutf8` 未指定で UTF-8 を Latin-1 として解釈
- 修正方針: 1 行追加（`perl -pe ...` → `perl -CSD -Mutf8 -pe ...`）。回帰テストとして fullwidth カッコを含む日本語タイトルでの動作確認を実装記録に記載

### `.claude/settings.json` / `bin/markdownlint-on-md-changes.sh`（修正対象 #609）

- 既存 PostToolUse hook (`check-utf8-corruption.sh`) と同じ枠組みで追加可能
- 修正方針:
  - `.claude/settings.json` の `hooks.PostToolUse` に `matcher: "Edit|Write"` の hook を追加
  - 新規スクリプト `bin/markdownlint-on-md-changes.sh`（命名は Construction で確定）: 対象ファイル拡張子チェック（`*.md` のみ）→ `markdownlint-cli2` 存在確認（未インストール時 exit 0）→ 違反時は exit code で通知

### `skills/aidlc/steps/operations/operations-release.md` / `02-deploy.md` / `scripts/operations-release.sh`（修正対象 #609）

- `operations-release.md:28` に §7.5 の lint コマンド記述、`02-deploy.md:183` に「7.5 Markdownlint実行」の参照
- `operations-release.md:63` に「§7.5 で `markdownlint:auto-fix` が発生した場合のみ」の条件分岐記述
- 修正方針: §7.5 ステップ削除、関連参照を grep で全特定して整合更新。`scripts/operations-release.sh` の lint サブコマンド本体も削除（hook と CI に集約）

## 特記事項

- **#612 の影響範囲縮小**: ダウンストリーム向け命名 `chore/aidlc-v<version>-upgrade` は既に aidlc-setup / aidlc-migrate に実装済み。本サイクルでの主な変更は `.aidlc/rules.md:274` の旧表記更新と SKILL.md 系の文言追加。コード変更はほぼ不要
- **#611 の後方互換シム実装ポイント**: `read-config.sh` 利用側（`review-routing.md` の §3 設定参照箇所）にシムを置くか、`ToolSelection` ロジック内に置くかを Construction Phase で判断。後者の方がカプセル化される
- **#609 hook の `markdownlint-cli2` 依存**: ローカル環境で `markdownlint-cli2` が未インストールな場合、hook はスキップ（exit 0）。CI 側は `markdownlint-cli2-action@v18` がセットアップを行うため未インストール問題は発生しない
- **`starter_kit_version` 同期**: `.aidlc/config.toml.starter_kit_version = "2.4.1"` は v2.4.0 以降のルール（`bin/update-version.sh` 除外対象）により release 時に自動更新されない。本サイクルで Operations 7.x 完了時に `2.4.3` へ手動更新する必要がある（`aidlc-setup` / `aidlc-migrate` 経由ではなく Operations 手順内で実施）
- **既存 backlog で関連するもの**: #573（旧キー新キー体系自動移行）、#586（progress.md 6step と spec §5.1 5checkpoint の 3層整合化）は本サイクル対象外。ただし #611 のシム実装が #573 の論点に重なる可能性があれば Construction Phase で再評価する
