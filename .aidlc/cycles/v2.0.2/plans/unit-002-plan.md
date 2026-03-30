# Unit 002 計画: v1→v2移行スキル

## 概要

v1環境からv2への自動移行機能（`/aidlc migrate`）を作成し、v1痕跡のクリーンアップとKiroエージェント設定のサンプル提供を行う。

## アーキテクチャ

### 責務分離

移行処理はオーケストレーション層（ステップファイル）と実処理層（スクリプト群）に分離する。

- **ステップファイル（`steps/migrate/`）**: AIエージェントが読み込むオーケストレーション指示。状態遷移の制御のみを担当
- **スクリプト群（`scripts/`）**: 副作用を持つ下位処理。各スクリプトは単一責務

### スクリプト構成と入出力インターフェース

**I/O方針**: `stdout=機械可読JSON`、`stderr=人向け診断メッセージ`

| スクリプト | 責務 | 入力 | 出力(stdout) | 終了コード |
|-----------|------|------|-------------|-----------|
| `migrate-detect.sh` | v1環境検出・移行計画生成 | なし | manifest JSON（status で v1/v2 判定） | 0: 成功, 2: エラー |
| `migrate-backup.sh` | バックアップ作成（cleanup対象含む） | `--manifest <path>` | backup result JSON（backup_dir を含む） | 0: 成功, 2: エラー |
| `migrate-apply-config.sh` | config.toml パス更新 | `--manifest <path>` `--backup-dir <path>` | journal JSON（config phase） | 0: 成功, 2: エラー |
| `migrate-apply-data.sh` | cycles配下データ移行 | `--manifest <path>` `--backup-dir <path>` | journal JSON（data phase） | 0: 成功, 2: エラー |
| `migrate-cleanup.sh` | v1痕跡削除（manifest宣言済みリソースのみ） | `--manifest <path>` `--backup-dir <path>` | journal JSON（cleanup phase） | 0: 成功, 2: エラー |
| `migrate-verify.sh` | 移行後検証 | `--manifest <path>` | verify result JSON（overall で ok/fail） | 0: 成功, 2: エラー |

**終了コード方針**: 全スクリプト共通で `0=実行成功`（状態遷移はJSONペイロードの status/overall で表現）、`2=実行失敗`。

**ロールバック単位とスクリプトの対応**:
- config phase → `migrate-apply-config.sh` → バックアップからリストア
- data phase → `migrate-apply-data.sh` → バックアップからリストア
- cleanup phase → `migrate-cleanup.sh` → バックアップからリストア

### manifest JSONスキーマ

```json
{
  "version": 1,
  "detected_at": "ISO8601",
  "source_version": "v1",
  "target_version": "v2",
  "backlog_mode": "issue-only",
  "resources": [
    {
      "resource_type": "symlink_agents",
      "path": ".agents/skills/aidlc-setup",
      "link_target": "../../docs/aidlc/skills/aidlc-setup",
      "action": "delete"
    },
    {
      "resource_type": "symlink_kiro",
      "path": ".kiro/agents/aidlc.json",
      "link_target": "../../docs/aidlc/kiro/agents/aidlc.json",
      "action": "delete"
    },
    {
      "resource_type": "file_kiro",
      "path": ".kiro/agents/aidlc-poc.json",
      "action": "delete"
    },
    {
      "resource_type": "backlog_dir",
      "path": ".aidlc/cycles/backlog/",
      "action": "delete",
      "condition": "backlog_mode in [issue, issue-only]"
    },
    {
      "resource_type": "github_template",
      "path": ".github/ISSUE_TEMPLATE/backlog.yml",
      "action": "delete"
    },
    {
      "resource_type": "config_update",
      "path": ".aidlc/config.toml",
      "action": "update",
      "updates": {"paths.aidlc_dir": "docs/aidlc → 新パス"}
    },
    {
      "resource_type": "data_migration",
      "source": ".aidlc/cycles/xxx/rules.md",
      "target": ".aidlc/cycles/xxx/rules.md",
      "action": "migrate"
    }
  ]
}
```

