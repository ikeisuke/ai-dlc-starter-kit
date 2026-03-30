# Unit 003 実装計画: コミットメッセージへのサイクル名追加

## 概要

Unit完了時のコミットメッセージにサイクル名を含めるようプロンプトを更新する。

## 変更対象ファイル

以下のファイルを修正（`prompts/package/` 配下を編集）:

1. **prompts/package/prompts/construction.md**（メイン）
   - 行454-457: コミットメッセージ例を更新

2. **prompts/package/prompts/inception.md**
   - 行491-494: コミットメッセージ例を更新

3. **prompts/package/prompts/operations.md**
   - 行402-405: コミットメッセージ例を更新

## 変更内容

### 現在の形式

**Construction Phase**:
```
feat: [Unit名]の実装完了 - ドメインモデル、論理設計、コード、テストを作成
```

**Inception Phase**:
```
feat: Inception Phase完了 - Intent、ユーザーストーリー、Unit定義を作成
```

**Operations Phase**:
```
chore: Operations Phase完了 - デプロイ、CI/CD、監視を構築
```

### 新しい形式

**Construction Phase**:
```
feat: [{{CYCLE}}] Unit 001完了 - ドメインモデル、論理設計、コード、テストを作成
```

**Inception Phase**:
```
feat: [{{CYCLE}}] Inception Phase完了 - Intent、ユーザーストーリー、Unit定義を作成
```

**Operations Phase**:
```
chore: [{{CYCLE}}] Operations Phase完了 - デプロイ、CI/CD、監視を構築
```

## 設計方針

このUnitはプロンプト修正のみで、コード生成は不要。
ドメインモデル設計・論理設計は省略し、直接実装に進む。

## 実施手順

1. 3つのプロンプトファイルのコミットメッセージ例を更新
2. ビルド確認（構文エラーなどがないか）
3. Unit定義ファイルの実装状態を「完了」に更新
4. 履歴記録
5. Gitコミット（新形式を使用: `feat: [v1.5.1] Unit 003完了 - ...`）
