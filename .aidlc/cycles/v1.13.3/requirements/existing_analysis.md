# 既存コード分析 - v1.13.3

## #175 progress.md更新タイミング

### Operations Phaseの実装（検証済みパターン）
- `prompts/package/prompts/operations.md` ステップ6.4.5
- progress.mdの「完了」を「PR準備完了」として解釈
- PR作成前にprogress.mdを更新し、コミットに含める

### Construction Phaseの現状
- `prompts/package/prompts/construction.md` のUnit完了時の必須作業セクション
- progress.mdの更新タイミングが明示的に定義されていない
- Unit PR作成後にマージされてからprogress.mdが更新される問題

### 変更対象
| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/construction.md` | Unit完了時の必須作業にprogress.md更新タイミングを追加（Operations Phaseの6.4.5パターン適用） |

## #174 フィードバック送信機能オン/オフ

### 現状
- `prompts/package/prompts/AGENTS.md` のフィードバック送信セクション
- フィードバック送信は常時有効（設定オプションなし）
- GitHub CLIの有無で動作分岐（ブラウザ or URL案内）

### 変更対象
| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/AGENTS.md` | フィードバック送信セクションに `[rules.feedback].enabled` の読み込みと動作分岐を追加 |
| `prompts/package/aidlc.toml` | `[rules.feedback]` セクション追加（`enabled = true`） |
