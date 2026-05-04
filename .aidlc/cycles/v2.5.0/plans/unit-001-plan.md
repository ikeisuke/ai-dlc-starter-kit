# Unit 001 計画: 個人好みキーの defaults.toml 集約

## 概要

`config.toml.template` から「個人好み」7 キーを除去し、`skills/aidlc/config/defaults.toml` に既定値を集約する。4 階層マージ仕様（spec: defaults < user-global < project < project.local）の枠組みを変えず、新規 `aidlc-setup` で生成される `.aidlc/config.toml`（project 共有）から「個人好み」キーが消えることを保証する。既存プロジェクトの project `.aidlc/config.toml` に同キーが残っていても引き続き読み取れる後方互換を維持する。

## 対象キー（user_stories.md ストーリー 1 の正規定義）

本サイクル内全ファイルで以下の 7 キーを「個人好みキー」として同一定義で扱う:

| # | キー | template 現値 | defaults.toml 現値 | 一致 |
|---|------|--------------|---------------------|------|
| 1 | `rules.reviewing.mode` | `"recommend"` | `"recommend"` | ✓ |
| 2 | `rules.reviewing.tools` | `["codex"]` | `["codex"]` | ✓ |
| 3 | `rules.automation.mode` | `"manual"` | `"manual"` | ✓ |
| 4 | `rules.git.squash_enabled` | `false` | `false` | ✓ |
| 5 | `rules.git.ai_author` | `""` | `""` | ✓ |
| 6 | `rules.git.ai_author_auto_detect` | `true` | `true` | ✓ |
| 7 | `rules.linting.enabled` | `false` | `false` | ✓ |

**結論**: defaults.toml には既に全 7 キーが「template 現値と完全一致」で存在する。Unit 001 の主作業は **template からの除去** とテスト追加。defaults.toml への新規追加は発生しない（NFR「既定値同等性」を満たす確認のみ）。

## 現状分析

### `skills/aidlc-setup/templates/config.toml.template` の該当箇所

- `[rules.git]` セクション内（行 31〜49）: `squash_enabled` / `ai_author` / `ai_author_auto_detect` の 3 キー（先頭・末尾コメントを含む）
- `[rules.reviewing]` セクション内（行 54〜69）: `mode` / `tools` の 2 キー（コメントを含む）
- `[rules.linting]` セクション内（行 71〜75）: `enabled` の 1 キー（コメントを含む）
- `[rules.automation]` セクション内（行 84〜89）: `mode` の 1 キー（コメントを含む）

### `skills/aidlc/config/defaults.toml` の該当箇所

- 上記 7 キー全てが既に存在（行 5〜57）。本 Unit では追加・編集は行わず、template 削除後の動作確認に使用する。

### 4 階層マージ仕様

`scripts/read-config.sh` および `scripts/lib/bootstrap.sh` に既に実装済み（spec §config-merge）。本 Unit では既存マージロジックを変更せず、テストでマージ後の解決値を検証するのみ。

## 変更対象ファイル

### Phase 1: テンプレート差分

1. **`skills/aidlc-setup/templates/config.toml.template`** — 7 キー＋関連コメントを除去
   - `[rules.git]` セクション: `squash_enabled` / `ai_author` / `ai_author_auto_detect` 削除（`commit_on_unit_complete` / `commit_on_phase_complete` / `branch_mode` / `unit_branch_enabled` は **残す**: プロジェクト強制カテゴリ）
   - `[rules.reviewing]` セクション: `mode` / `tools` 削除（`exclude_patterns` の説明コメントは残す。コメントアウト例 `# exclude_patterns = ...` も残す）
   - `[rules.linting]` セクション: `enabled` 削除。セクションヘッダ・コメントは保持し空セクション化を避けるため、`[rules.linting]` セクション全体を削除する（defaults 側で完結）
   - `[rules.automation]` セクション: `mode` 削除。同様に `[rules.automation]` セクション全体を削除
   - **保持理由（プロジェクト強制カテゴリ）**: `project.*` / `rules.coding.*` / `rules.security.*` / `rules.documentation.*` / `rules.git.commit_on_*` / `rules.git.branch_mode` / `rules.git.unit_branch_enabled` / `rules.feedback.enabled` / `rules.custom` / `[inception]`

2. **`skills/aidlc/config/defaults.toml`** — **編集なし**（全 7 キーが既に正しい値で存在）。本 Unit ではテストで「template 除去後も既定値が defaults から取得できる」ことを保証する。

### Phase 2: テスト追加（bats 形式に確定）

