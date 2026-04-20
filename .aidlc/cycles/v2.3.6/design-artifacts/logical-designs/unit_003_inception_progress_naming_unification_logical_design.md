# 論理設計: Unit 003 - Inception Part ラベル修正 + CHANGELOG 集約【DR-005 選択肢 C 確定版】

## 位置づけ

本ドキュメントは DR-005 選択肢 C 決定後の縮小スコープに基づく軽量な論理設計である。4 ファイルの Part ラベル置換パターン + CHANGELOG エントリ骨子 + バックログ Issue 本文の設計に限定する。

## 1. Part ラベル置換パターン

### 置換の基本原則

- **置換ターゲット**: `Part [0-9]+`（正規表現）でヒットする箇所
- **置換方針**: 意味論を保持しつつ、既存 step ファイル名（`01-setup` / `02-preparation`）と整合する表現へ
- **意味論の対応**:
  - `Part 1` → `ステップ1`（`01-setup` に対応、セットアップ）
  - `Part 2` → `ステップ2以降` または `ステップ2`（`02-preparation` 以降、インセプション本体）
- **保持する意味論**: タスクリストの内容、セクションの機能、他ファイルへの参照関係、成果物との紐づき

### ファイル別置換ルール

#### 1-1. `skills/aidlc/steps/inception/index.md`

| 行 | 現在 | 置換後 |
|----|------|--------|
| L47 | `\| Part 1（セットアップ） \| inception.01-setup \| フェーズ開始時から開始 \|` | `\| ステップ1（セットアップ） \| inception.01-setup \| フェーズ開始時から開始 \|` |
| L48 | `\| Part 2（インセプション本体） \| inception.02-preparation 以降 \| サイクルディレクトリ作成完了 / 既存サイクル再開時は progress.md 読み込み完了 \|` | `\| ステップ2以降（インセプション本体） \| inception.02-preparation 以降 \| サイクルディレクトリ作成完了 / 既存サイクル再開時は progress.md 読み込み完了 \|` |

影響: フェーズ構成テーブルの最左列。step_id・遷移条件は不変。

#### 1-2. `skills/aidlc/steps/inception/01-setup.md`

| 行 | 現在 | 置換後 |
|----|------|--------|
| L47 | `## Part 1: セットアップ` | `## ステップ1: セットアップ` |
| L58 | `### 1b. Part 1タスクリスト作成【必須】` | `### 1b. ステップ1タスクリスト作成【必須】` |
| L60 | `**【次のアクション】** \`steps/common/task-management.md\` の「Inception Phase: Part 1」テンプレートに従い、Part 1のタスクリストを作成してください。` | `**【次のアクション】** \`steps/common/task-management.md\` の「Inception Phase: ステップ1（セットアップ）」テンプレートに従い、ステップ1のタスクリストを作成してください。` |
| L206 | `.aidlc/cycles/{{CYCLE}}/` が存在 → ステップ10a・10bを実行してから**Part 2**へ、未存在 → ステップ11へ。 | `.aidlc/cycles/{{CYCLE}}/` が存在 → ステップ10a・10bを実行してから**ステップ2以降**へ、未存在 → ステップ11へ。 |
| L226 | `Part 2のステップ18では既存ファイルの確認のみ行う。` | `ステップ2以降のステップ18では既存ファイルの確認のみ行う。` |

影響: セクション見出し + タスクリストテンプレート参照 + 次ステップ参照。全て表現層のみ。

#### 1-3. `skills/aidlc/steps/inception/02-preparation.md`

| 行 | 現在 | 置換後 |
|----|------|--------|
| L3 | `## Part 2: インセプション準備` | `## ステップ2: インセプション準備` |
| L7 | `Part 1 ステップ1のプリフライトチェックで取得済みのコンテキスト変数を参照する:` | `ステップ1のプリフライトチェックで取得済みのコンテキスト変数を参照する:` |
| L23 | `プリフライトチェック（Part 1 ステップ1）で取得済みの \`depth_level\` コンテキスト変数を参照し、...` | `プリフライトチェック（ステップ1）で取得済みの \`depth_level\` コンテキスト変数を参照し、...` |

