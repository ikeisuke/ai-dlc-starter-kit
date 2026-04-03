# ドメインモデル: リモートデフォルトブランチ取り込み確認

## 概要

既存の`setup-branch.sh`が出力する`main_status`シグナルを活用し、ステップ10-3のbehind時メッセージを「取り込み推奨」の警告に拡張する。新規エンティティの追加は不要。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### MainStatus（既存・変更なし）
- **属性**: status: enum(up-to-date | behind | fetch-failed)
- **不変性**: setup-branch.sh実行後に確定
- **等価性**: 文字列完全一致

## ドメインサービス

### BranchFreshnessCheck（既存・setup-branch.sh）
- **責務**: リモートデフォルトブランチとのfetch+behind判定（変更なし）
- **操作**: check() → MainStatus出力

### InceptionSetupOrchestrator（01-setup.md・ステップ10-3）
- **責務**: MainStatus出力を受けてユーザーへの表示を行う（メッセージ拡張のみ）
- **変更**: behind時のメッセージを「取り込み推奨」警告に拡張

## ユビキタス言語

- **取り込み確認（Freshness Check）**: リモートデフォルトブランチとの差分を検出する機能
- **main_status**: setup-branch.shが出力する同期状態シグナル

## 不明点と質問

（なし）
