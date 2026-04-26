# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit v2.4.2 — setup/migrate マージ後フォローアップ追加 + Operations 手順書 / progress.md テンプレート明文化 patch

## 開発の目的

**主目的**: v2.4.0 / v2.4.1 までに発見された 4 件のオープン Issue を 1 patch サイクルで解消し、(A) `/aidlc-setup` `/aidlc-migrate` のアップグレード時マージ後フォローアップ整備と、(B) Operations Phase 手順書 / progress.md テンプレートの明文化を完成させる。

対象 Issue:

1. **#607 [setup/migrate] アップグレード後の chore/aidlc-vX.X.X-upgrade 一時ブランチが削除されず残る**
2. **#605 [Backlog] aidlc-setup のマージ後 HEAD を origin/main と同期する処理を追加**
3. **#591 [Backlog] operations-release.md §7.6 / template / 02-deploy.md の明文化（固定スロット配置・状態ラベル・コミット対象）**
4. **#585 [Backlog] operations_progress_template.md に固定スロット（release_gate_ready / completion_gate_ready / pr_number）を追加**

### 背景・経緯

1. **#607**: v2.4.0 アップグレード（visitory リポジトリ等）で `chore/aidlc-v2.4.0-upgrade` ローカルブランチがマージ後も残留することが確認された。`bin/post-merge-sync.sh` は `cycle/` および `upgrade/` プレフィックスのマージ済みブランチ削除に対応しているが、setup/migrate スキルが作成する `chore/aidlc-v*-upgrade` プレフィックスはカバーしていない。残留は次サイクル開始時の `git branch` 出力ノイズや手動削除負荷の原因
2. **#605**: v2.3.6 → v2.4.0 アップグレード（PR #604）後、ローカル HEAD がアップグレードブランチに残り、`origin/main` から乖離した状態で次フェーズを開始するケースが発生。手動で `git fetch` → `git checkout --detach origin/main` → `git branch -d` の同期作業が必要だった。worktree / 通常ブランチ / detached HEAD の場合分け必須
3. **#591**: v2.3.6 サイクル retrospective（empirical-prompt-tuning 適用）で `operations-release.md §7.6` 周辺に 8 件の不明瞭点が検出された。固定スロット配置位置（独自見出し命名分散）、行区切り（改行 vs カンマ）、§7.7 コミット対象列挙不在、状態ラベル列挙不在、テンプレート不在による裁量補完分散などが裁量幅として残存
4. **#585**: v2.3.6 Unit 001 の follow-up として、`templates/operations_progress_template.md` への固定スロット 3 種（`release_gate_ready` / `completion_gate_ready` / `pr_number`）追加が独立 backlog 化されていた。#591 の [P2] スコープに包含されるため統合実装する

### スコープ範囲と方針判断

本サイクルは **patch 単発**として位置付け、以下の方針でスコープを確定する:

- **#607 の解決方針**: **対話ベースの最終ステップ追加**を採用。`/aidlc-setup` / `/aidlc-migrate` の最終ステップで「マージ確認 → ローカル / リモート一時ブランチ削除」をユーザーへ案内する手順を追加する。`bin/post-merge-sync.sh` への統合は範囲が広がるため本 patch では行わず、setup/migrate スキル内で完結させる
- **#605 の解決方針**: **ユーザー確認ベースの fetch + detach/branch 切替**を採用。`/aidlc-setup` の最終ステップ（コミット後）で「PR を作成・マージしましたか？」を確認し、同意があれば `git fetch origin --prune` → 現在ブランチが worktree か通常ブランチか detached HEAD かに応じた同期処理を実行する。マージ済み自動検出（`gh pr view`）は誤検出リスクと実装複雑度が patch には過剰と判断。**outcome 固定**: 同意があれば 3 ケースいずれでも「ローカル HEAD（detached なら HEAD 自身、通常ブランチなら現ブランチ tip、worktree なら worktree のチェックアウト位置）が `origin/main` の最新コミットに一致する」状態に至る。**手段は Construction Phase で確定**: 各ケースの具体的な git コマンド系列（`git pull --ff-only` / `git checkout --detach origin/main` / `git reset --hard origin/main` 等の選定と、未コミット差分検出時のガード手順）は Construction Phase の設計レビューで決定する
- **#591 / #585 の解決方針**: **#591 のスコープに #585 を統合し 1 Unit として実装**。#591 の [P2]（template 更新）が #585 と同一スコープのため重複対応を避ける。#591 の [P1]〜[P4]（02-deploy.md 最小完成例 inline、template 更新、状態ラベル列挙、コミット対象列挙）を一括反映し、#585 は #591 完了時に同時 close する
- **検証方針**: 本サイクル内では `scripts/*.sh` の dry-run / `--help` テキスト整備、Markdown 手順書のレビュー、setup/migrate スキル内ロジックの単体検証のみに留める。実際のアップグレード走行検証（v2.4.1 → v2.4.2）は本 patch リリース後に別リポジトリで運用検証として実施する（メタ開発時の検証境界明確化）
- **本 patch のスコープ外**: バックログ Issue（#590 振り返りステップ追加 / #582 リポジトリ分離 / #581 Operations new_format 完成 / #573 旧キー自動移行 / #586 progress.md 整合化リファクタ 等）、`bin/post-merge-sync.sh` の汎用化、自動マージ検出機能。これらは規模・破壊性のため別 minor サイクル以降で対応

