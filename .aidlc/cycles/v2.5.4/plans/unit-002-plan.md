# Unit 002 計画: worktree 環境立ち上げ時のメインリポジトリ health check 追加

## 概要

worktree 環境で AI-DLC を運用する際、Operations Phase 開始時にメインリポジトリの状態異常（unmerged paths / マージ進行中状態 / コンフリクトマーカー残骸）を早期検出する health check helper（`skills/aidlc/scripts/main-repo-health-check.sh`）を新設し、`skills/aidlc/steps/operations/01-setup.md` の冒頭に必須呼び出しを組み込む。

これにより、v2.5.3 で発生した「Operations Phase 終盤の `post-merge-cleanup.sh` で失敗 → 原因調査に時間 → ユーザー手動クリーンアップ」という運用負荷を、Operations 開始時点で警告検出 + 復旧手順案内に置き換える。

> **前提**: 検出のみで自動修復は行わない（境界）。worktree 環境を主対象とし、通常リポジトリでは best-effort 動作とする。

## 関連 Issue

- #657（[Backlog] worktree 環境立ち上げ時のメインリポジトリ health check を追加）
- 関連: v2.5.3 Operations Phase post-merge-cleanup.sh 失敗事例（KPT Try 2）

## 責務分離原則

| レイヤ | 役割 | ファイル |
|--------|------|---------|
| 検出ロジック | unmerged paths / マージ進行中 / コンフリクトマーカー scan の 3 項目を実装 | `skills/aidlc/scripts/main-repo-health-check.sh`（新設） |
| 呼び出し点 | Operations Phase 冒頭で health check を必須実行 | `skills/aidlc/steps/operations/01-setup.md`（改修、挿入位置は次節「挿入位置の決定」を参照） |
| 自動テスト | 4 ケース以上の bats シナリオ（健全 / unmerged / MERGE_HEAD / コンフリクトマーカー残骸） | `tests/main-repo-health-check.bats`（新設） |
| 履歴 | 実装進捗の記録 | `.aidlc/cycles/v2.5.4/history/construction_unit02.md`（新規作成） |

### 挿入位置の決定

Unit 定義の責務記述（「step:0 または step:1a 相当の位置に挿入」）と境界（「step:0 等の追加挿入位置を慎重に選ぶ」）は **早期検出を意図する flex な指示**である。本計画では Unit 定義の意図（早期検出）を満たしつつ、依存制約（git CLI 可用性）を考慮して挿入位置を **step:3a**（プリフライト直後 / セッションタイトル設定前）に確定する。

**根拠**:

- `01-setup.md` 既存番号体系: `1, 2, 3, 4, 5, 6, 6a, 6b, 7, 8, 9, 10, 11`。`step:0` / `step:1a` は実体上不在
- main-repo-health-check.sh は `git rev-parse --git-common-dir` / `git status --porcelain` 等を依存。step:3 プリフライトで `git:available` を確認済みであることが安全前提
- step:3a は「プリフライト後 / 詳細処理前」の最早期点であり、Unit 定義の「早期検出」意図と整合

**SoT 整合**: Unit 定義側の責務記述は本計画の決定に合わせて Unit 完了処理時に補足追記する（SoT 二重化解消の対象は **2 点**）:

1. **位置契約**: 「step:3a に確定」（Unit 定義の責務記述「step:0 または step:1a 相当」を本計画決定に整合）
2. **終了コード契約**: Unit 定義の「終了コード規約」（旧 `0`=健全 / `1`=警告検出 / `2`=致命的エラー）を `skills/aidlc/guides/exit-code-convention.md` 規約準拠の形（`0`=健全+警告 / `1`=バリデーションエラー / `2`=システムエラー）に更新。warning は stdout の `status:warning` で通知する形に統一。Intent 側「成功基準」(a) の `exit code は 0（健全）または 1（警告検出）` も併せて更新する

### ドリフト防止策

- helper の出力 contract（`health-check:<項目>:<status>:<detail>` 形式）を `validate-git.sh` の `status:`/`error:` 出力規約に揃え、AI エージェント側で独自の git 判定を行わない
- 01-setup.md への組み込みは **step:3a**（プリフライト後 / セッションタイトル設定前）の 1 箇所のみ。既存 step 番号は再採番しない
- 終了コード規約は `skills/aidlc/guides/exit-code-convention.md` に整合させる:
  - **exit 0**: 正常完了（健全シナリオ + warning 検出を含む。warning は stdout の `status:warning` で通知）
  - **exit 1**: バリデーションエラー（引数不正等。本 helper は引数を取らないため通常は発生しない）
  - **exit 2**: システムエラー（`git rev-parse --git-common-dir` 失敗 / 必須コマンド不在等）
- 呼び出し側（01-setup.md）は **stdout の `status:warning` を判定**して警告表示・続行可否を決定する（exit code 1 を warning として扱わない）

### main-repo パス解決の契約

helper のメインリポジトリパス解決は以下の手順で行う:

