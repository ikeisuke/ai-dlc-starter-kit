# Unit: 履歴記録スクリプト

## 概要
履歴ファイルへの追記を標準化されたフォーマットで行うスクリプトを作成する。

## 含まれるユーザーストーリー
- ストーリー 1-6: 履歴記録

## 関連Issue
- #34

## 責務
- フェーズ、サイクル、ステップ名等を引数で指定
- 日時の自動取得
- 統一フォーマットでの履歴追記
- プロンプト内のヒアドキュメントをスクリプト呼び出しに置換

## 境界
- 履歴ファイルの新規作成は含まない（init-cycle-dirで対応）

## 依存関係

### 依存する Unit
- Unit 003（ディレクトリ初期化でhistory/作成済み前提）

### 外部依存
- bash
- date コマンド

## 非機能要件（NFR）
- **パフォーマンス**: 即時完了
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: オフライン環境でも動作

## 技術的考慮事項

### 使用方法
```bash
bin/write-history.sh \
  --cycle v1.8.0 \
  --phase inception \
  --step "Intent明確化" \
  --content "Intent文書を作成" \
  --artifacts "docs/cycles/v1.8.0/requirements/intent.md"
```

### 出力フォーマット
```markdown
## 2026-01-17 12:00:00 JST

- **フェーズ**: Inception Phase
- **ステップ**: Intent明確化
- **実行内容**: Intent文書を作成
- **成果物**: docs/cycles/v1.8.0/requirements/intent.md

---
```

### 変更対象ファイル
- `prompts/package/bin/write-history.sh`（新規）
- 各フェーズプロンプト（呼び出し追加）

## 実装優先度
Medium

## 見積もり
30分

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
