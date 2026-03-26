# Unit: 軽量サイクル（Lite版）

## 概要
バグ修正や軽微な変更向けの簡略化されたAI-DLCサイクルを提供する

## 含まれるユーザーストーリー
- ストーリー 2-1: Lite版サイクルの選択
- ストーリー 2-2: Lite版の簡略フロー実行

## 責務
- セットアップ時のFull/Lite選択機能
- Lite版プロンプトファイルの作成（inception-lite.md, construction-lite.md, operations-lite.md）
- 簡略化されたフローの定義

## 境界
- Full版プロンプトの変更は含まない（Lite版は別ファイルとして作成）
- Lite版とFull版の相互変換機能は含まない

## 依存関係

### 依存する Unit
なし（独立して実装可能）

※ただし、Unit 4（コンテキストリセット提案機能）の内容をLite版にも反映するため、Unit 4の後に実装することを推奨

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: 特になし（ドキュメント変更のみ）
- **セキュリティ**: 特になし
- **スケーラビリティ**: 将来的なLite版の拡張に対応できる構造
- **可用性**: 特になし

## 技術的考慮事項
- `docs/aidlc/prompts/lite/` ディレクトリの作成
- `setup-prompt.md` への `CYCLE_TYPE` 変数追加
- Lite版の簡略化内容:
  - Inception: Intent + 簡易Unit定義のみ（PRFAQ省略）
  - Construction: 設計ステップ省略、直接実装可能
  - Operations: 必要な場合のみ実行（スキップ可能）

## 実装優先度
High

## 見積もり
3時間
