# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.24.2

## 開発の目的
rsyncコマンドの直接実行をスクリプト内に閉じ込め、AIエージェントの許可ルールからrsync個別許可を不要にする。現在、aidlc-setup.shの`_has_file_diff()`関数内でrsync dry-runを直接呼び出しているが、これをスクリプト実行として完結させることで、rsyncコマンドへの個別許可（`Bash(rsync *)`）というセキュリティリスクを排除する。

## 対象Issue
- #367 rsync実行をスクリプトに閉じ込め、直接実行の許可ルールを不要にする

## ターゲットユーザー
AI-DLCスターターキットを使用する開発者

## ビジネス価値
- rsyncコマンドへの個別許可が不要になり、セキュリティリスクを低減
- AIエージェントの許可設定がシンプルになる
- スクリプト単位の許可でrsync実行を制御できる

## 成功基準
- rsyncの直接実行がスクリプト外から呼び出されない
- ai-agent-allowlist.mdからrsync個別許可ルールが削除される
- 既存の同期機能（aidlc-setup、sync-package）が正常に動作する

## 期限とマイルストーン
パッチリリースとして即時対応

## 制約事項
- 既存のsync-package.shの動作を変更しない
- aidlc-setup.shのファイル差分チェック機能を維持する

## 不明点と質問（Inception Phase中に記録）

[Question] rsyncの直接実行をスクリプトに閉じ込める対象範囲は？
[Answer] aidlc-setup.sh内の_has_file_diff()でrsync dry-runを直接呼び出している箇所。個別許可はセキュリティリスクがあるためスクリプトを許可することで許可を代替したい。
