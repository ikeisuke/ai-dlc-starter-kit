# Unit: rsync同期スクリプト

## 概要
prompts/package配下の同期（prompts, templates, guides, bin）を一括で行うスクリプトを作成する。

## 含まれるユーザーストーリー
- ストーリー 1-7: rsync同期処理

## 関連Issue
- #34

## 責務
- prompts, templates, guides, bin を同期
- 同期先ディレクトリを引数で指定
- プロンプト内のrsyncをスクリプト呼び出しに置換

## 境界
- 同期元は prompts/package/ 固定

## 依存関係

### 依存する Unit
- なし（独立して実装可能）

### 外部依存
- rsync

## 非機能要件（NFR）
- **パフォーマンス**: 数秒以内
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: rsync インストール済み環境で動作

## 技術的考慮事項

### 使用方法
```bash
# デフォルト（docs/aidlc/に同期）
bin/sync-prompts.sh

# 同期先指定
bin/sync-prompts.sh --dest docs/aidlc/

# 特定ディレクトリのみ
bin/sync-prompts.sh --only prompts,guides
```

### 同期対象
| ソース | 宛先 |
|--------|------|
| prompts/package/prompts/ | docs/aidlc/prompts/ |
| prompts/package/templates/ | docs/aidlc/templates/ |
| prompts/package/guides/ | docs/aidlc/guides/ |
| prompts/package/bin/ | docs/aidlc/bin/ |

### 変更対象ファイル
- `prompts/package/bin/sync-prompts.sh`（新規）
- `prompts/package/prompts/setup.md`（呼び出し追加）

## 実装優先度
Medium

## 見積もり
20分

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
