# 既存コード分析

## 分析対象

今回の改修に関連するファイル:

1. **prompts/package/prompts/inception.md** - Inception Phase本体
2. **prompts/setup-cycle.md** - サイクル開始（セットアップ）

---

## 1. prompts/package/prompts/inception.md

### 現状の「最初に必ず実行すること（5ステップ）」

| ステップ | 内容 | 現状の動作 |
|----------|------|------------|
| 1 | サイクル存在確認 | 存在しない場合はエラーを表示し、セットアップを促す |
| 2 | 追加ルール確認 | rules.mdを読み込む |
| 3 | バックログ確認 | 共通バックログとサイクル固有バックログを確認 |
| 4 | 進捗管理ファイル確認 | progress.mdの存在確認、なければ作成 |
| 5 | 既存成果物の確認 | 冪等性のため既存ファイルを確認 |

### 改修ポイント

| 機能 | 改修箇所 | 内容 |
|------|----------|------|
| バックログ対応済みチェック | ステップ3 | バックログ確認時にbacklog-completed.mdを参照して対応済みかチェックする手順を追加 |
| セットアップスキップ | ステップ1 | サイクルが存在しない場合、エラーではなくサイクルディレクトリの自動作成を提案 |
| 最新バージョンチェック | ステップ1の前 | prompts/package/version.txtとdocs/aidlc/version.txtを比較し、差異があれば通知 |
| Dependabot PR確認 | ステップ3の前 | gh pr listでDependabot PRの有無を確認 |

---

## 2. prompts/setup-cycle.md

### 現状

- セットアップ時にサイクルディレクトリを作成
- history.md、backlog.mdを初期化
- Gitコミットを実施

### 改修ポイント

変更なし。

ただし、inception.mdにサイクルディレクトリ自動作成機能を追加するため、setup-cycle.mdとの機能重複に注意。
- setup-cycle.md: アップグレード後にサイクルを開始する場合に使用
- inception.md: アップグレード不要でサイクルを直接開始する場合に使用

両方のパスでサイクルディレクトリが正しく作成されることを保証する。

---

## 影響範囲

| ファイル | 改修内容 | 影響度 |
|----------|----------|--------|
| prompts/package/prompts/inception.md | 4機能追加 | 高 |
| prompts/setup-cycle.md | 変更なし | - |
| docs/aidlc/templates/inception_progress_template.md | ステップ6削除（別途対応推奨） | 低 |

---

## 技術的考慮事項

### 最新バージョンチェックの実装

```bash
# バージョン比較
PACKAGE_VERSION=$(cat prompts/package/version.txt 2>/dev/null || echo "unknown")
AIDLC_VERSION=$(cat docs/aidlc/version.txt 2>/dev/null || echo "unknown")

if [ "$PACKAGE_VERSION" != "$AIDLC_VERSION" ]; then
  echo "新しいバージョンが利用可能です: $PACKAGE_VERSION"
  echo "現在のバージョン: $AIDLC_VERSION"
  echo "アップグレードするには setup-prompt.md を実行してください。"
fi
```

### Dependabot PR確認の実装

```bash
# Dependabot PRの確認（GitHub CLI使用）
gh pr list --label "dependencies" --state open 2>/dev/null || echo "GitHub CLI未設定"
```

### サイクルディレクトリ自動作成

setup-cycle.mdのステップ4〜6の処理をinception.mdにも記載（または共通化の検討）。
