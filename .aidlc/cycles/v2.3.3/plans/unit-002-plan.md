# Unit 002 計画: write-config.shレガシーエイリアス対応

## 概要
write-config.shにkey-aliases.shの正規化ロジックを導入し、レガシーキーと正規キーの重複書き込みを防止する。

## 修正対象
- `skills/aidlc/scripts/write-config.sh`

## 修正内容

### 1. key-aliases.shのsource追加
bootstrap.shの後に `lib/key-aliases.sh` をsourceする。

### 2. 書き込み先決定関数 `resolve_write_target()` の追加
エイリアス解決・存在判定・書き込み先決定を単一関数に集約する。

```text
resolve_write_target(input_key, file) → target_section, target_leaf, action
```

処理フロー:
1. `aidlc_normalize_key()` で入力キーを正規キーに正規化
2. `aidlc_get_legacy_key()` で対応するレガシーキーを取得
3. `section + leaf` の完全キー単位で存在判定（セクション内のleafを確認）
4. 書き込み先を決定:
   - 正規キーが存在 → 正規キーを更新（action=update）
   - 正規キー不在 + レガシーキーが存在 → レガシーキーを更新（action=update_legacy）
   - 両方不在 → 正規キーで新規追加（action=create）

**存在判定の粒度**: 現行の `grep "^${LEAF_KEY}"` はセクション未考慮で誤検出リスクがある。セクションヘッダー以降〜次セクションまでの範囲内でleafを検索する方式に改善する。

### 3. メインフロー修正
`resolve_write_target()` の戻り値に基づき、既存の `update_existing_key()` / セクション追加 / ファイル末尾追加の3パスを実行。dry-runも同関数を利用。

### 4. dry-runの出力改善
正規化されたキーとレガシーキーの情報をdry-run出力に反映。

## 完了条件チェックリスト
- [ ] write-config.shがkey-aliases.shをsourceしている
- [ ] レガシーキーで書き込み要求 → 正規化される
- [ ] 正規キーが既存の場合 → 正規キーを更新
- [ ] 正規キー不在 + レガシーキー既存の場合 → レガシーキーを更新（重複防止）
- [ ] 両方不在の場合 → 正規キーで新規追加
- [ ] 既存の書き込み機能（エイリアス無関係のキー）が不変
- [ ] 存在判定がsection+leaf完全キー単位で行われる（別セクション同名leafの誤検出なし）
- [ ] dry-run出力にキー正規化情報が含まれる
