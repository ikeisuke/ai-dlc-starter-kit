# 実装計画: Unit 002 — 禁止パースパターンの CI 機械検出（T4）

- **サイクル**: v3.0.0-alpha.4
- **対象 Unit**: 002-frontmatter-parse-ci-guard
- **関連 Issue**: #733（部分対応 / T4 のみ / Relates、Closes ではない）
- **depth_level**: standard（Phase 1 設計あり）
- **実装優先度**: High
- **依存**: Unit 001（完了済み。共有 parser `lib/frontmatter.sh` 確立 + 禁止規約 SoT を `lib/frontmatter.sh:24-31` に文書化済み）

## 1. 目的

`skills/aidlc-v3/scripts/`（`lib/` と `tests/` を除く個別 consumer スクリプト）に frontmatter 構造解釈の禁止パターン（`grep` / `sed` / `awk` / permissive `jq`）が混入していないかを機械検出する独立スクリプトを追加し、GitHub Actions のジョブで実行する。Unit 001 で確立した共有 parser 境界からの逸脱（個別スクリプトでのローカルパース再実装）を、人手レビューに頼らず自動で弾く。

**性質**: 新規 CI ガードの追加（検出スクリプト + テスト + CI ジョブ）。既存 consumer の挙動は変えない。本 Unit 完了時点で v3 consumer は Unit 001 で全て共有 parser に移行済みのため、追加した検出ジョブは緑になることが完了条件。

## 2. 現状（調査結果サマリ）

- 共有 parser: `skills/aidlc-v3/scripts/lib/frontmatter.sh`（150 行）。公開 API は `fm_` prefix（`fm_has_closing_frontmatter` / `fm_extract_block` / `fm_extract_body` / `fm_scalar` / `fm_scalar_raw` / `fm_key_count` / `fm_deps`）。
- 禁止規約の SoT: `lib/frontmatter.sh:24-31` のコメントブロック（grep/sed/awk/permissive jq の frontmatter 構造解釈利用を禁止、`lib/` と `tests/` を除外、state-*.sh の JSON/jq・ログ整形は対象外と明記）。
- 走査対象候補: `work-item-validate.sh` / `work-item-next.sh` / `work-item-status.sh`（Unit 001 で共有 parser へ移行済み）と `state-init.sh` / `state-read.sh` / `state-validate.sh` / `state-write.sh`（JSON/jq 用途・対象外）。
- 既存 check スクリプト様式（`bin/check-bash-substitution.sh` / `check-skill-references.sh` / `check-test-isolation.sh`）: `#!/usr/bin/env bash` + `set -euo pipefail`、`git rev-parse --show-toplevel` でルート解決、`find -print0` 走査、`<file>:<line>: <message>` 形式の違反報告、終了コード 0=合格 / 1=違反 / 2=システムエラー、末尾にサマリ行。
- CI: `.github/workflows/skill-reference-check.yml` は**単一ジョブ `skill-reference-check` 内に 3 つの check を step として並べる**様式（`Detect skip` step → `Checkout` → check-skill-references / check-bash-substitution / check-test-isolation の各 step）。各 check step は `if: steps.detect.outputs.should_skip != 'true'` で共通 skip 判定を共有し、checkout・permissions はジョブレベルで 1 回。`PATHS_REGEX`（`Detect skip` step の env / 同ファイル）の skip 判定で `skills/.+` 等の変更時のみ実行。既に `bin/tests/check-test-isolation/.*\.bats` のようにテストパスを `PATHS_REGEX` に登録する前例がある。
- テストハーネス: `skills/aidlc-v3/scripts/tests/` の自己完結型 bash（`mktemp -d` サンドボックス + `trap rm -rf EXIT` + `assert_rc` ヘルパ）。

## 3. スコープ

### 含む（T4）

- 検出スクリプト新設（暫定名: `bin/check-frontmatter-parse-guard.sh`）。`skills/aidlc-v3/scripts/`（`lib/` と `tests/` を除く個別 consumer スクリプト）を走査し、**frontmatter 構造解釈の文脈に限定して** `grep` / `sed` / `awk` / permissive `jq`（`// 既定値` / `?` 型エラー抑制 / 暗黙型変換）を検出。
- allowlist 除外（`lib/` = 共有 parser 本体 / `tests/` = fixture）。ディレクトリベース走査で consumer 追加時も自動的に対象に含まれる。
- 終了コード規約（0=合格 / 1=違反 + 違反箇所報告 / 2=システムエラー）の遵守。
- GitHub Actions ワークフローへの **step 追加**（`skill-reference-check.yml` の既存単一ジョブ `skill-reference-check` 内に check step を追加し、既存の `Detect skip` / checkout / permissions を共有する。別ジョブ化はしない = skip 判定・checkout・権限設定の重複を避ける）+ `PATHS_REGEX` skip 判定の更新（新スクリプト本体パス + テストファイルパスの両方）。
- 検出スクリプトの自己完結型 bash テスト（合格 fixture / 違反 fixture / システムエラー系、consumer 追加時の自動対象化の確認を含む）。

