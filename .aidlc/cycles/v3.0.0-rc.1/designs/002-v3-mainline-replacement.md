# Design 002: フル本流化置換

- trace: work item 002-v3-mainline-replacement
- matrix_case: risky_standard
- design_mode: full

## Goal

`skills/aidlc-v3` を `skills/aidlc` に置換して `/aidlc` = v3 を実現し、旧 v2 実装を
main から撤去、marketplace を `3.0.0-rc.1` 化する（Epic #736 7-e）。撤去は「撤去対象の
確定リスト」に基づき、v3 が委譲利用する v2 資産は**既存パスのまま残置**して参照互換を保つ。

## Context

### 前提（調査で確定した依存構造）

- **v3 → v2 委譲（実行時依存 / 4 系統）**:
  1. `skills/aidlc/scripts/read-config.sh`（develop / doctor の depth_level・config 読取。公開 API スクリプト層）
  2. `skills/aidlc/guides/exit-code-convention.md`（doctor の exit code 規約 SoT）
  3. `skills/aidlc/steps/common/review-routing.md`（レビュー処理パス選択の正本）
  4. `skills/aidlc/steps/common/review-flow.md`（反復レビュー・Defer・機密マスクの正本）
- **read-config.sh の source 閉包**: `lib/bootstrap.sh` → `lib/toml-reader.sh` + `lib/version.sh`、
  `lib/validate.sh`、`lib/key-aliases.sh`、データとして `config/defaults.toml` と
  `.claude-plugin/marketplace.json`（version 正本）
- **v3 がスキル名で委譲するレビュースキル**: `reviewing-construction-code` / `-design`（develop Step 5）、
  `reviewing-operations-premerge` / `reviewing-construction-integration` / `reviewing-operations-deploy`
  （release Step 2）。`reviewing-construction-plan` は routing 上の capability として存在
- **他の残置スキルの v2 依存**: `aidlc-feedback` → read-config.sh のみ。`aidlc-migrate`（v2→v3 経路）→
  自己完結（`lib/path-guard.sh` 内包）+ `state-init.sh` / `state-validate.sh` の 2 候補解決
  （`../aidlc-v3/` → `../aidlc/` の順 / beta.3 003 で置換耐性整備済み）
- **v2 保全**: work item 001 で v2 実装一式を `v2-maintenance` branch へ保全済み（commit b2f02da8）。
  撤去後も v2 は branch から取得可能
- **リポジトリ規約**: `CLAUDE.md` が `skills/aidlc/steps/common/bash-tool-safety.md` と
  `skills/reviewing-common/reviewing-common-base.md` を規約詳細 / SoT として参照する（残置必須）
- **CI**: `pr-check.yml`（bash-substitution / defaults-sync / marketplace-version / markdownlint）、
  `migration-tests.yml`（v2 系 bats を広範に実行）、`skill-reference-check.yml`、
  `cycle-phase-completion-check.yml`（`bin/check-cycle-phase-completion.sh` が v2 `lib/validate.sh` と
  v3 `state-read.sh` / `work-item-status.sh` を同時 source する dual 実装）

### 制約

- 1 実行 = 1 work item = 最終 commit 1 つ（develop Step 6）
- `.aidlc/` 配下の履歴・過去 cycle 成果物、CHANGELOG 既存エントリ、docs/ の歴史的設計文書は
  書き換えない（履歴の不変原則）
- README 刷新は work item 003 のスコープ（本 work item では触れない）
- ドッグフーディング特殊処理（starter kit 自己判定分岐）を本体に埋めない

## Design

### D1. 置換方式: 「同一パス残置」原則

新 `skills/aidlc` = **v3 一式（`git mv skills/aidlc-v3` 由来） + 残置 v2 資産（既存パス不変）** の合成とする。

- v3 の cross-skill 参照（`skills/aidlc/scripts/read-config.sh` 等）は**パス文字列を一切変更せずに**
  置換後も解決される（残置資産のパスが不変のため）
