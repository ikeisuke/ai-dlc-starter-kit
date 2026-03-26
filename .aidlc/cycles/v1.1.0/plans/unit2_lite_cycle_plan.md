# Unit 2: 軽量サイクル（Lite版）実装計画

## 概要

バグ修正や軽微な変更向けの簡略化されたAI-DLCサイクルを提供する。

## 実装方式

**案4: Full版参照+差分指示**を採用

- Lite版プロンプトはFull版を参照し、スキップ/簡略化する箇所のみを記述
- Full版が唯一の真実（Single Source of Truth）
- メンテナンス性と実装コストのバランスが良い

## 対象ストーリー

- ストーリー 2-1: Lite版サイクルの選択
- ストーリー 2-2: Lite版の簡略フロー実行

## 実装内容

### Phase 1: 設計

#### ステップ1: ドメインモデル設計
- Lite版サイクルの概念モデル
- Full版との関係性（参照+差分）
- 各フェーズでのスキップ/簡略化ポイント

#### ステップ2: 論理設計
- ディレクトリ構成: `docs/aidlc/prompts/lite/`
- 各Lite版プロンプトの構造（参照+差分指示）
- `setup-prompt.md` の変更（CYCLE_TYPE変数追加）

#### ステップ3: 設計レビュー

### Phase 2: 実装

#### ステップ4: コード生成
1. `docs/aidlc/prompts/lite/` ディレクトリ作成
2. `inception-lite.md` の作成
   - Full版（inception.md）を参照
   - 差分: PRFAQ省略、詳細ユーザーストーリー簡略化
3. `construction-lite.md` の作成
   - Full版（construction.md）を参照
   - 差分: 設計ステップ省略、直接実装可能
4. `operations-lite.md` の作成
   - Full版（operations.md）を参照
   - 差分: スキップ可能、簡易チェックリスト
5. `setup-prompt.md` への変更
   - CYCLE_TYPE変数追加（Full/Lite選択）

#### ステップ5: テスト生成
- 各Lite版プロンプトの整合性確認

#### ステップ6: 統合とレビュー
- 実装記録の作成

## 成果物

1. `docs/aidlc/prompts/lite/inception-lite.md`
2. `docs/aidlc/prompts/lite/construction-lite.md`
3. `docs/aidlc/prompts/lite/operations-lite.md`
4. `prompts/setup-prompt.md`（変更）
5. 設計・実装記録ドキュメント

## 見積もり

3時間
