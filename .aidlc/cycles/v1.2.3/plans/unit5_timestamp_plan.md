# Unit 5: 日時記録必須ルール化 - 実装計画

## 概要
日時記録時に必ず現在時刻を取得するルールを「推奨」から「必須」に変更する。

## 修正対象ファイル（6ファイル）

| ファイル | 種別 |
|----------|------|
| `docs/aidlc/prompts/inception.md` | 成果物 |
| `docs/aidlc/prompts/construction.md` | 成果物 |
| `docs/aidlc/prompts/operations.md` | 成果物 |
| `prompts/package/prompts/inception.md` | パッケージ版 |
| `prompts/package/prompts/construction.md` | パッケージ版 |
| `prompts/package/prompts/operations.md` | パッケージ版 |

## 修正内容

### Before（現状）
```markdown
- **プロンプト履歴管理【重要】**: ... 日時取得の推奨方法:
  ```bash
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
  ...
```

### After（変更後）
```markdown
- **プロンプト履歴管理【重要】**: ... 追記方法は Bash heredoc (`cat <<EOF | tee -a docs/cycles/{{CYCLE}}/history.md`)。

  **日時取得の必須ルール**:
  - 日時を記録する際は**必ずその時点で** `date` コマンドを実行すること
  - セッション開始時に取得した日時を使い回さないこと
  - 複数の記録を行う場合、それぞれで `date` を実行すること

  ```bash
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
  ...
```

## 実装手順

1. **設計フェーズ**: スキップ（プロンプト修正のみのため、ドメインモデル・論理設計は不要）
2. **実装フェーズ**:
   - 6つのプロンプトファイルを順次修正
   - 各ファイルの「プロンプト履歴管理」セクションを変更
3. **検証**:
   - 修正箇所の確認（grep で変更後のテキストが含まれていることを確認）
4. **完了処理**:
   - 実装記録作成
   - progress.md 更新
   - Git コミット

## 受け入れ基準
- [ ] 「推奨方法」が「必須ルール」に変更されている
- [ ] 「その時点で`date`コマンドを実行すること」が強調されている
- [ ] 「セッション開始時の日時を使い回さない」禁止事項が追加されている

## 見積もり
小（プロンプト修正のみ）

## 作成日時
$(date '+%Y-%m-%d %H:%M:%S %Z')
