# 既存コード分析

## 分析対象

- prompts/package/prompts/setup.md
- prompts/package/prompts/construction.md
- prompts/package/prompts/operations.md
- .markdownlint.json
- AGENTS.md / CLAUDE.md（存在確認）

## 分析結果

### 1. AIレビュー必須設定が機能しない問題

**現状**:
- 各プロンプトに「AIレビュー優先ルール」セクションが存在
- `docs/aidlc.toml` の `[rules.mcp_review]` を参照する指示あり
- MCP利用可否チェックの具体的なコマンドが明示されていない

**問題点**:
- 「MCP利用可否チェック」の実装が曖昧
- mode確認のためのコマンドが記載されていない
- AIが設定を読み飛ばす可能性がある

**修正箇所**: prompts/package/prompts/*.md

### 2. macOS grep互換性問題

**現状**:
- setup.md 73行目: `grep -E ... | sed ...` 形式（POSIX互換）
- バックログには `grep -oP` が問題と記載

**分析結果**:
- setup.md のバージョン確認は既に修正済みの可能性あり
- 他のプロンプトファイルに `-oP` オプションが残っていないか要確認

**修正箇所**: prompts/package/prompts/setup.md（確認が必要）

### 3. Unitブランチ作成時にPRが作成されない

**現状**:
- construction.md にUnitブランチ作成の手順あり（ステップ6）
- Unit完了時にPR作成・マージの手順あり（Unit完了時の必須作業 - 4）
- しかし、ブランチ作成時にドラフトPRを作成する処理がない

**問題点**:
- Unitブランチ作成時（ステップ6）にPR作成の案内がない
- ユーザーが手動でPRを作成する必要がある

**修正箇所**: prompts/package/prompts/construction.md

### 4. markdownlintルールの段階的有効化

**現状** (.markdownlint.json):
```json
{
  "default": true,
  "MD003": false, "MD007": false, "MD009": false,
  "MD012": false, "MD013": false, "MD022": false,
  "MD024": false, "MD026": false, "MD029": false,
  "MD030": false, "MD031": false, "MD032": false,
  "MD033": false, "MD034": false, "MD036": false,
  "MD040": false, "MD041": false, "MD053": false,
  "MD058": false
}
```

**高優先度で有効化すべきルール**:
- MD009: 末尾スペース
- MD034: 裸URL
- MD040: コードブロック言語指定

**修正箇所**: .markdownlint.json、既存Markdownファイル

### 5. スターターキット自体のアップグレードフロー明確化

**現状**:
- setup.md ステップ1でアップグレード案内を表示
- スターターキット開発リポジトリかどうかの判定なし

**問題点**:
- ai-dlc-starter-kit リポジトリ自体では、アップグレード案内は不適切
- 「次サイクルで変更を加えてリリース」が正しいフロー

**修正箇所**: prompts/package/prompts/setup.md

### 6. AGENTS.md/CLAUDE.mdへのAI-DLC統合

**現状**:
- AGENTS.md: 存在しない
- CLAUDE.md: 存在しない

**対応**:
- 両ファイルを新規作成
- AIエージェントがAI-DLCを認識できるようにする

**修正箇所**: AGENTS.md（新規）、CLAUDE.md（新規）

### 7. 一問一答質問でAskUserQuestion使用

**現状**:
- 各プロンプトに「予想禁止・一問一答質問ルール」あり
- Claude Code固有のAskUserQuestion機能への言及なし

**対応案**:
- CLAUDE.md に「選択肢が明確な場合はAskUserQuestion機能を使用」と記載

**修正箇所**: CLAUDE.md（新規）

### 8. レビュー前後のタイミングでコミット

**現状**:
- コミットタイミング: セットアップ完了時、Inception完了時、Unit完了時、Operations完了時
- レビュー前後のコミットは含まれていない

**対応**:
- AIレビュー優先ルールの処理フローにコミット追加
- レビュー前: `chore: [{{CYCLE}}] レビュー前 - {成果物名}`
- レビュー後: `chore: [{{CYCLE}}] レビュー反映 - {成果物名}`

**修正箇所**: prompts/package/prompts/*.md

### 9. バックログ移行時の同名タイトル重複処理改善

**現状** (setup.md ステップ6):
- スキップ条件に「同名ファイルが既に存在する」場合を含む
- 重複時の警告表示なし

**対応**:
- 重複検出時に警告を表示する処理を追加

**修正箇所**: prompts/package/prompts/setup.md

## 影響範囲まとめ

| 対応項目 | 修正対象ファイル |
|---------|-----------------|
| AIレビュー必須設定 | prompts/package/prompts/*.md |
| macOS grep互換性 | prompts/package/prompts/setup.md |
| UnitブランチPR | prompts/package/prompts/construction.md |
| markdownlint | .markdownlint.json + 既存mdファイル |
| アップグレードフロー | prompts/package/prompts/setup.md |
| AGENTS.md統合 | AGENTS.md（新規）、CLAUDE.md（新規） |
| AskUserQuestion | CLAUDE.md（新規） |
| レビュー前後コミット | prompts/package/prompts/*.md |
| バックログ重複処理 | prompts/package/prompts/setup.md |
