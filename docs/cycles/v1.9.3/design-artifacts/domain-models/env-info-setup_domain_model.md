# ドメインモデル: env-info.sh セットアップ情報追加

## エンティティ/概念

### EnvironmentInfo（環境情報）

スクリプトが出力する情報の集約。

| 属性 | 型 | 説明 |
|------|------|------|
| toolStatuses | Map<string, string> | 依存ツールの状態（gh, dasel, jj, git） |
| projectName | string | プロジェクト名（aidlc.tomlから） |
| backlogMode | string | バックログモード（aidlc.tomlから） |
| currentBranch | string | 現在のGitブランチ |
| latestCycle | string | 最新サイクルバージョン |

### OutputMode（出力モード）

| モード | 説明 |
|--------|------|
| default | ツール状態のみ出力（既存動作） |
| setup | ツール状態 + セットアップ情報を出力 |

## 責務

### env-info.sh

1. **ツール状態確認**: gh, dasel, jj, git の利用可否を判定
2. **設定読み取り**: docs/aidlc.toml から project.name, backlog.mode を取得
3. **Git情報取得**: 現在のブランチ名を取得
4. **サイクル情報取得**: docs/cycles/ 配下の最新サイクルを特定
5. **統一フォーマット出力**: `key:value` 形式で出力

## 制約

- 既存出力との後方互換性を維持（オプションなしは従来通り）
- dasel が未インストールの場合、設定読み取りはスキップ（空値出力）
- Git リポジトリ外での実行時は current_branch を空値出力
