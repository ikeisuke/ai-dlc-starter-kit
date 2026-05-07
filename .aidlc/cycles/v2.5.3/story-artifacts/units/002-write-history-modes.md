# Unit: write-history skill にモード追加（unit-complete-short-note + operations-round）

## 概要

`aidlc:write-history` skill / `skills/aidlc/scripts/write-history.sh` に 2 つの新モードを追加する。Unit 完了時の short note と Operations PR マージ前レビュー round エントリを構造的に記録できるようにし、v2.5.1 で発生した履歴漏れの再発を防ぐ。ストーリー 2A と 2B を同一スクリプト改修の効率化のため 1 Unit に統合する。

## 含まれるユーザーストーリー

- ストーリー 2A: write-history skill に Unit 完了 short note モードを追加（#637 / 分割①）
- ストーリー 2B: write-history skill に Operations round エントリモードを追加（#637 / 分割②）

## 責務

- `skills/aidlc/scripts/write-history.sh` に `--mode unit-complete-short-note` オプションを追加
  - 引数: `--cycle X --unit N --short-note "<3-5 行>"`
  - 動作: `history/construction_unitNN.md` 末尾に固定テンプレ「## 補足（short note）」セクション + 自由記述行を追記
- `skills/aidlc/scripts/write-history.sh` に `--mode operations-round` オプションを追加
  - 引数: `--cycle X --round R --findings F --critical C --high H --medium M --low L --resolved-count X --deferred-count Y`
  - 動作: `history/operations.md` に round R エントリ（指摘件数 / 重要度内訳 / 対応判定の集計テーブル）を追記
- `skills/write-history/SKILL.md` 引数表に新モード説明を追記（500 行制限内）
- 既存呼び出し（`--mode` 未指定）の完全互換維持
- post-merge ガード（`--operations-stage post-merge` / 自動判定）が新モードでも有効（exit 3 維持）
- self-apply: 本 Unit 自身の short note を新モードで書く

## 境界

- 既存の `--mode` 未指定パスの内部リファクタは行わない（互換性最優先）
- round 番号 R の値域チェック厳格化（例: R > 5 で reject 等）は本 Unit のスコープ外（Construction で必要なら拡張可だが Intent では未指示）
- history ファイル全体のテンプレ刷新は本 Unit のスコープ外
- Inception / Construction Phase の他フェーズ用モード追加は本 Unit のスコープ外
- 推定値検出ガードに関連する `--mode` 自体（例: `--mode review-summary`）は本 Unit のスコープ外

## 依存関係

### 依存する Unit

- なし（論理依存なし、独立した skill 改修）

### 外部依存

- bash 4+ / `getopts` または手動引数パース（既存 write-history.sh が利用）
- なし（新規外部ライブラリ追加なし）

## 非機能要件（NFR）

- **パフォーマンス**: 新モードの追加は O(1) のテンプレ展開 + ファイル append のみで既存性能に影響なし
- **セキュリティ**: 既存の機密情報マスクポリシーを継承。short note / round エントリには機密情報マスク対象パターンを含めない設計
- **スケーラビリティ**: history ファイルの累積行数増加はあるが、サイクルあたり 5-10 エントリ追加程度のオーダーで影響軽微
- **可用性**: 影響なし
- **後方互換**: `--mode` 未指定の従来呼び出しは exit code / 出力フォーマット / 追記位置すべて完全互換

## 技術的考慮事項

- `write-history.sh` 787 行のうち引数パーサ + 新モード分岐 + テンプレ構築箇所を増設
- 新モード共通の入力検証（cycle / unit / round の必須性、数値の妥当性）を `validate_*_args` 関数として再利用可能に分離
- short note の改行保持（`\n` の取り扱い）を実装方針として確定（ヒアドキュメント or `printf '%s\n'`）
- post-merge ガード（既存 `--operations-stage post-merge` / 第二条件 `completion_gate_ready=true ∧ MERGED PR`）は新モードにもそのまま適用される
- self-apply: Unit 完了直前に `/write-history --mode unit-complete-short-note` を本 Unit 自身で呼び出すことで、新モードの動作を実体験で検証

## 関連Issue

- #637（履歴記録の構造改善 - Unit short note + Operations round 1 エントリ）
- 関連（実装済参考）: #616 (write-history マージ前ガード)

## 実装優先度

High（履歴漏れ予防 / Must-have / self-apply で本 Unit が新モードを利用）

## 見積もり

- 設計フェーズ: 0.5 日（domain model / 引数パース仕様 / テンプレ仕様）
- 実装フェーズ: 1 日（write-history.sh 改修 + SKILL.md 改修 + 単体テスト）
- 合計: **1.5 日**

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-07
- **完了日**: 2026-05-07
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
