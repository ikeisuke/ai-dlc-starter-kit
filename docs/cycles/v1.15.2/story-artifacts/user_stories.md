# ユーザーストーリー

## Epic: シェルスクリプト・ドキュメント品質改善

### ストーリー 1: シェルスクリプトのバグ修正・バリデーション強化
**優先順位**: Must-have

As a AI-DLCスターターキットの利用者
I want to シェルスクリプトのバグが修正され入力バリデーションが追加されている
So that スクリプト実行時に予期しないエラーや不正な動作が発生しない

**受け入れ基準**:
- [ ] `check-open-issues.sh` の `--limit` オプションに整数以外の値（例: "abc"）を渡した場合、エラーメッセージ（例: "Error: --limit must be a positive integer"）が表示され exit 1 する
- [ ] `check-open-issues.sh` の `--limit` オプションに正の整数を渡した場合、従来通り正常に Issue 一覧が出力される
- [ ] `check-open-issues.sh` で `gh issue list` が失敗した場合、失敗コマンドとエラー内容が含まれるエラーメッセージが出力される（例: "error:gh issue list failed: [エラー詳細]"）
- [ ] `suggest-version.sh` の case 文に `*)` default ケースが追加され、不正なバージョンタイプが渡された場合に stderr にエラーメッセージを出力して exit 1 する
- [ ] `suggest-version.sh` に正常な入力（patch/minor/major）を渡した場合、従来通り正しいバージョン番号が出力される

**技術的考慮事項**:
- 修正は `prompts/package/bin/` 配下で行う
- 既存のスクリプトインターフェース（引数、出力形式、終了コード）は変更しない

---

### ストーリー 2: ドキュメントの構文エラー修正
**優先順位**: Must-have

As a AI-DLCスターターキットの利用者
I want to ドキュメント内のコード例が正しい構文で記載されている
So that ドキュメントに従ってコマンドを実行した際に構文エラーが発生しない

**受け入れ基準**:
- [ ] `guides/ios-version-update.md` のパラメータ展開が `${CYCLE#v}` の正しい bash 構文になっている（`${{CYCLE}#v}` から修正）
- [ ] `guides/config-merge.md` の TOML 例で `[rules.reviewing]` テーブルが重複定義されておらず、1つのテーブルにキーがまとめられている

**技術的考慮事項**:
- 修正は `prompts/package/guides/` 配下で行う
- ドキュメント内のコード例が正しい構文であることを目視確認

---

### ストーリー 3: エラー処理の改善
**優先順位**: Should-have

As a AI-DLCスターターキットの利用者
I want to スクリプトのエラー処理が充実している
So that エラー発生時に原因を迅速に特定し対処できる

**受け入れ基準**:
- [ ] `issue-ops.sh` の `parse_gh_error` 関数が認証エラー（"authentication", "401", "403" 等のパターン）を検出し、"auth-error" を返す
- [ ] `issue-ops.sh` の `parse_gh_error` 関数に従来のエラーパターン（"not found" 等）を渡した場合、従来通り "not-found" を返す
- [ ] `cycle-label.sh` のリダイレクト `2>&1 1>/dev/null` の直前コメントが、「stderrをstdoutへリダイレクトし、stdoutは/dev/nullに破棄。結果としてstderrの内容のみ変数に格納される」という趣旨の説明に改善されている
- [ ] `setup-branch.sh` の相対パス→絶対パス変換で、`realpath` が利用可能な場合は `realpath` を使用し、利用不可の場合は既存の `cd + pwd` 方式にフォールバックする。相対パス `./foo` を渡した場合に絶対パスが返される
- [ ] `setup-branch.sh` の正常系パス解決（既存ディレクトリの指定）が従来通り正しく動作する

**技術的考慮事項**:
- `realpath` は macOS にデフォルトでは存在しない場合がある。フォールバックとして既存の `cd + pwd` 方式を残す
- エラー処理追加は成功系パスの既存動作に影響を与えないこと

---

### ストーリー 4: コード品質向上
**優先順位**: Could-have

As a AI-DLCスターターキットの開発者・保守者
I want to スクリプトのコード品質が向上している
So that コードの保守性と可読性が高まる

**受け入れ基準**:
- [ ] `aidlc-git-info.sh` の strict mode 設定前に `IFS=$'\n\t'` が初期化されている
- [ ] `aidlc-git-info.sh` が正常に動作する（既存の出力が変わらない）
- [ ] `env-info.sh` の `cat docs/aidlc.toml | dasel` パターンが `dasel -f docs/aidlc.toml` に変更されている（該当する全箇所）
- [ ] `env-info.sh --setup` の出力が従来と同じフォーマットで出力される

**技術的考慮事項**:
- `dasel -f` オプションが使用中の dasel バージョンでサポートされていることを確認
- IFS初期化は既存の動作に影響しないことを確認
