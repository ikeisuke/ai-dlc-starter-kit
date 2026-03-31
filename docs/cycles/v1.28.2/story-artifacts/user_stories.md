# ユーザーストーリー

## Epic: migrate-config.sh cleanup trap バグ修正

### ストーリー 1: dry-run 実行時の正常終了
**優先順位**: Must-have

As a AI-DLC Starter Kit を導入したプロジェクトの開発者
I want to `migrate-config.sh --dry-run` が正常終了する
So that AIDLC アップグレード時に `error:migrate-failed` が発生せず、スムーズにアップグレードできる

**受け入れ基準**:
- [ ] `migrate-config.sh --dry-run` の終了コードが `0` である（一時ファイル未生成経路）
- [ ] `migrate-config.sh` の通常実行（一時ファイル生成経路）で、一時ファイルが正しく削除される（回帰なし）
- [ ] 利用プロジェクト側の AIDLC アップグレード導線で `error:migrate-failed` が発生しない

**技術的考慮事項**:
- Bash の `set -u` (nounset) 下では空配列の展開 `"${arr[@]}"` が unbound variable エラーとなる
- 修正は `${_cleanup_files[@]+"${_cleanup_files[@]}"}` パターンまたは配列長チェックで対応可能
- `set -euo pipefail` の設定は維持する
