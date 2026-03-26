# ステップ2: 既存コード分析計画

## 目的
v1.1.0 の4機能に関連する既存コードを分析し、変更箇所を特定する

## 作成するファイル
`docs/cycles/v1.1.0/requirements/existing_analysis.md`

## 分析結果サマリー

### 機能1: Operations Phase再利用性
**関連ファイル**:
- `docs/aidlc/prompts/operations.md` - Operations Phase プロンプト
- `prompts/setup-prompt.md` - セットアップ時のディレクトリ構成

**現状**:
- 現在は各サイクルごとに `docs/cycles/vX.X.X/operations/` に成果物を作成
- CI/CD構築（ステップ2）、監視・ロギング戦略（ステップ3）は毎回新規作成
- サイクル横断での再利用の仕組みがない

**変更方針**:
- 共通Operations成果物を `docs/aidlc/operations/` に配置するオプションを追加
- 既存設定がある場合は「再利用/更新」の選択肢を提示

### 機能2: 軽量サイクル（Lite版）
**関連ファイル**:
- `prompts/setup-prompt.md` - セットアップ時にサイクルタイプを選択
- `docs/aidlc/prompts/inception.md` - 簡略化が必要
- `docs/aidlc/prompts/construction.md` - 簡略化が必要
- `docs/aidlc/prompts/operations.md` - 簡略化が必要

**現状**:
- フル版のみ存在
- 軽いバグ修正でも全ステップを経由する必要がある

**変更方針**:
- Lite版プロンプトを新規作成（または既存プロンプトにLite版分岐を追加）
- セットアップ時に「Full/Lite」を選択

### 機能3: ブランチ確認機能
**関連ファイル**:
- `prompts/setup-prompt.md` - セットアップ時に確認を追加

**現状**:
- `BRANCH` 変数は定義されているが、実際のブランチ名との比較は行われていない
- 誤ったブランチで作業を開始するリスクがある

**変更方針**:
- セットアップ時に `git branch --show-current` で現在のブランチを取得
- `CYCLE` がブランチ名に含まれていない場合、警告を表示
- ブランチ切り替えの提案を行う

### 機能4: コンテキストリセット提案機能
**関連ファイル**:
- `docs/aidlc/prompts/inception.md` - 「次のステップ」セクション
- `docs/aidlc/prompts/construction.md` - 「次のステップ」「Unit完了時の必須作業」セクション
- `docs/aidlc/prompts/operations.md` - 「次のステップ」セクション

**現状**:
- フェーズ移行時に「新しいセッションで」という記載はあるが、強調されていない
- リセット+呼び出しプロンプトの明示的な提示がない

**変更方針**:
- フェーズ完了時に「コンテキストリセット推奨」セクションを追加
- コピペ可能な呼び出しプロンプトを明示
- Unit完了時にも同様の案内を追加

## 実行手順
1. 上記分析結果を `docs/cycles/v1.1.0/requirements/existing_analysis.md` に記録
2. progress.md のステップ2を「完了」に更新

## 承認
この計画で進めてよろしいですか？
