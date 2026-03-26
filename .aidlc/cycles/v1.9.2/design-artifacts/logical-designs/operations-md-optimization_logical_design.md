# 論理設計: operations.mdサイズ最適化

## 設計方針

### 1. 付録の外部ファイル化

**変更内容**:
- 「付録: 依存コマンド追加手順」セクション（128行）を削除
- 新規ファイル `prompts/package/guides/dependency-commands.md` に内容を移動
- operations.mdには参照リンク（3行程度）を追加

**削減効果**: 約125行

**新規ファイル構成**:
```
prompts/package/guides/dependency-commands.md
├── # 依存コマンド追加手順
├── ## 1. env-info.shへの追加
│   ├── ### 1.1 汎用ツールの場合
│   └── ### 1.2 認証が必要なツールの場合
├── ## 2. setup.mdへの追加
├── ## 3. 各プロンプトでの利用方法追加
└── ## 4. チェックリスト
```

### 2. iOSビルド番号確認のスクリプト化

**変更内容**:
- iOSビルド番号確認ロジック（約80行）をヘルパースクリプト化
- 新規スクリプト `prompts/package/bin/ios-build-check.sh` を作成
- operations.mdではスクリプト呼び出しと出力解釈のみ記載

**削減効果**: 約60行

**スクリプト仕様**:
```bash
# 使用方法
docs/aidlc/bin/ios-build-check.sh [project.pbxproj path]

# 出力形式
status:found|not-found|multiple
current_build:123
previous_build:122
comparison:updated|same|unknown
files:[file1,file2,...]  # status=multiple の場合
```

### 3. デフォルトブランチ取得のスクリプト化

**変更内容**:
- デフォルトブランチ取得ロジックをヘルパースクリプト化
- 新規スクリプト `prompts/package/bin/get-default-branch.sh` を作成

**削減効果**: 約15行

**スクリプト仕様**:
```bash
# 使用方法
docs/aidlc/bin/get-default-branch.sh

# 出力形式
branch:main
# または
branch:master
# または
branch:unknown
```

### 4. 冗長な記述の簡略化

**変更箇所**:

| 箇所 | 現在 | 変更後 | 削減 |
|------|------|--------|------|
| バージョン確認コマンド例 | 8行 | 4行 | 4行 |
| 空行の最適化 | - | 連続空行を1行に | 数行 |

## 変更ファイル一覧

| ファイル | 操作 | 変更概要 |
|----------|------|----------|
| `prompts/package/prompts/operations.md` | 編集 | 付録削除、スクリプト呼び出しに置換、冗長記述簡略化 |
| `prompts/package/guides/dependency-commands.md` | 新規 | 付録内容を移動 |
| `prompts/package/bin/ios-build-check.sh` | 新規 | iOSビルド番号確認スクリプト |
| `prompts/package/bin/get-default-branch.sh` | 新規 | デフォルトブランチ取得スクリプト |

## 削減見込み

| 項目 | 削減行数 |
|------|----------|
| 付録の外部ファイル化 | 125行 |
| iOSビルド番号スクリプト化 | 60行 |
| デフォルトブランチスクリプト化 | 15行 |
| その他簡略化 | 10行 |
| **合計** | **約210行** |

**見込み結果**: 1029行 → 約820行

## 検証項目

### 行数確認
```bash
wc -l prompts/package/prompts/operations.md
# 期待値: 1000行以下
```

### 必須キーワード確認
```bash
grep -c "CI/CD\|監視\|CHANGELOG\|git tag\|version_tag" prompts/package/prompts/operations.md
# 期待値: 各キーワードが1以上
```

### 必須セクション確認
```bash
grep -c "## 最初に必ず実行すること\|## フロー\|### ステップ1\|## 完了基準" prompts/package/prompts/operations.md
# 期待値: 各セクションが存在
```

### スクリプト動作確認
```bash
# get-default-branch.sh
docs/aidlc/bin/get-default-branch.sh
# 期待: branch:main または branch:master

# ios-build-check.sh (iOSプロジェクトがある場合)
docs/aidlc/bin/ios-build-check.sh
# 期待: status:XXX 形式の出力
```