影響: セクション見出し + 前段ステップへの参照。意味論維持。

#### 1-4. `skills/aidlc/steps/common/task-management.md`

| 行 | 現在 | 置換後 |
|----|------|--------|
| L55 | `### Part 1: セットアップ（プリフライト完了後、\`01-setup.md\` ステップ1a直後に作成）` | `### ステップ1（セットアップ）: プリフライト完了後、\`01-setup.md\` ステップ1a直後に作成` |
| L63 | `### Part 2以降（\`01-setup.md\` ステップ12b、サイクルディレクトリ作成後に作成）` | `### ステップ2以降（\`01-setup.md\` ステップ12b、サイクルディレクトリ作成後に作成）` |

影響: タスクテンプレートの見出しのみ。テンプレート中身は不変。

## 2. CHANGELOG エントリ骨子

### 追加位置

`CHANGELOG.md` の先頭、`## [2.3.5] - 2026-04-18` の**前**に挿入。

### エントリ構造（既存 `[2.3.5]` フォーマット準拠）

```markdown
## [2.3.6] - 2026-04-20

### Added

- `operations-release.md §7.6` に固定スロット反映ステップを追加。PR 作成から Ready 化までの `release_gate_ready` / `pr_number` 反映を自動化（#583-A / Unit 001）
- `write-history.sh` に Operations Phase マージ後呼び出し拒否ガードを実装（`--operations-stage` 引数 + `completion_gate_ready` + `gh pr view` の AND 条件、exit 3）。`/write-history` SKILL.md の引数表・出力表も追記。`operations/04-completion.md` に 7.8〜7.13 以降での `write-history.sh` 呼び出し禁止記述を追加（#583-B / DR-001 / Unit 002）
- `pull_request` トリガーのワークフロー（`pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml`）に Draft PR スキップの二段ガード（`types: [..., ready_for_review]` + ジョブレベル `if: github.event.pull_request.draft == false`）を追加。Draft PR 期間中の runner 分単位消費を 0 にし、Ready 遷移で初回 runner 実行される運用へ（DR-004 / Unit 004）

### Changed

- Inception Phase の手順書で `Part 1` / `Part 2` の章立て表現を「ステップ1（セットアップ）」「ステップ2以降（インセプション本体）」等の表現に修正（#565 部分対応 / Unit 003）
- `templates/inception_progress_template.md` の 6 ステップ構造と `verify-inception-recovery.sh` の 5 ステップ構造、`phase-recovery-spec.md §5.1` の 5 checkpoint 判定仕様の 3 層整合化は、patch サイクル予算を超える根本リファクタのため本サイクルでは実施せず、次サイクル以降（minor リリース予定）で対応（#<BACKLOG_ISSUE_NUMBER> / DR-005）

### Fixed

（本サイクルでの Fixed 該当なし、必要に応じて省略可）

---
```

**注記**:
- 各 Unit のサマリは 1 行で簡潔に。詳細は関連 Issue / DR 参照
- `#<BACKLOG_ISSUE_NUMBER>` は Issue 作成後に実番号に置換
- Unit 003 の Changed エントリで DR-005 の経緯を明示し、追跡可能性を確保

## 3. バックログ Issue 本文骨子

### タイトル

```
Inception progress.md テンプレート 6 ステップと判定仕様 §5.1（5 checkpoint）の 3 層整合化リファクタ
```

### 本文構造