- v3 内部の skill-base 相対参照（`scripts/state-read.sh` 等）はディレクトリ名変更の影響を受けない
- `skills/aidlc-v3/scripts/` と `skills/aidlc/scripts/`（残置分）にファイル名衝突なし（調査済: scripts 直下 /
  lib / templates すべて衝突ゼロ）
- `state-init.sh` が `skills/aidlc/scripts/state-init.sh` に着地することで、aidlc-migrate の
  2 候補解決は候補 2 で自然に解決される（コード変更不要）

### D2. 残置 v2 資産の確定リスト（新 skills/aidlc に既存パスのまま残す）

| 分類 | ファイル | 残置理由 |
|------|---------|---------|
| scripts | `scripts/read-config.sh` | v3 develop/doctor + aidlc-feedback + aidlc-migrate が参照する公開 API |
| scripts/lib | `lib/bootstrap.sh` / `lib/toml-reader.sh` / `lib/version.sh` / `lib/validate.sh` / `lib/key-aliases.sh` | read-config.sh の source 閉包 + `bin/check-cycle-phase-completion.sh`（validate.sh）+ `bin/check-marketplace-version.sh` / `bin/update-version.sh`（version.sh） |
| config | `config/defaults.toml` | 4 階層マージの既定値正本（read-config.sh / review-routing.md が参照） |
| config | `config/config.toml.example` | 設定表面のドキュメント（consumer 向け設定例） |
| steps/common | `review-routing.md` / `review-flow.md` / `review-flow-reference.md` / `rules-core.md` | v3 develop Step 5 / release Step 2 の委譲正本 + その発リンク閉包（rules-core.md はスコープ保護 + 公開 API 規約） |
| steps/common | `bash-tool-safety.md` | CLAUDE.md（リポジトリ規約）が参照する運用ガイド |
| guides | `exit-code-convention.md` | v3 doctor の exit code 規約 SoT |

上記**以外**の v2 `skills/aidlc` 配下（SKILL.md、steps/inception|construction|operations/、
steps/common の他 13 ファイル、guides の他 20 ファイル、templates 28 ファイル、agents/、
scripts 直下の他 34 本、scripts/lib の他 13 本、config/retrospective-schema.yml）は撤去する。

**発リンク閉包ルール**: 残置 md が撤去対象を参照する箇所は、残置 md 側の参照記述を除去する（D6）。
実装時に残置 md の発リンクを再走査し、「リンク先残置 or 参照除去」の閉包を確認する。

### D3. スキル単位の撤去確定リスト

| スキル | 判断 | 根拠 |
|--------|------|------|
| `skills/aidlc`（v2 本体） | D2 残置分を除き撤去 | v3 で置換 |
| `skills/aidlc-v3` | `skills/aidlc` へ改名（git mv） | 本流化の実体 |
| `skills/aidlc-setup` | 撤去 | v2 専用セットアップ。v3 は config.toml 不在時に defaults へ正規化して動作（doctor が診断）。defaults-sync の対向も消滅 |
| `skills/aidlc-retrospective` | 撤去 | v3 reflect は自己完結（v3 から参照ゼロ / marketplace 未登録） |
| `skills/squash-unit` | 撤去 | v2 commit-flow 専用。v3 は work item 単位 1 commit |
| `skills/write-history` | 撤去 | v2 history 専用。v3 は journal.md 直接追記 |
| `skills/install-kiro-agent` | 撤去 | v2 テンプレート（templates/kiro/）依存 / marketplace 未登録 |
| `skills/reviewing-inception-intent` / `-stories` / `-units` | 撤去 | v3 define にレビューゲートなし（stories 承認は廃止 / workflow.md §5.1） |
| `skills/reviewing-construction-plan` / `-design` / `-code` / `-integration` | 残置 | v3 develop/release が委譲（plan は routing capability） |
| `skills/reviewing-operations-deploy` / `-premerge` | 残置 | v3 release Step 2 が委譲 |
| `skills/reviewing-common` | 残置（非配布） | reviewing-\* の references 同期正本 + CLAUDE.md の stdin ガード SoT |
| `skills/aidlc-feedback` | 残置 | 世代非依存（read-config.sh のみに依存） |
| `skills/aidlc-migrate` | 残置 + v2→v3 専用化（D4） | intent AC「v2→v3 migration 経路の維持」 |

