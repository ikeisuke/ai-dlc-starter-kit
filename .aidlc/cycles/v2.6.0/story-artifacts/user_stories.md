# ユーザーストーリー: v2.6.0

## Epic 1: バージョン管理 SoT 一本化（#617 + #618）

### ストーリー 1A: marketplace.json への version 参照経路移行

**優先順位**: Must-have

As an AI-DLC スターターキット利用者
I want to バージョン参照（read 経路）が `marketplace.json` を SoT として動作するようにしたい
So that リリースバージョンとプラグインの表示が常に一致し、誤インストール・乖離が発生しない

**受け入れ基準**:

- [ ] `.claude-plugin/marketplace.json` の `metadata.version` が `2.6.0` にバックフィル更新されている（コマンド: `dasel -i json -r json '.metadata.version' < .claude-plugin/marketplace.json` の出力が `2.6.0`）
- [ ] `skills/aidlc/SKILL.md` の `version` アクションが `marketplace.json.metadata.version` を読み込み、`/aidlc version` 実行時の表示が `marketplace.json` 値と完全一致する（手動実行で `AI-DLC Starter Kit v2.6.0` を確認）
- [ ] `skills/aidlc/steps/inception/01-setup.md` ステップ5a の 3 経路（リモート / スキル / ローカル）がすべて `marketplace.json` 参照に書き換えられ、各経路で同一値（`2.6.0`）を返す
- [ ] `skills/aidlc/scripts/env-info.sh` の `get_starter_kit_version()` が `marketplace.json.metadata.version` を返す（実行コマンド: `bash skills/aidlc/scripts/env-info.sh | grep starter_kit_version` の出力が `starter_kit_version:2.6.0`）
- [ ] `skills/aidlc/scripts/lib/version.sh` の `read_starter_kit_version()` が `marketplace.json` を一次ソースとして参照する
- [ ] 異常系: `marketplace.json` 不在 / 不正 JSON 時、各経路でエラーメッセージを表示して exit non-zero（暗黙の空文字フォールバックを行わない）

### ストーリー 1B: bin/update-version.sh の marketplace.json 主体化

**優先順位**: Must-have

As an AI-DLC スターターキット開発者
I want to `bin/update-version.sh` でバージョンを更新したときに `marketplace.json` も同期更新したい
So that リリース時に Plugin Marketplace 表示の同期漏れが構造的に発生しない

**受け入れ基準**:

- [ ] `bin/update-version.sh --version 2.6.0` 実行時、`.claude-plugin/marketplace.json.metadata.version` が `2.6.0` に更新される
- [ ] `bin/update-version.sh --version 2.6.0 --dry-run` 実行時、`marketplace.json` への変更内容（before/after）が標準出力に表示される
- [ ] 既存の `version.txt` 系 3 ファイル更新ロジックは、ストーリー 1D 完了までは並行更新を維持する（`update-version.sh` の段階的移行）
- [ ] エラー時に exit code 1 を返す（既存仕様維持）
- [ ] 異常系: `marketplace.json` 不在 / 不正 JSON 時、`error:marketplace-json-invalid` を出力して exit 1

### ストーリー 1C: pre-release / CI ガード追加

**優先順位**: Should-have

As an AI-DLC スターターキット開発者
I want to `marketplace.json.metadata.version` が他のバージョン情報と乖離している状態をリリース前に自動検出したい
So that 同期漏れによる Plugin Marketplace 表示乖離を再発させない

**受け入れ基準**:

- [ ] `bin/` 配下または `.github/workflows/` 配下に「`marketplace.json` バージョン整合性チェック」スクリプトが追加されている
- [ ] チェックスクリプトは「最新の git tag（`v*`）」と「`marketplace.json.metadata.version`」を比較し、不一致時 exit 1 + 差分を stderr に出力する
- [ ] CI（既存 GitHub Actions workflow または新規 workflow）で当該チェックが Pull Request 時に実行され、不一致 PR は merge ブロックされる
- [ ] チェックスクリプトに `--help` オプションがあり、使い方を表示する
- [ ] 異常系: チェック実行時に `marketplace.json` 不在 / 不正 JSON / git tag 不在の場合、明確なエラーメッセージを表示して exit 1

### ストーリー 1D: 冗長 version.txt 3 ファイルの廃止

**優先順位**: Should-have

As an AI-DLC スターターキット開発者
I want to ストーリー 1A〜1C 完了後、冗長な `version.txt` 系 3 ファイルを削除したい
So that バージョン情報の SoT が `marketplace.json` のみとなり、責務境界が明確になる

