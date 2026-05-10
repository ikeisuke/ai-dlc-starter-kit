# Unit 004 計画: dasel 直接呼び出しの `read-config.sh` 経由統一 + 規約追記

## 概要

AI エージェントが `.aidlc/config.toml` 読取で `dasel -f <file> '<key>'`（dasel CLI v3 で `unknown flag` エラーになる不正フラグ）を誤生成しがちな問題に対し、(1) AI プロンプト（`.md`）に残る dasel 直接呼び出しを `scripts/read-config.sh` 経由に統一、(2) `steps/common/rules-core.md` に dasel CLI v3 の制約と禁止呼び出しパターンを明文化、の 2 軸で構造的予防を行う。

## 採用案（Issue #689 提案 1 + 2 + 3 の組合せ、ハイブリッド方針）

### スコープ確定方針（計画レビュー Round 1 反映）

スキル間依存ルール（`.aidlc/rules.md` 「スキル間依存ルール」）との整合を取るため、本 Unit は以下の **ハイブリッド方針** を採用する:

1. **必須置換**: `dasel -f` 不正フラグを実際に使用している箇所のみ `scripts/read-config.sh` 経由に置換する
2. **規約強化**: 正しい dasel 構文（`cat file | dasel -i toml '<key>'`）を使用している箇所は、`rules-core.md` の規約追記によって anti-pattern 誤生成を予防する（現状コードは compliant のまま維持）
3. **対象外確定**: 既存構文が compliant かつ他スキル本体（`aidlc-setup`）の独立性に影響する箇所は本 Unit の置換対象に含めない

これにより、(a) スキル間依存ルールの違反を回避、(b) Issue #689 の本質的論点（不正フラグの実使用 + 将来誤生成の予防）の両方を達成、(c) Unit 単体スコープを最小化する。

### 呼び出し契約の統一（計画レビュー Round 1 / Round 2 反映）

`scripts/read-config.sh` の呼び出し方法は **「実行時の規約（AI 手順内コマンド）」** と **「検証時の規約（人間 / CI の確認コマンド）」** を明示的に分離して統一する。

**対応関係（1 行固定）**: 手順内は `scripts/read-config.sh <key>`（SKILL.md パス解決でスキルベースディレクトリ相対）、検証は `bash skills/aidlc/scripts/read-config.sh <key>`（リポジトリルート相対の絶対参照）。

| 項目 | 実行時の規約（AI 手順内コマンド） | 検証時の規約（人間 / CI の確認コマンド） |
|------|---------------------------------|------------------------------------|
| 呼び出し記法 | `bash scripts/read-config.sh <key>`（スキルベースディレクトリ相対、SKILL.md パス解決ルールに従う） | `bash skills/aidlc/scripts/read-config.sh <key>`（リポジトリルート相対の絶対参照） |
| 適用箇所 | プロンプトファイル（`.md`）内のコードブロック | 完了条件チェックリストのスモークテスト / `grep` 検証 / CI スクリプト |
| 実行コンテキスト | プロジェクトルート（cwd = リポジトリルート）、AI エージェントは SKILL.md のパス解決でスキルベース相対パスを絶対化して実行 | プロジェクトルート（cwd = リポジトリルート）から直接実行 |
| 共通項目 | 単一キー呼び出しを標準（`--keys` 形式は本 Unit の対象外） | 同左 |
| 共通項目 | 終了コード: 0=値あり、1=キー不在、2=エラー（dasel 未インストール / TOML 破損等） | 同左 |
| 禁止記法（共通） | `dasel -f <file> '<key>'`（不正フラグ）、`bash ../aidlc/scripts/read-config.sh ...`（相対パス遡及） | 同左 |

### 変更箇所

#### A. AI プロンプトファイル内の dasel 直接呼び出しを `read-config.sh` 経由に置換（必須対象）

| ファイル | 行 | 現状 | 置換後 | 判定 |
|---------|-----|------|-------|------|
| `skills/aidlc/steps/inception/02-preparation.md` | 140-144 | `dasel -f .aidlc/config.toml github_projects.{project_url,project_number,owner}`（**不正フラグ使用**） | 単一キー × 3 呼び出し: `bash scripts/read-config.sh github_projects.project_url` 等 | **必須置換**（不正フラグ修正、aidlc プラグイン内で完結） |

#### B. AI プロンプトファイル内の dasel 直接呼び出しを `read-config.sh` 経由に置換（推奨対象）

