# Unit: state-validate.sh schema_version 互換性検証（#731）

## 概要

alpha.2 レビューで defer した #731 を解消する。`state-validate.sh` がサポート対象 `schema_version`（初版 `"3.0"`）と未知バージョンを区別し、未知バージョンを `docs/v3/data-model.md` §6 の WARN / migration・手動対応案内方針に沿って扱えるようにする。

## 含まれるユーザーストーリー

- ストーリー 4: 未サポート schema_version を安全に扱う（#731）

## 責務

- `state-validate.sh` に `schema_version` 値の互換性検証を追加（型のみでなく値も区別）
- 未知 `schema_version` 値を invalid（exit 1）にせず、WARN + migration・手動対応案内として扱う（§6 整合）
- `state-write.sh` が**未知 `schema_version` の既存 `state.json` を更新しないガード**（ファイルを不変のまま保持し migration・手動対応案内を出す）。#731 の本質リスク（writer が非互換 state を更新・保持する事故）を塞ぐ最小範囲
- サポート対象値 / 未知値 / 型不正の境界テスト追加（validator・writer 両方）
- 既存の必須フィールド・型検証（alpha.2 実装）の非後退

## 境界

- `recovery.md` / migration スクリプトの実装（後続フェーズ。本 Unit は validator + writer の最小ガードに留める）
- `state-write.sh` の一般的な状態遷移制御（`define_completed` / `release.*` の許可・禁止遷移ルール）の本格実装（Phase 3+ の別範囲）。本 Unit は「未知 schema_version の既存 state を更新しない」ガードに限定する

## 依存関係

### 依存する Unit

- なし（`state-validate.sh` は alpha.2 で実装済み。本 Unit はその hardening であり define / develop フローと独立）

### 外部依存

- `docs/v3/data-model.md` §6（WARN / migration 方針の正本）

## 非機能要件（NFR）

- **パフォーマンス**: 検証は即時
- **セキュリティ**: 非互換 state の誤更新・保持を防止（本 Unit の主目的）
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項

未知バージョンの扱いは「invalid（exit 1）」ではなく「WARN + 案内」とする点が §6 規定の要。validator の終了コード設計が終了コード規約（v2 の `skills/aidlc/guides/exit-code-convention.md` に準拠。v3 側 rules への移植は後続フェーズ）と整合するよう注意する（WARN 付き完了を exit 非 0 にしない）。

## 関連Issue

- #731（state-validate.sh schema_version 値の互換性検証）

## 実装優先度

Medium

## 見積もり

0.5 サイクル相当

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
