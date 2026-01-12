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

**ステップ**:

1. **project.pbxprojファイルの検索**
   - `find . -name "project.pbxproj"` で検索（Pods/DerivedData除外）
   - 複数見つかった場合はユーザーに確認
   - 見つからない場合は理由を明示してスキップ

2. **デフォルトブランチの取得**
   - `git remote show origin | grep "HEAD branch"` で取得
   - 取得失敗時は `main` または `master` を順に試行
   - リモートブランチ参照は `origin/${DEFAULT_BRANCH}` を使用

3. **CURRENT_PROJECT_VERSIONの抽出**
   - 現在ブランチから抽出
   - デフォルトブランチ（リモート）から抽出
   - 複数ターゲット/構成がある場合は最初に見つかった値を使用

4. **比較と判定**
   - ビルド番号が同一の場合: インクリメントを提案
   - 異なる場合: 確認完了
   - 抽出失敗の場合: 手動確認を促す

5. **結果表示**
   - 比較結果を表示
   - 必要に応じて警告を表示

**関与するコンポーネント**: operations.md（プロンプトファイル）

## 詳細設計

### 追加するセクション位置

既存の「##### iOSプロジェクトの場合の事前確認」セクションの「**判定結果**」の後に、新しいサブセクション「##### iOSビルド番号確認」を追加する。

### 追加するコマンド例

```bash
# デフォルトブランチを取得
DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep "HEAD branch" | sed 's/.*: //')
[ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH="main"
git rev-parse --verify origin/${DEFAULT_BRANCH} >/dev/null 2>&1 || DEFAULT_BRANCH="master"

# project.pbxprojファイルを検索（Pods/DerivedData除外）
PROJECT_FILES=$(find . -name "project.pbxproj" \
    -not -path "*/Pods/*" \
    -not -path "*/DerivedData/*" \
    -not -path "*/.build/*" \
    2>/dev/null)
PROJECT_COUNT=$(echo "$PROJECT_FILES" | grep -c . 2>/dev/null || echo 0)

# ファイルが見つからない場合 → スキップ
if [ "$PROJECT_COUNT" -eq 0 ]; then
    echo "PROJECT_NOT_FOUND"
    # ビルド番号確認をスキップし、次のステップへ進む
    exit 0  # または return（関数内の場合）
fi

# 複数ファイルの場合はユーザー確認が必要
if [ "$PROJECT_COUNT" -gt 1 ]; then
    echo "MULTIPLE_PROJECT_FILES"
    echo "$PROJECT_FILES"
    # AIがユーザーに選択を求め、選択されたファイルを PROJECT_FILE に設定
    # 選択されるまで後続処理に進まない（プロンプト実行時のため、ここで処理停止）
    exit 0  # 選択後に再実行、または対話的に PROJECT_FILE を設定
fi
```

### バージョン抽出コマンド

```bash
# 現在ブランチのビルド番号（`CURRENT_PROJECT_VERSION = 123;` 形式に対応）
CURRENT_BUILD=$(grep "CURRENT_PROJECT_VERSION" ${PROJECT_FILE} \
    | head -1 \
    | sed 's/.*= *\([^;]*\);.*/\1/' \
    | tr -d ' \t"')

# デフォルトブランチのビルド番号（リモートブランチを参照）
PREVIOUS_BUILD=$(git show origin/${DEFAULT_BRANCH}:${PROJECT_FILE} 2>/dev/null \
    | grep "CURRENT_PROJECT_VERSION" \
    | head -1 \
    | sed 's/.*= *\([^;]*\);.*/\1/' \
    | tr -d ' \t"')

# 変数参照チェック（$を含む場合は抽出失敗扱い）
if echo "$CURRENT_BUILD" | grep -q '\$'; then
    CURRENT_BUILD=""
fi
if echo "$PREVIOUS_BUILD" | grep -q '\$'; then
    PREVIOUS_BUILD=""
fi
```

**注意事項**:

- `$` を含む値（`$(CURRENT_PROJECT_VERSION)`、`$(inherited)`、`1.$(BUILD_NUMBER)` 等）は抽出失敗扱い
- 複数ターゲット/構成がある場合は最初に見つかった値を使用
- 抽出失敗時は手動確認を促すメッセージを表示

### 判定ロジック

```text
# 抽出成功チェック
if [ -z "$CURRENT_BUILD" ] || [ -z "$PREVIOUS_BUILD" ]; then
    echo "EXTRACTION_FAILED"
    # 手動確認を促す
elif [ "$CURRENT_BUILD" = "$PREVIOUS_BUILD" ]; then
    echo "WARNING: ビルド番号が前回と同一です"
    # インクリメント提案
else
    echo "OK: ビルド番号が更新されています"
fi
```

### 表示メッセージ

**プロジェクトファイルが見つからない場合**:

```text
【情報】iOSビルド番号確認をスキップします

理由: project.pbxprojファイルが見つかりませんでした。
（Pods/DerivedData/は検索対象外）

iOSプロジェクトの場合は、.xcodeprojディレクトリ内にproject.pbxprojが存在するか確認してください。
```

**抽出失敗の場合**:

```text
【注意】iOSビルド番号を自動抽出できませんでした

プロジェクトファイル: [パス]
現在のビルド番号: 取得失敗
前回のビルド番号: 取得失敗

考えられる原因:
- CURRENT_PROJECT_VERSIONが変数参照（$(inherited)等）になっている
- xcconfig等で外部定義されている

手動でビルド番号を確認してください:
1. Xcode > プロジェクト設定 > Build Settings > Current Project Version
```

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

1. 手動で対応する（推奨）
2. このまま続行する（非推奨）
```

**注意**: 自動インクリメント機能は提供しない（CI/CD推奨、Unit境界に記載）

## 非機能要件（NFR）への対応

### パフォーマンス

- 該当なし（プロンプト実行時のコマンド実行のみ）

### セキュリティ

- 該当なし

### スケーラビリティ

- 該当なし

### 可用性

- gitコマンド失敗時のフォールバック処理を含む
- project.pbxprojが見つからない場合は理由を明示してスキップ
- バージョン抽出失敗時は手動確認を促す

## 技術選定

- **言語**: Bash（シェルスクリプト）
- **ツール**: git, grep, find, sed

## 実装上の注意事項

- project.pbxprojファイルが複数ある場合（ワークスペース等）はユーザー確認が必要
- CURRENT_PROJECT_VERSIONが変数参照の場合は抽出失敗となる
- デフォルトブランチ名が`main`でも`master`でもない場合はフォールバックが必要
- リモートブランチ参照は常に `origin/${DEFAULT_BRANCH}` を使用

## 不明点と質問（設計中に記録）

### AIレビュー指摘への対応

[Question] 複数ターゲット/構成がある場合、どのターゲットを比較対象にする想定ですか？
[Answer] 最初に見つかった値を使用する。詳細な比較が必要な場合は手動確認を促す。

[Question] `CURRENT_PROJECT_VERSION` は「数値のみ」を必須とみなしますか？
[Answer] 数値を想定するが、抽出結果が変数参照等の場合は手動確認を促す。
