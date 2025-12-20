# Construction Phase実装以外でのコード記述を制限

- **発見日**: 2025-12-20
- **発見フェーズ**: サイクル開始時
- **発見サイクル**: -
- **優先度**: 高

## 概要

Construction Phaseの実装時以外でのコード記述を原則禁止する。

## 詳細

Inception Phase でコードを書くと、計画なしに実装が進んでしまうリスクがある。コード記述は原則 Construction Phase に限定する。

### 許容されるケース

1. **Construction Phase**: 実装時（通常の開発）
2. **調査時**: 巨大ファイル処理などでどうしてもスクリプトが必要な場合（要ユーザー承認）
3. **Operations Phase**: CI/CD、デプロイ処理、オペレーション自動化に必要なコード

### Operations Phase でのコード記述について

Operations Phase でのコード記述（CI/CD等）は許容されるが、基本的にはバックログに登録し、次のサイクルの Construction Phase で実装することを推奨する。

## 対応案

- 各フェーズプロンプトに「コード記述制限ルール」を追加
- Construction Phase以外でコードを書く場合は承認フローを明記
- Operations Phase でのコード記述は「バックログ登録を推奨」と明記
