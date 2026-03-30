# Unit 001 簡易設計: env-info.sh バグ修正

## 概要

`env-info.sh` の `starter_kit_version` と `current_branch` 取得ロジックを修正する。

## 変更対象

- `prompts/package/bin/env-info.sh`

## 関数設計

### get_starter_kit_version() の変更

**現行**:
- `version.txt` から読み取り

**変更後**:
- `docs/aidlc.toml` から `starter_kit_version` を読み取り

```text
入力: なし
出力: バージョン文字列 または 空文字

処理フロー:
1. docs/aidlc.toml が存在しない → 空文字を返す
2. dasel が利用可能
   → cat docs/aidlc.toml | dasel -i toml 'starter_kit_version' で取得
   → 両端の引用符（" または '）のみを除去して返す
3. dasel が利用不可（フォールバック）
   → grep で "^[[:space:]]*starter_kit_version[[:space:]]*=" を含む行を抽出
   → 最初の非コメント行のみ採用（# で始まる行は無視）
   → sed で = の後の値部分を抽出
   → インラインコメント（# 以降）は値に含めない
   → 両端の空白と引用符を除去

TOML書式の許容範囲:
- 行頭の空白: 許容（インデントされていても取得可能）
- インラインコメント: 許容（値の後の # 以降は無視）
  - 制約: 引用符内の # は考慮しない簡易実装（例: "a#b" は "a として扱われる）
- 引用符: ダブルクォート/シングルクォート両対応
- 複数定義: 最初の定義のみ採用
```

### get_current_branch() の変更

**現行**:
- `git branch --show-current` のみ

**変更後**:
- jj/git 環境を考慮した優先順位で取得

```text
入力: なし
出力: ブランチ名/bookmark名 または 空文字

処理フロー:
1. jj が利用可能な場合
   → jj log -r @ --no-graph -T 'bookmarks' で取得
   → tr -s '[:space:]' ' ' で複数スペース/タブ/改行を単一スペースに正規化
   → スペースで分割してリスト化
   → "cycle/" で始まるものを優先、なければ最初のものを選択
   → 空の場合は次のフォールバックへ
2. git branch --show-current で取得
   → 結果があれば返す
3. detached HEAD の場合
   → git rev-parse --abbrev-ref HEAD で取得
   → 結果が "HEAD" の場合は空文字として扱う
4. すべて失敗 → 空文字を返す

jj出力の正規化:
- 複数スペース/タブ/改行: 単一スペースに正規化
- 先頭/末尾の空白: トリム
```

## インターフェース

変更なし。出力形式は従来と同じ `key:value` 形式。

## エラー処理

- ファイル不存在、コマンド失敗時は空文字を返す
- エラー終了しない（exit code 0 を維持）
