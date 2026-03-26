# Unit 007: iOSバージョン更新タイミング - 実装計画

## 概要

iOSアプリ開発向けに、バージョン更新をInception Phaseで実施するオプションを追加する。

## 背景

iOSアプリでは、App Store Connectにビルドを提出する際に前回承認されたバージョンより高いバージョンが必要。現在のOperations Phaseでバージョン更新を行うフローでは、Construction Phase中のTestFlight配布に問題が発生する。

## 関連Issue

- #28 (推定)

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計

**責務**:
- プロジェクトタイプ設定の定義（project.type）
- バージョン更新タイミングの決定ロジック

**成果物**: `docs/cycles/v1.7.1/design-artifacts/domain-models/007-ios-version-timing_domain_model.md`

#### ステップ2: 論理設計

**責務**:
- aidlc.tomlへの設定追加設計
- inception.mdへの条件分岐追加設計
- operations.mdとの整合性確認

**成果物**: `docs/cycles/v1.7.1/design-artifacts/logical-designs/007-ios-version-timing_logical_design.md`

#### ステップ3: 設計レビュー

- 設計内容の承認

### Phase 2: 実装

#### ステップ4: コード生成

**変更対象ファイル**:
1. `prompts/package/aidlc.toml` - project.type設定の追加
2. `prompts/package/prompts/inception.md` - iOSプロジェクト向けバージョン更新フローの追加
3. `prompts/package/prompts/operations.md` - project.type=iosの場合のバージョン更新スキップロジック

#### ステップ5: テスト生成

- 設定ファイルの構文確認
- Markdownlint実行

#### ステップ6: 統合とレビュー

- 変更内容の最終確認
- 実装記録の作成

## 完了基準

- [ ] project.type設定がaidlc.tomlに追加されている
- [ ] project.type=iosの場合、Inception Phaseでバージョン更新が提案される
- [ ] 従来のOperations Phase更新も引き続きサポートされている
- [ ] Markdownlintがパスする
- [ ] 実装記録が作成されている

## 見積もり

1時間
