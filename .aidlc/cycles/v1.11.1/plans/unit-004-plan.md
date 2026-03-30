# Unit 004: 定型コマンドのスクリプト化 - 計画

## 概要

AI-DLCで頻繁に使用する定型コマンドをスクリプト化し、許可リスト設定を簡素化する。

## 変更対象ファイル

- `prompts/package/bin/aidlc-env-check.sh`（新規作成）
- `prompts/package/bin/aidlc-git-info.sh`（新規作成）
- `prompts/package/bin/aidlc-cycle-info.sh`（新規作成）
- 許可リストガイド（該当ファイルを確認して更新）

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 各スクリプトの入出力と機能を定義
2. **論理設計**: スクリプト構成と既存スクリプトとの関係を整理
3. **設計レビュー**: ユーザー承認

### Phase 2: 実装

4. **コード生成**: 3本のスクリプトを作成
   - `aidlc-env-check.sh`: 環境チェック（gh, jj, dasel等の存在確認）
   - `aidlc-git-info.sh`: Git状態取得（status, branch, log等）
   - `aidlc-cycle-info.sh`: サイクル情報取得（ブランチ名からバージョン抽出等）

5. **テスト生成**: 各スクリプトの動作確認

6. **統合とレビュー**: AIレビュー → 人間レビュー

## 完了条件チェックリスト

- [x] `aidlc-env-check.sh`（環境チェック: gh, jj, dasel等の存在確認）を作成
- [x] `aidlc-git-info.sh`（Git状態取得: status, branch, log等）を作成
- [x] `aidlc-cycle-info.sh`（サイクル情報取得: ブランチ名からバージョン抽出等）を作成
- [x] 許可リストガイドにスクリプト活用方法を追記