```markdown
## 背景

v2.3.6 サイクル Unit 003 で「Inception progress.md 表記統一」に取り組む中で、以下の 3 層構造ズレが顕在化した:

1. `templates/inception_progress_template.md` の **6 ステップ構造**（DR-003 で正本化、Intent明確化 / 既存コード分析 / ユーザーストーリー作成 / Unit定義 / PRFAQ作成 / Construction用progress.md作成）
2. `verify-inception-recovery.sh` の **5 ステップ fixture**（セットアップ / インセプション準備 / Intent明確化 / ストーリー・Unit定義 / 完了処理）
3. `phase-recovery-spec.md §5.1` の **5 checkpoint 判定仕様**（setup_done / preparation_done / intent_done / units_done / completion_done、step ファイル `01-setup`〜`05-completion` と 1:1 対応）

6 ステップ progress には `01-setup`（サイクル作成）・`02-preparation`（インセプション準備）に対応する行がなく、判定仕様 §5.1.1 / §5.1.2 の「progress.md のステップ1完了マーク」参照が機械的には意味が通らなくなる。§5.1.4 の「progress.md『完了処理』未着手」も 6 ステップ progress に該当行がない。

## DR-005 での判断（v2.3.6 Unit 003）

Unit 003 のスコープを Part ラベル修正 + CHANGELOG 集約に縮小し、3 層整合化は本 Issue（次サイクル以降）で対応。DR-003 の再検討も含める。

## 推奨方針（選択肢 B）

判定仕様 §5.1 の「progress.md 直接参照」を「step ファイル + 成果物存在ベース」にリファクタ:
- `setup_done`: サイクルディレクトリ存在
- `preparation_done`: 成果物（例: `requirements/` 配下）存在チェック
- `intent_done`: `intent.md` 存在 + `user_stories.md` 未存在
- `units_done`: `user_stories.md` 存在、`units/*.md` 未存在 or `units/*.md` 存在 + 進捗未完了
- `completion_done`: `history/inception.md` 存在 or progress.md 全完了

fixture も 6 ステップに追従（またはテンプレートの再検討結果に応じて調整）。

## 影響範囲

- `skills/aidlc/steps/common/phase-recovery-spec.md §5.1`（判定仕様）
- `skills/aidlc/scripts/verify-inception-recovery.sh`（fixture）
- 必要に応じて `templates/inception_progress_template.md`（テンプレート再検討）
- `skills/aidlc/steps/inception/04-stories-units.md` / `05-completion.md`（ステップ N-M 表記の残留分）
- Construction / Operations の判定仕様との整合確認

## 関連

- DR-003（Inception progress 6 ステップ構造確定、v2.3.6 Inception）
- DR-005（6 ステップと 5 checkpoint の階層分離、v2.3.6 Construction Unit 003）
- #565（Inception progress.md 表記統一、Unit 003 で一部対応済み）

## 対応時期

patch サイクルの予算を超えるため、minor リリース（v2.4.0）以降を推奨。
```

### Issue 作成コマンド

```bash
# 一時ファイルに本文を書き出してから実行
gh issue create \
    --title "Inception progress.md テンプレート 6 ステップと判定仕様 §5.1（5 checkpoint）の 3 層整合化リファクタ" \
    --label "backlog,type:refactor,priority:medium" \
    --body-file /tmp/unit003-backlog-issue.md
```

## 4. 実装順序

1. **Part ラベル修正（4 ファイル）**: Edit ツールで 1 ファイルずつ置換。各ファイル修正後に `rg "Part [0-9]+" <ファイル>` で 0 ヒット確認
2. **バックログ Issue 作成**: 一時ファイルに本文を書き出し → `gh issue create` → Issue 番号を記録
3. **CHANGELOG 追記**: Issue 番号を挿入した上で `[2.3.6]` エントリを `CHANGELOG.md` 先頭に追加
4. **コードレビュー**: `reviewing-construction-code` スキル（codex）
5. **統合レビュー**: 全変更反映後に `reviewing-construction-integration` スキル

## 境界外（本 Unit では扱わない）

- テンプレート / fixture / 判定仕様の 3 層整合化（バックログ Issue で別対応）
- `04-stories-units.md` / `05-completion.md` の「ステップ N-M」表記
- Operations 関連ファイルの「ステップ N-M」表記
- `guides/error-handling.md` の Part ラベル
- DR-003 の再検討

## 参考資料

- ドメインモデル: `unit_003_inception_progress_naming_unification_domain_model.md`
- DR-005（`inception/decisions.md`）
- 計画: `plans/unit-003-plan.md`
