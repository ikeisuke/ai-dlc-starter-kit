# ステップ4: Unit定義 計画

## Unit分割方針

5ストーリーから7 Unitに分割。ストーリー2（Depth Levels）とストーリー5（jj削除）はスコープが広いため2 Unitに分割。

## Unit一覧

| Unit | 名前 | 対応ストーリー | 依存 | 優先度 |
|------|------|---------------|------|--------|
| 001 | overconfidence-prevention | S1: AIの過信防止原則 | なし | High |
| 002 | depth-levels-config | S2前半: 設定・共通ルール | なし | High |
| 003 | depth-levels-prompts | S2後半: フェーズプロンプト | Unit 002 | High |
| 004 | reverse-engineering | S3: 既存コード体系的解析 | なし | Medium |
| 005 | session-continuity | S4: セッション中断・再開 | なし | High |
| 006 | remove-jj-prompts | S5前半: jjプロンプト参照除去 | なし | High |
| 007 | remove-jj-scripts | S5後半: jjスクリプト処理除去 | Unit 006 | High |

## 依存関係グラフ

```
001 (独立)
002 → 003
004 (独立)
005 (独立)
006 → 007
```

## 実行順序の推奨

1. Unit 001, 002, 004, 005, 006 は並行実行可能
2. Unit 003 は Unit 002 完了後
3. Unit 007 は Unit 006 完了後

## 分割根拠

- **Unit 002/003**: Depth Levelsは設定定義（toml+rules.md）と各フェーズプロンプト反映の2段階。設定が確定しないとプロンプト修正方針が定まらない
- **Unit 006/007**: jj削除はプロンプトファイル（prompts/package/）とスクリプト（docs/aidlc/bin/）で編集対象が異なる。プロンプト側の方針がスクリプト側の警告実装に影響
