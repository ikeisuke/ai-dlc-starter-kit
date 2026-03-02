# Intent（開発意図）

## プロジェクト名

AI-DLC スターターキット v1.18.2 - オートモード互換性向上と開発ワークフロー改善

## 開発の目的

AI-DLCスターターキットのセミオートモード（automation_mode=semi_auto）がClaude Codeの許可設定と干渉して円滑に動作しない問題を解消し、併せて開発ワークフローの効率化・セキュリティ強化を行う。

## ターゲットユーザー

AI-DLCスターターキットを利用する開発者（自身のプロジェクトも含む）

## ビジネス価値

- **オートモード実用化**: `$()`コマンド置換を排除し、セミオートモードが許可プロンプトなしで動作するようになる
- **ワークフロー効率化**: upgrading-aidlcスキルのスクリプト化・PR分離により、毎サイクルのアップグレード作業が自動化・簡素化される
- **セキュリティ強化**: AIレビュー時の機密情報マスキング手順により、外部AIへの情報漏洩リスクを低減
- **開発体験向上**: セッションタイトル表示やスクリプト配置の最適化により、日常の開発操作がスムーズになる

## 成功基準

- commit-flow.mdおよびwrite-history.sh呼び出しで`$()`コマンド置換が使われていないこと。write-history.shに`--content-file`オプションが追加され、`echo "test content" > /tmp/test.txt && docs/aidlc/bin/write-history.sh --content-file /tmp/test.txt ...` で正常動作すること
- `prompts/package/` 配下の全プロンプト（`.md`）および全スクリプト（`.sh`）から`$()`パターンをgrepし、Bash実行例として残存する箇所が0件であること。検出された場合はIssue化すること
- upgrading-aidlcスキルがスクリプトベースで実行可能で、`--dry-run`でアップグレード予定が確認できること。アップグレード用ブランチ作成・PR作成が自動化されていること。スキル内のBashコマンドに`$()`が含まれず、Claude Codeの許可プロンプトなしで実行完了すること
- review-flow.mdにレビュー前の機密情報スキャン・除外ステップが追加され、対象ファイル決定時に`.env`、認証情報、APIキーを含むファイルが除外されること
- セッション開始時にリポジトリ名・フェーズ・サイクルがウィンドウタイトルに表示されること（例: `ai-dlc-starter-kit / Inception / v1.18.2`）。プロンプト内の`env-info.sh`出力を利用して設定すること
- update-version.shが`prompts/package/bin/`から`bin/`（リポジトリルート直下）に移動し、`docs/aidlc/bin/`にrsyncされないこと。`docs/cycles/rules.md`の参照パスが更新されていること

## 期限とマイルストーン

パッチリリース（v1.18.2）

- **Inception Phase完了**: 2026-03-02
- **Construction Phase完了**: 2026-03-03
- **Operations Phase・リリース**: 2026-03-04

## 制約事項

- スターターキットのメタ開発構造を維持すること（`prompts/package/` を正本とする）
- 既存のAI-DLCワークフローへの影響を最小限にすること
- 後方互換性を保つこと（既存のCLI引数・戻り値・終了コードを維持）
- セミオートモードとの互換性を常に意識すること

## 影響分析

| 影響対象 | 影響内容 | 回帰確認項目 |
|---------|---------|------------|
| write-history.sh | --content-file オプション追加。既存の--content引数は維持 | 既存呼び出し箇所が--contentで動作すること |
| commit-flow.md | git commitの記述方式変更（heredoc → -F方式） | コミットメッセージが正しく記録されること |
| review-flow.md | 機密情報スキャンステップ追加、write-history.sh呼び出し方式変更 | AIレビューフロー全体が正常動作すること |
| upgrading-aidlcスキル | スクリプト化・ブランチ分離。既存のSKILL.mdフロー変更 | /upgrading-aidlc がエラーなく完了すること |
| update-version.sh | ファイルパス変更。docs/cycles/rules.mdの参照更新 | Operations Phaseのバージョン更新が動作すること |
| inception.md / construction.md / operations.md | write-history.sh呼び出し例の更新 | 各フェーズの履歴記録が正常動作すること |

## スコープ

### 含まれるもの

- $()パターン排除とwrite-history.sh --content-file追加（#258）
- upgrading-aidlcスキルのスクリプト化・PR分離・許可自動化（#256, #213, #212）
- AIレビューフロー機密情報マスキング手順追加（#255）
- セッションタイトル表示（#215）
- update-version.sh rsync対象外ディレクトリへ移動（#210）
- $()パターン調査: `prompts/package/` 配下の全`.md`・`.sh`ファイルを対象にgrep調査し、Bash実行例として残存する`$()`を検出。検出時はIssue化、未検出なら「0件」を記録して完了

### 明示的に除外するもの

- Amazon AIDLCリポジトリからのエッセンス取り込み（#218）
- GitHub Projects連携（#31）
- サイクルバージョン決定時のバックログ状況提示（#217）

## 不明点と質問（Inception Phase中に記録）

[Question] #211（マージ後のmain pullとworktree同期）はv1.18.1のUnit 004（post-merge-cleanup.sh）で対応済みか
[Answer] はい、対応済みとして扱う

[Question] オートモード改善のスコープ
[Answer] #258と同等。commit-flow.mdとwrite-history.shの$()パターン更新を中心に、その他は調査してIssue化

[Question] 新サイクルか既存サイクルへの追加か
[Answer] 新サイクル（v1.18.2）として開始