### 含まない（境界）

- doctor コマンドの新設（未実装・予約 / Intent 除外事項）。検出は CI チェックとして実装する。
- 共有 parser ライブラリ本体の実装（Unit 001 で完了）。
- framework 側（`skills/aidlc/`）スクリプトの検出（対象は v3 本体 `skills/aidlc-v3/scripts/` のみ）。
- `state-*.sh` の JSON / jq パース検出。JSON は jq 一本化が正当な設計（Intent 除外事項）。検出は frontmatter 構造解釈に混入した禁止パターンのみを対象とし、JSON 用途の jq は誤検出しない。
- cycle 解決ロジック（Unit 003 / T6）。
- 既存 consumer の挙動変更（本 Unit はガード追加のみ）。

## 4. 実装アプローチ

### Phase 1: 設計

1. **ドメインモデル**: 検出概念（`ScanTarget` / `Allowlist` / `ForbiddenPattern` / `FrontmatterContext` / `Violation`）と責務境界（走査・文脈判定・パターン照合・違反報告）を定義。
2. **論理設計**: 検出スクリプトの公開 I/F（引数・走査ルート・出力形式・終了コード）、**中心課題である「frontmatter 文脈限定の検出ロジック」のアルゴリズム確定**、誤検出抑制方針、CI ジョブ追加方針を確定。

#### 4.1 中心的な設計課題（Phase 1 で確定 / 最重要）

本 Unit の難所は「frontmatter 構造解釈の文脈に限定して禁止パターンを検出する」こと。`state-*.sh` の JSON 用途 jq・ログ整形・正当な文字列処理を false positive にしないアルゴリズムが要。Phase 1 で以下の方針候補を評価し 1 つに確定する（暫定第一候補を太字で示す）:

- **候補 A（コンテキスト・ヒント方式 / 第一候補）**: `grep`/`sed`/`awk` を含む行のうち、frontmatter 構造解釈を示すトークン（`---` delimiter 処理 / `^[a-z_]+:` 形式のキー抽出 / `dependencies` / work item frontmatter フィールド名 / `.md` work item ファイルへの適用）を伴うものを違反とする。JSON（`.json` / jq の `.field` アクセス）・ログ整形は文脈トークンに該当せず除外。
- **候補 B（行マーカー許可方式）**: 正当な例外行に `# parse-guard: allow <理由>` インラインマーカーの付与を許可し、マーカー無しの禁止コマンドを違反とする（allowlist の粒度を行単位に）。
- **候補 C（A + B 併用）**: 文脈ヒントで一次検出し、誤検出が避けられない正当行はインラインマーカーで個別 allow。

**検出境界（false negative）の評価基準（R1 指摘1 反映 / 必須）**: 候補 A の「同一行トークン共起」方式は、frontmatter を変数に格納して別行で `grep`/`sed`/`awk` するケース・関数引数経由・複数行パイプを構造的に取りこぼす（実コードにも `work-item-validate.sh:171` の `echo "$body" | grep -Eq ...` のような「変数を別行で grep」する構文形状が実在する。これ自体は body セクション存在チェックで構造解釈ではないが、同型の真の違反 = `block=...fm_extract_block...` 後に別行で `echo "$block" | sed -n ...` を取りこぼす）。Phase 1 ではこの false negative 境界を評価基準に明示する: (a)「同一行ヒントに依存しない検出」（frontmatter 関連変数・関数名・work item `.md` 入力の最小データフロー追跡）を採るか、(b) 採らない場合でも **違反 fixture に「変数経由・複数行パイプ・関数経由」の禁止パターンを必ず含め、それらが全て検出される（テストで RC=違反）ことを必須とする**。**「既知の未検出として合格扱い」は不可**（T4 の目的「共有境界からの逸脱を自動で弾く」を満たさないため）。万一実装上どうしても検出できないケースを残す場合は、それは Phase 1 の設計判断ではなく **スコープ縮小 / 既知制限** として扱い、Unit 受け入れ基準との整合を再確認のうえ、`rules-core.md`「スコープ保護ルール」に基づき（Intent「含まれるもの」該当時は）ユーザー確認を経て明示する。どちらを採るかを Phase 1 で確定する。

