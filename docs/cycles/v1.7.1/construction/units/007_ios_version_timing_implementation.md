# 実装記録: Unit 007 - iOSバージョン更新タイミング

## 概要

iOSアプリ開発向けに、バージョン更新をInception Phaseで実施するオプションを追加した。

## 実装内容

### 変更ファイル

1. **prompts/package/prompts/inception.md**
   - 「0.5 iOSバージョン更新」セクションを追加
   - project.type=iosの場合、Inception Phase完了時にバージョン更新を提案
   - 履歴に「iOSバージョン更新実施」を記録

2. **prompts/package/prompts/operations.md**
   - バージョン確認セクションに「iOSプロジェクトの場合の事前確認」を追加
   - Inception Phase履歴を確認し、更新済みの場合はスキップ

### 設定

- `project.type = "ios"` が設定されているプロジェクトで有効
- project.type設定は初回セットアップ時に追加される（setup-prompt.mdのセクション6）

## ビジネスルール

| ルール | 内容 |
|--------|------|
| BR-001 | project.type=iosの場合、Inception Phaseでバージョン更新を提案 |
| BR-002 | それ以外の場合は従来通りOperations Phaseで更新 |
| BR-003 | 履歴記録（「iOSバージョン更新実施」）で重複更新を防止 |
| BR-004 | CFBundleShortVersionStringはvプレフィックスなしの形式（1.7.1）を使用 |
| BR-005 | ビルド番号（CFBundleVersion）はスコープ外 |

## テスト結果

- Markdownlint: パス（0エラー）

## 備考

- AIレビューで指摘された問題点（バージョン比較の曖昧さ、vプレフィックス問題）を設計段階で修正
- 履歴記録を使用することで、すでに同じバージョンだった場合でも正確に判定可能

## 完了日

2026-01-11
