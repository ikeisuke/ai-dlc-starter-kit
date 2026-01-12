# 論理設計: iOSバージョン確認強化

## 概要

Operations Phase ステップ1（デプロイ準備）に、iOSプロジェクトのビルド番号（CURRENT_PROJECT_VERSION）確認フローを追加する。

**重要**: この論理設計では**コードは書かず**、処理フローと変更点の定義のみを行います。具体的なプロンプト記述はImplementation Phase（コード生成ステップ）で作成します。

## アーキテクチャパターン

既存のOperations Phaseプロンプト構造に従い、ステップ1の「iOSプロジェクトの場合の事前確認」セクションを拡張する。

## コンポーネント構成

### 変更対象ファイル

```text
prompts/package/prompts/
└── operations.md
    └── ステップ1: デプロイ準備
        └── iOSプロジェクトの場合の事前確認（拡張）
            ├── 既存: MARKETING_VERSION確認
            └── 追加: CURRENT_PROJECT_VERSION確認
```

## 処理フロー概要

### iOSビルド番号確認の処理フロー

**前提条件**:

- `project.type = "ios"` であること
- Inception Phaseでのバージョン更新がスキップされていないこと

**ステップ**:

1. **project.pbxprojファイルの検索**
   - `find . -name "project.pbxproj"` で検索
   - 複数見つかった場合はユーザーに確認
   - 見つからない場合はスキップ

2. **デフォルトブランチの取得**
   - `git remote show origin | grep "HEAD branch"` で取得
   - 取得失敗時は `main` または `master` を順に試行

3. **CURRENT_PROJECT_VERSIONの抽出**
   - 現在ブランチから抽出
   - デフォルトブランチから抽出

4. **比較と判定**
   - ビルド番号が同一の場合: インクリメントを提案
   - 異なる場合: 確認完了

5. **結果表示**
   - 比較結果を表示
   - 必要に応じて警告を表示

**関与するコンポーネント**: operations.md（プロンプトファイル）

## 詳細設計

### 追加するセクション位置

既存の「##### iOSプロジェクトの場合の事前確認」セクションの後に、新しいサブセクション「##### iOSビルド番号確認」を追加する。

### 追加するコマンド例

```bash
# デフォルトブランチを取得
DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep "HEAD branch" | sed 's/.*: //')
[ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH="main"
git rev-parse --verify origin/${DEFAULT_BRANCH} >/dev/null 2>&1 || DEFAULT_BRANCH="master"

# project.pbxprojファイルを検索
PROJECT_FILES=$(find . -name "project.pbxproj" 2>/dev/null)
PROJECT_COUNT=$(echo "$PROJECT_FILES" | grep -c .)

# 複数ファイルの場合はユーザー確認が必要
if [ "$PROJECT_COUNT" -gt 1 ]; then
    echo "MULTIPLE_PROJECT_FILES"
    echo "$PROJECT_FILES"
fi
```

### バージョン抽出コマンド

```bash
# 現在ブランチのビルド番号
CURRENT_BUILD=$(grep -A1 "CURRENT_PROJECT_VERSION" ${PROJECT_FILE} | grep -E "^\s+[0-9]+" | head -1 | tr -d ' \t;')

# デフォルトブランチのビルド番号
PREVIOUS_BUILD=$(git show ${DEFAULT_BRANCH}:${PROJECT_FILE} 2>/dev/null | grep -A1 "CURRENT_PROJECT_VERSION" | grep -E "^\s+[0-9]+" | head -1 | tr -d ' \t;')
```

### 判定ロジック

```text
if [ "$CURRENT_BUILD" = "$PREVIOUS_BUILD" ]; then
    echo "WARNING: ビルド番号が前回と同一です"
    # インクリメント提案
else
    echo "OK: ビルド番号が更新されています"
fi
```

### 表示メッセージ

**確認結果（正常）**:

```text
iOSビルド番号確認結果:
- プロジェクトファイル: [パス]
- 現在のビルド番号: [番号]
- 前回のビルド番号: [番号]
- 状態: 更新済み ✓
```

**警告（ビルド番号同一）**:

```text
【警告】iOSビルド番号が前回と同一です

- 現在のビルド番号: [番号]
- 前回のビルド番号: [番号]

App Storeは同一ビルド番号での再提出を拒否します。
ビルド番号をインクリメントすることを推奨します。

1. 自動インクリメントする（[番号] → [番号+1]）
2. 手動で対応する
3. このまま続行する（非推奨）
```

## 非機能要件（NFR）への対応

### パフォーマンス

- 該当なし（プロンプト実行時のコマンド実行のみ）

### セキュリティ

- 該当なし

### スケーラビリティ

- 該当なし

### 可用性

- gitコマンド失敗時のフォールバック処理を含む
- project.pbxprojが見つからない場合はスキップ

## 技術選定

- **言語**: Bash（シェルスクリプト）
- **ツール**: git, grep, find, sed

## 実装上の注意事項

- project.pbxprojファイルが複数ある場合（ワークスペース等）はユーザー確認が必要
- CURRENT_PROJECT_VERSIONはプロジェクト設定によって異なる行に記載される可能性あり
- デフォルトブランチ名が`main`でも`master`でもない場合はフォールバックが必要

## 不明点と質問（設計中に記録）

※ 現時点で不明点なし