**受け入れ基準**:

- [ ] ストーリー 1A / 1B / 1C がすべて完了している（参照経路移行・update-version.sh 改修・CI ガード稼働）
- [ ] ルート `version.txt` / `skills/aidlc/version.txt` / `skills/aidlc-setup/version.txt` の 3 ファイルが削除されている
- [ ] `bin/update-version.sh` から `version.txt` 系 3 ファイル更新ロジックが削除されている
- [ ] `git grep "version\.txt"` の検索結果に **規範的な参照** が残らない（過去サイクルの履歴・CHANGELOG・ドキュメント言及は除外。スクリプト/SKILL/設定ファイルの実行参照のみゼロ）
- [ ] 異常系: 削除実行前にストーリー 1A〜1C 未完了が検出された場合、削除を拒否して exit 1（誤順序防止）

### ストーリー 2: aidlc-setup の starter_kit_version-only 差分 no-op スキップ

**優先順位**: Should-have

As an AI-DLC スターターキット利用者
I want to アップグレード適用時、差分が `starter_kit_version` だけのときに無駄な書き込みを発生させたくない
So that アップグレード実行ログがクリーンになり、不要なファイル変更で git status が汚れない

**受け入れ基準**:

- [ ] `aidlc-setup` のアップグレード判定で「適用前 / 適用後の差分が `config.toml.starter_kit_version` のみ」の場合、no-op スキップする（実書き込みを行わない）
- [ ] スキップ時のメッセージ: `「変更不要のためスキップしました（差分: starter_kit_version のみ）」` を stdout に表示
- [ ] スキップ判定は **ストーリー 1A の SoT 一本化完了後** に動作する（`marketplace.json` を SoT として参照するため）
- [ ] 通常のアップグレード（他のフィールド差分あり）では従来通り全項目を更新する
- [ ] 異常系: 差分検出に失敗した場合、警告（`warn:diff-detection-failed:fallback-to-full-update`）を stdout に表示して **安全側に倒し従来動作（全更新）** を実行する

---

## Epic 2: GitHub Projects 移行（#673）

### ストーリー 3: GitHub Projects (ProjectsV2) フル移行

**優先順位**: Must-have

As an AI-DLC メンテナ
I want to バックログを GitHub Projects で動的に管理したい
So that Issue Close 時の手動編集（#524 編集）が不要になり、Status / Priority / Cycle / Type の動的フィルタで次サイクル候補を素早く決定できる

**受け入れ基準**（具体的検証コマンド付き）:

- [ ] gh CLI トークンスコープ拡張ガイド（`gh auth refresh -s project,read:project`）が `docs/` または `README.md` に手順として記載されている（grep 検証: `git grep -n "gh auth refresh -s project" docs/ README.md` でヒット 1 件以上）
- [ ] ProjectsV2 が作成されている（検証: `gh project list --owner ikeisuke --format json | jq '.[] | select(.title=="<projectのtitle>")'` でヒット 1 件）
- [ ] フィールド `Status` が単一選択フィールドで、選択肢が `Backlog` / `Next` / `In Progress` / `Review` / `Done` の 5 値（検証: `gh project field-list <project-number> --owner ikeisuke --format json | jq` で 5 値の選択肢確認）
- [ ] フィールド `Priority` が単一選択フィールドで、選択肢が `high` / `medium` / `low` の 3 値
- [ ] フィールド `Cycle` が単一選択フィールドで、`v2.6.0` 等の既存 milestone と `Later` を含む
- [ ] フィールド `Type` が存在する（`Type` フィールドまたは label-derived view filter のいずれか、Construction Design で確定）
- [ ] ビュー `Roadmap` / `Backlog Board` / `Priority Table` / `Feedback View` の 4 ビューが作成されている（検証: `gh project view-list` 相当の確認手順、各ビュー名で 1 件ずつヒット）
- [ ] Project workflow `Item closed` が **enabled** で、 `Status=Done` への遷移が設定されている（検証: テスト用ダミー Issue を Project に追加 → `gh issue close <N>` → 5 秒以内に `gh project item-list <N> --owner <O> --format json | jq '.items[]|select(.content.number==<N>)|.fieldValueByName.Status'` で `Done` を確認）
- [ ] 現状 Open Issue（Issue #524 リスト記載分）が Project に追加されている（検証: `gh project item-list <N> --owner <O> --format json | jq '.items | length'` が #524 リスト件数以上）
- [ ] 各 Item の `Priority` / `Cycle` / `Status` フィールドに初期値が設定されている（検証: ランダム 3 件サンプリングで全フィールドが non-null）
- [ ] Issue #524 の本文が **Project URL + 運用ルールのみ** にリダイレクト化されている（検証: `gh issue view 524 --json body --jq .body` の出力で「完了済み」セクション削除確認）
- [ ] `skills/aidlc/steps/inception/02-preparation.md` ステップ17（バックログ確認）に Project 参照ステップが追加されている（検証: `git grep -n "gh project" skills/aidlc/steps/inception/02-preparation.md` でヒット 1 件以上）
- [ ] 異常系: gh CLI のトークンスコープが不足している場合（`gh auth status -t` で `project` scope 不在検出時）、AI-DLC スクリプトは Project 操作をスキップして `warn:gh-token-scope-missing:project-skip` 出力 + 既存バックログ確認は継続する