**resource_type一覧**（allowlist）:
- `symlink_agents`: `.agents/skills/` 内のシンボリックリンク
- `symlink_kiro`: `.kiro/skills/`, `.kiro/agents/` 内のシンボリックリンク
- `file_kiro`: `.kiro/agents/` 内の既知実体ファイル（POC等）
- `backlog_dir`: `.aidlc/cycles/backlog/` ディレクトリ
- `github_template`: `.github/ISSUE_TEMPLATE/` 内のスターターキット由来テンプレート
- `config_update`: config.toml のパス更新
- `data_migration`: cycles配下のデータ移行

### journal JSONスキーマ

```json
{
  "phase": "config|data",
  "applied": [
    {"resource_type": "...", "path": "...", "status": "success|skipped|error", "detail": "..."}
  ]
}
```

### backup result JSONスキーマ

```json
{
  "backup_dir": "/tmp/aidlc-migrate-backup-XXXXXX",
  "files": [
    {"source": ".aidlc/config.toml", "backup": "/tmp/.../config.toml"}
  ]
}
```

### cleanup result JSONスキーマ

```json
{
  "deleted": [
    {"resource_type": "...", "path": "...", "status": "success|skipped|error", "detail": "..."}
  ]
}
```

### verify result JSONスキーマ

```json
{
  "checks": [
    {"name": "config_paths", "status": "ok|fail", "detail": "..."},
    {"name": "v1_symlinks_removed", "status": "ok|fail", "detail": "..."},
    {"name": "data_migrated", "status": "ok|fail", "detail": "..."}
  ],
  "overall": "ok|fail"
}
```

### 削除対象の所有権判定（allowlist方式）

削除対象は「AI-DLCが生成したことを判定できるもの」に限定する。判定ロジックは `migrate-detect.sh` が担当し、manifest の `resources` に宣言する。`migrate-cleanup.sh` は manifest に宣言済みのリソースのみを削除する（自身では判定しない）。

**判定基準**（detect側で実施）:

| 対象 | resource_type | 判定方法 | 削除条件 |
|------|--------------|---------|---------|
| `.agents/skills/*` | symlink_agents | シンボリックリンクかつリンク先が `docs/aidlc/` を含む | allowlist一致 |
| `.kiro/skills/*` | symlink_kiro | シンボリックリンクかつリンク先が `docs/aidlc/` を含む | allowlist一致 |
| `.kiro/agents/aidlc.json` | symlink_kiro | シンボリックリンクかつリンク先が `docs/aidlc/` を含む | allowlist一致 |
| `.kiro/agents/aidlc-poc.json` | file_kiro | 既知ファイル名 + 内容ハッシュ検証（スターターキット原本のSHA256と一致） | allowlist + ハッシュ一致 |
| `.aidlc/cycles/backlog/` | backlog_dir | ディレクトリ存在 | backlog mode が `issue` or `issue-only` の場合のみ |
| `.github/ISSUE_TEMPLATE/*.yml` | github_template | 既知ファイル名 + 内容ハッシュ検証（スターターキット原本のSHA256と一致。ユーザー編集済みはスキップ） | allowlist + ハッシュ一致 |

**ユーザー作成ファイルの保護**: allowlistに含まれないファイルは manifest に含まれず、削除されない。実体ファイル（シンボリックリンクでないもの）は内容ハッシュ検証を併用し、ユーザーが編集済みの場合は削除をスキップする。

### backlog mode別 移行マトリクス

| backlog mode | `.aidlc/cycles/backlog/` 内ファイル移行 | `.aidlc/cycles/backlog/` ディレクトリ削除 |
|-------------|----------------------------------------|----------------------------------------|
| `git` | 保持（そのまま） | しない |
| `git-only` | 保持（そのまま） | しない |
| `issue` | バックアップ後削除 | する |
| `issue-only` | バックアップ後削除 | する |

### ロールバック設計

**単位**: config / data / cleanup の3フェーズに分離。各フェーズのスクリプトと1対1対応。

