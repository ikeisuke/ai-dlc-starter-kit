# Unit 003: Self-Healingリトライ回数の設定化 - 計画

## 概要
Self-Healingループの最大リトライ回数を `aidlc.toml` の `rules.construction.max_retry` で設定可能にする。

## 変更対象ファイル
1. `docs/aidlc.toml` — `[rules.construction]` セクション追加
2. `prompts/package/prompts/common/preflight.md` — 設定値取得に `max_retry` 追加
3. `prompts/package/prompts/construction.md` — ハードコード "3回" を設定値参照に変更

## 実装計画

### 1. aidlc.toml に設定追加
`[rules.construction]` セクションに `max_retry = 3` を追加。

### 2. preflight.md に設定値取得追加
`rules.construction.max_retry` を取得し、`max_retry` コンテキスト変数に格納。バリデーション: 0以上の整数のみ、不正値はデフォルト3。

### 3. construction.md のハードコード箇所を置換
- "最大3回" → "最大{max_retry}回"
- "attempt {N}/3" → "attempt {N}/{max_retry}"
- "3回到達" → "{max_retry}回到達"
- max_retry=0 時のスキップ分岐を追加

## 完了条件チェックリスト
- [ ] `aidlc.toml` に `[rules.construction]` セクションの `max_retry`（デフォルト: 3）が追加されている
- [ ] `construction.md` のSelf-Healingループが `max_retry` 設定値を参照する
- [ ] `max_retry` 未設定時は3回で動作する
- [ ] `max_retry=0` の場合、Self-Healingループをスキップしてフォールバックに進む
- [ ] 負の値・非数値は警告を表示しデフォルト値3にフォールバック
- [ ] プリフライトチェック時に `rules.construction.max_retry` がコンテキスト変数として取得される
