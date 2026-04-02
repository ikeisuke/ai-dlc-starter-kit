# Claude Code固有の設定

## 質問時のルール

AI-DLCプロンプトで質問する際は、以下のルールに従ってください。

### AskUserQuestion機能の活用

選択肢が明確な場合はAskUserQuestion機能を使用してください：
- 技術的な選択肢がある場合（例: 「どのライブラリを使用しますか？」）
- Yes/No の判断が必要な場合（例: 「この設計で進めてよいですか？」）
- 複数の対応案から選択する場合
- バックログ登録時の優先度選択（Medium(デフォルト) / High / Low）

**選択肢の順序ルール**:
- 推奨オプションがある場合は、一番上（最初の選択肢）に配置する
- 推奨オプションには「(推奨)」または「(Recommended)」をラベル末尾に付加する

**必ず使用すべき場面**:
- Unit選択時（実行可能Unitが複数ある場合）
- 設計・計画の承認確認
- PRレビュー/マージの判断
- AIレビュー後の継続判断（修正して再レビュー or ユーザーレビューへ進む）
- Unitブランチ作成の確認

### テキストでの質問

自由回答が必要な場合はテキストで質問してください：
- 要件の詳細を聞く場合
- ユーザーの意図を確認する場合
- 具体的な値や名前を聞く場合

### 質問の深掘り

ユーザーの回答が曖昧な場合は、追加質問で深掘りしてください：
- 「具体的には？」「例えば？」で詳細を引き出す
- 前提条件や制約を確認する
- ユースケースやシナリオを聞いて理解を深める

## gitコミットメッセージのルール

コミットメッセージでは `$()` を使用しない。以下のルールに従う：

**単一行メッセージ**: `-m` で直接指定する。

```bash
git commit -m "feat: add new feature"
```

**複数行メッセージ**: テンポラリファイル規約（`steps/common/rules.md` 参照）に従い、`mktemp` で一時ファイルを生成して `-F` で読み込む。

```bash
# 1. mktemp /tmp/aidlc-commit-msg.XXXXXX でパスを生成
# 2. Writeツールで生成されたパスにメッセージを書き出す
# 3. git commit -F <生成されたパス>
# 4. 一時ファイルを削除
```

## TodoWriteツールの活用

タスク管理にはTodoWriteツールを積極的に使用してください。
複雑なタスクは細分化し、進捗を可視化することで、ユーザーとの協調作業を円滑にします。

## フェーズ簡略指示

以下の簡略指示でフェーズを開始できます。正本は `SKILL.md` の「引数ルーティング」セクションです。

| 指示 | 対応処理 |
|------|----------|
| 「インセプション進めて」「start inception」 | `/aidlc inception`（短縮形: `/aidlc inc` `/aidlc i`） |
| 「コンストラクション進めて」「start construction」 | `/aidlc construction`（短縮形: `/aidlc con` `/aidlc c`） |
| 「オペレーション進めて」「start operations」 | `/aidlc operations`（短縮形: `/aidlc ops` `/aidlc o`） |
| 「セットアップ」「start setup」 | `/aidlc setup` → `/aidlc-setup` に委譲 |
| 「start express」 | `/aidlc express`（短縮形: `/aidlc exp` `/aidlc e`、エクスプレスモード） |
| 「AIDLCフィードバック」「aidlc feedback」 | `/aidlc feedback` → `/aidlc-feedback` に委譲 |
| 「start migrate」「aidlc migrate」 | `/aidlc migrate` → `/aidlc-migrate` に委譲 |
| 「ヘルプ」「help」 | `/aidlc help`（短縮形: `/aidlc h`、アクション一覧表示） |
| 「バージョン」「version」 | `/aidlc version`（短縮形: `/aidlc v`、スキルバージョン表示） |

**追加コンテキスト**: `/aidlc <action> <テキスト>` の形式で、actionの後に任意のテキストを追加できます。追加テキストはフェーズ実行中にコンテキスト変数 `additional_context` として参照されます。ARGUMENTSパーシングの詳細仕様（有効action一覧、エラー条件、引数なし時の既定動作）は `SKILL.md` の「ARGUMENTSパーシング」セクションが正本です。

例: `/aidlc construction 前回のセッションで設計レビューまで完了`

**後方互換性**: 従来の詳細な指示（`docs/aidlc/prompts/xxx.md を読み込んで`）は `/aidlc` コマンドにリダイレクトされます。

## Compact Instructions

@`steps/common/compaction.md`
