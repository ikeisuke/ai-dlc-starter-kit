# Unit 002: プリフライトチェック項目の設定化 - 計画

## 概要
プリフライトチェックの項目（gh, review-tools等）のon/offを `aidlc.toml` の `[rules.preflight]` セクションで制御可能にする。

## 変更対象ファイル
1. `prompts/package/prompts/common/preflight.md` — チェック処理を設定値に基づく分岐に変更
2. `docs/aidlc.toml` — `[rules.preflight]` セクション追加

## 実装計画

### 1. aidlc.toml にデフォルト設定追加
`[rules.preflight]` セクションを追加:
- `enabled = true` （デフォルト）
- `checks = ["gh", "review-tools", "config-validation"]`

### 2. preflight.md の設定値取得に追加
手順4（設定値取得）に `rules.preflight.enabled` と `rules.preflight.checks` を追加。

### 3. preflight.md のチェック処理を設定駆動に変更
- `enabled=false` 時: blockerチェック（git, aidlc.toml）のみ実行し、オプションチェックをスキップ
- `enabled=true` 時: `checks` リストに含まれる項目のみ実行
- 未知の項目: 警告して無視
- 空配列: blockerチェックのみ実行

### 4. 結果提示に preflight 設定値を追加

## 完了条件チェックリスト
- [ ] `aidlc.toml` に `[rules.preflight]` セクション（`enabled`, `checks`）が追加されている
- [ ] `preflight.md` のチェック処理が設定値に基づく分岐に変更されている
- [ ] blockerチェック（git, aidlc.toml）は `enabled` 設定に関わらず常時実行される
- [ ] `enabled=false` 時はオプションチェックのみスキップされる
- [ ] `checks` が未設定の場合、全項目チェックが実行される（後方互換性）
- [ ] `checks` が空配列の場合、blockerチェックのみ実行される
- [ ] 未知のチェック項目は警告して無視される
