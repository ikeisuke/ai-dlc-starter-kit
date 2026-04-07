# Session Continuity

フェーズ再開時の進捗復元とコンパクション復帰の共通手順。

## フェーズ別の進捗源

| フェーズ | 復元元 |
|---------|--------|
| Inception | `inception/progress.md` |
| Construction | Unit定義ファイル（`story-artifacts/units/*.md`）の「実装状態」セクション |
| Operations | `operations/progress.md` |

## コンパクション復帰

コンパクション復帰と判定された場合は `steps/common/compaction.md` を読み込む。
