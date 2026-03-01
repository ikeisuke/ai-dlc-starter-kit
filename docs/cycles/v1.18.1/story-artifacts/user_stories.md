# ユーザーストーリー

## Epic: スクリプト基盤の品質改善・保守性向上

### ストーリー 1: operations.mdの分割リファクタリング (#257)
**優先順位**: Must-have

As a AI-DLCスターターキットの開発者
I want to operations.mdを責務単位で分割したい
So that 閾値（1000行）以下でメンテナンスしやすくなる

**受け入れ基準**:
- [ ] operations.mdが1000行以下であること
- [ ] ステップ6（リリース準備）が`operations-release.md`として独立していること
- [ ] 分割後の各ファイルが単独で読み取り可能で、必要な参照が明記されていること
- [ ] 分割後のoperations.mdから`operations-release.md`への参照（`【次のアクション】`形式）が正しく記載されていること
- [ ] ファイル間のリンク切れが0件であること（参照パスの整合性確認）
- [ ] `prompts/package/prompts/` 配下の正本が更新されていること

**技術的考慮事項**:
- 正本は `prompts/package/prompts/operations.md`。`docs/aidlc/prompts/` はrsyncコピーなので直接編集しない
- ステップ6は約400行でバージョン確認、CHANGELOG、PR操作、マージなど独立性が高い
- 分割後のファイル間の参照は相対パスで記載
- **ストーリー3の呼び出し箇所更新は分割後のファイル名（operations-release.md）を対象とする**

---

### ストーリー 2: write-history.shの安全性ドキュメント改善 (#254)
**優先順位**: Should-have

As a AI-DLCスターターキットの利用者
I want to write-history.shの--content引数の安全な使い方を知りたい
So that プロンプトからの呼び出し時にインジェクションリスクを回避できる

**受け入れ基準**:
- [ ] スクリプトの安全性確認結果が文書化されていること（確認観点: eval不使用、全変数が二重引用符でクォート、コマンド置換未使用、set -euo pipefail有効）
- [ ] 確認対象ファイル（`prompts/package/bin/write-history.sh`）と確認日が記載されていること
- [ ] プロンプト内のheredoc例で安全なパターン（`<<'EOF'`によるクォート）が一貫して使用されていること
- [ ] 終端トークン（CONTENT_EOF等）のインジェクション防止の注意書きがプロンプトに記載されていること
- [ ] 検証コマンド例が記載されていること（例: `echo '$(whoami) \`id\`' | xargs -I{} docs/aidlc/bin/write-history.sh --content "{}"` で意図しないコマンドが実行されないこと）

**技術的考慮事項**:
- 既存コード分析の結果、スクリプト自体はセキュア（変数クォート済み、eval不使用）
- 対応の中心はプロンプト側の記載改善（呼び出し例の安全パターン統一）
- review-flow.md等の既存プロンプトでheredoc例が多数存在

---

### ストーリー 3: バリデーションスクリプトの統合 (#248)
**優先順位**: Should-have
**依存**: ストーリー1完了後（呼び出し箇所の更新はストーリー1で分割されたファイルが対象）

As a AI-DLCスターターキットの開発者
I want to validate-uncommitted.shとvalidate-remote-sync.shを1つのスクリプトに統合したい
So that 保守対象を減らし、一括実行も可能になる

**受け入れ基準**:
- [ ] `validate-git.sh` に統合され、`uncommitted`、`remote-sync`、`all` サブコマンドが動作すること
- [ ] 各サブコマンドの出力形式が旧スクリプトと同一であること（後方互換性）
- [ ] 旧スクリプト名（`validate-uncommitted.sh`、`validate-remote-sync.sh`）が互換ラッパーとして残り、非推奨警告を出力すること
- [ ] `all` サブコマンドで両方のチェックが順次実行され、結果がまとめて出力されること
- [ ] 不正なサブコマンド指定時に、利用可能なサブコマンド一覧とともにエラーメッセージ（終了コード1）が出力されること
- [ ] Git管理外ディレクトリで実行した場合に、明確なエラーメッセージ（終了コード1）が出力されること
- [ ] `all` 実行時に片側が失敗しても、もう片方は実行され、終了コードは既存慣例に準拠すること（ok/warning=0、error=1。片側でもerrorがあれば終了コード1）
- [ ] `operations-release.md`（分割後）の呼び出し箇所が新スクリプトに更新されていること

**技術的考慮事項**:
- 正本は `prompts/package/bin/`。`docs/aidlc/bin/` はrsyncコピー
- 出力形式: `status:ok|warning|error` + 詳細情報
- 分割後のoperations-release.mdのステップ6.6.5、6.6.6から呼び出される

---

### ストーリー 4: worktreeクリーンアップスクリプト (#227)
**優先順位**: Should-have

As a worktree環境でAI-DLCを使用する開発者
I want to PRマージ後のクリーンアップを1コマンドで実行したい
So that 手動の5ステップ作業を自動化して作業効率が上がる

**受け入れ基準**:
- [ ] `post-merge-cleanup.sh --cycle vX.X.X` でクリーンアップが完了すること
- [ ] `--dry-run` オプションで実行予定の操作を事前確認できること（実際の変更は行わない）
- [ ] メインリポジトリパスが `git worktree list` から自動検出されること
- [ ] 以下の5ステップが自動実行されること: メインリポジトリでpull、worktreeでfetch、HEAD detach、ローカルブランチ削除、リモートブランチ削除
- [ ] 各ステップの成功/失敗が出力に含まれること
- [ ] 個別ステップ（ブランチ削除等）の失敗時もwarning扱いで後続ステップを継続し、最終結果をサマリ出力すること
- [ ] 致命的エラー（メインリポジトリ検出失敗、detach失敗）時は処理を中断し、エラーメッセージと手動復旧手順が表示されること
- [ ] 出力形式が既存スクリプト（setup-branch.sh等）と統一されていること（`status:`, `branch:`, `message:`）
- [ ] worktree環境でない場合に `status:error` と明確なエラーメッセージが出力されること
- [ ] `--cycle` 未指定時にusageが表示されること

**技術的考慮事項**:
- 正本は `prompts/package/bin/post-merge-cleanup.sh`（新規作成）
- 参考: `setup-branch.sh`（出力形式）、`pr-ops.sh`（エラーハンドリング）
- worktree内から `git -C <main-repo>` でメインリポジトリを操作
