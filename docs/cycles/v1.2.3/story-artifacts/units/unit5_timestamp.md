# Unit 5: 日時記録必須ルール化

## 概要
日時記録時に必ず現在時刻を取得するルールを「推奨」から「必須」に変更する。

## 対象ストーリー
- US-5: 日時記録の正確性向上

## 依存関係
なし

## 修正対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `docs/aidlc/prompts/inception.md` | 日時取得ルールを必須化 |
| `docs/aidlc/prompts/construction.md` | 日時取得ルールを必須化 |
| `docs/aidlc/prompts/operations.md` | 日時取得ルールを必須化 |
| `prompts/package/prompts/inception.md` | 同上（パッケージ版） |
| `prompts/package/prompts/construction.md` | 同上（パッケージ版） |
| `prompts/package/prompts/operations.md` | 同上（パッケージ版） |

## 修正内容

### 「プロンプト履歴管理」セクションの修正

変更前:
```markdown
- **プロンプト履歴管理【重要】**: history.mdファイルは初回セットアップ時に作成され、以降は必ずファイル末尾に追記（既存履歴を絶対に削除・上書きしない）。追記方法は Bash heredoc (`cat <<EOF | tee -a docs/cycles/{{CYCLE}}/history.md`)。日時取得の推奨方法:
```

変更後:
```markdown
- **プロンプト履歴管理【重要】**: history.mdファイルは初回セットアップ時に作成され、以降は必ずファイル末尾に追記（既存履歴を絶対に削除・上書きしない）。追記方法は Bash heredoc (`cat <<EOF | tee -a docs/cycles/{{CYCLE}}/history.md`)。

  **日時取得の必須ルール**:
  - 日時を記録する際は**必ずその時点で** `date` コマンドを実行すること
  - セッション開始時に取得した日時を使い回さないこと
  - 複数の記録を行う場合、それぞれで `date` を実行すること

  ```bash
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
```

## 受け入れ基準
- [ ] 「推奨方法」が「必須ルール」に変更されている
- [ ] 「その時点で`date`コマンドを実行すること」が強調されている
- [ ] 「セッション開始時の日時を使い回さない」禁止事項が追加されている

## 見積もり
小（プロンプト修正のみ）
