# ドメインモデル: iOSバージョン確認強化

## 概要

Operations Phaseでのデプロイ準備において、iOSプロジェクトのビルド番号（CURRENT_PROJECT_VERSION）を確認し、前バージョンからの更新を検証する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## エンティティ（Entity）

※ このUnitはプロンプト修正であり、ランタイムエンティティは存在しない

## 値オブジェクト（Value Object）

### iOSVersion

- **属性**:
  - marketingVersion: String - App Storeに表示されるバージョン（例: 1.7.1）
  - buildNumber: String - ビルド番号（例: 1, 2, 123）
- **不変性**: バージョン情報は一度取得したら変更されない
- **等価性**: marketingVersionとbuildNumberの両方が一致すれば等価

### ProjectFile

- **属性**:
  - path: String - project.pbxprojファイルへのパス
- **不変性**: ファイルパスは実行中に変化しない
- **等価性**: pathが一致すれば等価

## 集約（Aggregate）

### iOSVersionComparison

- **集約ルート**: 現在ブランチのiOSVersion
- **含まれる要素**:
  - currentVersion: iOSVersion（現在ブランチ）
  - previousVersion: iOSVersion（デフォルトブランチ）
- **境界**: バージョン比較の判定ロジック
- **不変条件**:
  - ビルド番号が同一の場合、App Store再提出でリジェクトされる可能性
  - ビルド番号はインクリメントされていることが推奨

## ドメインサービス

### VersionCheckService

- **責務**: iOSプロジェクトのバージョン確認と比較
- **操作**:
  - findProjectFiles() - project.pbxprojファイルを検索
  - extractVersion(projectFile, branch) - 指定ブランチからバージョン情報を抽出
  - compareVersions(current, previous) - バージョン比較と警告生成

## ユビキタス言語

このドメインで使用する共通用語：

- **MARKETING_VERSION**: App Storeに表示されるバージョン番号（CFBundleShortVersionString）
- **CURRENT_PROJECT_VERSION**: ビルド番号（CFBundleVersion）。App Storeは同一ビルド番号での再提出を拒否する
- **デフォルトブランチ**: main/masterなど、リリース元となるブランチ
- **ビルド番号インクリメント**: App Store提出時に必須となるビルド番号の増加

## 処理フロー

1. `project.type = "ios"` の確認
2. project.pbxprojファイルの検索（Pods/DerivedData除外、複数の場合はユーザー確認）
3. デフォルトブランチの取得（リモートブランチを参照）
4. 現在ブランチとデフォルトブランチのCURRENT_PROJECT_VERSIONを比較
5. 同一の場合はインクリメントを提案、抽出失敗の場合は手動確認を促す

## 不明点と質問（設計中に記録）

### AIレビュー指摘への対応

[Question] 複数ターゲット/構成がある場合、どのターゲットを比較対象にする想定ですか？
[Answer] 最初に見つかった値を使用する。詳細な比較が必要な場合は手動確認を促す。

[Question] `CURRENT_PROJECT_VERSION` は「数値のみ」を必須とみなしますか？
[Answer] 数値を想定するが、抽出結果が変数参照等の場合は手動確認を促す。
