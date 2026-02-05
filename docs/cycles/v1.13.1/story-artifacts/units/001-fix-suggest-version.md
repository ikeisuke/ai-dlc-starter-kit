# Unit: suggest-version.shバグ修正

## 概要
suggest-version.shがalpha/betaサフィックスなしのバージョン（例: v2.0.0）で実行した際にエラーとなる問題を修正する。

## 含まれるユーザーストーリー
- ストーリー1: suggest-version.shのalpha/betaなしバージョン対応

## 責務
- suggest-version.shのバージョン解析ロジックの修正
- alpha/beta部分をオプショナルとして扱うよう変更

## 境界
- 他のスクリプトへの変更は含まない

## ソースファイル管理
- **修正対象**: `prompts/package/bin/suggest-version.sh`（ソース）
- **同期先**: `docs/aidlc/bin/suggest-version.sh`はrsync同期で自動更新（Operations Phaseで実施）
- このリポジトリはメタ開発のため、`prompts/package/`がソースオブトゥルース

## 依存関係

### 依存するUnit
なし

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: 変更なし
- **セキュリティ**: 変更なし
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- 現在のスクリプトは `set -u` で未定義変数をエラーにしている
- バージョン解析時にalpha/beta部分が存在しない場合の処理を追加

## 実装優先度
High（Must-have）

## 見積もり
小規模（スクリプト1ファイルの修正）

## 関連Issue
- #161

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
