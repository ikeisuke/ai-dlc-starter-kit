# 既存コードベース分析

## 対象ファイル

### 1. Inception Phase プロンプト
- **パス**: `prompts/package/prompts/inception.md`
- **行数**: 554行
- **構造**: ステップ0-5（ブランチ確認、サイクル存在確認、バックログ確認、進捗管理、既存成果物確認）
- **関連箇所**: なし（ドラフトPR機能は未実装）

### 2. Construction Phase プロンプト
- **パス**: `prompts/package/prompts/construction.md`
- **行数**: 558行
- **構造**: Phase 1（設計）、Phase 2（実装）、Unit単位で進行
- **関連箇所**: なし（Unit完了時のPR作成機能は未実装）

### 3. Operations Phase プロンプト
- **パス**: `prompts/package/prompts/operations.md`
- **行数**: 585行
- **構造**: ステップ1-6（デプロイ準備、CI/CD、監視、テスト、バックログ整理、リリース準備）
- **関連箇所**: なし（ドラフトPRのReady化機能は未実装）

### 4. セットアッププロンプト
- **パス**: `prompts/setup-prompt.md`
- **構造**: ケースA-D（初回セットアップ、アップグレード、バージョン同じ、エラー）
- **関連箇所**:
  - ケースB（アップグレード）の完了メッセージ - setup.md参照案内あり
  - ケースC（バージョン同じ）の完了メッセージ - setup.md参照案内あり

## 分析結果

### 1. ドラフトPRワークフロー

**現状**:
- Inception Phase: PR作成機能なし
- Construction Phase: Unit完了時のPR作成機能なし
- Operations Phase: PR関連の処理なし

**必要な変更**:
- `inception.md`: 完了時にドラフトPR作成ステップを追加
- `construction.md`: Unit完了時にPR作成・マージフローを追加
- `operations.md`: 全Unit完了確認とドラフトPRのReady化を追加

### 2. backlog.md移行処理

**現状**:
- `setup-prompt.md`: 旧形式backlog.mdの移行処理なし
- Inception Phase: backlog/ディレクトリ確認のみ（backlog.md確認なし）

**必要な変更**:
- `setup-prompt.md`: ケースB/Cに移行処理を追加
  - backlog.mdの存在確認
  - 完了済みチェック（backlog-completed参照）
  - 1ログ1ファイルで分割
  - backlog/ディレクトリに移動
  - 元ファイル削除

### 3. setup-prompt.md改善（アップグレードしない場合）

**現状**:
- ケースC（バージョン同じ）の完了メッセージ:
  ```
  次のサイクルを開始するには、以下のファイルを読み込んでください：
  docs/aidlc/prompts/setup.md
  ```
- 問題: v1.5.0以降、setup-cycle.mdがsetup.mdに統合されたが、アップグレードしない場合はsetup.mdがコピーされない

**必要な変更**:
- ケースC（バージョン同じ）の完了メッセージを修正:
  - `docs/aidlc/prompts/setup.md` が存在しない場合
  - `prompts/package/prompts/setup.md` を直接参照するよう案内

**修正後の案内**:
```
次のサイクルを開始するには、以下のファイルを読み込んでください：
- docs/aidlc/prompts/setup.md が存在する場合: docs/aidlc/prompts/setup.md
- 存在しない場合: prompts/package/prompts/setup.md
```

## 互換性への影響

- **後方互換性**: すべて新機能追加のため、既存ワークフローに影響なし
- **移行の必要性**: なし（オプトイン形式）
- **ドキュメント更新**: README.mdにv1.5.2の機能追加を記載

## 技術的課題

### ドラフトPRワークフロー
- GitHub CLI（gh）の利用可否確認が必要
- ブランチ命名規則の定義（例: `cycle/v1.5.2/unit-001`）
- PR作成時のテンプレート活用

### backlog.md移行
- ファイル名生成ロジック（prefix + ケバブケース）
- 完了済み判定の精度（類似度計算）
- セクション単位での分割処理

### setup-prompt.md改善
- ファイル存在確認の確実な実装
- 案内メッセージの明確化
