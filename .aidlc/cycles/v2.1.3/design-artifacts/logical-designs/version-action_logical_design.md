# 論理設計: /aidlc version アクションの追加

## 概要

SKILL.md に version アクションを追加するための変更箇所と表示ロジックを定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## SKILL.md 変更箇所

### 1. frontmatter description

`"aidlc version"` を Use when 例に追加。

### 2. ARGUMENTSパーシング（L37）

短縮形展開リストに `v`→`version` を追加。

### 3. 有効値リスト（L38-39）

有効値に `version` を追加。エラーメッセージの一覧にも追加。

### 4. 引数ルーティングテーブル（L44-55）

`| version (v) | バージョン表示 |` 行を追加。

### 5. version表示セクション（新規、ヘルプ表示セクションの後に配置）

`help` と同様に共通初期化フローは実行しない独立フロー。

### 6. ヘルプ表示テーブル（L133-148）

`| version | v | スキルバージョンを表示 |` 行を追加。

## version表示ロジック

```text
`version` アクション時に以下を表示して処理を終了する。共通初期化フローは実行しない。

1. スキルベースディレクトリの `version.txt` を読み込む
2. 以下のフォーマットで表示:

AI-DLC Starter Kit v{version}

3. `version.txt` が存在しない場合:

AI-DLC Starter Kit (version unknown)
```

## 処理フロー

1. ARGUMENTSパーシングで `version` / `v` を検出
2. 引数ルーティングで version 表示セクションにルーティング
3. `version.txt` を読み取り
4. フォーマットに従い表示して終了
