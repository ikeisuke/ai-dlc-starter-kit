# フィードバック送信

「AIDLCフィードバック」「aidlc feedback」と言われた場合、以下の手順でフィードバック送信を案内する。

## 設定確認

最初に `.aidlc/config.toml` の設定を確認する：

```bash
cat .aidlc/config.toml | dasel -i toml 'rules.feedback.enabled'
```

**エラーハンドリング**:
- `.aidlc/config.toml` 不在: `true`（デフォルト有効）として続行。初回セットアップ前の正常ケース
- `dasel` 未インストール / TOML破損・キー不在: ユーザーに送信可否を対話確認（自動判定しない）

**`false` の場合**:

以下のメッセージを表示して終了する（ヒアリング・Issue作成・URL案内は行わない）。

```text
【フィードバック送信機能 無効】
この機能は無効化されています。
`.aidlc/config.toml` の `[rules.feedback].enabled` を `true` に設定することで有効化できます。
```

**`false` 以外の場合（デフォルト: `true`）**:

以下の手順に進む。

## 手順

1. **フィードバック内容のヒアリング**:
   - 改善提案、要望、バグ報告、感想などを自由に入力してもらう
   - 必要に応じて詳細を質問する

2. **Issue作成画面を開く**:
   - GitHub CLIが利用可能な場合、以下のコマンドでブラウザを開く
   - ユーザーが内容を確認・編集してから送信できる
   - **重要**: ユーザー入力はヒアドキュメントで安全に渡すこと

   1. Writeツールで一時ファイルを作成（内容: フィードバック本文）:

   ```text
   フィードバック内容をここに記載
   ```

   2. 以下を実行:

   ```bash
   gh issue create --web \
     --repo ikeisuke/ai-dlc-starter-kit \
     --template feedback.yml \
     --title "[Feedback] タイトル" \
     --body-file <一時ファイルパス>
   ```

   3. 一時ファイルを削除

3. **GitHub CLIが利用できない場合**:
   - 以下のURLを案内する
   - `https://github.com/ikeisuke/ai-dlc-starter-kit/issues/new?template=feedback.yml`

## 注意事項

- Issue作成は自動で行わず、必ずブラウザで確認画面を開く
- ユーザーが「Submit」ボタンを押すまでIssueは作成されない
