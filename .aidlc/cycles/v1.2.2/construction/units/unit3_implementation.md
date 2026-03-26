# Unit 3: ファイルコピー判定改善 - 実装記録

## 概要
セットアップ時のファイルコピーをrsyncで効率化

## 実装日
2025-12-06

## 変更内容

### 変更ファイル
| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup-init.md` | セクション7.2をrsync対応に書き換え |

### 主な変更点

1. **セクション7.2.1**: フェーズプロンプトのコピー → rsync同期に変更
2. **セクション7.2.2**: テンプレートのコピー → rsync同期に変更
3. **セクション7.2.3**: プロジェクト固有ファイルは従来通り条件付きコピー
4. **セクション7.2.4**: rsync出力例を追加
5. **セクション7.3**: 同期対象ファイル一覧に更新

### rsyncコマンド

```bash
# プロンプトの同期
rsync -av --checksum --delete \
  [スターターキットパス]/prompts/package/prompts/ \
  docs/aidlc/prompts/

# テンプレートの同期
rsync -av --checksum --delete \
  [スターターキットパス]/prompts/package/templates/ \
  docs/aidlc/templates/
```

## 状態
完了
