# ドメインモデル: post-merge-cleanup.sh 通常ブランチ対応

## 概要
`post-merge-cleanup.sh` の環境判定を拡張し、worktree環境と通常ブランチ環境の両方でPRマージ後のクリーンアップ処理を実行可能にするための構造と責務を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## エンティティ（Entity）

### ExecutionEnvironment（実行環境）
- **ID**: 実行時の `abs_git_dir` パスで一意に識別
- **属性**:
  - `is_worktree`: Boolean - worktree環境かどうか（`abs_git_dir != toplevel/.git` で判定）
  - `toplevel`: String - `git rev-parse --show-toplevel` の結果
  - `git_dir`: String - `git rev-parse --git-dir` の結果
  - `main_repo_path`: String - メインリポジトリのパス（worktree: worktree listから取得、通常: toplevelと同一）
- **振る舞い**:
  - `detect()`: git dirとtoplevelからworktree/通常ブランチを判定し、`is_worktree` を設定
  - `resolve_main_repo_path()`: 環境に応じたメインリポジトリパスを解決

### RemoteConfig（リモート設定）
- **ID**: リポジトリパス + リモート名で一意
- **属性**:
  - `remote_name`: String - リモート名（動的に解決、ハードコードしない）
  - `default_branch`: String - デフォルトブランチ名（`resolve_default_branch()` で解決）
- **振る舞い**:
  - `resolve()`: リモート名とデフォルトブランチを動的に特定

## 値オブジェクト（Value Object）

### EnvironmentType（環境タイプ）
- **属性**: `type`: Enum("worktree", "normal_branch")
- **不変性**: 実行開始時に判定され、処理中に変更されない
- **等価性**: `type` の値で判定

### StepResult（ステップ結果）
- **属性**: `step_id`: String, `status`: Enum("ok", "warning", "error"), `code`: String (optional)
- **不変性**: ステップ完了後に生成され変更されない
- **等価性**: 既存の出力契約 `step_result:<N>:<status>[:<code>]` 形式と完全一致

## 集約（Aggregate）

### CleanupProcess（クリーンアッププロセス）
- **集約ルート**: CleanupProcess
- **含まれる要素**: ExecutionEnvironment, RemoteConfig, StepResult群
- **境界**: 1回のスクリプト実行が1つのCleanupProcessに対応
- **不変条件**:
  - 環境判定（step_0a）は全ステップより先に完了していること
  - `is_worktree` フラグは全ステップで一貫して参照されること
  - 出力契約（`main_repo_path:`, `branch:`, `step_result:`, `status:`）は環境タイプに関わらず維持されること

## ドメインサービス

### EnvironmentDetectionService（環境検出サービス）
- **責務**: worktree環境か通常ブランチ環境かを判定する
- **操作**:
  - `detect_environment()` - `abs_git_dir` と `toplevel/.git` を比較し、`IS_WORKTREE` グローバル変数を設定
  - worktree: `IS_WORKTREE=true`、従来のworktree list解析で `MAIN_REPO_PATH` を設定
  - 通常ブランチ: `IS_WORKTREE=false`、`MAIN_REPO_PATH` に `toplevel` を設定

### StepDispatcher（ステップディスパッチャー）
- **責務**: `IS_WORKTREE` フラグに応じて各ステップの処理を分岐する
- **操作**:
  - step_0a: 通常ブランチの場合、環境判定と同時にサイクルブランチの `WT_REMOTE` をプリフェッチ（step_1のcheckout前に退避）
  - step_1: コマンド的に分岐不要（`git -C $MAIN_REPO_PATH` が通常ブランチでは自リポジトリを指す）。ただしstep_1のcheckoutにより `current_branch` が変わる副作用あり（step_2への影響はstep_0aのプリフェッチで解消）
  - step_2: worktree → 既存のWT_REMOTE解決（current_branchベース）、通常ブランチ → step_0aでプリフェッチ済みの `WT_REMOTE` を使用（current_branchベースの解決をスキップ）
  - step_3: worktree → `git checkout --detach`、通常ブランチ → スキップ（`step_result:3:ok` のみ出力）
  - step_4, step_5: 共通（変更不要）

## ユビキタス言語

- **worktree環境**: `git worktree add` で作成された作業ツリーでスクリプトが実行される状態。`abs_git_dir != toplevel/.git`
- **通常ブランチ環境**: メインリポジトリ上のブランチでスクリプトが実行される状態。`abs_git_dir == toplevel/.git`
- **IS_WORKTREE**: グローバル変数。環境タイプを示すフラグ（`true`/`false`）
- **MAIN_REPO_PATH**: メインリポジトリのパス。worktreeではworktree listの最初のエントリ、通常ブランチでは自リポジトリのtoplevel
- **出力契約（機械可読）**: `step_result:`, `main_repo_path:`, `branch:`, `status:`, `message:` の各行。呼び出し元がパースする対象
- **出力契約（表示用）**: `step:<N>:<名前>` 行。人間向けの表示であり、呼び出し元はパースしない。名前の変更は後方互換性に影響しない
- **デフォルトブランチ**: リモートのHEADが指すブランチ（`resolve_default_branch()` で動的に解決）

## 不明点と質問（設計中に記録）

（不明点なし。計画段階のAIレビューで主要な設計判断は確定済み）
