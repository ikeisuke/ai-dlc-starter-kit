# ドメインモデル: アップグレードチェックスキップ機能

## エンティティ

- **upgrade_check設定**: `docs/aidlc.toml` の `[rules.upgrade_check]` セクション
  - `enabled`: boolean（デフォルト: `true`）
- **ステップ5（スターターキットバージョン確認）**: Inception Phaseのcurl実行によるバージョン比較処理

## 振る舞い

- `enabled=true`（デフォルト）: 従来通りcurlでバージョン確認を実行
- `enabled=false`: ステップ5をスキップし、ステップ5.5（サイクルモード確認）へ直接遷移
- 読み取り失敗/非boolean値: 警告表示し `true` にフォールバック

## 影響範囲

- inception.mdのステップ5のみが対象
- ステップ5.5以降は影響を受けない
