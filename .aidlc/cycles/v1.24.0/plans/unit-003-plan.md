# Unit 003 計画: エクスプレスモードフロー実装

## 概要

inception.md と construction.md にエクスプレスモードのフロー分岐を実装する。Unit 002 で rules.md に定義した仕様に基づき、`depth_level=minimal` かつ Unit 数がちょうど1の場合に Inception→Construction を1つの連続フローで実行する。

## 変更対象ファイル

- `prompts/package/prompts/inception.md` — エクスプレスモード判定とフロー分岐
- `prompts/package/prompts/construction.md` — エクスプレスモード時の簡略フロー

## 実装計画

### 1. inception.md の変更

#### 1-1. エクスプレスモード判定（ステップ4完了後）

ステップ4（Unit定義）完了後、完了時の必須作業の前にエクスプレスモード判定セクションを挿入:

- `depth_level` が `minimal` でない場合: 判定スキップ、通常フローへ
- `depth_level=minimal` の場合: Unit定義ファイル数をカウント
  - ちょうど1: エクスプレスモード有効
  - 0: フォールバック（rules.md の正本メッセージを参照）
  - 2以上: フォールバック（rules.md の正本メッセージを参照）

#### 1-2. エクスプレスモード有効時のフロー

- PRFAQ作成をスキップ（minimal の既存仕様通り）
- コンテキストリセット提示をスキップ
- Construction Phase の実装ステップに自動遷移
- 遷移メッセージ表示:
  ```text
  【エクスプレスモード】Inception Phase 完了。Construction Phase に自動遷移します。
  ```

#### 1-3. 完了時の必須作業へのフォールバック

エクスプレスモード適用不可の場合、通常の完了時の必須作業（ラベル付与、PR作成、squash、コミット、コンテキストリセット提示）を実行。

### 2. construction.md の変更

#### 2-1. エクスプレスモード検出

「最初に必ず実行すること」のステップ12（実行前確認と完了条件の提示）の前後で、エクスプレスモードフラグを検出する仕組みを追加:

- Inception Phase からの自動遷移で `express_mode=true` が設定されている場合を検出
- 検出方法: `depth_level=minimal` かつ Unit 数がちょうど1の場合にエクスプレスモードと判定

#### 2-2. エクスプレスモード時の簡略フロー

Phase 1（設計）をスキップ:
- `depth_level=minimal` の既存仕様（ドメインモデル・論理設計スキップ可）をそのまま適用
- 設計レビューもスキップ
- 直接 Phase 2（実装）のステップ4（コード生成）に進む

#### 2-3. エクスプレスモード完了時

- 通常の Unit 完了処理（完了条件確認、Unit 定義ファイル更新、履歴記録、コミット）を実行
- commit-flow.md の Unit 完了コミット手順に従う
- コミット失敗時のエラーハンドリング:
  ```text
  【エラー】コミットの作成に失敗しました。
  手動でコミットを作成してください:
  git add -A && git commit -m "feat: [{{CYCLE}}] Unit {NNN}完了 - {DESCRIPTION}"
  ```

## 完了条件チェックリスト

- [ ] inception.md にエクスプレスモード判定分岐を追加（Depth Level 読み込み後）
- [ ] inception.md のエクスプレスモード時フロー（簡略 Intent→簡略ストーリー→実装への自動遷移）
- [ ] construction.md にエクスプレスモード用の簡略フロー（設計省略→直接実装）を追加
- [ ] エクスプレスモード完了時のコミットフロー記述
- [ ] フォールバック時の通知メッセージ適用（文言の正本は rules.md を参照）
- [ ] エクスプレスモード完了失敗時のエラーメッセージ表示と手動対応案内