## ターゲットユーザー

- **メタ開発者（一次）**: ai-dlc-starter-kit 自体を開発する利用者。アップグレード時のマージ後手作業が削減され、メタ開発フローの完結性が向上する直接的恩恵を受ける
- **AI-DLC 利用者（二次）**: 外部プロジェクトで `/aidlc-setup` `/aidlc-migrate` を実行する利用者。アップグレード後のローカルブランチ整理と HEAD 同期が手順化され、手動操作なしで次フェーズに移行できる
- **Operations Phase 実施者（二次）**: progress.md 固定スロット配置・状態ラベル・コミット対象が明文化され、retrospective で観測された裁量補完分散が解消されることで、subagent 間 / 人間間で出力差分が小さくなる

## ビジネス価値

1. **アップグレードフロー完結性の向上**: setup/migrate のマージ後手作業（一時ブランチ削除・HEAD 同期）が削減され、メタ開発者・AI-DLC 利用者双方の負荷低減
2. **Operations 手順書の裁量幅縮小**: 固定スロット配置・状態ラベル・§7.7 コミット対象が明文化され、empirical-prompt-tuning で観測された「機能要件は満たすが配置不統一」を構造的に解消
3. **テンプレート整合性の確保**: `operations_progress_template.md` に固定スロット見本が同梱され、初回サイクル開始時から正しい構造が適用される
4. **patch サイクルの安定継続**: v2.4.0 / v2.4.1 で確立された patch 級 Issue 集約解消の運用パターンを継続し、minor 系の大規模変更に着手する前のクリーンアップを完遂

## 成功基準

### Issue 別終了条件

| Issue | 終了条件（観測可能な状態） |
|-------|---------------------------|
| **#607** | (a) `/aidlc-setup` および `/aidlc-migrate` の最終ステップに「マージ確認 → ローカル / リモート一時ブランチ削除案内」が明示記載されている / (b) ユーザー同意時に `git branch --list 'chore/aidlc-v*-upgrade'` が空、`git ls-remote --heads origin 'chore/aidlc-v*-upgrade'` が空（リモート push 権限がある場合）/ (c) 同意拒否時はローカル/リモートいずれも変更されない |
| **#605** | (a) `/aidlc-setup` の最終ステップ（コミット後）に「PR マージ済みなら HEAD 同期しますか？」確認手順が追加されている / (b) 同意時、3 ケース（worktree / 通常ブランチ / detached HEAD）すべてで「ローカル HEAD が `origin/main` の最新コミットに一致する」状態に至る（`git rev-parse HEAD == git rev-parse origin/main`）/ (c) 未コミット差分があるケースのガード手順（中断 or 強制継続）が定義されている |
| **#591** | (a) `skills/aidlc/steps/operations/operations-release.md §7.2-§7.6` に [P1] 最小完成例 inline（固定スロット 3 行を `## 固定スロット` セクションへ追記する具体例）が記載 / (b) `skills/aidlc/steps/operations/02-deploy.md §7` に [P3] 状態ラベル 5 値列挙（`未着手` / `進行中` / `完了` / `スキップ` / `PR準備完了`）と [P4] §7.7 コミット対象ファイル列挙が記載 / (c) 行区切り規約（改行区切り）が明示されている |
| **#591 [P2] / #585** | `skills/aidlc/templates/operations_progress_template.md` に固定スロット 3 種（`release_gate_ready=` / `completion_gate_ready=` / `pr_number=`）が初期値空の `key=value` 形式で同梱されている。`<!-- fixed-slot-grammar: v1 -->` コメントが付与されている |

### サイクル全体の終了条件

- 4 件すべての Issue（#607 / #605 / #591 / #585）が close され、Milestone v2.4.2 に紐付けされている
- CHANGELOG.md に Issue 別の変更点・背景が詳細列挙されている（v2.4.1 と同等のスタイル）
- バージョンファイル群が `2.4.2` に更新されている: `version.txt` / `skills/aidlc/version.txt` / `skills/aidlc-setup/version.txt`（存在時）/ `skills/aidlc-migrate/version.txt`（存在時）/ `.aidlc/config.toml.starter_kit_version` は v2.4.0 以降の例外ルール（リリース時非更新）に従い、ここでは更新対象外とする
- 既存の Construction / Operations Phase テスト・スクリプトに regression が発生していない（CI green）
- markdownlint 違反なし（`bin/check-markdown.sh` 等の lint）