---

## Epic 3: 振り返りフロー独立化（#667）

### ストーリー 4: /aidlc-retrospective 独立スキル化（破壊的変更）

**優先順位**: Must-have

As an AI-DLC スターターキット利用者
I want to 振り返りを Operations Phase 完了直後だけでなく後日まとめて実施したい
So that 思考の整理時間を確保しつつ、次サイクル着手の遅延を回避できる

**受け入れ基準**:

- [ ] `skills/aidlc-retrospective/` が新設され、`SKILL.md` / `version.txt` が配置されている（検証: `ls skills/aidlc-retrospective/SKILL.md skills/aidlc-retrospective/version.txt`）
- [ ] `/aidlc-retrospective`（および `aidlc:aidlc-retrospective` Skill 経由）で起動可能
- [ ] `skills/aidlc/SKILL.md` の `/aidlc {action}` parser に `retrospective`（短縮: `r`）アクションが追加され、独立スキルへ委譲する（検証: `git grep -n "retrospective" skills/aidlc/SKILL.md` でアクション一覧と短縮形にヒット）
- [ ] `skills/aidlc/steps/operations/04-completion.md` §1 の振り返り **実行ロジック** が完全削除されている。**残してよいのは案内文のみ**（具体的禁止条件: `function` 定義 / `bash` heredoc / `gh issue create` / `retrospective_dialog_token_*` / `retrospective_issue_create` / 条件分岐 `if/case` のうち振り返り関連すべて。検証 grep パターン: `grep -E "retrospective_(dialog_token|issue_create|prefill_hook|update_hook)" skills/aidlc/steps/operations/04-completion.md` で **0 件**、および `grep -E "feedback_mode|retrospective_template|retrospective-spool" skills/aidlc/steps/operations/04-completion.md` で **0 件**）
- [ ] Operations Phase 完了時のメッセージで `/aidlc i`（次 Inception）案内と同列に `/aidlc r`（振り返り起動）が表示される（検証: `grep -E "/aidlc r|/aidlc retrospective" skills/aidlc/steps/operations/04-completion.md` で完了メッセージ箇所にヒット 1 件以上）
- [ ] `/aidlc-retrospective` は対象サイクル自動検出（直近完了サイクル）と明示指定（引数）の両モードで起動できる
- [ ] 共有ライブラリ（`lib/retrospective-issue.sh` / `lib/feedback-mode.sh` / `lib/predecessor-issue.sh` / `templates/retrospective_template.md`）が `aidlc-retrospective` から参照可能（パス解決方針が SKILL.md に明記、循環依存なし）
- [ ] 既存の `[rules.retrospective].feedback_mode` 設定値（`interactive` / `local-issue-only` / `mirror-only` / `local-and-mirror` / `disabled`）は互換維持
- [ ] 異常系: `/aidlc r` 起動時に対象サイクルが特定できない場合（`.aidlc/cycles/` 不在等）、エラーメッセージ `error:cycle-not-found` を表示して exit 1（黙ってフォールバックしない）
- [ ] マージ前完結契約（DR-001）が `/aidlc-retrospective` 経由でも維持される（post-merge での `cycles/.../**` 改変が `write-history.sh` exit 3 で拒否される）

---

## Epic 4: 小バグ修正（#615 / #614）

### ストーリー 5: migrate-backlog.sh の UTF-8 多バイト境界分断バグ修正

**優先順位**: Should-have

As an AI-DLC スターターキット利用者（日本語環境）
I want to 日本語タイトルを含む Issue を migrate しても slug 末尾が文字化けしない
So that 過去サイクルのバックログを安全に新形式に移行できる

