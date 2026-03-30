# Unit 005 計画: 既存プロンプトのテンポラリファイルパス統一

## 概要

既存プロンプト・スキル内の固定テンポラリファイルパスをUnit 004で策定した規約に統一する。

## 変更対象ファイル（5ファイル）

1. `prompts/package/prompts/CLAUDE.md` - `/tmp/commit-msg.txt` → `/tmp/aidlc-commit-msg.txt`
2. `prompts/package/prompts/common/rules.md` - `<tmpfile>`/`<一時ファイルパス>` → 具体的な規約パス＋規約セクション参照
3. `prompts/package/prompts/common/commit-flow.md` - `<一時ファイルパス>` → 用途別の規約パス
4. `prompts/package/prompts/common/review-flow.md` - `<一時ファイルパス>` → 用途別の規約パス
5. `prompts/package/skills/squash-unit/SKILL.md` - `/tmp/squash-msg.txt`/`<一時ファイルパス>` → `/tmp/aidlc-squash-msg.txt`

## 実装計画

### Phase 1: 設計

1. ドメインモデル・論理設計は不要（プレースホルダーの置換のみのため）

### Phase 2: 実装

2. **コード生成**: 5ファイルのテンポラリファイルパス参照を規約に統一
3. **テスト**: 全ファイルの一時ファイルパス記述が規約準拠であることを検証
4. **統合とレビュー**: AIレビュー実施

### 置換ルール

| 変更前 | 変更後 | 対象ファイル |
|--------|--------|------------|
| `/tmp/commit-msg.txt` | `/tmp/aidlc-commit-msg.txt` | CLAUDE.md |
| `/tmp/squash-msg.txt` | `/tmp/aidlc-squash-msg.txt` | squash-unit/SKILL.md |
| `<tmpfile>`（コミット用） | `/tmp/aidlc-commit-msg.txt` | rules.md |
| `<tmpfile>`（squash用） | `/tmp/aidlc-squash-msg.txt` | rules.md |
| `<tmpfile>`（履歴用） | `/tmp/aidlc-history-content.txt` | rules.md |
| `<tmpfile>`（PR用） | `/tmp/aidlc-pr-body.txt` | rules.md |
| `git commit -F <一時ファイルパス>` | `git commit -F /tmp/aidlc-commit-msg.txt` | commit-flow.md |
| `jj describe --stdin < <一時ファイルパス>` | `jj describe --stdin < /tmp/aidlc-commit-msg.txt` | commit-flow.md |
| `--message-file <一時ファイルパス>` | `--message-file /tmp/aidlc-squash-msg.txt` | commit-flow.md |
| `--content-file <一時ファイルパス>` | `--content-file /tmp/aidlc-history-content.txt` | review-flow.md |
| `--body-file <一時ファイルパス>` | `--body-file /tmp/aidlc-pr-body.txt` | review-flow.md |
| `--message-file <一時ファイルパス>` | `--message-file /tmp/aidlc-squash-msg.txt` | squash-unit/SKILL.md |
| `--content-file <一時ファイルパス>` | `--content-file /tmp/aidlc-history-content.txt` | rules.md（セミオート履歴記録セクション） |

### rules.md の追加変更

- `<tmpfile>` プレースホルダーの説明（$()使用禁止セクション内）を規約パスに更新する
- セミオート履歴記録セクションの `<一時ファイルパス>` を規約パスに更新する

### 後方互換性

- プロンプトの記述変更のみ。実行ロジック・出力フォーマットは変更なし
- AIエージェントの動作に影響なし（プレースホルダーが具体パスに変わるだけ）

## 完了条件チェックリスト

- [ ] CLAUDE.md: `/tmp/commit-msg.txt` → `/tmp/aidlc-commit-msg.txt`
- [ ] rules.md: `<tmpfile>`/`<一時ファイルパス>` → 規約パスに置換
- [ ] commit-flow.md: 全`<一時ファイルパス>` → 用途別の規約パス
- [ ] review-flow.md: 全`<一時ファイルパス>` → 用途別の規約パス
- [ ] squash-unit/SKILL.md: `/tmp/squash-msg.txt`/`<一時ファイルパス>` → `/tmp/aidlc-squash-msg.txt`
- [ ] 全5ファイルに旧パス（`/tmp/commit-msg.txt`, `/tmp/squash-msg.txt`, `<tmpfile>`, `<一時ファイルパス>`）が残っていないこと

### 検証手順

旧パスの残存チェック（0件であること）:

```bash
rg '<tmpfile>|<一時ファイルパス>|/tmp/commit-msg\.txt|/tmp/squash-msg\.txt' \
  prompts/package/prompts/CLAUDE.md \
  prompts/package/prompts/common/rules.md \
  prompts/package/prompts/common/commit-flow.md \
  prompts/package/prompts/common/review-flow.md \
  prompts/package/skills/squash-unit/SKILL.md
```

規約パスの正存在チェック:

```bash
rg 'aidlc-(commit-msg|squash-msg|history-content|pr-body)\.txt' \
  prompts/package/prompts/CLAUDE.md \
  prompts/package/prompts/common/rules.md \
  prompts/package/prompts/common/commit-flow.md \
  prompts/package/prompts/common/review-flow.md \
  prompts/package/skills/squash-unit/SKILL.md
```