## 期限とマイルストーン

- **本サイクル**: v2.4.2 patch リリース。Inception → Construction → Operations を通常通り順次実行
- **マイルストーン**: GitHub Milestone v2.4.2 に上記 4 Issue をすべて紐付け（`inception.05-completion` ステップ1で本作成）
- **Construction Phase 想定規模**: Unit 数 3〜4 程度。**結合検討候補**: #607（一時ブランチ削除）と #605（HEAD 同期）は `skills/aidlc-setup/` `skills/aidlc-migrate/` 配下のファイル重複範囲が大きいため、1 Unit に結合するか setup と migrate で分割するかを Construction Phase 計画時に決定。**並列実装可能性**: #591+#585 統合 Unit は他 Issue と独立しており並列実装可能（依存なし）
- **リリース後の運用検証**: v2.4.2 リリース後、別リポジトリ（visitory 等）で `/aidlc-setup` を実走させ、一時ブランチ削除と HEAD 同期が期待通り動作することを確認（本サイクル外）

## 制約事項

- **互換性**: 既存サイクル（v2.4.1 以前）の Operations Phase progress.md フォーマットとの後方互換性を維持。新テンプレートへの適用は本サイクル以降の新規サイクルから（既存サイクルへの強制移行は行わない）
- **検証境界**: 実アップグレード（v2.4.1 → v2.4.2）の動作検証は本サイクル内では実施しない。スクリプト dry-run / 手順書レビュー / 単体ロジック検証のみ
- **依存スクリプト**: `bin/post-merge-sync.sh`（`cycle/` + `upgrade/` プレフィックス対応の既存スクリプト）への変更は本サイクルでは行わず、setup/migrate スキル内で独立して `chore/aidlc-v*-upgrade` 一時ブランチ削除と HEAD 同期を実装する。`bin/post-merge-sync.sh` への `chore/aidlc-v*-upgrade` プレフィックス追加は別 Issue（候補: #607 解決方針の代替案）として将来サイクルで検討
- **メタ開発参照境界**: スキル内リソース修正は `skills/aidlc/**`（プロジェクトルート相対、META-001 例外）で実施。スキル実行時参照はスキルベース相対パスを維持
- **コマンド置換禁止**: Claude Code が **Bash ツール経由で実行する** コマンドでは `$()` / バッククォートを使用しない（シェルスクリプトファイル `scripts/*.sh` の内部コードはこの制約の対象外、CI 上で実行される `$()` は通常許容される）。`.aidlc/rules.md` 「コマンド置換（`$()`）使用禁止」セクション、および個人 CLAUDE.md 設定で重複適用

## 含まれるもの

- **#607**: `/aidlc-setup` および `/aidlc-migrate` の最終ステップに、マージ確認 → ローカル / リモート一時ブランチ削除案内フローを追加（対話ベース、ユーザー同意で実行）
- **#605**: `/aidlc-setup` のコミット後ステップに、PR マージ済み確認 → `git fetch origin --prune` → worktree / 通常ブランチ / detached HEAD ごとの HEAD 同期処理を追加（ユーザー確認ベース）
- **#591**: `skills/aidlc/steps/operations/operations-release.md §7.2-§7.6` および `02-deploy.md §7` に [P1] 最小完成例 inline、[P3] 状態ラベル列挙（5 値: 未着手 / 進行中 / 完了 / スキップ / PR準備完了）、[P4] §7.7 コミット対象具体的列挙を追加
- **#591 [P2] / #585**: `skills/aidlc/templates/operations_progress_template.md` に固定スロット見本（`release_gate_ready=` / `completion_gate_ready=` / `pr_number=`）を同梱
- CHANGELOG.md / 全 version.txt 群（プロジェクトルート + `skills/aidlc/` + `skills/aidlc-setup/` + `skills/aidlc-migrate/`、「成功基準 / サイクル全体の終了条件」のバージョンファイル列挙に準拠）の更新（v2.4.2）と Issue 別詳細記載。**`.aidlc/config.toml.starter_kit_version` は更新対象外**（v2.4.0 以降の例外ルール: setup/migrate の正規フロー以外で書き換えない）
- スキル実行時の dry-run / ヘルプテキスト整備（新規追加コマンドへの `--help` または相当ガイダンス）

### Unit 構成（予定）

