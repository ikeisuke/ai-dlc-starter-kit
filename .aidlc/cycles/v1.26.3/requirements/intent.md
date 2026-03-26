# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.26.3

## 開発の目的
ツール基盤の設定デフォルト値の欠落修正と、開発支援スクリプト・設定ファイルの品質改善を行う。具体的には、`defaults.toml` に `rules.cycle.mode` と `rules.upgrade_check.enabled` のデフォルト値を追加して `read-config.sh` のキー不在エラーを解消し、`.claude/settings.json` の mktemp 許可ルールをワイルドカードに統合して保守性を向上させ、`post-merge-cleanup.sh` のリモート解決ロジックの重複を共通関数に抽出してDRY原則に準拠させる。

## ターゲットユーザー
AI-DLCスターターキットの利用者および開発者

## ビジネス価値
- 設定デフォルト値の欠落によるInception Phase開始時のエラーを防止し、ユーザー体験を改善する
- 許可ルールの統合により `.claude/settings.json` の肥大化を抑制し、保守コストを削減する
- スクリプトのDRY改善により、将来のリモート解決ロジック変更時の修正箇所を一元化する

## スコープ

**含まれる変更**:
- `prompts/package/config/defaults.toml` に `rules.cycle.mode` と `rules.upgrade_check.enabled` のデフォルト値追加
- `.claude/settings.json` の mktemp 許可ルール統合（個別5件→ワイルドカード1件）
- `setup-ai-tools.sh` のテンプレート生成部分の同時更新（許可ルール統合に伴う）
- `bin/post-merge-cleanup.sh` のリモート解決ロジックの共通関数抽出

**含まれない変更**:
- `read-config.sh` 本体のロジック変更（デフォルト値追加のみで対応可能）
- `aidlc.toml` のコメントアウト行の変更（既存の設定例はそのまま維持）
- バックログ #384, #385, #381 の対応

## 成功基準
- `read-config.sh rules.cycle.mode` が exit code 0 で `"default"` を返すこと
- `read-config.sh rules.upgrade_check.enabled` がデフォルト値 `false` を返すこと（aidlc.toml で明示設定がない場合）
- mktemp 許可ルール統合後も、既存の5種の mktemp ユースケース（commit-msg, squash-msg, history-content, pr-body, review-input）が許可されること
- ワイルドカードパターンが `/tmp/aidlc-` プレフィックスに限定され、不要な権限拡大がないこと
- `post-merge-cleanup.sh` の共通関数化後、主要リモート構成（origin, 複数リモート）で従来と同じ解決結果になること

## 影響範囲

| 変更対象 | 維持すべき既存挙動 | 確認方法 |
|---------|-----------------|---------|
| defaults.toml | aidlc.toml の明示設定がデフォルト値より優先される | 明示設定ありの場合に read-config.sh がその値を返すことを確認 |
| .claude/settings.json | 既存5種の mktemp コマンドが許可される | ワイルドカードパターンが全ユースケースにマッチすることを確認 |
| setup-ai-tools.sh | テンプレート生成で統合後のルールが出力される | スクリプト実行結果の確認 |
| post-merge-cleanup.sh | step_0a と step_2 で同一のリモート解決結果を返す | 既存テスト通過 |

## 期限とマイルストーン
パッチリリース（v1.26.3）

## 制約事項
- `defaults.toml` の変更は `prompts/package/config/defaults.toml` を編集し、`docs/aidlc/config/defaults.toml` は rsync で反映する
- 許可ルールの統合は `setup-ai-tools.sh` のテンプレート生成部分も同時に更新が必要
- 後方互換性を維持すること（既存の明示設定がある場合はそちらが優先される）

## 不明点と質問（Inception Phase中に記録）

（なし）