### D4. aidlc-migrate の v2→v3 専用化

v1→v2 移行は「v2 実装を生成する経路」であり、v2 が main に存在しない以上 main 上では機能しない
（さらに aidlc-setup / write-config.sh / feedback-mode.sh 等の v2 資産残置を強制する）。よって:

- **SKILL.md ルーティング変更**: v1 マーカー（`docs/aidlc.toml`）検出時は v1→v2 フローに入らず、
  「v1→v2 移行は `v2-maintenance` branch の aidlc-migrate を使用 → その後 main の v2→v3 移行」を
  案内して終了する（読み取り専用）
- **撤去**: `steps/01-preflight.md` / `02-execute.md` / `03-verify.md`、
  `scripts/migrate-{detect,apply-config,apply-data,cleanup,feedback-mode,relocate-prefs,verify}.sh`、
  `scripts/tests/`（v1 系 2 本）、`config/known-hashes.json`（v1 検出用）
- **残置**: `steps/v3-migrate.md`（案内表記を `/aidlc define` に更新）、
  `scripts/migrate-v3-{preflight,config,archive-index}.sh`、`scripts/lib/path-guard.sh`
- 2 候補解決コード（preflight L44–68 / v3-migrate.md Step 5）は**無変更**。置換後は候補 1
  （`../aidlc-v3/`）不在 → 候補 2（`../aidlc/`）解決となることを検証で確認する（AC 該当）

### D5. marketplace.json

- `metadata.version`: `3.0.0-beta.2` → `3.0.0-rc.1`
- `plugins[0].skills`: 16 → **9 エントリ**

```text
./skills/aidlc                            （= v3）
./skills/aidlc-migrate
./skills/aidlc-feedback
./skills/reviewing-construction-plan
./skills/reviewing-construction-design
./skills/reviewing-construction-code
./skills/reviewing-construction-integration
./skills/reviewing-operations-deploy
./skills/reviewing-operations-premerge
```

（`./skills/aidlc-v3` エントリ削除 = 旧 v2 の `./skills/aidlc` エントリが v3 実体を指す。
撤去スキルのエントリ削除で計 9。当初「10 エントリ」と記載していたが列挙どおり 9 が正
〔release 統合レビュー指摘 #2 で訂正〕）

### D6. 残置 md の v2 固有記述の整理（発リンク閉包）

- **review-routing.md**: inception 3 perspective（intent / stories / units）の行と関連フォールバック記述を
  除去。plan / design / code / integration / deploy / premerge の 6 perspective とパス選択・フォールバック
  ロジックは無変更で維持
- **review-flow.md**: v3 が「使わない」と明示するサブセクション（レビュー前後の三段階コミット /
  review-summary 更新 / history 配置 / `write-history` 呼び出し / `operations-release.sh` 言及）と
  撤去ファイルへの参照を除去。**反復レビュー・5R 完了判定・千日手検出・スコープ保護・Defer 自動
  Issue 化・機密マスクのロジックは無変更で維持**（workflow.md §5.2 の方法論ロジック保全）
- **rules-core.md / review-flow-reference.md / bash-tool-safety.md / exit-code-convention.md**:
  撤去ファイルへの参照箇所のみ除去 / 表記調整（ロジック変更なし）
- **v3 SKILL.md**: frontmatter `name: aidlc-v3` → `aidlc`、共存前提の位置づけ注記（「現時点の起動表面は
  /aidlc-v3」等）を本流化済みの記述へ書き換え。旧名エイリアス（inception / construction / operations /
  retrospective）は維持