判定基準: false positive を出さず（NFR「正当な共有 parser 利用をブロックしない」）かつ将来の逸脱を確実に弾けること（上記 false negative 境界の評価基準を含む）。permissive `jq` coerce（`// default` / `?` / 暗黙型変換）の検出は **frontmatter パース文脈に限定**し、`state-*.sh` の JSON jq は誤検出しない。コメント行・文字列リテラル内の誤検出抑制方針も Phase 1 で確定する。

**候補 B / C（行マーカー許可方式）採用時の統制（R1 指摘2 反映 / 条件付き必須）**: マーカーで allow できる対象は **「非構造用途の false positive のみ」に限定**し、frontmatter 構造解釈そのものの allow は不可とする（抜け道防止）。マーカー採用時は既存 allowlist 系チェック（`bin/check-test-isolation.sh` + `bin/check-test-isolation.allowlist`: 理由・追加日・tracking_issue・期限・stale 検出・致命パターン allowlist 不可の統制）と同等の統制（理由必須 / Issue 必須 / 期限 or stale 検出）を備えることを完了条件に含める。候補 A 単独採用時は本統制は不要（マーカー機構を持たないため）。

### Phase 2: 実装

1. 検出スクリプト `bin/check-frontmatter-parse-guard.sh` を実装（既存 check スクリプト様式に準拠: shebang / `set -euo pipefail` / `git rev-parse --show-toplevel` / `find -print0` 走査 / `<file>:<line>: <message>` 報告 / 終了コード 0/1/2 / サマリ行 / 自スクリプト除外 / `-h`/`--help`）。
2. allowlist（`lib/` / `tests/`）除外ロジックと frontmatter 文脈限定検出（Phase 1 確定アルゴリズム）を実装。
3. GitHub Actions に検出 step を追加（`skill-reference-check.yml` の既存単一ジョブ `skill-reference-check` 内に check step を追加し `Detect skip` / checkout / permissions を共有 + `PATHS_REGEX` に新スクリプト本体パスと**テストファイルパス**を追加して skip 判定を更新。テスト変更のみの PR で CI が skip されないようにする / 既存 `bin/tests/check-test-isolation/.*\.bats` 登録が前例）。
4. 自己完結型 bash テスト（合格 fixture = 共有 parser 利用のみ / 違反 fixture = grep/sed/awk/permissive jq の frontmatter パース / state-*.sh の JSON jq が誤検出されないこと / 終了コード 0/1/2 / consumer 追加時の自動対象化）を実装。
5. 検出スクリプトを現状の `skills/aidlc-v3/scripts/` に実行 → **緑（違反 0）を確認**（Unit 001 移行済みのため合格するのが完了条件）。
6. v3 全テスト + check スクリプトテストを実行し回帰緑を確認。

#### 4.2 opt-in シグナル原則の遵守（CLAUDE.md / .aidlc/rules.md）

「ドッグフーディング特殊処理を本体に埋めない」原則に従い、検出スクリプトの存在自体を opt-in シグナルとして扱う。スクリプト内に「starter kit リポジトリか consumer か」を判定する分岐を埋め込まない。走査対象が存在しない場合（`skills/aidlc-v3/scripts/` 不在）は自然に skip（合格）する汎用論理で表現する。

#### 4.3 squash-unit 連携の確認（Phase 1 で判断）

`.aidlc/config.toml` の `[rules.squash.internal_ci_checks].scripts` に新検出スクリプトを追加するかを Phase 1 で判断する（追加すると Unit 完了時の squash で構造チェックとして自動実行される / opt-in シグナル方式）。本 Unit のスコープ内（設定追記は小規模）だが、CI ジョブで担保されるため二重実行の要否を含めて設計時に確定する。

## 5. 完了条件チェックリスト

Unit 定義「責務」+ ストーリー受け入れ基準 + Intent T4 成功基準から抽出:

