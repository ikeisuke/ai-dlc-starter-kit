# Unit 002 計画: /aidlc help アクション追加

## 概要
`/aidlc help` (`/aidlc h`) で利用可能なアクション一覧を表示する機能を追加。

## 変更対象ファイル
- `skills/aidlc/SKILL.md` — ARGUMENTSパーシングに help/h を追加、引数ルーティングテーブルに追加、ヘルプ表示セクションを追加

## 実装計画
1. ARGUMENTSパーシングの短縮形展開に `h`→`help` を追加
2. 有効値リストに `help` を追加
3. 引数ルーティングテーブルに `help` (`h`) を追加
4. ヘルプ表示セクションを追加（アクション一覧テーブル形式）

## 完了条件チェックリスト
- [ ] `/aidlc help` で利用可能なアクション一覧が表示される
- [ ] `/aidlc h` が `help` の短縮形として動作する
- [ ] 各アクションの簡潔な説明と短縮形が表示される
- [ ] 既存アクション（inception/construction/operations/setup/express/feedback/migrate）の動作に影響がない
