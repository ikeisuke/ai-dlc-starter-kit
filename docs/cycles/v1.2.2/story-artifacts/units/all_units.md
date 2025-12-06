# Unit定義（v1.2.2）

## Unit一覧

| Unit | 名前 | 依存関係 | 対象ストーリー |
|------|------|----------|----------------|
| Unit 1 | 気づき記録フロー定義 | なし | US-1 |
| Unit 2 | ホームディレクトリ共通設定 | なし | US-2 |
| Unit 3 | ファイルコピー判定改善 | なし | US-3 |
| Unit 4 | Lite版案内追加 | なし | US-4 |
| Unit 5 | サイクル固有バックログ確認 | なし | US-5 |

---

## Unit 1: 気づき記録フロー定義

### 概要
Unit作業中に別Unitに関する気づきがあった場合の対応フローを定義する

### 対象ファイル
- `docs/aidlc/prompts/construction.md`（またはadditional-rules.md）

### 実装内容
- 気づきをサイクル固有バックログに記録する手順を追加
- 現在のUnit作業を中断せずに記録する方法を明記

---

## Unit 2: ホームディレクトリ共通設定

### 概要
`~/.aidlc/` にユーザー共通設定を配置できるようにする

### 対象ファイル
- `prompts/setup-prompt.md`
- `docs/aidlc/prompts/additional-rules.md`（読み込み優先順位の説明）

### 実装内容
- ホームディレクトリの設定ファイル読み込みロジックを追加
- 読み込み優先順位: ホーム設定 → プロジェクト設定

---

## Unit 3: ファイルコピー判定改善

### 概要
セットアップ時のファイルコピー判定にハッシュ値を使用する

### 対象ファイル
- `prompts/setup-prompt.md`

### 実装内容
- `shasum` または `sha1sum` でハッシュ値を比較するロジックを追加
- 一致していればスキップ、異なれば更新を提案

---

## Unit 4: Lite版案内追加

### 概要
サイクルセットアップ完了メッセージにLite版の案内を追加

### 対象ファイル
- `prompts/setup-cycle.md`

### 実装内容
- 完了メッセージにLite版プロンプトのパスを追記

---

## Unit 5: サイクル固有バックログ確認

### 概要
Inception Phaseでサイクル固有バックログも確認するようにする

### 対象ファイル
- `docs/aidlc/prompts/inception.md`
- `docs/aidlc/prompts/lite/inception.md`

### 実装内容
- バックログ確認ステップに `docs/cycles/{{CYCLE}}/backlog.md` の確認を追加
