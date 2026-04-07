# Unit 001 計画: session-state.md廃止

## 概要

session-state.mdの生成・復元ロジックを廃止し、progress.md / Unit定義ファイルベースの復元に一本化する。

## 対象ファイル（7ファイル）

| # | ファイル | 変更内容 |
|---|---------|---------|
| 1 | `steps/common/session-continuity.md` | session-state.md生成・復元セクション全体を除去。progress.mdベースの復元のみ残す |
| 2 | `steps/common/context-reset.md` | session-state.md生成指示・セミオート判定文・手順・節見出し・再開説明を除去。progress/history更新と継続プロンプト提示のみ残し、再開説明はprogress.md / Unit定義ベースに差し替え |
| 3 | `steps/common/compaction.md` | フェーズ判定・作業継続・コンパクション前保存の各session-state.md参照を除去し、成果物ベース復元に統一 |
| 4 | `steps/inception/01-setup.md` | session-state.md参照を除去。ステップ番号繰り上げ・参照先更新・文言整合の周辺修正を含む |
| 5 | `steps/construction/01-setup.md` | session-state.md参照を除去。ステップ番号繰り上げ・参照先更新・文言整合の周辺修正を含む |
| 6 | `steps/operations/01-setup.md` | session-state.md参照を除去。ステップ番号繰り上げ・参照先更新・文言整合の周辺修正を含む |
| 7 | `guides/troubleshooting.md` | session-state.md関連記述を除去 |

## 方針

- session-continuity.mdファイル自体は残す（内容を簡略化）
- progress.mdの復元ロジック自体の変更は行わない（既存フォールバックをそのまま使用）
- 復元ソース変更以外の意味的ロジックは変えないが、ステップ番号繰り上げ・参照先更新・文言整合のための周辺修正は行う

## 完了条件チェックリスト

- [ ] session-continuity.mdからsession-state.md生成・復元ロジックが除去されている
- [ ] context-reset.mdからsession-state.md関連の全参照（生成指示・セミオート判定・再開説明含む）が除去されている
- [ ] compaction.mdからsession-state.md参照（フェーズ判定・作業継続・コンパクション前保存）が全て除去されている
- [ ] inception/01-setup.mdからsession-state.md参照が除去され、ステップ番号・参照先が整合している
- [ ] construction/01-setup.mdからsession-state.md参照が除去され、ステップ番号・参照先が整合している
- [ ] operations/01-setup.mdからsession-state.md参照が除去され、ステップ番号・参照先が整合している
- [ ] guides/troubleshooting.mdからsession-state.md関連記述が除去されている
- [ ] 運用上のsession-state.md参照が残っていないこと（grep補助確認）
- [ ] 復元フローがprogress.md / Unit定義ベースで一貫していること

## 関連Issue

- #547
