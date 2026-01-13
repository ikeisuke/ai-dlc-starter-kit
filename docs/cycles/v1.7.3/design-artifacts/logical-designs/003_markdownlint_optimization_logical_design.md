# Unit 003: Markdownlint対象範囲の最適化 - 論理設計

## 概要

Construction PhaseでのMarkdownlint実行時に、過去サイクルのファイルを除外し、効率的なlint実行を実現する。

## 変更対象

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/construction.md` | Markdownlint対象範囲の修正 |

## 現状と変更内容

### 現状（問題）

`construction.md`のMarkdownlint実行:

```bash
npx markdownlint-cli2 "docs/**/*.md" "prompts/**/*.md" "*.md"
```

- `docs/**/*.md` は過去サイクル（`docs/cycles/v1.x.x/`等）も含む
- 過去の成果物を今更修正しても意味がない
- 不要なエラー検出で作業効率が低下

### 変更後

```bash
# 現在サイクルと変更ファイルのみを対象（過去サイクルは除外）
npx markdownlint-cli2 "docs/cycles/{{CYCLE}}/**/*.md" "prompts/**/*.md" "*.md"
```

- 現在サイクルのファイルのみを対象
- `operations.md`と同じ方式に統一
- 注意事項コメントを追加

## 変更箇所の詳細

### construction.md 該当箇所（行630-638付近）

**変更前**:

```markdown
### 3. Markdownlint実行【CI対応】
コミット前にMarkdownlintを実行し、エラーがあれば修正する。

\```bash
# markdownlint-cli2がインストールされている場合
npx markdownlint-cli2 "docs/**/*.md" "prompts/**/*.md" "*.md"
\```

**エラーがある場合**: 修正してから次のステップへ進む。
```

**変更後**:

```markdown
### 3. Markdownlint実行【CI対応】
コミット前にMarkdownlintを実行し、エラーがあれば修正する。

\```bash
# 現在サイクルと変更ファイルのみを対象（過去サイクルは除外）
npx markdownlint-cli2 "docs/cycles/{{CYCLE}}/**/*.md" "prompts/**/*.md" "*.md"
\```

**注意**: 過去サイクルのファイルはCIでもチェック対象外のため、現在サイクルのみを対象とします。

**エラーがある場合**: 修正してから次のステップへ進む。
```

## 整合性確認

| 項目 | construction.md（変更後） | operations.md（参考） |
|------|--------------------------|---------------------|
| 対象範囲 | `docs/cycles/{{CYCLE}}/**/*.md` | `docs/cycles/{{CYCLE}}/**/*.md` |
| コメント | 同一 | 同一 |
| 注意事項 | 追加 | 既存 |

## 影響範囲

- **直接影響**: Construction PhaseでのMarkdownlint実行
- **間接影響**: なし
- **後方互換性**: 問題なし（対象範囲の縮小のみ）

## 完了条件

- [ ] construction.mdのMarkdownlint対象が`docs/cycles/{{CYCLE}}/**/*.md`に変更されている
- [ ] 注意事項コメントが追加されている
- [ ] operations.mdと表記が統一されている
