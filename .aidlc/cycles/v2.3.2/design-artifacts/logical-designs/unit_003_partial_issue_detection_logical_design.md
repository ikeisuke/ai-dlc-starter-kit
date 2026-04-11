# 論理設計: 部分対応Issue自動判別

## 概要

`pr-ops.sh get-related-issues` の出力を Closes/Relates 区別形式に変更し、関連テンプレート・ステップファイルを対応���

## 変更対象詳細

### 1. `pr-ops.sh` の `cmd_get_related_issues` 修正

**抽出対象スコープ**: Unit定義ファイル内の「## 関連Issue」セクション範囲のみを対象とする（ファイル全体ではない）。セクション範囲は `## 関連Issue` ヘッダーから次の `##` ヘッダーまたはファイル末尾まで。

**修正後ロジック**（1件ずつ直接パース方式）:
```bash
# 1. 各Unit定義ファイルの「## 関連Issue」セクションを切り出し
# 2. セクション内の各行を直接パースして分類:
#    - `#NNN（部分対応）` → relates に追加
#    - `#NNN`（注記なし） → closes に追加
# 3. 出力（3行: 後方互換 issues + 新形式 closes/relates）

for file in "${units_dir}"/*.md; do
    section=$(sed -n '/^## 関連Issue/,/^## /{/^## 関連Issue/d;/^## /d;p}' "$file")
    while IFS= read -r line; do
        if [[ "$line" =~ \#([0-9]+)（部分対応） ]]; then
            relates_list+=("#${BASH_REMATCH[1]}")
        elif [[ "$line" =~ \#([0-9]+) ]]; then
            closes_list+=("#${BASH_REMATCH[1]}")
        fi
    done <<< "$section"
done

# 重複除去・ソート後に出力
echo "issues:${all_csv:-none}"       # 後方互換行（closes + relates を結合）
echo "closes:${closes_csv:-none}"
echo "relates:${relates_csv:-none}"
```

**出力形式（3行）**:

| 行 | 説明 | 後方互換 |
|----|------|---------|
| `issues:...` | 全Issue（closes + relates 結合） | 旧形式と同一 |
| `closes:...` | 完全対応Issueのみ | 新規 |
| `relates:...` | 部分対応Issueのみ | 新規 |

**後方互換**: 1行目 `issues:` は旧形式と完全互換。既存の呼び出し元は1行目のみパースすれば従来と同じ動作。新機能を使う呼び出し元は2-3行目をパースする。

### 2. `operations-release.sh` の対応

`pr-ready` サブコマンド内の `get-related-issues` 結果パース部を修正。`closes:` 行からCloses対象、`relates:` 行からRelates対象を取得してPR本文を構築。

### 3. `templates/unit_definition_template.md` 修正

```markdown
## 関連Issue
- #[Issue番号]（なければ「なし」と記載）
- 部分対応の場合は `#NNN（部分対応）` と記載（PRではClosesではなくRelatesとして扱われます）
```

### 4. `templates/pr_body_template.md` 修正

```markdown
## Closes
Closes #[完全対応Issue番号]

## Related Issues
Relates to #[部分対応Issue番号]（部分対応）
```

**PR本文生成ルール（closes/relates の組み合わせ別）**:

| closes | relates | PR本文 |
|--------|---------|--------|
| あり | あり | Closes + Related Issues 両セクション |
| あり | none | Closes のみ（Related Issues 省略） |
| none | あり | Related Issues のみ（Closes 省略） |
| none | none | 両セクション省略（「関連Issueなし」と注記） |

### 5. `operations-release.md` 7.8 の修正

PR本文生成時に `get-related-issues` の新出力を使い、上記ルールに従ってCloses/Relatesを区別してPR本文を構築する記述を追加。

## 実装上の注意事項

- 抽出対象は「## 関連Issue」セクション内のみ。ファイル全体から `#NNN` を拾わない
- grep ではなく sed + bash の行単位パースで1件ずつ分類（差集合ベースではない）
- `（部分対応）` は全角括弧を使用（日本語記法）
- `issues:` 行の後方互換出力を維持（呼び出し元の段階的移行を可能にする）
- 既存Unit定義ファイルには `（部分対応）` 注記がないため、全て `closes` に分類される

## 不明点と質問

なし