### D7. 表記更新（`/aidlc-v3` → `/aidlc`）と参照整合の対象一覧

| 領域 | ファイル | 変更 |
|------|---------|------|
| v3 steps | `steps/{define,status,develop,release,reflect,doctor}.md` | `/aidlc-v3` → `/aidlc`（23 箇所） |
| v3 scripts | `scripts/doctor.sh` | パス解決コメント + 出力文字列の表記 |
| v3 tests | `scripts/tests/`（test-activation / test-status / test-doctor / test-release-flow / test-reflect-flow 等） | パス・表記の整合 |
| migrate | `steps/v3-migrate.md` | 次アクション案内 `/aidlc-v3 define` → `/aidlc define`（2 候補解決の説明表記は実態どおり維持） |
| bin | `check-cycle-phase-completion.sh` / `check-frontmatter-parse-guard.sh` / `bin/tests/check-frontmatter-parse-guard.sh` | `skills/aidlc-v3/scripts` → `skills/aidlc/scripts` |
| bin | `check-skill-references.sh` | allowlist の `aidlc-v3/steps/*` → `aidlc/steps/*`、撤去スキル項目（aidlc-retrospective / write-history 等）の削除 |
| bin | `sync-reviewing-common.sh` | 同期先 9 → 6 スキル |
| bin | `check-defaults-sync.sh` | 撤去（対向 aidlc-setup/config/defaults.toml が消滅） |
| CI | `pr-check.yml` | defaults-sync-check ジョブ削除 |
| CI | `migration-tests.yml` | PATHS_REGEX と bats 実行リストを存続テスト（下記 D8）へ削減 |
| CI | `skill-reference-check.yml` | コメント表記（aidlc-v3 consumers）の更新 |
| CI | `cycle-phase-completion-check.yml` | 無変更（bin スクリプト側の更新で吸収） |

### D8. tests/ の存続・撤去

- **存続**: `tests/migration/`（migrate-v3-preflight / -v3-config / -v3-archive-index）、
  `tests/config-defaults/`、`tests/check-cycle-phase-completion.bats`（+ fixtures / パス更新）、
  `tests/feedback-route-resolution.bats`、v3 内部テスト `skills/aidlc/scripts/tests/` 全 11 本
- **撤去**: retrospective 系全 bats（tests/retrospective\* + tests 直下 retrospective-\*.bats）、
  operations-\* 系、write-history-\* 系、predecessor-issue-\*、main-repo-health-check.bats、
  cycle-resolver.bats、feedback-cap-by-mode / feedback-mode-wizard / feedback-mode-migration、
  validate-unit-slug.bats、aidlc-helpers-\*.bats、tests/aidlc-setup/、tests/aidlc-migrate-prefs/、
  tests/migration/ の v1→v2 系（migrate-detect / -apply-config / -apply-data / -cleanup / -verify /
  e2e-full-flow の v1 経路分）、対応 fixtures（v1-structure / v2-config-generations /
  aidlc-migrate-prefs / retrospective\* / gh-pr-edit-fallback 等）
- e2e-full-flow が v1→v2 と v2→v3 を跨ぐ場合は v2→v3 部分のみ存続させる（実装時に分割判断）
- **設計変更（実装時 / release 統合レビュー指摘 #1 で追記）**: `migrate-path-traversal.bats` は当初
  「v3 該当分を存続」としたが、テスト対象の大半（`migrate-apply-config.sh` / `migrate-apply-data.sh` /
  `migrate-cleanup.sh` = v1→v2 系）が D4 で撤去されたため、テストファイルごと撤去した（復元検証で
  12 件中 9 件が対象スクリプト不在で fail することを確認済み）。存続する `scripts/lib/path-guard.sh` の
  symlink escape / 初期化異常 / `realpath -m` フォールバックの回帰テスト移植は Issue #757 で後続対応とする

