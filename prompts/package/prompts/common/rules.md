# 共通開発ルール

以下のルールは全フェーズで共通して適用されます。

## 人間の承認プロセス【重要】

計画作成後、必ず以下を実行する:

1. 計画ファイルのパスをユーザーに提示
2. 「この計画で進めてよろしいですか？」と明示的に質問
3. ユーザーが「承認」「OK」「進めてください」などの肯定的な返答をするまで待機
4. **承認なしで次のステップを開始してはいけない**

## 質問と回答の記録【重要】

独自の判断をせず、不明点はドキュメントに `[Question]` タグで記録し `[Answer]` タグを配置、ユーザーに回答を求める。

## 予想禁止・一問一答質問ルール【重要】

不明点や判断に迷う点がある場合、予想や仮定で進めてはいけない。必ずユーザーに質問する。

**質問フロー（ハイブリッド方式）**:

1. まず質問の数と概要を提示する

   ```text
   質問が{N}点あります：
   1. {質問1の概要}
   2. {質問2の概要}
   ...

   まず1点目から確認させてください。
   ```

2. 1問ずつ詳細を質問し、回答を待つ
3. 回答を得てから次の質問に進む
4. 回答に基づく追加質問が発生した場合は「追加で確認させてください」と明示して質問する

**質問すべき場面**:

- 要件が曖昧な場合
- 複数の解釈が可能な場合
- 技術的な選択肢がある場合
- 前提条件が不明確な場合

## Gitコミットのタイミング【必須】

以下のタイミングで**必ず**Gitコミットを作成する:

1. セットアップ完了時
2. Inception Phase完了時
3. 各Unit完了時
4. Operations Phase完了時

コミットメッセージは変更内容を明確に記述

## Co-Authored-By の設定

コミットメッセージに追加する Co-Authored-By 情報は自動検出または手動設定で決定する。

### 自動検出の有効化/無効化

`docs/aidlc.toml` の `[rules.commit]` セクションで制御:

```toml
[rules.commit]
ai_author_auto_detect = true  # デフォルト: true（自動検出有効）
ai_author = ""                # 手動設定（自動検出無効時に使用）
```

- `ai_author_auto_detect = false`: 自動検出をスキップし、`ai_author`の値を使用
- `ai_author_auto_detect = true`（デフォルト）: 以下の検出フローを実行

### 検出フロー

以下の優先順位でAI著者情報を決定:

1. **設定確認**: `ai_author`が有効値で設定済み → その値を使用
2. **自己認識**: AIツールが自身を認識 → 対応するai_author値を使用
3. **環境変数**: AIツール固有の環境変数を検出 → 対応するai_author値を使用
4. **ユーザー確認**: 上記すべて失敗 → ユーザーに質問

**「未設定」の定義**: キー不存在、空文字(`""`)、空白のみ(`"   "`)

### AIツールマッピングテーブル

| AIツール | 自己認識キーワード | 環境変数 | ai_author値 |
|---------|-------------------|---------|-------------|
| Claude Code | Claude Code | `CLAUDE_CODE` | `Claude <noreply@anthropic.com>` |
| Cursor | Cursor | `CURSOR_EDITOR` | `Cursor <noreply@cursor.com>` |
| Cline | Cline | `CLINE_*` | `Cline <noreply@cline.bot>` |
| Windsurf | Windsurf | `WINDSURF_*` | `Windsurf <noreply@codeium.com>` |
| Codex CLI | Codex | `CODEX_*` | `Codex <noreply@openai.com>` |
| KiroCLI | Kiro | `KIRO_*` | `Kiro <noreply@aws.com>` |

### マイグレーション（既存設定の削除）

v1.9.1以前で`ai_author`が設定されている場合、初回コミット時に以下を確認:

```text
【マイグレーション確認】
aidlc.tomlに ai_author が設定されていますが、v1.9.2から自動検出機能が利用可能です。

現在の設定: ai_author = "{現在値}"

自動検出を有効にするため、この設定を削除しますか？
1. はい - 設定を削除して自動検出を使用（推奨）
2. いいえ - 現在の設定を維持
```

「はい」の場合: `ai_author`行をコメントアウトまたは削除

### コミットメッセージ形式

```text
{コミットメッセージ}

Co-Authored-By: {検出または設定されたai_author値}
```

## jjサポート設定

`docs/aidlc.toml`の`[rules.jj]`セクションを確認:

- `enabled = true`: jjを使用。gitコマンドを`docs/aidlc/guides/jj-support.md`の対照表で読み替えて実行
- `enabled = false`、未設定、または不正値: 以下のgitコマンドをそのまま使用

## コード品質基準

コード品質基準、Git運用の原則は `docs/cycles/rules.md` を参照