1. 現ディレクトリの worktree トップレベルを `git rev-parse --show-toplevel` で取得
2. `git rev-parse --git-common-dir` の戻り値が相対パスの場合、`show-toplevel` を基準に絶対化する（`cd <toplevel> && cd <git-common-dir>` で正規化）
3. `git-common-dir` の親ディレクトリが「メインリポジトリの worktree top」となる
4. 解決失敗（`show-toplevel` または `git-common-dir` が空・相対化失敗）時は exit 2 で `error:git-path-resolve-failed:<details>` を stdout に出力

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/scripts/main-repo-health-check.sh` | 新規作成 | 3 項目の health check 実装、stdout 機械可読出力、終了コード 0/1/2 |
| `skills/aidlc/steps/operations/01-setup.md` | 改修 | step:3a として「メインリポジトリ health check」セクションを追加。warning / error 時の挙動を明示 |
| `tests/main-repo-health-check.bats` | 新規作成 | 4 ケース以上の自動テスト（健全 / unmerged / MERGE_HEAD / コンフリクトマーカー） |
| `.aidlc/cycles/v2.5.4/history/construction_unit02.md` | 新規作成 | Unit 002 進捗履歴 |

> 編集箇所の正確な文言・差分・関数構成・stdout フォーマット詳細は **論理設計** で確定する。本計画では変更対象ファイルと SoT 構造のみを宣言する。

## 実装計画

### Phase 1（設計）

設計成果物として以下を作成する:

- ドメインモデル（`design-artifacts/domain-models/unit_002_main_repo_health_check_domain_model.md`）: ドメイン語彙（HealthCheckResult / MainRepositoryPath / ConflictMarkerPattern / 検出項目分類 / 終了コード規約 / worktree 主対象境界）を整理
- 論理設計（`design-artifacts/logical-designs/unit_002_main_repo_health_check_logical_design.md`）: helper の関数構成・stdout フォーマット・cross-platform 互換戦略・01-setup.md への挿入位置（step:3a）と挿入文言・bats fixture 設計（4 シナリオ）を確定

`depth_level=standard` のため Phase 1 はスキップしない。設計レビュー（`reviewing-construction-design`）を 5R 内で実施する。

### Phase 2（実装）

実装順序:

1. `main-repo-health-check.sh` 新設（検出ロジック 3 項目 + stdout フォーマット + 終了コード）
2. `tests/main-repo-health-check.bats` 新設（4 シナリオ + fixture セットアップ）
3. bats 実行 → Self-Healing ループ（失敗時自動修正）
4. `01-setup.md` step:3a 追加（helper 呼び出し + stdout の `status:warning` を解釈する分岐記述）
5. AI レビュー → 統合レビュー
6. cross-platform 観点レビュー / markdownlint 実行 / 履歴補足

> 具体的なコマンド分岐・関数構成・bats シナリオ詳細・Self-Healing リトライ条件は **論理設計** で確定する。

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| `git rev-parse --show-toplevel` / `--git-common-dir` 失敗 | exit 2、stdout に `error:git-path-resolve-failed:<message>` を出力 |
| メインリポジトリパス解決後に `git status --porcelain` 失敗 | exit 2、stdout に `error:git-status-failed:<message>` を出力 |
| worktree 環境ではない通常リポジトリで実行された場合 | best-effort 動作（メインリポジトリ = カレントリポジトリとして 3 項目チェック）。warning/error が出ない限り exit 0 |
| バイナリファイル除外戦略 | `git grep -I` を主経路（git の tracked + バイナリ自動除外）。`grep` 単体への依存は避ける |
| macOS（BSD）/ Linux（GNU）の `grep` 差異 | scan は `git grep` 中心に統一し、`grep` 単体オプションへの依存を避ける（`tools:cross-platform-review` 観点で検証） |
| パフォーマンス（数千ファイル中規模リポジトリ）が 1 秒を超える | `git grep` 経由（tracked + バイナリ自動除外）に統一し、`find` での全 walk を回避 |
| 01-setup.md の挿入位置で後続 step 番号がズレる | step:3a として挿入し既存 step 番号は不変 |
| bats テスト fixture（fake main repo）の隔離 | `BATS_TEST_TMPDIR` 配下で隔離（詳細な fixture 構造は logical design で確定） |

## NFR

- **パフォーマンス**: コンフリクトマーカー scan は `git grep` 中心（tracked + バイナリ自動除外）。中規模リポジトリ（数千ファイル）で 1 秒以下
- **セキュリティ**: メインリポジトリパスは `git rev-parse --show-toplevel` + `--git-common-dir` で動的解決し絶対化、ハードコード禁止。stdout 出力は機械可読固定フォーマット。ファイルパスに改行を含む異常入力は `-z` 系オプション（`git ls-files -z` 等）で対処（詳細は logical design）
- **後方互換**: 既存 `01-setup.md` の step 番号体系を維持。既存スクリプト（`validate-git.sh` / `post-merge-cleanup.sh`）への変更なし
- **可用性**: Operations Phase の開始時間に最大 1 秒程度のオーバーヘッド。warning 検出時もユーザー判断で続行可能（**exit 0 を維持し、stdout の `status:warning` で通知**）

## 完了条件チェックリスト

### 機能要件

- [ ] `skills/aidlc/scripts/main-repo-health-check.sh` が新設され、unmerged paths / マージ進行中状態 / コンフリクトマーカー scan の 3 項目を実装している
- [ ] スクリプトの終了コードが `skills/aidlc/guides/exit-code-convention.md` 規約通り（**exit 0**: 健全 + warning 検出 / **exit 1**: バリデーションエラー / **exit 2**: システムエラー）
- [ ] warning 検出は exit 0 を維持し、stdout の `status:warning` および `health-check:<項目>:<status>:<detail>` で通知している
- [ ] メインリポジトリパスが `git rev-parse --show-toplevel` + `--git-common-dir` で動的解決・絶対化されており、相対パス／ハードコードに依存していない
- [ ] コンフリクトマーカー scan が `git grep` を主経路として実装されており、`grep` 単体（BSD/GNU 差異リスク）への依存がない
- [ ] `skills/aidlc/steps/operations/01-setup.md` の step:3a 相当の位置に health check 必須呼び出しが追加されている
- [ ] 01-setup.md の呼び出し記述が **exit code ではなく stdout の `status:warning` を解釈** して警告表示する形になっている
- [ ] warning / error 時の挙動（続行可能 / 復旧手順案内）が 01-setup.md に明示されている
- [ ] Unit 定義ファイル（`002-main-repo-health-check.md`）の責務記述に「step:3a に確定」の補足が追記されている（SoT 二重化解消）

### 自動テスト

- [ ] `tests/main-repo-health-check.bats` が新設され、以下 4 ケース以上を含む:
  - [ ] 健全シナリオ（3 項目すべて問題なし）→ **exit 0** + stdout に `status:ok`
  - [ ] unmerged paths ありシナリオ → **exit 0** + stdout に `status:warning` + 該当項目の `health-check:<項目>:warning:<detail>`
  - [ ] MERGE_HEAD ありシナリオ → **exit 0** + stdout に `status:warning` + `health-check:merge-in-progress:warning:<detail>`
  - [ ] コンフリクトマーカー残骸シナリオ（v2.5.3 再現）→ **exit 0** + stdout に `status:warning` + `health-check:conflict-marker:warning:<detail>`
- [ ] 全 bats テストが pass する

### 既存ガード仕様との論理整合

- [ ] 01-setup.md の step 番号体系（既存 step 1-11）が維持されており、step 3a 挿入により後続が再採番されていない
- [ ] `validate-git.sh` / `post-merge-cleanup.sh` への変更がない（`git diff --name-only -- "skills/aidlc/scripts/validate-git.sh" "skills/aidlc/scripts/post-merge-cleanup.sh"` が空）
- [ ] 終了コード規約が `skills/aidlc/guides/exit-code-convention.md` に整合している（**警告付き完了 = exit 0 + stdout `status:warning`**、バリデーションエラー = exit 1（本 helper は引数を取らないため通常発生しない）、システムエラー = exit 2）
- [ ] Unit 定義ファイル（`002-main-repo-health-check.md`）の責務セクションに記載された終了コード規約が、`skills/aidlc/guides/exit-code-convention.md` に整合する形（旧 `1=警告検出` ではなく `0=健全+警告`）に更新されている（SoT 二重化解消の対象）

### スコープ保護

- [ ] Inception / Construction Phase の 01-setup.md への health check 呼び出しは行っていない（Operations Phase 限定、境界に明記）
- [ ] post-merge-cleanup.sh 自体の改修は行っていない（境界に明記）
- [ ] メインリポジトリの「未コミット差分（コンフリクトを含まないもの）」の警告検出は行っていない（境界に明記）
- [ ] 自動修復ロジック（unmerged を `git checkout --` で消す等）が含まれていない（検出のみの境界）

### 履歴

- [ ] `.aidlc/cycles/v2.5.4/history/construction_unit02.md` が新規作成され、変更ファイル一覧 / レビュー round / 検証結果が追記されている

### 品質ゲート

- [ ] cross-platform 互換（macOS BSD / Linux GNU 両対応）が `tools:cross-platform-review` 観点で確認されている
- [ ] markdownlint（`markdown_lint=true` 設定）が変更対象ファイルで pass する
- [ ] AI レビュー（`reviewing-construction-design` / `reviewing-construction-code` / `reviewing-construction-integration`）が完了条件（最後 2 round 連続で指摘ゼロまたは defer 化）を満たす
- [ ] Codex レビュー（`codex review --base main`）でも追加指摘なし、または defer 化済み

## 見積もり

- 設計フェーズ: 1 日（domain model / 検出ロジック / cross-platform 互換性 / fixture 設計）
- 実装フェーズ: 2 日（helper 新設 + 01-setup.md 組み込み + bats テスト 4 ケース以上 + fixture 整備 + cross-platform 検証）
- 合計: **3 日**（Unit 定義の見積もりと一致）
