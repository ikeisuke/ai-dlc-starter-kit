# Unit 001 計画: defaults.toml参照のスキル間依存ルール準拠

## 概要
`aidlc-setup` スキルが `aidlc` スキルの内部ファイル `config/defaults.toml` を直接参照している箇所を修正し、自スキル内にコピーした `defaults.toml` を参照するよう変更する。

## 実装計画

### Phase 1: 設計
1. ドメインモデル設計（変更対象のファイルと依存関係の整理）
2. 論理設計（パス解決ロジックの変更仕様）
3. 設計AIレビュー

### Phase 2: 実装
1. `skills/aidlc/config/defaults.toml` を `skills/aidlc-setup/config/defaults.toml` にコピー
2. `skills/aidlc-setup/steps/02-generate-config.md` のパス解決ロジックを修正（自スキルのベースディレクトリ配下の `config/defaults.toml` を参照）
3. コードAIレビュー
4. 検証（diff確認、参照チェック）
5. 統合AIレビュー

## 完了条件チェックリスト
- [ ] `skills/aidlc-setup/config/defaults.toml` が存在し、`skills/aidlc/config/defaults.toml` とTOML設定値部分が一致（同期用コメントの差異は許容）
- [ ] `skills/aidlc-setup/steps/` および `skills/aidlc-setup/scripts/` 内に `aidlc` スキルの内部パス参照がない
- [ ] `/aidlc setup` アップグレードモードで欠落キーが正しく検出される（既知キー除去テスト）
- [ ] 既存キーが誤検出されない（false positive なし）
- [ ] `defaults.toml` 不在時に「defaults.toml が見つかりません。欠落キー検出をスキップします。」と表示してスキップする
- [ ] `aidlc` スキルの既存フロー（プリフライトチェック、設定読み込み等）が変更前と同一動作する（非回帰）

## 関連Issue
- #526
