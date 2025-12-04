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

## 2. バージョン互換性確認

### 2.1 現在のバージョン確認

```bash
cat docs/aidlc/version.txt 2>/dev/null || echo "VERSION_NOT_FOUND"
```

### 2.2 スターターキットのバージョン確認

このファイル（setup-cycle.md）のディレクトリから `../version.txt` を読み込み、スターターキットのバージョンを確認してください。

### 2.3 バージョン比較

| 状態 | 対応 |
|------|------|
| 同じ | そのまま続行 |
| プロジェクトが古い | アップグレードを案内（任意） |
| プロジェクトが新しい | 警告を表示（スターターキットの更新を推奨） |

---

## 3. サイクルバージョンの確認

```
新しいサイクルのバージョンを入力してください（例: v1.1.0, v2.0.0）:
```

### 既存サイクルの確認

```bash
ls -d docs/cycles/*/ 2>/dev/null | sort -V
```

既存のサイクル一覧を表示し、重複がないか確認してください。

---

## 4. Git ブランチの確認

### 4.1 現在のブランチ

```bash
git branch --show-current
```

### 4.2 ブランチ作成の提案

```
現在のブランチ: [ブランチ名]

推奨: cycle/[バージョン] ブランチで作業することを推奨します。

1. 新しいブランチを作成して切り替える: git checkout -b cycle/[バージョン]
2. 現在のブランチで続行する

どちらを選択しますか？
```

---

## 5. サイクルディレクトリの作成

### 5.1 ディレクトリ構造

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

### 5.2 .gitkeep の配置

各ディレクトリに `.gitkeep` ファイルを配置:

```bash
find docs/cycles/[バージョン] -type d -empty -exec touch {}/.gitkeep \;
```

---

## 6. history.md の初期化

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
- docs/cycles/[バージョン]/（各種ディレクトリ）

---

## 次のステップ: Inception Phase の開始

新しいセッションで以下を実行してください：

以下のファイルを読み込んで、サイクル [バージョン] の Inception Phase を開始してください：
docs/aidlc/prompts/inception.md
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
