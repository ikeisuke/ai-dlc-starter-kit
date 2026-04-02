# Unit 004 計画: /aidlc version アクションの追加

## 概要

`/aidlc version`（短縮形: `v`）でスキルのバージョンを表示するアクションを SKILL.md に追加する。

## 変更対象ファイル

- `skills/aidlc/SKILL.md` — ARGUMENTSパーシング、引数ルーティング、ヘルプ表示、version表示ロジックの追加

## 実装計画

1. ARGUMENTSパーシングの短縮形展開に `v`→`version` を追加
2. 有効値リストに `version` を追加
3. 引数ルーティングテーブルに `version` 行を追加
4. ヘルプ表示テーブルに `version` 行を追加
5. version表示ロジックを追加（共通初期化フローは実行しない、`help` と同様の独立フロー）
6. エラーメッセージの有効アクション一覧に `version` を追加

### バージョン取得方法

スキルベースディレクトリの `version.txt` を直接読み取る。`env-info.sh` は環境診断全体を実行するため、バージョン表示のみの用途には重すぎる。

### 追加変更箇所

- `skills/aidlc/SKILL.md` の frontmatter `description` に `version` の使用例を追加

### 短縮形の競合確認

既存: `i`(inception), `c`(construction), `o`(operations), `e`(express), `h`(help)
追加: `v`(version) — 競合なし

## 完了条件チェックリスト

- [ ] SKILL.mdのARGUMENTSパーシングに `version`（短縮形: `v`）を追加
- [ ] 引数ルーティングテーブルに `version` を追加
- [ ] ヘルプ表示テーブルに `version` を追加
- [ ] version表示ロジックの実装（共通初期化フローは実行しない）
- [ ] `v` エイリアスが既存アクション短縮形と競合しないことを確認