| ファイル | 行 | 現状 | 置換後 | 判定 |
|---------|-----|------|-------|------|
| `skills/aidlc-feedback/steps/feedback.md` | 10 | `cat .aidlc/config.toml \| dasel -i toml 'rules.feedback.enabled'`（構文は正しい） | `bash scripts/read-config.sh rules.feedback.enabled`（aidlc-feedback スキルベースから aidlc プラグイン内 read-config.sh を共通基盤として参照） | **推奨置換**（Issue #689 の主目的に直接対応 + スキル間依存ルール例外として整理） |

スキル間依存ルール例外: `scripts/read-config.sh` は AI-DLC スターターキット内の設定読取の共通基盤であり、`feedback.md` からの参照は SKILL.md パス解決の例外として扱う。本 Unit の `rules-core.md` 改訂内で「`read-config.sh` は AI-DLC スターターキット全体の共通基盤として全スキルから参照可」を明記する。

#### C. AI プロンプトファイル内の dasel 直接呼び出し（対象外、規約で予防）

| ファイル | 行 | 現状 | 判定理由 |
|---------|-----|------|---------|
| `skills/aidlc-setup/steps/01-detect.md` | 97 | `cat .aidlc/config.toml \| dasel -i toml 'starter_kit_version'`（構文は正しい） | aidlc-setup スキルの独立性（aidlc プラグインへの依存を強制すると、setup フローの自己完結性が失われる）。既存構文は `rules-core.md` の規約追記で compliant となるため、規約強化のみで対処 |

#### D. `steps/common/rules-core.md` への規約追記（必須）

`rules-core.md` の「## 設定読み込み【重要】」セクション直下に、以下 2 つの H3 サブセクションを追記する（新規 H2 セクションは作らず、既存の設定読み込みルールの自然な拡張として配置）:

**1. 「dasel 呼び出し規約（CLI v3）」セクション**

- 第一推奨: `.aidlc/config.toml` 読取は `bash scripts/read-config.sh <key>` を使う
  - 理由: 4 階層マージ・キー alias 対応・終了コード規約の正規経路
  - スキル間共有: `read-config.sh` は AI-DLC スターターキット全体の共通基盤として全スキルから参照可（スキル間依存ルールの例外）
- 例外: `read-config.sh` 自身が動作不能な低レイヤー（bootstrap 内部・stdlib 系・aidlc-setup の早期判定）でのみ直接 dasel を呼んでよい
- dasel CLI v3 の `-f` フラグは存在しない（`unknown flag` エラー、exit 80）
- 直接呼び出し時は以下の 2 形式のみ:
  - `cat <file> | dasel -i toml '<key>'`
  - `dasel -i toml '<key>' < <file>`

**2. 「禁止呼び出しパターン」セクション**

- `dasel -f <file> '<key>'`（`-f` フラグ存在しない、AI 誤生成の代表例）
- `dasel -f <file> -r toml '<key>'`（同上、`-r`/`-f` 混在）
- 拡張余地: 将来の anti-pattern は別 Issue / Unit で追加（初版は dasel 関連に限定）

### 補助変更

なし（CHANGELOG / docs への波及はリリース時に Operations Phase で別途行う）

## 完了条件チェックリスト

### Unit 004 受け入れ基準（user_stories.md ストーリー 4 より）

#### 正常系（置換と動作確認）

- [x] **A. 02-preparation.md** の `dasel -f` 直接呼び出し（不正フラグ）が `bash scripts/read-config.sh` 経由に置換されている（diff 確認）
- [x] **B. feedback.md** の dasel 直接呼び出しが `bash skills/aidlc/scripts/read-config.sh` 経由（リポジトリルート相対）に置換されている（diff 確認）、エラーハンドリング記述が `read-config.sh` の exit code（0/1/2）に整合している
- [x] **C. 01-detect.md** は対象外として計画スコープ確定方針に記録され、変更されていない
- [x] 置換後の手順が dasel v3 環境で正しく動作する（実コマンドの動作確認、スモークテスト 3 キーで確認済）

#### 規約系

- [x] `steps/common/rules-core.md` に「dasel 呼び出し規約（CLI v3）」セクションが存在し、`read-config.sh` 第一推奨ルール・正規構文・公開 API スクリプト層としての位置付けが明記されている（L20 で確認）
- [x] `steps/common/rules-core.md` に「禁止呼び出しパターン」セクションが存在し、`dasel -f` 形式が anti-pattern として列挙されている（L53 で確認）
- [x] 規約追記が既存の「## 設定読み込み【重要】」セクション直下に H3 サブセクションとして配置されている（重複・矛盾なし）