A 案と B 案は排他的選択肢（同時不採用）。Construction Phase 着手時の Unit 設計レビューで A/B のいずれを採用するか確定する（#607 と #605 の責務重複度・テスト境界・PR 差分サイズで判断）。

| Unit 候補 | 対象 Issue | 主要修正対象ファイル（プロジェクトルート相対、existing_analysis で再確認） | 並列性 |
|-----------|-----------|------------------------------------------------|--------|
| Unit A 案: setup/migrate マージ後フォローアップ統合 | #607 + #605 | `skills/aidlc-setup/SKILL.md`, `skills/aidlc-setup/steps/03-migrate.md`（§9 以降または新規 §9.5 / §10）, `skills/aidlc-migrate/SKILL.md`, `skills/aidlc-migrate/steps/03-verify.md`（最終ステップ相当） | Unit C と並列可 |
| Unit B 案: setup/migrate を分離 | A 案と排他 | A 案と同じファイル群を Unit 単位で分割 | A 案と排他、Unit C と並列可 |
| Unit C: Operations 手順書 / template 明文化 | #591 + #585 | `skills/aidlc/steps/operations/operations-release.md`, `skills/aidlc/steps/operations/02-deploy.md`, `skills/aidlc/templates/operations_progress_template.md` | A/B と並列可 |
| Unit D: リリース系（バージョン更新・CHANGELOG）| - | 全 version.txt 群（プロジェクトルート + `skills/aidlc/` + `skills/aidlc-setup/` + `skills/aidlc-migrate/`）, `CHANGELOG.md` | Operations Phase で対応 |

**ファイル名検証**: 上記 Unit A 案の対象ファイルは Inception ステップ2（Reverse Engineering）の `existing_analysis.md` 作成時に実在確認する（v2.4.2 時点では `skills/aidlc-setup/steps/03-migrate.md` および `skills/aidlc-migrate/steps/03-verify.md` の実在を確認済み）。

## 含まれないもの

- 実アップグレード走行検証（v2.4.1 → v2.4.2 を別リポジトリで実行）。リリース後の運用検証として実施
- `bin/post-merge-sync.sh` の汎用化 / setup/migrate ブランチ統合
- `gh pr view --json state` 等を用いたマージ済み自動検出（誤検出リスクと実装複雑度のため）
- 他バックログ Issue（#590 / #582 / #581 / #573 / #586 / #592 等）の対応
- Operations Phase 復帰判定 new_format の実装完成（#581 別 Issue）
- Inception progress.md 6 ステップと §5.1 5 checkpoint 整合化リファクタ（#586 別 Issue）

## 不明点と質問（Inception Phase中に記録）

[Question] 既存コード分析（Reverse Engineering）の範囲は？
[Answer] brownfield 扱いだが、本サイクルは限定的なファイル変更（setup/migrate スキル + Operations 手順書 + テンプレート）に閉じるため、対象範囲を以下に限定する:
- `skills/aidlc-setup/SKILL.md` および `skills/aidlc-setup/steps/03-migrate.md`（§9 周辺の現行構造把握、実在確認済み）
- `skills/aidlc-migrate/SKILL.md` および `skills/aidlc-migrate/steps/01-preflight.md` / `02-execute.md` / `03-verify.md`（最終ステップ相当: `03-verify.md`、実在確認済み）
- `skills/aidlc/steps/operations/operations-release.md` §7.2-§7.6
- `skills/aidlc/steps/operations/02-deploy.md` §7
- `skills/aidlc/templates/operations_progress_template.md`
- `bin/post-merge-sync.sh`（除外対象だが既存挙動の理解のため目視確認）
プロジェクト全体のディレクトリ構造解析や技術スタック解析は v2.4.x で確立済みのため省略（standard 深度で重複を避ける）。

[Question] #607 のリモート一時ブランチ削除に必要な権限は？
[Answer] `git push origin --delete chore/aidlc-vX.X.X-upgrade` には push 権限が必要。実行時には push 権限の有無を確認できない場合があるため、Construction Phase の設計で「ローカル削除は無条件、リモート削除は失敗時に warning 表示で続行」のフォールバック設計を含める。実装ガード: ユーザー同意時にリモート削除コマンドを試行 → 失敗時は warning 出力のみで非中断とする。

[Question] #605 で worktree かつ未コミット差分ありの場合の挙動は？
[Answer] 未コミット差分検出時は同期を中断し「未コミット差分があります。stash / commit / 中止のいずれかを選んでください」と案内する。既定では中止し、ユーザーの手動操作後に再実行を推奨。具体的な選択肢の提示方法（`AskUserQuestion` 利用 / 静的メッセージ）は Construction Phase の設計で確定する。

（対話を通じて不明点を明確化し、このセクションに記録していく）
