# Unit: aidlc-setup の starter_kit_version-only 差分 no-op スキップ

## 概要

`aidlc-setup` のアップグレードフローで「適用差分が `config.toml.starter_kit_version` のみ」を検出した際に書き込みをスキップする no-op 判定を追加する。ストーリー 1 の SoT 一本化（Unit 003）完了後に動作することを前提とする。

## 含まれるユーザーストーリー

- ストーリー 2: aidlc-setup の starter_kit_version-only 差分 no-op スキップ

## 責務

- `aidlc-setup` の差分判定ロジックに「`starter_kit_version` のみ差分」検出を追加
- 検出時に書き込みをスキップし、`「変更不要のためスキップしました（差分: starter_kit_version のみ）」` を stdout に表示
- 通常のアップグレード（他フィールド差分あり）では従来動作を維持
- 異常系（差分検出失敗）では警告 + 安全側フォールバック（全更新）

## 境界

- `marketplace.json` の SoT 化（Unit 003）には立ち入らず、参照のみ
- `aidlc-migrate` 側のロジックは対象外（v1→v2 マイグレーションの判定は別系統）
- 他のフィールド差分（`[rules.*]` 等）の no-op 判定は対象外（本 Unit は `starter_kit_version` のみ）

## 依存関係

### 依存する Unit

- **Unit 003: marketplace.json への version SoT 一本化**（依存理由: ストーリー 1A の SoT 一本化完了後に「`starter_kit_version` の役割」が「ローカルキャッシュ値」として明確になり、no-op スキップが意味を持つため）

### 外部依存

- `aidlc-setup` 既存の差分判定ロジック（既存実装）

## 非機能要件（NFR）

- **正確性**: 差分判定が偽陰性（書き込みすべきところをスキップ）を起こさない
- **可観測性**: スキップ時に明確なメッセージで利用者に通知

## 技術的考慮事項

- 差分判定アルゴリズム: 適用前 / 適用後の `config.toml` を行レベルまたはキーレベルで比較し、差分が `starter_kit_version` キーの値変化のみであることを判定
- `dasel` の TOML 比較機能 or `diff` ベースの実装どちらを採用するかを Construction Design で確定
- スキップ判定の実装位置: `aidlc-setup` のアップグレードエントリポイント直後（書き込み前）

## 関連Issue

- #618

## 実装優先度

Low（補助機能）

## 見積もり

1〜2 時間（差分判定実装 + メッセージ追加 + テスト）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
