# Unit: aidlc-v3 起動有効化（marketplace.json 登録 + 統合検証）

## 概要

`marketplace.json` の plugins に `./skills/aidlc-v3` を追加して `/aidlc-v3` 起動を有効化し、define / develop フローが実際に起動・ドッグフーディングできることを統合検証する。

## 含まれるユーザーストーリー

- ストーリー 5: /aidlc-v3 を起動可能にしてドッグフーディングする

## 責務

- `.claude-plugin/marketplace.json` の plugins への `./skills/aidlc-v3` 追加（1 行）
- `/aidlc-v3 define` / `/aidlc-v3 develop` が起動できることの確認
- v2 非影響の確認（`skills/aidlc/` 配下に変更なし / v2 `.aidlc/` 成果物を破壊しない）
- SKILL.md の skeleton 注記（「起動有効化は Phase 3 以降」等）を実態に合わせて更新

## 境界

- v3 → v2 置換（本流化 = `skills/aidlc-v3 → skills/aidlc`、marketplace version の v3.0.0 化）は Phase 7
- release / reflect / doctor の起動（未実装コマンドは予約のまま）

## 依存関係

### 依存する Unit

- 001-v3-define-flow（依存理由: 起動有効化後に `/aidlc-v3 define` が機能する必要があるため）
- 003-v3-develop-tiny-flow（依存理由: 起動有効化後に `/aidlc-v3 develop` が機能する必要があるため）
- 004-state-validate-schema-compat（依存理由: 起動有効化＝ドッグフーディング開始は state safety hardening（#731 / 未知 schema_version 更新防止）完了後の統合検証として位置づけるため。define が state を実書き込みする前に writer ガードが揃っている必要がある）

### 外部依存

- `marketplace.json`（プラグインルート `.claude-plugin/marketplace.json`）

## 非機能要件（NFR）

- **パフォーマンス**: 該当なし
- **セキュリティ**: v2 runtime / ファイルへの非影響（クリーンカット）
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項

v3 の `state.json`（`.aidlc/state.json`）は v2 の `.aidlc/config.toml` / `cycles/` と location が異なるため共存可能。本 Unit は登録 + 検証 + skeleton 注記更新に限定し、本流化は Phase 7 へ defer する。

## 関連Issue

- なし

## 実装優先度

High

## 見積もり

0.3 サイクル相当

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-14
- **完了日**: 2026-06-14
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
