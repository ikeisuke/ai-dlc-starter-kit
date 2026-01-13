# backlog.mode片方のみ確認オプション

- **発見日**: 2026-01-11
- **発見フェーズ**: Construction
- **発見サイクル**: v1.7.1
- **優先度**: 低

## 概要

backlog.mode設定に応じて、バックログ確認時にファイルまたはIssueの片方のみを確認するオプションを追加する。

## 詳細

現在のデフォルト動作では、mode設定に関わらず「ローカルファイルとIssue両方を確認」としている（安全策）。

しかし、ユーザーによっては片方のみを確認したい場合がある：
- mode=gitを選んだらファイルのみ確認
- mode=issueを選んだらIssueのみ確認

## 対応案

aidlc.tomlに以下の設定を追加:

```toml
[backlog]
mode = "issue"
# single_source: true | false
# - true: modeに応じて片方のみ確認
# - false: 両方確認（デフォルト、安全策）
single_source = false
```

各フェーズプロンプトでこの設定を参照し、確認範囲を決定する。
