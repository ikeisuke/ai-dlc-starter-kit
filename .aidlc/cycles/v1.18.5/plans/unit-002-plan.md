# Unit 002 計画: コンパクション後のセミオートモード引き継ぎ強化

## 概要

コンパクション後にsemi_autoモードが確実に維持されるよう、プロンプトファイル2つを修正する。

## 変更対象ファイル

1. `prompts/package/prompts/common/compaction.md`（正本）
2. `prompts/package/prompts/common/agents-rules.md`（正本）

## 実装計画

### 1. compaction.md の強化

現在のL17-24「セミオートモード時のコンパクション対応」を以下の観点で強化:

- **手順1の明確化**: `read-config.sh`の再取得手順を具体的なコマンドと期待出力で記載
- **終了コード2の処理追加**: 読取失敗時に`manual`にフォールバックしユーザーに通知する手順を追加
- **コンテキスト記録の明示化**: 再取得した`automation_mode`の値をコンテキストに明示的に記録する手順を追加
- **検証手順の追記**: コンパクション後の次の承認ポイントでsemi_auto/manual分岐の確認手順を追加

### 2. agents-rules.md の強化

L56-78「コンテキスト要約時の情報保持」の保持必須情報に`automation_mode`を追加:

- 保持必須リストに`automation_mode`を追加
- 保持形式の例に`- Automation Mode: semi_auto`（許容値: `semi_auto` | `manual`）を追加

## 完了条件チェックリスト

- [ ] `compaction.md`のsemi_auto時手順で`read-config.sh`再取得が明確化されている
- [ ] 終了コード2（読取失敗）時の`manual`フォールバックとユーザー通知手順が追加されている
- [ ] 再取得した`automation_mode`の値をコンテキストに記録する手順が追加されている
- [ ] `agents-rules.md`のコンテキスト保持必須情報に`automation_mode`が含まれている
- [ ] コンパクション後の次の承認ポイントでsemi_auto/manual分岐確認の検証手順が明記されている
