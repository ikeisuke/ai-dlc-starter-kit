# Unit: defaults.toml参照のスキル間依存ルール準拠

## 概要
`aidlc-setup` スキルが `aidlc` スキルの内部ファイル `config/defaults.toml` を直接参照している箇所を修正し、自スキル内にコピーした `defaults.toml` を参照するよう変更する。

## 含まれるユーザーストーリー
- ストーリー 1: defaults.tomlの自スキル内配置

## 責務
- `skills/aidlc/config/defaults.toml` を `skills/aidlc-setup/config/defaults.toml` にコピー
- `skills/aidlc-setup/steps/02-generate-config.md` のパス解決ロジックを自スキル内の `config/defaults.toml` を参照するよう修正
- `aidlc` スキルの内部パスへの参照が残っていないことの確認

## 完了条件
- `skills/aidlc-setup/config/defaults.toml` が存在し、`skills/aidlc/config/defaults.toml` とTOML設定値部分が一致すること（同期用コメントの差異は許容）
- `skills/aidlc-setup/steps/` および `skills/aidlc-setup/scripts/` 内に `aidlc` スキルの内部パス参照がない
- `/aidlc setup` アップグレードモードで欠落キーが正しく検出される（既知キー除去テスト）
- 既存キーが誤検出されない（false positive なし）
- `defaults.toml` 不在時に「defaults.toml が見つかりません。欠落キー検出をスキップします。」と表示してスキップする
- `aidlc` スキルの既存フロー（プリフライトチェック、設定読み込み等）が変更前と同一動作する（非回帰）

## 境界
- `detect-missing-keys.sh` のロジック変更は含まない
- `defaults.toml` の内容変更は含まない
- `aidlc` スキルへの変更は含まない
- 他のスキル間依存違反の修正は含まない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 変更なし（パス解決のみの変更）
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- `02-generate-config.md` のパス解決ロジックは、自スキルのベースディレクトリ配下の `config/defaults.toml` をReadツールで存在確認する方式に変更
- `detect-missing-keys.sh` の `--defaults` 引数インターフェイスは維持（パスの渡し元のみ変更）
- コピー方式のため、`aidlc` 側の `defaults.toml` 更新時にメタ開発チームが手動同期する責任がある

## 関連Issue
- #526

## 実装優先度
High

## 見積もり
小規模（ファイルコピー + ステップファイル1箇所のパス解決ロジック修正）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-04
- **完了日**: 2026-04-04
- **担当**: -
- **エクスプレス適格性**: eligible
- **適格性理由**: 受け入れ基準が具体的で検証可能、依存なし、既知技術、変更影響範囲が限定的
