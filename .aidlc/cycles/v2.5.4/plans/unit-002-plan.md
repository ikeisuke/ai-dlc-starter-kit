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
| 呼び出し点 | Operations Phase 冒頭で health check を必須実行 | `skills/aidlc/steps/operations/01-setup.md`（改修、step:3a 相当） |
| 自動テスト | 4 ケース以上の bats シナリオ（健全 / unmerged / MERGE_HEAD / コンフリクトマーカー残骸） | `tests/main-repo-health-check.bats`（新設） |
| 履歴 | 実装進捗の記録 | `.aidlc/cycles/v2.5.4/history/construction_unit02.md`（新規作成） |

**ドリフト防止策**:

- helper の出力 contract（`health-check:<項目>:<status>:<detail>` 形式）を `validate-git.sh` の `status:`/`error:` 出力規約に揃え、AI エージェント側で独自の git 判定を行わない
- 01-setup.md への組み込みは **step:3a**（プリフライト後 / セッションタイトル設定前）の 1 箇所のみ。step 番号体系は維持し、後続 step を再採番しない
- 終了コード規約は `guides/exit-code-convention.md` に整合させる（0=健全 / 1=警告 / 2=致命的エラー）

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
3. bats 実行 → Self-Healing ループ（max_retry=3）で失敗時自動修正
4. `01-setup.md` step:3a 追加（helper 呼び出し + warning/error 時の挙動明示）
5. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）
6. cross-platform 観点レビュー（`tools:cross-platform-review` 観点。BSD vs GNU `grep` / `find` 差異）
7. markdownlint 実行 / 履歴記録の補足追加

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| `git rev-parse --git-common-dir` 失敗（git 未初期化 / 破損） | exit 2（致命的エラー）、stdout に `error:git-common-dir-failed:<message>` を出力 |
| メインリポジトリパス解決後に `git status --porcelain` 失敗 | exit 2、stdout に `error:git-status-failed:<message>` を出力 |
| worktree 環境ではない通常リポジトリで実行された場合 | best-effort 動作（メインリポジトリ = カレントリポジトリとして 3 項目チェック）。warning/error が出ない限り exit 0 |
| バイナリファイルが `git ls-files` の結果に含まれる場合 | `git grep -I` の `-I` フラグでバイナリ自動除外、または `file --mime-type` で text/* 限定 |
| macOS（BSD）/ Linux（GNU）の `grep` 差異 | POSIX 互換オプションのみ使用（`-E` / `-l` / `-I` 等）、独自拡張回避。`tools:cross-platform-review` 観点で検証 |
| パフォーマンス（数千ファイル中規模リポジトリ）が 1 秒を超える | コンフリクトマーカー scan を `git grep` 経由（tracked のみ + バイナリ除外）に統一し、`find` での全 walk を回避 |
| 01-setup.md の挿入位置で後続 step 番号がズレる | step:3a として挿入し既存 step 番号は不変（step 4-11 を再採番しない） |
| bats テスト fixture（fake main repo）の隔離 | `setup()` で `BATS_TEST_TMPDIR` 配下に独立した bare/working repo を生成し、`teardown()` で破棄。既存 `tests/fixtures/` を参考に独立 fixture 設計 |

## NFR

- **パフォーマンス**: コンフリクトマーカー scan は `git grep -I -lE '...'` で tracked + バイナリ除外。中規模リポジトリ（数千ファイル）で 1 秒以下
- **セキュリティ**: メインリポジトリパスは `git rev-parse --git-common-dir` で動的解決、ハードコード禁止。stdout 出力は機械可読固定フォーマットで、ファイルパスをエスケープせずそのまま出すケースに留意（ファイルパスに改行を含む異常入力は `git ls-files -z` で対処）
- **後方互換**: 既存 `01-setup.md` の step 番号体系を維持。既存スクリプト（`validate-git.sh` / `post-merge-cleanup.sh`）への変更なし
- **可用性**: Operations Phase の開始時間に最大 1 秒程度のオーバーヘッド。warning 検出時もユーザー判断で続行可能（exit 1 で中断はしない）

## 完了条件チェックリスト

### 機能要件

- [ ] `skills/aidlc/scripts/main-repo-health-check.sh` が新設され、unmerged paths / マージ進行中状態 / コンフリクトマーカー scan の 3 項目を実装している
- [ ] スクリプトの終了コードが規約通り（0=健全 / 1=警告 / 2=致命的エラー）
- [ ] stdout 出力が `health-check:<項目>:<status>:<detail>` 形式で機械可読
- [ ] メインリポジトリパスが `git rev-parse --git-common-dir` で動的解決されており、ハードコードされていない
- [ ] `skills/aidlc/steps/operations/01-setup.md` の step:3a 相当の位置に health check 必須呼び出しが追加されている
- [ ] warning / error 時の挙動（続行可能 / 復旧手順案内）が 01-setup.md に明示されている

### 自動テスト

- [ ] `tests/main-repo-health-check.bats` が新設され、以下 4 ケース以上を含む:
  - [ ] 健全シナリオ（3 項目すべて問題なし）→ exit 0
  - [ ] unmerged paths ありシナリオ → exit 1 + warning 出力
  - [ ] MERGE_HEAD ありシナリオ → exit 1 + warning 出力
  - [ ] コンフリクトマーカー残骸シナリオ（v2.5.3 再現）→ exit 1 + warning 出力
- [ ] 全 bats テストが pass する

### 既存ガード仕様との論理整合

- [ ] 01-setup.md の step 番号体系（既存 step 1-11）が維持されており、step 3a 挿入により後続が再採番されていない
- [ ] `validate-git.sh` / `post-merge-cleanup.sh` への変更がない（`git diff --name-only -- "skills/aidlc/scripts/validate-git.sh" "skills/aidlc/scripts/post-merge-cleanup.sh"` が空）
- [ ] 終了コード規約が `guides/exit-code-convention.md` に整合している（warning 付き完了 = exit 1、致命的エラー = exit 2）

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