既存 `tests/migration/*.bats` の bats 慣行に合わせて Unit 001 用テストを `tests/config-defaults/` ディレクトリに配置する。bats バイナリは既に CI / ローカル環境（`/opt/homebrew/bin/bats` / CI: `npm i -g bats@1.11.1`）で利用可能。

**テストファイル**:

- `tests/config-defaults/template-removed-keys.bats` — **観点 A**（template: grep/awk ベース section + leaf 検査 / example: `aidlc_read_toml` ベース dotted_path 検査の 2 経路）
- `tests/config-defaults/defaults-resolution.bats` — **観点 B1 / B2**（後方互換 NFR の二面検証）

**観点 A: template / example に対象 7 キーが含まれない（実装で 2 経路に分割）**

実装で判明した制約により、検査方式は対象ファイルに応じて 2 経路に分かれる:

- **template（`skills/aidlc-setup/templates/config.toml.template`）**: ファイルが project プレースホルダ（例: `[プロジェクト名]` / `[[言語リスト]]`）を含む **invalid TOML** のため、TOML パーサ（`dasel` / `aidlc_read_toml`）では構造解析できない。`grep`／`awk` ベースで `[section]` ヘッダ存在検査と「セクション直下の葉キー = 行」検査を組み合わせて実装する（`tests/config-defaults/helpers/setup.bash` の `template_has_section` / `template_has_section_leaf`）
- **example（`skills/aidlc/config/config.toml.example`）**: valid TOML のため `aidlc_read_toml`（dasel v2/v3 互換ライブラリ）で dotted_path 検査を行う（`tests/config-defaults/helpers/setup.bash` の `example_has_key`）

これにより「`mode` という葉キーが他セクション（例: `[rules.git]` の `branch_mode`）にマッチする」grep 誤検知を、template 側では section + leaf 連動チェックで防ぐ。

**観点 B: defaults / project の優先順位検証（B1 / B2 の二面検証）**

| 観点 | 前提 | 期待動作 | NFR との対応 |
|------|------|---------|-------------|
| **B1** | project `.aidlc/config.toml` に対象 7 キーが**無い** | `read-config.sh --keys <7キー>` が **defaults.toml の値**を返す | 「既定値同等性」NFR — defaults が template 旧値と等価で機能することを保証 |
| **B2** | project `.aidlc/config.toml` に対象 7 キーが**ある**（既存プロジェクトを模した状態） | `read-config.sh --keys <7キー>` が **project の値**を返す（defaults を上書き） | 「後方互換」NFR — 4 階層マージで project 値が優先される既存挙動の維持を保証 |

両観点とも `tests/fixtures/config-defaults/` 配下に最小ヘッダのみの project config（B1 用）と 7 キー記述済み project config（B2 用）を fixture として配置し、一時ディレクトリ＋環境変数 `AIDLC_PROJECT_ROOT` で切り替えて検証する（既存 `tests/migration/` の bats helper パターンに準拠）。

**実行コマンド**: `bats tests/config-defaults/`

### Phase 3: CI 接続

`.github/workflows/migration-tests.yml` を最小拡張し、Unit 001 のテストも CI で実行されるようにする:

- **PATHS_REGEX 拡張**: 既存 `tests/migration/.+` に加えて `tests/config-defaults/.+` および `skills/aidlc-setup/templates/config.toml.template` / `skills/aidlc/config/defaults.toml` を検出対象に追加
- **実行コマンド変更**: `bats tests/migration/` → `bats tests/migration/ tests/config-defaults/`
- **ジョブ名・ワークフロー名**: 「Migration Tests」名のままだと意味が乖離するため、ジョブ表示名のみ「Bash Tests (migration + config-defaults)」相当に調整可（要・実装時最終確認。既存名維持でも機能上は問題なし）

**新規 workflow ファイルは作成しない**（CI 構造の最小差分維持）。

### Phase 4: ドキュメント整合

4. `skills/aidlc/config/config.toml.example` の所有 Unit を **Unit 001 に確定**。Unit 002（aidlc-setup ウィザード案内）は example を参照のみで編集しない。
   - **方針確定**: example からは対象 7 キーの**実値を削除**し、**コメント例（`# rules.reviewing.mode = "recommend"` 形式）も残さない**（template と同じ単純除去ルール）。`[rules.linting]` / `[rules.automation]` の対象キーが全て個人好みのセクションは template と同様にセクション全体を削除。`[rules.git]` / `[rules.reviewing]` はセクションヘッダのみ保持（プロジェクト強制キーが残るため）。
   - **理由**: 「個人好みは user-global 推奨」の案内文言は Unit 002（aidlc-setup ウィザード）が単一ソースとして担うため、example でコメント例を残すと文言の二重保守を生む。example は「project 共有に何を書くべきか」のリファレンス機能に特化させる。
