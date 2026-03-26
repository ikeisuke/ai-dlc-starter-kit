# 論理設計: write-history.shセキュリティ強化

## 概要

review-flow.md内のwrite-history.sh呼び出し例5箇所をヒアドキュメント方式に変換する。

## 変換対象と変換パターン

### 変換パターン（共通）

`--content "..."` → `--content "$(cat <<'CONTENT_EOF'...CONTENT_EOF)"` に変換する。

**注意事項**:
- ヒアドキュメントの開始タグは `<<'CONTENT_EOF'`（シングルクォート付き）を使用すること
- `CONTENT_EOF` の終了行はインデントなし（行頭に配置）。ただしreview-flow.md内のコード例ではMarkdownパーサーとの互換性のためインデント付きで記載し、注記で行頭配置の必要性を説明している
- 外側のダブルクォート `"$(cat <<'CONTENT_EOF'...CONTENT_EOF)"` は `cat` の出力を `--content` の引数として渡すために必要
- 区切り文字を`EOF`ではなく`CONTENT_EOF`にすることで、コンテンツ内に`EOF`が含まれる場合のヒアドキュメント終端衝突リスクを低減

### 変換箇所1: AIレビュー完了の履歴記録（L152-165）

**Before**:
```bash
        docs/aidlc/bin/write-history.sh \
            --cycle {{CYCLE}} \
            --phase {{PHASE}} \
            --unit {N} \
            --unit-name "[Unit名]" \
            --unit-slug "[unit-slug]" \
            --step "AIレビュー完了" \
            --content "【AIレビュー完了】指摘0件
        【対象タイミング】{呼び出し元のステップ名（例: 設計レビュー、統合とレビュー）}
        【対象成果物】{成果物名}
        【レビュー種別】{実行した全種別（例: code, security）}
        【レビューツール】{使用したツール名}"
```

**After**:
```bash
        docs/aidlc/bin/write-history.sh \
            --cycle {{CYCLE}} \
            --phase {{PHASE}} \
            --unit {N} \
            --unit-name "[Unit名]" \
            --unit-slug "[unit-slug]" \
            --step "AIレビュー完了" \
            --content "$(cat <<'CONTENT_EOF'
        【AIレビュー完了】指摘0件
        【対象タイミング】{呼び出し元のステップ名（例: 設計レビュー、統合とレビュー）}
        【対象成果物】{成果物名}
        【レビュー種別】{実行した全種別（例: code, security）}
        【レビューツール】{使用したツール名}
        CONTENT_EOF
        )"
```

### 変換箇所2: 千日手判断の履歴記録（L251-263）

同様の変換パターンを適用。

### 変換箇所3: 先送り判断の履歴記録（L336-347）

同様の変換パターンを適用。ユーザー入力の理由が直接含まれるため最もリスクが高い箇所。

### 変換箇所4: 指摘対応判断サマリの履歴記録（L354-367）

同様の変換パターンを適用。

### 変換箇所5: セルフレビュー完了の履歴記録（L478-492）

同様の変換パターンを適用。

## コンポーネント構成

変更はプロンプトファイル（Markdownドキュメント内のコード例）のみ。スクリプト本体への変更なし。

| コンポーネント | 変更 |
|-------------|------|
| `prompts/package/bin/write-history.sh` | 変更なし |
| `prompts/package/prompts/common/review-flow.md` | 5箇所のコード例を修正 |

## 不明点と質問

なし
