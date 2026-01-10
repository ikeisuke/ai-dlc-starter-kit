# 論理設計: バージョンタグ運用

## 概要
Operations Phaseにバージョンタグ付けとCHANGELOG更新の手順を追加する設計。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコード（SQL、JSON、実装コード等）はImplementation Phase（コード生成ステップ）で作成します。

## アーキテクチャパターン
プロンプトファイル（operations.md）への手順追加。既存のフロー構造を維持しつつ、適切な位置に新しいステップを挿入する。

## 変更対象

### 対象ファイル
- `prompts/package/prompts/operations.md`

### 完了条件への追加
既存の完了条件セクションにCHANGELOG更新を追加:
- 「完了時の確認【重要】」セクションにCHANGELOG更新完了を追記

### 変更箇所

#### 1. CHANGELOG更新手順の追加

**追加位置**: ステップ6「リリース準備」のセクション内、6.1 README更新の前に「6.0 CHANGELOG更新」として追加

**内容**:
- CHANGELOG.mdの存在確認
- 現在のサイクルのエントリがあるか確認
- なければ追加を促す
- Keep a Changelog形式での記載ガイド

#### 2. バージョンタグ付け手順の追加

**追加位置**: 「5. PRマージ後の手順」セクション内、mainブランチ移動後に追加

**内容**:
- バージョンタグの作成（`git tag -a`）
- タグのリモートへのプッシュ（`git push origin --tags`）
- GitHub Releaseの作成（オプション、gh CLI使用）

## 処理フロー概要

### CHANGELOG更新フロー

**ステップ**:
1. CHANGELOG.mdの存在確認
2. 現在のサイクルバージョンのエントリ確認
3. エントリがなければ追加を促す
4. Keep a Changelog形式でのガイド提示

**関与するコンポーネント**: operations.md（ステップ6）

### バージョンタグ付けフロー

**ステップ**:
1. PRマージ完了を確認
2. mainブランチに移動
3. 最新の変更を取得（`git pull origin main`）
4. **git pull後に**バージョンタグを作成（`git tag -a vX.X.X -m "Release vX.X.X"`）
5. タグをリモートにプッシュ（`git push origin vX.X.X` - 個別タグ指定で安全）
6. （オプション）GitHub Releaseを作成

**関与するコンポーネント**: operations.md（セクション5）

## 詳細設計

### 6.0 CHANGELOG更新（追加セクション）

```markdown
#### 6.0 CHANGELOG更新【推奨】

CHANGELOG.mdを更新し、現在のサイクルの変更内容を記録します。

**CHANGELOG.md確認**:
\`\`\`bash
# CHANGELOG.mdの存在確認
ls CHANGELOG.md 2>/dev/null && echo "CHANGELOG_EXISTS" || echo "CHANGELOG_NOT_EXISTS"
\`\`\`

**存在しない場合**:
\`\`\`text
CHANGELOG.mdが存在しません。

1. 作成する - Keep a Changelog形式で新規作成
2. スキップ - CHANGELOGなしで続行
\`\`\`

**存在する場合**:
現在のサイクルバージョンのエントリがあるか確認し、なければ追加を促す。
※ Unreleasedセクションは使用しない。直接バージョン付きエントリを作成する。

**Keep a Changelog形式**:
\`\`\`markdown
## [X.Y.Z] - YYYY-MM-DD
※ バージョン番号はvなし（[1.6.0]形式）で記載
※ サイクル名から「v」を除いた形式で記載

### Added
- 新機能

### Changed
- 変更点

### Fixed
- バグ修正
\`\`\`

**参考**: [Keep a Changelog](https://keepachangelog.com/)
```

### バージョンタグ付け手順（追加セクション）

```markdown
#### バージョンタグ付け【推奨】

PRマージ後、`git pull origin main`の後にバージョンタグを付与します。

**タグ作成**:
\`\`\`bash
# アノテーション付きタグを作成（マージ後の最新コミットに付与）
git tag -a vX.X.X -m "Release vX.X.X"

# タグをリモートにプッシュ（個別タグ指定で安全にプッシュ）
git push origin vX.X.X
\`\`\`

**GitHub Release作成（オプション）**:
\`\`\`bash
# GitHub CLIが利用可能な場合
gh release create vX.X.X --title "vX.X.X" --notes "See CHANGELOG.md for details"
\`\`\`
```

## 非機能要件（NFR）への対応

### パフォーマンス
- N/A（プロンプトファイルの変更のみ）

### セキュリティ
- N/A

### スケーラビリティ
- N/A

### 可用性
- N/A

## 技術選定
- **言語**: Markdown
- **ツール**: git, gh（GitHub CLI）

## 実装上の注意事項
- `docs/aidlc/`は直接編集禁止、`prompts/package/`を編集すること
- 既存のフロー構造を壊さないよう、適切な位置に挿入
- 【推奨】タグを使用し、必須ではないことを明示

## 不明点と質問（設計中に記録）

現時点で不明点はありません。
