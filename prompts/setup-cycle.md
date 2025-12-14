# AI-DLC サイクル開始

このファイルは新しい開発サイクルを開始します。

**前提**:
- setup-prompt.md から誘導されてこのファイルを読み込んでいること
- `docs/aidlc/project.toml` が存在すること（初回セットアップ済み）

---

## 1. プロジェクト設定の読み込み

`docs/aidlc/project.toml` を読み込んでください。

このファイルには以下の情報が含まれています:
- プロジェクト名・概要
- 技術スタック
- パス設定
- 開発ルール

---

## 2. サイクルバージョンの確認

### 2.1 既存サイクルの検出

まず、既存サイクルを確認します:

```bash
ls -d docs/cycles/v*/ 2>/dev/null | sort -V
```

### 2.2 バージョン提案

#### ケース A: 既存サイクルがある場合

最新バージョンから次バージョンを提案します。

**バージョン解析手順**:
1. 最新サイクル（ソート後の最後）を特定
2. バージョン文字列を解析: `v{major}.{minor}.{patch}` 形式
3. 次バージョン候補を生成

**提案表示**:

```
既存サイクル: [一覧]
最新バージョン: v{X}.{Y}.{Z}

次バージョンの提案:
1. v{X}.{Y}.{Z+1}（パッチ - バグ修正・小さな変更）[推奨]
2. v{X}.{Y+1}.0（マイナー - 新機能追加）
3. v{X+1}.0.0（メジャー - 破壊的変更）
4. その他（カスタム入力）

どれを選択しますか？
```

- 1〜3 を選択: 該当バージョンを使用
- 4 を選択: カスタムバージョンを入力

#### ケース B: 既存サイクルがない場合（初回サイクル）

プロジェクトのバージョン情報を調査して提案します。

**調査対象ファイル**（優先順位順）:

| 優先順位 | ファイル | 対象 |
|----------|----------|------|
| 1 | `package.json` | Node.js プロジェクト |
| 2 | `pyproject.toml` | Python プロジェクト |
| 3 | `Cargo.toml` | Rust プロジェクト |
| 4 | `build.gradle` / `pom.xml` | Java プロジェクト |

**調査手順**:
1. 上記ファイルを順にチェックし、バージョン情報を抽出
2. 最初に見つかったバージョンを採用

**バージョンが検出された場合**:

```
プロジェクトバージョン [検出されたバージョン] を検出しました（ソース: [ファイル名]）。

このバージョンをサイクルバージョンとして使用しますか？
1. はい、v[検出されたバージョン] を使用する
2. いいえ、別のバージョンを入力する
```

**バージョンが検出されなかった場合**:

```
プロジェクトバージョンが検出されませんでした。

サイクルバージョンの提案:
1. v1.0.0（デフォルト）[推奨]
2. その他（カスタム入力）

どれを選択しますか？
```

### 2.3 重複チェック

選択されたバージョンが既存サイクルと重複する場合、エラーを表示:

```
エラー: サイクル [バージョン] は既に存在します。
別のバージョンを選択してください。
```

2.2 に戻って再選択を促します。

---

## 3. Git ブランチの確認

### 3.1 現在のブランチ

```bash
git branch --show-current
```

### 3.2 ブランチ作成の提案

`docs/aidlc.toml` の `[rules.worktree]` 設定を確認:

```bash
grep -A1 "^\[rules.worktree\]" docs/aidlc.toml 2>/dev/null | grep "enabled" | grep -q "true" && echo "WORKTREE_ENABLED" || echo "WORKTREE_DISABLED"
```

#### worktree が有効な場合（WORKTREE_ENABLED）

```
現在のブランチ: [ブランチ名]

推奨: cycle/[バージョン] ブランチで作業することを推奨します。

1. git worktreeを使用して新しい作業ディレクトリを作成する
2. 新しいブランチを作成して切り替える: git checkout -b cycle/[バージョン]
3. 現在のブランチで続行する

どれを選択しますか？
```

**1を選択した場合（worktree使用）**:

