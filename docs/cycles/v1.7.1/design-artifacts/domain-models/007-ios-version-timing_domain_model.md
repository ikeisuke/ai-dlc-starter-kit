# ドメインモデル: iOSバージョン更新タイミング

## 概要

iOSアプリ開発プロジェクトにおいて、バージョン更新をInception Phaseで実施するオプションを追加し、Construction Phase中のTestFlight配布に対応できるようにする。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### ProjectType

プロジェクトの種類を表す値オブジェクト。

- **属性**: type: String - プロジェクトタイプ識別子
- **許容値**:
  - `"general"` - 一般的なプロジェクト（デフォルト）
  - `"web"` - Webアプリケーション
  - `"backend"` - バックエンドサービス
  - `"cli"` - コマンドラインツール
  - `"desktop"` - デスクトップアプリケーション
  - `"ios"` - iOSアプリケーション
  - `"android"` - Androidアプリケーション
- **不変性**: プロジェクトタイプはサイクル中に変更されない
- **等価性**: typeの文字列値が同一であれば等価

### VersionUpdateTiming

バージョン更新のタイミングを表す値オブジェクト。

- **属性**: timing: String - 更新タイミング
- **許容値**:
  - `"inception"` - Inception Phaseでバージョン更新
  - `"operations"` - Operations Phaseでバージョン更新（従来動作）
- **不変性**: サイクル開始時に決定
- **等価性**: timingの文字列値が同一であれば等価

## ドメインサービス

### VersionUpdateDecisionService

バージョン更新タイミングを決定するサービス。

- **責務**: ProjectTypeに基づいてバージョン更新タイミングを判断
- **操作**:
  - `shouldUpdateInInception(projectType)` - project.type="ios"の場合はtrue
  - `getVersionUpdateProposal(projectType)` - 更新提案メッセージを生成

## ビジネスルール

### BR-001: iOSプロジェクトのバージョン更新タイミング

- **条件**: project.type = "ios"
- **動作**: Inception Phase完了時にバージョン更新を提案する
- **理由**: App Store Connectではビルド提出時に前回より高いバージョンが必要。Construction Phase中のTestFlight配布を可能にするため。

### BR-002: 従来動作の維持

- **条件**: project.type != "ios" または project.type が未設定
- **動作**: 従来通りOperations Phaseでバージョン更新を行う
- **理由**: 既存ワークフローとの互換性を維持

### BR-003: バージョン更新の重複防止

- **条件**: Inception Phaseでバージョン更新済み
- **動作**: Operations Phaseのバージョン確認で「更新済み」と認識しスキップ
- **方法**: Inception Phase履歴（`history/inception.md`）に「バージョン更新実施」の記録があるか確認
- **注意**: バージョン値の比較だけでは、すでに同じバージョンだった場合に判別できないため、履歴記録を使用する

### BR-004: バージョン形式の正規化

- **条件**: iOSプロジェクト（CFBundleShortVersionString使用時）
- **動作**: サイクルバージョン（v1.7.1）からvプレフィックスを除去して使用（1.7.1）
- **理由**: CFBundleShortVersionStringは数値ドット区切り形式のみ受け付ける

### BR-005: スコープ外の明確化

- **対象外**: ビルド番号（CFBundleVersion）の管理
- **理由**: ビルド番号はCIツールやビルドシステムで自動インクリメントされることが多く、プロンプトでの管理は不適切
- **代替**: 必要に応じてバックログに記録し、別途対応

## 影響範囲

### 変更対象

1. **aidlc.toml**: `[project].type` 設定の追加
2. **inception.md**: iOSプロジェクト向けバージョン更新提案の追加
3. **operations.md**: Inception Phase更新済みの場合のスキップロジック

### 変更なし

- construction.md: 影響なし（実装フェーズの動作は変わらない）
- 既存のproject設定（name, description, tech_stack）: 変更なし

## ユビキタス言語

このドメインで使用する共通用語：

- **ProjectType**: プロジェクトの種類（ios, android, web等）
- **Inception Version Update**: Inception Phaseでのバージョン更新
- **Operations Version Update**: Operations Phaseでのバージョン更新（従来動作）
- **TestFlight**: iOSアプリのベータ配布プラットフォーム

## 不明点と質問

（対話を通じて不明点を明確化し、このセクションに記録していく）

現時点で不明点はありません。Unit定義とバックログ（feature-ios-version-inception-phase.md）に十分な情報が記載されています。
