# PRFAQ: ai-dlc-starter-kit v1.28.2

## Press Release（プレスリリース）

**見出し**: AI-DLC Starter Kit v1.28.2 - マイグレーションスクリプトの安定性修正

**副見出し**: `migrate-config.sh --dry-run` の cleanup trap エラーを修正し、アップグレード体験を改善

**発表日**: 2026-03-31

**本文**:

AI-DLC Starter Kit v1.28.1 では、`migrate-config.sh --dry-run` の終了時に cleanup trap で unbound variable エラーが発生し、利用プロジェクト側の AIDLC アップグレードが `error:migrate-failed` で失敗する問題がありました。

v1.28.2 では、`_cleanup` 関数での空配列展開を `set -u` 安全にすることで、dry-run を含む全実行経路で正常終了するようになりました。

利用プロジェクトの開発者は、v1.28.2 にアップグレードすることでスムーズなアップグレード体験を取り戻すことができます。

## FAQ（よくある質問）

### Q1: この修正は既存の cleanup 動作に影響しますか？
A: いいえ。一時ファイルが存在する場合の削除動作は従来と同じです。空配列の場合のみ安全にスキップされます。

### Q2: Bash のバージョンに依存しますか？
A: 修正パターンは Bash 3.2 以降で動作します。Bash 4.4+ で改善された空配列展開に依存せず、明示的なガードを使用しています。
