# Unit: AI レビュー完了条件を `last_round_clean` に緩和（hotfix）

## 概要

`skills/aidlc/steps/common/review-flow.md` の「完了条件の判定単一仕様」（v2.5.2 Unit 001 / #635 で導入）から `last_two_rounds_clean` 規則を削除し、`last_round_clean`（直近 round が clean なら完了）ベースに書き換える。これにより Round 1 で指摘 → Round 2 で全 resolve した場合に追加の Round 3 を強制せず 2R で完了できる。同時に `skills/aidlc/templates/review_summary_template.md` の反復回数表記補注を新ルールと整合させる。

5R 上限 / defer 自動 Issue 起票 / 千日手検出 / Round 4+ 新領域 backlog 化 などの v2.5.2 で導入された他要素は **完全に維持**する。

## 含まれるユーザーストーリー

- ストーリー 5: AI レビュー完了条件の `last_round_clean` 化（v2.5.4 内部 hotfix）

## 責務

- `skills/aidlc/steps/common/review-flow.md` の「完了条件の判定単一仕様」セクション本体を `last_round_clean` ベースに書き換え
  - `last_two_rounds_clean` の文字列を完全に削除
  - 規則表現は形式 A（`last_round_clean` 主規則）または形式 B（`1R clean 特例` を独立、`2R 以上 + last_round_clean` を別規則）から実装者が選択
  - 同一 round が二重判定されない一意な規則体系を担保
- `skills/aidlc/steps/common/review-flow.md` の他箇所で `last_two_rounds_clean` への参照が残っていれば併せて削除（`grep -c "last_two_rounds_clean"` が **0** になるまで）
- `skills/aidlc/steps/common/review-flow.md` のパス 2（セルフ）記述「反復上限・完了条件はパス 1 と同一」が新ルールと整合していることを確認
- `skills/aidlc/templates/review_summary_template.md` の反復回数表記補注（`v2.5.2 以降の上限値・完了条件`）を新ルールと整合させる更新
- 履歴記録 (`history/construction_unit05.md`) に Unit 005 の変更内容と「本サイクル後続 Unit（002 / 003 / 004）への新ルール即時適用」の証跡を残す

## 境界

- `5R 上限`・`defer 自動 Issue 起票フロー`・`千日手検出（5R 中 3R 連続同種）`・`Round 4+ 新領域 backlog 化` などの v2.5.2 導入要素の **削除・縮約は行わない**
- `is_clean()` 関数の定義変更は行わない（`findings` が空または全件 defer 化されているかで判定する既存定義を維持）
- 本 Unit は **完了条件の判定基準のみを緩和**するもので、レビュー実行手順（パス 1/2/3）・指摘対応判断フロー・スコープ保護確認・機密情報マスクなどには変更を加えない
- レビューサマリの「指摘一覧」テーブル形式・列ガイダンスは変更しない（反復回数表記の補注のみ更新）
- 設定ファイル（`config.toml`）への新規キー追加は行わない（`5R 化` と同様、ハードコード規則として運用）
- v2.5.4 サイクル内で **既に完了済み** の AI レビュー成果物（Unit 001 完了時のレビュー履歴等）への遡及書き換えは行わない

## 依存関係

### 依存する Unit

- なし（論理依存なし）

### 外部依存

- なし（docs のみ改訂）

### 後続 Unit への影響

- **Unit 002 / 003 / 004 のレビューに新ルールが即時適用される**ため、Unit 005 を **Unit 002 より前に実装する**（実装順序の制約）

## 非機能要件（NFR）

- **パフォーマンス**: docs / template 改訂のみのためランタイム影響なし。新ルール適用後は AI レビューの所要 round が 1〜2 round 削減される見込み
- **セキュリティ**: 機密情報の取り扱いに変更なし
- **後方互換**: `5R 上限`・`defer 自動 Issue 起票`・`千日手検出`・`Round 4+ 新領域 backlog 化` など v2.5.2 で導入された他要素を維持。`1R clean 特例` の挙動は新ルール（`last_round_clean`）の自然な帰結として包含される（または独立規則として明記）
- **可用性**: 影響なし

## 技術的考慮事項

- 規則表現の選択肢:
  - **形式 A**: `last_round_clean` を主規則とし、`1R clean 特例` を「`rounds.size == 1 && last_round_clean` の自然な帰結」として一行記述に縮約
  - **形式 B**: `1R clean 特例` を独立規則として残し、`rounds.size >= 2 && last_round_clean → completed` を別規則として明記（既存スタイル踏襲、変更を最小化）
- 形式 B の方が変更量が小さく、レビュー指摘リスクも低い（推奨）
- 反復回数表記補注の更新方針: 「v2.5.2 で 5R 化導入、v2.5.4 で完了条件を `last_round_clean` に緩和」と sequential history を 1 行で示す
- `is_clean()` の定義は維持。本 Unit はあくまで「複数 round に渡る完了判定規則」のみを緩和する

## 関連 Issue

- なし（v2.5.4 内部 hotfix、Issue 起票なし）
- 関連: v2.5.2 Unit 001 / #635（5R 化導入元）

## 実装優先度

**Hotfix / Highest**（本サイクル後続 Unit 002 / 003 / 004 のレビューに即時影響するため、Unit 002 より前に実装する）

## 見積もり

- 設計フェーズ: 0.25 日（既存規則の置き換え範囲確定 + 形式 A/B の選択 + grep 検証クエリ整備）
- 実装フェーズ: 0.25 日（review-flow.md 該当箇所書き換え + template 補注更新 + grep 検証 + lint）
- 合計: **0.5 日**

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
