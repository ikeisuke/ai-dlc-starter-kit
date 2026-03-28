# 論理設計: v1→v2移行スクリプトE2Eテスト

## 概要

移行スクリプト群のbats-coreテストにおけるコンポーネント構成、テストケース一覧、ヘルパーの責務を定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

**Fixture-based Integration Testing**: 静的fixtureとセットアップヘルパーによる環境構築 + JSON契約検証の2層テスト構造。bats-coreのsetup/teardownメカニズムを活用し、テスト間の独立性を保証する。

## コンポーネント構成

```text
tests/
├── fixtures/
│   └── v1-structure/           # 静的fixture（v1環境の最小再現）
│       ├── .aidlc/
│       │   ├── config.toml     # docs/aidlc参照あり
│       │   └── cycles/
│       │       ├── backlog/    # 空ディレクトリ（.gitkeep）
│       │       └── v1.0.0/
│       │           └── history/
│       │               └── example.md  # docs/aidlc参照あり
│       ├── .github/
│       │   └── ISSUE_TEMPLATE/
│       │       └── backlog.yml # 既知ハッシュ一致ファイル
│       └── .kiro/
│           └── agents/
│               └── aidlc-poc.json  # 既知ハッシュ一致ファイル
└── migration/
    ├── helpers/
    │   └── setup.bash          # 共通ヘルパー
    ├── migrate-detect.bats
    ├── migrate-backup.bats
    ├── migrate-apply-config.bats
    ├── migrate-apply-data.bats
    ├── migrate-cleanup.bats
    ├── migrate-verify.bats
    └── e2e-full-flow.bats
```

### コンポーネント詳細

#### helpers/setup.bash（共通ヘルパー）

- **責務**: テスト環境の構築・破棄、コマンド契約差異の吸収、JSON契約検証
- **依存**: bats-core, jq
- **公開インターフェース**:
  - `setup_v1_environment`: 一時ディレクトリにv1構造を展開（AIDLC_PROJECT_ROOT設定含む）
  - `setup_v2_environment`: v2構造（v1アーティファクトなし）を展開
  - `teardown_environment`: 一時ディレクトリを削除
  - `run_detect`: migrate-detect.shを実行（AIDLC_PROJECT_ROOT注入）
  - `run_backup manifest`: migrate-backup.shを実行
  - `run_apply_config manifest backup_dir`: migrate-apply-config.shを実行
  - `run_apply_data manifest backup_dir`: migrate-apply-data.shを実行
  - `run_cleanup manifest backup_dir`: migrate-cleanup.shを実行
  - `run_verify manifest`: migrate-verify.shを実行
  - `assert_json_field json path expected`: jqでJSON値を検証
  - `assert_json_array_length json path expected`: JSON配列長を検証
  - `assert_json_has_field json path`: JSONフィールドの存在を検証
  - `save_manifest output path`: manifest JSONをファイルに保存
  - `get_backup_dir result`: BackupResultJSONからbackup_dirを抽出
  - `create_symlinks tmpdir`: シンボリックリンクを動的生成（fixture展開時）

#### fixtures/v1-structure/（静的fixture）

- **責務**: v1環境を再現する最小限のファイル群を格納
- **依存**: なし
- **特記事項**:
  - ハッシュ一致が必要なファイル（aidlc-poc.json, backlog.yml）は実際のスターターキット原本と同一内容
  - シンボリックリンクはfixtureに含めず、セットアップヘルパーで動的生成（gitがシンボリックリンクを追跡しない問題を回避）
  - `.aidlc/cycles/backlog/`は空ディレクトリのため`.gitkeep`で保持

## テストケース一覧

### migrate-detect.bats

| # | テストケース | 検証内容 |
|---|------------|---------|
| 1 | symlink_agents検出 | `.agents/skills/aidlc` → `docs/aidlc/` リンクがresourcesに含まれる |
| 2 | symlink_kiro skills検出 | `.kiro/skills/aidlc` → `docs/aidlc/` リンクがresourcesに含まれる |
| 3 | symlink_kiro agents検出 | `.kiro/agents/aidlc.json` → `docs/aidlc/` リンクがresourcesに含まれる |
| 4 | file_kiro検出（ハッシュ一致） | `.kiro/agents/aidlc-poc.json` がハッシュ一致でresourcesに含まれる |
| 5 | backlog_dir検出 | `.aidlc/cycles/backlog/` がresourcesに含まれる（conditionフィールド付き） |
| 6 | github_template検出（ハッシュ一致） | `.github/ISSUE_TEMPLATE/backlog.yml` がハッシュ一致でresourcesに含まれる |
| 7 | config_update検出 | `.aidlc/config.toml` にdocs/aidlc参照ありでresourcesに含まれる |
| 8 | data_migration検出 | cycles配下mdファイルにdocs/aidlc参照ありでresourcesに含まれる |
| 9 | already_v2判定 | v2構造ではstatus="already_v2"、resources空配列 |
| 10 | manifest JSONスキーマ検証 | version, status, detected_at, resources等の必須フィールド存在 |

### migrate-backup.bats