### D9. 触れないもの（履歴の不変原則）

- `.aidlc/` 配下の全履歴（過去 cycle 成果物 / journal / state）
- `CHANGELOG.md` 既存エントリ（rc.1 エントリ追記は release フェーズの責務）
- `docs/v3-renewal-plan.md` / `docs/v3/rfc.md` 等の歴史的設計記述（`/aidlc-v3` 表記は当時の事実）
- `README.md`（work item 003 のスコープ）
- `.aidlc/config.toml` の `[rules.squash.internal_ci_checks]` 等のプロジェクトローカル設定
  （squash-unit 撤去後は opt-in シグナル不成立で自然 skip される設計のため無害）

### 実装手順

1. **残置抽出**: v2 `skills/aidlc` から D2 リスト以外を `git rm`
2. **置換**: `git mv skills/aidlc-v3/<各エントリ> skills/aidlc/`（残置資産と合成 / 衝突なし確認済み）
3. **表記更新**: D6 / D7 の SKILL.md・steps・scripts・tests の書き換え
4. **スキル撤去**: D3 の 8 スキルディレクトリを `git rm`
5. **migrate 専用化**: D4 の SKILL.md ルーティング変更 + v1 系撤去
6. **marketplace / bin / CI / tests**: D5 / D7 / D8 の更新
7. **検証**（下記）→ Step 5 レビュー（code_security）→ Step 6 で単一 commit

### 検証（Acceptance Criteria 対応）

| AC | 検証方法 |
|----|---------|
| `/aidlc` = v3 ルーティング | `skills/aidlc-v3` 不存在 + `skills/aidlc/SKILL.md` frontmatter `name: aidlc` + v3 steps 実在 + `skills/aidlc/scripts/tests/test-activation.sh` pass |
| 旧 v2 実装が main に残存しない | D2 残置リスト以外の v2 ファイル不存在を確認 + `grep -r 'skills/aidlc-v3'` の残存が履歴（.aidlc/ / CHANGELOG / docs）のみ |
| marketplace = rc.1 / 9 skills | jq で version / skills 配列検証 + `bin/check-marketplace-version.sh` |
| migration 経路維持 | `tests/migration/` v3 系 bats pass + 2 候補解決が候補 2（`skills/aidlc/scripts/state-init.sh`）で解決することの fixture 確認 |
| CI 全 green | ローカルで bin checks（skill-references / frontmatter-parse-guard / bash-substitution / test-isolation / size）+ 存続 bats 全件 + v3 内部テスト 11 本 + shellcheck（変更 sh）+ `npx markdownlint-cli2` |

## Rollback Note

- **保全先**: v2 実装一式は `v2-maintenance` branch（commit b2f02da8 で保全済み）に存在し、
  撤去後も `git checkout v2-maintenance -- <path>` で任意ファイルを選択復元できる
- **cycle branch 上の切り戻し**: 本 work item は最終 commit 1 つに集約するため、問題発覚時は
  `git revert <commit>` 1 回で置換前状態（v2 + aidlc-v3 共存）へ完全に戻せる。work item status は
  frontmatter を `in_progress` に手動で戻し、journal に revert 記録を追記する
- **main への影響時期**: main には release フェーズの PR merge まで一切影響しない。merge 後に
  致命問題が出た場合は revert PR で本流化前へ戻し、v2 は v2-maintenance から復元する
- **配布物の切り戻し**: marketplace 配布はタグ / リリース単位のため、rc.1 タグ公開前なら consumer
  影響ゼロ。公開後は `metadata.version` を戻した hotfix release を発行する（既存 consumer は旧
  バージョン pin のまま影響を受けない）
- **移行データの安全性**: 本 work item は consumer プロジェクトのデータ（`.aidlc/`）を一切変更しない
  ため、ロールバックにデータ復旧は不要
