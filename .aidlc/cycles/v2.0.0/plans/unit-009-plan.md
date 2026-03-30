# Unit 009 実装計画: CLAUDE.md / AGENTS.md 刷新

## 概要

プラグインレベル（`skills/aidlc/`）の CLAUDE.md と AGENTS.md を作成し、旧 `docs/aidlc/prompts/` のファイルを統合する。

## 作業一覧

### 1. `skills/aidlc/CLAUDE.md` 作成

`docs/aidlc/prompts/CLAUDE.md` の内容をプラグインレベルに移行・統合:

- **質問時のルール**: AskUserQuestion 使用ルール、テキスト質問、深掘り
- **gitコミットメッセージルール**: `$()` 禁止、mktemp + `-F` パターン
- **TodoWriteツール活用**
- **フェーズ簡略指示**: `/aidlc` スキルへのマッピング（正本は SKILL.md）
- **Compact Instructions**: `steps/common/compaction.md` への参照

変更点:
- `common/rules.md` → `steps/common/rules.md`
- `prompts/package/prompts/AGENTS.md` → `SKILL.md`（正本参照先の更新）
- `docs/aidlc/prompts/common/compaction.md` → `steps/common/compaction.md`

### 2. `skills/aidlc/AGENTS.md` 作成

`docs/aidlc/prompts/AGENTS.md` の内容をプラグインレベルに移行・統合:

- **開発サイクル開始**: `/aidlc` スキル経由のフェーズ開始（旧ファイルパス指示を置換）
- **フェーズ簡略指示テーブル**: 既存テーブルを維持
- **サイクル判定ロジック**: ブランチ名ベースの判定
- **非AIDLCプロジェクトガード**: `.aidlc/config.toml` 未検出時の動作定義（新規追加）
- **共通ルール参照**: `steps/common/agents-rules.md`、`steps/common/feedback.md`（新規コピー必要）、`steps/common/ai-tools.md`（新規コピー必要）

### 3. ルート CLAUDE.md / AGENTS.md 更新

- `CLAUDE.md`: `@docs/aidlc/prompts/CLAUDE.md` → `@skills/aidlc/CLAUDE.md`
- `AGENTS.md`: `@docs/aidlc/prompts/AGENTS.md` → `@skills/aidlc/AGENTS.md`

### 4. `steps/common/compaction.md` パス参照更新

フェーズ再読み込みパステーブル内の旧パス参照を `/aidlc` コマンドに更新:
- `docs/aidlc/prompts/inception.md` → `/aidlc inception`
- `docs/aidlc/prompts/construction.md` → `/aidlc construction`
- `docs/aidlc/prompts/operations.md` → `/aidlc operations`

### 5. 共通ステップファイル追加（必要に応じて）

`docs/aidlc/prompts/common/` から `skills/aidlc/steps/common/` にまだコピーされていないファイル:
- `feedback.md` → AGENTS.md から参照
- `ai-tools.md` → AGENTS.md から参照

## 影響範囲

- `skills/aidlc/CLAUDE.md` (新規)
- `skills/aidlc/AGENTS.md` (新規)
- `CLAUDE.md` (更新)
- `AGENTS.md` (更新)
- `skills/aidlc/steps/common/compaction.md` (更新)
- `skills/aidlc/steps/common/feedback.md` (新規コピー)
- `skills/aidlc/steps/common/ai-tools.md` (新規コピー)