| # | テストケース | 検証内容 |
|---|------------|---------|
| 1 | ファイルバックアップ成功 | manifest内のファイルがbackup_dirにコピーされる |
| 2 | シンボリックリンクバックアップ成功 | シンボリックリンクがリンク情報保持（cp -P）でバックアップされる |
| 3 | ディレクトリバックアップ成功 | ディレクトリが再帰的にバックアップされる |
| 4 | 存在しないファイルのスキップ | 対象不存在時はスキップ（files配列に含まれない） |
| 5 | backup_dir生成確認 | 一時ディレクトリが作成され、backup_dirフィールドに返される |
| 6 | backup result JSON契約検証 | backup_dir, files配列の構造検証 |

### migrate-apply-config.bats

| # | テストケース | 検証内容 |
|---|------------|---------|
| 1 | config.tomlパス置換成功 | `docs/aidlc` → `skills/aidlc` に置換される |
| 2 | 置換不要時のスキップ | docs/aidlc参照なしならstatus="skipped" |
| 3 | ファイル不存在時のエラー | 対象ファイルがない場合status="error" |
| 4 | journal JSON契約検証 | phase="config"、applied配列の構造検証 |

### migrate-apply-data.bats

| # | テストケース | 検証内容 |
|---|------------|---------|
| 1 | Markdownパス置換成功 | `docs/aidlc` → `{{aidlc_dir}}` に置換される |
| 2 | 置換不要時のスキップ | docs/aidlc参照なしならstatus="skipped" |
| 3 | ファイル不存在時のエラー | 対象ファイルがない場合status="error" |
| 4 | journal JSON契約検証 | phase="data"、applied配列の構造検証 |

### migrate-cleanup.bats

| # | テストケース | 検証内容 |
|---|------------|---------|
| 1 | ファイル削除成功 | action=deleteのファイルが削除される |
| 2 | シンボリックリンク削除成功 | action=deleteのシンボリックリンクが削除される |
| 3 | ディレクトリ削除成功 | action=deleteのディレクトリ（末尾/）が削除される |
| 4 | 存在しないファイルのスキップ | 対象不存在時status="skipped" |
| 5 | 絶対パス拒否 | `/etc/passwd`等の絶対パスでstatus="error" |
| 6 | パストラバーサル拒否 | `../`を含むパスでstatus="error" |
| 7 | 空ディレクトリの自動削除 | 親ディレクトリが空になった場合に自動削除 |
| 8 | journal JSON契約検証 | phase="cleanup"、applied配列の構造検証 |

### migrate-verify.bats

| # | テストケース | 検証内容 |
|---|------------|---------|
| 1 | config_paths検証OK | config.tomlにskills/aidlcがありdocs/aidlcがない場合ok |
| 2 | config_paths検証FAIL | config.tomlにdocs/aidlcが残っている場合fail |
| 3 | v1_artifacts_removed検証OK | action=deleteのリソースが全て存在しない場合ok |
| 4 | v1_artifacts_removed検証FAIL | action=deleteのリソースが残っている場合fail |
| 5 | data_migrated検証OK | data_migration対象にdocs/aidlcがなく{{aidlc_dir}}がある場合ok |
| 6 | data_migrated検証FAIL | data_migration対象にdocs/aidlcが残っている場合fail |
| 7 | overall判定 | 全checkがokならoverall="ok"、1つでもfailならoverall="fail" |
| 8 | verify result JSON契約検証 | checks配列、overall フィールドの構造検証 |

### e2e-full-flow.bats

| # | テストケース | 検証内容 |
|---|------------|---------|
| 1 | v1→v2完全移行フロー | detect→backup→apply-config→apply-data→cleanup→verify全ステージ成功、verify overall="ok" |
| 2 | already_v2スキップフロー | v2構造ではdetectがalready_v2を返し、後続ステージの実行が不要であることを検証 |
| 3 | backup→apply間のbackup_dir受け渡し | backupの出力backup_dirがapply-config/apply-data/cleanupの--backup-dir引数に正しく渡される |

## CI ワークフロー設計

### .github/workflows/migration-tests.yml

- **トリガー**: pull_request (branches: [main])
- **パスフィルタ**:
  - `skills/aidlc/scripts/migrate-*.sh`
  - `skills/aidlc/scripts/lib/**`
  - `tests/migration/**`
  - `tests/fixtures/**`
  - `.github/workflows/migration-tests.yml`
- **ジョブ**: `migration-tests`
  - runs-on: ubuntu-latest
  - ステップ:
    1. actions/checkout@v4
    2. bats-coreインストール（npm install -g bats）
    3. jq確認（ubuntu-latestにプリインストール済み）
    4. `bats tests/migration/` 実行

## 技術選定

- **テストフレームワーク**: bats-core 1.x
- **JSON処理**: jq（テスト内のJSON契約検証）
- **fixture管理**: 静的ファイル + セットアップヘルパーによる動的構築

## 実装上の注意事項

- シンボリックリンクはgitで追跡困難なため、セットアップヘルパーで動的生成する
- ハッシュ一致ファイルはスクリプト内の`KNOWN_HASHES`と同期する必要がある。fixtureの原本ファイルをそのまま使用し、テスト側でハッシュ定数を重複保持しない
- `AIDLC_PROJECT_ROOT`環境変数によるbootstrap.shの依存注入を活用し、実プロジェクトディレクトリを汚染しない
- 各テストのsetup/teardownで一時ディレクトリを完全に独立させる
- E2Eテストでは中間JSON出力をファイルに保存し、ステージ間の受け渡し（特にbackup_dir）を検証する
- 終了コード: 現行スクリプトは0/2のみ使用するが、テストでは規約準拠（0/1/2）に備えた設計とする
