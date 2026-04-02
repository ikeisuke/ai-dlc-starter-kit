# Unit: named_enabled 設定キーの追加

## 概要
`rules.cycle.named_enabled` 設定キーを追加し、名前付きサイクル機能のon/offを制御できるようにする。

## 含まれるユーザーストーリー
- ストーリー 2: 名前付きサイクル機能の制御 (#507)

## 責務
- `defaults.toml` に `rules.cycle.named_enabled = false` を追加
- `inception/01-setup.md` のステップ7-8に `named_enabled` チェックを追加
- `false` の場合、mode=namedの分岐とステップ8をスキップする制御

## 境界
- 名前付きサイクル機能の文書化のみは行わない（設定キーによる制御を実装）
- 名前付きサイクル機能の内部ロジック変更は行わない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **意図的な仕様変更**: デフォルト `false` により、既存ユーザーは名前付きサイクル機能を使うには `config.toml` に `named_enabled = true` を追加する必要がある。これは後方互換ではなく意図的なopt-in化

## 技術的考慮事項
- `read-config.sh` は `defaults.toml` のデフォルト値を自動フォールバックするため、`config.toml` 側にキーがなくても動作する
- ステップ7の `cycle_mode` 読み取りより前に `named_enabled` をチェックする

## 関連Issue
- #507

## 実装優先度
High

## 見積もり
小規模（defaults.toml 1行追加 + ステップファイル分岐制御追加）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-02
- **完了日**: 2026-04-02
- **担当**: @ikeisuke
- **エクスプレス適格性**: -
- **適格性理由**: -