| フェーズ | スクリプト | 成功条件 | 復旧方法 | 復旧条件 |
|---------|-----------|---------|---------|---------|
| config | `migrate-apply-config.sh` | config.tomlのパス値が正しい | バックアップからリストア | 失敗時 |
| data | `migrate-apply-data.sh` | cycles配下のファイルが移行先に存在 | バックアップからリストア | 失敗時 |
| cleanup | `migrate-cleanup.sh` | allowlist対象が削除済み | バックアップからリストア | 失敗時 |

**方式**: manifest（変更計画）を先に確定 → `migrate-backup.sh` で全対象（cleanup含む）のスナップショットを作成 → apply/cleanup後にjournal保持 → 失敗時はバックアップから復元

## 変更対象ファイル

### 新規作成

- `skills/aidlc/steps/migrate/01-preflight.md` — v1検出・manifest生成・バックアップ確認
- `skills/aidlc/steps/migrate/02-execute.md` — manifest入力として移行実行・クリーンアップ
- `skills/aidlc/steps/migrate/03-verify.md` — manifest入力として期待状態との差分検証・完了メッセージ
- `skills/aidlc/scripts/migrate-detect.sh` — v1環境検出・manifest生成（判定ロジック担当）
- `skills/aidlc/scripts/migrate-backup.sh` — バックアップ作成（cleanup対象含む）
- `skills/aidlc/scripts/migrate-apply-config.sh` — config.toml パス更新
- `skills/aidlc/scripts/migrate-apply-data.sh` — cycles配下データ移行
- `skills/aidlc/scripts/migrate-cleanup.sh` — v1痕跡削除（manifest宣言済みリソースのみ）
- `skills/aidlc/scripts/migrate-verify.sh` — 移行後検証（manifest対比）
- `examples/kiro/README.md` — Kiroエージェント設定サンプルの説明
- `examples/kiro/agents/aidlc.json` — Kiroエージェント設定サンプル

### 既存ファイル更新

- `skills/aidlc/SKILL.md` — 引数ルーティングテーブルに `migrate` 行追加
- `skills/aidlc/CLAUDE.md` — フェーズ簡略指示テーブルに移行指示追加
- `skills/aidlc/AGENTS.md` — フェーズ簡略指示テーブルに移行指示追加

## 実装計画

### Phase 1: 設計

1. ドメインモデル設計: 移行フローの状態遷移（検出→バックアップ→config適用→data適用→クリーンアップ→検証）
2. 論理設計: スクリプト間のインターフェース（manifest/journal JSONスキーマ、終了コード、ロールバック条件）

### Phase 2: 実装

1. `/aidlc migrate` のルーティング追加（SKILL.md, CLAUDE.md, AGENTS.md）
2. 移行スクリプト群の実装（上記7スクリプト）
3. 移行ステップファイルの作成（`steps/migrate/`）
4. `examples/kiro/` サンプル作成
5. テスト・検証

## 完了条件チェックリスト

- [ ] `/aidlc migrate` コマンドがSKILL.mdの引数ルーティングに登録されている
- [ ] 移行ステップファイル（`steps/migrate/`）が作成されている
- [ ] config.tomlのパス更新ロジックが実装されている（`migrate-apply-config.sh`）
- [ ] cycles配下のデータ移行が実装されている（`migrate-apply-data.sh`）
- [ ] v1由来の不要ファイル削除がallowlist方式・manifest宣言ベースで実装されている
- [ ] backlog mode別の移行マトリクスに基づく分岐が実装されている
- [ ] `.github/ISSUE_TEMPLATE/` のスターターキット由来テンプレート削除が実装されている
- [ ] `examples/kiro/` へのサンプルファイル配置とREADME作成が完了している
- [ ] バックアップ・ロールバック機能がmanifest/journal方式で実装され、cleanup対象もバックアップに含まれている
- [ ] 冪等性が確保されている（既にv2環境なら何もしない）
- [ ] 各スクリプトの入出力がJSON形式で、終了コードが設計通り実装されている