- [ ] `skills/aidlc-v3/scripts/`（`lib/` と `tests/` を除く）を走査し frontmatter 構造解釈の禁止パターン（`grep`/`sed`/`awk`/permissive `jq`）を検出する独立スクリプトが追加されている
- [ ] allowlist（`lib/` = 共有 parser 本体 / `tests/` = fixture）が除外されている
- [ ] 検出は **frontmatter パース文脈に限定** され、`state-*.sh` の JSON / jq（正当な用途）を誤検出しない
- [ ] permissive `jq` coerce（`// 既定値` / `?` 型エラー抑制 / 暗黙型変換）の検出が frontmatter パース文脈に限定されている
- [ ] 終了コード規約（0=合格 / 1=違反 + 違反箇所報告 / 2=システムエラー）を遵守している
- [ ] 違反報告が `<file>:<line>: <message>`（リポジトリ相対パス）形式で出力される
- [ ] GitHub Actions ワークフローに検出 step が追加され（既存単一ジョブ内 / 別ジョブ化しない）、PR で違反を fail させる
- [ ] コメント行・文字列リテラル内の誤検出を抑制している
- [ ] false negative 境界の評価結果（候補 A の「変数経由・複数行・関数経由」取りこぼし）に対し、「同一行ヒント非依存検出」の採否を Phase 1 で確定し、違反 fixture に変数経由・複数行・関数経由パターンを含めて**それらが全て検出される（RC=違反）ことを必須**としている。既知の未検出を合格扱いにせず、残す場合はスコープ縮小/既知制限として明示（Intent 該当時はユーザー確認）している（R1 指摘1 / R2 指摘1）
- [ ] （候補 B/C 採用時のみ）allow マーカーは非構造用途の false positive のみに限定（構造解釈は allow 不可）し、既存 allowlist 系チェック同等の統制（理由/Issue 必須 / 期限 or stale 検出）を備えている（R1 指摘2）
- [ ] GitHub Actions は既存単一ジョブ `skill-reference-check` 内への **step 追加**で実装し、`Detect skip` / checkout / permissions を共有している（別ジョブ化しない / R1 指摘3）
- [ ] `PATHS_REGEX` に検出スクリプト本体パスと**テストファイルパスの両方**を追加し、テスト変更のみの PR で CI が skip されない（R1 指摘3）
- [ ] 検出パターンが Unit 001 の禁止規約（`lib/frontmatter.sh:24-31` SoT）と整合している
- [ ] 検出スクリプトの存在を opt-in シグナルとして扱い、starter kit / consumer 判定分岐を本体に埋めていない（走査対象不在時は自然に skip）
- [ ] 将来 consumer 追加時もディレクトリベース走査で自動的に対象に含まれる
- [ ] 自己完結型 bash テスト（合格 fixture / 違反 fixture / state-*.sh 誤検出なし / 終了コード 0/1/2 / consumer 自動対象化）が追加されている
- [ ] 検出スクリプトを現状の `skills/aidlc-v3/scripts/` に実行して緑（違反 0）であることを確認
- [ ] v3 全テスト + check スクリプトテストが緑（既存回帰の維持）
- [ ] bash 3.2/4.0+ 互換 / `set -euo pipefail` を維持
- [ ] Bash ツール経由のコマンド置換禁止規約（CLAUDE.md）に違反しない

## 6. リスクと留意点

- **false positive リスク（最重要）**: frontmatter 文脈限定の検出が難所。`state-*.sh` の JSON jq・ログ整形・正当な文字列処理をブロックしないこと。→ Phase 1 で検出アルゴリズム（候補 A/B/C）を確定し、conformance 的な合格/違反 fixture テストで保証。
- **false negative リスク**: 文脈ヒントが緩いと逸脱を取りこぼす。特に candidate A の同一行トークン共起方式は「変数経由・複数行パイプ・関数経由」の禁止パターンを構造的に取りこぼす（§4.1 false negative 評価基準）。→ Phase 1 で「同一行ヒント非依存の検出」採否を確定し、違反 fixture に変数経由・複数行・関数経由パターンを必ず含めて合否判定を固定。
- **allow マーカーの抜け道リスク（候補 B/C 採用時）**: 行マーカーで frontmatter 構造解釈そのものを温存する抜け道になり得る。→ allow 対象を非構造用途の false positive のみに限定 + 既存 allowlist 系チェック同等の統制（理由/Issue/stale）を完了条件化（§4.1）。
- **既存スクリプトでの偽陽性**: 現状の consumer に検出が反応すると CI が即赤になる。→ Phase 2 で現状走査の緑を完了条件に含める。万一反応する正当行があれば、それは Unit 001 移行漏れか allowlist 設計の問題として切り分ける。
- **CI 二重実行**: squash-unit の internal_ci_checks と GitHub Actions ジョブの二重化。→ §4.3 で要否を判断。
- **コマンド置換禁止規約**: 検出スクリプト・テスト・コミットメッセージで `$(...)` / backtick を Bash ツール引数に含めない（zsh OOM 回避 / CLAUDE.md）。スクリプト内部のコマンド置換はファイル実行であり対象外だが、`bin/check-bash-substitution.sh` の別チェック対象になりうる点に留意。

## 7. AI レビュー

- `review_mode=required`（tools=codex）。計画 / 設計 / コード / 統合の各承認前に AI レビューを実施（スキップ不可）。
- 外部 CLI（codex）呼び出し前に必ずローカル `git diff` レビューを実施（.aidlc/rules.md「ローカルレビュー必須ルール」）。