**受け入れ基準**:

- [ ] `skills/aidlc-setup/scripts/migrate-backlog.sh` line 79 の `cut -c1-50` が `LC_ALL=C.UTF-8 awk '{ s=$0; if (length(s) > 50) s=substr(s, 1, 50); print s }'` 相当に置換されている（検証: `grep -n "cut -c" skills/aidlc-setup/scripts/migrate-backlog.sh` で検出 0 件）
- [ ] 入力 `これは日本語のIssueタイトルですABCDEFGHIJKLMNOPQRSTUVWXYZ`（51 文字以上の日本語混在）に対し、出力末尾が文字化けしない（具体的期待: `?` や U+FFFD `（REPLACEMENT CHARACTER）` を含まず、コードポイント 50 個で切られる）
- [ ] `LANG=C` / `LC_ALL=C` 環境変数下でも文字化けしない（実装内で `LC_ALL=C.UTF-8` を明示固定するため）
- [ ] 純 ASCII タイトル（51 文字以上）に対し、出力が従来動作（先頭 50 バイト = 50 文字）と完全一致する
- [ ] `skills/aidlc-setup/scripts/tests/test_migrate_backlog_slug.sh`（新規）が追加され、上記 3 ケース（日本語混在 / `LC_ALL=C` / ASCII のみ）を `bash test_migrate_backlog_slug.sh && echo OK || echo FAIL` の形式で実行可能（exit code + 期待出力比較）
- [ ] 既存の `migrate-backlog.sh` テストが回帰せずパスする
- [ ] 異常系: `awk` が利用不可の環境では明示的なエラーメッセージ `error:awk-not-found` を表示して exit non-zero（暗黙の `cut` フォールバックは行わない）

### ストーリー 6: rules.md L107/L122 の MD040 違反修正

**優先順位**: Could-have

As an AI-DLC スターターキット開発者
I want to markdownlint-cli2 で `rules.md` の MD040 違反を 0 件にしたい
So that markdownlint CI を一段階クリーンに保てる

**受け入れ基準**:

- [ ] `.aidlc/rules.md` L107 / L122 の fenced code block に言語指定（`text` または該当言語）が追加されている
- [ ] `npx markdownlint-cli2 .aidlc/rules.md` の実行で MD040 違反が 0 件（コマンド出力に `MD040` を含まない）
- [ ] 既存の他の lint ルール違反が新たに発生していない（リグレッションなし）
- [ ] コードブロック内のコマンド表記が変更されていない（言語指定追加のみで内容は不変）
- [ ] 異常系: `npx markdownlint-cli2` が利用不可の環境（npx 不在等）では、ローカルでの確認をスキップ可能とし、CI（GitHub Actions）で同等チェックが走ることをドキュメント化（README または CONTRIBUTING）。CI が `markdownlint-cli2` を起動できない場合（依存解決失敗等）はその旨のエラーメッセージで CI を fail させる（黙って green を返さない）

---

## ストーリー横断の受け入れ基準（共通要件・SoT）

ストーリー 1A〜1D / 3 / 4 / 5 / 6 横断で適用される要件。各ストーリー側からは本セクションを参照する形とし、個別ストーリーへの重複記載は行わない。

### ドキュメント更新要件

- [ ] CHANGELOG.md に v2.6.0 リリースノートが追加されている。**冒頭に破壊的変更（#667 振り返りフロー独立化）を明示**し、その下に Epic 1〜4 の要約を記載
- [ ] README.md の関連セクション（バージョン管理 / 振り返り / バックログ / プロジェクト管理）が v2.6.0 仕様に更新されている
- [ ] `aidlc-migrate` スキルが v2.5.x → v2.6.0 アップグレード時に **「振り返り起動方法が変わりました（`/aidlc r` を使用してください）」** メッセージを表示する（検証: `aidlc-migrate` テスト or 実行ログで該当文言ヒット）

### CI / 品質ガード

- [ ] markdownlint / 既存自動 CI チェックがすべて green
- [ ] 新規追加テスト（`test_migrate_backlog_slug.sh` 等）が CI で実行されるか、または手動実行手順がドキュメント化されている

### リリース完了基準

- [ ] v2.6.0 PR の test plan に各ストーリーの検証手順（特にストーリー 3 の Project 自動化遷移、ストーリー 5 の slug 出力検証）が記載されている
- [ ] Milestone `v2.6.0` が close 状態
- [ ] 関連 Issue（#617 / #618 / #673 / #667 / #615 / #614）が close 状態
