# 既存コード分析 - v1.18.1

## #257: operations.md 行数超過

### 現状
- **ファイル**: `prompts/package/prompts/operations.md`（正本）
- **行数**: 1,097行（閾値1,000行を超過）

### セクション構成

| セクション | 行範囲 | 行数 | 内容 |
|-----------|--------|------|------|
| プロジェクト情報 | 11-96 | 86 | 初期設定、ルール参照 |
| あなたの役割 | 99-103 | 5 | 役割定義 |
| 最初に必ず実行すること | 105-288 | 184 | 初期化7ステップ |
| フロー（ステップ0-5） | 292-505 | 214 | メインワークフロー |
| フロー（ステップ6） | 506-895 | 399 | リリース準備（最大セクション） |
| 実行ルール〜完了 | 905-1097 | 192 | ルール、完了基準、サイクル完了 |

### 分割方針（責務単位）

operations.mdを**ステップ6（リリース準備）を別ファイルに抽出**することで閾値以下にする。

- `operations.md`: セットアップ〜ステップ5 + 完了処理（約700行）
- `operations-release.md`: ステップ6のリリース準備処理（約400行）

ステップ6はバージョン確認、CHANGELOG、PR操作、マージなど独立性が高く、分離に適している。

---

## #254: write-history.sh コマンドインジェクション

### 現状
- **ファイル**: `prompts/package/bin/write-history.sh`（正本）
- **結論**: **現状のスクリプトはセキュアである**

### 分析結果

| 箇所 | 評価 | 理由 |
|------|------|------|
| --content引数の取得（L273-279） | 安全 | `"$2"` で正しくクォート |
| format_entry()での使用（L203） | 安全 | ローカル変数で受け取り、echoで出力 |
| ファイル書き込み（L421） | 安全 | `echo "$entry" >> "$filepath"` で安全 |

- `eval`、バッククォート、コマンド置換なし
- 全変数が二重引用符で保護済み
- `set -euo pipefail` で厳密モード有効

### 対応方針

スクリプト自体は安全だが、**呼び出し側のプロンプト記載**（heredocでの`--content`渡し方）に関する注意事項を明確化する。具体的には：
- プロンプト内のheredoc例で安全なパターンを明示
- 終端トークン（CONTENT_EOF等）のインジェクション防止の注意書きを追加

---

## #248: validate-uncommitted.sh と validate-remote-sync.sh の統合

### 現状

| 項目 | validate-uncommitted.sh | validate-remote-sync.sh |
|------|------------------------|------------------------|
| 行数 | 約45行 | 約96行 |
| 目的 | 未コミット変更の検出 | リモート未プッシュの検出 |
| 出力形式 | status:ok/warning/error | status:ok/warning/error |
| エラー種類 | 1種類 | 5種類 |
| 使用場面 | Operations ステップ6.6.5 | Operations ステップ6.6.6 |

### 統合方針

**サブコマンド方式で統合**:
```bash
validate-git.sh uncommitted   # 旧 validate-uncommitted.sh
validate-git.sh remote-sync   # 旧 validate-remote-sync.sh
validate-git.sh all           # 両方実行
```

- 出力形式は既存と同じ（後方互換性維持）
- 旧スクリプト名は互換ラッパーとして残す（非推奨警告付き）
- `all` サブコマンドで一括実行可能

### 呼び出し箇所
- `prompts/package/prompts/operations.md`（ステップ6.6.5, 6.6.6）

---

## #227: PRマージ後のworktreeクリーンアップスクリプト

### 現状
- **既存スクリプト**: なし（手動作業）
- **手動手順**（`docs/cycles/rules.md` L153-179）:
  1. メインリポジトリで `git pull origin main`
  2. worktreeで `git fetch origin`
  3. `git checkout --detach origin/main`
  4. `git branch -d cycle/vX.X.X`
  5. `git push origin --delete cycle/vX.X.X`

### 実装方針

`prompts/package/bin/post-merge-cleanup.sh` を新規作成:

- **入力**: `--cycle <version>` 必須、`--dry-run` オプション
- **処理**: `git worktree list` でメインリポジトリを自動検出し、5ステップを順次実行
- **出力**: `status:success|warning|error`, `branch:`, `main_repo_path:`, `message:`
- **エラー処理**: 失敗時にエラーメッセージと手動復旧手順を提示
- **参考スクリプト**: `setup-branch.sh`（出力形式）、`pr-ops.sh`（エラーハンドリング）