5. `skills/aidlc-setup/config/defaults.toml` は `skills/aidlc/config/defaults.toml` の同期コピー（`bin/check-defaults-sync.sh` で監視）。本 Unit では正本（`skills/aidlc/config/defaults.toml`）に変更を加えないため sync チェックには影響しないが、想定外の差分が発生していないかを `check-defaults-sync.sh` で実装時に確認する。

## 実装計画

### 設計方針

- **defaults.toml 不変原則**: 本 Unit では defaults.toml を編集しない。既に正しい値で 7 キーが揃っているため、追加変更は破壊的差分のリスクがある。
- **template 削除の単位**: 個別キー行のみではなく「セクションごと整理」で行う。`[rules.linting]` / `[rules.automation]` は対象キーが全て個人好みのためセクション全体を削除。`[rules.git]` / `[rules.reviewing]` はプロジェクト強制キーが残るためセクションヘッダは保持し対象キー行＋関連コメントのみを削除。
- **後方互換**: 既存プロジェクトの project `.aidlc/config.toml` に対象キーが残っていても、4 階層マージで project 値が優先される（既存の挙動）。本 Unit では既存マージロジックを変更しない。
- **dry-run 検証**: テスト追加時に一時ディレクトリで read-config.sh を呼び、defaults 値が返ることを確認するため、bootstrap.sh の `AIDLC_PROJECT_ROOT` を一時パスに切り替えられる仕組みを使う（既存テスト群の慣行を踏襲）。

### Unit 002 / 003 との境界

| 論点 | 所有 Unit | 他 Unit の扱い |
|------|----------|---------------|
| `config.toml.template` の 7 キー除去 | Unit 001 | Unit 002 / 003 は変更しない |
| `defaults.toml`（正本: `skills/aidlc/config/defaults.toml`）の 7 キー値 | Unit 001（変更なし、現値の維持確認のみ） | Unit 002 / 003 は変更しない |
| `defaults.toml`（同期コピー: `skills/aidlc-setup/config/defaults.toml`）| Unit 001（同期確認のみ。`bin/check-defaults-sync.sh` で監視） | Unit 002 / 003 は変更しない |
| `config.toml.example` の編集 | **Unit 001**（template と整合） | Unit 002 は参照のみ・編集しない |
| `aidlc-setup` ウィザード UI 文言 | Unit 002 | Unit 001 / 003 は触れない |
| `aidlc-migrate` 移動提案ロジック | Unit 003 | Unit 001 / 002 は触れない |
| 「個人好みは `~/.aidlc/config.toml`」推奨文言 | Unit 002（master）/ Unit 003（参照） | Unit 001 は本文を持たない |

- **Unit 002（aidlc-setup ウィザード案内）**: 本 Unit の template 差分が確定した後、ウィザード UI 文言を追加する。本 Unit では UI 文言には触れない。
- **Unit 003（aidlc-migrate 移動提案）**: 本 Unit の template 差分が確定した後、既存プロジェクトの project `.aidlc/config.toml` から該当 7 キーを検出して移動提案する。本 Unit では migrate 側を変更しない。

### ステップ

1. `config.toml.template` から対象 7 キーと関連コメント・空セクションを除去
2. `config.toml.example` に同キーが含まれている場合は同様に削除（差分整合）
3. `bin/check-defaults-sync.sh` を実行し、正本／コピーの sync が崩れていないことを確認（本 Unit は defaults.toml を編集しないが回帰防止のため）
4. defaults.toml（正本）に全 7 キーが正しい値で存在することを `read-config.sh` 経由で確認（編集なし）
5. テスト追加: `tests/config-defaults/template-removed-keys.bats`（観点 A）/ `tests/config-defaults/defaults-resolution.bats`（観点 B1+B2）
6. fixture 配置: `tests/fixtures/config-defaults/` に B1（7 キー無し project config）/ B2（7 キー有り project config）を作成
7. CI 接続: `.github/workflows/migration-tests.yml` の `PATHS_REGEX` を拡張し、実行コマンドを `bats tests/migration/ tests/config-defaults/` に変更
8. ローカルでテスト実行（`bats tests/migration/ tests/config-defaults/`）— 既存テストへの回帰がないことも確認
9. markdownlint 実行（`.md` 変更があれば）
10. コミット

## 完了条件チェックリスト

