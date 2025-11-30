# ステップ2: 既存コード分析 実行計画

## 目的
v1.0.0の既存構造を分析し、以下を明確にする：
- バグ1（日付コマンド展開問題）の原因箇所
- バグ2（ディレクトリ作成漏れ）の原因箇所
- バージョンアップ手法に関連する現在の仕組み

## 分析対象

### 1. セットアッププロンプトの分析
- `prompts/setup-prompt.md` を読み込み、セットアップ手順を確認
- ディレクトリ作成の記述を確認

### 2. 各フェーズプロンプトの分析
- `docs/aidlc/prompts/inception.md`
- `docs/aidlc/prompts/construction.md`
- `docs/aidlc/prompts/operations.md`
- 履歴記録（history.md）の記述方法を確認

### 3. テンプレートの分析
- `docs/aidlc/templates/` 配下のテンプレートを確認
- 表記揺れの可能性がある箇所を特定

### 4. v1.0.0の成果物確認
- `docs/cycles/v1.0.0/` の構造を確認（参考情報として）

## 成果物
- `docs/cycles/v1.0.1/requirements/existing_analysis.md`
  - バグ原因の特定
  - 現在の仕組みの分析
  - 改善が必要な箇所のリストアップ

## 実行手順
1. セットアッププロンプトの読み込みと分析
2. 各フェーズプロンプトの読み込みと分析
3. テンプレートファイルの確認
4. v1.0.0構造の確認（ls コマンドで構造のみ）
5. 分析結果を existing_analysis.md にまとめる
6. progress.md を更新
