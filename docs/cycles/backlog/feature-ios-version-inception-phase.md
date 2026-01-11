# iOSアプリ向けバージョン更新タイミングの改善

- **発見日**: 2026-01-11
- **発見フェーズ**: Operations
- **発見サイクル**: v1.7.0
- **優先度**: 中

## 概要

iOSアプリでは、App Store Connectにビルドを提出する際に、前回承認されたバージョンより高いバージョンが必要。現在Operations Phaseでバージョン更新を行うフローでは、開発中に複数回ビルド提出する場合に問題が発生する可能性がある。

## 詳細

### 発生したエラー
```
Validation failed
Invalid Pre-Release Train. The train version '1.3.3' is closed for new build submissions

Validation failed
This bundle is invalid. The value for key CFBundleShortVersionString [1.3.3] in the Info.plist file must contain a higher version than that of the previously approved version [1.3.3].
```

### 問題点
- Operations Phaseでバージョン更新すると、Construction Phase中のTestFlight配布ができない
- iOSアプリ開発では、開発初期からバージョンを確定させる必要がある

## 対応案

### 案1: Inception Phaseでバージョン更新（推奨）
- サイクル開始時（Inception Phase）でバージョンを更新
- Construction Phase中のTestFlight配布に対応可能
- セマンティックバージョニングの早期確定

### 案2: プロジェクトタイプ別フロー
- `project.type = "ios"` の場合、Inception Phaseでバージョン更新を提案
- 他のタイプは従来通りOperations Phaseで更新

## 影響範囲

- `docs/aidlc/prompts/inception.md`
- `docs/aidlc/prompts/operations.md`
- `docs/cycles/operations.md`（運用引き継ぎ）

## 推奨対応サイクル

次回以降のサイクルで検討