```
## git worktree の使用

git worktreeを使うと、同じリポジトリの複数ブランチを別ディレクトリで同時に開けます。
複数サイクルの並行作業に便利です。

**推奨ディレクトリ構成**:

~/projects/
├── my-project/              # メインディレクトリ（mainブランチ）
├── my-project-v1.4.0/       # worktree（cycle/v1.4.0ブランチ）
└── my-project-v1.5.0/       # worktree（cycle/v1.5.0ブランチ）

**worktree作成コマンド**:

# 親ディレクトリに移動してworktreeを作成
cd ..
git -C [元のディレクトリ名] worktree add -b cycle/[バージョン] [元のディレクトリ名]-[バージョン]
cd [元のディレクトリ名]-[バージョン]

作成後、新しいディレクトリでセッションを開始してください。
```

worktree作成後、セクション4以降は新しいディレクトリで実行します。

#### worktree が無効な場合（WORKTREE_DISABLED）- デフォルト

```
現在のブランチ: [ブランチ名]

推奨: cycle/[バージョン] ブランチで作業することを推奨します。

1. 新しいブランチを作成して切り替える: git checkout -b cycle/[バージョン]
2. 現在のブランチで続行する

どちらを選択しますか？
```

---

## 4. サイクルディレクトリの作成

### 4.1 ディレクトリ構造

```bash
mkdir -p docs/cycles/[バージョン]/plans
mkdir -p docs/cycles/[バージョン]/requirements
mkdir -p docs/cycles/[バージョン]/story-artifacts/units
mkdir -p docs/cycles/[バージョン]/design-artifacts/domain-models
mkdir -p docs/cycles/[バージョン]/design-artifacts/logical-designs
mkdir -p docs/cycles/[バージョン]/design-artifacts/architecture
mkdir -p docs/cycles/[バージョン]/inception
mkdir -p docs/cycles/[バージョン]/construction/units
mkdir -p docs/cycles/[バージョン]/operations
```

### 4.2 .gitkeep の配置

各ディレクトリに `.gitkeep` ファイルを配置:

```bash
find docs/cycles/[バージョン] -type d -empty -exec touch {}/.gitkeep \;
```

---

## 5. history.md の初期化

`docs/cycles/[バージョン]/history.md` を作成:

```markdown
# プロンプト実行履歴

## サイクル
[バージョン]

---

## [現在日時]

**フェーズ**: 準備
**実行内容**: サイクル開始
**成果物**:
- docs/cycles/[バージョン]/（サイクルディレクトリ）

---
```

**日時取得方法**:
```bash
date '+%Y-%m-%d %H:%M:%S %Z'
```

---

## 6. サイクル固有バックログの作成

`docs/cycles/[バージョン]/backlog.md` を作成（テンプレート: `docs/aidlc/templates/cycle_backlog_template.md`）:

このファイルには以下を記録します:
- このサイクルで発見した改善点・技術的負債
- 共通バックログから対応する項目（転記）

Operations Phase完了時に共通バックログへ反映されます。

---

## 7. Git コミット

サイクル開始で作成したファイルをコミット:

```bash
git add docs/cycles/[バージョン]/
git commit -m "feat: サイクル [バージョン] 開始"
```

---

## 8. 完了メッセージ

```
サイクル [バージョン] の準備が完了しました！

作成されたファイル:
- docs/cycles/[バージョン]/history.md
- docs/cycles/[バージョン]/backlog.md
- docs/cycles/[バージョン]/（各種ディレクトリ）

**重要**: Inception Phase で計画を立ててから実装してください。
セットアップ完了後すぐに実装コードを書き始めないでください。

---

## 次のステップ: Inception Phase の開始

新しいセッションで以下を実行してください：

**Full版**（推奨: 新機能・大きな変更）:

以下のファイルを読み込んで、サイクル [バージョン] の Inception Phase を開始してください：
docs/aidlc/prompts/inception.md

**Lite版**（バグ修正・小さな変更）:

以下のファイルを読み込んで、サイクル [バージョン] の Inception Phase (Lite) を開始してください：
docs/aidlc/prompts/lite/inception.md
```

---

## 補足: サイクル種別

### Full サイクル（デフォルト）

全ステップを実行する完全版:
- Inception: Intent → ユーザーストーリー → Unit定義
- Construction: 設計 → 実装 → テスト
- Operations: デプロイ → 監視

### Lite サイクル（オプション）

軽微な変更向けの軽量版:
- 一部ステップを省略
- バグ修正や小さな機能追加に適用

Lite サイクルを使用する場合は、Inception Phase 開始時に以下を読み込んでください:
```
docs/aidlc/prompts/lite/inception.md
```