- [ ] `skills/aidlc-setup/templates/config.toml.template` から対象 7 キー（`rules.reviewing.mode` / `rules.reviewing.tools` / `rules.automation.mode` / `rules.git.squash_enabled` / `rules.git.ai_author` / `rules.git.ai_author_auto_detect` / `rules.linting.enabled`）が完全に削除されている
- [ ] template から削除した 7 キーが `skills/aidlc/config/defaults.toml` に「template 旧値と同等」で存在する（同等性確認）
- [ ] `skills/aidlc-setup/config/defaults.toml`（同期コピー）と正本（`skills/aidlc/config/defaults.toml`）の sync が崩れていない（`bin/check-defaults-sync.sh` がパス）
- [ ] `[rules.linting]` / `[rules.automation]` の空セクションが template に残っていない
- [ ] プロジェクト強制カテゴリのキー（例: `rules.git.branch_mode` / `rules.git.unit_branch_enabled` / `rules.git.commit_on_*` / `rules.feedback.enabled` 等）は template に残っている
- [ ] **観点 A テスト**: `tests/config-defaults/template-removed-keys.bats` が、template 側は grep/awk ベースで section + 葉キーが存在しないこと、example 側は `aidlc_read_toml`（dasel v2/v3 互換）で dotted_path が存在しないことを 2 経路で検証する（template が invalid TOML のため）
- [ ] **観点 B1 テスト**: `tests/config-defaults/defaults-resolution.bats` が、project `.aidlc/config.toml` に対象 7 キー無しの状態で `read-config.sh --keys ...` が defaults 値を返すことを検証する
- [ ] **観点 B2 テスト**: 同 bats が、project `.aidlc/config.toml` に対象 7 キー有りの状態で `read-config.sh --keys ...` が project 値を返すこと（後方互換 NFR）を検証する
- [ ] CI 接続: `.github/workflows/migration-tests.yml` の `PATHS_REGEX` と実行コマンドが拡張され、PR 上で `bats tests/config-defaults/` が走る
- [ ] 既存の `tests/migration/` のテストが回帰せずパスする
- [ ] `config.toml.example` が template と整合（対象 7 キーの実値もコメント例も含まれない。`[rules.linting]` / `[rules.automation]` セクション全体は削除、`[rules.git]` / `[rules.reviewing]` はセクションヘッダ保持）
- [ ] 4 階層マージロジック（`scripts/read-config.sh` / `scripts/lib/bootstrap.sh`）に変更が入っていない（既存挙動の維持）
- [ ] `.md` 差分があれば markdownlint パス

## NFR チェック

- **後方互換**: 既存プロジェクトの project `.aidlc/config.toml` に同キーが残っていても 4 階層マージで読み取れる（破壊的変更なし）— 観点 B テストでマージ動作確認
- **既定値同等性**: defaults.toml に移したキーの値は template 旧値と一致（NFR 完了条件項目で明示確認）
- **冪等性**: template の再生成（aidlc-setup 再実行）でも対象キーが復活しない

## 想定リスクと対策

| リスク | 対策 |
|--------|------|
| `[rules.linting]` / `[rules.automation]` セクション全削除でユーザーがセクションヘッダ自体を期待しているケース | `defaults.toml` 側にセクションが存在するため `read-config.sh` 経由ではセクション欠落として観測されない。template から除去するのは「project 共有の単純化」目的であり、user-global / defaults 経路で値は供給される |
| `config.toml.example` の差分が template と乖離して保守コストが増える | 所有 Unit を **Unit 001 に確定**し（Unit 002 / 003 は参照のみ）、template と同一スタンスで 7 キーの**実値もコメント例も削除**する。「user-global 推奨」案内文言は Unit 002（aidlc-setup ウィザード）に単一ソース化し、example での重複保守を排除 |
| `bin/check-defaults-sync.sh` の sync チェック失敗（正本／コピーの不整合が想定外に発生） | 本 Unit は正本（`skills/aidlc/config/defaults.toml`）を編集しないため新規不整合は発生しない見込みだが、ステップ 3 で `check-defaults-sync.sh` を必ず実行して回帰防止する |
| `migration-tests.yml` の PATHS_REGEX 拡張で既存ジョブの skip 判定が誤動作 | 拡張前後で「migration 関連 PR は引き続き走る」「config-defaults 関連 PR で新たに走る」をローカルで `gh api` を使わない論理確認（regex 単体テスト）で確認してから push |

## 関連 Issue

- #592（部分対応: 実装スコープ 1, 2 を担当）

## 見積もり

0.5 セッション（小規模、テンプレート差分主体）
