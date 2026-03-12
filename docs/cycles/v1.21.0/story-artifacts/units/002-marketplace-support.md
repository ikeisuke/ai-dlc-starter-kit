# Unit: マーケットプレイス対応

## 概要
スキルのマーケットプレイス方式を実装し、埋め込み方式との共存を確認する。`marketplace.json` の定義、インストールフロー、既存パイプラインとの互換性を担保する。

## 含まれるユーザーストーリー
- ストーリー 1: マーケットプレイスからのスキルインストール
- ストーリー 2: 埋め込み方式との共存

## 責務
- `marketplace.json` の作成（AI-DLCスキルカタログ定義）
- `/plugin marketplace add` でリポジトリ登録可能にする
- `/plugin install <スキル名>` で個別スキルインストール可能にする
- 埋め込み方式（sync-package.sh → setup-ai-tools.sh）の動作確認
- エラーケース（存在しないスキル名、再インストール）の処理

## 境界
- `claude-skills` リポジトリ側の変更は行わない
- 名前空間プレフィックスの導入はUnit 003で実施
- jj関連スキルのマーケットプレイス登録はUnit 005で扱う

## 依存関係

### 依存する Unit
- 001-rename-aidlc-setup（依存理由: マーケットプレイスのカタログにはリネーム後の `aidlc-setup` を使用するため）

### 外部依存
- `claude-skills` リポジトリの `.claude-plugin/marketplace.json` パターン（参考実装）

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- `claude-skills` リポジトリの `.claude-plugin/marketplace.json` パターンを参考にする
- setup-ai-tools.sh のシンボリックリンク作成ロジックは変更不要
- シンボリックリンク先ディレクトリが存在しない場合のエラーハンドリング（スキップして続行）

## 完了条件（DoD）
- `marketplace.json` がバリデーション済みで、全スキルのカタログIDが定義されている
- `/plugin install <スキル名>` の成功ケース・失敗ケース（存在しないスキル名）が動作確認済み
- 埋め込み方式（`/aidlc-setup` 実行 → sync-package.sh → setup-ai-tools.sh → シンボリックリンク作成）の回帰確認済み
- reviewing-*, session-title, squash-unit スキルが呼び出し可能であることを確認済み

## 実装優先度
High

## 見積もり
中〜大規模（marketplace.json定義＋インストールフロー実装＋共存テスト＋エラーハンドリング）

## 関連Issue
- #292

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
