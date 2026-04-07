# Unit 004 計画: review-flow追加圧縮

## 対象Unit

Unit 004: review-flow追加圧縮（#519 S10残り）

## 目的

review-flow-reference.mdの冗長な記述を圧縮し、review-flow関連ファイルの合計サイズを20%以上削減する。

## 現状サイズ

| ファイル | バイト数 |
|---------|---------|
| review-flow.md | 10,769 |
| review-flow-reference.md | 7,438 |
| 合計 | 18,207 |

## 目標

合計 ≤ 14,565B（20%削減）

## 圧縮方針

### review-flow-reference.md（主な圧縮対象）

1. **制約種別ごとの正規化統合**: ツール別セクション（Codex/Claude/Gemini）を廃止し、制約種別ごとに全ツール横断の1テーブルに正規化する
   - `sandbox_restriction`: Codex(2件)+Gemini(1件)を1テーブルに集約（Claude該当なしのため行なし）
   - `auth_lifecycle`: 3ツールの検知/再認証コマンドを1テーブルに集約
   - `interactive_mode`: Codex固有のため独立保持（ただしヘッダ階層を簡略化）
   - `output_format`: Claude固有のため独立保持
2. **空セクション削除**: Claude sandbox_restrictionは「該当なし」のみ。削除
3. **責務境界の短文化**: 「事前予防」と「事後フォールバック」の責務境界説明を維持しつつ、ASCII図を短文に圧縮
4. **セキュリティ注意事項の簡潔化**: 4項目の意味を保持したまま記述を短縮
5. **共通セクション圧縮**: 「共通（全ツール）」セクションのフォールバック手順・フリーズ対策を簡潔化

### review-flow.md（参照リンク調整のみ）

- review-flow-reference.mdの構造変更に伴う「分割ファイル参照」セクションの調整（必要に応じて）

## 品質劣化リスクマトリクス対応

### review-flow.md（変更しない）

- 指摘対応判断フロー
- AIレビュー指摘の却下禁止ルール
- 処理パス分岐ロジック

### review-flow-reference.md（意味を保全する）

- セキュリティ注意事項4項目（機密情報除外の事前適用、エラーメッセージの機密マスキング、認証情報の平文禁止、公式配布元からの導入）は意味を落とさず残す
- 事前予防と事後フォールバックの責務境界説明を維持する
- review-flow.mdのエラー分類表への参照を残す

## 完了条件チェックリスト

- [ ] 制約種別ごとに全ツール横断の1テーブルに正規化されている
- [ ] セキュリティ注意事項4項目が意味を保持して残っている
- [ ] 事前予防と事後フォールバックの責務境界が明示されている
- [ ] review-flow.mdのエラー分類表への参照が残っている
- [ ] review-flow.mdの参照リンクが正しく調整されている（必要な場合）
- [ ] `wc -c skills/aidlc/steps/common/review-flow.md skills/aidlc/steps/common/review-flow-reference.md` で合計 ≤ 14,565B
- [ ] review-flow.mdの処理パス分岐ロジック・指摘対応判断フロー・却下禁止ルールが変更されていない

## 測定方法

```bash
wc -c skills/aidlc/steps/common/review-flow.md skills/aidlc/steps/common/review-flow-reference.md
```
