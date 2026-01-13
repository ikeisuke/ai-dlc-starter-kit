# Unit 001: ドキュメント整合性修正 - 論理設計

## 概要

このUnitはドキュメント修正のみであり、ドメインロジックを含まないため、ドメインモデル設計は省略。
論理設計として各Issueの修正内容を詳細に整理する。

## 修正内容

### Issue #55: setup.mdのステップ番号を連番に整理

**対象ファイル**: `prompts/package/prompts/setup.md`

**現在のステップ番号**:

| 現在 | 内容 |
|------|------|
| -1 | 依存コマンド確認 |
| 0 | デプロイ済みファイル確認 |
| 0.5 | スターターキット開発リポジトリ判定 |
| 0.7 | バックログモード確認 |
| 0.8 | backlogラベル確認・作成 |
| 1 | スターターキットバージョン確認 |
| 2 | サイクルバージョンの決定 |
| 3 | ブランチ確認 |
| 4 | サイクル存在確認 |
| 5 | サイクルディレクトリ作成 |
| 6 | 旧形式バックログ移行 |

**変更後のステップ番号**:

| 新番号 | 旧番号 | 内容 |
|--------|--------|------|
| 1 | -1 | 依存コマンド確認 |
| 2 | 0 | デプロイ済みファイル確認 |
| 3 | 0.5 | スターターキット開発リポジトリ判定 |
| 4 | 0.7 | バックログモード確認 |
| 5 | 0.8 | backlogラベル確認・作成 |
| 6 | 1 | スターターキットバージョン確認 |
| 7 | 2 | サイクルバージョンの決定 |
| 8 | 3 | ブランチ確認 |
| 9 | 4 | サイクル存在確認 |
| 10 | 5 | サイクルディレクトリ作成 |
| 11 | 6 | 旧形式バックログ移行 |

**参照箇所の変更**:

| 行番号 | 変更前 | 変更後 |
|--------|--------|--------|
| 106 | ステップ0.5（スターターキット開発リポジトリ判定）へ進む | ステップ3（スターターキット開発リポジトリ判定）へ進む |
| 107 | ステップ0.5へ進む | ステップ3へ進む |
| 132 | ステップ2（サイクルバージョンの決定）へ進む | ステップ7（サイクルバージョンの決定）へ進む |
| 137 | ステップ1（スターターキットバージョン確認）へ進む | ステップ6（スターターキットバージョン確認）へ進む |
| 239 | ステップ2（サイクルバージョンの決定）へ進む | ステップ7（サイクルバージョンの決定）へ進む |
| 240 | ステップ2（サイクルバージョンの決定）へ進む | ステップ7（サイクルバージョンの決定）へ進む |
| 255 | ステップ2（サイクルバージョンの決定）へ進む | ステップ7（サイクルバージョンの決定）へ進む |
| 256 | ステップ2（サイクルバージョンの決定）へ進む | ステップ7（サイクルバージョンの決定）へ進む |
| 525 | ステップ5（サイクルディレクトリ作成）へ進む | ステップ10（サイクルディレクトリ作成）へ進む |

---

### Issue #55 追加: inception.mdの完了時作業のステップ番号整理

**対象ファイル**: `prompts/package/prompts/inception.md`

**現在の完了時作業ステップ番号**:

| 現在 | 内容 |
|------|------|
| 0 | サイクルラベル作成・Issue紐付け |
| 0.5 | iOSバージョン更新 |
| 1 | 履歴記録 |
| 2 | ドラフトPR作成 |
| 3 | Gitコミット |

**変更後のステップ番号**:

| 新番号 | 旧番号 | 内容 |
|--------|--------|------|
| 1 | 0 | サイクルラベル作成・Issue紐付け |
| 2 | 0.5 | iOSバージョン更新 |
| 3 | 1 | 履歴記録 |
| 4 | 2 | ドラフトPR作成 |
| 5 | 3 | Gitコミット |

---

### Issue #54: post_release_operations.mdにGitHub Issueテンプレートの記載漏れ

**対象ファイル**: `docs/cycles/v1.7.2/operations/post_release_operations.md`

**変更内容**:
「v1.7.2の主要な変更」セクションに以下を追加:

```markdown
### GitHub Issueテンプレート

- backlog.yml, bug.yml, feature.ymlテンプレート追加
```

---

### Issue #53: deployment_checklist.mdのlint対象がCIと不整合

