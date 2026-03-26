# Unit 003 計画: バージョンチェック機能統合

## 概要

環境一覧スクリプト `env-info.sh` にバージョンチェック機能を組み込み、環境情報とバージョン情報を一括で確認できるようにする。

## 変更対象ファイル

| ファイル | 変更種別 | 変更内容 |
|---------|---------|---------|
| `prompts/package/bin/env-info.sh` | 修正 | バージョン情報出力機能を追加 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: バージョン情報取得ロジックの構造を定義
2. **論理設計**: `env-info.sh` への統合方法を設計

### Phase 2: 実装

1. **コード生成**: `env-info.sh` にバージョン出力機能を追加
   - `version.txt` からスターターキットバージョンを取得
   - 出力形式: `starter_kit_version:X.X.X`
   - 既存の `check-version.sh` のロジックを再利用可能な形で統合
2. **テスト**: スクリプトの動作確認
3. **統合とレビュー**: AIレビュー実行、実装記録作成

## 設計方針

### バージョン情報の取得方法

- 既存の `prompts/setup/bin/check-version.sh` が `version.txt` を参照している
- `env-info.sh` にも同様のロジックを追加するが、シンプルなバージョン表示に特化
- `version.txt` はプロジェクトルート直下に配置されている

### 出力形式

```text
# 通常出力
gh:available
dasel:available
jj:available
git:available
starter_kit_version:1.9.2   # 新規追加

# --setup オプション時
gh:available
dasel:available
jj:available
git:available
starter_kit_version:1.9.2   # 新規追加
project.name:my-project
backlog.mode:issue-only
current_branch:main
latest_cycle:v1.0.0
```

## 完了条件チェックリスト

- [ ] 環境確認スクリプト（`env-info.sh`）へのバージョン出力機能追加
- [ ] `version.txt` からのバージョン情報取得が正常に動作すること
