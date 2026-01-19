# Unit 002 計画: write-history.sh統合

## 概要

各プロンプトファイル（inception.md、construction.md、operations.md）の履歴記録heredocを`write-history.sh`スクリプト呼び出しに置き換える。

## 変更対象ファイル

すべて `prompts/package/prompts/` 配下を編集（`docs/aidlc/` は直接編集禁止）

| ファイル | 変更箇所 | 内容 |
|----------|----------|------|
| inception.md | 行99-111 | 一般履歴記録のheredocを置換 |
| inception.md | 行894-906 | iOSバージョン更新履歴のheredocを置換 |
| construction.md | 行101-115 | 履歴記録のheredocを置換 |
| operations.md | 行101-114 | 履歴記録のheredocを置換 |

## 実装計画

### Phase 1: 設計

1. **write-history.sh呼び出しパターンの設計**
   - 各フェーズに対応する呼び出し例を定義
   - プレースホルダーの扱い（`{{CYCLE}}`, `{N}`, `[ステップ名]`等）を整理

2. **互換性確認**
   - 既存のheredocフォーマットとwrite-history.shの出力形式が一致することを確認

### Phase 2: 実装

1. **inception.md の修正**
   - 一般履歴記録セクション（行99-111）をwrite-history.sh呼び出しに置換
   - iOSバージョン更新セクション（行894-906）をwrite-history.sh呼び出しに置換

2. **construction.md の修正**
   - 履歴記録セクション（行101-115）をwrite-history.sh呼び出しに置換
   - Unit関連パラメータ（`--unit`, `--unit-name`, `--unit-slug`）を含める

3. **operations.md の修正**
   - 履歴記録セクション（行101-114）をwrite-history.sh呼び出しに置換

### Phase 3: 検証

1. **markdownlintの実行**
   - 各mdファイルがlintをパスすることを確認

2. **スクリプト動作確認**
   - dry-runモードでwrite-history.shが正しく動作することを確認

## write-history.sh呼び出しパターン

### inception.md用

```bash
docs/aidlc/bin/write-history.sh \
    --cycle {{CYCLE}} \
    --phase inception \
    --step "[ステップ名]" \
    --content "[作業概要]" \
    --artifacts "[作成・更新したファイル]"
```

### construction.md用

```bash
docs/aidlc/bin/write-history.sh \
    --cycle {{CYCLE}} \
    --phase construction \
    --unit {N} \
    --unit-name "[Unit名]" \
    --unit-slug "[unit-slug]" \
    --step "[ステップ名]" \
    --content "[作業概要]" \
    --artifacts "[作成・更新したファイル]"
```

### operations.md用

```bash
docs/aidlc/bin/write-history.sh \
    --cycle {{CYCLE}} \
    --phase operations \
    --step "[ステップ名]" \
    --content "[作業概要]" \
    --artifacts "[作成・更新したファイル]"
```

---

## 完了条件チェックリスト

- [ ] inception.mdのheredocをwrite-history.sh呼び出しに置換
- [ ] construction.mdのheredocをwrite-history.sh呼び出しに置換
- [ ] operations.mdのheredocをwrite-history.sh呼び出しに置換
- [ ] 従来のフォーマットとの互換性を維持
- [ ] 変更後の各mdファイルがmarkdownlintをパスすることを確認