**対象ファイル**: `prompts/package/prompts/operations.md`

**現在の記載（Line 800-803）**:

```markdown
#### 6.3 Markdownlint実行【CI対応】
コミット前にMarkdownlintを実行し、エラーがあれば修正する。

\`\`\`bash
# markdownlint-cli2がインストールされている場合
npx markdownlint-cli2 "docs/**/*.md" "prompts/**/*.md" "*.md"
\`\`\`
```

**変更内容**:
CIの対象（`docs/translations/**/*.md`）に合わせるか、または「現在サイクルのファイルのみ」を対象にする。

**推奨対応**:
変更ファイルまたは現在サイクルのみを対象にする方式に変更:

```markdown
#### 6.3 Markdownlint実行【CI対応】
コミット前にMarkdownlintを実行し、エラーがあれば修正する。

\`\`\`bash
# 現在サイクルと変更ファイルのみを対象（過去サイクルは除外）
npx markdownlint-cli2 "docs/cycles/{{CYCLE}}/**/*.md" "prompts/**/*.md" "*.md"
\`\`\`
```

---

### Issue #52: cicd_setup.mdのYAML抜粋が実ファイルと不一致

**対象ファイル**: `docs/cycles/v1.7.2/operations/cicd_setup.md`

**現在の記載（Line 30-31）**:

```markdown
\`\`\`yaml
name: PR Check
on:
  pull_request:
    branches: [main]
    paths: ['**.md', ...]
\`\`\`
```

**変更内容**:
「抜粋」であることを明示するコメントを追加:

```markdown
\`\`\`yaml
# 抜粋（詳細は .github/workflows/pr-check.yml を参照）
name: PR Check
on:
  pull_request:
    branches: [main]
    paths: ['**.md', ...]
\`\`\`
```

---

### Issue #51: aidlc.tomlのコメント内バージョン番号が古い

**対象ファイル**: `prompts/setup-prompt.md`

**変更内容**:
aidlc.toml生成部分から以下のコメント行を削除:

```toml
# スターターキットバージョン: 1.2.3
```

理由: `starter_kit_version` フィールドで管理しているため冗長。

**注意**: 実際の `docs/aidlc.toml` は直接編集不可（rsyncコピー）。
setup-prompt.md内のテンプレート生成部分を修正する必要がある。

---

### Issue #50: ドラフトPR表記の簡素化

**対象ファイル1**: `prompts/package/prompts/inception.md`

**現在の記載（Line 819-831）**:

```markdown
gh pr create --draft \
  --title "[Draft] サイクル {{CYCLE}}" \
  --body "$(cat <<'EOF'
## サイクル概要
[Intentから抽出した1-2文の概要]

## 含まれるUnit
[Unit定義ファイルから一覧を生成]

---
このPRはドラフト状態です。Operations Phase完了時にReady for Reviewに変更されます。
EOF
)"
```

**変更後**:

```markdown
gh pr create --draft \
  --title "サイクル {{CYCLE}}" \
  --body "$(cat <<'EOF'
## サイクル概要
[Intentから抽出した1-2文の概要]

## 含まれるUnit
[Unit定義ファイルから一覧を生成]
EOF
)"
```

**対象ファイル2**: `prompts/package/prompts/operations.md`

**現在の記載（Line 854-856）**:

```markdown
# PRタイトルから[Draft]を削除
gh pr edit {PR番号} --title "{{CYCLE}}"
```

**変更後**: 削除（[Draft]プレフィックスがなくなるため不要）

---

## 修正対象ファイル一覧

| Issue | ファイル | 種類 |
|-------|---------|------|
| #55 | `prompts/package/prompts/setup.md` | プロンプト |
| #55 | `prompts/package/prompts/inception.md` | プロンプト |
| #54 | `docs/cycles/v1.7.2/operations/post_release_operations.md` | 過去サイクル成果物 |
| #53 | `prompts/package/prompts/operations.md` | プロンプト |
| #52 | `docs/cycles/v1.7.2/operations/cicd_setup.md` | 過去サイクル成果物 |
| #51 | `prompts/setup-prompt.md` | プロンプト |
| #50 | `prompts/package/prompts/inception.md` | プロンプト |
| #50 | `prompts/package/prompts/operations.md` | プロンプト |

## 検証方法

1. Markdownlint実行
2. 各ファイルの構文確認
3. 関連Issueの完了条件を満たしているか確認
