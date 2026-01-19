# 論理設計: write-history.sh統合

## 概要

各プロンプトファイルの履歴記録heredocを`write-history.sh`スクリプト呼び出しに置き換える。

## 互換性分析

### 現在のheredocフォーマット

```markdown
## ${TIMESTAMP}

- **フェーズ**: [Phase] Phase
- **Unit**: [Unit名]  ← constructionのみ
- **ステップ**: [ステップ名]
- **実行内容**: [作業概要]
- **成果物**: [作成・更新したファイル]

---
```

### write-history.shの出力フォーマット

```markdown
## ${timestamp}

- **フェーズ**: [Phase] Phase
- **Unit**: [Unit表示]  ← constructionのみ
- **ステップ**: ${step}
- **実行内容**: ${content}
- **成果物**:
  - `${artifact1}`
  - `${artifact2}`

---
```

### 差分と互換性判定

| 項目 | 現在 | write-history.sh | 互換性 |
|------|------|------------------|--------|
| 見出し形式 | `## TIMESTAMP` | `## TIMESTAMP` | 完全互換 |
| フェーズ表示 | 同一 | 同一 | 完全互換 |
| Unit表示 | `[Unit名]` | `{N}-{slug}（{name}）` | 形式変更（情報量増加） |
| 成果物形式 | 1行テキスト | 箇条書きリスト | 形式変更（可読性向上） |
| 区切り線 | `---` | `---` | 完全互換 |

**結論**: 基本構造は互換。成果物形式の変更は可読性向上のため許容。

## 置換パターン設計

### inception.md

#### 一般履歴記録（行99-111）

**現在**:
```bash
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
cat <<EOF | tee -a docs/cycles/{{CYCLE}}/history/inception.md
## ${TIMESTAMP}

- **フェーズ**: Inception Phase
- **ステップ**: [ステップ名]
- **実行内容**: [作業概要]
- **成果物**: [作成・更新したファイル]

---
EOF
```

**置換後**:
```bash
docs/aidlc/bin/write-history.sh \
    --cycle {{CYCLE}} \
    --phase inception \
    --step "[ステップ名]" \
    --content "[作業概要]" \
    --artifacts "[作成・更新したファイル]"
```

#### iOSバージョン更新履歴（行894-906）

**現在**:
```bash
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
cat <<EOF >> docs/cycles/{{CYCLE}}/history/inception.md
## ${TIMESTAMP}

- **フェーズ**: Inception Phase
- **ステップ**: iOSバージョン更新実施
- **実行内容**: CFBundleShortVersionString を ${CYCLE_VERSION} に更新
- **成果物**: [更新したファイル]

---
EOF
```

**置換後**:
```bash
docs/aidlc/bin/write-history.sh \
    --cycle {{CYCLE}} \
    --phase inception \
    --step "iOSバージョン更新実施" \
    --content "CFBundleShortVersionString を ${CYCLE_VERSION} に更新" \
    --artifacts "[更新したファイル]"
```

#### 説明文（行914-915）

**現在**:
```markdown
`docs/cycles/{{CYCLE}}/history/inception.md` に履歴を追記（heredoc使用、日時は `date '+%Y-%m-%d %H:%M:%S'` で取得）
```

**置換後**:
```markdown
`docs/cycles/{{CYCLE}}/history/inception.md` に履歴を追記（write-history.sh使用）
```

### construction.md（行101-115）

**現在**:
```bash
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
cat <<EOF | tee -a docs/cycles/{{CYCLE}}/history/construction_unit{N}.md
## ${TIMESTAMP}

- **フェーズ**: Construction Phase
- **Unit**: [Unit名]
- **ステップ**: [ステップ名]
- **実行内容**: [作業概要]
- **成果物**: [作成・更新したファイル]

---
EOF
```

**置換後**:
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

### operations.md（行101-114）

**現在**:
```bash
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
cat <<EOF | tee -a docs/cycles/{{CYCLE}}/history/operations.md
## ${TIMESTAMP}

- **フェーズ**: Operations Phase
- **ステップ**: [ステップ名]
- **実行内容**: [作業概要]
- **成果物**: [作成・更新したファイル]

---
EOF
```

**置換後**:
```bash
docs/aidlc/bin/write-history.sh \
    --cycle {{CYCLE}} \
    --phase operations \
    --step "[ステップ名]" \
    --content "[作業概要]" \
    --artifacts "[作成・更新したファイル]"
```

## 注意事項

1. **プレースホルダーの維持**: `{{CYCLE}}`, `{N}`, `[ステップ名]`等のプレースホルダーはそのまま維持
2. **複数成果物**: `--artifacts`オプションは複数回指定可能
3. **出力確認**: スクリプトは`history:<path>:<status>`形式で結果を出力

## 変更しないもの

- write-history.sh自体
- setup.mdの履歴記録
- lite版プロンプト（対象外）
