# 論理設計: CLIプロジェクトタイプ追加

## 概要

Operations Phaseのプロンプトとテンプレートを修正し、CLIプロジェクトタイプを追加する。

**重要**: このUnitはMarkdownドキュメントの修正のみであり、プログラムコードは含まない。

## 変更対象ファイル

```
prompts/package/
├── prompts/
│   └── operations.md          # ステップ4の説明を修正
└── templates/
    └── operations_progress_template.md  # プロジェクト種別に cli を追加
```

## 変更詳細

### 1. operations_progress_template.md

**変更箇所**: 「プロジェクト種別による差異」セクション（27-30行目付近）

**変更内容**:
- 「デスクトップ/CLI（desktop/cli）: 全ステップ実施」を追加
- モバイルアプリと同様に配布ステップを実施する分類として明記

### 2. operations.md

**変更箇所**: ステップ4のヘッダー（268行目付近）

**変更内容**:
- `PROJECT_TYPE=general` → `PROJECT_TYPE=web/backend/general` に変更
- スキップ対象を明確化し、cli/desktop が含まれないことを暗黙的に示す

## 処理フロー

### Operations Phase開始時のプロジェクトタイプ判定

1. progress.md を作成/読み込み
2. プロジェクトタイプを確認
3. 配布ステップの実行可否を判定:
   - `ios`, `android`, `desktop`, `cli` → 配布ステップ実施
   - `web`, `backend`, `general` → 配布ステップスキップ

## 非機能要件（NFR）への対応

### パフォーマンス
- 該当なし

### セキュリティ
- 該当なし

### スケーラビリティ
- 該当なし

### 可用性
- 該当なし

## 技術選定
- **言語**: Markdown
- **フレームワーク**: なし

## 実装上の注意事項
- `prompts/package/` を編集すること（`docs/aidlc/` は rsync コピーなので直接編集禁止）
- 既存のプロジェクトタイプ分類との整合性を保つ

## 不明点と質問

なし（要件は明確）
