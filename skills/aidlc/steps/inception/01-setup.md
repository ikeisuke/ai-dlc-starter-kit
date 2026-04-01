# Inception Phase - セットアップ

## プロジェクト情報

### ディレクトリ構成
- `.aidlc/cycles/{{CYCLE}}/`: サイクル固有成果物（Inception Phaseで作成）

### 開発ルール

**共通ルールは `steps/common/rules.md` を参照**

- **プロンプト履歴管理【重要】**: `/write-history` スキルを使用して `.aidlc/cycles/{{CYCLE}}/history/inception.md` に記録。詳細はスキルのSKILL.mdを参照。

**【次のアクション】** 今すぐ `steps/common/review-flow.md` を読み込んで、内容を確認してください。

  **AIレビュー対象タイミング**: Intent承認前、ユーザーストーリー承認前、Unit定義承認前

- **コンテキストリセット対応【重要】**: ユーザーからリセット・中断の発言があった場合:
  1. progress.mdを更新（現在のステップを「進行中」のまま保持）
  2. 履歴記録（中断状態を追記）
  3. session-state.mdを生成（`common/session-continuity.md` に従う。`automation_mode` に関係なく必ず実行）
  4. 継続用プロンプトを提示: `/aidlc inception`

**【次のアクション】** 今すぐ `steps/common/compaction.md` を読み込んで、内容を確認してください。

### フェーズの責務【重要】

**行うこと**: サイクル作成、Intent作成、ユーザーストーリー作成、Unit定義
**禁止**: 実装コード・テストコード・設計ドキュメント詳細化（Construction Phaseで実施）
**承認なしにConstruction Phaseに進んではいけない**（`semi_auto`での自動承認を除く）