### Unit 定義「責務」セクション

- [x] `feedback.md` 等の dasel 直接呼び出し箇所を `scripts/read-config.sh` 経由に置換（必須対象 A + 推奨対象 B、対象外 C は計画で確定済み）
- [x] `rules-core.md` に dasel CLI v3 制約と禁止フラグを明文化（H3 サブセクション「dasel 呼び出し規約（CLI v3）」）
- [x] `rules-core.md` に「禁止呼び出しパターン」H3 サブセクションを新設し、`dasel -f` / その他 anti-pattern を列挙

### Construction Phase 共通

- [x] 計画レビュー（reviewing-construction-plan）: codex 3 round / Round 1 = 5 件 → Round 2 = 1 件 → Round 3 = 0 件、unresolved 0
- [x] 設計レビュー（reviewing-construction-design）: codex 3 round / Round 1 = 4 件 → Round 2 = 2 件 → Round 3 = 0 件、unresolved 0
- [x] コードレビュー（reviewing-construction-code）: codex 2 round / Round 1 = 1 件 → Round 2 = 0 件、unresolved 0
- [x] 統合レビュー（reviewing-construction-integration）: 本セクション追記後の Round で確認
- [x] markdownlint 実行（`bash skills/aidlc/scripts/run-markdownlint.sh v2.6.1`）でエラー 0 件（4 files, 0 errors）
- [x] 設計と実装の整合性チェック（論理設計通り 4 ファイルを編集、対象外 1 ファイルは未変更）

### 観測可能な判定指標（機械判定可能、計画レビュー Round 1 反映）

- [x] **anti-pattern 残存チェック**: 以下のコマンドで `dasel -f` 不正フラグが対象範囲から除去されている（exit 1 = 0 件）
  ```bash
  # rules-core.md（anti-pattern 例示用）を除外して dasel -f を検索 → 0 件期待
  grep -rn --include="*.md" "dasel -f" skills/ \
    | grep -v "skills/aidlc/steps/common/rules-core.md" \
    || echo "OK: no dasel -f outside rules-core.md"
  ```
- [x] **置換完了チェック**: 必須対象 A / 推奨対象 B から dasel 直接呼び出し（バッククォート / コードブロック内のコマンド行）が除去され、`read-config.sh` 経由に置換されている（exit 1 = 0 件）
  ```bash
  # 対象ファイル内に "dasel" コマンド呼び出しが残っていないこと（説明文中の言及は許容）
  grep -nE "^\s*(cat .*\|\s*)?dasel\b" \
    skills/aidlc/steps/inception/02-preparation.md \
    skills/aidlc-feedback/steps/feedback.md \
    || echo "OK: no dasel command invocation in target files"
  ```
- [x] **対象外ファイル確認**: `01-detect.md` の dasel 行が変更されていない（`git diff` の line 数 = 0）
- [x] **スモークテスト**: 以下 3 キーが `read-config.sh` 経由で正しく取得できる（regression 確認）
  ```bash
  bash skills/aidlc/scripts/read-config.sh rules.feedback.enabled         # → exit 0, "true"
  bash skills/aidlc/scripts/read-config.sh github_projects.project_url    # → exit 1（キー不在、正常）
  bash skills/aidlc/scripts/read-config.sh github_projects.project_number # → exit 1（キー不在、正常）
  ```
- [x] **規約セクション存在確認**: `rules-core.md` に新設 2 セクションが存在（L20: dasel 呼び出し規約、L53: 禁止呼び出しパターン）
- [x] **既存 bats テスト green**: `tests/config-defaults/template-removed-keys.bats` 18 件すべて ok

## スコープ

### 含まれるもの

- AI プロンプトファイル（`.md`）に含まれる `.aidlc/config.toml` 読取の dasel 直接呼び出しを `scripts/read-config.sh` 経由に置換
  - 必須対象 A: `skills/aidlc/steps/inception/02-preparation.md`（不正フラグ修正）
  - 推奨対象 B: `skills/aidlc-feedback/steps/feedback.md`（規約統一）
- `steps/common/rules-core.md` への dasel 規約追記（CLI v3 制約 + 禁止パターン + read-config.sh 優先ルール + スキル間共通基盤としての位置付け）
- 置換後の動作確認（スモークテスト + grep 検証）

### 含まれないもの

- 対象外 C: `skills/aidlc-setup/steps/01-detect.md` の置換（既存構文 compliant、aidlc-setup 独立性確保）
- `bin/` 配下のシェルスクリプト（`gh-project-cli.sh` / `check-size.sh` 等）の dasel 直接呼び出し（人手記述・CI 実行であり AI 誤生成論点ではない）
- `skills/aidlc/scripts/lib/toml-reader.sh` / `lib/version.sh` 等の共有 utility 内の dasel 呼び出し（`read-config.sh` の内部実装）
- JSON 抽出系の dasel 呼び出し（`dasel -i json` での `marketplace.json` 抽出など、`read-config.sh` のスコープ外）
- `skills/aidlc-setup/steps/02-generate-config.md` の説明文中での dasel 言及（解説的記述で動作命令ではない）
- `scripts/read-config.sh` 自体の機能拡張（既存インターフェース維持）
- dasel v3 → v4 アップグレード対応
- CHANGELOG / docs / README への dasel 言及の網羅的更新（必要に応じて Operations Phase で行う）
- `--keys` 形式（バッチモード）の使用（本 Unit では単一キー呼び出しに統一）

## 関連ファイル（修正対象）

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/steps/inception/02-preparation.md` | 135-144 行目の `dasel -f` 3 行を `bash scripts/read-config.sh` 経由（単一キー × 3 呼び出し）に置換、説明文（135 行目）を整合 |
| `skills/aidlc-feedback/steps/feedback.md` | 10 行目の `cat .aidlc/config.toml \| dasel ...` を `bash scripts/read-config.sh rules.feedback.enabled` に置換、エラーハンドリング記述を `read-config.sh` の exit code（0/1/2）に合わせて更新 |
| `skills/aidlc/steps/common/rules-core.md` | 「dasel 呼び出し規約（CLI v3）」サブセクション（H3） + 「禁止呼び出しパターン」サブセクション（H3）を「## 設定読み込み【重要】」直下に追加 |
| `.aidlc/rules.md` | 「### スキル間依存ルール」に公開 API スクリプト層の例外行を追記（`read-config.sh` を全スキルから参照可と明示） |

## 設計フェーズ（Phase 1）の対象

`depth_level=standard` のため Phase 1（設計）を実施する。設計の論点（計画レビュー Round 1 で 1 件確定済み、残 2 件）:

- **論点 1（解消済み）**: aidlc-setup スキルの 01-detect.md の扱い → 対象外（C）として計画で確定
- **論点 2**: `rules-core.md` への規約セクション挿入位置（「## 設定読み込み【重要】」直下に確定）
- **論点 3**: 「禁止呼び出しパターン」リストの初期粒度（dasel 関連 2 例に確定）

設計フェーズではドメインモデル（dasel 呼び出し規約のドメイン概念）と論理設計（規約セクションの構成・対象 2 ファイルの差分構造）を超軽量にまとめる。

## 実装フェーズ（Phase 2）の対象

- 4 ファイルの編集（02-preparation.md / feedback.md / rules-core.md / .aidlc/rules.md）
- markdownlint 実行（`bash skills/aidlc/scripts/run-markdownlint.sh v2.6.1`）
- 機械判定 grep（観測可能な判定指標セクションのコマンド）
- スモークテスト（read-config.sh 経由の 3 キー取得 dry run）

## リスク

| リスク | 影響度 | 対応 |
|-------|-------|------|
| `read-config.sh` 経由化により `feedback.md` のエラーハンドリング表現が変わる（dasel 未インストール時の挙動が exit 2 でラップされる） | 中 | `feedback.md` のエラーハンドリング記述を `read-config.sh` の exit code（0/1/2）に合わせて更新する。Issue #689 の「ユーザーに送信可否を対話確認（自動判定しない）」要件は exit 2 時の対話分岐として残す |
| `rules-core.md` 規約追記が既存の「## 設定読み込み【重要】」と重複・矛盾する | 低 | 設計レビューで挿入位置（「## 設定読み込み【重要】」直下に H3 サブセクションとして追加）に確定済み。既存の `read-config.sh` 規約への参照を追加することで重複を避ける |
| 「禁止呼び出しパターン」リストが将来の anti-pattern 追加で肥大化 | 低 | 初版は dasel 関連 2 例に限定。将来追加は別 Issue / Unit で個別対応（拡張余地を本 Unit 計画に明示） |
| **障害伝播（計画レビュー Round 1 反映）**: `read-config.sh` 側仕様変更（終了コード / エラーメッセージ）時に、置換対象 2 スキル（aidlc / aidlc-feedback）のプロンプト挙動が同時劣化する連鎖リスク | 中 | (1) 呼び出し契約を「観測可能な判定指標」セクションで統一固定、(2) 代表 3 キー（`rules.feedback.enabled` / `github_projects.project_url` / `github_projects.project_number`）のスモークテストを完了条件に追加、(3) `read-config.sh` の exit code 規約を `rules-core.md` の規約セクションで明記し、エラーハンドリング表現の共通基盤化 |
| スキル間依存ルール（`.aidlc/rules.md`）との整合 | 中 | `rules-core.md` の規約セクションで「`scripts/read-config.sh` は AI-DLC スターターキット全体の共通基盤として全スキルから参照可（スキル間依存ルールの例外）」を明記し、規約レベルで例外を整理 |

## 見積もり

0.5 day（02-preparation.md / feedback.md の置換 + rules-core.md / `.aidlc/rules.md` 改訂 + 影響範囲確認 + スモークテスト）

## 関連

- Issue: #689
- Inception 決定: DR-004（修正方針は Construction で確定 → 本計画 Round 1 で確定）
- 関連 Unit: Unit 003 / Unit 005（推奨依存元、本 Unit 完了後に並行実装可）
- 計画レビュー: Round 1（codex / 5 件指摘 → 全件 resolve）+ Round 2（codex / 1 件指摘 → 全件 resolve、実行時/検証時の規約を分離固定）+ Round 3（codex / 0 件、確認）
- 設計レビュー: Round 1（codex / 4 件指摘 → 全件 resolve、挿入位置・rules.md 追記・config 不在チェック・恒久根拠化）+ Round 2（codex / 2 件指摘 → 全件 resolve、計画整合）+ Round 3（codex / 0 件、確認）
- コードレビュー: Round 1（codex / 1 件指摘 → 全件 resolve、aidlc-feedback からの read-config.sh 解決パス修正）+ Round 2（codex / 0 件、確認）

## 完了条件達成証跡（2026-05-10）

| 項目 | コマンド / 観測 | 結果 |
|------|---------------|------|
| markdownlint | `bash skills/aidlc/scripts/run-markdownlint.sh v2.6.1` | exit 0 / 4 files / 0 errors |
| anti-pattern 残存（dasel -f） | `grep -rn --include='*.md' 'dasel -f' skills/ \| grep -v 'rules-core.md'` | exit 1 / 0 件 |
| 置換完了（対象 2 ファイル） | `grep -nE '^\s*(cat .*\|\s*)?dasel\b' 02-preparation.md feedback.md` | exit 1 / 0 件 |
| 対象外 01-detect.md 未変更 | `git diff -- skills/aidlc-setup/steps/01-detect.md \| wc -l` | 0 lines |
| 規約セクション存在 | `grep -n 'dasel 呼び出し規約\|禁止呼び出しパターン' skills/aidlc/steps/common/rules-core.md` | L20, L53（2 件マッチ）|
| rules.md 公開 API 例外 | `grep -n '公開 API スクリプト層' .aidlc/rules.md` | L37（1 件マッチ）|
| スモークテスト 1 | `bash skills/aidlc/scripts/read-config.sh rules.feedback.enabled` | exit 0 / "true" |
| スモークテスト 2 | `bash skills/aidlc/scripts/read-config.sh github_projects.project_url` | exit 1（キー不在、正常）|
| スモークテスト 3 | `bash skills/aidlc/scripts/read-config.sh github_projects.project_number` | exit 1（キー不在、正常）|
| 既存 bats（regression 確認） | `bats tests/config-defaults/template-removed-keys.bats` | 18 件 ok |
| 計画レビュー | reviewing-construction-plan / codex 3 round | resolve 5+1+0 / unresolved 0 |
| 設計レビュー | reviewing-construction-design / codex 3 round | resolve 4+2+0 / unresolved 0 |
| コードレビュー | reviewing-construction-code / codex 2 round | resolve 1+0 / unresolved 0 |
| 統合レビュー | reviewing-construction-integration / codex（実施中） | 本セクション追記後の Round で確認 |