**【次のアクション】** 今すぐ `steps/common/phase-responsibilities.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `steps/common/progress-management.md` を読み込んで、内容を確認してください。

---

## あなたの役割

プロジェクトセットアップ担当者兼プロダクトマネージャー兼ビジネスアナリスト。
新しいサイクルのディレクトリ構造を作成し、要件を明確化してUnit定義まで完了する。

---

## 個人設定（オプション）

| ファイル | 用途 | Git管理 |
|----------|------|---------|
| `.aidlc/config.toml` | プロジェクト共有設定 | Yes |
| `.aidlc/config.local.toml` | 個人設定（上書き用） | No |

詳細は `guides/config-merge.md` を参照。

---

## Part 1: セットアップ

### 1. プリフライトチェック

**【次のアクション】** 今すぐ `steps/common/preflight.md` を読み込んで、手順に従ってください。

結果をコンテキスト変数として保持。以降は再実行しない（ユーザーがインストール/認証した場合のみ再チェック）。

### 1a. Inception固有の追加情報取得

- `current_branch`: `git branch --show-current`
- `latest_cycle`: `.aidlc/cycles/` 配下の最新 `v*` ディレクトリ

### 2. セッション判別設定【オプション】

`session-title` スキルが利用可能な場合のみ実行。

### 3. デプロイ済みファイル確認

`skills/aidlc/SKILL.md` の存在確認。未存在時は `/aidlc setup` を案内し続行。

### 4. スターターキット開発リポジトリ判定

`.aidlc/config.toml` の `[project].name` が `ai-dlc-starter-kit` → `STARTER_KIT_DEV`（アップグレード案内スキップ）、それ以外 → `USER_PROJECT`。

### 5. 追加ルール確認

`.aidlc/rules.md` が存在すれば読み込む。

### 6. スターターキットバージョン確認（三角モデル）

**スキップ条件**: `STARTER_KIT_DEV` の場合、または `rules.upgrade_check.enabled` が `true` でない場合（デフォルト `false`）。

#### 6a. バージョン情報取得（3点）+ 正規化

| ソース | 取得方法 | エラー時 |
|--------|---------|---------|
| リモート | `curl -s --max-time 5 https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/version.txt` | available=false |
| スキル | `skills/aidlc/SKILL.md` の親ディレクトリ直下の `version.txt` をReadツールで読み込み | available=false |
| ローカル設定 | `scripts/read-config.sh starter_kit_version` | available=false |

**正規化**: `v`プレフィックス除去、空白トリム、semverパース検証。パース不可は取得失敗扱い。

**注意**: スキルバージョンは `skills/aidlc/version.txt`（SKILL.mdの親ディレクトリ）であり、リポジトリルートの `version.txt` ではない。

#### 6b. ComparisonMode決定

| モード | 条件 | 比較対象 |
|--------|------|---------|
| THREE_WAY | 3点全available | 3点比較 |
| REMOTE_LOCAL | skillのみunavailable | remote vs local（従来フォールバック） |
| SKILL_LOCAL | remoteのみunavailable | skill vs local |
| REMOTE_SKILL | localのみunavailable | remote vs skill |
| SINGLE_OR_NONE | 2点以上unavailable | 比較スキップ（警告のみ表示して続行） |

#### 6c. 比較実行

**THREE_WAYモード**:

| パターン | 条件 | アクション |
|---------|------|-----------|
| 全一致 | remote = skill = local | 「最新バージョンです」表示 |
| リモートのみ新しい | remote > skill = local | スキル更新を促す（プラグイン再インストール） |
| スキルのみ古い | remote = local > skill | スキル更新を促す |
| ローカルのみ古い | remote = skill > local | `/aidlc setup`の実行を促す + starter_kit_version確認手順 |
| ローカルのみ進んでいる | local > remote = skill | 警告表示（設定が先行） |
| 複数不一致 | 上記以外 | 各差分を表示、スキル更新→ローカル設定更新の順にアクション提示 |

**REMOTE_LOCALモード（スキル取得失敗時のフォールバック）**:

| パターン | 条件 | アクション |
|---------|------|-----------|
| 一致 | remote = local | 「取得可能分は一致」+ スキル取得失敗警告 |
| remote > local | - | `/aidlc setup`の実行を促す + starter_kit_version確認手順 |
| local > remote | - | 警告表示（設定が先行） |

**SKILL_LOCAL / REMOTE_SKILLモード**:
- 一致 → 「取得可能分は一致」+ unavailableソースの警告
- 不一致 → 差分表示 + 比較方向に応じたアクション（remote > skill → スキル更新案内、skill > remote → 「スキルが先行」警告） + unavailableソースの警告

**SINGLE_OR_NONEモード**: 比較スキップ、unavailableソースの警告のみ表示して続行。

#### 6d. starter_kit_version確認手順（ローカルのみ古い場合に追加表示）

```text
アップグレード後、以下を確認してください:
1. `/aidlc setup` を実行してアップグレードモードを完了
2. `.aidlc/config.toml` の `starter_kit_version` がスキルバージョンと一致するか確認
```

### 7. サイクルモード確認

```bash
scripts/read-config.sh rules.cycle.mode
```

| mode | 動作 |
|------|------|
| `default` | 従来フロー（名前入力なし） |
| `named` | サイクル名を入力/選択。バリデーション: `^[a-z0-9][a-z0-9-]{0,63}$`、禁止名: `backlog`, `backlog-completed`, `v[0-9]`開始 |
| `ask` | 通常/名前付きの選択を提示 |

無効値 → `default` にフォールバック。

**named モード**: 既存名前付きサイクルがあれば選択肢に表示。「新規作成」で名前入力フローへ。
選択/入力された名前は `cycle_name` として保持。

### 8. 名前付きサイクル継続確認

**スキップ**: `cycle_name` 設定済み、ask→通常サイクル選択時、名前付きサイクル0件の場合。

`.aidlc/cycles/` 配下の名前付きサイクル（`v[0-9]`開始でない、予約名でない）を検出し、継続するか新規開始するか選択を提示。

### 9. サイクルバージョンの決定

**9-1. コンテキスト表示**:

```bash
scripts/check-open-issues.sh --limit 5
```

直近3サイクルの `requirements/intent.md` から「開発の目的」を抽出して表示。

**9-2. バージョン提案**:

```bash
scripts/suggest-version.sh
```

| 条件 | 選択肢 |
|------|--------|
| `cycle_name` あり + 既存バージョンあり | 最新を基準にpatch/minor/major |
| `cycle_name` あり + 初回 | `v0.0.1` / `v0.1.0` / `v1.0.0` |
| `cycle_name` なし + `branch_version` あり | そのバージョンを提案 |
| `cycle_name` なし + その他 | `suggested_*` から選択 + カスタム入力 |

`all_cycles` に完全一致する場合はエラー（重複防止）。名前付きサイクルの `{{CYCLE}}` は `${cycle_name}/${version}` 形式。

### 10. ブランチ確認【推奨】

**10-1. ブランチ作成方式**: `scripts/read-config.sh rules.branch.mode`

| mode | 動作 |
|------|------|
| `branch` | 自動でブランチ作成 |
| `worktree` | worktree作成（`rules.worktree.enabled=true` 必須、false時→branch） |
| `ask`（デフォルト） | ユーザーに選択（worktree/branch/現在のブランチで続行） |

無効値 → `ask` にフォールバック。

**10-2. ブランチ状況による分岐**:

| 現在のブランチ | 動作 |
|-------------|------|
| main/master | 上記modeに従いブランチ/worktree作成 |
| `cycle/*` | そのまま続行 |
| その他/detached | サイクルブランチへの切り替えを提案（新規作成/既存選択/続行） |

**ブランチ作成コマンド**:

```bash
scripts/setup-branch.sh {{CYCLE}} branch   # ブランチ方式
scripts/setup-branch.sh {{CYCLE}} worktree  # worktree方式
```

**10-3. main最新化チェック**: `setup-branch.sh` 出力の `main_status:` をパースして表示。

| main_status | メッセージ |
|-------------|-----------|
| `up-to-date` | 最新です |
| `behind` | 未取り込み変更あり（merge/rebase推奨） |
| `fetch-failed` | リモート確認失敗（オフライン等） |

**10-4. rules.md再読み込み**: ブランチ切り替えが発生した場合のみ、ステップ5を再実行。

### 11. サイクル存在確認

`.aidlc/cycles/{{CYCLE}}/` が存在 → Part 2へ、未存在 → ステップ12へ。

### 12. サイクルディレクトリ作成

```bash
scripts/init-cycle-dir.sh {{CYCLE}}
```

10個のサイクル固有ディレクトリと初期履歴ファイルを一括作成。`--dry-run` で確認可能。

---
